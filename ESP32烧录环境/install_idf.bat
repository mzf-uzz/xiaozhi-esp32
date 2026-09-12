@echo off
REM ESP-IDF 安装脚本
REM 用于安装 ESP-IDF v5.5 到 F 盘
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP-IDF 安装工具
echo ============================================
echo.

REM 设置安装路径
set "INSTALL_DIR=F:\esp-idf"
set "IDF_VERSION=5.5"

echo [信息] 安装目录: %INSTALL_DIR%
echo [信息] ESP-IDF 版本: %IDF_VERSION%
echo.

REM 检查 F 盘空间
echo [步骤 1/5] 检查磁盘空间...
for /f "tokens=3" %%a in ('dir F:\ ^| findstr /C:"可用空间"') do (
    set "FREE_SPACE=%%a"
)

echo [信息] F 盘可用空间: %FREE_SPACE%
echo.

REM 创建安装目录
echo [步骤 2/5] 创建安装目录...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    if errorlevel 1 (
        echo [错误] 无法创建目录 %INSTALL_DIR%
        pause
        exit /b 1
    )
)

REM 下载 ESP-IDF
echo [步骤 3/5] 下载 ESP-IDF...
echo.
echo 正在下载 ESP-IDF v%IDF_VERSION%...
echo 这可能需要几分钟，取决于网络速度...
echo.

REM 使用 PowerShell 下载
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/espressif/esp-idf/releases/download/v5.5/esp-idf-v5.5.zip' -OutFile '%INSTALL_DIR%\esp-idf-v5.5.zip'}"

if errorlevel 1 (
    echo.
    echo [错误] 下载失败！
    echo.
    echo 请尝试以下方法：
    echo 1. 检查网络连接
    echo 2. 使用 VPN 或代理
    echo 3. 手动下载：https://github.com/espressif/esp-idf/releases/download/v5.5/esp-idf-v5.5.zip
    echo.
    pause
    exit /b 1
)

echo.
echo [完成] 下载完成！

REM 解压文件
echo [步骤 4/5] 解压文件...
echo.
echo 正在解压 ESP-IDF...
echo 这可能需要几分钟...
echo.

REM 使用 PowerShell 解压
powershell -Command "Expand-Archive -Path '%INSTALL_DIR%\esp-idf-v5.5.zip' -DestinationPath '%INSTALL_DIR%' -Force"

if errorlevel 1 (
    echo.
    echo [错误] 解压失败！
    pause
    exit /b 1
)

echo.
echo [完成] 解压完成！

REM 安装工具链
echo [步骤 5/5] 安装工具链...
echo.
echo 正在安装 ESP-IDF 工具链...
echo.

REM 进入 ESP-IDF 目录
cd /d "%INSTALL_DIR%\esp-idf-v5.5"

REM 运行安装脚本
call install.bat

if errorlevel 1 (
    echo.
    echo [错误] 工具链安装失败！
    pause
    exit /b 1
)

echo.
echo [完成] 工具链安装完成！

REM 设置环境变量
echo [设置] 配置环境变量...
echo.

REM 设置 IDF_PATH
setx IDF_PATH "%INSTALL_DIR%\esp-idf-v5.5"
if errorlevel 1 (
    echo [警告] 无法设置系统环境变量
)

REM 更新 idf-env.json
echo [更新] 更新 idf-env.json...
echo {
echo     "idfInstalled": {
echo         "%INSTALL_DIR%\esp-idf-v5.5": {
echo             "version": "%IDF_VERSION%",
echo             "path": "%INSTALL_DIR%\esp-idf-v5.5",
echo             "features": [
echo                 "core"
echo             ],
echo             "targets": [
echo                 "esp32c5",
echo                 "esp32h2",
echo                 "esp32c2",
echo                 "esp32c6",
echo                 "esp32c61",
echo                 "esp32h4",
echo                 "esp32p4",
echo                 "esp32",
echo                 "esp32s3",
echo                 "esp32h21",
echo                 "esp32s2",
echo                 "esp32c3"
echo             ]
echo         }
echo     }
echo } > "C:\Users\%USERNAME%\.espressif\idf-env.json"

echo.
echo ============================================
echo 安装完成！
echo ============================================
echo.
echo ESP-IDF 已成功安装到: %INSTALL_DIR%\esp-idf-v5.5
echo.
echo 下一步操作：
echo 1. 重新打开命令提示符或 PowerShell
echo 2. 运行 start_idf.bat 启动 ESP-IDF 环境
echo 3. 运行 flash.bat 烧录固件
echo.
echo 注意：请重新打开命令行窗口以使环境变量生效
echo.
pause
