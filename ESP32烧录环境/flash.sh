#!/bin/bash
# ESP32 固件烧录脚本 (Linux/Git Bash 版本)
# 用于烧录小智桌面机器人固件到 ESP32-S3 开发板
# 作者: Claude Code
# 日期: 2026-09-11

echo "============================================"
echo "ESP32 固件烧录工具"
echo "============================================"
echo ""

# 设置代理
export HTTP_PROXY="http://127.0.0.1:7897"
export HTTPS_PROXY="http://127.0.0.1:7897"
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"

# 检查 IDF_PATH 环境变量
if [ -z "$IDF_PATH" ]; then
    echo "[错误] IDF_PATH 环境变量未设置！"
    echo ""
    echo "请先运行 setup_full.sh 配置环境"
    echo "然后运行 start_idf.sh 启动 ESP-IDF 环境"
    exit 1
fi

# 检查项目目录
PROJECT_DIR="$(dirname "$0")/.."
if [ ! -f "$PROJECT_DIR/CMakeLists.txt" ]; then
    echo "[错误] 未找到项目 CMakeLists.txt！"
    echo ""
    echo "请确保此脚本位于 ESP32烧录环境 目录中"
    exit 1
fi

echo "[信息] 项目目录: $PROJECT_DIR"
echo ""

# 检查是否已编译
if [ ! -d "$PROJECT_DIR/build" ]; then
    echo "[警告] 未找到 build 目录，需要先编译项目！"
    echo ""
    echo "是否现在编译？(y/n)"
    read -r COMPILE_CHOICE
    if [[ "$COMPILE_CHOICE" =~ ^[Yy]$ ]]; then
        echo ""
        echo "[步骤 1/2] 设置目标芯片为 ESP32-S3..."
        cd "$PROJECT_DIR"
        idf.py set-target esp32s3
        if [ $? -ne 0 ]; then
            echo "[错误] 设置目标芯片失败！"
            exit 1
        fi

        echo ""
        echo "[步骤 2/2] 编译项目..."
        idf.py build
        if [ $? -ne 0 ]; then
            echo "[错误] 编译失败！"
            exit 1
        fi
    else
        echo ""
        echo "[信息] 跳过编译，请先手动编译项目"
        exit 0
    fi
fi

echo ""
echo "============================================"
echo "烧录选项"
echo "============================================"
echo ""
echo "请选择烧录模式："
echo ""
echo "1. 标准烧录 (USB 串口)"
echo "2. 高速烧录 (USB 串口，使用 921600 波特率)"
echo "3. OTA 烧录 (通过网络)"
echo "4. 仅编译不烧录"
echo "5. 烧录并监控串口"
echo "6. 仅监控串口"
echo "7. 清理并重新编译烧录"
echo "8. 退出"
echo ""
read -r -p "请输入选项 (1-8): " FLASH_CHOICE

# 获取串口端口
COM_PORT=""
if [[ "$FLASH_CHOICE" =~ ^[1257]$ ]]; then
    echo ""
    echo "可用的串口端口："
    echo ""

    # 列出可用的 COM 端口
    for port in /dev/ttyS* /dev/ttyUSB* /dev/ttyACM* /dev/com*; do
        if [ -e "$port" ]; then
            echo "  $port"
        fi
    done

    echo ""
    echo "请输入串口端口 (例如: /dev/ttyUSB0 或 COM3):"
    read -r COM_PORT
    if [ -z "$COM_PORT" ]; then
        echo "[错误] 未指定串口端口！"
        exit 1
    fi
    echo ""
fi

cd "$PROJECT_DIR"

case $FLASH_CHOICE in
    1)
        echo "[烧录] 使用标准模式烧录..."
        echo ""
        echo "正在烧录固件到 $COM_PORT..."
        idf.py -p "$COM_PORT" flash
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] 烧录失败！"
            echo ""
            echo "可能的原因："
            echo "1. 串口端口错误"
            echo "2. 开发板未连接"
            echo "3. 开发板未进入下载模式"
            echo "4. 驱动未安装"
            echo ""
            echo "解决方法："
            echo "1. 检查 USB 线缆连接"
            echo "2. 按住 BOOT 按钮，然后按 RESET 按钮进入下载模式"
            echo "3. 安装 CP2102 或 CH340 驱动"
            exit 1
        fi
        echo ""
        echo "[完成] 烧录成功！"
        ;;
    2)
        echo "[烧录] 使用高速模式烧录 (921600 波特率)..."
        echo ""
        echo "正在烧录固件到 $COM_PORT..."
        idf.py -p "$COM_PORT" -b 921600 flash
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] 高速烧录失败，尝试标准模式..."
            idf.py -p "$COM_PORT" flash
            if [ $? -ne 0 ]; then
                echo "[错误] 烧录失败！"
                exit 1
            fi
        fi
        echo ""
        echo "[完成] 烧录成功！"
        ;;
    3)
        echo "[烧录] OTA 烧录模式..."
        echo ""
        echo "请输入设备的 IP 地址:"
        read -r DEVICE_IP
        if [ -z "$DEVICE_IP" ]; then
            echo "[错误] 未指定 IP 地址！"
            exit 1
        fi
        echo ""
        echo "正在通过 OTA 烧录固件到 $DEVICE_IP..."
        idf.py ota --ip "$DEVICE_IP" flash
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] OTA 烧录失败！"
            echo ""
            echo "请确保："
            echo "1. 设备已连接到同一网络"
            echo "2. IP 地址正确"
            echo "3. 设备已启用 OTA 功能"
            exit 1
        fi
        echo ""
        echo "[完成] OTA 烧录成功！"
        ;;
    4)
        echo "[编译] 仅编译项目..."
        echo ""
        idf.py build
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] 编译失败！"
            exit 1
        fi
        echo ""
        echo "[完成] 编译成功！"
        echo "固件文件位于: build/xiaozhi.bin"
        ;;
    5)
        echo "[烧录] 烧录并监控串口..."
        echo ""
        echo "正在烧录固件到 $COM_PORT..."
        idf.py -p "$COM_PORT" flash monitor
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] 烧录或监控失败！"
            exit 1
        fi
        ;;
    6)
        echo "[监控] 启动串口监控..."
        echo ""
        echo "正在监控 $COM_PORT..."
        echo "按 Ctrl+] 退出监控"
        echo ""
        idf.py -p "$COM_PORT" monitor
        ;;
    7)
        echo "[清理] 清理并重新编译烧录..."
        echo ""
        echo "[步骤 1/3] 清理构建目录..."
        idf.py fullclean || echo "[警告] 清理失败，继续..."

        echo ""
        echo "[步骤 2/3] 设置目标芯片..."
        idf.py set-target esp32s3
        if [ $? -ne 0 ]; then
            echo "[错误] 设置目标芯片失败！"
            exit 1
        fi

        echo ""
        echo "[步骤 3/3] 编译并烧录..."
        idf.py -p "$COM_PORT" flash
        if [ $? -ne 0 ]; then
            echo ""
            echo "[错误] 烧录失败！"
            exit 1
        fi
        echo ""
        echo "[完成] 清理并烧录成功！"
        ;;
    8)
        echo "[退出] 再见！"
        exit 0
        ;;
    *)
        echo "[错误] 无效的选项！"
        exit 1
        ;;
esac
