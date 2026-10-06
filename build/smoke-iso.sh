#!/usr/bin/env bash
set -Eeuo pipefail
image="$1"; kernel="$2"; initrd="$3"
log="${image%.iso}-boot.log"
# Direct kernel boot checks the remastered live root. El Torito structure is
# checked separately; graphical desktop, installation and games need manual tests.
set +e
timeout 600 qemu-system-x86_64 -accel tcg -m 4096 -smp 2 -display none -no-reboot \
  -cdrom "$image" -kernel "$kernel" -initrd "$initrd" \
  -append 'boot=casper console=ttyS0,115200n8 rift.smoketest=1 noprompt' \
  -serial "file:$log" -monitor none
result=$?
set -e
[[ "$result" -eq 0 ]] || { echo "QEMU exited with $result; see $log"; exit 1; }
grep -q RIFT_SMOKE_OK "$log"
if grep -q RIFT_SMOKE_FAIL "$log"; then exit 1; fi
