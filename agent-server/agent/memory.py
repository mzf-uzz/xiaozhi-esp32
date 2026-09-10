"""
对话记忆管理

为每个设备维护独立的对话历史，支持多设备并发连接。
"""

import logging
from typing import Dict, List

from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage

from .prompts import SYSTEM_PROMPT

logger = logging.getLogger("memory")

# 每个设备的最大对话轮数
MAX_HISTORY_TURNS = 20


class DeviceMemory:
    """
    单个设备的对话记忆

    Attributes:
        device_id: 设备标识（MAC 地址）
        history: 对话历史消息列表
    """

    def __init__(self, device_id: str):
        self.device_id = device_id
        self.history: List[BaseMessage] = [SystemMessage(content=SYSTEM_PROMPT)]
        logger.info(f"创建设备记忆: {device_id}")

    def add_user_message(self, text: str):
        """添加用户消息到历史"""
        self.history.append(HumanMessage(content=text))
        self._trim_history()

    def add_ai_message(self, text: str):
        """添加 AI 回复到历史"""
        self.history.append(AIMessage(content=text))
        self._trim_history()

    def get_messages(self) -> List[BaseMessage]:
        """获取完整对话历史（含系统提示词）"""
        return self.history

    def _trim_history(self):
        """
        裁剪对话历史，保持在最大轮数以内
        保留系统提示词 + 最近 N 轮对话
        """
        if len(self.history) > MAX_HISTORY_TURNS * 2 + 1:
            # 保留系统提示词 + 最近的对话
            self.history = [self.history[0]] + self.history[-(MAX_HISTORY_TURNS * 2):]
            logger.debug(f"设备 {self.device_id} 对话历史已裁剪到 {len(self.history)} 条")


class MemoryManager:
    """
    多设备对话记忆管理器

    为每个连接的设备维护独立的对话上下文。
    """

    def __init__(self):
        self._memories: Dict[str, DeviceMemory] = {}

    def get_or_create(self, device_id: str) -> DeviceMemory:
        """
        获取或创建设备的对话记忆

        Args:
            device_id: 设备标识

        Returns:
            DeviceMemory 实例
        """
        if device_id not in self._memories:
            self._memories[device_id] = DeviceMemory(device_id)
        return self._memories[device_id]

    def remove(self, device_id: str):
        """移除设备的对话记忆"""
        if device_id in self._memories:
            del self._memories[device_id]
            logger.info(f"移除设备记忆: {device_id}")

    def list_devices(self) -> list:
        """列出所有已连接设备"""
        return list(self._memories.keys())


# 全局记忆管理器实例
memory_manager = MemoryManager()
