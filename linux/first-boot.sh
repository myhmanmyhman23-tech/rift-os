#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C DEBIAN_FRONTEND=noninteractive
# Do not detect build-host/live-session hardware as the installed target.
if grep -qw 'boot=casper' /proc/cmdline; then exit 0; fi
mkdir -p /var/lib/rift-os
status(){ printf '{"state":"%s","message":"%s"}\n' "$1" "$2" > /var/lib/rift-os/driver-status.json; }
trap 'status error "Driver preparation failed; see journalctl -u rift-driver-prepare"' ERR
status preparing 'Preparing graphics packages; internet may be required'
if lspci -nn | grep -Ei 'VGA|3D|Display' | grep -qi NVIDIA; then
  apt-get update
  ubuntu-drivers install
  flatpak update --system --noninteractive -y
fi
status ready 'Graphics packages prepared; reboot if requested'
touch /var/lib/rift-os/drivers-ready
