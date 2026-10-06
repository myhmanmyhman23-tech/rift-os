#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
shopt -s nullglob
first=(rift-os-*-amd64.iso.part-001)
[[ ${#first[@]} -eq 1 ]] || { echo 'Keep exactly one release in this folder'; exit 1; }
image="${first[0]%.part-001}"
[[ ! -e "$image" && ! -e "$image.partial" ]] || { echo 'Output already exists'; exit 1; }
parts=("$image".part-*)
for ((i=0;i<${#parts[@]};i++)); do
  expected="$(printf '%s.part-%03d' "$image" "$((i+1))")"
  [[ "${parts[$i]}" == "$expected" ]] || { echo 'Missing or unexpected part'; exit 1; }
done
grep -F " $image.part-" SHA256SUMS > .rift-parts-checksums
sha256sum --check .rift-parts-checksums
cat "${parts[@]}" > "$image.partial"
expected_sum="$(awk -v n="$image" '$2==n {print $1}' SHA256SUMS)"
[[ "$expected_sum" =~ ^[0-9a-f]{64}$ ]]
printf '%s  %s\n' "$expected_sum" "$image.partial" | sha256sum --check -
mv "$image.partial" "$image"
echo "Verified ISO ready: $image"
