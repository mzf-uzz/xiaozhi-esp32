@echo off
setlocal
set "IDF_PATH=F:\esp-idf\esp-idf-v5.5"
set "IDF_PYTHON_ENV_PATH=C:\Users\1\.espressif\python_env\idf5.5_py3.9_env"
set "PYTHON=%IDF_PYTHON_ENV_PATH%\Scripts\python.exe"
set "IDF_PY=%IDF_PATH%\idf_wrapper.py"
set "PATH=C:\Users\1\.espressif\tools\xtensa-esp-elf\esp-14.2.0_20241119\xtensa-esp-elf\bin;C:\Users\1\.espressif\tools\riscv32-esp-elf\esp-14.2.0_20241119\riscv32-esp-elf\bin;C:\Users\1\.espressif\tools\cmake\3.30.2\bin;C:\Users\1\.espressif\tools\ninja\1.12.1;C:\Users\1\.espressif\tools\ccache\4.10.2;C:\Users\1\.espressif\python_env\idf5.5_py3.9_env\Scripts;C:\WINDOWS\system32;C:\WINDOWS;D:\python3.9;D:\python3.9\Scripts"
set "HTTP_PROXY=http://127.0.0.1:7897"
set "HTTPS_PROXY=http://127.0.0.1:7897"
set "http_proxy=http://127.0.0.1:7897"
set "https_proxy=http://127.0.0.1:7897"
cd /d E:\xiaozhi-esp32
python "%IDF_PY%" build
