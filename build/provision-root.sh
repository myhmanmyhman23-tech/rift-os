#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive LC_ALL=C
dpkg --add-architecture i386
apt-get update
apt-get install -y nodejs flatpak pciutils vulkan-tools mesa-utils ubuntu-drivers-common mokutil xdg-utils curl ca-certificates libvulkan1 libvulkan1:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 gamemode
flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system --noninteractive -y flathub com.modrinth.ModrinthApp com.valvesoftware.Steam net.lutris.Lutris com.usebottles.bottles
apt-get clean
