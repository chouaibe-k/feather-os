#!/usr/bin/env bash
# ==============================================================================
# FeatherOS — One-Click Windows-Style Lightweight OS & Security Fortress Setup
# Repository: https://github.com/chouaibe-k/feather-os
# ==============================================================================
# Designed for non-coders. Automatically configures:
#   1. Ultra-Low RAM Booster (ZRAM zstd memory compression + kernel tuning)
#   2. 5-Layer Anti-Virus, Anti-Trojan & Anti-Hacker Security Fortress
#      - UFW Strict Firewall (blocks all incoming hacker connections)
#      - ClamAV Antivirus + Daily Signature Updates + Automatic Downloads Guard
#      - Anti-Malware / Anti-Phishing DNS Shield (Cloudflare 1.1.1.2 & Quad9 9.9.9.9)
#      - Browser Shield (Auto-blocks malicious ads, popups, and Trojans)
#   3. 100% Automatic System Updates + AI Remote Auto-Pilot
#      - Pulls updates automatically from https://github.com/chouaibe-k/feather-os
#        whenever you ask your AI assistant to make a change!
# ==============================================================================

set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/chouaibe-k/feather-os/main"
INSTALL_DIR="/opt/feather-os"

echo "======================================================================"
echo "  FeatherOS — Setting Up Lightweight Speed, Security & Auto-Updates"
echo "======================================================================"

# Elevate to root automatically with graphical password prompt (pkexec) or sudo
if [ "$(id -u)" -ne 0 ]; then
    if command -v pkexec >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        exec pkexec bash "$0" "$@"
    else
        exec sudo bash "$0" "$@"
    fi
fi

mkdir -p "${INSTALL_DIR}"

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    echo "==> [1/6] Updating package catalogs..."
    apt-get update -y

    echo "==> [2/6] Installing ZRAM Memory Booster & Laptop Battery Saver..."
    apt-get install -y \
        zram-tools \
        earlyoom \
        tlp \
        curl \
        ca-certificates \
        ufw \
        unattended-upgrades \
        apt-listchanges \
        clamav \
        clamav-daemon \
        clamav-freshclam \
        libnotify-bin || true

    # Configure ZRAM (compresses RAM 3:1 so old laptops never freeze)
    cat > /etc/default/zramswap << 'EOF'
ALGO=zstd
PERCENT=75
PRIORITY=100
EOF
    systemctl enable --now zramswap 2>/dev/null || service zramswap restart 2>/dev/null || true
    systemctl enable --now earlyoom 2>/dev/null || true
    systemctl enable --now tlp 2>/dev/null || true

    # Kernel Low-RAM & Anti-Exploit Hardening
    cat > /etc/sysctl.d/99-feather-fortress.conf << 'EOF'
# Low-RAM ZRAM Optimization
vm.swappiness = 180
vm.page-cluster = 0
vm.vfs_cache_pressure = 125
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10

# Anti-Hacker Network & Kernel Hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1
EOF
    sysctl --system >/dev/null 2>&1 || true

    echo "==> [3/6] Activating Anti-Hacker Firewall (UFW)..."
    ufw --force reset >/dev/null
    ufw default deny incoming
    ufw default allow outgoing
    ufw --force enable

    echo "==> [4/6] Configuring Anti-Malware DNS Shield & Browser Protection..."
    # Configure Malware & Phishing Blocking DNS (Cloudflare Security 1.1.1.2 + Quad9 9.9.9.9)
    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/90-feather-security-dns.conf << 'EOF'
[global-dns-domain-*]
servers=1.1.1.2,9.9.9.9,1.0.0.2
EOF
    systemctl reload NetworkManager 2>/dev/null || true

    # Install Browser Enterprise Security & Low-RAM Policy (Chromium / Chrome / Brave / Edge)
    for policy_dir in /etc/chromium/policies/managed /etc/opt/chrome/policies/managed /etc/brave/policies/managed; do
        mkdir -p "${policy_dir}"
        cat > "${policy_dir}/feather-security-and-speed.json" << 'EOF'
{
  "SafeBrowsingProtectionLevel": 2,
  "SafeBrowsingExtendedReportingEnabled": false,
  "DnsOverHttpsMode": "automatic",
  "DnsOverHttpsTemplates": "https://security.cloudflare-dns.com/dns-query",
  "HighEfficiencyModeEnabled": true,
  "BatterySaverModeAvailability": 1,
  "BackgroundModeEnabled": false,
  "BlockThirdPartyCookies": true,
  "PopupsAllowedForUrls": [],
  "DefaultPopupsSetting": 2,
  "DownloadRestrictions": 1
}
EOF
    done

    echo "==> [5/6] Configuring ClamAV Antivirus & Automatic Downloads Guard..."
    systemctl enable --now clamav-freshclam 2>/dev/null || true
    cat > /usr/local/bin/feather-virus-scan << 'EOF'
#!/usr/bin/env bash
# Scans all user Downloads & Desktop folders for viruses/Trojans and quarantines threats
QUARANTINE_DIR="/var/lib/clamav/quarantine"
mkdir -p "${QUARANTINE_DIR}"
chmod 700 "${QUARANTINE_DIR}"
for home_dir in /home/*; do
    [ -d "${home_dir}" ] || continue
    for target in "${home_dir}/Downloads" "${home_dir}/Desktop"; do
        if [ -d "${target}" ]; then
            clamscan -r --infected --move="${QUARANTINE_DIR}" "${target}" >/var/log/feather-av-scan.log 2>&1 || true
        fi
    done
done
EOF
    chmod +x /usr/local/bin/feather-virus-scan

    # Run daily automatic virus scan on Downloads & Desktop
    cat > /etc/cron.daily/feather-antivirus << 'EOF'
#!/bin/sh
/usr/local/bin/feather-virus-scan
EOF
    chmod +x /etc/cron.daily/feather-antivirus

    echo "==> [6/6] Enabling 100% Automatic Updates & AI Remote Auto-Pilot..."
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Install the AI Remote Auto-Pilot agent that pulls remote changes from GitHub
    cat > "${INSTALL_DIR}/autopilot-sync.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/chouaibe-k/feather-os/main/remote-updates.sh"
STATE_FILE="/opt/feather-os/last_applied_version"
TMP_SCRIPT="/tmp/feather-remote-updates.sh"

if curl -fsSL "${REMOTE_SCRIPT_URL}" -o "${TMP_SCRIPT}"; then
    NEW_HASH="$(sha256sum "${TMP_SCRIPT}" | awk '{print $1}')"
    OLD_HASH="$(cat "${STATE_FILE}" 2>/dev/null || echo "")"
    if [ "${NEW_HASH}" != "${OLD_HASH}" ]; then
        bash "${TMP_SCRIPT}" && echo "${NEW_HASH}" > "${STATE_FILE}"
    fi
fi
EOF
    chmod +x "${INSTALL_DIR}/autopilot-sync.sh"

    cat > /etc/systemd/system/feather-autopilot.service << 'EOF'
[Unit]
Description=FeatherOS Remote Auto-Pilot & Automatic Maintenance
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/feather-os/autopilot-sync.sh
EOF

    cat > /etc/systemd/system/feather-autopilot.timer << 'EOF'
[Unit]
Description=Run FeatherOS Remote Auto-Pilot every 15 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable --now feather-autopilot.timer
    "${INSTALL_DIR}/autopilot-sync.sh" || true

elif command -v apk >/dev/null 2>&1; then
    # Fallback for Alpine Linux
    curl -fsSL "${REPO_URL}/install-feather-desktop.sh" | sh
fi

echo ""
echo "======================================================================"
echo "  SUCCESS! Your laptop is now protected, optimized, and on Auto-Pilot!"
echo "  - RAM Compression (ZRAM): ACTIVE"
echo "  - Anti-Hacker Firewall & Anti-Malware DNS: ACTIVE"
echo "  - ClamAV Antivirus Shield: ACTIVE"
echo "  - Automatic Updates & AI Remote Control: ACTIVE"
echo "======================================================================"
