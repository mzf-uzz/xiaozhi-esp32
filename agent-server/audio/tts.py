"""
语音合成（TTS）模块

调用小米 Token Plan API（兼容 OpenAI TTS 格式）将文本转为音频。
返回的音频需要转码为 PCM 24kHz 再编码为 Opus 发送给设备。
"""

import io
import logging
from typing import Optional

import httpx
import numpy as np

import config

logger = logging.getLogger("tts")


async def synthesize(text: str) -> Optional[bytes]:
    """
    将文本合成为 PCM 音频

    Args:
        text: 要合成的文本

    Returns:
        PCM 16-bit 24kHz 单声道音频数据，失败返回 None
    """
    if not config.XIAOMI_API_KEY or config.XIAOMI_API_KEY == "your-api-key-here":
        logger.error("未配置 XIAOMI_API_KEY")
        return None

    url = f"{config.XIAOMI_BASE_URL}/audio/speech"

    headers = {
        "Authorization": f"Bearer {config.XIAOMI_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "model": config.XIAOMI_TTS_MODEL,
        "input": text,
        "voice": config.XIAOMI_TTS_VOICE,
        "response_format": "pcm",
        "sample_rate": config.SERVER_SAMPLE_RATE,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()

            # API 返回原始 PCM 音频数据
            pcm_data = response.content

            if len(pcm_data) == 0:
                logger.warning("TTS 返回空音频")
                return None

            logger.info(f"TTS 合成完成: {len(pcm_data)} bytes, text={text[:50]}...")
            return pcm_data
    except httpx.HTTPStatusError as e:
        logger.error(f"TTS API 错误: {e.response.status_code} - {e.response.text}")
        return None
    except Exception as e:
        logger.error(f"TTS 请求失败: {e}")
        return None
