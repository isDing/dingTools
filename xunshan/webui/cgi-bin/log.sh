#!/system/bin/sh
echo "Content-Type: text/plain; charset=utf-8"
echo

ROOT_DIR="/data/local/tmp/xunshan"
FILE="$ROOT_DIR/xunshan.log"

QS="$QUERY_STRING"
if echo "$QS" | grep -q '^file='; then
  RAW=$(echo "$QS" | sed -n 's/^file=\([^&]*\).*/\1/p')
  RAW=$(echo "$RAW" | sed 's/%2F/\//gi; s/%3A/:/gi; s/%20/ /gi')
  case "$RAW" in
    "$ROOT_DIR"/*) FILE="$RAW" ;;
  esac
fi

if [ -r "$FILE" ]; then
  # 倒序输出最后 300 行（最新的在最上面）
  if command -v tac >/dev/null 2>&1; then
    # 如果有 tac 命令（busybox 通常包含）
    tail -n 300 "$FILE" | tac
  else
    # 回退方案：使用 awk 反转行
    tail -n 300 "$FILE" | awk '{a[NR]=$0} END {for(i=NR;i>0;i--) print a[i]}'
  fi
else
  echo "Log not found or unreadable: $FILE"
fi
