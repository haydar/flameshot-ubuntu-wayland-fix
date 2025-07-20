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
# Check if Flameshot is already installed via APT
if dpkg -s flameshot &>/dev/null; then
    echo "    Flameshot is already installed via APT. Ensuring it's the latest version..."
    sudo apt update
    sudo apt install -y flameshot
    echo "    Flameshot APT confirmed to be up to date."
else
    echo "    Flameshot is not installed via APT. Installing now..."
    sudo apt update
    sudo apt install -y flameshot
    echo "    Flameshot APT installed successfully."
fi

# --- Disable GNOME's default Print Screen shortcut ---
echo "--- Disabling GNOME's default Print Screen shortcut ---"
# This command unbinds the 'Print' key from GNOME's default screenshot tool.
# 'org.gnome.shell.keybindings' is where default GNOME Shell keybindings are set.
# 'screenshot' is the keybinding for the full screen screenshot.
gsettings set org.gnome.shell.keybindings screenshot "[]"
echo "    GNOME's default Print Screen keybinding disabled."

# --- Configuring GNOME custom shortcut ---
echo "--- Configuring GNOME custom shortcut ---"

SHORTCUT_NAME="flameshot"
SHORTCUT_CMD='sh -c -- "QT_QPA_PLATFORM=wayland flameshot gui"'
SHORTCUT_KEY="Print"

# 1. Check if Flameshot shortcut already exists
echo "    Checking if Flameshot shortcut already exists in custom keybindings..."
FLAMESHOT_SHORTCUT_EXISTS=false
CURRENT_BINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null)

if [[ "$CURRENT_BINDINGS" != "@as []" ]]; then
    # Parse the array-like string to get individual paths (e.g., 'custom0', 'custom1')
    # Remove '[' and ']' and single quotes, then split by commas
    IFS=',' read -ra BINDING_FRAGMENTS <<< "${CURRENT_BINDINGS//[\[\]\'[:space:]]/}"

    for fragment in "${BINDING_FRAGMENTS[@]}"; do
        # Reconstruct full path for gsettings query
        # Remove any empty strings from fragments due to multiple delimiters
        if [ -n "$fragment" ]; then
            FULL_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${fragment}/"
            # Check if the command for this custom binding matches Flameshot's command
            if gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$FULL_PATH" command 2>/dev/null | grep -q "$SHORTCUT_CMD"; then
                echo "    Flameshot shortcut already found at: $FULL_PATH. Skipping creation."
                FLAMESHOT_SHORTCUT_EXISTS=true
                break
            fi
        fi
    done
fi

if [ "$FLAMESHOT_SHORTCUT_EXISTS" = false ]; then
    # 2. If not, find the next available custom binding slot
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

    # 3. Add the new custom binding path to the list
    if [[ "$CURRENT_BINDINGS" == "@as []" ]]; then
        NEW_BINDINGS="['$BINDING_PATH']"
    else
        # Remove the trailing ']' and append the new path, then add ']' back
        NEW_BINDINGS="${CURRENT_BINDINGS::-1}, '$BINDING_PATH']"
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_BINDINGS"
    echo "    Added '$BINDING_PATH' to custom keybindings list."

    # 4. Set the properties for the new custom keybinding
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" name "$SHORTCUT_NAME"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" command "$SHORTCUT_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" binding "$SHORTCUT_KEY"
    echo "    Set name, command, and binding for '$BINDING_PATH'."
else
    echo "    Flameshot shortcut already configured. Skipping shortcut creation."
fi

echo "[✓] Done! Flameshot is now bound to the Print key under Wayland."
echo "    You might need to log out and log back in for the changes to take full effect."