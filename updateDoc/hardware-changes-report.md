# 小智桌面机器人 — 硬件更改报告

> 生成日期：2026-09-10
> 项目版本：v2.1.0
> 目标芯片：ESP32-S3

---

## 一、概述

本报告记录了小智桌面机器人（qebabe-xiaoche）相对于原版小智 AI 聊天机器人项目所做的全部硬件相关更改。核心变更是在原有语音交互功能基础上，新增了 **L298N 电机驱动模块** 控制两个 N20 减速电机（轮子），实现了机器人的移动和情感动作表达。

---

## 二、硬件清单

### 2.1 基础硬件（与原版相同）

| 硬件 | 型号/规格 | 用途 |
|------|----------|------|
| 开发板 | ESP32-S3-DevKitC-1（WROOM N16R8） | 主控 |
| 数字麦克风 | INMP441 / ICS43434 | 语音输入 |
| 功放 | MAX98357A | 音频输出 |
| 喇叭 | 8Ω 2~3W 或 4Ω 2~3W | 语音播放 |
| 显示屏 | SSD1306 128x32/64 OLED（I2C） | 状态显示 |
| 按键 | 6×6mm 轻触开关 × 4 | BOOT/触摸/音量+/音量- |

### 2.2 新增硬件（桌面机器人扩展）

| 硬件 | 型号/规格 | 用途 |
|------|----------|------|
| 电机驱动模块 | 迷你 L298N（TC1508） | 驱动两个 N20 电机 |
| N20 减速电机 | 带轮子 × 2 | 机器人移动 |
| 导线 | 杜邦线若干 | 电机与 ESP32 连接 |

---

## 三、GPIO 引脚分配

### 3.1 音频引脚（I2S Simplex 模式）

| 功能 | GPIO | 说明 |
|------|------|------|
| MIC_WS | GPIO_4 | 麦克风字选择 |
| MIC_SCK | GPIO_5 | 麦克风时钟 |
| MIC_DIN | GPIO_6 | 麦克风数据输入 |
| SPK_DOUT | GPIO_7 | 喇叭数据输出 |
| SPK_BCLK | GPIO_15 | 喇叭位时钟 |
| SPK_LRCK | GPIO_16 | 喇叭字时钟 |

### 3.2 显示屏引脚（I2C）

| 功能 | GPIO | 说明 |
|------|------|------|
| SDA | GPIO_41 | I2C 数据线 |
| SCL | GPIO_42 | I2C 时钟线 |

### 3.3 按键引脚

| 功能 | GPIO | 说明 |
|------|------|------|
| BOOT_BUTTON | GPIO_0 | 启动/配网按键 |
| TOUCH_BUTTON | GPIO_47 | 触摸按键（长按说话） |
| VOLUME_UP | GPIO_40 | 音量+ |
| VOLUME_DOWN | GPIO_39 | 音量- |

### 3.4 其他引脚

| 功能 | GPIO | 说明 |
|------|------|------|
| BUILTIN_LED | GPIO_48 | 板载 LED |
| LAMP | GPIO_18 | MCP 控制灯 |

### 3.5 ⭐ 新增电机引脚

| 功能 | GPIO | 说明 |
|------|------|------|
| MOTOR_LF | **GPIO_12** | 左轮前进 |
| MOTOR_LB | **GPIO_13** | 左轮后退 |
| MOTOR_RF | **GPIO_14** | 右轮前进 |
| MOTOR_RB | **GPIO_21** | 右轮后退（原为 GPIO_3，因 strapping pin 问题改为 GPIO_21） |

> 接线方式：ESP32 GPIO → L298N 输入端 → L298N 输出端 → N20 电机

---

## 四、固件代码更改

### 4.1 新增文件

| 文件路径 | 说明 |
|----------|------|
| `main/boards/qebabe-xiaoche/config.h` | 板级引脚配置（含电机 GPIO 定义） |
| `main/boards/qebabe-xiaoche/config.json` | 构建变体定义（esp32s3, 128x32/128x64） |
| `main/boards/qebabe-xiaoche/compact_wifi_board.cc` | 板级初始化 + 电机控制 + MCP 工具注册 |
| `main/boards/qebabe-xiaoche/compact_wifi_board.h` | 板级类声明 |
| `main/web_server/web_server.cc` | HTTP Web 控制服务器（含嵌入式 HTML 遥控器页面） |
| `main/web_server/web_server.h` | Web 服务器接口 |

### 4.2 修改的文件

| 文件路径 | 修改内容 |
|----------|----------|
| `main/application.h` | 新增 `MotorActionConfig` 结构体、电机控制方法声明 |
| `main/application.cc` | 新增电机控制任务、情感驱动、PWM 系统、Web 电机控制处理 |
| `main/Kconfig.projbuild` | OTA URL 默认值改为自建服务器地址 |
| `main/boards/common/board.h` | 无直接修改，通过继承扩展 |

### 4.3 OTA 地址变更

```diff
- default "https://api.tenclass.net/xiaozhi/ota/"
+ default "http://192.168.31.181:8080/xiaozhi/ota/"
```

> 此更改使设备启动后连接到自建的 LangChain Agent 服务器，而非官方服务器。

---

## 五、电机控制系统

### 5.1 驱动方式

使用 ESP32 LEDC PWM 控制 L298N 电机驱动模块：
- 4 个 GPIO 分别控制左前、左后、右前、右后
- PWM 频率和分辨率通过 `ledc_timer_config` / `ledc_channel_config` 配置
- 速度通过 PWM 占空比控制（0-100%）

### 5.2 电机动作配置结构体

```cpp
struct MotorActionConfig {
    int forward_duration_ms = 5000;        // 前进时长
    int backward_duration_ms = 5000;       // 后退时长
    int left_turn_duration_ms = 600;       // 左转时长（约 90°）
    int right_turn_duration_ms = 600;      // 右转时长（约 90°）
    int spin_duration_ms = 2500;           // 转圈时长
    int wiggle_duration_ms = 600;          // 摇摆时长
    int dance_duration_ms = 1500;          // 跳舞时长
    int quick_forward_duration_ms = 5000;  // 快速前进时长
    int quick_backward_duration_ms = 5000; // 快速后退时长
    int default_speed_percent = 100;       // 默认速度百分比
};
```

### 5.3 基本移动动作

| 方向编码 | 动作 | MCP 工具名 | 默认时长 |
|---------|------|-----------|---------|
| 0 | 停止 | `self.motor.stop` | — |
| 1 | 右转 | `self.motor.turn_right` | 600ms |
| 2 | 后退 | `self.motor.move_backward` | 5000ms |
| 3 | 左转 | `self.motor.turn_left` | 600ms |
| 4 | 前进 | `self.motor.move_forward` | 5000ms |

### 5.4 特殊动作

| MCP 工具名 | 动作描述 | 实现方式 |
|-----------|---------|---------|
| `self.motor.spin_around` | 原地转圈 | 左转 2000ms |
| `self.motor.quick_forward` | 快速前进 | 前进 500ms |
| `self.motor.quick_backward` | 快速后退 | 后退 500ms |
| `self.motor.wiggle` | 摇摆 | 右转 300ms |
| `self.motor.dance` | 跳舞（8 步序列） | 前进→左转→右转→后退→前进→左转→右转→前进 |

### 5.5 舞蹈序列详情

```
步骤 1: 前进 300ms（80% 速度）
步骤 2: 左转 250ms
步骤 3: 右转 250ms
步骤 4: 后退 300ms
步骤 5: 前进 200ms
步骤 6: 左转 200ms
步骤 7: 右转 200ms
步骤 8: 前进 400ms（结束动作）
```

---

## 六、情感电机动作系统

当 AI 回复中包含 `emotion` 字段时，电机会自动执行对应的情感动作。

### 6.1 情感动作映射表

| emotion 值 | 情感描述 | 电机动作 | 动作详情 |
|-----------|---------|---------|---------|
| `happy` / `joy` | 开心 | 前进 + 左转 | 前进 200ms → 等待 100ms → 左转 200ms |
| `sad` / `unhappy` | 难过 | 缓慢后退 | 后退 400ms |
| `thinking` | 思考 | 轻微左右转 | 左转 150ms → 等待 200ms → 右转 150ms |
| `listening` / `curious` | 倾听 | 轻柔左右转 | 左转 100ms → 等待 150ms → 右转 100ms |
| `speaking` / `talking` | 说话 | 前进 | 前进 250ms |
| `excited` | 兴奋 | 快速三连动 | 前进 150ms → 左转 150ms → 右转 150ms |
| `loving` | 喜爱 | 温柔前进 + 左转 | 前进 300ms → 等待 200ms → 左转 200ms |
| `angry` | 生气 | 后退 + 前冲 | 后退 200ms → 等待 100ms → 前进 200ms |
| `surprised` | 惊讶 | 快速后退 + 前进 | 后退 100ms → 等待 150ms → 前进 200ms |
| `confused` | 困惑 | 犹豫多段动 | 左转 100ms → 等待 200ms → 右转 100ms → 等待 200ms → 左转 100ms |
| `wake` / `wakeup` | 唤醒 | 兴奋前进 | 前进 300ms |

### 6.2 空闲随机动作

设备空闲时有 **5% 概率** 触发随机方向的短暂移动（60% 速度，500ms），增加机器人的"生命感"。

---

## 七、Web 控制服务器

### 7.1 HTTP API 路由

| 方法 | URI | 功能 |
|------|-----|------|
| GET | `/` | 遥控器主页面（嵌入式 HTML） |
| GET | `/config` | 电机动作配置页面 |
| POST | `/control` | 简单格式电机控制（`direction=X,speed=Y`） |
| POST | `/api/control` | JSON 格式电机控制 |
| POST | `/api/motor/action` | 预设动作执行 |
| POST | `/api/debug/motor_test` | 调试电机测试 |
| GET | `/api/config` | 获取电机动作配置 |
| POST | `/api/config` | 保存电机动作配置 |

### 7.2 Web 遥控器功能

- **虚拟摇杆**：触摸/拖拽控制方向和速度
- **停止按钮**：立即停止电机
- **基本移动**：前进/后退/左转/右转/转圈
- **情感表达**：唤醒/开心/悲伤/思考/倾听/说话/摇摆/跳舞
- **高级情感**：兴奋/爱慕/生气/惊讶/困惑
- **配置页面**：调整各动作时长和默认速度

---

## 八、MCP 工具列表

### 8.1 通用工具（所有板子共有）

| 工具名 | 功能 |
|--------|------|
| `self.get_device_status` | 获取设备状态 |
| `self.audio_speaker.set_volume` | 设置音量（0-100） |
| `self.screen.set_brightness` | 设置屏幕亮度 |
| `self.screen.set_theme` | 设置主题 |

### 8.2 用户专用工具（AI 不可见）

| 工具名 | 功能 |
|--------|------|
| `self.get_system_info` | 获取系统信息 |
| `self.reboot` | 重启设备 |
| `self.upgrade_firmware` | 固件升级 |

### 8.3 ⭐ 桌面机器人专用电机工具

| 工具名 | 参数 | 功能 |
|--------|------|------|
| `self.motor.move_forward` | speed_percent(0-100), duration_ms | 前进 |
| `self.motor.move_backward` | speed_percent(0-100), duration_ms | 后退 |
| `self.motor.turn_left` | speed_percent(0-100), duration_ms | 左转 |
| `self.motor.turn_right` | speed_percent(0-100), duration_ms | 右转 |
| `self.motor.spin_around` | speed_percent(0-100) | 原地转圈 |
| `self.motor.quick_forward` | speed_percent(0-100) | 快速前进 |
| `self.motor.quick_backward` | speed_percent(0-100) | 快速后退 |
| `self.motor.wiggle` | speed_percent(0-100) | 摇摆 |
| `self.motor.dance` | speed_percent(0-100) | 跳舞（8 步） |
| `self.motor.stop` | — | 停止 |
| `self.motor.wake_up` | — | 唤醒动作 |
| `self.motor.happy` | — | 开心动作 |
| `self.motor.sad` | — | 难过动作 |
| `self.motor.thinking` | — | 思考动作 |
| `self.motor.listening` | — | 倾听动作 |
| `self.motor.speaking` | — | 说话动作 |
| `self.motor.excited` | — | 兴奋动作 |
| `self.motor.loving` | — | 爱慕动作 |
| `self.motor.angry` | — | 生气动作 |
| `self.motor.surprised` | — | 惊讶动作 |
| `self.motor.confused` | — | 困惑动作 |
| `self.network.get_ip` | — | 获取 IP 地址 |

---

## 九、Agent 服务器（Python 后端）

### 9.1 新增目录结构

```
agent-server/
├── main.py              # 主入口
├── config.py            # 配置管理
├── protocol.py          # BinaryProtocol3 帧编解码
├── ota_server.py        # OTA 配置分发（端口 8080）
├── ws_server.py         # WebSocket Agent 服务（端口 8765）
├── agent/               # LangChain 对话链
├── audio/               # Opus 编解码 + ASR + TTS
├── start.bat            # Windows 启动脚本
├── requirements.txt     # Python 依赖
└── .env                 # API Key 配置
```

### 9.2 技术栈

| 组件 | 技术 |
|------|------|
| Web 框架 | FastAPI + Uvicorn |
| WebSocket | websockets 库 |
| AI 框架 | LangChain + LangChain-OpenAI |
| LLM/ASR/TTS | 小米 Token Plan API（兼容 OpenAI 格式） |
| 音频编解码 | opuslib（需 libopus 动态库） |
| Conda 环境 | xiaozhi-agent (Python 3.11) |

### 9.3 API 配置

```env
XIAOMI_API_KEY=<已配置>
XIAOMI_BASE_URL=https://token-plan-cn.xiaomimimo.com/v1
XIAOMI_LLM_MODEL=mimo-v2.5-pro
XIAOMI_TTS_MODEL=mimo-v2.5-tts
XIAOMI_TTS_VOICE=mimo-v2.5-tts-voicedesign
XIAOMI_ASR_MODEL=mimo-v2.5-asr
SERVER_HOST=192.168.31.181
```

---

## 十、接线参考

### 10.1 ESP32 → L298N 电机驱动

```
ESP32-S3          L298N
─────────         ─────
GPIO_12  ──────►  IN1（左轮前进）
GPIO_13  ──────►  IN2（左轮后退）
GPIO_14  ──────►  IN3（右轮前进）
GPIO_21  ──────►  IN4（右轮后退）
GND      ──────►  GND
5V/VIN   ──────►  VCC（电机电源）
```

### 10.2 L298N → N20 电机

```
L298N             N20 电机（左）
──────            ─────────────
OUT1  ──────►  电机线 +
OUT2  ──────►  电机线 -

L298N             N20 电机（右）
──────            ─────────────
OUT3  ──────►  电机线 +
OUT4  ──────►  电机线 -
```

---

## 十一、已知问题与注意事项

1. **GPIO_3 → GPIO_21**：原设计使用 GPIO_3 控制右轮后退，因 ESP32-S3 的 strapping pin 问题已改为 GPIO_21
2. **电机电源**：L298N 需要独立的电机电源（建议 5V-12V），不要仅依赖 ESP32 的 5V 引脚
3. **PWM 频率**：LEDC PWM 频率需根据电机特性调整，过高可能导致电机不转
4. **Agent 服务器**：需要在 `.env` 中配置正确的 API Key 才能使用 LLM/ASR/TTS 功能
5. **opuslib 依赖**：Windows 下需将 `opus.dll` 所在目录加入 PATH 环境变量
