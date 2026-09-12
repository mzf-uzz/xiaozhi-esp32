"""
OTA 配置分发服务器

设备启动时会请求 OTA 服务器获取连接配置，
本服务返回 WebSocket 连接信息，引导设备连接到自建的 Agent 服务器。
"""

import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

import config

logger = logging.getLogger("ota")

app = FastAPI(title="Xiaozhi OTA Server")


@app.get("/xiaozhi/ota/")
@app.post("/xiaozhi/ota/")
async def ota_config(request: Request):
    """
    处理设备的 OTA 版本检查请求

    设备会发送以下 Header：
      - Device-Id: MAC 地址
      - Client-Id: UUID
      - User-Agent: {board_name}/{version}

    返回 WebSocket 连接配置，设备会自动连接到指定的 WebSocket 服务器
    """
    device_id = request.headers.get("Device-Id", "unknown")
    client_id = request.headers.get("Client-Id", "unknown")
    user_agent = request.headers.get("User-Agent", "unknown")

    logger.info(f"OTA 请求: Device-Id={device_id}, Client-Id={client_id}, UA={user_agent}")

    ws_url = f"ws://{config.SERVER_HOST}:{config.WS_PORT}/ws"
    ota_url = f"http://{config.SERVER_HOST}:{config.OTA_PORT}/xiaozhi/ota/"

    response = {
        "websocket": {
            "url": ws_url,
            "token": config.DEVICE_TOKEN,
            "version": 3
        },
        "server_time": {
            "timestamp": 0,
            "timezone_offset": 480
        },
        "firmware": {
            "version": "2.1.0",
            "url": f"http://{config.SERVER_HOST}/xiaozhi/firmware/ota.bin"
        }
    }

    logger.info(f"返回配置: {ws_url}")
    return JSONResponse(content=response)
