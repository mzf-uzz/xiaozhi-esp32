# 小智桌面机器人 — 源代码接口文档

本文档梳理了 xiaozhi-esp32 项目中所有核心接口定义，涵盖硬件抽象层、音频处理、通信协议和应用层服务。

---

## 目录

- [一、硬件抽象层接口（HAL）](#一硬件抽象层接口hal)
  - [1. Board — 板级抽象基类](#1-board--板级抽象基类)
  - [2. AudioCodec — 音频编解码器](#2-audiocodec--音频编解码器)
  - [3. Display — 显示抽象接口](#3-display--显示抽象接口)
  - [4. Led — LED 控制接口](#4-led--led-控制接口)
- [二、音频处理接口](#二音频处理接口)
  - [5. WakeWord — 唤醒词检测](#5-wakeword--唤醒词检测)
  - [6. AudioProcessor — 音频处理器](#6-audioprocessor--音频处理器)
- [三、通信协议接口](#三通信协议接口)
  - [7. Protocol — 通信协议抽象](#7-protocol--通信协议抽象)
- [四、应用层核心接口](#四应用层核心接口)
  - [8. Application — 应用核心单例](#8-application--应用核心单例)
  - [9. McpServer — MCP 工具注册框架](#9-mcpserver--mcp-工具注册框架)
  - [10. Settings — NVS 键值存储](#10-settings--nvs-键值存储)
  - [11. Ota — 固件升级](#11-ota--固件升级)
  - [12. DeviceStateMachine — 设备状态机](#12-devicestatemachine--设备状态机)
  - [13. WebServer — HTTP 服务器](#13-webserver--http-服务器)
  - [14. Assets — 资源管理](#14-assets--资源管理)
- [五、接口关系总览](#五接口关系总览)

---

## 一、硬件抽象层接口（HAL）

### 1. Board — 板级抽象基类

**文件路径：** `main/boards/common/board.h`

通过 `DECLARE_BOARD` 宏 + `create_board()` 工厂函数注册，单例访问（`Board::GetInstance()`）。

#### 枚举类型

**`enum class NetworkEvent`** — 网络事件统一回调类型：

| 枚举值 | 说明 |
|--------|------|
| `Scanning` | 网络扫描中 |
| `Connecting` | 网络连接中（data 为 SSID） |
| `Connected` | 网络已连接（data 为 SSID） |
| `Disconnected` | 网络已断开 |
| `WifiConfigModeEnter` | 进入 WiFi 配置模式 |
| `WifiConfigModeExit` | 退出 WiFi 配置模式 |
| `ModemDetecting` | 检测调制解调器（波特率、模块类型） |
| `ModemErrorNoSim` | 未检测到 SIM 卡 |
| `ModemErrorRegDenied` | 网络注册被拒绝 |
| `ModemErrorInitFailed` | 调制解调器初始化失败 |
| `ModemErrorTimeout` | 操作超时 |

**`enum class PowerSaveLevel`** — 省电级别：

| 枚举值 | 说明 |
|--------|------|
| `LOW_POWER` | 最大省电（最低功耗） |
| `BALANCED` | 中等省电（平衡模式） |
| `PERFORMANCE` | 不省电（最大性能） |

#### 纯虚方法（子类必须实现）

| 方法签名 | 说明 |
|----------|------|
| `virtual std::string GetBoardType() = 0` | 返回板型名称字符串 |
| `virtual AudioCodec* GetAudioCodec() = 0` | 返回音频编解码器实例 |
| `virtual NetworkInterface* GetNetwork() = 0` | 返回网络接口实例 |
| `virtual void StartNetwork() = 0` | 启动网络连接 |
| `virtual const char* GetNetworkStateIcon() = 0` | 返回当前网络状态对应的图标字符串 |
| `virtual void SetPowerSaveLevel(PowerSaveLevel level) = 0` | 设置省电级别 |
| `virtual std::string GetBoardJson() = 0` | 返回板级信息的 JSON 字符串 |
| `virtual std::string GetDeviceStatusJson() = 0` | 返回设备状态的 JSON 字符串 |

#### 可选覆写方法

| 方法签名 | 默认行为 | 说明 |
|----------|----------|------|
| `virtual std::string GetUuid()` | 返回软件生成的设备唯一标识 `uuid_` | 设备唯一标识 |
| `virtual Backlight* GetBacklight()` | 返回 `nullptr` | 背光控制对象 |
| `virtual Led* GetLed()` | 返回 `nullptr` | LED 控制对象 |
| `virtual Display* GetDisplay()` | 返回 `nullptr` | 显示设备对象 |
| `virtual Camera* GetCamera()` | 返回 `nullptr` | 摄像头对象 |
| `virtual bool GetTemperature(float& esp32temp)` | 返回 `false` | ESP32 芯片温度 |
| `virtual bool GetBatteryLevel(int& level, bool& charging, bool& discharging)` | 返回 `false` | 电池电量和充放电状态 |
| `virtual std::string GetSystemInfoJson()` | 返回基础 JSON | 系统信息 JSON |
| `virtual void SetNetworkEventCallback(NetworkEventCallback callback)` | 空实现 | 设置网络事件回调 |

#### 已有实现

`WifiBoard`、`Ml307Board`、`DualNetworkBoard` 及 113 个板级目录的具体实现。

---

### 2. AudioCodec — 音频编解码器

**文件路径：** `main/audio/audio_codec.h`

#### Public Virtual 方法

| 方法签名 | 说明 |
|----------|------|
| `virtual void SetOutputVolume(int volume)` | 设置输出音量 |
| `virtual void SetInputGain(float gain)` | 设置输入增益 |
| `virtual void EnableInput(bool enable)` | 启用/禁用音频输入 |
| `virtual void EnableOutput(bool enable)` | 启用/禁用音频输出 |
| `virtual void OutputData(std::vector<int16_t>& data)` | 将 PCM 数据写入输出（播放） |
| `virtual bool InputData(std::vector<int16_t>& data)` | 从输入读取 PCM 数据（录音），返回是否有数据 |
| `virtual void Start()` | 启动编解码器 |

#### Protected 纯虚方法（子类必须实现硬件读写）

| 方法签名 | 说明 |
|----------|------|
| `virtual int Read(int16_t* dest, int samples) = 0` | 从硬件读取指定采样数的 PCM 数据，返回实际读取数 |
| `virtual int Write(const int16_t* data, int samples) = 0` | 向硬件写入指定采样数的 PCM 数据，返回实际写入数 |

#### Inline 访问器方法

| 方法签名 | 说明 |
|----------|------|
| `inline bool duplex() const` | 是否支持全双工 |
| `inline bool input_reference() const` | 是否有输入参考信号（用于 AEC） |
| `inline int input_sample_rate() const` | 输入采样率 |
| `inline int output_sample_rate() const` | 输出采样率 |
| `inline int input_channels() const` | 输入通道数 |
| `inline int output_channels() const` | 输出通道数 |
| `inline int output_volume() const` | 当前输出音量 |
| `inline float input_gain() const` | 当前输入增益 |
| `inline bool input_enabled() const` | 输入是否已启用 |
| `inline bool output_enabled() const` | 输出是否已启用 |

#### 已有实现

`Es8311AudioCodec`、`Es8374AudioCodec`、`Es8388AudioCodec`、`Es8389AudioCodec`、`BoxAudioCodec`、`NoAudioCodec`、`DummyAudioCodec`

---

### 3. Display — 显示抽象接口

**文件路径：** `main/display/display.h`

#### 辅助类

| 类名 | 说明 |
|------|------|
| `Theme` | 主题基类，含 `name()` 访问器 |
| `DisplayLockGuard` | RAII 风格的显示锁守卫，构造时 `Lock(30000)`，析构时 `Unlock()` |
| `NoDisplay` | 空实现子类，`Lock` 直接返回 `true`，`Unlock` 为空操作 |

#### Public Virtual 方法

| 方法签名 | 说明 |
|----------|------|
| `virtual void SetStatus(const char* status)` | 设置状态文本 |
| `virtual void ShowNotification(const char* notification, int duration_ms = 3000)` | 显示通知（C 字符串版本） |
| `virtual void ShowNotification(const std::string& notification, int duration_ms = 3000)` | 显示通知（std::string 重载） |
| `virtual void SetEmotion(const char* emotion)` | 设置当前表情/情绪 |
| `virtual void SetChatMessage(const char* role, const char* content)` | 设置聊天消息（角色 + 内容） |
| `virtual void SetTheme(Theme* theme)` | 设置当前主题 |
| `virtual Theme* GetTheme()` | 获取当前主题指针 |
| `virtual void UpdateStatusBar(bool update_all = false)` | 更新状态栏，可选全量刷新 |
| `virtual void SetPowerSaveMode(bool on)` | 设置省电模式开/关 |
| `virtual void SetAnimatedEmotionMode(bool enable)` | 启用/禁用动画表情模式 |
| `virtual bool IsAnimatedEmotionMode() const` | 查询动画表情模式是否启用 |
| `virtual void SetEmotionDirection(int direction)` | 设置表情方向（0-8: center, up, down, left, right, 四个对角） |
| `virtual void UpdateAnimatedEmotion()` | 更新动画表情帧 |

#### Protected 纯虚方法（线程安全）

| 方法签名 | 说明 |
|----------|------|
| `virtual bool Lock(int timeout_ms = 0) = 0` | 加锁（带超时），用于线程安全的显示操作 |
| `virtual void Unlock() = 0` | 解锁 |

#### Inline 访问器

| 方法签名 | 说明 |
|----------|------|
| `inline int width() const` | 返回屏幕宽度 |
| `inline int height() const` | 返回屏幕高度 |

#### 已有实现

`OledDisplay`、`LcdDisplay`、`LvglDisplay`、`EmoteDisplay`、`NoDisplay`

---

### 4. Led — LED 控制接口

**文件路径：** `main/led/led.h`

最简洁的接口，仅包含 1 个纯虚方法。

| 方法签名 | 说明 |
|----------|------|
| `virtual void OnStateChanged() = 0` | 根据设备状态自动更新 LED 显示 |

#### 已有实现

`SingleLed`、`CircularStripLed`、`NoLed`（空实现）

---

## 二、音频处理接口

### 5. WakeWord — 唤醒词检测

**文件路径：** `main/audio/wake_word.h`

#### 纯虚方法（全部为纯虚，完全抽象接口）

| 方法签名 | 说明 |
|----------|------|
| `virtual bool Initialize(AudioCodec* codec, srmodel_list_t* models_list) = 0` | 初始化唤醒词检测器，传入音频编解码器和语音识别模型列表 |
| `virtual void Feed(const std::vector<int16_t>& data) = 0` | 喂入 PCM 音频数据供唤醒词检测 |
| `virtual void OnWakeWordDetected(std::function<void(const std::string& wake_word)> callback) = 0` | 注册唤醒词检测到时的回调，参数为检测到的唤醒词文本 |
| `virtual void Start() = 0` | 启动唤醒词检测 |
| `virtual void Stop() = 0` | 停止唤醒词检测 |
| `virtual size_t GetFeedSize() = 0` | 获取每次 Feed 需要的采样数大小 |
| `virtual void EncodeWakeWordData() = 0` | 将唤醒词音频数据编码（用于发送给服务器验证） |
| `virtual bool GetWakeWordOpus(std::vector<uint8_t>& opus) = 0` | 获取编码后的唤醒词 Opus 数据 |
| `virtual const std::string& GetLastDetectedWakeWord() const = 0` | 获取最后一次检测到的唤醒词文本 |

#### 已有实现

| 实现类 | 适用平台 | 说明 |
|--------|----------|------|
| `AfeWakeWord` | ESP32-S3 / ESP32-P4（需 PSRAM） | 基于 AFE 的唤醒词检测 |
| `EspWakeWord` | ESP32 / ESP32-C3 / C5 / C6 | ESP 标准唤醒词检测 |
| `CustomWakeWord` | 通用 | 通过 Multinet 实现的自定义唤醒词 |

---

### 6. AudioProcessor — 音频处理器

**文件路径：** `main/audio/audio_processor.h`

#### 纯虚方法（全部为纯虚，完全抽象接口）

| 方法签名 | 说明 |
|----------|------|
| `virtual void Initialize(AudioCodec* codec, int frame_duration_ms, srmodel_list_t* models_list) = 0` | 初始化音频处理器，传入编解码器、帧时长（ms）和模型列表 |
| `virtual void Feed(std::vector<int16_t>&& data) = 0` | 喂入 PCM 音频数据（右值引用，避免拷贝） |
| `virtual void Start() = 0` | 启动音频处理 |
| `virtual void Stop() = 0` | 停止音频处理 |
| `virtual bool IsRunning() = 0` | 查询处理器是否正在运行 |
| `virtual void OnOutput(std::function<void(std::vector<int16_t>&& data)> callback) = 0` | 注册处理后音频输出回调（经 AEC/NS/VAD 处理后的干净音频） |
| `virtual void OnVadStateChange(std::function<void(bool speaking)> callback) = 0` | 注册 VAD（语音活动检测）状态变化回调 |
| `virtual size_t GetFeedSize() = 0` | 获取每次 Feed 需要的采样数大小 |
| `virtual void EnableDeviceAec(bool enable) = 0` | 启用/禁用设备端 AEC（回声消除） |

#### 已有实现

| 实现类 | 说明 |
|--------|------|
| `AfeAudioProcessor` | 基于 AFE 的音频降噪处理（需 PSRAM） |
| `NoAudioProcessor` | 无处理直通 |
| `AudioDebugger` | UDP 音频调试器 |

---

## 三、通信协议接口

### 7. Protocol — 通信协议抽象

**文件路径：** `main/protocols/protocol.h`

#### 枚举类型

**`enum AbortReason`** — 中止原因：

| 枚举值 | 说明 |
|--------|------|
| `kAbortReasonNone` | 无原因 |
| `kAbortReasonWakeWordDetected` | 检测到唤醒词 |

**`enum ListeningMode`** — 监听模式：

| 枚举值 | 说明 |
|--------|------|
| `kListeningModeAutoStop` | 自动停止监听 |
| `kListeningModeManualStop` | 手动停止监听 |
| `kListeningModeRealtime` | 实时监听（需要 AEC 支持） |

#### 数据结构

**`AudioStreamPacket`** — 音频流数据包：

| 字段 | 类型 | 说明 |
|------|------|------|
| `sample_rate` | `int` | 采样率 |
| `frame_duration` | `int` | 帧时长（ms） |
| `timestamp` | `uint32_t` | 时间戳 |
| `payload` | `std::vector<uint8_t>` | 音频载荷（Opus 编码） |

**`BinaryProtocol2`** — 二进制协议 v2（packed）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | `uint8_t` | 协议版本 |
| `type` | `uint8_t` | 消息类型 |
| `reserved` | `uint16_t` | 保留字段 |
| `timestamp` | `uint32_t` | 时间戳 |
| `payload_size` | `uint32_t` | 载荷大小 |
| `payload[]` | `uint8_t[]` | 载荷数据 |

**`BinaryProtocol3`** — 二进制协议 v3（packed）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | `uint8_t` | 消息类型 |
| `reserved` | `uint8_t` | 保留字段 |
| `payload_size` | `uint16_t` | 载荷大小 |
| `payload[]` | `uint8_t[]` | 载荷数据 |

#### 回调注册方法

| 方法签名 | 说明 |
|----------|------|
| `void OnIncomingAudio(std::function<void(std::unique_ptr<AudioStreamPacket>)> callback)` | 注册接收音频数据包的回调 |
| `void OnIncomingJson(std::function<void(const cJSON* root)> callback)` | 注册接收 JSON 消息的回调 |
| `void OnAudioChannelOpened(std::function<void()> callback)` | 注册音频通道打开事件回调 |
| `void OnAudioChannelClosed(std::function<void()> callback)` | 注册音频通道关闭事件回调 |
| `void OnNetworkError(std::function<void(const std::string&)> callback)` | 注册网络错误事件回调 |
| `void OnConnected(std::function<void()> callback)` | 注册连接成功事件回调 |
| `void OnDisconnected(std::function<void()> callback)` | 注册断开连接事件回调 |

#### Public 纯虚方法

| 方法签名 | 说明 |
|----------|------|
| `virtual bool Start() = 0` | 启动协议（建立底层连接） |
| `virtual bool OpenAudioChannel() = 0` | 打开音频通道 |
| `virtual void CloseAudioChannel() = 0` | 关闭音频通道 |
| `virtual bool IsAudioChannelOpened() const = 0` | 查询音频通道是否已打开 |
| `virtual bool SendAudio(std::unique_ptr<AudioStreamPacket> packet) = 0` | 发送音频数据包到服务器 |

#### Public 非纯虚方法

| 方法签名 | 说明 |
|----------|------|
| `virtual void SendWakeWordDetected(const std::string& wake_word)` | 发送唤醒词检测通知 |
| `virtual void SendStartListening(ListeningMode mode)` | 发送开始监听指令 |
| `virtual void StopListening()` | 发送停止监听指令 |
| `virtual void SendAbortSpeaking(AbortReason reason)` | 发送中止语音指令 |
| `virtual void SendMcpMessage(const std::string& message)` | 发送 MCP 协议消息 |

#### Protected 纯虚方法

| 方法签名 | 说明 |
|----------|------|
| `virtual bool SendText(const std::string& text) = 0` | 发送文本消息到底层传输 |

#### Inline 访问器

| 方法签名 | 说明 |
|----------|------|
| `inline int server_sample_rate() const` | 返回服务器音频采样率（默认 24000） |
| `inline int server_frame_duration() const` | 返回服务器音频帧时长（默认 60ms） |
| `inline const std::string& session_id() const` | 返回当前会话 ID |

#### 已有实现

`WebSocketProtocol`（文档：`docs/websocket.md`）、`MqttProtocol`（文档：`docs/mqtt-udp.md`）

---

## 四、应用层核心接口

### 8. Application — 应用核心单例

**文件路径：** `main/application.h`

通过 `Application::GetInstance()` 获取单例实例，是整个应用的核心协调器。

#### 枚举类型

**`enum AecMode`** — 回声消除模式：

| 枚举值 | 说明 |
|--------|------|
| `kAecOff` | AEC 关闭 |
| `kAecOnDeviceSide` | 设备端 AEC |
| `kAecOnServerSide` | 服务端 AEC |

**`enum DisplayMode`** — 显示模式：

| 枚举值 | 说明 |
|--------|------|
| `kDisplayModeDefault` | 默认模式：显示文字和表情 |
| `kDisplayModeEyeOnly` | 眼睛模式：只显示动画眼睛 |

#### 事件位定义

| 宏定义 | 位 | 说明 |
|--------|------|------|
| `MAIN_EVENT_SCHEDULE` | `1 << 0` | 调度事件 |
| `MAIN_EVENT_SEND_AUDIO` | `1 << 1` | 发送音频事件 |
| `MAIN_EVENT_WAKE_WORD_DETECTED` | `1 << 2` | 唤醒词检测事件 |
| `MAIN_EVENT_VAD_CHANGE` | `1 << 3` | VAD 状态变化事件 |
| `MAIN_EVENT_ERROR` | `1 << 4` | 错误事件 |
| `MAIN_EVENT_ACTIVATION_DONE` | `1 << 5` | 激活完成事件 |
| `MAIN_EVENT_CLOCK_TICK` | `1 << 6` | 时钟滴答事件 |
| `MAIN_EVENT_NETWORK_CONNECTED` | `1 << 7` | 网络连接事件 |
| `MAIN_EVENT_NETWORK_DISCONNECTED` | `1 << 8` | 网络断开事件 |
| `MAIN_EVENT_TOGGLE_CHAT` | `1 << 9` | 切换聊天事件 |
| `MAIN_EVENT_START_LISTENING` | `1 << 10` | 开始监听事件 |
| `MAIN_EVENT_STOP_LISTENING` | `1 << 11` | 停止监听事件 |
| `MAIN_EVENT_STATE_CHANGED` | `1 << 12` | 状态变更事件 |

#### 电机动作配置结构体

```cpp
struct MotorActionConfig {
    int forward_duration_ms = 5000;        // 前进时长
    int backward_duration_ms = 5000;       // 后退时长
    int left_turn_duration_ms = 600;       // 左转时长
    int right_turn_duration_ms = 600;      // 右转时长
    int spin_duration_ms = 2500;           // 旋转时长
    int wiggle_duration_ms = 600;          // 摇摆时长
    int dance_duration_ms = 1500;          // 跳舞时长
    int quick_forward_duration_ms = 5000;  // 快速前进时长
    int quick_backward_duration_ms = 5000; // 快速后退时长
    int default_speed_percent = 100;       // 默认速度百分比
};
```

#### 核心生命周期方法

| 方法签名 | 说明 |
|----------|------|
| `static Application& GetInstance()` | 单例获取全局 Application 实例 |
| `void Initialize()` | 初始化应用，设置显示、音频、网络回调等，网络连接异步启动 |
| `void Run()` | 主事件循环，在主任务中运行且永不返回 |

#### 设备状态管理方法

| 方法签名 | 说明 |
|----------|------|
| `DeviceState GetDeviceState() const` | 获取当前设备状态 |
| `bool SetDeviceState(DeviceState state)` | 请求状态转换，返回是否成功 |
| `bool IsVoiceDetected() const` | 检测是否有人声 |

#### 显示模式方法

| 方法签名 | 说明 |
|----------|------|
| `DisplayMode GetDisplayMode() const` | 获取当前显示模式 |
| `void SetDisplayMode(DisplayMode mode)` | 设置显示模式 |
| `void ToggleDisplayMode()` | 切换显示模式 |

#### 语音交互方法

| 方法签名 | 说明 |
|----------|------|
| `void ToggleChatState()` | 切换聊天状态（线程安全，通过事件驱动） |
| `void StartListening()` | 开始监听（线程安全，通过事件驱动） |
| `void StopListening()` | 停止监听（线程安全，通过事件驱动） |
| `void AbortSpeaking(AbortReason reason)` | 中止语音播放 |
| `void WakeWordInvoke(const std::string& wake_word)` | 唤醒词触发调用 |
| `void PlaySound(const std::string_view& sound)` | 播放指定声音 |

#### 调度与警报方法

| 方法签名 | 说明 |
|----------|------|
| `void Schedule(std::function<void()>&& callback)` | 调度回调在主任务中执行 |
| `void Alert(const char* status, const char* message, const char* emotion = "", const std::string_view& sound = "")` | 发出警报，包含状态、消息、表情和可选声音 |
| `void DismissAlert()` | 关闭/取消警报 |

#### AEC 模式方法

| 方法签名 | 说明 |
|----------|------|
| `void SetAecMode(AecMode mode)` | 设置 AEC（回声消除）模式 |
| `AecMode GetAecMode() const` | 获取当前 AEC 模式 |

#### 电机控制方法（桌面机器人扩展）

| 方法签名 | 说明 |
|----------|------|
| `void TriggerMotorControl()` | 触发电机控制 |
| `void TriggerMotorEmotion(int emotion_type)` | 触发电机表情动作（1-6 对应不同情绪） |
| `void HandleWebMotorControl(int direction, int speed)` | 处理来自 Web 的电机控制 |
| `void HandleMotorActionWithDuration(int direction, int speed, int duration_ms, int priority = 1)` | 处理带时长和优先级的电机动作 |
| `void QueueMotorAction(int direction, int speed, int duration_ms, const std::string& description)` | 将电机动作加入队列 |
| `void ExecuteMotorActionQueue()` | 执行电机动作队列 |
| `void MotorControlTask()` | 电机控制任务（主循环） |

#### 电机配置方法

| 方法签名 | 说明 |
|----------|------|
| `void LoadMotorActionConfig()` | 从存储加载电机动作配置 |
| `void SaveMotorActionConfig()` | 保存电机动作配置到存储 |
| `const MotorActionConfig& GetMotorActionConfig() const` | 获取电机动作配置引用 |
| `void SetMotorActionConfig(const MotorActionConfig& config)` | 设置电机动作配置 |

#### 其他方法

| 方法签名 | 说明 |
|----------|------|
| `void Reboot()` | 重启设备 |
| `bool UpgradeFirmware(const std::string& url, const std::string& version = "")` | 固件升级，传入 URL 和可选版本号 |
| `bool CanEnterSleepMode()` | 检查是否可进入睡眠模式 |
| `void SendMcpMessage(const std::string& payload)` | 发送 MCP 消息 |
| `AudioService& GetAudioService()` | 获取音频服务引用 |
| `void ResetProtocol()` | 重置协议资源（线程安全），释放网络连接后分配的资源 |

---

### 9. McpServer — MCP 工具注册框架

**文件路径：** `main/mcp_server.h`

JSON-RPC 风格的工具注册和调用框架，用于 AI 模型控制设备外设。通过 `McpServer::GetInstance()` 获取单例。

#### 类型定义

```cpp
using ReturnValue = std::variant<bool, int, std::string, cJSON*, ImageContent*>;
```

#### 枚举类型

**`enum PropertyType`** — 属性类型：

| 枚举值 | 说明 |
|--------|------|
| `kPropertyTypeBoolean` | 布尔类型 |
| `kPropertyTypeInteger` | 整数类型 |
| `kPropertyTypeString` | 字符串类型 |

#### 辅助类：ImageContent

| 方法签名 | 说明 |
|----------|------|
| `ImageContent(const std::string& mime_type, const std::string& data)` | 构造函数，自动对 data 进行 base64 编码 |
| `std::string to_json() const` | 序列化为 JSON 字符串（含 type/image/mimeType/data 字段） |

#### 辅助类：Property

| 方法签名 | 说明 |
|----------|------|
| `Property(const std::string& name, PropertyType type)` | 必填属性构造函数 |
| `Property(const std::string& name, PropertyType type, const T& default_value)` | 带默认值的可选属性构造函数（模板） |
| `Property(const std::string& name, PropertyType type, int min_value, int max_value)` | 带范围限制的整数属性构造函数（无默认值） |
| `Property(const std::string& name, PropertyType type, int default_value, int min_value, int max_value)` | 带范围限制和默认值的整数属性构造函数 |
| `const std::string& name() const` | 获取属性名 |
| `PropertyType type() const` | 获取属性类型 |
| `bool has_default_value() const` | 是否有默认值 |
| `bool has_range() const` | 是否有值域范围限制 |
| `int min_value() const` | 获取最小值 |
| `int max_value() const` | 获取最大值 |
| `T value() const` | 获取属性值（模板，支持 bool/int/string） |
| `void set_value(const T& value)` | 设置属性值（模板，整数类型自动范围检查） |
| `std::string to_json() const` | 序列化为 JSON 字符串 |

#### 辅助类：PropertyList

| 方法签名 | 说明 |
|----------|------|
| `PropertyList()` | 默认构造函数 |
| `PropertyList(const std::vector<Property>& properties)` | 从属性向量构造 |
| `void AddProperty(const Property& property)` | 添加属性 |
| `const Property& operator[](const std::string& name) const` | 按名称索引属性 |
| `auto begin()` | 迭代器起始 |
| `auto end()` | 迭代器结束 |
| `std::vector<std::string> GetRequired() const` | 获取所有必填属性名列表 |
| `std::string to_json() const` | 序列化为 JSON 字符串 |

#### 辅助类：McpTool

| 方法签名 | 说明 |
|----------|------|
| `McpTool(const std::string& name, const std::string& description, const PropertyList& properties, std::function<ReturnValue(const PropertyList&)> callback)` | 构造工具，绑定名称、描述、属性列表和回调 |
| `void set_user_only(bool user_only)` | 设置是否为仅用户可见工具（AI 不可见） |
| `const std::string& name() const` | 获取工具名 |
| `const std::string& description() const` | 获取工具描述 |
| `const PropertyList& properties() const` | 获取属性列表 |
| `bool user_only() const` | 是否为仅用户可见 |
| `std::string to_json() const` | 序列化为 JSON（含 inputSchema 和 annotations） |
| `std::string Call(const PropertyList& properties)` | 调用工具，返回 JSON 格式的结果字符串（支持文本/图片/布尔/整数/cJSON 返回值） |

#### 核心类：McpServer

| 方法签名 | 说明 |
|----------|------|
| `static McpServer& GetInstance()` | 单例获取全局 McpServer 实例 |
| `void AddCommonTools()` | 注册通用工具集 |
| `void AddUserOnlyTools()` | 注册仅用户可见的工具集 |
| `void AddTool(McpTool* tool)` | 注册工具（直接传指针） |
| `void AddTool(const std::string& name, const std::string& description, const PropertyList& properties, std::function<ReturnValue(const PropertyList&)> callback)` | 注册工具（通过参数构建） |
| `void AddUserOnlyTool(const std::string& name, const std::string& description, const PropertyList& properties, std::function<ReturnValue(const PropertyList&)> callback)` | 注册仅用户可见工具 |
| `void ParseMessage(const cJSON* json)` | 解析 MCP 消息（cJSON 对象） |
| `void ParseMessage(const std::string& message)` | 解析 MCP 消息（JSON 字符串） |

---

### 10. Settings — NVS 键值存储

**文件路径：** `main/settings.h`

基于 ESP-IDF NVS (Non-Volatile Storage) 的键值存储类。

| 方法签名 | 说明 |
|----------|------|
| `Settings(const std::string& ns, bool read_write = false)` | 构造函数，指定 NVS 命名空间，可选读写模式 |
| `~Settings()` | 析构函数 |
| `std::string GetString(const std::string& key, const std::string& default_value = "")` | 获取字符串值，支持默认值 |
| `void SetString(const std::string& key, const std::string& value)` | 设置字符串值 |
| `int32_t GetInt(const std::string& key, int32_t default_value = 0)` | 获取整数值，支持默认值 |
| `void SetInt(const std::string& key, int32_t value)` | 设置整数值 |
| `bool GetBool(const std::string& key, bool default_value = false)` | 获取布尔值，支持默认值 |
| `void SetBool(const std::string& key, bool value)` | 设置布尔值 |
| `void EraseKey(const std::string& key)` | 删除指定键 |
| `void EraseAll()` | 删除命名空间下所有键值 |

---

### 11. Ota — 固件升级

**文件路径：** `main/ota.h`

#### 版本检查与激活方法

| 方法签名 | 说明 |
|----------|------|
| `esp_err_t CheckVersion()` | 检查固件版本（从服务器获取最新版本信息） |
| `esp_err_t Activate()` | 执行设备激活 |
| `bool HasActivationChallenge()` | 是否有激活挑战（需要用户确认） |
| `bool HasNewVersion()` | 是否有新版本可用 |
| `bool HasMqttConfig()` | 是否获取到了 MQTT 配置 |
| `bool HasWebsocketConfig()` | 是否获取到了 WebSocket 配置 |
| `bool HasActivationCode()` | 是否有激活码 |
| `bool HasServerTime()` | 是否获取到了服务器时间 |

#### 升级方法

| 方法签名 | 说明 |
|----------|------|
| `bool StartUpgrade(std::function<void(int progress, size_t speed)> callback)` | 开始 OTA 升级，回调报告进度和速度 |
| `static bool Upgrade(const std::string& firmware_url, std::function<void(int progress, size_t speed)> callback)` | 静态方法，从指定 URL 升级固件 |
| `void MarkCurrentVersionValid()` | 标记当前固件版本为有效（防止回滚） |

#### 信息获取方法

| 方法签名 | 说明 |
|----------|------|
| `const std::string& GetFirmwareVersion() const` | 获取服务器端最新固件版本 |
| `const std::string& GetCurrentVersion() const` | 获取当前固件版本 |
| `const std::string& GetFirmwareUrl() const` | 获取固件下载 URL |
| `const std::string& GetActivationMessage() const` | 获取激活消息 |
| `const std::string& GetActivationCode() const` | 获取激活码 |
| `std::string GetCheckVersionUrl()` | 获取版本检查 URL |

---

### 12. DeviceStateMachine — 设备状态机

**文件路径：** `main/device_state_machine.h`

#### 设备状态枚举（`main/device_state.h`）

```cpp
enum DeviceState {
    kDeviceStateUnknown,          // 未知状态
    kDeviceStateStarting,         // 启动中
    kDeviceStateWifiConfiguring,  // WiFi 配置中
    kDeviceStateIdle,             // 空闲
    kDeviceStateConnecting,       // 连接中
    kDeviceStateListening,        // 监听中
    kDeviceStateSpeaking,         // 说话中
    kDeviceStateUpgrading,        // 升级中
    kDeviceStateActivating,       // 激活中
    kDeviceStateAudioTesting,     // 音频测试中
    kDeviceStateFatalError        // 致命错误
};
```

#### 类型定义

```cpp
using StateCallback = std::function<void(DeviceState old_state, DeviceState new_state)>;
```

#### Public 方法

| 方法签名 | 说明 |
|----------|------|
| `DeviceState GetState() const` | 获取当前设备状态（原子操作） |
| `bool TransitionTo(DeviceState new_state)` | 尝试转换到新状态，返回是否成功 |
| `bool CanTransitionTo(DeviceState target) const` | 检查从当前状态到目标状态的转换是否合法 |
| `int AddStateChangeListener(StateCallback callback)` | 添加状态变更监听器（观察者模式），返回监听器 ID |
| `void RemoveStateChangeListener(int listener_id)` | 按 ID 移除状态变更监听器 |
| `static const char* GetStateName(DeviceState state)` | 获取状态的名称字符串（用于日志） |

> 该类禁止拷贝构造和赋值操作。

---

### 13. WebServer — HTTP 服务器

**文件路径：** `main/web_server/web_server.h`

#### 内部结构体

```cpp
struct MotorActionConfig {
    int forward_duration_ms = 5000;
    int backward_duration_ms = 5000;
    int left_turn_duration_ms = 600;
    int right_turn_duration_ms = 600;
    int spin_duration_ms = 2500;
    int wiggle_duration_ms = 600;
    int dance_duration_ms = 1500;
    int quick_forward_duration_ms = 5000;
    int quick_backward_duration_ms = 5000;
    int default_speed_percent = 100;
};
```

#### Public 方法

| 方法签名 | 说明 |
|----------|------|
| `bool Start(int port = 80)` | 启动 HTTP 服务器，默认端口 80 |
| `void Stop()` | 停止 HTTP 服务器 |
| `void SetMotorControlCallback(std::function<void(int direction, int speed)> callback)` | 注册电机控制回调 |
| `void InvokeMotorControl(int direction, int speed)` | 外部调用以触发电机控制 |
| `void SetEmotionCallback(std::function<void(const char* emotion)> callback)` | 注册表情设置回调 |
| `void SetEmotion(const char* emotion)` | 设置表情 |
| `void SetMotorActionConfigCallback(std::function<MotorActionConfig()> get_callback, std::function<void(const MotorActionConfig&)> set_callback)` | 注册电机动作配置的获取和设置回调 |
| `static esp_err_t debug_motor_test_handler(httpd_req_t* req)` | 静态 Debug 处理器（`/api/debug/motor_test`） |

---

### 14. Assets — 资源管理

**文件路径：** `main/assets.h`

通过 `Assets::GetInstance()` 获取单例。采用策略模式（Strategy Pattern）适配不同资源类型。

#### 结构体定义

```cpp
struct Asset {
    size_t size;    // 资源大小
    size_t offset;  // 资源在分区中的偏移量
};
```

#### Public 方法

| 方法签名 | 说明 |
|----------|------|
| `static Assets& GetInstance()` | 单例获取全局 Assets 实例 |
| `bool Download(std::string url, std::function<void(int progress, size_t speed)> progress_callback)` | 从指定 URL 下载资源，回调报告进度和速度 |
| `bool Apply()` | 应用/加载已下载的资源到系统 |
| `bool GetAssetData(const std::string& name, void*& ptr, size_t& size)` | 按名称获取资源数据指针和大小 |
| `bool partition_valid() const` | 分区是否有效 |
| `std::string default_assets_url() const` | 获取默认资源下载 URL |

#### 内部策略类

| 策略类 | 说明 |
|--------|------|
| `AssetStrategy`（抽象基类） | 定义 `Apply`、`InitializePartition`、`UnApplyPartition`、`GetAssetData` 纯虚接口 |
| `LvglStrategy` | LVGL 资源策略，支持内存映射（mmap）和校验和验证 |
| `EmoteStrategy` | 表情资源策略 |

---

## 五、接口关系总览

```
Application (核心单例，事件驱动状态机)
  │
  ├── Board (板级抽象单例，工厂模式)
  │     ├── AudioCodec → Read/Write (硬件 PCM I/O)
  │     │     └── ES8311 / ES8388 / Box / NoCodec / Dummy
  │     ├── Display → Lock/Unlock (线程安全显示)
  │     │     └── OLED / LCD / LVGL / Emote / NoDisplay
  │     ├── Led → OnStateChanged
  │     │     └── SingleLed / CircularStrip / NoLed
  │     ├── NetworkInterface → 网络连接
  │     ├── Camera → 摄像头
  │     └── Backlight → 背光
  │
  ├── Protocol (WebSocket / MQTT)
  │     ├── SendAudio / SendText (音频/文本传输)
  │     └── OnIncoming* 回调 (接收服务端数据)
  │
  ├── WakeWord → Feed/OnWakeWordDetected (唤醒词检测)
  │     └── AfeWakeWord / EspWakeWord / CustomWakeWord
  │
  ├── AudioProcessor → Feed/OnOutput/OnVadStateChange (降噪/AEC/VAD)
  │     └── AfeAudioProcessor / NoAudioProcessor / AudioDebugger
  │
  ├── McpServer → AddTool/ParseMessage (AI 工具控制框架)
  │     ├── Property / PropertyList (属性定义)
  │     └── McpTool (工具定义 + 回调绑定)
  │
  ├── WebServer → HTTP REST API (远程控制)
  │     └── /api/motor_control, /api/emotion, /api/debug/*
  │
  ├── Ota → CheckVersion/StartUpgrade (固件升级)
  │
  ├── Settings → NVS 键值存储 (GetString/SetString/GetInt/SetInt/GetBool/SetBool)
  │
  ├── DeviceStateMachine → TransitionTo/AddStateChangeListener (状态管理)
  │     └── 11 种 DeviceState 枚举
  │
  └── Assets → Download/Apply/GetAssetData (资源管理)
        └── LvglStrategy / EmoteStrategy (策略模式)
```

---

## 六、接口统计汇总

| 接口 | 文件路径 | 纯虚方法数 | 设计模式 |
|------|----------|-----------|----------|
| Board | `main/boards/common/board.h` | 8 | 单例 + 工厂（`DECLARE_BOARD` 宏） |
| AudioCodec | `main/audio/audio_codec.h` | 2 (protected) | 模板方法（public 高层操作 → protected 硬件读写） |
| Display | `main/display/display.h` | 2 (protected) | 模板方法 + RAII（`DisplayLockGuard`） |
| Led | `main/led/led.h` | 1 | 策略模式 |
| WakeWord | `main/audio/wake_word.h` | 9 | 完全抽象接口 |
| AudioProcessor | `main/audio/audio_processor.h` | 9 | 完全抽象接口 |
| Protocol | `main/protocols/protocol.h` | 6 | 模板方法 + 观察者（回调注册） |
| Application | `main/application.h` | 0 | 单例 + 事件驱动 + 状态机 |
| McpServer | `main/mcp_server.h` | 0 | 单例 + 注册表模式 |
| Settings | `main/settings.h` | 0 | 封装 NVS |
| Ota | `main/ota.h` | 0 | HTTP 客户端 |
| DeviceStateMachine | `main/device_state_machine.h` | 0 | 状态机 + 观察者 |
| WebServer | `main/web_server/web_server.h` | 0 | 回调注入 |
| Assets | `main/assets.h` | 0 | 单例 + 策略模式 |
