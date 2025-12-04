#!/system/bin/sh
echo "Content-Type: application/json"
echo

NAME="autoClickForXunShan.sh"

_pids=$(ps 2>/dev/null | grep "$NAME" | grep -v grep | awk '{print $2}' | tr '\n' ' ')
if [ -n "$_pids" ]; then
  echo "{\"running\":true,\"pids\":\"$_pids\"}"
else
  echo '{"running":false}'
fi

