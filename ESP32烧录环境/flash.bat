@echo off
REM ESP32 固件烧录脚本
REM 用于烧录小智桌面机器人固件到 ESP32-S3 开发板
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP32 固件烧录工具
echo ============================================
echo.

REM 设置环境变量
set "IDF_PATH=F:\esp-idf\esp-idf-v5.5"
set "IDF_PYTHON_ENV_PATH=C:\Users\1\.espressif\python_env\idf5.5_py3.9_env"
set "ESPRESSIF_PATH=C:\Users\1\.espressif"
set "PYTHON=%IDF_PYTHON_ENV_PATH%\Scripts\python.exe"
set "IDF_PY=%IDF_PATH%\idf_wrapper.py"

REM 添加工具链到 PATH
set "PATH=%ESPRESSIF_PATH%\tools\xtensa-esp-elf\esp-14.2.0_20241119\xtensa-esp-elf\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\riscv32-esp-elf\esp-14.2.0_20241119\riscv32-esp-elf\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\cmake\3.30.2\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\ninja\1.12.1;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\ccache\4.10.2;%PATH%"
set "PATH=%IDF_PYTHON_ENV_PATH%\Scripts;%PATH%"

REM 检查项目目录
set "PROJECT_DIR=%~dp0.."
if not exist "%PROJECT_DIR%\CMakeLists.txt" (
    echo [错误] 未找到项目 CMakeLists.txt！
    echo 请确保此脚本位于 ESP32烧录环境 目录中
    pause
    exit /b 1
)

echo [信息] 项目目录: %PROJECT_DIR%
echo [信息] ESP-IDF: %IDF_PATH%
echo.

REM 检查是否已编译
if not exist "%PROJECT_DIR%\build" (
    echo [警告] 未找到 build 目录，需要先编译项目！
    echo.
    echo 是否现在编译？(Y/N)
    set /p COMPILE_CHOICE=
    if /i "!COMPILE_CHOICE!"=="Y" (
        echo.
        echo [步骤 1/2] 设置目标芯片为 ESP32-S3...
        cd /d "%PROJECT_DIR%"
        "%PYTHON%" "%IDF_PY%" set-target esp32s3
        if errorlevel 1 (
            echo [错误] 设置目标芯片失败！
            pause
            exit /b 1
        )
        echo.
        echo [步骤 2/2] 编译项目...
        "%PYTHON%" "%IDF_PY%" build
        if errorlevel 1 (
            echo [错误] 编译失败！
            pause
            exit /b 1
        )
    ) else (
        echo [信息] 跳过编译，请先手动编译项目
        pause
        exit /b 0
    )
)

echo.
echo ============================================
echo 烧录选项
echo ============================================
echo.
echo 请选择烧录模式：
echo.
echo 1. 标准烧录 (USB 串口)
echo 2. 高速烧录 (USB 串口，使用 921600 波特率)
echo 3. 仅编译不烧录
echo 4. 烧录并监控串口
echo 5. 仅监控串口
echo 6. 清理并重新编译烧录
echo 7. 退出
echo.
set /p FLASH_CHOICE=请输入选项 (1-7):

REM 获取串口端口
set "COM_PORT="
if "%FLASH_CHOICE%"=="1" goto :get_port
if "%FLASH_CHOICE%"=="2" goto :get_port
if "%FLASH_CHOICE%"=="4" goto :get_port
if "%FLASH_CHOICE%"=="5" goto :get_port
if "%FLASH_CHOICE%"=="6" goto :get_port
goto :flash_menu

:get_port
echo.
echo 请输入串口端口 (例如: COM3):
set /p COM_PORT=
if "!COM_PORT!"=="" (
    echo [错误] 未指定串口端口！
    pause
    exit /b 1
)
echo.

:flash_menu
cd /d "%PROJECT_DIR%"

if "%FLASH_CHOICE%"=="1" goto :standard_flash
if "%FLASH_CHOICE%"=="2" goto :high_speed_flash
if "%FLASH_CHOICE%"=="3" goto :build_only
if "%FLASH_CHOICE%"=="4" goto :flash_monitor
if "%FLASH_CHOICE%"=="5" goto :monitor_only
if "%FLASH_CHOICE%"=="6" goto :clean_flash
if "%FLASH_CHOICE%"=="7" goto :exit
echo [错误] 无效的选项！
pause
exit /b 1

:standard_flash
echo [烧录] 使用标准模式烧录到 %COM_PORT%...
"%PYTHON%" "%IDF_PY%" -p %COM_PORT% flash
if errorlevel 1 (
    echo [错误] 烧录失败！请检查串口连接，或按住BOOT按钮进入下载模式
    pause
    exit /b 1
)
echo [完成] 烧录成功！
pause
exit /b 0

:high_speed_flash
echo [烧录] 使用高速模式烧录到 %COM_PORT% (921600 bps)...
"%PYTHON%" "%IDF_PY%" -p %COM_PORT% -b 921600 flash
if errorlevel 1 (
    echo [警告] 高速烧录失败，尝试标准模式...
    "%PYTHON%" "%IDF_PY%" -p %COM_PORT% flash
    if errorlevel 1 (
        echo [错误] 烧录失败！
        pause
        exit /b 1
    )
)
echo [完成] 烧录成功！
pause
exit /b 0

:build_only
echo [编译] 仅编译项目...
"%PYTHON%" "%IDF_PY%" build
if errorlevel 1 (
    echo [错误] 编译失败！
    pause
    exit /b 1
)
echo [完成] 编译成功！固件位于: build\xiaozhi.bin
pause
exit /b 0

:flash_monitor
echo [烧录] 烧录并监控串口 %COM_PORT%...
"%PYTHON%" "%IDF_PY%" -p %COM_PORT% flash monitor
exit /b 0

:monitor_only
echo [监控] 监控串口 %COM_PORT%... (按 Ctrl+] 退出)
"%PYTHON%" "%IDF_PY%" -p %COM_PORT% monitor
exit /b 0

:clean_flash
echo [清理] 清理并重新编译烧录...
"%PYTHON%" "%IDF_PY%" fullclean
"%PYTHON%" "%IDF_PY%" set-target esp32s3
"%PYTHON%" "%IDF_PY%" -p %COM_PORT% flash
if errorlevel 1 (
    echo [错误] 烧录失败！
    pause
    exit /b 1
)
echo [完成] 清理并烧录成功！
pause
exit /b 0

:exit
echo [退出] 再见！
exit /b 0
