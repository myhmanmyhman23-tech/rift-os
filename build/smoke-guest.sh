#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo RIFT_SMOKE_FAIL > /dev/ttyS0' ERR
node /usr/share/rift-os/server.cjs > /tmp/rift-smoke-center.log 2>&1 &
for _ in {1..60}; do
  if curl --fail --silent http://127.0.0.1:4180/api/status > /tmp/rift-status.json; then break; fi
  sleep 1
done
node -e 'const d=require("/tmp/rift-status.json");if(d.system.preview||!d.system.flatpak||!d.system.apps.modrinth||!d.system.apps.steam||!d.system.apps.lutris||!d.system.apps.bottles)process.exit(1)'
echo RIFT_SMOKE_OK > /dev/ttyS0
systemctl poweroff
