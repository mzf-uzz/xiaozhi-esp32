/**
 * @file servo_controller.h
 * @brief SG90 舵机控制器
 *
 * 使用 LEDC PWM 控制 3 个 SG90 舵机（脖子、左手、右手）
 * 独立使用 LEDC_TIMER_2（50Hz），不与电机的 LEDC_TIMER_1（5kHz）冲突
 *
 * SG90 参数：
 *   - 工作频率: 50Hz (周期 20ms)
 *   - 脉宽范围: 0.5ms ~ 2.5ms
 *   - 角度范围: 0° ~ 180°
 *   - PWM 分辨率: 13位 (0~8191)
 */

#ifndef _SERVO_CONTROLLER_H_
#define _SERVO_CONTROLLER_H_

#include <driver/ledc.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_log.h>
#include <cmath>
#include "config.h"

#define SERVO_LOG_TAG "ServoController"

// LEDC 配置常量 — 舵机专用（与电机 PWM 完全独立）
#define SERVO_LEDC_TIMER       LEDC_TIMER_2       // 使用 Timer2（电机用 Timer1，完全隔离）
#define SERVO_LEDC_MODE        LEDC_LOW_SPEED_MODE
#define SERVO_LEDC_RESOLUTION  LEDC_TIMER_13_BIT  // 13位分辨率，最大值 8191
#define SERVO_LEDC_FREQ_HZ     50                 // 50Hz 标准舵机频率
#define SERVO_LEDC_MAX_DUTY    8191               // 2^13 - 1

// LEDC 通道分配
#define SERVO_LEDC_CH_NECK     LEDC_CHANNEL_4     // 脖子舵机通道
#define SERVO_LEDC_CH_LEFT     LEDC_CHANNEL_5     // 左手舵机通道
#define SERVO_LEDC_CH_RIGHT    LEDC_CHANNEL_6     // 右手舵机通道

/**
 * @brief SG90 舵机控制器类
 *
 * 管理 3 个 SG90 舵机的 PWM 控制，提供角度设置和预定义动画动作。
 */
class ServoController {
private:
    // 舵机当前角度
    int neck_angle_;
    int left_angle_;
    int right_angle_;

    // 舵机 GPIO 引脚
    gpio_num_t neck_pin_;
    gpio_num_t left_pin_;
    gpio_num_t right_pin_;

    // PWM 是否已初始化
    bool initialized_;

    /**
     * @brief 将角度转换为 LEDC 占空比
     *
     * SG90 舵机脉宽映射关系：
     *   0°   → 0.5ms 脉宽 → duty = (0/180 * 2.0 + 0.5) * 8191 / 20.0 ≈ 205
     *   90°  → 1.5ms 脉宽 → duty = (90/180 * 2.0 + 0.5) * 8191 / 20.0 ≈ 614
     *   180° → 2.5ms 脉宽 → duty = (180/180 * 2.0 + 0.5) * 8191 / 20.0 ≈ 1024
     *
     * @param angle 角度值，范围 0~180
     * @return LEDC 占空比值，范围 205~1024
     */
    uint32_t AngleToDuty(int angle) {
        // 限幅到有效范围
        if (angle < SERVO_MIN_DEGREE) angle = SERVO_MIN_DEGREE;
        if (angle > SERVO_MAX_DEGREE) angle = SERVO_MAX_DEGREE;

        // 角度 → 脉宽占空比
        // 公式: duty = (angle / 180.0 * 2.0 + 0.5) * 8191 / 20.0
        // 其中 20.0 = 20ms 周期（单位 ms），0.5 = 最小脉宽 0.5ms
        uint32_t duty = (uint32_t)(((angle / 180.0) * 2.0 + 0.5) * SERVO_LEDC_MAX_DUTY / 20.0);
        return duty;
    }

    /**
     * @brief 设置指定 LEDC 通道的舵机角度
     *
     * @param channel LEDC 通道号
     * @param angle 目标角度 0~180
     */
    void SetChannelAngle(ledc_channel_t channel, int angle) {
        if (!initialized_) {
            ESP_LOGW(SERVO_LOG_TAG, "PWM 未初始化，无法设置角度");
            return;
        }

        uint32_t duty = AngleToDuty(angle);
        ESP_LOGI(SERVO_LOG_TAG, "设置舵机: channel=%d, angle=%d°, duty=%d",
                 channel, angle, duty);

        // 直接设置占空比（与 otto-robot 一致的方式）
        ledc_set_duty(SERVO_LEDC_MODE, channel, duty);
        ledc_update_duty(SERVO_LEDC_MODE, channel);
    }

public:
    /**
     * @brief 构造函数
     *
     * @param neck_pin 脖子舵机 GPIO 引脚
     * @param left_pin 左手舵机 GPIO 引脚
     * @param right_pin 右手舵机 GPIO 引脚
     */
    ServoController(gpio_num_t neck_pin = SERVO_NECK_GPIO,
                    gpio_num_t left_pin = SERVO_LEFT_GPIO,
                    gpio_num_t right_pin = SERVO_RIGHT_GPIO)
        : neck_angle_(SERVO_CENTER_DEGREE),
          left_angle_(SERVO_CENTER_DEGREE),
          right_angle_(SERVO_CENTER_DEGREE),
          neck_pin_(neck_pin),
          left_pin_(left_pin),
          right_pin_(right_pin),
          initialized_(false) {
    }

    /**
     * @brief 初始化舵机 PWM
     *
     * 配置独立的 LEDC Timer（50Hz，13位分辨率），为 3 个舵机通道创建 PWM。
     * 必须在电机 PWM 初始化之后调用（避免 Timer 冲突）。
     *
     * @return true 初始化成功，false 失败
     */
    bool Init() {
        if (initialized_) return true;

        ESP_LOGI(SERVO_LOG_TAG, "初始化舵机 PWM (freq=%dHz, resolution=13bit)", SERVO_LEDC_FREQ_HZ);

        // 1. 配置独立的 PWM Timer — 50Hz，13位分辨率
        ledc_timer_config_t timer_config = {};
        timer_config.speed_mode = SERVO_LEDC_MODE;
        timer_config.duty_resolution = SERVO_LEDC_RESOLUTION;
        timer_config.timer_num = SERVO_LEDC_TIMER;
        timer_config.freq_hz = SERVO_LEDC_FREQ_HZ;
        timer_config.clk_cfg = LEDC_AUTO_CLK;

        esp_err_t ret = ledc_timer_config(&timer_config);
        if (ret != ESP_OK) {
            ESP_LOGE(SERVO_LOG_TAG, "舵机 Timer 配置失败: %s", esp_err_to_name(ret));
            return false;
        }
        ESP_LOGI(SERVO_LOG_TAG, "舵机 Timer 配置成功 (Timer%d, %dHz)",
                 SERVO_LEDC_TIMER, SERVO_LEDC_FREQ_HZ);

        // 2. 配置 3 个舵机通道
        struct ServoChannelConfig {
            ledc_channel_t channel;
            gpio_num_t pin;
            const char* name;
        };

        ServoChannelConfig channels[] = {
            {SERVO_LEDC_CH_NECK,  neck_pin_,  "脖子"},
            {SERVO_LEDC_CH_LEFT,  left_pin_,  "左手"},
            {SERVO_LEDC_CH_RIGHT, right_pin_, "右手"},
        };

        for (int i = 0; i < 3; i++) {
            ledc_channel_config_t channel_config = {};
            channel_config.gpio_num = channels[i].pin;
            channel_config.speed_mode = SERVO_LEDC_MODE;
            channel_config.channel = channels[i].channel;
            channel_config.intr_type = LEDC_INTR_DISABLE;
            channel_config.timer_sel = SERVO_LEDC_TIMER;
            channel_config.duty = 0;
            channel_config.hpoint = 0;

            ret = ledc_channel_config(&channel_config);
            if (ret != ESP_OK) {
                ESP_LOGE(SERVO_LOG_TAG, "舵机通道 %s 配置失败: %s",
                         channels[i].name, esp_err_to_name(ret));
                return false;
            }
            ESP_LOGI(SERVO_LOG_TAG, "舵机通道 %s 配置成功 (GPIO%d, Channel%d)",
                     channels[i].name, channels[i].pin, channels[i].channel);
        }

        initialized_ = true;

        // 3. 所有舵机回到中间位置
        CenterAll();

        ESP_LOGI(SERVO_LOG_TAG, "✅ 舵机初始化完成，所有舵机已居中 (%d°)", SERVO_CENTER_DEGREE);
        return true;
    }

    /**
     * @brief 确保舵机已初始化（延迟初始化）
     */
    void EnsureInit() {
        if (!initialized_) {
            Init();
        }
    }

    /**
     * @brief 测试任意 GPIO 引脚的舵机 PWM
     *
     * 使用完全独立的 LEDC 资源（TIMER_3 + CHANNEL_7），不干扰现有舵机。
     *
     * @param pin GPIO 引脚号
     * @param angle 目标角度 0~180
     */
    void TestPin(int pin, int angle) {
        if (angle < 0) angle = 0;
        if (angle > 180) angle = 180;

        uint32_t duty = AngleToDuty(angle);
        gpio_num_t gpio = (gpio_num_t)pin;

        // 使用完全独立的 LEDC 资源，避免干扰现有舵机
        ledc_timer_config_t timer_cfg = {};
        timer_cfg.speed_mode = LEDC_LOW_SPEED_MODE;
        timer_cfg.duty_resolution = LEDC_TIMER_13_BIT;
        timer_cfg.timer_num = LEDC_TIMER_3;  // 独立 Timer
        timer_cfg.freq_hz = 50;
        timer_cfg.clk_cfg = LEDC_AUTO_CLK;
        ledc_timer_config(&timer_cfg);

        ledc_channel_config_t ch_cfg = {};
        ch_cfg.gpio_num = gpio;
        ch_cfg.speed_mode = LEDC_LOW_SPEED_MODE;
        ch_cfg.channel = LEDC_CHANNEL_7;     // 独立 Channel
        ch_cfg.intr_type = LEDC_INTR_DISABLE;
        ch_cfg.timer_sel = LEDC_TIMER_3;
        ch_cfg.duty = duty;
        ch_cfg.hpoint = 0;
        ledc_channel_config(&ch_cfg);

        ESP_LOGI(SERVO_LOG_TAG, "测试引脚: GPIO%d = %d° (duty=%d)", pin, angle, duty);
    }

    /**
     * @brief 设置脖子舵机角度
     *
     * @param angle 目标角度 0~180
     */
    void SetNeckAngle(int angle) {
        EnsureInit();
        if (angle < SERVO_MIN_DEGREE) angle = SERVO_MIN_DEGREE;
        if (angle > SERVO_MAX_DEGREE) angle = SERVO_MAX_DEGREE;
        neck_angle_ = angle;
        SetChannelAngle(SERVO_LEDC_CH_NECK, angle);
        ESP_LOGI(SERVO_LOG_TAG, "脖子舵机: %d°", angle);
    }

    /**
     * @brief 设置左手舵机角度
     *
     * @param angle 目标角度 0~180
     */
    void SetLeftAngle(int angle) {
        EnsureInit();
        if (angle < SERVO_MIN_DEGREE) angle = SERVO_MIN_DEGREE;
        if (angle > SERVO_MAX_DEGREE) angle = SERVO_MAX_DEGREE;
        left_angle_ = angle;
        SetChannelAngle(SERVO_LEDC_CH_LEFT, angle);
        ESP_LOGI(SERVO_LOG_TAG, "左手舵机: %d°", angle);
    }

    /**
     * @brief 设置右手舵机角度
     *
     * @param angle 目标角度 0~180
     */
    void SetRightAngle(int angle) {
        EnsureInit();
        if (angle < SERVO_MIN_DEGREE) angle = SERVO_MIN_DEGREE;
        if (angle > SERVO_MAX_DEGREE) angle = SERVO_MAX_DEGREE;
        right_angle_ = angle;
        SetChannelAngle(SERVO_LEDC_CH_RIGHT, angle);
        ESP_LOGI(SERVO_LOG_TAG, "右手舵机: %d°", angle);
    }

    /**
     * @brief 同时设置 3 个舵机角度
     *
     * @param neck 脖子角度（-1 表示不改变）
     * @param left 左手角度（-1 表示不改变）
     * @param right 右手角度（-1 表示不改变）
     */
    void MoveTo(int neck, int left, int right) {
        if (neck >= 0) SetNeckAngle(neck);
        if (left >= 0) SetLeftAngle(left);
        if (right >= 0) SetRightAngle(right);
    }

    /**
     * @brief 所有舵机回到中间位置（90°）
     */
    void CenterAll() {
        EnsureInit();
        ESP_LOGI(SERVO_LOG_TAG, "所有舵机居中 (%d°)", SERVO_CENTER_DEGREE);
        SetChannelAngle(SERVO_LEDC_CH_NECK, SERVO_CENTER_DEGREE);
        SetChannelAngle(SERVO_LEDC_CH_LEFT, SERVO_CENTER_DEGREE);
        SetChannelAngle(SERVO_LEDC_CH_RIGHT, SERVO_CENTER_DEGREE);
        neck_angle_ = SERVO_CENTER_DEGREE;
        left_angle_ = SERVO_CENTER_DEGREE;
        right_angle_ = SERVO_CENTER_DEGREE;
    }

    // ==================== 预定义动画动作 ====================

    /**
     * @brief 挥手动作 — 左右手交替摆动
     *
     * 动作序列：左手举起→右手放下→交换→重复→回中
     */
    void WaveHands() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 挥手");

        // 挥手 3 次
        for (int i = 0; i < 3; i++) {
            // 左手举起，右手放下
            SetLeftAngle(30);
            SetRightAngle(150);
            vTaskDelay(pdMS_TO_TICKS(300));

            // 左手放下，右手举起
            SetLeftAngle(150);
            SetRightAngle(30);
            vTaskDelay(pdMS_TO_TICKS(300));
        }

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 挥手完成");
    }

    /**
     * @brief 点头动作 — 脖子上下摆动
     *
     * 动作序列：低头→抬头→重复→回中
     */
    void Nod() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 点头");

        // 点头 3 次
        for (int i = 0; i < 3; i++) {
            // 低头（脖子角度减小）
            SetNeckAngle(50);
            vTaskDelay(pdMS_TO_TICKS(400));

            // 抬头（脖子角度增大）
            SetNeckAngle(130);
            vTaskDelay(pdMS_TO_TICKS(400));
        }

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 点头完成");
    }

    /**
     * @brief 摇头动作 — 脖子左右摆动
     *
     * 动作序列：左转→右转→重复→回中
     */
    void ShakeHead() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 摇头");

        // 摇头 3 次
        for (int i = 0; i < 3; i++) {
            // 左转
            SetNeckAngle(50);
            vTaskDelay(pdMS_TO_TICKS(350));

            // 右转
            SetNeckAngle(130);
            vTaskDelay(pdMS_TO_TICKS(350));
        }

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 摇头完成");
    }

    /**
     * @brief 开心动作 — 双手举起+摇头
     */
    void HappyDance() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 开心");

        // 双手举起
        SetLeftAngle(30);
        SetRightAngle(30);
        vTaskDelay(pdMS_TO_TICKS(500));

        // 摇头
        for (int i = 0; i < 2; i++) {
            SetNeckAngle(50);
            vTaskDelay(pdMS_TO_TICKS(250));
            SetNeckAngle(130);
            vTaskDelay(pdMS_TO_TICKS(250));
        }

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 开心完成");
    }

    /**
     * @brief 思考动作 — 脖子微摆+左手托腮
     */
    void ThinkPose() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 思考");

        // 左手托腮（抬起）
        SetLeftAngle(45);
        // 右手自然放下
        SetRightAngle(120);
        // 脖子微倾
        SetNeckAngle(110);
        vTaskDelay(pdMS_TO_TICKS(1500));

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 思考完成");
    }

    /**
     * @brief 悲伤动作 — 双手低垂+低头
     */
    void SadPose() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 悲伤");

        // 双手低垂
        SetLeftAngle(150);
        SetRightAngle(150);
        // 低头
        SetNeckAngle(50);
        vTaskDelay(pdMS_TO_TICKS(1500));

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 悲伤完成");
    }

    /**
     * @brief 兴奋动作 — 双手快速摆动+摇头
     */
    void ExcitedDance() {
        ESP_LOGI(SERVO_LOG_TAG, "动画: 兴奋");

        // 双手快速上下摆动
        for (int i = 0; i < 4; i++) {
            SetLeftAngle(30);
            SetRightAngle(150);
            vTaskDelay(pdMS_TO_TICKS(150));
            SetLeftAngle(150);
            SetRightAngle(30);
            vTaskDelay(pdMS_TO_TICKS(150));
        }

        // 快速摇头
        for (int i = 0; i < 3; i++) {
            SetNeckAngle(50);
            vTaskDelay(pdMS_TO_TICKS(200));
            SetNeckAngle(130);
            vTaskDelay(pdMS_TO_TICKS(200));
        }

        // 回到中间
        CenterAll();
        ESP_LOGI(SERVO_LOG_TAG, "动画: 兴奋完成");
    }

    // ==================== 状态查询 ====================

    /**
     * @brief 获取当前舵机状态字符串
     */
    std::string GetStatus() const {
        char buf[128];
        snprintf(buf, sizeof(buf),
                 "舵机状态: 脖子=%d° 左手=%d° 右手=%d° 初始化=%s",
                 neck_angle_, left_angle_, right_angle_,
                 initialized_ ? "是" : "否");
        return std::string(buf);
    }

    // Getter 方法
    int GetNeckAngle() const { return neck_angle_; }
    int GetLeftAngle() const { return left_angle_; }
    int GetRightAngle() const { return right_angle_; }
    bool IsInitialized() const { return initialized_; }
};

#endif // _SERVO_CONTROLLER_H_
