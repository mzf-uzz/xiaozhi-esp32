#ifndef _BOARD_CONFIG_H_
#define _BOARD_CONFIG_H_

#include <driver/gpio.h>

#define AUDIO_INPUT_SAMPLE_RATE  16000
#define AUDIO_OUTPUT_SAMPLE_RATE 24000

// 如果使用 Duplex I2S 模式，请注释下面一行
#define AUDIO_I2S_METHOD_SIMPLEX

#ifdef AUDIO_I2S_METHOD_SIMPLEX

#define AUDIO_I2S_MIC_GPIO_WS   GPIO_NUM_4
#define AUDIO_I2S_MIC_GPIO_SCK  GPIO_NUM_5
#define AUDIO_I2S_MIC_GPIO_DIN  GPIO_NUM_6
#define AUDIO_I2S_SPK_GPIO_DOUT GPIO_NUM_7
#define AUDIO_I2S_SPK_GPIO_BCLK GPIO_NUM_15
#define AUDIO_I2S_SPK_GPIO_LRCK GPIO_NUM_16

#else

#define AUDIO_I2S_GPIO_WS GPIO_NUM_4
#define AUDIO_I2S_GPIO_BCLK GPIO_NUM_5
#define AUDIO_I2S_GPIO_DIN  GPIO_NUM_6
#define AUDIO_I2S_GPIO_DOUT GPIO_NUM_7

#endif


#define BUILTIN_LED_GPIO        GPIO_NUM_48
#define BOOT_BUTTON_GPIO        GPIO_NUM_0
#define TOUCH_BUTTON_GPIO       GPIO_NUM_47
#define VOLUME_UP_BUTTON_GPIO   GPIO_NUM_40
#define VOLUME_DOWN_BUTTON_GPIO GPIO_NUM_39

#define DISPLAY_SDA_PIN GPIO_NUM_41
#define DISPLAY_SCL_PIN GPIO_NUM_42
#define DISPLAY_WIDTH   128

#if CONFIG_OLED_SSD1306_128X32
#define DISPLAY_HEIGHT  32
#elif CONFIG_OLED_SSD1306_128X64
#define DISPLAY_HEIGHT  64
#elif CONFIG_OLED_SH1106_128X64
#define DISPLAY_HEIGHT  64
#define SH1106
#else
#error "未选择 OLED 屏幕类型"
#endif

#define DISPLAY_MIRROR_X true
#define DISPLAY_MIRROR_Y true


// A MCP Test: Control a lamp
#define LAMP_GPIO GPIO_NUM_18

// Motor control pins for TC1508 module (N20 motors as wheels)
#define MOTOR_LF_GPIO GPIO_NUM_18   // Left Forward (IN1)
#define MOTOR_LB_GPIO GPIO_NUM_17   // Left Backward (IN2)
#define MOTOR_RF_GPIO GPIO_NUM_14   // Right Forward (IN3)
#define MOTOR_RB_GPIO GPIO_NUM_13   // Right Backward (IN4)

// SG90 舵机控制引脚
#define SERVO_NECK_GPIO   GPIO_NUM_9   // 脖子舵机信号线
#define SERVO_LEFT_GPIO   GPIO_NUM_10   // 左手舵机信号线
#define SERVO_RIGHT_GPIO  GPIO_NUM_11  // 右手舵机信号线

// SG90 舵机参数
#define SERVO_MIN_PULSEWIDTH_US  500    // 最小脉宽 0.5ms (对应 0°)
#define SERVO_MAX_PULSEWIDTH_US  2500   // 最大脉宽 2.5ms (对应 180°)
#define SERVO_MIN_DEGREE         0      // 最小角度
#define SERVO_MAX_DEGREE         180    // 最大角度
#define SERVO_CENTER_DEGREE      90     // 中间角度

#endif // _BOARD_CONFIG_H_
