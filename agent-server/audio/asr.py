"""
语音识别（ASR）模块

调用小米 Token Plan API（兼容 OpenAI Whisper 格式）将 Opus/PCM 音频转为文本。
"""

import io
import logging
import tempfile
import wave
from typing import Optional

import httpx

import config

logger = logging.getLogger("asr")


async def transcribe(pcm_data: bytes, sample_rate: int = config.OPUS_SAMPLE_RATE) -> Optional[str]:
    """
    将 PCM 音频数据转为文本

    Args:
        pcm_data: PCM 16-bit 单声道音频数据
        sample_rate: 采样率（默认 16000）

    Returns:
        识别出的文本，失败返回 None
    """
    if not config.XIAOMI_API_KEY or config.XIAOMI_API_KEY == "your-api-key-here":
        logger.error("未配置 XIAOMI_API_KEY")
        return None

    # 将 PCM 数据封装为 WAV 格式（API 要求）
    wav_buffer = io.BytesIO()
    with wave.open(wav_buffer, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)  # 16-bit = 2 bytes
        wf.setframerate(sample_rate)
        wf.writeframes(pcm_data)
    wav_buffer.seek(0)

    url = f"{config.XIAOMI_BASE_URL}/audio/transcriptions"

    headers = {
        "Authorization": f"Bearer {config.XIAOMI_API_KEY}",
    }

    files = {
        "file": ("audio.wav", wav_buffer, "audio/wav"),
    }

    data = {
        "model": config.XIAOMI_ASR_MODEL,
        "language": "zh",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, headers=headers, files=files, data=data)
            response.raise_for_status()
            result = response.json()
            text = result.get("text", "")
            logger.info(f"ASR 识别结果: {text}")
            return text
    except httpx.HTTPStatusError as e:
        logger.error(f"ASR API 错误: {e.response.status_code} - {e.response.text}")
        return None
    except Exception as e:
        logger.error(f"ASR 请求失败: {e}")
        return None
