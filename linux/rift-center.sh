#!/usr/bin/env bash
set -Eeuo pipefail
runtime_dir="${XDG_RUNTIME_DIR:-$HOME/.cache}/rift-os"
mkdir -p "$runtime_dir"
log_file="$runtime_dir/center.log"
# flock prevents duplicate background servers; the lock follows the Node process.
if flock -n "$runtime_dir/center.lock" true; then
  # shellcheck disable=SC2016
  nohup flock -n "$runtime_dir/center.lock" bash -c 'exec node "$1" > "$2" 2>&1' rift-center "${RIFT_APP_ROOT:-$HOME/.local/share/rift-os}/server.cjs" "$log_file" < /dev/null > /dev/null 2>&1 &
fi
for _ in {1..50}; do
  url="$(sed -n 's/^RIFT OS Control Center: //p' "$log_file" 2>/dev/null | tail -n 1 || true)"
  if [[ -n "$url" ]]; then xdg-open "$url"; exit 0; fi
  sleep 0.1
done
echo 'Could not start RIFT OS. See:' "$log_file" >&2
exit 1
