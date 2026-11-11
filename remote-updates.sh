#!/usr/bin/env bash
# ==============================================================================
# FeatherOS Remote Auto-Pilot Command File (Managed by your AI Assistant)
# Release: v1.1.0 — Windows 11 Fluent Dark UI Transformation, Colorful Icons & Desktop Shortcuts
# ==============================================================================

set -u

export DEBIAN_FRONTEND=noninteractive

# 1. Install colorful Windows/Fluent-style icons (Papirus), LookSwitcher, and Dolphin File Explorer
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y --no-install-recommends \
    papirus-icon-theme \
    breeze-icon-theme \
    dolphin \
    konsole \
    chromium \
    q4os-lookswitcher \
    lookswitcher >/dev/null 2>&1 || \
apt-get install -y --no-install-recommends \
    papirus-icon-theme \
    breeze-icon-theme \
    dolphin >/dev/null 2>&1 || true

# 2. Create a sleek Windows 11 Bloom-inspired HD Wallpaper
mkdir -p /usr/share/backgrounds
cat > /usr/share/backgrounds/featheros-win11.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080" width="1920" height="1080">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#050b1a"/>
      <stop offset="45%" stop-color="#0a1936"/>
      <stop offset="100%" stop-color="#030914"/>
    </linearGradient>
    <radialGradient id="glow1" cx="50%" cy="50%" r="55%">
      <stop offset="0%" stop-color="#0078d4" stop-opacity="0.75"/>
      <stop offset="50%" stop-color="#004e8c" stop-opacity="0.35"/>
      <stop offset="100%" stop-color="#050b1a" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="petal1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#60cdff" stop-opacity="0.92"/>
      <stop offset="50%" stop-color="#0078d4" stop-opacity="0.88"/>
      <stop offset="100%" stop-color="#002b5e" stop-opacity="0.95"/>
    </linearGradient>
    <linearGradient id="petal2" x1="100%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.85"/>
      <stop offset="60%" stop-color="#1d4ed8" stop-opacity="0.85"/>
      <stop offset="100%" stop-color="#0f172a" stop-opacity="0.9"/>
    </linearGradient>
    <linearGradient id="petal3" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0284c7" stop-opacity="0.8"/>
      <stop offset="50%" stop-color="#2563eb" stop-opacity="0.85"/>
      <stop offset="100%" stop-color="#7dd3fc" stop-opacity="0.9"/>
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <circle cx="960" cy="540" r="780" fill="url(#glow1)"/>
  <path d="M960,540 C650,180 380,350 480,650 C560,880 860,820 960,540 Z" fill="url(#petal2)"/>
  <path d="M960,540 C1270,180 1540,350 1440,650 C1360,880 1060,820 960,540 Z" fill="url(#petal1)"/>
  <path d="M960,540 C700,80 1220,80 960,540 Z" fill="url(#petal3)"/>
  <path d="M960,540 C520,420 550,940 960,860 C1370,940 1400,420 960,540 Z" fill="url(#petal1)" opacity="0.82"/>
  <circle cx="960" cy="520" r="180" fill="#60cdff" opacity="0.22"/>
</svg>
EOF

# 3. Apply Windows 11 / 10 Fluent Theme, Colorful Icons & Desktop Icons for user 'chouaibe'
TARGET_USER="chouaibe"
if ! id "${TARGET_USER}" >/dev/null 2>&1; then
    TARGET_USER="$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd)"
fi

if [ -n "${TARGET_USER}" ] && id "${TARGET_USER}" >/dev/null 2>&1; then
    USER_UID="$(id -u "${TARGET_USER}")"
    USER_HOME="$(eval echo "~${TARGET_USER}")"
    DESKTOP_DIR="${USER_HOME}/Desktop"
    mkdir -p "${DESKTOP_DIR}"

    # Create Windows-style Desktop Shortcuts (This PC, Documents, Control Panel, Recycle Bin)
    cat > "${DESKTOP_DIR}/This-PC.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=This PC (File Explorer)
Comment=Browse your hard drives, D: drive, and USB sticks
Exec=dolphin
Icon=computer
Terminal=false
Categories=System;FileManager;
EOF

    cat > "${DESKTOP_DIR}/My-Documents.desktop" << EOF
[Desktop Entry]
Type=Application
Name=My Documents
Comment=Open your personal Documents folder
Exec=dolphin "${USER_HOME}/Documents"
Icon=folder-documents
Terminal=false
EOF

    cat > "${DESKTOP_DIR}/Windows-Theme-Settings.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Customize Theme & Look
Comment=Switch themes, colors, icons, and taskbar style
Exec=systemsettings
Icon=preferences-desktop-theme
Terminal=false
EOF

    cat > "${DESKTOP_DIR}/Recycle-Bin.desktop" << 'EOF'
[Desktop Entry]
Type=Link
Name=Recycle Bin
Icon=user-trash-full
URL=trash:/
EOF

    chmod +x "${DESKTOP_DIR}"/*.desktop 2>/dev/null || true
    chown -R "${TARGET_USER}:${TARGET_USER}" "${DESKTOP_DIR}"

    # Configure KDE Plasma Globals for Colorful Papirus Icons & Modern Breeze Dark/Twilight Windows Style
    sudo -u "${TARGET_USER}" bash -c '
        export DISPLAY=:0
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/'"${USER_UID}"'/bus"

        # Apply Breeze Dark (sleek Windows 10/11 dark glass style)
        if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
            plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
            plasma-apply-lookandfeel -a org.kde.breezetwilight.desktop 2>/dev/null || true
        fi

        # Apply Colorful Papirus Icon Theme (replaces boring gray icons)
        for kw in kwriteconfig6 kwriteconfig5; do
            if command -v "$kw" >/dev/null 2>&1; then
                "$kw" --file ~/.config/kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null || true
                "$kw" --file ~/.config/kdeglobals --group KDE --key SingleClick false 2>/dev/null || true
            fi
        done

        # Apply the new Windows 11 Bloom Wallpaper live
        if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
            plasma-apply-wallpaperimage /usr/share/backgrounds/featheros-win11.svg 2>/dev/null || true
        fi
    ' || true
fi

# Preserve working grub.cfg backup
if [ -f /boot/grub/grub.cfg.working.bak ]; then
    cp -f /boot/grub/grub.cfg.working.bak /boot/grub/grub.cfg 2>/dev/null || true
fi

exit 0
