@echo off
REM ESP-IDF 完整环境配置脚本
REM 使用代理下载并安装 ESP-IDF v5.5 到 F 盘
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP-IDF 完整环境配置工具
echo ============================================
echo.

REM 设置代理
set "HTTP_PROXY=http://127.0.0.1:7897"
set "HTTPS_PROXY=http://127.0.0.1:7897"
set "http_proxy=http://127.0.0.1:7897"
set "https_proxy=http://127.0.0.1:7897"

REM 设置安装路径
set "INSTALL_DIR=F:\esp-idf"
set "IDF_VERSION=5.5"
set "IDF_PATH=%INSTALL_DIR%\esp-idf-v%IDF_VERSION%"

echo [信息] 代理设置: %HTTP_PROXY%
echo [信息] 安装目录: %INSTALL_DIR%
echo [信息] ESP-IDF 版本: %IDF_VERSION%
echo.

REM 检查代理连接
echo [步骤 1/7] 检查代理连接...
curl -s --proxy %HTTP_PROXY% https://httpbin.org/ip >nul 2>&1
if errorlevel 1 (
    echo [错误] 代理连接失败！
    echo.
    echo 请确保：
    echo 1. VPN 已连接
    echo 2. 代理地址正确: %HTTP_PROXY%
    echo.
    pause
    exit /b 1
)
echo [通过] 代理连接正常
echo.

REM 检查 F 盘空间
echo [步骤 2/7] 检查磁盘空间...
for /f "tokens=3" %%a in ('dir F:\ ^| findstr /C:"可用空间"') do (
    set "FREE_SPACE=%%a"
)
echo [信息] F 盘可用空间: %FREE_SPACE%
echo.

REM 创建安装目录
echo [步骤 3/7] 创建安装目录...
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
    if errorlevel 1 (
        echo [错误] 无法创建目录 %INSTALL_DIR%
        pause
        exit /b 1
    )
)
echo [完成] 目录创建成功
echo.

REM 下载 ESP-IDF
echo [步骤 4/7] 下载 ESP-IDF...
echo.
echo 正在下载 ESP-IDF v%IDF_VERSION%...
echo 这可能需要 10-30 分钟，取决于网络速度...
echo.

REM 使用 PowerShell 通过代理下载
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $webclient = New-Object System.Net.WebClient; $webclient.Proxy = New-Object System.Net.WebProxy('http://127.0.0.1:7897'); $webclient.DownloadFile('https://github.com/espressif/esp-idf/releases/download/v%IDF_VERSION%/esp-idf-v%IDF_VERSION%.zip', '%INSTALL_DIR%\esp-idf-v%IDF_VERSION%.zip')}"

if errorlevel 1 (
    echo.
    echo [错误] 下载失败！
    echo.
    echo 尝试使用备用下载方式...
    echo.

    REM 备用方式：使用 curl
    curl -L --proxy %HTTP_PROXY% -o "%INSTALL_DIR%\esp-idf-v%IDF_VERSION%.zip" "https://github.com/espressif/esp-idf/releases/download/v%IDF_VERSION%/esp-idf-v%IDF_VERSION%.zip"

    if errorlevel 1 (
        echo.
        echo [错误] 备用下载也失败了！
        echo.
        echo 请手动下载：
        echo URL: https://github.com/espressif/esp-idf/releases/download/v%IDF_VERSION%/esp-idf-v%IDF_VERSION%.zip
        echo 保存到: %INSTALL_DIR%\esp-idf-v%IDF_VERSION%.zip
        echo.
        pause
        exit /b 1
    )
)

echo.
echo [完成] 下载完成！

REM 解压文件
echo [步骤 5/7] 解压文件...
echo.
echo 正在解压 ESP-IDF...
echo 这可能需要 5-10 分钟...
echo.

REM 使用 PowerShell 解压
powershell -Command "Expand-Archive -Path '%INSTALL_DIR%\esp-idf-v%IDF_VERSION%.zip' -DestinationPath '%INSTALL_DIR%' -Force"

if errorlevel 1 (
    echo.
    echo [错误] 解压失败！
    pause
    exit /b 1
)

echo.
echo [完成] 解压完成！

REM 安装工具链
echo [步骤 6/7] 安装工具链...
echo.
echo 正在安装 ESP-IDF 工具链...
echo 这可能需要 10-20 分钟...
echo.

REM 进入 ESP-IDF 目录
cd /d "%IDF_PATH%"

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

REM 配置环境
echo [步骤 7/7] 配置环境...
echo.

REM 设置环境变量
setx IDF_PATH "%IDF_PATH%"
if errorlevel 1 (
    echo [警告] 无法设置系统环境变量
)

REM 更新 idf-env.json
echo [更新] 更新 idf-env.json...
(
echo {
echo     "idfInstalled": {
echo         "%IDF_PATH%": {
echo             "version": "%IDF_VERSION%",
echo             "path": "%IDF_PATH%",
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
echo }
) > "C:\Users\%USERNAME%\.espressif\idf-env.json"

REM 创建环境配置文件
echo [创建] 生成环境配置文件...
(
echo # ESP-IDF 环境配置文件
echo # 生成时间: %date% %time%
echo.
echo IDF_PATH=%IDF_PATH%
echo INSTALL_DIR=%INSTALL_DIR%
echo HTTP_PROXY=%HTTP_PROXY%
echo HTTPS_PROXY=%HTTPS_PROXY%
) > "%~dp0env_config.txt"

echo.
echo ============================================
echo 安装完成！
echo ============================================
echo.
echo ESP-IDF 已成功安装到: %IDF_PATH%
echo.
echo 环境配置：
echo - IDF_PATH: %IDF_PATH%
echo - 代理: %HTTP_PROXY%
echo.
echo 下一步操作：
echo 1. 重新打开命令提示符或 PowerShell
echo 2. 运行 start_idf.bat 启动 ESP-IDF 环境
echo 3. 运行 flash.bat 烧录固件
echo.
echo 注意：请重新打开命令行窗口以使环境变量生效
echo.

REM 清理下载文件
echo [清理] 删除下载的压缩包...
del /q "%INSTALL_DIR%\esp-idf-v%IDF_VERSION%.zip" 2>nul
echo [完成] 清理完成
echo.

pause
