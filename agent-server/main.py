"""
小智桌面机器人 Agent 大脑 — 主入口

同时启动 OTA 配置服务器（HTTP）和 WebSocket Agent 服务器。
设备启动时会请求 OTA 服务器获取连接配置，然后连接到 WebSocket 服务器进行对话。

使用方法：
    1. 修改 .env 文件填入 API Key 和服务器地址
    2. pip install -r requirements.txt
    3. python main.py

ESP32 设备侧：
    修改 CONFIG_OTA_URL 为 http://{你的IP}:8080/xiaozhi/ota/ 后重新编译烧录
"""

import asyncio
import logging
import sys

import uvicorn

import config
from ota_server import app as ota_app
from ws_server import start_ws_server

# ─── 日志配置 ─────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("main")


async def main():
    """并发启动 OTA 和 WebSocket 服务"""

    # 检查 API Key 配置
    if not config.XIAOMI_API_KEY or config.XIAOMI_API_KEY == "your-api-key-here":
        logger.warning("=" * 60)
        logger.warning("未配置 XIAOMI_API_KEY！ASR/TTS/LLM 功能将不可用。")
        logger.warning("请在 .env 文件中填入你的 API Key。")
        logger.warning("=" * 60)

    logger.info("=" * 60)
    logger.info("小智桌面机器人 Agent 大脑")
    logger.info(f"  OTA 服务器:  http://0.0.0.0:{config.OTA_PORT}/xiaozhi/ota/")
    logger.info(f"  WS  服务器:  ws://0.0.0.0:{config.WS_PORT}/ws")
    logger.info(f"  API Base:    {config.XIAOMI_BASE_URL}")
    logger.info(f"  LLM Model:   {config.XIAOMI_LLM_MODEL}")
    logger.info(f"  Server Host: {config.SERVER_HOST}")
    logger.info("=" * 60)

    # 创建 OTA HTTP 服务器
    ota_server = uvicorn.Server(uvicorn.Config(
        app=ota_app,
        host="0.0.0.0",
        port=config.OTA_PORT,
        log_level="info",
    ))

    # 启动 WebSocket 服务器
    ws_server = await start_ws_server()

    # 并发运行 OTA HTTP 服务器
    await ota_server.serve()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("服务器已停止")
        sys.exit(0)
