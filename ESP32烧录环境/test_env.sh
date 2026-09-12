#!/bin/bash
# ESP-IDF 环境测试脚本 (Linux/Git Bash 版本)
# 用于测试 ESP-IDF 开发环境是否正确配置
# 作者: Claude Code
# 日期: 2026-09-11

echo "============================================"
echo "ESP-IDF 环境测试工具"
echo "============================================"
echo ""

TEST_PASS=0
TEST_FAIL=0

# 设置代理
export HTTP_PROXY="http://127.0.0.1:7897"
export HTTPS_PROXY="http://127.0.0.1:7897"

# 测试 1: 检查代理连接
echo "[测试 1/9] 检查代理连接..."
if curl -s --proxy "$HTTP_PROXY" https://httpbin.org/ip > /dev/null 2>&1; then
    echo "[通过] 代理连接正常"
    ((TEST_PASS++))
else
    echo "[失败] 代理连接失败"
    ((TEST_FAIL++))
fi
echo ""

# 测试 2: 检查 IDF_PATH 环境变量
echo "[测试 2/9] 检查 IDF_PATH 环境变量..."
if [ -z "$IDF_PATH" ]; then
    echo "[失败] IDF_PATH 环境变量未设置"
    ((TEST_FAIL++))
else
    if [ -d "$IDF_PATH" ]; then
        echo "[通过] IDF_PATH=$IDF_PATH"
        ((TEST_PASS++))
    else
        echo "[失败] IDF_PATH 目录不存在: $IDF_PATH"
        ((TEST_FAIL++))
    fi
fi
echo ""

# 测试 3: 检查 ESP-IDF export 脚本
echo "[测试 3/9] 检查 ESP-IDF export 脚本..."
if [ -f "$IDF_PATH/export.sh" ]; then
    echo "[通过] export.sh 存在"
    ((TEST_PASS++))
else
    echo "[失败] 未找到 export.sh"
    ((TEST_FAIL++))
fi
echo ""

# 测试 4: 检查 Python 环境
echo "[测试 4/9] 检查 Python 环境..."
ESPRESSIF_PATH="/c/Users/$USERNAME/.espressif"
if [ -d "$ESPRESSIF_PATH/python_env/idf5.5_py3.9_env" ]; then
    echo "[通过] Python 虚拟环境存在"
    ((TEST_PASS++))
else
    echo "[警告] Python 虚拟环境不存在，可能需要安装"
    ((TEST_FAIL++))
fi
echo ""

# 测试 5: 检查工具链
echo "[测试 5/9] 检查工具链..."
XTENSA_PATH="$ESPRESSIF_PATH/tools/xtensa-esp-elf/xtensa-esp-elf/bin"
if [ -d "$XTENSA_PATH" ]; then
    echo "[通过] Xtensa 工具链存在"
    ((TEST_PASS++))
else
    echo "[失败] Xtensa 工具链不存在"
    ((TEST_FAIL++))
fi
echo ""

# 测试 6: 检查 CMake
echo "[测试 6/9] 检查 CMake..."
CMAKE_PATH="$ESPRESSIF_PATH/tools/cmake/3.30.2/bin"
if [ -d "$CMAKE_PATH" ]; then
    echo "[通过] CMake 存在"
    ((TEST_PASS++))
else
    echo "[失败] CMake 不存在"
    ((TEST_FAIL++))
fi
echo ""

# 测试 7: 检查 Ninja
echo "[测试 7/9] 检查 Ninja..."
NINJA_PATH="$ESPRESSIF_PATH/tools/ninja/1.12.1"
if [ -d "$NINJA_PATH" ]; then
    echo "[通过] Ninja 存在"
    ((TEST_PASS++))
else
    echo "[失败] Ninja 不存在"
    ((TEST_FAIL++))
fi
echo ""

# 测试 8: 检查串口设备
echo "[测试 8/9] 检查串口设备..."
echo "正在检测串口设备..."
SERIAL_FOUND=0

# 检查 Windows 串口
for port in /dev/ttyS* /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$port" ]; then
        echo "[信息] 发现串口: $port"
        SERIAL_FOUND=1
    fi
done

# 在 Git Bash 中检查 COM 端口
for com in /dev/com*; do
    if [ -e "$com" ]; then
        echo "[信息] 发现串口: $com"
        SERIAL_FOUND=1
    fi
done

if [ $SERIAL_FOUND -eq 1 ]; then
    echo "[通过] 发现串口设备"
    ((TEST_PASS++))
else
    echo "[警告] 未发现串口设备，请检查："
    echo "  1. 开发板是否已连接"
    echo "  2. USB 线缆是否正常"
    echo "  3. 串口驱动是否安装 (CP2102/CH340)"
    ((TEST_FAIL++))
fi
echo ""

# 测试 9: 检查项目文件
echo "[测试 9/9] 检查项目文件..."
PROJECT_DIR="$(dirname "$0")/.."
if [ -f "$PROJECT_DIR/CMakeLists.txt" ]; then
    echo "[通过] 项目 CMakeLists.txt 存在"
    ((TEST_PASS++))
else
    echo "[失败] 未找到项目 CMakeLists.txt"
    ((TEST_FAIL++))
fi
echo ""

# 显示测试结果
echo "============================================"
echo "测试结果"
echo "============================================"
echo ""
echo "通过: $TEST_PASS"
echo "失败: $TEST_FAIL"
echo ""

if [ $TEST_FAIL -eq 0 ]; then
    echo "[结论] 所有测试通过！环境配置正确。"
    echo ""
    echo "下一步操作："
    echo "1. 运行 start_idf.sh 启动 ESP-IDF 环境"
    echo "2. 运行 flash.sh 烧录固件"
else
    echo "[结论] 存在 $TEST_FAIL 个问题需要解决。"
    echo ""
    echo "建议操作："
    echo "1. 运行 setup_full.sh 重新配置环境"
    echo "2. 安装缺失的组件"
    echo "3. 检查串口驱动"
fi
echo ""

# 显示详细信息
echo "============================================"
echo "详细信息"
echo "============================================"
echo ""
echo "ESP-IDF 路径: $IDF_PATH"
echo "工具链路径: $ESPRESSIF_PATH/tools"
echo "Python 环境: $ESPRESSIF_PATH/python_env/idf5.5_py3.9_env"
echo "项目目录: $PROJECT_DIR"
echo "代理设置: $HTTP_PROXY"
echo ""

# 检查 idf.py 是否可用
echo "[额外测试] 检查 idf.py 命令..."
if command -v idf.py &> /dev/null; then
    echo "[通过] idf.py 命令可用"
    echo ""
    echo "ESP-IDF 版本信息:"
    idf.py --version
else
    echo "[警告] idf.py 不在 PATH 中"
    echo "请运行 start_idf.sh 启动 ESP-IDF 环境"
fi
echo ""
