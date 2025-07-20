#!/bin/bash

# Author: Haydar ŞAHİN
# Description: Installs Flameshot and binds it to the Print key under Wayland on Ubuntu 24.04+.
# OS Support: Ubuntu 24.04+ (GNOME with Wayland)

set -e

# Check for Ubuntu and version
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "❌ This script is intended for Ubuntu only."
    exit 1
fi

VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
if dpkg --compare-versions "$VERSION" lt 24.04; then
    echo "❌ Requires Ubuntu 24.04 or newer."
    exit 1
fi

echo "[+] Installing Flameshot..."
sudo apt update
sudo apt install -y flameshot

SHORTCUT_NAME="flameshot"
SHORTCUT_CMD='sh -c -- "QT_QPA_PLATFORM=wayland flameshot gui"'
SHORTCUT_KEY="Print"
BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

echo "[+] Configuring GNOME custom shortcut..."
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

if [[ "$CURRENT_BINDINGS" != *"$BINDING_PATH"* ]]; then
    if [[ "$CURRENT_BINDINGS" == "@as []" ]]; then
        NEW_BINDINGS="['$BINDING_PATH']"
    else
        NEW_BINDINGS=$(echo "$CURRENT_BINDINGS" | sed "s/]$/, '$BINDING_PATH']/")
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"
fi

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH name "$SHORTCUT_NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH command "$SHORTCUT_CMD"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BINDING_PATH binding "$SHORTCUT_KEY"

echo "[✓] Done! Flameshot is now bound to the Print key under Wayland."
