#!/bin/bash
set -e

echo "🧪 Checking system requirements..."
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "❌ This script is for Ubuntu only."; exit 1
fi

VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
if dpkg --compare-versions "$VERSION" lt 24.04; then
    echo "❌ Requires Ubuntu 24.04 or newer (Detected: $VERSION)."; exit 1
fi
echo "✅ Ubuntu $VERSION detected."

echo "🔍 Removing Flameshot Snap (if exists)..."
if snap list 2>/dev/null | grep -q "flameshot"; then
    sudo snap remove flameshot || {
        echo "❌ Could not remove Flameshot Snap. Remove manually."; exit 1;
    }
    echo "✅ Flameshot Snap removed."
fi

echo "📦 Installing Flameshot via APT..."
sudo apt update
sudo apt install -y flameshot

echo "🔧 Disabling GNOME default PrintScreen shortcuts..."
gsettings set org.gnome.shell.keybindings screenshot '[]'
gsettings set org.gnome.shell.keybindings show-screenshot-ui '[]'

echo "🎯 Setting custom Flameshot shortcut..."
CMD='sh -c -- "QT_QPA_PLATFORM=wayland flameshot gui"'
KEY="Print"
SHORTCUT_NAME="flameshot"
BASE_KEY="org.gnome.settings-daemon.plugins.media-keys"
CUSTOM_KEYS_PATH="$BASE_KEY.custom-keybinding"

# Read and clean existing shortcuts
EXISTING=$(gsettings get $BASE_KEY custom-keybindings)
CLEANED=$(echo "$EXISTING" | tr -d "[]'," | xargs)
IFS=' ' read -ra ENTRIES <<< "$CLEANED"

# Check if this command has been added before
for path in "${ENTRIES[@]}"; do
    current_cmd=$(gsettings get "$CUSTOM_KEYS_PATH:$path" command 2>/dev/null | tr -d \')
    if [[ "$current_cmd" == "$CMD" ]]; then
        echo "⚠️ Flameshot shortcut already exists at $path"
        exit 0
    fi
done

# Find a new empty slot
for i in {0..99}; do
    new_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
    if ! printf '%s\n' "${ENTRIES[@]}" | grep -qx "$new_path"; then
        ENTRIES+=("$new_path")
        break
    fi
done

# Write the list in the correct format
KEYBINDING_LIST="["
for path in "${ENTRIES[@]}"; do
    KEYBINDING_LIST+="'$path', "
done
KEYBINDING_LIST="${KEYBINDING_LIST%, }]"  # remove trailing comma
gsettings set $BASE_KEY custom-keybindings "$KEYBINDING_LIST"

#  Set shortcut details
gsettings set "$CUSTOM_KEYS_PATH:$new_path" name "$SHORTCUT_NAME"
gsettings set "$CUSTOM_KEYS_PATH:$new_path" command "$CMD"
gsettings set "$CUSTOM_KEYS_PATH:$new_path" binding "$KEY"

echo "✅ Flameshot bound to Print key under Wayland. Logout/login may be required."

