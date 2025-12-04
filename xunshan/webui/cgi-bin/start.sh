#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
NAME="autoClickForXunShan.sh"
SCRIPT="$ROOT_DIR/$NAME"
OUT_FILE="$ROOT_DIR/autoClickForXunShan.out"

mkdir -p "$ROOT_DIR" 2>/dev/null

running_pids() {
  ps 2>/dev/null | grep "$NAME" | grep -v grep | awk '{print $2}'
}

PIDS=$(running_pids | tr '\n' ' ')
if [ -n "$PIDS" ]; then
  echo "{\"ok\":true,\"already_running\":true,\"pids\":\"$PIDS\"}"
  exit 0
fi

if [ ! -f "$SCRIPT" ]; then
  echo '{"ok":false,"error":"script_not_found"}'
  exit 0
fi

chmod +x "$SCRIPT" 2>/dev/null
( sh "$SCRIPT" >"$OUT_FILE" 2>&1 & )
sleep 1

PIDS=$(running_pids | tr '\n' ' ')
if [ -n "$PIDS" ]; then
  echo "{\"ok\":true,\"started\":true,\"pids\":\"$PIDS\"}"
else
  echo '{"ok":false,"error":"start_failed"}'
fi
