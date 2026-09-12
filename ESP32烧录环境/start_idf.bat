@echo off
REM ESP-IDF 环境启动脚本
REM 用于启动 ESP-IDF v5.5 开发环境
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP-IDF v5.5 环境启动工具
echo ============================================
echo.

REM 设置环境变量
set "IDF_PATH=F:\esp-idf\esp-idf-v5.5"
set "IDF_PYTHON_ENV_PATH=C:\Users\1\.espressif\python_env\idf5.5_py3.9_env"
set "ESPRESSIF_PATH=C:\Users\1\.espressif"

REM 检查 ESP-IDF 是否存在
if not exist "%IDF_PATH%" (
    echo [错误] ESP-IDF 目录不存在: %IDF_PATH%
    pause
    exit /b 1
)

echo [信息] ESP-IDF 路径: %IDF_PATH%
echo [信息] Python 环境: %IDF_PYTHON_ENV_PATH%
echo.

REM 添加工具链到 PATH
set "PATH=%ESPRESSIF_PATH%\tools\xtensa-esp-elf\esp-14.2.0_20241119\xtensa-esp-elf\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\riscv32-esp-elf\esp-14.2.0_20241119\riscv32-esp-elf\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\cmake\3.30.2\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\ninja\1.12.1;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\ccache\4.10.2;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\openocd-esp32\v0.12.0-esp32-20250422\bin;%PATH%"
set "PATH=%ESPRESSIF_PATH%\tools\idf-exe\v1.0.3;%PATH%"
set "PATH=%IDF_PYTHON_ENV_PATH%\Scripts;%PATH%"

echo [完成] ESP-IDF 环境已配置！
echo.
echo 可用的命令：
echo   idf.py --version          - 查看 ESP-IDF 版本
echo   idf.py set-target esp32s3 - 设置目标芯片
echo   idf.py menuconfig         - 打开配置菜单
echo   idf.py build              - 编译项目
echo   idf.py flash              - 烧录固件
echo   idf.py flash monitor      - 烧录并监控串口
echo   idf.py monitor            - 监控串口输出
echo.
echo 提示：使用 idf_wrapper.py 代替 idf.py 以避免 MSys 警告
echo 用法: python F:\esp-idf\esp-idf-v5.5\idf_wrapper.py [命令]
echo.
echo 当前工作目录: %CD%
echo.

REM 保持命令行窗口打开
cmd /k "cd /d %CD%"
