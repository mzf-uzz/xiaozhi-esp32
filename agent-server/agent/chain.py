"""
LangChain 对话链

构建基于小米 Token Plan API 的 LLM Agent，
集成工具调用和对话记忆。
"""

import json
import logging
from typing import Optional, Tuple

from langchain_openai import ChatOpenAI
from langchain_core.messages import BaseMessage

import config
from .tools import TOOLS
from .memory import memory_manager

logger = logging.getLogger("chain")


def create_llm() -> ChatOpenAI:
    """
    创建 LLM 实例（小米 Token Plan API）

    Returns:
        配置好的 ChatOpenAI 实例
    """
    return ChatOpenAI(
        model=config.XIAOMI_LLM_MODEL,
        openai_api_key=config.XIAOMI_API_KEY,
        openai_api_base=config.XIAOMI_BASE_URL,
        temperature=0.7,
        max_tokens=500,
    )


# 全局 LLM 实例（带工具绑定）
_llm_with_tools: Optional[ChatOpenAI] = None


def get_llm_with_tools() -> ChatOpenAI:
    """获取绑定了工具的 LLM 实例（懒加载单例）"""
    global _llm_with_tools
    if _llm_with_tools is None:
        llm = create_llm()
        _llm_with_tools = llm.bind_tools(TOOLS)
    return _llm_with_tools


async def chat(device_id: str, user_text: str) -> Tuple[str, str, list]:
    """
    与设备进行一轮对话

    Args:
        device_id: 设备标识
        user_text: 用户输入文本

    Returns:
        (回复文本, 情感状态, 工具调用列表)
    """
    memory = memory_manager.get_or_create(device_id)
    memory.add_user_message(user_text)

    llm = get_llm_with_tools()
    messages = memory.get_messages()

    try:
        response = await llm.ainvoke(messages)
        response_text = response.content

        # 解析 JSON 格式的回复
        text, emotion = _parse_response(response_text)

        # 提取工具调用
        tool_calls = []
        if hasattr(response, "tool_calls") and response.tool_calls:
            for tc in response.tool_calls:
                tool_calls.append({
                    "name": tc["name"],
                    "arguments": tc["args"]
                })

        memory.add_ai_message(response_text)

        logger.info(f"[{device_id}] AI 回复: {text}, emotion={emotion}, tools={len(tool_calls)}")
        return text, emotion, tool_calls

    except Exception as e:
        logger.error(f"LLM 调用失败: {e}")
        error_msg = "抱歉，我暂时无法回答，请稍后再试。"
        memory.add_ai_message(error_msg)
        return error_msg, "sad", []


def _parse_response(response_text: str) -> Tuple[str, str]:
    """
    解析 LLM 回复，提取文本和情感

    Args:
        response_text: LLM 的原始回复

    Returns:
        (回复文本, 情感状态)
    """
    try:
        # 尝试解析 JSON 格式
        data = json.loads(response_text)
        text = data.get("text", response_text)
        emotion = data.get("emotion", "happy")
        return text, emotion
    except (json.JSONDecodeError, TypeError):
        # JSON 解析失败，直接使用原始文本
        return response_text, "happy"
