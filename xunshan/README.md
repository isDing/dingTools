
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

创建脚本：

```sh
echo -e '#!/system/bin/sh\n\nsh /data/local/tmp/autoClickForXunShan.sh &\n' > /data/adb/service.d/start_auto.sh
```

---

## **步骤 2：设置权限**

```sh
chmod 755 /data/adb/service.d/start_auto.sh
```

---

## **步骤 3：把你平时运行的自动脚本放这里：**

例如你的脚本：

```
/data/local/tmp/autoClickForXunShan.sh
```

确保它是可执行的：

```sh
chmod 755 /data/local/tmp/autoClickForXunShan.sh
```

---

## **脚本会在开机完成后自动运行**

重启手机后，查看：

```sh
cat /data/local/tmp/xunshan.log
```

# [Fake Location 下载页](https://github.com/Lerist/FakeLocation/releases)
