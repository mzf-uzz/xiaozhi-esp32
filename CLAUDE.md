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
- `main/application.cc` — 核心 Application 类（~80KB），协调音频、显示、协议、OTA、MCP、Web 服务器、电机控制

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

### MCP 服务

`McpServer`（单例）注册工具供大模型调用，工具定义包含名称、描述、属性列表和回调函数。属性支持布尔/整数/字符串类型，整数可设置范围限制。工具分为两类：
- **Common Tools** — AI 可调用（音量控制、灯光、电机动作等）
- **User Only Tools** — 仅用户端可见（通过 `annotations.audience` 标记）

### Web 控制界面

设备启动后通过浏览器访问板子 IP 地址即可打开控制界面，提供以下 API：
- `GET /` — 主控制页面（电机方向/速度控制、表情设置）
- `POST /api/control` — 电机控制（JSON：`{"direction": 0-8, "speed": 0-100}`）
- `POST /api/motor_action` — 电机动作（带持续时间）
- `GET /api/config` — 获取电机动作配置
- `POST /api/config` — 保存电机动作配置
- `POST /api/servo` — 舵机控制（JSON：`{"action": "neck|left|right|center|wave|nod|shake", "angle": 0-180}`）

### 网络连接

- **WiFi** — 主要连接方式，配网支持 Hotspot / 声波 / BluFi
- **ML307 Cat.1 4G** — 通过 ML307 模块的蜂窝网络备选方案

## 当前项目开发板

本项目主要使用 `qebabe-xiaoche` 开发板（`main/boards/qebabe-xiaoche/`），基于 ESP32-S3-DevKitC-1（WROOM N16R8 模组），新增电机驱动引脚：
- `GPIO18` / `GPIO17` — 左电机前进/后退
- `GPIO14` / `GPIO13` — 右电机前进/后退

### SG90 舵机控制（3路）
- `GPIO9`  — 脖子舵机
- `GPIO11` — 左手舵机
- `GPIO12` — 右手舵机（与左电机前进共用引脚，不同时使用）

舵机使用独立的 LEDC_TIMER_1（50Hz，13位分辨率），不与电机的 LEDC_TIMER_0（20kHz）冲突。

构建时需在 `idf.py menuconfig` 中选择 `QEBABE_XIAOCHE` 板型。

## 添加新开发板

每个板级目录位于 `main/boards/<board-name>/`，需包含：
- `config.h` — 硬件引脚映射（I2S、I2C、GPIO、显示屏）
- `config.json` — 目标芯片和构建变体定义
- `<board>.cc` — 板级初始化代码，使用 `DECLARE_BOARD` 宏注册

参考文档：`docs/custom-board.md`

## 引脚表
引脚号	名称	功能说明
1	GND	电源地
2	3V3	模组供电，只能3.3V，严禁5V输入
3	EN	使能脚；拉低复位，建议上拉到3V3，不能悬空
4	IO4	GPIO4 / ADC1_CH3 / Touch4
5	IO5	GPIO5 / ADC1_CH4 / Touch5
6	IO6	GPIO6 / ADC1_CH5 / Touch6
7	IO7	GPIO7 / ADC1_CH6 / Touch7
8	IO15	GPIO15 / ADC2_CH4
9	IO16	GPIO16 / ADC2_CH5
10	IO17	GPIO17 / ADC2_CH6
11	IO18	GPIO18 / ADC2_CH7
12	IO8	GPIO8 / ADC1_CH7 / Touch8
13	IO19	GPIO19 / USB_D-
14	IO20	GPIO20 / USB_D+
15	IO3	GPIO3 / ADC1_CH2 / Touch3
16	IO46	GPIO46（仅输入）
17	IO9	GPIO9 / ADC1_CH8 / Touch9
18	IO10	GPIO10 / ADC1_CH9 / Touch10
19	IO11	GPIO11 / ADC2_CH10 / Touch11
20	IO12	GPIO12 / ADC2_CH11 / Touch12
21	IO13	GPIO13 / ADC2_CH12 / Touch13
22	IO14	GPIO14 / ADC2_CH13 / Touch14
23	IO21	GPIO21
24	IO47	GPIO47
25	IO48	GPIO48
26	IO45	GPIO45
27	IO44	GPIO44
28	IO43	GPIO43
29	IO42	GPIO42
30	IO41	GPIO41
31	IO40	GPIO40
32	IO39	GPIO39
33	IO38	GPIO38
34	IO37	GPIO37
35	IO36	GPIO36（PSRAM信号，不建议用作普通IO）
36	IO35	GPIO35（PSRAM信号，不建议用作普通IO）
37	IO34	GPIO34（PSRAM信号，不建议用作普通IO）
38	IO33	GPIO33（PSRAM信号，不建议用作普通IO）
39	IO32	GPIO32（PSRAM信号，不建议用作普通IO）
40	IO2	GPIO2 / ADC1_CH1 / Touch2

## 配置系统

- `main/Kconfig.projbuild` — 主配置菜单（开发板类型、语言、显示屏、唤醒词、WiFi 配网方式等）
- `sdkconfig.defaults` — 全局默认 SDK 配置
- `sdkconfig.defaults.<chip>` — 芯片特定配置（esp32s3）
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
