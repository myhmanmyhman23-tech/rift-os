#!/usr/bin/env bash
# System preparation only. Run as root on Ubuntu/Kubuntu 24.04 x86_64.
set -Eeuo pipefail
export LC_ALL=C
if [[ "${1:-}" == "--plan" ]]; then
  printf '%s\n' 'Target: Ubuntu/Kubuntu 24.04, x86_64' '1. Enable universe/multiverse and i386 packages' '2. Install graphics, firmware, Flatpak, Node.js and diagnostics' '3. Install recommended NVIDIA driver when detected' '4. Keep the existing desktop; optional KDE install with --desktop' '5. Reboot if requested, then run setup.sh as your normal user'
  exit 0
fi
[[ $EUID -eq 0 ]] || { echo 'Run: sudo bash linux/bootstrap.sh [--desktop]'; exit 1; }
source /etc/os-release
[[ "${VERSION_ID:-}" == '24.04' && "${ID:-}" == 'ubuntu' ]] || { echo 'This bootstrap currently supports Ubuntu/Kubuntu 24.04 only.'; exit 1; }
[[ "$(dpkg --print-architecture)" == 'amd64' ]] || { echo 'The initial gaming profile targets x86_64 only.'; exit 1; }
[[ $# -eq 0 || ( $# -eq 1 && "$1" == '--desktop' ) ]] || { echo 'Unknown option'; exit 1; }
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y universe
add-apt-repository -y multiverse
dpkg --add-architecture i386
apt-get update
apt-get install -y nodejs flatpak pciutils vulkan-tools mesa-utils linux-firmware ubuntu-drivers-common mokutil xdg-utils ca-certificates libvulkan1 libvulkan1:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 gamemode
if lspci -nn | grep -Ei 'VGA|3D|Display' | grep -qi NVIDIA; then
  echo 'Installing the distribution-recommended NVIDIA driver.'
  ubuntu-drivers install
fi
if [[ "${1:-}" == '--desktop' ]]; then apt-get install -y kde-plasma-desktop; fi
echo 'System packages prepared. Run linux/setup.sh as your normal desktop user.'
if [[ -f /var/run/reboot-required ]]; then echo 'Reboot required. With Secure Boot, follow any driver key enrollment prompt.'; fi
