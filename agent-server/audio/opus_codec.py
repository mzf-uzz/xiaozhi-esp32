"""
Opus 音频编解码封装

将设备发送的 Opus 帧解码为 PCM，以及将 TTS 的 PCM 编码为 Opus 发送给设备。
"""

import io
import struct
import logging
from typing import Optional

import numpy as np

import config

logger = logging.getLogger("opus")

# Opus 帧大小：采样率 16kHz × 帧时长 60ms = 960 个采样点
SAMPLES_PER_FRAME = config.OPUS_SAMPLE_RATE * config.OPUS_FRAME_DURATION_MS // 1000

# 服务器返回音频帧大小：采样率 24kHz × 帧时长 60ms = 1440 个采样点
SERVER_SAMPLES_PER_FRAME = config.SERVER_SAMPLE_RATE * config.OPUS_FRAME_DURATION_MS // 1000


class OpusDecoder:
    """
    Opus 解码器：将 Opus 编码数据解码为 PCM 16-bit 音频

    Attributes:
        decoder: opuslib 解码器实例
        sample_rate: 采样率（默认 16000）
        channels: 声道数（默认 1）
    """

    def __init__(self, sample_rate: int = config.OPUS_SAMPLE_RATE, channels: int = 1):
        try:
            import opuslib
            self.decoder = opuslib.Decoder(sample_rate, channels)
            self.sample_rate = sample_rate
            self.channels = channels
        except ImportError:
            logger.error("opuslib 未安装，请运行: pip install opuslib")
            raise

    def decode(self, opus_data: bytes) -> bytes:
        """
        解码一帧 Opus 数据为 PCM

        Args:
            opus_data: Opus 编码的音频帧

        Returns:
            PCM 16-bit 音频数据（bytes）
        """
        try:
            pcm_data = self.decoder.decode(opus_data, SAMPLES_PER_FRAME)
            return pcm_data
        except Exception as e:
            logger.error(f"Opus 解码失败: {e}")
            return b""


class OpusEncoder:
    """
    Opus 编码器：将 PCM 16-bit 音频编码为 Opus

    Attributes:
        encoder: opuslib 编码器实例
        sample_rate: 采样率（默认 24000，服务器返回音频）
        channels: 声道数（默认 1）
    """

    def __init__(self, sample_rate: int = config.SERVER_SAMPLE_RATE, channels: int = 1):
        try:
            import opuslib
            self.encoder = opuslib.Encoder(sample_rate, channels, opuslib.APPLICATION_AUDIO)
            self.sample_rate = sample_rate
            self.channels = channels
        except ImportError:
            logger.error("opuslib 未安装，请运行: pip install opuslib")
            raise

    def encode(self, pcm_data: bytes) -> bytes:
        """
        编码 PCM 数据为 Opus 帧

        Args:
            pcm_data: PCM 16-bit 音频数据

        Returns:
            Opus 编码的音频帧
        """
        try:
            opus_data = self.encoder.encode(pcm_data, SERVER_SAMPLES_PER_FRAME)
            return opus_data
        except Exception as e:
            logger.error(f"Opus 编码失败: {e}")
            return b""
