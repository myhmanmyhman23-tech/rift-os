#!/usr/bin/env bash
# Remaster the official Kubuntu live filesystem while replaying its boot setup.
set -Eeuo pipefail
export LC_ALL=C
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=build/base.env
source "$repo/build/base.env"
version="$(node -p "require(process.argv[1]).version" "$repo/package.json")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]] || exit 1
if [[ "${1:-}" == '--plan' ]]; then
  printf '%s\n' "RIFT OS $version / $BASE_NAME" 'Verify SHA-256, unpack the live root, install dependencies and Flatpak apps,' 'embed RIFT OS, repack SquashFS, replay BIOS/UEFI boot configuration,' 'run structural validation and QEMU kernel/live-root smoke test, then split release assets.'
  exit 0
fi
[[ $EUID -eq 0 ]] || { echo 'Run with sudo on an x86_64 Linux build machine.'; exit 1; }
[[ "$(uname -m)" == x86_64 ]] || { echo 'x86_64 build host required'; exit 1; }
[[ $# -eq 0 ]] || { echo 'Unknown option'; exit 1; }
for tool in xorriso unsquashfs mksquashfs curl chroot mount qemu-system-x86_64; do command -v "$tool" >/dev/null || { echo "Missing: $tool"; exit 1; }; done
work="$(mktemp -d /mnt/rift-build.XXXXXX)"
root="$work/root"; medium="$work/medium"; output="$repo/dist"
mkdir -p "$root" "$medium" "$output" "$repo/build/cache"
mounts=()
cleanup(){ for ((i=${#mounts[@]}-1;i>=0;i--)); do umount "${mounts[$i]}" || true; done; echo "Build work retained for inspection: $work"; }
trap cleanup EXIT
free_kb="$(df -Pk /mnt | awk 'NR==2 {print $4}')"
[[ "$free_kb" -gt 40000000 ]] || { echo 'At least 40 GB free on /mnt is required.'; exit 1; }
base="$repo/build/cache/$BASE_NAME"
if [[ ! -f "$base" ]]; then curl --fail --location --retry 5 --output "$base.part" "$BASE_URL"; mv "$base.part" "$base"; fi
printf '%s  %s\n' "$BASE_SHA256" "$base" | sha256sum --check -
mount -o loop,ro "$base" "$medium"; mounts+=("$medium")
[[ -f "$medium/casper/filesystem.squashfs" ]] || { echo 'Unsupported base: no single casper/filesystem.squashfs'; exit 1; }
count="$(find "$medium/casper" -maxdepth 1 -name '*.squashfs' | wc -l)"
[[ "$count" -eq 1 ]] || { echo 'Unsupported layered base: inspect before rebuilding'; exit 1; }
unsquashfs -d "$root" "$medium/casper/filesystem.squashfs"
for directory in dev dev/pts proc sys; do mount --bind "/$directory" "$root/$directory"; mounts+=("$root/$directory"); done
cp -a "$root/etc/resolv.conf" "$work/resolv.conf.original"
cp --remove-destination /etc/resolv.conf "$root/etc/resolv.conf"
if [[ -e "$root/usr/sbin/policy-rc.d" ]]; then cp -a "$root/usr/sbin/policy-rc.d" "$work/policy.original"; fi
printf '#!/bin/sh\nexit 101\n' > "$root/usr/sbin/policy-rc.d"; chmod +x "$root/usr/sbin/policy-rc.d"
cp "$repo/build/provision-root.sh" "$root/tmp/rift-provision.sh"
chroot "$root" bash /tmp/rift-provision.sh
mkdir -p "$root/usr/share/rift-os" "$root/usr/share/backgrounds/rift-os" "$root/etc/xdg/autostart" "$root/etc/skel/.config"
cp -R "$repo/public" "$repo/lib" "$root/usr/share/rift-os/"
cp "$repo/server.cjs" "$repo/package.json" "$root/usr/share/rift-os/"
cp "$repo/linux/rift-center.sh" "$root/usr/share/rift-os/start.sh"
cp "$repo/linux/first-boot.sh" "$root/usr/share/rift-os/first-boot.sh"
cp "$repo/build/smoke-guest.sh" "$root/usr/share/rift-os/smoke-guest.sh"
cp "$repo/build/wallpaper.svg" "$root/usr/share/backgrounds/rift-os/wallpaper.svg"
chmod +x "$root/usr/share/rift-os/"*.sh
cat > "$root/usr/local/bin/rift-center" <<'LAUNCH'
#!/bin/bash
export RIFT_APP_ROOT=/usr/share/rift-os
timeout 20 flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
if command -v plasma-apply-wallpaperimage >/dev/null && [[ ! -f "$HOME/.config/rift-theme-ready" ]]; then
  if plasma-apply-wallpaperimage /usr/share/backgrounds/rift-os/wallpaper.svg >/dev/null 2>&1; then
    mkdir -p "$HOME/.config"; touch "$HOME/.config/rift-theme-ready"
  fi
fi
exec bash /usr/share/rift-os/start.sh
LAUNCH
chmod +x "$root/usr/local/bin/rift-center"
cp "$repo/build/rift-center.desktop" "$root/usr/share/applications/rift-center.desktop"
cp "$repo/build/rift-center.desktop" "$root/etc/xdg/autostart/rift-center.desktop"
cp "$repo/build/rift-driver-prepare.service" "$repo/build/rift-smoke.service" "$root/etc/systemd/system/"
chroot "$root" systemctl enable rift-driver-prepare.service rift-smoke.service
printf '[General]\nColorScheme=BreezeDark\n[Icons]\nTheme=breeze-dark\n' > "$root/etc/skel/.config/kdeglobals"
printf 'RIFT OS %s\nBased on Kubuntu 24.04.5 LTS. Unofficial remix.\n' "$version" > "$root/etc/rift-os-release"
chroot "$root" node --check /usr/share/rift-os/server.cjs
chroot "$root" flatpak list --app --columns=application > "$work/flatpak-apps.txt"
for app in com.modrinth.ModrinthApp com.valvesoftware.Steam net.lutris.Lutris com.usebottles.bottles; do grep -Fx "$app" "$work/flatpak-apps.txt"; done
# These are dpkg-query substitutions, not shell variables.
# shellcheck disable=SC2016
chroot "$root" dpkg-query -W --showformat='${Package} ${Version}\n' > "$work/filesystem.manifest"
rm -f "$root/tmp/rift-provision.sh" "$root/usr/sbin/policy-rc.d"
if [[ -e "$work/policy.original" ]]; then cp -a "$work/policy.original" "$root/usr/sbin/policy-rc.d"; fi
cp --remove-destination -a "$work/resolv.conf.original" "$root/etc/resolv.conf"
for ((i=${#mounts[@]}-1;i>=1;i--)); do umount "${mounts[$i]}"; unset 'mounts[i]'; done
du -sx --block-size=1 "$root" | cut -f1 > "$work/filesystem.size"
mksquashfs "$root" "$work/filesystem.squashfs" -noappend -comp xz -b 1M -processors 2 -mem 1G
image="$output/rift-os-$version-amd64.iso"
python3 "$repo/build/update-md5.py" "$medium/md5sum.txt" "$work" "$work/md5sum.txt"
# Preserve the upstream volume ID: GRUB may use it to discover the live medium.
# The boot images, kernel and initramfs are deliberately kept unchanged.
xorriso -indev "$base" -outdev "$image" \
  -map "$work/filesystem.squashfs" /casper/filesystem.squashfs \
  -map "$work/filesystem.manifest" /casper/filesystem.manifest \
  -map "$work/filesystem.size" /casper/filesystem.size \
  -map "$work/md5sum.txt" /md5sum.txt \
  -boot_image any replay -commit
xorriso -indev "$image" -report_el_torito plain > "$output/boot-layout.txt" 2>&1
grep -q 'BIOS' "$output/boot-layout.txt"; grep -q 'UEFI' "$output/boot-layout.txt"
bash "$repo/build/smoke-iso.sh" "$image" "$medium/casper/vmlinuz" "$medium/casper/initrd"
cp "$work/flatpak-apps.txt" "$output/flatpak-apps.txt"
cp "$work/filesystem.manifest" "$output/package-manifest.txt"
printf '%s\n' "$BASE_NAME" "$BASE_SHA256" > "$output/base-image.txt"
bash "$repo/build/package-release.sh" "$image"
echo "Built and smoke-tested: $image"
