"""
BinaryProtocol3 帧编解码模块

帧格式（packed）：
  [type:1B][reserved:1B][payload_size:2B(big-endian)][payload...]

type=0 表示 Opus 音频帧
"""

import struct
from typing import Optional

# 帧头大小：1(type) + 1(reserved) + 2(payload_size) = 4 字节
HEADER_SIZE = 4

# 消息类型
FRAME_TYPE_OPUS = 0


def encode_opus_frame(payload: bytes) -> bytes:
    """
    将 Opus 编码数据封装为 BinaryProtocol3 二进制帧

    Args:
        payload: Opus 编码后的音频数据

    Returns:
        完整的 BinaryProtocol3 帧（header + payload）
    """
    payload_size = len(payload)
    header = struct.pack(">BBH", FRAME_TYPE_OPUS, 0, payload_size)
    return header + payload


def decode_frame(data: bytes) -> Optional[bytes]:
    """
    解析 BinaryProtocol3 二进制帧，提取 payload

    Args:
        data: 原始二进制帧数据

    Returns:
        解析后的 payload 数据，帧格式无效时返回 None
    """
    if len(data) < HEADER_SIZE:
        return None

    frame_type, reserved, payload_size = struct.unpack(">BBH", data[:HEADER_SIZE])

    if len(data) < HEADER_SIZE + payload_size:
        return None

    return data[HEADER_SIZE: HEADER_SIZE + payload_size]


def is_opus_frame(data: bytes) -> bool:
    """
    判断二进制帧是否为 Opus 音频帧

    Args:
        data: 原始二进制帧数据

    Returns:
        True 表示是 Opus 帧，False 表示不是
    """
    if len(data) < HEADER_SIZE:
        return False
    frame_type = data[0]
    return frame_type == FRAME_TYPE_OPUS
