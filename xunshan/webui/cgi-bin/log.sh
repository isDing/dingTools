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
  tail -n 300 "$FILE"
else
  echo "Log not found or unreadable: $FILE"
fi
