#!/bin/bash
# ESP-IDF 完整环境配置脚本 (Linux/Git Bash 版本)
# 使用代理下载并安装 ESP-IDF v5.5 到 F 盘
# 作者: Claude Code
# 日期: 2026-09-11

set -e  # 遇到错误立即退出

echo "============================================"
echo "ESP-IDF 完整环境配置工具"
echo "============================================"
echo ""

# 设置代理
export HTTP_PROXY="http://127.0.0.1:7897"
export HTTPS_PROXY="http://127.0.0.1:7897"
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"

# 设置安装路径
INSTALL_DIR="/f/esp-idf"
IDF_VERSION="5.5"
IDF_PATH="${INSTALL_DIR}/esp-idf-v${IDF_VERSION}"

echo "[信息] 代理设置: $HTTP_PROXY"
echo "[信息] 安装目录: $INSTALL_DIR"
echo "[信息] ESP-IDF 版本: $IDF_VERSION"
echo ""

# 检查代理连接
echo "[步骤 1/7] 检查代理连接..."
if ! curl -s --proxy "$HTTP_PROXY" https://httpbin.org/ip > /dev/null 2>&1; then
    echo "[错误] 代理连接失败！"
    echo ""
    echo "请确保："
    echo "1. VPN 已连接"
    echo "2. 代理地址正确: $HTTP_PROXY"
    exit 1
fi
echo "[通过] 代理连接正常"
echo ""

# 检查 F 盘空间
echo "[步骤 2/7] 检查磁盘空间..."
FREE_SPACE=$(df -h /f/ 2>/dev/null | tail -1 | awk '{print $4}')
echo "[信息] F 盘可用空间: $FREE_SPACE"
echo ""

# 创建安装目录
echo "[步骤 3/7] 创建安装目录..."
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "[错误] 无法创建目录 $INSTALL_DIR"
        exit 1
    fi
fi
echo "[完成] 目录创建成功"
echo ""

# 下载 ESP-IDF
echo "[步骤 4/7] 下载 ESP-IDF..."
echo ""
echo "正在下载 ESP-IDF v${IDF_VERSION}..."
echo "这可能需要 10-30 分钟，取决于网络速度..."
echo ""

DOWNLOAD_URL="https://github.com/espressif/esp-idf/releases/download/v${IDF_VERSION}/esp-idf-v${IDF_VERSION}.zip"
DOWNLOAD_FILE="${INSTALL_DIR}/esp-idf-v${IDF_VERSION}.zip"

# 使用 curl 通过代理下载
if ! curl -L --proxy "$HTTP_PROXY" -o "$DOWNLOAD_FILE" "$DOWNLOAD_URL"; then
    echo ""
    echo "[错误] 下载失败！"
    echo ""
    echo "请手动下载："
    echo "URL: $DOWNLOAD_URL"
    echo "保存到: $DOWNLOAD_FILE"
    exit 1
fi

echo ""
echo "[完成] 下载完成！"

# 解压文件
echo "[步骤 5/7] 解压文件..."
echo ""
echo "正在解压 ESP-IDF..."
echo "这可能需要 5-10 分钟..."
echo ""

if ! unzip -q -o "$DOWNLOAD_FILE" -d "$INSTALL_DIR"; then
    echo ""
    echo "[错误] 解压失败！"
    exit 1
fi

echo ""
echo "[完成] 解压完成！"

# 安装工具链
echo "[步骤 6/7] 安装工具链..."
echo ""
echo "正在安装 ESP-IDF 工具链..."
echo "这可能需要 10-20 分钟..."
echo ""

# 进入 ESP-IDF 目录
cd "$IDF_PATH"

# 运行安装脚本
if [ -f "install.sh" ]; then
    ./install.sh
elif [ -f "install.bat" ]; then
    # 在 Git Bash 中运行 bat 文件
    cmd.exe /c "install.bat"
else
    echo "[错误] 未找到安装脚本"
    exit 1
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "[错误] 工具链安装失败！"
    exit 1
fi

echo ""
echo "[完成] 工具链安装完成！"

# 配置环境
echo "[步骤 7/7] 配置环境..."
echo ""

# 设置环境变量 (写入 .bashrc)
echo "[设置] 配置环境变量..."
if ! grep -q "IDF_PATH" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# ESP-IDF 环境变量" >> ~/.bashrc
    echo "export IDF_PATH=\"$IDF_PATH\"" >> ~/.bashrc
fi

# 更新 idf-env.json
echo "[更新] 更新 idf-env.json..."
cat > "/c/Users/$USERNAME/.espressif/idf-env.json" << EOF
{
    "idfInstalled": {
        "$IDF_PATH": {
            "version": "$IDF_VERSION",
            "path": "$IDF_PATH",
            "features": [
                "core"
            ],
            "targets": [
                "esp32c5",
                "esp32h2",
                "esp32c2",
                "esp32c6",
                "esp32c61",
                "esp32h4",
                "esp32p4",
                "esp32",
                "esp32s3",
                "esp32h21",
                "esp32s2",
                "esp32c3"
            ]
        }
    }
}
EOF

# 创建环境配置文件
echo "[创建] 生成环境配置文件..."
cat > "$(dirname "$0")/env_config.txt" << EOF
# ESP-IDF 环境配置文件
# 生成时间: $(date)

IDF_PATH=$IDF_PATH
INSTALL_DIR=$INSTALL_DIR
HTTP_PROXY=$HTTP_PROXY
HTTPS_PROXY=$HTTPS_PROXY
EOF

echo ""
echo "============================================"
echo "安装完成！"
echo "============================================"
echo ""
echo "ESP-IDF 已成功安装到: $IDF_PATH"
echo ""
echo "环境配置："
echo "- IDF_PATH: $IDF_PATH"
echo "- 代理: $HTTP_PROXY"
echo ""
echo "下一步操作："
echo "1. 重新打开终端或运行 'source ~/.bashrc'"
echo "2. 运行 start_idf.sh 启动 ESP-IDF 环境"
echo "3. 运行 flash.sh 烧录固件"
echo ""
echo "注意：请重新打开终端以使环境变量生效"
echo ""

# 清理下载文件
echo "[清理] 删除下载的压缩包..."
rm -f "$DOWNLOAD_FILE"
echo "[完成] 清理完成"
echo ""
