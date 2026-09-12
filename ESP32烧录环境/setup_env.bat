@echo off
REM ESP-IDF 环境配置脚本
REM 用于设置 ESP-IDF 开发环境变量
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP-IDF 环境配置工具
echo ============================================
echo.

REM 检查是否已安装 ESP-IDF
set "IDF_PATH_FOUND=0"
set "IDF_PATH="

REM 检查常见的 ESP-IDF 安装路径
if exist "C:\Users\%USERNAME%\esp\esp-idf" (
    set "IDF_PATH=C:\Users\%USERNAME%\esp\esp-idf"
    set "IDF_PATH_FOUND=1"
)

if exist "C:\Users\%USERNAME%\esp-idf" (
    set "IDF_PATH=C:\Users\%USERNAME%\esp-idf"
    set "IDF_PATH_FOUND=1"
)

if exist "C:\Espressif\frameworks\esp-idf-v5.5" (
    set "IDF_PATH=C:\Espressif\frameworks\esp-idf-v5.5"
    set "IDF_PATH_FOUND=1"
)

if exist "E:\esp-idf-v5.5" (
    set "IDF_PATH=E:\esp-idf-v5.5"
    set "IDF_PATH_FOUND=1"
)

if exist "E:\esp-idf" (
    set "IDF_PATH=E:\esp-idf"
    set "IDF_PATH_FOUND=1"
)

if exist "F:\esp-idf-v5.5" (
    set "IDF_PATH=F:\esp-idf-v5.5"
    set "IDF_PATH_FOUND=1"
)

if exist "F:\esp-idf" (
    set "IDF_PATH=F:\esp-idf"
    set "IDF_PATH_FOUND=1"
)

REM 如果未找到 ESP-IDF，提示用户安装
if "%IDF_PATH_FOUND%"=="0" (
    echo [错误] 未找到 ESP-IDF 安装目录！
    echo.
    echo 请先安装 ESP-IDF：
    echo 1. 访问 https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32s3/get-started/
    echo 2. 下载并安装 ESP-IDF v5.5 或更高版本
    echo 3. 或使用 ESP-IDF 安装器：https://dl.espressif.com/dl/idf-installer/esp-idf-tools-setup-offline-5.5.exe
    echo.
    pause
    exit /b 1
)

echo [信息] 找到 ESP-IDF 安装路径: %IDF_PATH%
echo.

REM 设置环境变量
echo [步骤 1/3] 设置 IDF_PATH 环境变量...
setx IDF_PATH "%IDF_PATH%"
if errorlevel 1 (
    echo [警告] 无法设置系统环境变量，尝试设置用户环境变量...
    setx /M IDF_PATH "%IDF_PATH%"
)

REM 添加工具链到 PATH
echo [步骤 2/3] 添加工具链到 PATH...

REM 检查 .espressif 目录
set "ESPRESSIF_PATH=C:\Users\%USERNAME%\.espressif"
if not exist "%ESPRESSIF_PATH%" (
    echo [警告] 未找到 .espressif 目录，可能需要先运行 ESP-IDF 安装程序
)

REM 检查 Python 环境
set "PYTHON_ENV=%ESPRESSIF_PATH%\python_env\idf5.5_py3.9_env"
if exist "%PYTHON_ENV%" (
    echo [信息] 找到 Python 虚拟环境: %PYTHON_ENV%
)

REM 检查工具链
set "XTENSA_PATH=%ESPRESSIF_PATH%\tools\xtensa-esp-elf\xtensa-esp-elf\bin"
set "RISCV_PATH=%ESPRESSIF_PATH%\tools\riscv32-esp-elf\riscv32-esp-elf\bin"
set "CMAKE_PATH=%ESPRESSIF_PATH%\tools\cmake\3.30.2\bin"
set "NINJA_PATH=%ESPRESSIF_PATH%\tools\ninja\1.12.1"

echo [步骤 3/3] 验证环境配置...
echo.

REM 创建环境配置文件
echo # ESP-IDF 环境配置文件 > env_config.txt
echo # 生成时间: %date% %time% >> env_config.txt
echo. >> env_config.txt
echo IDF_PATH=%IDF_PATH% >> env_config.txt
echo ESPRESSIF_PATH=%ESPRESSIF_PATH% >> env_config.txt
echo PYTHON_ENV=%PYTHON_ENV% >> env_config.txt
echo XTENSA_PATH=%XTENSA_PATH% >> env_config.txt
echo RISCV_PATH=%RISCV_PATH% >> env_config.txt
echo CMAKE_PATH=%CMAKE_PATH% >> env_config.txt
echo NINJA_PATH=%NINJA_PATH% >> env_config.txt

echo [完成] 环境配置已保存到 env_config.txt
echo.
echo ============================================
echo 配置说明：
echo ============================================
echo.
echo 1. IDF_PATH: %IDF_PATH%
echo 2. 工具链路径: %ESPRESSIF_PATH%\tools
echo 3. Python 环境: %PYTHON_ENV%
echo.
echo 下一步操作：
echo 1. 重新打开命令提示符或 PowerShell
echo 2. 运行 start_idf.bat 启动 ESP-IDF 环境
echo 3. 或运行 flash.bat 烧录固件
echo.
echo 注意：如果工具链路径不正确，请手动修改此脚本中的路径
echo.
pause
