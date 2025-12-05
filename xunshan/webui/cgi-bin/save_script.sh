#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
SCRIPT_FILE="$ROOT_DIR/autoClickForXunShan.sh"
BACKUP_FILE="$ROOT_DIR/autoClickForXunShan.sh.bak"
TEMP_FILE="$ROOT_DIR/.script_tmp"

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
if [ $? -ne 0 ] || [ ! -s "$TEMP_FILE.decoded" ]; then
  rm -f "$TEMP_FILE" "$TEMP_FILE.decoded"
  echo '{"ok":false,"error":"decode_failed"}'
  exit 1
fi

# 备份原文件
if [ -f "$SCRIPT_FILE" ]; then
  su -c "cp '$SCRIPT_FILE' '$BACKUP_FILE'"
  if [ $? -ne 0 ]; then
    rm -f "$TEMP_FILE" "$TEMP_FILE.decoded"
    echo '{"ok":false,"error":"backup_failed"}'
    exit 1
  fi
fi

# 保存文件（需要 root 权限）
su -c "cat '$TEMP_FILE.decoded' > '$SCRIPT_FILE'"
SAVE_STATUS=$?

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_FILE.decoded"

if [ $SAVE_STATUS -ne 0 ]; then
  echo '{"ok":false,"error":"write_failed"}'
  exit 1
fi

# 设置可执行权限 (0755 = rwxr-xr-x)
su -c "chmod 0755 '$SCRIPT_FILE'"
CHMOD_STATUS=$?

if [ $CHMOD_STATUS -ne 0 ]; then
  echo '{"ok":false,"error":"chmod_failed"}'
  exit 1
fi

# 验证保存是否成功且可执行
if [ ! -f "$SCRIPT_FILE" ]; then
  echo '{"ok":false,"error":"file_not_found"}'
  exit 1
fi

# 检查文件是否可执行
if [ ! -x "$SCRIPT_FILE" ]; then
  echo '{"ok":false,"error":"not_executable"}'
  exit 1
fi

# 获取文件信息
NEW_SIZE=$(wc -c < "$SCRIPT_FILE" 2>/dev/null)
FILE_PERMS=$(ls -l "$SCRIPT_FILE" 2>/dev/null | awk '{print $1}')

echo "{\"ok\":true,\"saved\":true,\"size\":$NEW_SIZE,\"permissions\":\"$FILE_PERMS\"}"
