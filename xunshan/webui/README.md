# XunShan WebUI (本地轻量管理面板)

目的：无需安装原生 APP，通过浏览器访问 http://127.0.0.1:8080 在手机上查看 `/data/local/tmp/xunshan/` 下的日志，并管理 `autoClickForXunShan.sh` 脚本。

## 前置条件
- 设备已 root（脚本与日志路径位于 `/data/local/tmp/xunshan/`）
- 已安装 BusyBox（如果设备上没有，部署脚本会自动推送）

## 快速部署

在电脑上通过 ADB 部署（推荐）：

```bash
bash xunshan/webui/deploy_via_adb.sh
```

部署脚本会自动完成：
1. 检测并推送 BusyBox（如果需要）
2. 推送所有 WebUI 文件到 `/data/local/tmp/xunshan/webui`
3. 设置 CGI 脚本执行权限

## 启动 WebUI 服务（或使用开机自启）

部署完成后，在设备上启动 httpd：

```sh
# 通过 ADB 启动
adb shell "su -c 'cd /data/local/tmp/xunshan/webui && /data/local/tmp/busybox httpd -p 127.0.0.1:8080 &'"

# 或在设备终端中启动
su -c 'cd /data/local/tmp/xunshan/webui && /data/local/tmp/busybox httpd -p 127.0.0.1:8080 &'
```

## 访问 WebUI

在手机浏览器打开：`http://127.0.0.1:8080`

## 功能说明

- ✅ **查看脚本状态**：实时显示脚本运行状态和 PID
- ✅ **启动脚本**：一键后台启动 autoClickForXunShan.sh
- ✅ **停止脚本**：一键停止运行中的脚本
- ✅ **查看日志**：实时查看最近 300 行日志
- ✅ **清空日志**：清空日志文件（需确认）
- ✅ **自动刷新**：每 10 秒自动更新状态和日志

## 开机自启

参考 [xunshan/README.md](../README.md) 中的 Magisk service.d 配置说明。

## 注意事项

- httpd 仅监听本机：`127.0.0.1:8080`，外部不可访问
- 所有脚本操作均需要 root 权限
- 日志文件路径：`/data/local/tmp/xunshan/xunshan.log`
