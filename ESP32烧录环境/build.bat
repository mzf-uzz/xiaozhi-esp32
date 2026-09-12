@echo off
setlocal

set "IDF_PATH=F:\esp-idf\esp-idf-v5.5"
set "IDF_PYTHON_ENV_PATH=C:\Users\1\.espressif\python_env\idf5.5_py3.9_env"
set "PYTHON=%IDF_PYTHON_ENV_PATH%\Scripts\python.exe"
set "IDF_PY=%IDF_PATH%\idf_wrapper.py"

set "PATH=C:\Users\1\.espressif\tools\xtensa-esp-elf\esp-14.2.0_20241119\xtensa-esp-elf\bin;C:\Users\1\.espressif\tools\riscv32-esp-elf\esp-14.2.0_20241119\riscv32-esp-elf\bin;C:\Users\1\.espressif\tools\cmake\3.30.2\bin;C:\Users\1\.espressif\tools\ninja\1.12.1;C:\Users\1\.espressif\tools\ccache\4.10.2;C:\Users\1\.espressif\python_env\idf5.5_py3.9_env\Scripts;C:\WINDOWS\system32;C:\WINDOWS;D:\python3.9;D:\python3.9\Scripts"

cd /d E:\xiaozhi-esp32

echo ============================================
echo [1/3] 设置目标芯片为 ESP32-S3...
echo ============================================
"%PYTHON%" "%IDF_PY%" set-target esp32s3
if errorlevel 1 (
    echo [错误] 设置目标芯片失败！
    pause
    exit /b 1
)

echo.
echo ============================================
echo [2/3] 配置项目 (menuconfig)...
echo ============================================
echo 跳过menuconfig，使用默认配置...

echo.
echo ============================================
echo [3/3] 编译项目...
echo ============================================
"%PYTHON%" "%IDF_PY%" build
if errorlevel 1 (
    echo [错误] 编译失败！
    pause
    exit /b 1
)

echo.
echo ============================================
echo 编译完成！
echo ============================================
echo 固件位于: E:\xiaozhi-esp32\build\xiaozhi.bin
echo.
pause
