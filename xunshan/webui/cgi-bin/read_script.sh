#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
SCRIPT_FILE="$ROOT_DIR/autoClickForXunShan.sh"

# 检查脚本文件是否存在
if [ ! -f "$SCRIPT_FILE" ]; then
  echo '{"ok":false,"error":"script_not_found"}'
  exit 0
fi

# 读取脚本内容并编码为 JSON
# 使用 base64 编码避免 JSON 转义问题
if command -v base64 >/dev/null 2>&1; then
  CONTENT=$(cat "$SCRIPT_FILE" | base64 | tr -d '\n')
  echo "{\"ok\":true,\"content_base64\":\"$CONTENT\"}"
else
  # 如果没有 base64，使用原始内容（需要转义）
  CONTENT=$(cat "$SCRIPT_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')
  echo "{\"ok\":true,\"content\":\"$CONTENT\"}"
fi
