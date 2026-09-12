#!/bin/bash
# ESP-IDF 环境启动脚本 (Linux/Git Bash 版本)
# 用于启动 ESP-IDF 开发环境
# 作者: Claude Code
# 日期: 2026-09-11

echo "============================================"
echo "ESP-IDF 环境启动工具"
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
    echo "或手动设置: export IDF_PATH=/f/esp-idf/esp-idf-v5.5"
    exit 1
fi

# 检查 ESP-IDF 是否存在
if [ ! -d "$IDF_PATH" ]; then
    echo "[错误] ESP-IDF 目录不存在: $IDF_PATH"
    echo ""
    echo "请检查 ESP-IDF 安装路径是否正确"
    exit 1
fi

echo "[信息] ESP-IDF 路径: $IDF_PATH"
echo ""

# 检查 export.sh 是否存在
if [ ! -f "$IDF_PATH/export.sh" ]; then
    echo "[错误] 未找到 export.sh 脚本！"
    echo ""
    echo "可能的原因："
    echo "1. ESP-IDF 安装不完整"
    echo "2. 路径配置错误"
    echo ""
    echo "请重新安装 ESP-IDF 或检查路径配置"
    exit 1
fi

echo "[步骤 1/2] 启动 ESP-IDF 环境..."
echo ""

# 设置 ESP-IDF 工具链路径
ESPRESSIF_PATH="/c/Users/$USERNAME/.espressif"

# 添加工具链到 PATH
if [ -d "$ESPRESSIF_PATH/tools/xtensa-esp-elf/xtensa-esp-elf/bin" ]; then
    export PATH="$ESPRESSIF_PATH/tools/xtensa-esp-elf/xtensa-esp-elf/bin:$PATH"
fi

if [ -d "$ESPRESSIF_PATH/tools/riscv32-esp-elf/riscv32-esp-elf/bin" ]; then
    export PATH="$ESPRESSIF_PATH/tools/riscv32-esp-elf/riscv32-esp-elf/bin:$PATH"
fi

if [ -d "$ESPRESSIF_PATH/tools/cmake/3.30.2/bin" ]; then
    export PATH="$ESPRESSIF_PATH/tools/cmake/3.30.2/bin:$PATH"
fi

if [ -d "$ESPRESSIF_PATH/tools/ninja/1.12.1" ]; then
    export PATH="$ESPRESSIF_PATH/tools/ninja/1.12.1:$PATH"
fi

# 激活 Python 虚拟环境
if [ -d "$ESPRESSIF_PATH/python_env/idf5.5_py3.9_env" ]; then
    echo "[信息] 激活 Python 虚拟环境..."
    source "$ESPRESSIF_PATH/python_env/idf5.5_py3.9_env/Scripts/activate" 2>/dev/null || \
    source "$ESPRESSIF_PATH/python_env/idf5.5_py3.9_env/bin/activate" 2>/dev/null
fi

# 运行 ESP-IDF export 脚本
echo "[步骤 2/2] 加载 ESP-IDF 环境变量..."
echo ""
source "$IDF_PATH/export.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo "[错误] ESP-IDF 环境加载失败！"
    echo ""
    echo "请检查："
    echo "1. ESP-IDF 安装是否完整"
    echo "2. Python 环境是否正确"
    echo "3. 工具链是否安装"
    exit 1
fi

echo ""
echo "============================================"
echo "ESP-IDF 环境已成功启动！"
echo "============================================"
echo ""
echo "可用的命令："
echo "  idf.py --version          - 查看 ESP-IDF 版本"
echo "  idf.py set-target esp32s3 - 设置目标芯片"
echo "  idf.py menuconfig         - 打开配置菜单"
echo "  idf.py build              - 编译项目"
echo "  idf.py flash              - 烧录固件"
echo "  idf.py flash monitor      - 烧录并监控串口"
echo "  idf.py monitor            - 监控串口输出"
echo ""
echo "当前工作目录: $(pwd)"
echo ""
echo "提示：输入 'exit' 退出 ESP-IDF 环境"
echo ""
