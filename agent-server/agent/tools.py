"""
MCP 工具定义

将 ESP32 设备支持的 MCP 工具封装为 LangChain Tool，
使 LLM Agent 能够控制机器人硬件。
"""

import json
import logging
from typing import Optional, Callable, Awaitable

from langchain_core.tools import tool

logger = logging.getLogger("tools")

# 电机控制命令映射
MOTOR_ACTIONS = {
    "move_forward": "前进",
    "move_backward": "后退",
    "turn_left": "左转",
    "turn_right": "右转",
    "spin_around": "转圈",
    "quick_forward": "快速前进",
    "quick_backward": "快速后退",
    "stop": "停止",
    "wake_up": "唤醒动作",
    "happy": "开心动作",
    "sad": "难过动作",
    "thinking": "思考动作",
    "wiggle": "摇摆",
    "dance": "跳舞",
    "excited": "兴奋动作",
    "loving": "喜爱动作",
    "angry": "生气动作",
    "surprised": "惊讶动作",
    "confused": "困惑动作",
}

# 用于存储设备 WebSocket 发送回调（运行时注入）
_mcp_sender: Optional[Callable[[str], Awaitable[None]]] = None


def set_mcp_sender(sender: Callable[[str], Awaitable[None]]):
    """注入 MCP 消息发送回调（由 WebSocket 服务器调用）"""
    global _mcp_sender
    _mcp_sender = sender


async def _send_mcp(name: str, arguments: dict) -> str:
    """
    发送 MCP 工具调用消息到设备

    Args:
        name: 工具名称（如 self.motor.dance）
        arguments: 工具参数

    Returns:
        执行结果描述
    """
    if _mcp_sender is None:
        return "设备未连接，无法执行控制命令"

    message = json.dumps({
        "type": "mcp",
        "payload": {
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": name,
                "arguments": arguments
            }
        }
    })

    try:
        await _mcp_sender(message)
        return f"已执行: {name}"
    except Exception as e:
        logger.error(f"MCP 发送失败: {e}")
        return f"执行失败: {e}"


@tool
async def motor_control(action: str) -> str:
    """
    控制机器人电机执行指定动作

    Args:
        action: 动作名称，可选值：move_forward, move_backward, turn_left, turn_right,
                spin_around, quick_forward, quick_backward, stop, wake_up, happy, sad,
                thinking, wiggle, dance, excited, loving, angry, surprised, confused
    """
    if action not in MOTOR_ACTIONS:
        return f"未知动作: {action}，可用动作: {', '.join(MOTOR_ACTIONS.keys())}"

    result = await _send_mcp(f"self.motor.{action}", {})
    return result


@tool
async def set_volume(volume: int) -> str:
    """
    设置机器人音量

    Args:
        volume: 音量值 0-100
    """
    if not 0 <= volume <= 100:
        return "音量范围为 0-100"

    result = await _send_mcp("self.audio_speaker.set_volume", {"volume": volume})
    return result


@tool
async def get_device_status() -> str:
    """获取机器人当前状态信息（音量、电池、网络等）"""
    result = await _send_mcp("self.get_device_status", {})
    return result


@tool
async def reboot_device() -> str:
    """重启机器人设备"""
    result = await _send_mcp("self.reboot", {})
    return result


# 所有可用工具列表
TOOLS = [motor_control, set_volume, get_device_status, reboot_device]
