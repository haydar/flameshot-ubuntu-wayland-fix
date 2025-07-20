#!/bin/bash


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

# --- Remove Snap version if it exists ---
echo "[+] Checking for and removing Flameshot Snap version (if present)..."
if snap list | grep -q "flameshot"; then
    echo "    Flameshot Snap version found. Uninstalling..."
    sudo snap remove flameshot || { echo "❌ Failed to remove Flameshot Snap. Please remove it manually and try again." && exit 1; }
    echo "    Flameshot Snap removed successfully."
else
    echo "    Flameshot Snap version not found. Skipping removal."
fi

# --- Install APT version ---
echo "[+] Installing Flameshot via APT..."
# Check if Flameshot is already installed via APT and up to date
if ! apt list --installed flameshot 2>/dev/null | grep -q "flameshot" || ! dpkg -s flameshot | grep -q "Version: 12.1.0-2build2"; then
    sudo apt update
    sudo apt install -y flameshot
else
    echo "Flameshot is already the newest version (12.1.0-2build2) via APT. Skipping installation."
fi


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
    # Check if this specific custom binding path is already in use by any custom shortcut
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
    # Using '#' as a delimiter for sed to avoid issues with '/' in BINDING_PATH
    NEW_BINDINGS=$(echo "$CURRENT_BINDINGS" | sed "s#]$#, '$BINDING_PATH']#")
fi
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"

# Set the properties for the new custom keybinding
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" name "$SHORTCUT_NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" command "$SHORTCUT_CMD"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" binding "$SHORTCUT_KEY"

echo "[✓] Done! Flameshot is now bound to the Print key under Wayland."