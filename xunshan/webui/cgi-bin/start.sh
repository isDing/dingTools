#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
NAME="autoClickForXunShan.sh"
SCRIPT="$ROOT_DIR/$NAME"
OUT_FILE="$ROOT_DIR/autoClickForXunShan.out"

mkdir -p "$ROOT_DIR" 2>/dev/null

running_pids() {
  # 方法 1: 使用 pgrep (如果可用)
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -f "$NAME"
  else
    # 方法 2: 遍历 /proc/*/cmdline 查找进程
    for pid_dir in /proc/[0-9]*; do
      pid=$(basename "$pid_dir")
      cmdline=$(cat "$pid_dir/cmdline" 2>/dev/null | tr '\0' ' ')
      if echo "$cmdline" | grep -q "$NAME"; then
        echo "$pid"
      fi
    done
  fi
}

PIDS=$(running_pids | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
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

PIDS=$(running_pids | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
if [ -n "$PIDS" ]; then
  echo "{\"ok\":true,\"started\":true,\"pids\":\"$PIDS\"}"
else
  echo '{"ok":false,"error":"start_failed"}'
fi

