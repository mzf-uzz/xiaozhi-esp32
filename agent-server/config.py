"""
配置管理模块
从 .env 文件和环境变量中加载所有配置项
"""

import os
from dotenv import load_dotenv

load_dotenv()

# ─── 小米 Token Plan API ────────────────────────────────────────────
XIAOMI_API_KEY: str = os.getenv("XIAOMI_API_KEY", "")
XIAOMI_BASE_URL: str = os.getenv("XIAOMI_BASE_URL", "https://token-plan-cn.xiaomimimo.com/v1")
XIAOMI_LLM_MODEL: str = os.getenv("XIAOMI_LLM_MODEL", "MiLM-v2")
XIAOMI_TTS_MODEL: str = os.getenv("XIAOMI_TTS_MODEL", "tts-1")
XIAOMI_TTS_VOICE: str = os.getenv("XIAOMI_TTS_VOICE", "alloy")
XIAOMI_ASR_MODEL: str = os.getenv("XIAOMI_ASR_MODEL", "whisper-1")

# ─── 服务器端口 ─────────────────────────────────────────────────────
OTA_PORT: int = int(os.getenv("OTA_PORT", "8080"))
WS_PORT: int = int(os.getenv("WS_PORT", "8765"))

# ─── 设备认证 ───────────────────────────────────────────────────────
DEVICE_TOKEN: str = os.getenv("DEVICE_TOKEN", "xiaozhi-agent-token")

# ─── 服务器地址（设备需要能访问到）─────────────────────────────────────
SERVER_HOST: str = os.getenv("SERVER_HOST", "10.140.147.96")

# ─── 音频参数 ───────────────────────────────────────────────────────
OPUS_SAMPLE_RATE: int = 16000       # 设备录音采样率
OPUS_FRAME_DURATION_MS: int = 60    # Opus 帧时长（毫秒）
SERVER_SAMPLE_RATE: int = 24000     # 服务器返回音频采样率
