# 🔥 A Seamless Installer for Flameshot on Ubuntu 24.04+ (GNOME Wayland)

This script installs [Flameshot](https://flameshot.org) and configures a custom GNOME keyboard shortcut to launch it with the **Print key**. It's properly set up to work under **Wayland**, the default session in Ubuntu 24.04 and later.

---

## ❓ Why This Script?

Ubuntu 24.04 and newer versions use **Wayland** instead of X11 by default. Many users encounter **“Unable to capture screen”** errors when using Flameshot with default GNOME shortcuts in a Wayland environment.

This script directly addresses this issue by:
* Ensuring the **APT version of Flameshot is installed**, removing any conflicting Snap version if detected.
* Setting the necessary `QT_QPA_PLATFORM=wayland` environment variable for proper Wayland compatibility.
* **Automating the creation of a custom GNOME shortcut** for the **Print** key, which is configured to work correctly with Flameshot under Wayland.

**References:**
* [Flameshot Issue #3700](https://github.com/flameshot-org/flameshot/issues/3700)
* [Wayland support in Flameshot Docs](https://flameshot.org/docs/guide/wayland-help/)

---

## ⚙️ Quick Setup

To install Flameshot and configure the shortcut, simply paste this command into your terminal:

```bash
 bash <(curl -s https://raw.githubusercontent.com/haydar/flameshot-ubuntu-wayland-fix/refs/heads/main/flameshot-install.sh)