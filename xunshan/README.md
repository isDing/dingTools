# XunShan 自动巡护系统

Android 自动化巡护脚本 + Web 管理面板

## 项目简介

本项目包含两部分：

1. **自动巡护脚本** (`autoClickForXunShan.sh`)：自动执行巡护任务的 Shell 脚本
2. **WebUI 管理面板**：通过浏览器管理脚本、查看日志、查看状态

## 前置条件

- Android 设备已 root
- 安装了 ADB（电脑端）
- 已安装 BusyBox（如果没有，部署脚本会自动推送）
- 已安装 [Fake Location](https://github.com/Lerist/FakeLocation/releases)（用于位置模拟）

## 快速部署

在电脑上通过 ADB 一键部署所有文件：

```bash
bash deploy.sh
```

部署脚本会自动完成：
1. ✅ 检测并部署 BusyBox（如果设备上没有）
2. ✅ 部署主脚本 `autoClickForXunShan.sh` 到 `/data/local/tmp/xunshan/`
3. ✅ 部署 WebUI 文件到 `/data/local/tmp/xunshan/webui/`
4. ✅ 设置所有脚本的执行权限

## 使用方式

### 方式 1: 手动启动

#### 启动主脚本：

```sh
adb shell "su -c 'sh /data/local/tmp/xunshan/autoClickForXunShan.sh &'"
```

#### 启动 WebUI：

```sh
adb shell "su -c 'cd /data/local/tmp/xunshan/webui && /data/local/tmp/busybox httpd -p 127.0.0.1:8080 &'"
```

#### 访问 WebUI：

在手机浏览器打开：`http://127.0.0.1:8080`

### 方式 2: 开机自启（推荐）

使用 Magisk service.d 实现开机自启。

#### 步骤 1：创建启动脚本

在设备上执行（通过 adb shell 或终端）：

```sh
su
cat > /data/adb/service.d/start_xunshan.sh <<'EOF'
#!/system/bin/sh

# 启动自动点击脚本
sh /data/local/tmp/xunshan/autoClickForXunShan.sh &

# 启动 WebUI 服务（可选）
sleep 5
BUSYBOX="/data/local/tmp/busybox"
if [ -x "$BUSYBOX" ]; then
  cd /data/local/tmp/xunshan/webui
  $BUSYBOX httpd -p 127.0.0.1:8080 &
fi
EOF
```

或者只启动自动点击脚本（不启动 WebUI）：

```sh
echo -e '#!/system/bin/sh\n\nsh /data/local/tmp/xunshan/autoClickForXunShan.sh &\n' > /data/adb/service.d/start_xunshan.sh
```

#### 步骤 2：设置权限

```sh
chmod 755 /data/adb/service.d/start_xunshan.sh
```

#### 步骤 3：验证

重启手机后，查看日志：

```sh
cat /data/local/tmp/xunshan/xunshan.log
```

## WebUI 功能

通过 `http://127.0.0.1:8080` 访问 WebUI，提供以下功能：

- ✅ **查看脚本状态**：实时显示脚本运行状态和 PID
- ✅ **启动/停止脚本**：一键后台启动或停止 autoClickForXunShan.sh
- ✅ **查看日志**：实时查看最近 300 行日志
- ✅ **清空日志**：清空日志文件（需确认）
- ✅ **编辑脚本**：在线编辑 autoClickForXunShan.sh 脚本（自动备份到 .bak）
- ✅ **自动刷新**：每 10 秒自动更新状态和日志

## 手动控制 WebUI

### 启动 WebUI：

```sh
su -c 'cd /data/local/tmp/xunshan/webui && /data/local/tmp/busybox httpd -p 127.0.0.1:8080 &'
```

### 停止 WebUI：

```sh
su -c 'pkill httpd'
```

### 检查 WebUI 状态：

```sh
ps | grep httpd
netstat -tuln | grep 8080
```

## 项目结构

```
xunshan/
├── deploy.sh                   # 一键部署脚本
├── autoClickForXunShan.sh      # 主自动化脚本
├── README.md                   # 项目文档
├── bin/                        # 二进制工具目录
│   ├── busybox                 # BusyBox 二进制文件
│   └── ssl_helper              # SSL 辅助工具
└── webui/                      # Web 管理界面
    ├── index.html              # WebUI 主页面
    ├── app.js                  # 前端 JavaScript
    └── cgi-bin/                # 后端 CGI 脚本
        ├── status.sh           # 查询脚本状态
        ├── start.sh            # 启动脚本
        ├── stop.sh             # 停止脚本
        ├── log.sh              # 查看日志
        ├── clear_log.sh        # 清空日志
        ├── read_script.sh      # 读取脚本内容
        └── save_script.sh      # 保存脚本内容
```

## 设备端文件路径

部署后，设备上的文件结构：

```
/data/local/tmp/
├── busybox                            # BusyBox 可执行文件
├── ssl_helper                         # SSL 辅助工具
└── xunshan/
    ├── autoClickForXunShan.sh         # 主脚本
    ├── autoClickForXunShan.sh.bak     # 脚本备份（编辑时自动创建）
    ├── xunshan.log                    # 运行日志
    ├── auto_xunshan_state             # 状态文件
    ├── ui.xml                         # UI dump 文件
    ├── ui_lines.txt                   # UI 解析文件
    └── webui/                         # WebUI 文件
        ├── index.html
        ├── app.js
        └── cgi-bin/*.sh
```

## 注意事项

- WebUI 仅监听本机：`127.0.0.1:8080`，外部不可访问
- 所有脚本操作均需要 root 权限
- 在 WebUI 中编辑脚本时，会自动备份原文件到 `autoClickForXunShan.sh.bak`
- 日志文件路径：`/data/local/tmp/xunshan/xunshan.log`

## 常见问题

### 1. 部署后无法访问 WebUI

检查 httpd 是否正在运行：

```sh
adb shell "su -c 'netstat -tuln | grep 8080'"
```

如果没有输出，手动启动 httpd。

### 2. 脚本没有执行权限

手动设置权限：

```sh
adb shell "su -c 'chmod 0755 /data/local/tmp/xunshan/autoClickForXunShan.sh'"
```

### 3. WebUI 显示脚本未运行但实际在运行

刷新页面或点击"刷新状态/日志"按钮。

## 相关链接

- [Fake Location 下载页](https://github.com/Lerist/FakeLocation/releases)
- [BusyBox 下载页](https://busybox.net/downloads/binaries/)

## 许可证

本项目仅供个人学习和研究使用。
