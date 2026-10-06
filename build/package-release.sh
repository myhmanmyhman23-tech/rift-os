#!/usr/bin/env bash
set -Eeuo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
image="$(realpath "$1")"; output="$(dirname "$image")"
cd "$output"
name="$(basename "$image")"
split --bytes=1900M --numeric-suffixes=1 --suffix-length=3 "$name" "$name.part-"
cp "$repo/release/Reassemble.ps1" "$output/Reassemble.ps1"
cp "$repo/release/reassemble.sh" "$output/reassemble.sh"
sha256sum "$name" > SHA256SUMS
sha256sum "$name".part-* >> SHA256SUMS
printf 'Download every ISO part, SHA256SUMS and a reassembly script.\nWindows: powershell -ExecutionPolicy Bypass -File .\\Reassemble.ps1\nLinux: bash reassemble.sh\n' > DOWNLOAD.txt
