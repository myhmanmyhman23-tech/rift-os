#!/usr/bin/env bash
# Registers Flathub, installs RIFT OS locally, and creates a desktop launcher.
set -Eeuo pipefail
if [[ "${1:-}" == '--plan' ]]; then
  printf '%s\n' '1. Add the Flathub remote for the current user' '2. Copy the control center to ~/.local/share/rift-os' '3. Create a start script and desktop entry' '4. Optionally install gaming launchers with --launchers'
  exit 0
fi
[[ $EUID -ne 0 ]] || { echo 'Run as your normal desktop user, without sudo.'; exit 1; }
[[ $# -eq 0 || ( $# -eq 1 && "$1" == '--launchers' ) ]] || { echo 'Unknown option'; exit 1; }
if ! command -v node >/dev/null || ! command -v flatpak >/dev/null; then echo 'Run linux/bootstrap.sh first.'; exit 1; fi
source_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_root="$HOME/.local/share/rift-os"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
mkdir -p "$install_root" "$HOME/.local/bin" "$HOME/.local/share/applications"
if [[ "$source_root" != "$install_root" ]]; then
  cp "$source_root/server.cjs" "$source_root/package.json" "$install_root/"
  cp -R "$source_root/lib" "$source_root/public" "$install_root/"
fi
cp "$source_root/linux/rift-center.sh" "$HOME/.local/bin/rift-center"
chmod +x "$HOME/.local/bin/rift-center"
cat > "$HOME/.local/share/applications/rift-center.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=RIFT OS Control Center
Comment=Gaming library and hardware diagnostics
Exec=sh -c "exec \"$HOME/.local/bin/rift-center\""
Icon=applications-games
Terminal=false
Categories=Game;Settings;
DESKTOP
if [[ "${1:-}" == '--launchers' ]]; then
  flatpak install --user --noninteractive -y flathub com.modrinth.ModrinthApp com.valvesoftware.Steam net.lutris.Lutris com.usebottles.bottles
fi
echo 'Ready. Open RIFT OS Control Center in the application menu.'
