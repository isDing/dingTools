#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
STATE_FILE="$ROOT_DIR/auto_xunshan_state"
BACKUP_FILE="$ROOT_DIR/auto_xunshan_state.bak"
TEMP_FILE="$ROOT_DIR/.state_tmp"

# 读取所有 POST 数据到临时文件
cat > "$TEMP_FILE"

# 提取 content_base64 参数
CONTENT_B64=$(sed 's/^content_base64=//' "$TEMP_FILE")

if [ -z "$CONTENT_B64" ]; then
  rm -f "$TEMP_FILE"
  echo '{"ok":false,"error":"content_empty"}'
  exit 1
fi

# Base64 解码
echo "$CONTENT_B64" | base64 -d > "$TEMP_FILE.decoded" 2>/dev/null
if [ $? -ne 0 ]; then
  rm -f "$TEMP_FILE" "$TEMP_FILE.decoded"
  echo '{"ok":false,"error":"decode_failed"}'
  exit 1
fi

# 备份原文件（如果存在）
if [ -f "$STATE_FILE" ]; then
  su -c "cp '$STATE_FILE' '$BACKUP_FILE'" 2>/dev/null
fi

# 保存文件（需要 root 权限）
su -c "cat '$TEMP_FILE.decoded' > '$STATE_FILE'"
SAVE_STATUS=$?

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_FILE.decoded"

if [ $SAVE_STATUS -ne 0 ]; then
  echo '{"ok":false,"error":"write_failed"}'
  exit 1
fi

# 获取文件信息
if [ -f "$STATE_FILE" ]; then
  NEW_SIZE=$(wc -c < "$STATE_FILE" 2>/dev/null)
  FILE_PERMS=$(ls -l "$STATE_FILE" 2>/dev/null | awk '{print $1}')
  echo "{\"ok\":true,\"saved\":true,\"size\":$NEW_SIZE,\"permissions\":\"$FILE_PERMS\"}"
else
  echo '{"ok":false,"error":"file_not_found"}'
fi
