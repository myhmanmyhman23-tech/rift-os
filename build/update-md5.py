"""Update the upstream live-medium integrity list after remastering."""
import hashlib
import pathlib
import sys

source, work, output = map(pathlib.Path, sys.argv[1:])
replacements = {}
for name in ("filesystem.squashfs", "filesystem.manifest", "filesystem.size"):
    with (work / name).open("rb") as stream:
        digest = hashlib.file_digest(stream, "md5").hexdigest()
    replacements[f"casper/{name}"] = digest
lines = []
for line in source.read_text().splitlines():
    digest, filename = line.split(maxsplit=1)
    normalized = filename.lstrip("*").removeprefix("./")
    if normalized in replacements:
        digest = replacements[normalized]
    lines.append(f"{digest}  {filename}")
output.write_text("\n".join(lines) + "\n")
