"""
WebSocket 服务器

处理 ESP32 设备的 WebSocket 连接，实现完整的对话流程：
  hello 握手 → 接收 Opus 音频 → ASR 识别 → LangChain 对话 → TTS 合成 → 发送回设备
"""

import asyncio
import json
import logging
import uuid
from typing import Optional

import websockets
from websockets.server import WebSocketServerProtocol

import config
from protocol import encode_opus_frame, decode_frame, is_opus_frame
from audio.opus_codec import OpusDecoder, OpusEncoder
from audio.asr import transcribe as asr_transcribe
from audio.tts import synthesize as tts_synthesize
from agent.chain import chat as agent_chat
from agent.tools import set_mcp_sender

logger = logging.getLogger("ws")


class DeviceSession:
    """
    设备会话管理

    管理单个设备的 WebSocket 连接状态、音频缓冲和对话流程。

    Attributes:
        device_id: 设备标识（MAC 地址）
        session_id: 会话 ID
        ws: WebSocket 连接对象
        opus_decoder: Opus 解码器
        opus_encoder: Opus 编码器
        audio_buffer: 音频数据缓冲区（PCM）
        is_speaking: 是否正在播放 TTS
    """

    def __init__(self, ws: WebSocketServerProtocol):
        self.ws = ws
        self.device_id: str = "unknown"
        self.session_id: str = str(uuid.uuid4())
        self.opus_decoder: Optional[OpusDecoder] = None
        self.opus_encoder: Optional[OpusEncoder] = None
        self.audio_buffer: bytearray = bytearray()
        self.is_speaking: bool = False
        self._processing: bool = False

    async def handle(self):
        """处理设备的 WebSocket 连接生命周期"""
        try:
            async for message in self.ws:
                if isinstance(message, bytes):
                    await self._handle_binary(message)
                elif isinstance(message, str):
                    await self._handle_text(message)
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"设备断开连接: {self.device_id}")
        except Exception as e:
            logger.error(f"处理消息异常: {e}", exc_info=True)
        finally:
            from agent.memory import memory_manager
            memory_manager.remove(self.device_id)

    async def _handle_text(self, data: str):
        """
        处理文本消息（JSON 控制消息）

        Args:
            data: JSON 字符串
        """
        try:
            msg = json.loads(data)
            msg_type = msg.get("type")

            if msg_type == "hello":
                await self._handle_hello(msg)
            elif msg_type == "listen":
                await self._handle_listen(msg)
            elif msg_type == "abort":
                await self._handle_abort(msg)
            elif msg_type == "mcp":
                await self._handle_mcp(msg)
            else:
                logger.warning(f"未知消息类型: {msg_type}")

        except json.JSONDecodeError:
            logger.error(f"JSON 解析失败: {data[:100]}")

    async def _handle_hello(self, msg: dict):
        """
        处理设备 hello 握手消息

        设备发送：
          {"type":"hello","version":3,"features":{"mcp":true},"transport":"websocket",
           "audio_params":{"format":"opus","sample_rate":16000,"channels":1,"frame_duration":60}}

        服务器回复：
          {"type":"hello","transport":"websocket","session_id":"xxx",
           "audio_params":{"sample_rate":24000,"frame_duration":60}}
        """
        version = msg.get("version", 3)
        audio_params = msg.get("audio_params", {})

        logger.info(f"设备握手: version={version}, audio_params={audio_params}")

        # 初始化编解码器
        self.opus_decoder = OpusDecoder(
            sample_rate=audio_params.get("sample_rate", config.OPUS_SAMPLE_RATE),
            channels=audio_params.get("channels", 1)
        )
        self.opus_encoder = OpusEncoder(
            sample_rate=config.SERVER_SAMPLE_RATE,
            channels=1
        )

        # 发送服务器 hello 响应
        response = {
            "type": "hello",
            "transport": "websocket",
            "session_id": self.session_id,
            "audio_params": {
                "sample_rate": config.SERVER_SAMPLE_RATE,
                "frame_duration": config.OPUS_FRAME_DURATION_MS
            }
        }

        await self.ws.send(json.dumps(response))
        logger.info(f"握手完成: session_id={self.session_id}")

    async def _handle_listen(self, msg: dict):
        """
        处理监听状态变化

        state="start" 时开始录音，state="stop" 时结束录音并处理
        """
        state = msg.get("state")

        if state == "stop":
            logger.info(f"录音结束，处理音频: {len(self.audio_buffer)} bytes")
            if len(self.audio_buffer) > 0:
                await self._process_audio()
        elif state == "start":
            logger.info("开始录音")
            self.audio_buffer = bytearray()

    async def _handle_abort(self, msg: dict):
        """处理中止指令"""
        logger.info("收到中止指令")
        self.is_speaking = False
        self.audio_buffer = bytearray()

    async def _handle_mcp(self, msg: dict):
        """处理来自设备的 MCP 消息"""
        logger.info(f"收到 MCP 消息: {json.dumps(msg, ensure_ascii=False)[:200]}")

    async def _handle_binary(self, data: bytes):
        """
        处理二进制消息（Opus 音频帧）

        Args:
            data: BinaryProtocol3 格式的音频帧
        """
        if not is_opus_frame(data):
            return

        opus_payload = decode_frame(data)
        if opus_payload is None:
            return

        if self.opus_decoder is None:
            return

        # 解码 Opus 为 PCM 并追加到缓冲区
        pcm_data = self.opus_decoder.decode(opus_payload)
        if pcm_data:
            self.audio_buffer.extend(pcm_data)

    async def _process_audio(self):
        """
        处理录音缓冲区中的音频数据

        流程：PCM → ASR 识别 → LangChain 对话 → TTS 合成 → Opus 编码 → 发送
        """
        if self._processing:
            logger.warning("上一轮处理未完成，跳过")
            return

        self._processing = True
        pcm_data = bytes(self.audio_buffer)
        self.audio_buffer = bytearray()

        try:
            # Step 1: ASR 语音识别
            logger.info("开始 ASR 识别...")
            user_text = await asr_transcribe(pcm_data)

            if not user_text or len(user_text.strip()) == 0:
                logger.warning("ASR 识别结果为空")
                return

            logger.info(f"ASR 结果: {user_text}")

            # 发送 STT 消息给设备（显示识别文本）
            await self._send_json({
                "type": "stt",
                "text": user_text
            })

            # Step 2: LangChain Agent 对话
            logger.info("调用 Agent 对话...")
            reply_text, emotion, tool_calls = await agent_chat(self.device_id, user_text)

            # Step 3: 发送 LLM 回复消息（驱动表情和显示）
            await self._send_json({
                "type": "llm",
                "emotion": emotion,
                "text": reply_text
            })

            # Step 4: TTS 语音合成
            logger.info(f"TTS 合成: {reply_text[:50]}...")
            await self._send_json({
                "type": "tts",
                "state": "sentence_start",
                "text": reply_text
            })

            pcm_audio = await tts_synthesize(reply_text)

            if pcm_audio:
                # Step 5: 编码为 Opus 并发送给设备
                await self._send_audio(pcm_audio)

            await self._send_json({
                "type": "tts",
                "state": "stop"
            })

            # Step 6: 执行工具调用（如果有）
            for tc in tool_calls:
                logger.info(f"执行工具: {tc['name']}({tc['arguments']})")
                await self._send_json({
                    "type": "mcp",
                    "payload": {
                        "jsonrpc": "2.0",
                        "method": "tools/call",
                        "params": tc
                    }
                })

        except Exception as e:
            logger.error(f"音频处理失败: {e}", exc_info=True)
        finally:
            self._processing = False

    async def _send_json(self, data: dict):
        """发送 JSON 消息给设备"""
        try:
            await self.ws.send(json.dumps(data, ensure_ascii=False))
        except Exception as e:
            logger.error(f"发送 JSON 失败: {e}")

    async def _send_audio(self, pcm_data: bytes):
        """
        将 PCM 音频编码为 Opus 并通过 WebSocket 发送给设备

        Args:
            pcm_data: PCM 16-bit 24kHz 单声道音频数据
        """
        if self.opus_encoder is None:
            return

        # 按帧切割 PCM 数据并逐帧发送
        frame_size = 24000 * 60 // 1000 * 2  # 24kHz × 60ms × 2bytes = 2880 bytes
        offset = 0

        while offset < len(pcm_data):
            chunk = pcm_data[offset:offset + frame_size]

            # 不足一帧时补零
            if len(chunk) < frame_size:
                chunk = chunk + b'\x00' * (frame_size - len(chunk))

            opus_data = self.opus_encoder.encode(chunk)
            if opus_data:
                frame = encode_opus_frame(opus_data)
                await self.ws.send(frame)

            offset += frame_size

            # 控制发送速率，避免淹没设备
            await asyncio.sleep(0.05)


async def handle_connection(ws: WebSocketServerProtocol):
    """
    处理新的 WebSocket 连接

    Args:
        ws: WebSocket 连接对象
    """
    path = ws.path if hasattr(ws, 'path') else "/"

    # 从 Header 或 URL 参数获取设备信息
    device_id = ws.request.headers.get("Device-Id", "unknown") if ws.request else "unknown"

    logger.info(f"新连接: device_id={device_id}, path={path}")

    session = DeviceSession(ws)
    session.device_id = device_id

    # 注入 MCP 发送回调
    set_mcp_sender(session._send_json)

    await session.handle()


async def start_ws_server():
    """启动 WebSocket 服务器"""
    logger.info(f"WebSocket 服务器启动: ws://0.0.0.0:{config.WS_PORT}/ws")

    server = await websockets.serve(
        handle_connection,
        "0.0.0.0",
        config.WS_PORT,
        max_size=1024 * 1024,  # 1MB 最大消息
        ping_interval=30,
        ping_timeout=10,
    )

    return server
