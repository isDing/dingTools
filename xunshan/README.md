
# ✅ **方案 1（推荐）：使用 Magisk service.d 实现开机自启脚本**

Magisk 提供目录：

```
/data/adb/service.d/
```

在系统**完全启动后**会自动执行里面的脚本（以 root 权限运行）。

---

## **步骤 1：创建管理脚本文件**

> 套个管理脚本的好处就是可以添加 `&` 参数使脚本后台运行。并且脚本可以不放在 `service.d` 目录中。

在 adb shell 中执行：

```sh
su
cd /data/adb/service.d
```

创建脚本（自动点击脚本 + WebUI）：

```sh
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

或者只启动自动点击脚本：

```sh
echo -e '#!/system/bin/sh\n\nsh /data/local/tmp/xunshan/autoClickForXunShan.sh &\n' > /data/adb/service.d/start_xunshan.sh
```

---

## **步骤 2：设置权限**

```sh
chmod 755 /data/adb/service.d/start_xunshan.sh
```

---

## **步骤 3：确保脚本可执行**

例如你的脚本：

```
/data/local/tmp/xunshan/autoClickForXunShan.sh
```

确保它是可执行的：

```sh
chmod 755 /data/local/tmp/xunshan/autoClickForXunShan.sh
```

---

## **手动启动/停止 WebUI 服务**

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

### 访问 WebUI：

在手机浏览器打开：`http://127.0.0.1:8080`

---

## **脚本会在开机完成后自动运行**

重启手机后，查看：

```sh
cat /data/local/tmp/xunshan/xunshan.log
```

# [Fake Location 下载页](https://github.com/Lerist/FakeLocation/releases)

