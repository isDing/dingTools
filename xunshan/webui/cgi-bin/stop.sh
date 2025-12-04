#!/system/bin/sh
echo "Content-Type: application/json"
echo

NAME="autoClickForXunShan.sh"

# 查找进程
find_pids() {
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

PIDS=$(find_pids)

if [ -z "$PIDS" ]; then
  echo '{"ok":false,"error":"not_running"}'
  exit 0
fi

# 停止进程 (需要 root 权限)
for pid in $PIDS; do
  su -c "kill $pid" 2>/dev/null
done

sleep 1

# 检查是否还在运行
REMAINING=$(find_pids)
if [ -z "$REMAINING" ]; then
  echo "{\"ok\":true,\"stopped\":true,\"pids\":\"$(echo $PIDS | tr '\n' ' ')\"}"
else
  # 如果还在运行，强制杀死
  for pid in $REMAINING; do
    su -c "kill -9 $pid" 2>/dev/null
  done
  sleep 0.5
  FINAL_CHECK=$(find_pids)
  if [ -z "$FINAL_CHECK" ]; then
    echo "{\"ok\":true,\"stopped\":true,\"force_killed\":true,\"pids\":\"$(echo $PIDS | tr '\n' ' ')\"}"
  else
    echo '{"ok":false,"error":"stop_failed"}'
  fi
fi
