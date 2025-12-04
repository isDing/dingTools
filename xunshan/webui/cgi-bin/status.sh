#!/system/bin/sh
echo "Content-Type: application/json"
echo

NAME="autoClickForXunShan.sh"

# 方法 1: 使用 pgrep (如果可用)
if command -v pgrep >/dev/null 2>&1; then
  _pids=$(pgrep -f "$NAME" | tr '\n' ' ')
else
  # 方法 2: 遍历 /proc/*/cmdline 查找进程
  _pids=""
  for pid_dir in /proc/[0-9]*; do
    pid=$(basename "$pid_dir")
    cmdline=$(cat "$pid_dir/cmdline" 2>/dev/null | tr '\0' ' ')
    if echo "$cmdline" | grep -q "$NAME"; then
      _pids="$_pids$pid "
    fi
  done
fi

# 去除首尾空格
_pids=$(echo "$_pids" | sed 's/^ *//;s/ *$//')

if [ -n "$_pids" ]; then
  echo "{\"running\":true,\"pids\":\"$_pids\"}"
else
  echo '{"running":false}'
fi

