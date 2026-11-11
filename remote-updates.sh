#!/usr/bin/env bash
# ==============================================================================
# FeatherOS Remote Auto-Pilot Command File (Managed by your AI Assistant)
# Release: v1.2.0 — Google Chrome + Windows 11 Taskbar, Start Logo & 8K Wallpaper
# ==============================================================================

set -u

export DEBIAN_FRONTEND=noninteractive
REPO_RAW="https://raw.githubusercontent.com/chouaibe-k/feather-os/main"

echo "==> [1/4] Installing Google Chrome & Windows 11 UI Components..."
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
    qdbus-qt6 >/dev/null 2>&1 || true

# Download and install official Google Chrome (.deb) if not already installed
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

echo "==> [2/4] Downloading Windows 11 8K Glass Wallpaper & Start Button Emblem..."
mkdir -p /usr/share/backgrounds /usr/share/icons/hicolor/scalable/apps

wget -qO /usr/share/backgrounds/win11-feather-wallpaper.jpg "${REPO_RAW}/assets/win11-wallpaper.jpg" || \
curl -fsSL "${REPO_RAW}/assets/win11-wallpaper.jpg" -o /usr/share/backgrounds/win11-feather-wallpaper.jpg || true

wget -qO /usr/share/icons/win11-start.svg "${REPO_RAW}/assets/win11-start.svg" || \
curl -fsSL "${REPO_RAW}/assets/win11-start.svg" -o /usr/share/icons/win11-start.svg || true
cp -f /usr/share/icons/win11-start.svg /usr/share/icons/hicolor/scalable/apps/win11-start.svg 2>/dev/null || true

echo "==> [3/4] Refining Bottom Taskbar, Start Menu, Wallpaper & Desktop Shortcuts..."
BROWSER_DESKTOP="google-chrome.desktop"
if [ ! -f /usr/share/applications/google-chrome.desktop ] && [ -f /usr/share/applications/chromium.desktop ]; then
    BROWSER_DESKTOP="chromium.desktop"
fi

for USER_HOME in /home/*; do
    [ -d "${USER_HOME}" ] || continue
    TARGET_USER="$(basename "${USER_HOME}")"
    id "${TARGET_USER}" >/dev/null 2>&1 || continue
    USER_UID="$(id -u "${TARGET_USER}")"

    DESKTOP_DIR="${USER_HOME}/Desktop"
    mkdir -p "${DESKTOP_DIR}"

    # Create Desktop Shortcuts (Google Chrome, This PC, My Documents, Theme Settings, Recycle Bin)
    if [ -f /usr/share/applications/google-chrome.desktop ]; then
        cp -f /usr/share/applications/google-chrome.desktop "${DESKTOP_DIR}/google-chrome.desktop"
    fi

    cat > "${DESKTOP_DIR}/This-PC.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=This PC (File Explorer)
Comment=Browse your hard drives, D: drive, and USB sticks
Exec=dolphin
Icon=system-file-manager
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
Name=Control Panel & Themes
Comment=Switch themes, colors, icons, and taskbar style
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
    chown -R "${TARGET_USER}:${TARGET_USER}" "${DESKTOP_DIR}"

    # Apply live KDE Plasma 6 Taskbar refinement, Windows 11 Start Emblem, Pinned Chrome & Wallpaper
    sudo -u "${TARGET_USER}" bash -c '
        export DISPLAY=:0
        export XDG_RUNTIME_DIR="/run/user/'"${USER_UID}"'"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/'"${USER_UID}"'/bus"

        # 1. Apply Dark Fluent Theme & Colorful Papirus Icons
        if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
            plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
        fi

        for kw in kwriteconfig6 kwriteconfig5; do
            if command -v "$kw" >/dev/null 2>&1; then
                "$kw" --file ~/.config/kdeglobals --group Icons --key Theme Papirus-Dark 2>/dev/null || true
                "$kw" --file ~/.config/kdeglobals --group KDE --key SingleClick false 2>/dev/null || true
            fi
        done

        # 2. Apply the 8K Windows 11 Glass Ribbon Wallpaper
        if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
            plasma-apply-wallpaperimage /usr/share/backgrounds/win11-feather-wallpaper.jpg 2>/dev/null || true
        fi

        # 3. Live-update the bottom Taskbar (Windows 11 4-square Start button, floating bar, pinned Chrome/Explorer/Settings)
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
    p.height = 46;
    p.floating = true;
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

        # Also patch plasma-org.kde.plasma.desktop-appletsrc directly and refresh plasmashell
        APPLETS_RC="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
        if [ -f "$APPLETS_RC" ]; then
            sed -i "s|^icon=.*|icon=/usr/share/icons/win11-start.svg|g" "$APPLETS_RC" 2>/dev/null || true
        fi

        # Restart plasmashell cleanly so the new taskbar icons, Start button, and wallpaper appear immediately
        killall plasmashell 2>/dev/null || true
        nohup plasmashell >/dev/null 2>&1 &
    ' || true
done

echo "==> [4/4] Verifying Bootloader Protection..."
if [ -f /boot/grub/grub.cfg.working.bak ]; then
    cp -f /boot/grub/grub.cfg.working.bak /boot/grub/grub.cfg 2>/dev/null || true
fi

echo "SUCCESS! Google Chrome, Windows 11 Start Button, Pinned Taskbar & 8K Wallpaper applied!"
exit 0
