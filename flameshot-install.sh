#!/bin/bash


set -e # Exit immediately if a command exits with a non-zero status

# --- System Compatibility Checks ---
echo "--- System Compatibility Checks ---"
# Check for Ubuntu distribution
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "❌ This script is intended for Ubuntu only. Exiting."
    exit 1
fi

# Check for Ubuntu version 24.04 or newer
VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2)
if dpkg --compare-versions "$VERSION" lt 24.04; then
    echo "❌ Requires Ubuntu 24.04 or newer. Current version: $VERSION. Exiting."
    exit 1
fi
echo "✅ Ubuntu 24.04+ detected. Proceeding."

# --- Remove Flameshot Snap Version (if present) ---
echo "--- Checking for and removing Flameshot Snap version ---"
if snap list | grep -q "flameshot"; then
    echo "    Flameshot Snap version found. Attempting to uninstall..."
    if sudo snap remove flameshot; then
        echo "    Flameshot Snap removed successfully."
    else
        echo "❌ Failed to remove Flameshot Snap. Please remove it manually using 'sudo snap remove flameshot' and try again. Exiting."
        exit 1
    fi
else
    echo "    Flameshot Snap version not found. Skipping removal."
fi

# --- Install APT version ---
echo "--- Installing Flameshot via APT ---"
# Check if Flameshot is already installed via APT and up to date
# This check might need adjustment for future Ubuntu releases if the version changes.
if ! apt list --installed flameshot 2>/dev/null | grep -q "flameshot" || ! dpkg -s flameshot | grep -q "Version: 12.1.0-2build2"; then
    echo "    Flameshot APT version not found or not the newest. Updating apt and installing..."
    sudo apt update
    sudo apt install -y flameshot
    echo "    Flameshot APT installed/updated successfully."
else
    echo "    Flameshot is already installed. Skipping installation."
fi


SHORTCUT_NAME="flameshot"
SHORTCUT_CMD='sh -c -- "QT_QPA_PLATFORM=wayland flameshot gui"'
SHORTCUT_KEY="Print"

echo "--- Configuring GNOME custom shortcut ---"

# Find the next available custom binding slot to avoid overwriting existing shortcuts.
BINDING_PATH=""
for i in $(seq 0 99); do # Check up to custom99 slots
    TEMP_BINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
    # Check if this specific custom binding path is already in use by any custom shortcut
    if ! gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null | grep -q "$TEMP_BINDING_PATH"; then
        BINDING_PATH="$TEMP_BINDING_PATH"
        break
    fi
done

if [ -z "$BINDING_PATH" ]; then
    echo "❌ Could not find an available slot for a new custom shortcut. Please check your existing shortcuts. Exiting."
    exit 1
fi
echo "    Using custom binding path: $BINDING_PATH"

CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$CURRENT_BINDINGS" == "@as []" ]]; then
    # If no custom bindings exist, start a new array
    NEW_BINDINGS="['$BINDING_PATH']"
else
    # Remove the trailing ']' and append the new path, then add ']' back
    # This is a robust way to append to the GSettings array-like string
    NEW_BINDINGS="${CURRENT_BINDINGS::-1}, '$BINDING_PATH']"
fi
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"
echo "    Added '$BINDING_PATH' to custom keybindings list."

# Set the properties for the the new custom keybinding
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" name "$SHORTCUT_NAME"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" command "$SHORTCUT_CMD"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" binding "$SHORTCUT_KEY"
echo "    Set name, command, and binding for '$BINDING_PATH'."

echo "[✓] Done! Flameshot is now bound to the Print key under Wayland."
echo "    You might need to log out and log back in for the changes to take full effect."