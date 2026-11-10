#!/bin/sh
# ==============================================================================
# FeatherLinux Turnkey Installer & Provisioner (Alpine Linux Base)
# ==============================================================================
# Transforms a minimal Alpine Linux installation (~35MB RAM console) into a full
# daily-driver graphical laptop OS using ~95MB idle RAM.
#
# Supports: x86_64 (64-bit) & x86 (32-bit i686), BIOS & UEFI laptops.
# ==============================================================================

set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Please run this script as root (e.g., 'doas sh install-feather-desktop.sh' or 'su -c ...')"
    exit 1
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TARGET_USER="${FEATHER_USER:-$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1; exit}' /etc/passwd)}"

if [ -z "${TARGET_USER}" ]; then
    echo "==> Creating default desktop user 'laptop'..."
    adduser -D -G wheel laptop
    echo "laptop:feather" | chpasswd
    TARGET_USER="laptop"
fi

echo "==> [1/8] Enabling Alpine Community Repositories..."
sed -i 's/^#\(.*\/community\)/\1/' /etc/apk/repositories
apk update

echo "==> [2/8] Installing Hardware Firmware, Microcode & Display Server..."
# Broad compatibility for older Intel, AMD, Radeon, Nouveau (Nvidia), and Wi-Fi chips
apk add \
    linux-firmware-other \
    linux-firmware-i915 \
    linux-firmware-intel \
    linux-firmware-ath9k_htc \
    linux-firmware-brcm \
    linux-firmware-rtlwifi \
    mesa-dri-gallium \
    mesa-va-gallium \
    xorg-server \
    xf86-video-vesa \
    xf86-video-fbdev \
    xf86-input-libinput \
    xinit \
    xset \
    xinput \
    setxkbmap \
    udev \
    dbus \
    polkit-elogind \
    elogind

# Setup udev & Xorg services
setup-devd udev
rc-update add dbus default
rc-update add elogind default

echo "==> [3/8] Installing Ultra-Light Desktop (Openbox + Tint2 + PCManFM)..."
apk add \
    openbox \
    tint2 \
    pcmanfm \
    lxterminal \
    rofi \
    feh \
    gvfs \
    gvfs-mtp \
    udisks2 \
    adwaita-icon-theme \
    font-dejavu \
    font-noto \
    font-noto-emoji \
    lightdm \
    lightdm-gtk-greeter

rc-update add lightdm default

echo "==> [4/8] Configuring Wi-Fi (NetworkManager) & Audio (PipeWire)..."
apk add \
    networkmanager \
    networkmanager-wifi \
    network-manager-applet \
    wpa_supplicant \
    pipewire \
    pipewire-pulse \
    wireplumber \
    alsa-utils \
    pavucontrol

rc-update add networkmanager default

echo "==> [5/8] Installing Daily-Driver Apps (Web, Docs, Spreadsheets, PDF, Media)..."
apk add \
    chromium \
    abiword \
    gnumeric \
    evince \
    mousepad \
    mpv \
    viewnior \
    htop \
    curl \
    wget \
    unzip \
    doas

echo "==> [6/8] Configuring ZRAM Compressed Swap, EarlyOOM & Laptop Power Saving (TLP)..."
apk add \
    zram-init \
    earlyoom \
    tlp

# Configure zram-init to allocate 100% of physical RAM size as zstd compressed swap
cat > /etc/conf.d/zram-init << 'EOF'
load_on_start="yes"
unload_on_stop="yes"
num_devices="1"
type0="swap"
flag0="zram_swap"
# Allocate compressed swap equal to 75% of RAM using fast zstd compression
size0="$(awk '/MemTotal/ {print int($2 * 0.75 / 1024)}' /proc/meminfo)"
algo0="zstd"
EOF

rc-update add zram-init boot
rc-update add earlyoom default
rc-update add tlp default

# Install low-RAM sysctl tuning
if [ -f "${SCRIPT_DIR}/configs/sysctl-lowram.conf" ]; then
    cp "${SCRIPT_DIR}/configs/sysctl-lowram.conf" /etc/sysctl.d/99-feather-lowram.conf
fi

# Install Chromium low-RAM flags
if [ -f "${SCRIPT_DIR}/configs/chromium-lowram-flags.conf" ]; then
    mkdir -p /etc/chromium
    cp "${SCRIPT_DIR}/configs/chromium-lowram-flags.conf" /etc/chromium/chromium.conf
fi

echo "==> [7/8] Configuring User Permissions & Desktop Session for '${TARGET_USER}'..."
for grp in audio video input netdev plugdev wheel; do
    addgroup "${TARGET_USER}" "${grp}" 2>/dev/null || true
done

echo "permit persist :wheel" > /etc/doas.d/doas.conf

USER_HOME="$(eval echo "~${TARGET_USER}")"
mkdir -p "${USER_HOME}/.config/openbox" "${USER_HOME}/.config/tint2"

if [ -f "${SCRIPT_DIR}/configs/openbox/autostart" ]; then
    cp "${SCRIPT_DIR}/configs/openbox/autostart" "${USER_HOME}/.config/openbox/autostart"
    chmod +x "${USER_HOME}/.config/openbox/autostart"
fi

if [ -f "${SCRIPT_DIR}/configs/tint2/tint2rc" ]; then
    cp "${SCRIPT_DIR}/configs/tint2/tint2rc" "${USER_HOME}/.config/tint2/tint2rc"
fi

chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.config"

echo "==> [8/8] FeatherLinux Installation Complete!"
echo "    Idle RAM target: ~95 MB | Reboot to launch into the graphical desktop."
