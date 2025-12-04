#!/usr/bin/env bash
set -euo pipefail

DOC_LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
DOC_REMOTE_DIR="/data/local/tmp/xunshan/webui"

echo $DOC_LOCAL_DIR
echo $DOC_REMOTE_DIR

echo "[*] Checking BusyBox availability..."
BUSYBOX_PATHS=(
  "/data/local/tmp/busybox"
  "/data/adb/magisk/busybox"
  "/data/adb/ksu/bin/busybox"
  "/data/adb/ap/bin/busybox"
  "/system/xbin/busybox"
  "busybox"
)

BUSYBOX_CMD=""
for bb_path in "${BUSYBOX_PATHS[@]}"; do
  if adb shell "test -f $bb_path && test -s $bb_path && $bb_path --list 2>/dev/null | grep -q httpd" 2>/dev/null; then
    BUSYBOX_CMD="$bb_path"
    echo "[+] Found working BusyBox with httpd at: $BUSYBOX_CMD"
    break
  fi
done

# 如果没有找到可用的 BusyBox，尝试从本地拷贝
if [ -z "$BUSYBOX_CMD" ]; then
  echo "[-] No working BusyBox found on device"

  LOCAL_BUSYBOX="$(dirname "$DOC_LOCAL_DIR")/busybox"
  LOCAL_SSL_HELPER="$(dirname "$DOC_LOCAL_DIR")/ssl_helper"

  if [ -f "$LOCAL_BUSYBOX" ]; then
    echo "[*] Found local busybox, pushing to device..."
    adb push "$LOCAL_BUSYBOX" /data/local/tmp/busybox >/dev/null
    adb shell "chmod +x /data/local/tmp/busybox"

    # 验证推送的 busybox 是否可用
    if adb shell "/data/local/tmp/busybox --list 2>/dev/null | grep -q httpd" 2>/dev/null; then
      BUSYBOX_CMD="/data/local/tmp/busybox"
      echo "[+] Successfully deployed busybox to /data/local/tmp/busybox"

      # 如果有 ssl_helper 也一起推送
      if [ -f "$LOCAL_SSL_HELPER" ]; then
        echo "[*] Pushing ssl_helper to device..."
        adb push "$LOCAL_SSL_HELPER" /data/local/tmp/ssl_helper >/dev/null
        adb shell "chmod +x /data/local/tmp/ssl_helper"
        echo "[+] Successfully deployed ssl_helper to /data/local/tmp/ssl_helper"
      fi
    else
      echo "[-] ERROR: Deployed busybox is not working on device!"
      echo "    The busybox binary may not be compatible with your device architecture."
      exit 1
    fi
  else
    echo "[-] ERROR: No working BusyBox found!"
    echo "    Local busybox not found at: $LOCAL_BUSYBOX"
    echo "    Please install BusyBox:"
    echo "    1. Install Magisk BusyBox module, or"
    echo "    2. Download busybox binary and place at: $LOCAL_BUSYBOX"
    exit 1
  fi
fi

echo "[*] Pushing files to device..."
adb shell "mkdir -p $DOC_REMOTE_DIR/cgi-bin"
adb push "$DOC_LOCAL_DIR/index.html" "$DOC_REMOTE_DIR/" >/dev/null
adb push "$DOC_LOCAL_DIR/app.js" "$DOC_REMOTE_DIR/" >/dev/null
adb push "$DOC_LOCAL_DIR/cgi-bin/status.sh" "$DOC_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$DOC_LOCAL_DIR/cgi-bin/log.sh" "$DOC_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$DOC_LOCAL_DIR/cgi-bin/start.sh" "$DOC_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$DOC_LOCAL_DIR/cgi-bin/stop.sh" "$DOC_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$DOC_LOCAL_DIR/cgi-bin/clear_log.sh" "$DOC_REMOTE_DIR/cgi-bin/" >/dev/null

echo "[*] Setting executable permissions..."
adb shell "chmod +x $DOC_REMOTE_DIR/cgi-bin/*.sh"

echo "[+] Deployment completed successfully!"
echo ""
echo "To start the web server, run:"
echo "  adb shell \"su -c 'cd $DOC_REMOTE_DIR && $BUSYBOX_CMD httpd -p 127.0.0.1:8080 &'\""
echo ""
echo "Or on the device (via terminal):"
echo "  su -c 'cd $DOC_REMOTE_DIR && $BUSYBOX_CMD httpd -p 127.0.0.1:8080 &'"
echo ""
echo "For auto-start on boot, see README.md"
