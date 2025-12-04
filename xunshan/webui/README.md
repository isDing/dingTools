# XunShan WebUI (本地轻量管理面板)

目的：无需安装原生 APP，通过浏览器访问 http://127.0.0.1:8080 在手机上查看 `/data/local/tmp/xunshan/` 下的日志，并检测/启动 `autoClickForXunShan.sh` 脚本。

前置条件
- 设备已 root（脚本与日志路径位于 `/data/local/tmp`）
- 已安装 BusyBox（Magisk 可开启 BusyBox 模块）

部署步骤（在手机上执行）
1) 将本目录拷贝到手机：`/data/local/tmp/xunshan/webui`
   - 目录结构：
     - `/data/local/tmp/xunshan/webui/index.html`
     - `/data/local/tmp/xunshan/webui/app.js`
     - `/data/local/tmp/xunshan/webui/cgi-bin/status.sh`
     - `/data/local/tmp/xunshan/webui/cgi-bin/log.sh`
     - `/data/local/tmp/xunshan/webui/cgi-bin/start.sh`
2) 赋予 CGI 可执行权限：
   ```sh
   su -c 'chmod +x /data/local/tmp/xunshan/webui/cgi-bin/*.sh'
   ```
3) 启动 httpd：
   ```sh
   su -c 'mkdir -p /data/local/tmp/xunshan/webui && busybox httpd -f -p 127.0.0.1:8080 -h /data/local/tmp/xunshan/webui'
   ```
4) 在手机浏览器访问：`http://127.0.0.1:8080`

功能说明
- 状态检测：`/cgi-bin/status.sh`
- 查看日志：`/cgi-bin/log.sh`（默认尾部 300 行，文件：`/data/local/tmp/xunshan/xunshan.log`）
- 启动脚本：`/cgi-bin/start.sh`（后台启动，输出到 `/data/local/tmp/xunshan/autoClickForXunShan.out`）

可选项
- 如需查看其他日志，可在浏览器地址栏访问：
  - `http://127.0.0.1:8080/cgi-bin/log.sh?file=/data/local/tmp/xunshan/xxx.log`
  - 出于安全，仅允许 `/data/local/tmp/xunshan/` 前缀

注意事项
- httpd 仅监听本机：`127.0.0.1:8080`，外部不可访问
- 若你的 BusyBox httpd 未启 CGI 功能，请另行安装支持 CGI 的 BusyBox 版本
- 若 `ps` 字段顺序异常，可按设备具体输出调整脚本中的 `awk '{print $2}'`
- 如果脚本路径不同，修改 `start.sh` 中的 `ROOT_DIR`
