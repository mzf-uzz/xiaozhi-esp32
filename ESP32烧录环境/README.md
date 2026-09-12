# ESP32 烧录环境配置指南

本目录包含用于配置和烧录小智桌面机器人固件的工具脚本，支持 Windows 和 Linux/Git Bash 环境。

## 📁 文件说明

### Windows 版本 (.bat)
| 文件名 | 功能描述 |
|--------|----------|
| `setup_full.bat` | **一键配置脚本** - 使用代理下载并安装 ESP-IDF 到 F 盘 |
| `install_idf.bat` | ESP-IDF 安装脚本 |
| `setup_env.bat` | 环境配置脚本，设置 ESP-IDF 环境变量 |
| `start_idf.bat` | 启动 ESP-IDF 开发环境 |
| `flash.bat` | 固件烧录脚本，支持多种烧录模式 |
| `test_env.bat` | 环境测试脚本，检查环境配置是否正确 |

### Linux/Git Bash 版本 (.sh)
| 文件名 | 功能描述 |
|--------|----------|
| `setup_full.sh` | **一键配置脚本** - 使用代理下载并安装 ESP-IDF 到 F 盘 |
| `start_idf.sh` | 启动 ESP-IDF 开发环境 |
| `flash.sh` | 固件烧录脚本，支持多种烧录模式 |
| `test_env.sh` | 环境测试脚本，检查环境配置是否正确 |

### 文档
| 文件名 | 功能描述 |
|--------|----------|
| `README.md` | 详细使用说明文档 |
| `快速入门.txt` | 快速入门指南 |

## 🚀 快速开始

### 方式一：Windows 命令提示符 (推荐)

#### 第一步：一键配置环境
```batch
双击运行: setup_full.bat
```

这个脚本会自动：
- ✅ 检查 VPN 代理连接
- ✅ 下载 ESP-IDF v5.5 (使用代理)
- ✅ 安装到 F:\esp-idf
- ✅ 安装工具链
- ✅ 配置环境变量
- ✅ 生成配置文件

**预计耗时：30-60 分钟**

#### 第二步：测试环境
```batch
双击运行: test_env.bat
```

#### 第三步：启动环境
```batch
双击运行: start_idf.bat
```

#### 第四步：烧录固件
```batch
双击运行: flash.bat
```

### 方式二：Git Bash (推荐用于开发)

#### 第一步：一键配置环境
```bash
# 在 Git Bash 中运行
chmod +x setup_full.sh
./setup_full.sh
```

#### 第二步：测试环境
```bash
chmod +x test_env.sh
./test_env.sh
```

#### 第三步：启动环境
```bash
chmod +x start_idf.sh
source ./start_idf.sh
```

#### 第四步：烧录固件
```bash
chmod +x flash.sh
./flash.sh
```

## 📋 详细说明

### 一键配置脚本 (setup_full.bat / setup_full.sh)

**功能：**
- 使用 VPN 代理下载 ESP-IDF (解决 GitHub 访问问题)
- 自动安装到 F 盘 (约 3GB 空间)
- 配置所有必要的环境变量
- 安装工具链 (Xtensa, RISC-V, CMake, Ninja)

**代理配置：**
- HTTP 代理: `http://127.0.0.1:7897`
- HTTPS 代理: `http://127.0.0.1:7897`
- 使用 Socloud VPN

**安装路径：**
- ESP-IDF: `F:\esp-idf\esp-idf-v5.5`
- 工具链: `C:\Users\<用户名>\.espressif\tools`

**下载内容：**
- ESP-IDF v5.5 源码 (~500MB)
- 工具链编译器 (~1.5GB)
- Python 虚拟环境
- CMake, Ninja 等工具

### 环境测试脚本 (test_env.bat / test_env.sh)

**测试项目：**

1. **代理连接** - 检查 VPN 代理是否正常
2. **IDF_PATH 环境变量** - 检查是否设置
3. **ESP-IDF export 脚本** - 检查 `export.bat/sh` 是否存在
4. **Python 环境** - 检查 Python 虚拟环境
5. **工具链** - 检查 Xtensa 工具链
6. **CMake** - 检查 CMake 安装
7. **Ninja** - 检查 Ninja 安装
8. **串口驱动** - 检测可用的串口设备
9. **项目文件** - 检查 `CMakeLists.txt` 是否存在

### 启动脚本 (start_idf.bat / start_idf.sh)

**功能：**
- 设置 ESP-IDF 工具链路径
- 激活 Python 虚拟环境
- 加载 ESP-IDF 环境变量
- 提供常用命令提示

**环境变量设置：**
- 添加 Xtensa 工具链到 PATH
- 添加 RISC-V 工具链到 PATH
- 添加 CMake 到 PATH
- 添加 Ninja 到 PATH

### 烧录脚本 (flash.bat / flash.sh)

**支持的烧录模式：**

1. **标准烧录 (USB 串口)**
   - 使用默认波特率烧录
   - 适用于大多数开发板
   - 命令：`idf.py -p COMx flash`

2. **高速烧录 (USB 串口)**
   - 使用 921600 波特率
   - 烧录速度更快
   - 命令：`idf.py -p COMx -b 921600 flash`

3. **OTA 烧录 (网络)**
   - 通过 WiFi 网络烧录
   - 需要设备已连接到同一网络
   - 命令：`idf.py ota --ip <IP> flash`

4. **仅编译不烧录**
   - 只编译项目，不烧录到设备
   - 生成固件文件：`build/xiaozhi.bin`

5. **烧录并监控串口**
   - 烧录后自动打开串口监控
   - 可以查看设备输出日志

6. **仅监控串口**
   - 只打开串口监控，不烧录
   - 按 `Ctrl+]` 退出监控

7. **清理并重新编译烧录**
   - 清理构建目录
   - 重新设置目标芯片
   - 重新编译并烧录

## 🔧 常见问题

### 1. 代理连接失败

**症状：**
```
[错误] 代理连接失败！
```

**解决方法：**
1. 确保 VPN 已连接 (Socloud VPN)
2. 检查代理地址：`http://127.0.0.1:7897`
3. 测试代理：`bash ~/.claude/skills/web-fetch/scripts/test-proxy.sh`

### 2. 下载速度慢或失败

**症状：**
```
[错误] 下载失败！
```

**解决方法：**
1. 检查 VPN 连接状态
2. 尝试更换 VPN 节点
3. 手动下载：
   - URL: https://github.com/espressif/esp-idf/releases/download/v5.5/esp-idf-v5.5.zip
   - 保存到: `F:\esp-idf\esp-idf-v5.5.zip`
4. 重新运行安装脚本

### 3. 磁盘空间不足

**症状：**
```
[错误] 无法创建目录
```

**解决方法：**
1. 检查 F 盘可用空间 (需要约 5GB)
2. 清理 F 盘空间
3. 或修改脚本中的 `INSTALL_DIR` 变量到其他盘符

### 4. 工具链安装失败

**症状：**
```
[错误] 工具链安装失败！
```

**解决方法：**
1. 检查网络连接
2. 确保代理正常工作
3. 手动运行安装脚本：
   ```bash
   cd /f/esp-idf/esp-idf-v5.5
   ./install.sh
   ```

### 5. 串口未识别

**症状：**
```
[警告] 未发现串口设备
```

**解决方法：**
1. 检查 USB 线缆连接
2. 安装串口驱动：
   - CP2102 驱动: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
   - CH340 驱动: http://www.wch.cn/downloads/CH341SER_EXE.html
3. 检查设备管理器中是否有未知设备

### 6. 烧录失败

**症状：**
```
[错误] 烧录失败！
```

**解决方法：**
1. **进入下载模式：**
   - 按住 `BOOT` 按钮
   - 按一下 `RESET` 按钮
   - 松开 `BOOT` 按钮

2. **检查串口端口：**
   - 确认选择的 COM 端口正确
   - 尝试其他 COM 端口

3. **降低波特率：**
   - 使用标准烧录模式
   - 避免使用高速烧录

### 7. 编译失败

**症状：**
```
[错误] 编译失败！
```

**解决方法：**
1. **清理构建目录：**
   ```bash
   idf.py fullclean
   ```

2. **重新设置目标芯片：**
   ```bash
   idf.py set-target esp32s3
   ```

3. **检查依赖：**
   ```bash
   idf.py reconfigure
   ```

### 8. Python 环境问题

**症状：**
```
[警告] Python 虚拟环境不存在
```

**解决方法：**
1. 重新运行安装脚本
2. 或手动创建 Python 环境：
   ```bash
   python -m venv /c/Users/$USERNAME/.espressif/python_env/idf5.5_py3.9_env
   ```

## 📝 使用示例

### 示例 1：首次安装 (Windows)

```batch
# 1. 一键配置环境 (使用代理下载)
双击运行: setup_full.bat

# 2. 测试环境
双击运行: test_env.bat

# 3. 启动环境
双击运行: start_idf.bat

# 4. 烧录固件
双击运行: flash.bat
# 选择选项 1 (标准烧录)
# 输入串口端口，例如: COM3
```

### 示例 2：首次安装 (Git Bash)

```bash
# 1. 一键配置环境
chmod +x setup_full.sh
./setup_full.sh

# 2. 测试环境
chmod +x test_env.sh
./test_env.sh

# 3. 启动环境
chmod +x start_idf.sh
source ./start_idf.sh

# 4. 烧录固件
chmod +x flash.sh
./flash.sh
```

### 示例 3：更新固件

```bash
# 1. 启动环境
source ./start_idf.sh

# 2. 烧录固件
./flash.sh
# 选择选项 5 (烧录并监控串口)
```

### 示例 4：调试编译问题

```bash
# 1. 启动环境
source ./start_idf.sh

# 2. 清理并重新编译
./flash.sh
# 选择选项 7 (清理并重新编译烧录)
```

## 🔗 相关链接

- [ESP-IDF 官方文档](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/)
- [ESP-IDF 编程指南](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32s3/api-guides/)
- [小智桌面机器人项目](https://github.com/qebabe/xiaozhi-esp32)
- [CP2102 驱动下载](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- [CH340 驱动下载](http://www.wch.cn/downloads/CH341SER_EXE.html)

## 📞 技术支持

如遇到问题，请：

1. 查看本文档的常见问题部分
2. 运行 `test_env.sh` 或 `test_env.bat` 检查环境配置
3. 查看 ESP-IDF 官方文档
4. 加入 QQ 群交流：
   - 二群：34974022
   - 一群(已满)：183253687

## 🎯 下一步

环境配置完成后，你可以：

1. **编译项目**
   ```bash
   idf.py set-target esp32s3
   idf.py build
   ```

2. **烧录固件**
   ```bash
   idf.py -p COM3 flash
   ```

3. **监控串口**
   ```bash
   idf.py -p COM3 monitor
   ```

4. **配置项目**
   ```bash
   idf.py menuconfig
   ```

---

**最后更新：2026-09-11**
**作者：Claude Code**
