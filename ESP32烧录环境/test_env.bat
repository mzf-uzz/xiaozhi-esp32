@echo off
REM ESP-IDF 环境测试脚本
REM 用于测试 ESP-IDF 开发环境是否正确配置
REM 作者: Claude Code
REM 日期: 2026-09-11

setlocal enabledelayedexpansion

echo ============================================
echo ESP-IDF 环境测试工具
echo ============================================
echo.

set "TEST_PASS=0"
set "TEST_FAIL=0"

REM 测试 1: 检查 IDF_PATH 环境变量
echo [测试 1/8] 检查 IDF_PATH 环境变量...
if "%IDF_PATH%"=="" (
    echo [失败] IDF_PATH 环境变量未设置
    set /a TEST_FAIL+=1
) else (
    if exist "%IDF_PATH%" (
        echo [通过] IDF_PATH=%IDF_PATH%
        set /a TEST_PASS+=1
    ) else (
        echo [失败] IDF_PATH 目录不存在: %IDF_PATH%
        set /a TEST_FAIL+=1
    )
)
echo.

REM 测试 2: 检查 ESP-IDF export 脚本
echo [测试 2/8] 检查 ESP-IDF export 脚本...
if exist "%IDF_PATH%\export.bat" (
    echo [通过] export.bat 存在
    set /a TEST_PASS+=1
) else (
    echo [失败] 未找到 export.bat
    set /a TEST_FAIL+=1
)
echo.

REM 测试 3: 检查 Python 环境
echo [测试 3/8] 检查 Python 环境...
set "ESPRESSIF_PATH=C:\Users\%USERNAME%\.espressif"
if exist "%ESPRESSIF_PATH%\python_env\idf5.5_py3.9_env" (
    echo [通过] Python 虚拟环境存在
    set /a TEST_PASS+=1
) else (
    echo [警告] Python 虚拟环境不存在，可能需要安装
    set /a TEST_FAIL+=1
)
echo.

REM 测试 4: 检查工具链
echo [测试 4/8] 检查工具链...
set "XTENSA_PATH=%ESPRESSIF_PATH%\tools\xtensa-esp-elf\xtensa-esp-elf\bin"
if exist "%XTENSA_PATH%" (
    echo [通过] Xtensa 工具链存在
    set /a TEST_PASS+=1
) else (
    echo [失败] Xtensa 工具链不存在
    set /a TEST_FAIL+=1
)
echo.

REM 测试 5: 检查 CMake
echo [测试 5/8] 检查 CMake...
set "CMAKE_PATH=%ESPRESSIF_PATH%\tools\cmake\3.30.2\bin"
if exist "%CMAKE_PATH%" (
    echo [通过] CMake 存在
    set /a TEST_PASS+=1
) else (
    echo [失败] CMake 不存在
    set /a TEST_FAIL+=1
)
echo.

REM 测试 6: 检查 Ninja
echo [测试 6/8] 检查 Ninja...
set "NINJA_PATH=%ESPRESSIF_PATH%\tools\ninja\1.12.1"
if exist "%NINJA_PATH%" (
    echo [通过] Ninja 存在
    set /a TEST_PASS+=1
) else (
    echo [失败] Ninja 不存在
    set /a TEST_FAIL+=1
)
echo.

REM 测试 7: 检查串口驱动
echo [测试 7/8] 检查串口驱动...
echo 正在检测串口设备...
set "SERIAL_FOUND=0"
for /f "tokens=*" %%i in ('mode') do (
    echo %%i | findstr /C:"COM" >nul
    if not errorlevel 1 (
        echo [信息] 发现串口: %%i
        set "SERIAL_FOUND=1"
    )
)
if "!SERIAL_FOUND!"=="1" (
    echo [通过] 发现串口设备
    set /a TEST_PASS+=1
) else (
    echo [警告] 未发现串口设备，请检查：
    echo   1. 开发板是否已连接
    echo   2. USB 线缆是否正常
    echo   3. 串口驱动是否安装 (CP2102/CH340)
    set /a TEST_FAIL+=1
)
echo.

REM 测试 8: 检查项目文件
echo [测试 8/8] 检查项目文件...
set "PROJECT_DIR=%~dp0.."
if exist "%PROJECT_DIR%\CMakeLists.txt" (
    echo [通过] 项目 CMakeLists.txt 存在
    set /a TEST_PASS+=1
) else (
    echo [失败] 未找到项目 CMakeLists.txt
    set /a TEST_FAIL+=1
)
echo.

REM 显示测试结果
echo ============================================
echo 测试结果
echo ============================================
echo.
echo 通过: %TEST_PASS%
echo 失败: %TEST_FAIL%
echo.

if %TEST_FAIL%==0 (
    echo [结论] 所有测试通过！环境配置正确。
    echo.
    echo 下一步操作：
    echo 1. 运行 start_idf.bat 启动 ESP-IDF 环境
    echo 2. 运行 flash.bat 烧录固件
) else (
    echo [结论] 存在 %TEST_FAIL% 个问题需要解决。
    echo.
    echo 建议操作：
    echo 1. 运行 setup_env.bat 重新配置环境
    echo 2. 安装缺失的组件
    echo 3. 检查串口驱动
)
echo.

REM 显示详细信息
echo ============================================
echo 详细信息
echo ============================================
echo.
echo ESP-IDF 路径: %IDF_PATH%
echo 工具链路径: %ESPRESSIF_PATH%\tools
echo Python 环境: %ESPRESSIF_PATH%\python_env\idf5.5_py3.9_env
echo 项目目录: %PROJECT_DIR%
echo.

REM 检查 idf.py 是否可用
echo [额外测试] 检查 idf.py 命令...
where idf.py >nul 2>&1
if errorlevel 1 (
    echo [警告] idf.py 不在 PATH 中
    echo 请运行 start_idf.bat 启动 ESP-IDF 环境
) else (
    echo [通过] idf.py 命令可用
    echo.
    echo ESP-IDF 版本信息:
    call idf.py --version
)
echo.

pause
