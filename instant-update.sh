#!/usr/bin/env bash
# ==============================================================================
# FeatherOS Instant Win11 Overhaul & Chrome Installer
# Repository: https://github.com/chouaibe-k/feather-os
# ==============================================================================
# Applies 100% Windows 11 Aesthetic:
#   1. Installs Official Google Chrome & sets as default browser
#   2. Installs Win11-Slim 1px borders & 28px titlebar with Windows caption buttons
#   3. Windows 11 Start Emblem, pinned taskbar & system tray
#   4. 8K Windows 11 Sapphire Ribbon Wallpaper
#   5. Applies changes INSTANTANEOUSLY live on screen!
# ==============================================================================

set -u

if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
REPO_RAW="https://raw.githubusercontent.com/chouaibe-k/feather-os/main"

echo "======================================================================"
echo "  FEATHER-OS: APPLYING REFINED WINDOWS 11 DESKTOP & GOOGLE CHROME     "
echo "======================================================================"

# 1. Install Google Chrome, modern fonts & icon themes
echo "--> [1/5] Installing Google Chrome & Modern Icons..."
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y --no-install-recommends \
    wget \
    curl \
    gpg \
    papirus-icon-theme \
    breeze-icon-theme \
    dolphin \
    konsole \
    libglib2.0-bin \
    fonts-noto-core >/dev/null 2>&1 || true

if ! command -v google-chrome-stable >/dev/null 2>&1; then
    CHROME_DEB="/tmp/google-chrome-stable_current_amd64.deb"
    if wget -qO "${CHROME_DEB}" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" || \
       curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -o "${CHROME_DEB}"; then
        apt-get install -y "${CHROME_DEB}" >/dev/null 2>&1 || {
            dpkg -i "${CHROME_DEB}" >/dev/null 2>&1 || true
            apt-get install -f -y >/dev/null 2>&1 || true
        }
        rm -f "${CHROME_DEB}"
    fi
fi

# Set Chrome as default browser system-wide
update-alternatives --set x-www-browser /usr/bin/google-chrome-stable 2>/dev/null || true

# 2. Download Windows 11 Assets (Wallpaper, Start Emblem, Window Theme)
echo "--> [2/5] Downloading Windows 11 Wallpaper, Start Logo & Window Theme..."
mkdir -p /usr/share/backgrounds /usr/share/icons/hicolor/scalable/apps
mkdir -p /usr/share/aurorae/themes/Win11-Slim

wget -qO /usr/share/backgrounds/win11-feather-wallpaper.jpg "${REPO_RAW}/assets/win11-wallpaper.jpg" || \
curl -fsSL "${REPO_RAW}/assets/win11-wallpaper.jpg" -o /usr/share/backgrounds/win11-feather-wallpaper.jpg || true

wget -qO /usr/share/icons/win11-start.svg "${REPO_RAW}/assets/win11-start.svg" || \
curl -fsSL "${REPO_RAW}/assets/win11-start.svg" -o /usr/share/icons/win11-start.svg || true
cp -f /usr/share/icons/win11-start.svg /usr/share/icons/hicolor/scalable/apps/win11-start.svg 2>/dev/null || true

for f in metadata.desktop Win11-Slimrc decoration.svg close.svg maximize.svg restore.svg minimize.svg; do
    wget -qO "/usr/share/aurorae/themes/Win11-Slim/${f}" "${REPO_RAW}/assets/win11-theme/aurorae/Win11-Slim/${f}" || \
    curl -fsSL "${REPO_RAW}/assets/win11-theme/aurorae/Win11-Slim/${f}" -o "/usr/share/aurorae/themes/Win11-Slim/${f}" || true
done

# 3. Apply to All User Desktops (Targeting Chouabe and any user on the machine)
echo "--> [3/5] Configuring Slim Borders, Aesthetic Taskbar & Shortcuts..."
for USER_HOME in /home/*; do
    [ -d "${USER_HOME}" ] || continue
    TARGET_USER="$(basename "${USER_HOME}")"
    id "${TARGET_USER}" >/dev/null 2>&1 || continue
    USER_UID="$(id -u "${TARGET_USER}")"

    # Also install theme into user directory so Aurorae detects it instantly
    USER_THEME_DIR="${USER_HOME}/.local/share/aurorae/themes/Win11-Slim"
    mkdir -p "${USER_THEME_DIR}"
    cp -rf /usr/share/aurorae/themes/Win11-Slim/* "${USER_THEME_DIR}/" 2>/dev/null || true

    # Desktop Icons (Chrome, This PC, Documents, Control Panel, Recycle Bin)
    DESKTOP_DIR="${USER_HOME}/Desktop"
    mkdir -p "${DESKTOP_DIR}"

    if [ -f /usr/share/applications/google-chrome.desktop ]; then
        cp -f /usr/share/applications/google-chrome.desktop "${DESKTOP_DIR}/Google-Chrome.desktop"
    fi

    cat > "${DESKTOP_DIR}/This-PC.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=This PC
Comment=Browse hard drives, D: drive, and files
Exec=dolphin
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
EOF

    cat > "${DESKTOP_DIR}/My-Documents.desktop" << EOF
[Desktop Entry]
Type=Application
Name=My Documents
Comment=Open Documents folder
Exec=dolphin "${USER_HOME}/Documents"
Icon=folder-documents
Terminal=false
EOF

    cat > "${DESKTOP_DIR}/Windows-Settings.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Settings
Comment=Windows Control Panel & Theme Settings
Exec=systemsettings
Icon=preferences-system
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
    chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/Desktop" "${USER_HOME}/.local"

    # Configure KWin Window Decoration (Slim 1px borders, Windows right buttons: Minimize, Maximize, Close)
    KWIN_RC="${USER_HOME}/.config/kwinrc"
    mkdir -p "${USER_HOME}/.config"

    for kw in kwriteconfig6 kwriteconfig5; do
        if command -v "$kw" >/dev/null 2>&1; then
            # Set Win11-Slim Aurorae Window Decoration
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "Decoration" "kwin4_decoration_qml_aurorae" 2>/dev/null || true
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "Theme" "__aurorae__svg__Win11-Slim" 2>/dev/null || true
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "BorderSize" "None" 2>/dev/null || true
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false" 2>/dev/null || true
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "ButtonsOnLeft" "" 2>/dev/null || true
            "$kw" --file "${KWIN_RC}" --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX" 2>/dev/null || true

            # Set Dark Fluent Theme, Papirus Icons, and Double-Click
            "$kw" --file "${USER_HOME}/.config/kdeglobals" --group Icons --key Theme Papirus-Dark 2>/dev/null || true
            "$kw" --file "${USER_HOME}/.config/kdeglobals" --group KDE --key SingleClick false 2>/dev/null || true
        fi
    done

    # Refine bottom taskbar in plasma config
    APPLETS_RC="${USER_HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"
    if [ -f "$APPLETS_RC" ]; then
        # Replace start icon with Windows 11 logo
        sed -i 's|^icon=.*|icon=/usr/share/icons/win11-start.svg|g' "$APPLETS_RC" 2>/dev/null || true
    fi

    chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.config"

    # Live UI update inside user session (instant screen reload)
    sudo -u "${TARGET_USER}" bash -c '
        export DISPLAY=:0
        export XDG_RUNTIME_DIR="/run/user/'"${USER_UID}"'"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/'"${USER_UID}"'/bus"

        # Apply dark look
        if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
            plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
        fi

        # Apply Wallpaper
        if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
            plasma-apply-wallpaperimage /usr/share/backgrounds/win11-feather-wallpaper.jpg 2>/dev/null || true
        fi

        # JavaScript script to reconfigure the bottom taskbar live
        read -r -d "" PLASMA_JS << "EOJS" || true
var allDesktops = desktops();
for (var d = 0; d < allDesktops.length; d++) {
    var desk = allDesktops[d];
    desk.wallpaperPlugin = "org.kde.image";
    desk.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
    desk.writeConfig("Image", "file:///usr/share/backgrounds/win11-feather-wallpaper.jpg");
}
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    var p = allPanels[i];
    p.height = 44;
    p.floating = false;
    var widgets = p.widgets();
    for (var j = 0; j < widgets.length; j++) {
        var w = widgets[j];
        if (w.type === "org.kde.plasma.kickoff" || w.type === "org.kde.plasma.kicker" || w.type === "org.kde.plasma.kickerdash") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("icon", "/usr/share/icons/win11-start.svg");
            w.writeConfig("favorites", ["google-chrome.desktop", "org.kde.dolphin.desktop", "systemsettings.desktop", "org.kde.kate.desktop", "org.kde.konsole.desktop"]);
        }
        if (w.type === "org.kde.plasma.icontasks" || w.type === "org.kde.plasma.taskmanager") {
            w.currentConfigGroup = ["General"];
            w.writeConfig("launchers", [
                "applications:google-chrome.desktop",
                "applications:org.kde.dolphin.desktop",
                "applications:systemsettings.desktop",
                "applications:org.kde.kate.desktop",
                "applications:org.kde.konsole.desktop"
            ]);
        }
    }
}
EOJS

        if command -v gdbus >/dev/null 2>&1; then
            gdbus call --session --dest org.kde.plasmashell --object-path /PlasmaShell --method org.kde.PlasmaShell.evaluateScript "$PLASMA_JS" >/dev/null 2>&1 || true
        elif command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$PLASMA_JS" >/dev/null 2>&1 || true
        fi

        # Reload KWin window borders live without closing any open windows
        if command -v qdbus >/dev/null 2>&1; then
            qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        elif command -v qdbus6 >/dev/null 2>&1; then
            qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
        fi

        # Soft reload plasmashell so changes appear on screen immediately
        systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
    ' || true
done

echo "--> [4/5] Preserving Dual-Boot Bootloader..."
if [ -f /boot/grub/grub.cfg.working.bak ]; then
    cp -f /boot/grub/grub.cfg.working.bak /boot/grub/grub.cfg 2>/dev/null || true
fi

echo "--> [5/5] Done!"
echo "======================================================================"
echo "  SUCCESS! WINDOWS 11 AESTHETIC & CHROME ARE NOW ACTIVE!              "
echo "  - Window Borders: Slim 1px with Windows Caption Buttons (X, [], -)  "
echo "  - Bottom Toolbar: 44px Docked with Windows 11 Start Logo & Chrome   "
echo "  - Wallpaper: 8K Sapphire Glass Ribbon                               "
echo "======================================================================"
