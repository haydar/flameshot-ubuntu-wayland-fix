# 🔥 A Seamless Installer for Flameshot on Ubuntu 24.04 Gnome Wayland


This script installs [Flameshot](https://flameshot.org) and sets a custom GNOME keyboard shortcut to launch it with the `Print` key — properly configured to work under **Wayland**, the default session in Ubuntu 24.04+.

---

## ❓ Why this repo?

Ubuntu 24.04 uses **Wayland** instead of X11.  
As a result, many users encounter **“Unable to capture screen”** errors when using Flameshot with default GNOME shortcuts.

This script solves the issue by:
- Setting `QT_QPA_PLATFORM=wayland`
- Automating GNOME shortcut creation for the Print key

References:
- [Flameshot Issue #3700](https://github.com/flameshot-org/flameshot/issues/3700)
- [Wayland support in Flameshot Docs](https://flameshot.org/docs/guide/wayland-help/)

---

## ⚙️ Quick Setup

Paste this into your terminal:

```bash
bash <(curl -s https://raw.githubusercontent.com/haydar/flameshot-shortcut/main/flameshot-install.sh)
