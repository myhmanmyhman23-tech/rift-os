# RIFT OS 0.2.0-alpha.1

An experimental gaming Linux remix based on Kubuntu 24.04.5 LTS (x86_64).

## Included

- KDE Plasma and the upstream Kubuntu live environment and installer.
- RIFT OS Gaming Center with game profiles, hardware diagnostics and launcher management.
- Preinstalled Modrinth App, Steam, Lutris and Bottles through Flatpak.
- Minecraft profile using Modrinth with a licensed Microsoft account.
- Overwatch profile for Battle.net, and Genshin profile for HoYoPlay.
- First installed boot prepares a recommended NVIDIA driver when required; internet and a reboot may be necessary.
- Versioned build information, package manifests and SHA-256 checksums.

## Download

Download all `.iso.part-*` files, `SHA256SUMS`, and the reassembly script for your operating system into one folder.

Windows: run `powershell -ExecutionPolicy Bypass -File .\Reassemble.ps1`.

Linux: run `bash reassemble.sh`.

The script verifies each part and the final ISO before naming the completed image. Parts are used because GitHub release assets must be smaller than 2 GiB.

## Validation and limits

Publication requires source tests, BIOS/UEFI boot-structure checks and a QEMU direct-kernel live-root test that checks the gaming center and preinstalled launchers. This does **not** verify the graphical desktop, bootloader execution, installation to disk, GPU drivers on physical hardware, or actual games. Those require separate manual tests.

Overwatch/Battle.net and Genshin/HoYoPlay compatibility is experimental. Installing Lutris does not install those games or guarantee compatibility. No anti-cheat bypass is included.

This is an unofficial remix, not an official Canonical or Kubuntu release. Modrinth's Flatpak package is community-maintained. Existing upstream license and copyright files remain in the image.
