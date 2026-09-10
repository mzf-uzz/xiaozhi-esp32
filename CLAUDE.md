# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

小智桌面机器人 — 基于 ESP32-S3 的 AI 语音聊天机器人固件，在小智 AI 聊天机器人基础上增加了电机驱动模块（L298N）控制两个轮子。使用大语言模型（千问、DeepSeek 等）通过 MCP 协议进行多设备控制。

## 构建系统

本项目使用 **ESP-IDF** (>= 5.4.0)，不支持 PlatformIO 或 Arduino IDE。

### 常用构建命令

```bash
# 设置目标芯片（首次或切换芯片时）
idf.py set-target esp32s3

# 配置菜单（选择开发板、语言、显示屏等）
idf.py menuconfig

# 编译
idf.py build

# 烧录（需要连接开发板）
idf.py flash

# 烧录并监控串口输出
idf.py flash monitor

# 仅监控串口
idf.py monitor

# 清理构建
idf.py fullclean
```

### 使用 release.py 批量构建

```bash
# 构建指定开发板的所有变体
python scripts/release.py <board-directory-name>

# 构建指定开发板的指定变体
python scripts/release.py <board-directory-name> --name <variant-name>

# 构建所有开发板
python scripts/release.py all

# 列出所有支持的开发板及变体
python scripts/release.py --list-boards

# JSON 格式输出开发板列表
python scripts/release.py --list-boards --json
```

### CI 构建

GitHub Actions 使用 `espressif/idf:release-v5.5` 容器，push 到 `main` 或 PR 时触发。修改 `main/` 核心文件会构建所有 70+ 变体，仅修改特定 board 文件则只构建受影响的板子。

## 架构

### 核心设计模式

- **单例模式**: `Application::GetInstance()` 和 `Board::GetInstance()`
- **工厂模式**: `create_board()` 函数通过 `DECLARE_BOARD` 宏注册板级实现
- **抽象接口**: `Board`、`Protocol`、`AudioCodec`、`Display`、`Led`、`WakeWord`、`AudioProcessor` 均为抽象基类
- **FreeRTOS 事件驱动**: 主循环使用 FreeRTOS 事件组进行状态转换
- **状态机**: `DeviceStateMachine` 管理设备状态（Unknown → Starting → WifiConfiguring → Idle ⇄ Connecting → Listening → Speaking）

### 入口与核心

- `main/main.cc` — `app_main()` 入口，初始化 NVS、LED PWM，创建 `Application` 单例并运行
- `main/application.cc` — 核心 Application 类（~80KB），协调音频、显示、协议、OTA、MCP、Web 服务器

### 子系统分层

```
main/
├── audio/
│   ├── codecs/        # 音频编解码器（ES8311/8374/8388/8389、BOX、NoCodec、Dummy）
│   ├── processors/    # 音频处理器（AFE 降噪、无处理、UDP 调试）
│   └── wake_words/    # 唤醒词检测（AFE/S3&P4、ESP、自定义 Multinet）
├── display/
│   ├── oled_display   # SSD1306/SH1106 OLED（I2C）
│   ├── lcd_display    # LCD 显示（支持多种控制器）
│   └── lvgl_display/  # LVGL 9.x 富图形（主题、字体、表情、GIF）
├── protocols/
│   ├── websocket      # WebSocket 协议（docs/websocket.md）
│   └── mqtt           # MQTT + UDP 混合协议（docs/mqtt-udp.md）
├── boards/            # 113 个板级目录 + common/ 公共抽象层
├── web_server/        # HTTP 远程控制服务器
├── led/               # LED 控制（单灯、灯环、GPIO）
└── third_party/       # 第三方库（adafruit_gfx、roboeyes）
```

### 音频流水线

MIC → AudioProcessor → Opus 编码（16kHz mono, 60ms 帧）→ 发送队列 → 服务器
服务器 → 解码队列 → Opus 解码 → 播放队列 → Speaker

### 通信协议

协议层使用自定义二进制帧（`BinaryProtocol2`/`BinaryProtocol3`），传输 OPUS 音频包和 JSON 控制消息。MCP 服务端运行在设备上，用于控制外设（音量、灯光、电机、GPIO）。

### 网络连接

- **WiFi** — 主要连接方式，配网支持 Hotspot / 声波 / BluFi
- **ML307 Cat.1 4G** — 通过 ML307 模块的蜂窝网络备选方案

## 添加新开发板

每个板级目录位于 `main/boards/<board-name>/`，需包含：
- `config.h` — 硬件引脚映射（I2S、I2C、GPIO、显示屏）
- `config.json` — 目标芯片和构建变体定义
- `<board>.cc` — 板级初始化代码，使用 `DECLARE_BOARD` 宏注册

参考文档：`docs/custom-board.md`

## 配置系统

- `main/Kconfig.projbuild` — 主配置菜单（开发板类型、语言、显示屏、唤醒词、WiFi 配网方式等）
- `sdkconfig.defaults` — 全局默认 SDK 配置
- `sdkconfig.defaults.<chip>` — 芯片特定配置（esp32s3、esp32c3 等）
- `partitions/v2/` — 分区表定义（默认 16MB flash：ota_0 4MB + ota_1 4MB + assets 8MB）

## 多语言支持

30+ 语言通过 Kconfig 选择，语言资源（`.ogg` 音频 + `language.json`）位于 `main/assets/locales/`。构建时 `scripts/gen_lang.py` 从 `language.json` 生成 `lang_config.h`。

## 代码规范

- Google C++ 代码风格
- 主要语言：C++（`.cc`/`.h`），部分 C（`.c` 用于 LVGL/JPEG），Python 用于构建脚本
- 无单元测试框架，验证依赖 CI 构建和手动测试

## 关键依赖

- ESP-IDF >= 5.4.0、LVGL 9.3.x、esp-sr 2.2.x（语音识别）
- esp_audio_codec 2.4.x（音频编解码）、esp-wifi-connect 3.0.x
- 详细依赖见 `main/idf_component.yml`
