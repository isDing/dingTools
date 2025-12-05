#!/system/bin/sh
echo "Content-Type: application/json"
echo

ROOT_DIR="/data/local/tmp/xunshan"
STATE_FILE="$ROOT_DIR/auto_xunshan_state"

# 读取 state 文件内容
if [ -f "$STATE_FILE" ]; then
  CONTENT=$(cat "$STATE_FILE" 2>/dev/null)
  if [ -n "$CONTENT" ]; then
    # 使用 base64 编码避免 JSON 转义问题
    if command -v base64 >/dev/null 2>&1; then
      CONTENT_B64=$(echo -n "$CONTENT" | base64 | tr -d '\n')
      echo "{\"ok\":true,\"content_base64\":\"$CONTENT_B64\"}"
    else
      # 回退：直接返回内容（可能有转义问题）
      echo "{\"ok\":true,\"content\":\"$CONTENT\"}"
    fi
  else
    echo '{"ok":true,"content":""}'
  fi
else
  # 文件不存在，返回空内容
  echo '{"ok":true,"content":"","note":"file_not_found"}'
fi
