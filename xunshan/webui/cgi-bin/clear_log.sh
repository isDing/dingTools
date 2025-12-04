#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
LOG_FILE="$ROOT_DIR/xunshan.log"

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
  echo '{"ok":false,"error":"log_not_found"}'
  exit 0
fi

# 备份当前日志大小
OLD_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo "0")

# 清空日志文件 (需要 root 权限)
su -c "echo '' > $LOG_FILE" 2>/dev/null

sleep 0.5

# 检查是否清空成功
NEW_SIZE=$(wc -c < "$LOG_FILE" 2>/dev/null || echo "0")

if [ "$NEW_SIZE" -lt 10 ]; then
  echo "{\"ok\":true,\"cleared\":true,\"old_size\":$OLD_SIZE}"
else
  echo '{"ok":false,"error":"clear_failed"}'
fi
