#!/bin/sh
# ==============================================================================
# FeatherLinux Custom Bootable ISO Overlay Builder (apkovl + ISO generator)
# ==============================================================================
# Generates a pre-configured Alpine Linux overlay (featherlinux.apkovl.tar.gz)
# and automated installer answerfile so you can boot ANY old PC (32-bit or 64-bit,
# BIOS or UEFI) from a USB stick and install FeatherLinux in one command.
# ==============================================================================

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
OVL_DIR="${BUILD_DIR}/ovl"
OUT_DIR="${SCRIPT_DIR}/dist"

rm -rf "${BUILD_DIR}"
mkdir -p "${OVL_DIR}/etc/local.d" \
         "${OVL_DIR}/etc/apk" \
         "${OVL_DIR}/opt/featherlinux/configs/openbox" \
         "${OVL_DIR}/opt/featherlinux/configs/tint2" \
         "${OUT_DIR}"

echo "==> Staging FeatherLinux payload into overlay..."
cp "${SCRIPT_DIR}/install-feather-desktop.sh" "${OVL_DIR}/opt/featherlinux/"
cp "${SCRIPT_DIR}/configs/sysctl-lowram.conf" "${OVL_DIR}/opt/featherlinux/configs/"
cp "${SCRIPT_DIR}/configs/chromium-lowram-flags.conf" "${OVL_DIR}/opt/featherlinux/configs/"
cp "${SCRIPT_DIR}/configs/openbox/autostart" "${OVL_DIR}/opt/featherlinux/configs/openbox/"
cp "${SCRIPT_DIR}/configs/tint2/tint2rc" "${OVL_DIR}/opt/featherlinux/configs/tint2/"
chmod +x "${OVL_DIR}/opt/featherlinux/install-feather-desktop.sh"

# Create automated Alpine setup answerfile for older PCs
cat > "${OVL_DIR}/opt/featherlinux/feather-answers" << 'EOF'
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n featherbook"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1 -c"
USEROPTS="-a -u -g audio,video,netdev,wheel laptop"
SSHDOPTS="none"
NTPOPTS="-c busybox"
DISKOPTS="-m sys /dev/sda"
EOF

# Create welcome MOTD banner with 1-step install command
cat > "${OVL_DIR}/etc/motd" << 'EOF'
========================================================================
  Welcome to FeatherLinux (Ultra-Lightweight Old Laptop Edition)
========================================================================
  To install to your laptop drive:
    1. Run: setup-alpine -f /opt/featherlinux/feather-answers
    2. Reboot into your disk and run:
       /opt/featherlinux/install-feather-desktop.sh
========================================================================
EOF

# Package the .apkovl.tar.gz overlay
TARBALL="${OUT_DIR}/featherbook.apkovl.tar.gz"
tar -C "${OVL_DIR}" -czf "${TARBALL}" .
cp "${SCRIPT_DIR}/install-feather-desktop.sh" "${OUT_DIR}/"

echo "==> Built FeatherLinux overlay: ${TARBALL}"
ls -lh "${OUT_DIR}"
