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

echo "[+] Configuring GNOME custom shortcut..."

# Check for existing custom keybindings and add a new one if necessary.
# This part is crucial for not overwriting existing custom keybindings.
# We find the next available custom binding slot.
BINDING_PATH=""
for i in $(seq 0 99); do # Check up to custom99
    TEMP_BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
    if ! gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | grep -q "$TEMP_BINDING_PATH"; then
        BINDING_PATH="$TEMP_BINDING_PATH"
        break
    fi
done

if [ -z "$BINDING_PATH" ]; then
    echo "❌ Could not find an available slot for a new custom shortcut. Please check your existing shortcuts."
    exit 1
fi

CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$CURRENT_BINDINGS" == "@as []" ]]; then
    NEW_BINDINGS="['$BINDING_PATH']"
else
    # Remove the trailing ']' and append the new path, then add ']' back
    NEW_BINDINGS="${CURRENT_BINDINGS::-1}, '$BINDING_PATH']"
fi
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"

# Set the properties for the new custom keybinding
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" name "$SHORTCUT_NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" command "$SHORTCUT_CMD"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" binding "$SHORTCUT_KEY"

echo "[✓] Done! Flameshot is now bound to the Print key under Wayland."