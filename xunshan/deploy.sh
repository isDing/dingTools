#!/usr/bin/env bash
set -euo pipefail

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
REMOTE_ROOT="/data/local/tmp/xunshan"
WEBUI_REMOTE_DIR="$REMOTE_ROOT/webui"

echo "[*] XunShan Deployment Script"
echo "[*] Project root: $PROJECT_ROOT"
echo ""

# ============================================
# 步骤 1: 检查并部署 BusyBox
# ============================================
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

  LOCAL_BUSYBOX="$PROJECT_ROOT/bin/busybox"
  LOCAL_SSL_HELPER="$PROJECT_ROOT/bin/ssl_helper"

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

# ============================================
# 步骤 2: 部署主脚本
# ============================================
echo ""
echo "[*] Deploying main script..."
adb shell "mkdir -p $REMOTE_ROOT"
adb push "$PROJECT_ROOT/autoClickForXunShan.sh" "$REMOTE_ROOT/" >/dev/null
adb shell "chmod 0755 $REMOTE_ROOT/autoClickForXunShan.sh"
echo "[+] Main script deployed: $REMOTE_ROOT/autoClickForXunShan.sh"

# ============================================
# 步骤 3: 部署 WebUI 文件
# ============================================
echo ""
echo "[*] Deploying WebUI files..."
adb shell "mkdir -p $WEBUI_REMOTE_DIR/cgi-bin"
adb push "$PROJECT_ROOT/webui/index.html" "$WEBUI_REMOTE_DIR/" >/dev/null
adb push "$PROJECT_ROOT/webui/app.js" "$WEBUI_REMOTE_DIR/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/status.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/log.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/start.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/stop.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/clear_log.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/read_script.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/save_script.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/read_state.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null
adb push "$PROJECT_ROOT/webui/cgi-bin/save_state.sh" "$WEBUI_REMOTE_DIR/cgi-bin/" >/dev/null

echo "[*] Setting executable permissions..."
adb shell "chmod +x $WEBUI_REMOTE_DIR/cgi-bin/*.sh"
echo "[+] WebUI files deployed successfully"

# ============================================
# 完成
# ============================================
echo ""
echo "=========================================="
echo "[+] Deployment completed successfully!"
echo "=========================================="
echo ""
echo "Deployed files:"
echo "  - Main script: $REMOTE_ROOT/autoClickForXunShan.sh"
echo "  - WebUI: $WEBUI_REMOTE_DIR"
echo "  - BusyBox: $BUSYBOX_CMD"
echo ""
echo "Next steps:"
echo ""
echo "1. Start the main script (manual):"
echo "   adb shell \"su -c 'sh $REMOTE_ROOT/autoClickForXunShan.sh &'\""
echo ""
echo "2. Start the WebUI (manual):"
echo "   adb shell \"su -c 'cd $WEBUI_REMOTE_DIR && $BUSYBOX_CMD httpd -p 127.0.0.1:8080 &'\""
echo ""
echo "3. Access WebUI in phone browser:"
echo "   http://127.0.0.1:8080"
echo ""
echo "4. For auto-start on boot, see README.md"
echo ""
