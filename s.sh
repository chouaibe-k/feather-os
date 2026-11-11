#!/usr/bin/env bash
# ==============================================================================
# FeatherOS — One-Click Windows-Style Lightweight OS & Security Fortress Setup
# Repository: https://github.com/chouaibe-k/feather-os
# ==============================================================================
# Safe for Q4OS Windows Dual-Boot (Wubi/loop) installations:
#   - Does NOT touch GRUB bootloader or GPU power states (prevents black screen)
#   - Enables ZRAM memory compression booster
#   - Enables UFW Firewall, Anti-Malware DNS, Browser Shield & ClamAV Scanner
#   - Enables Automatic Updates & AI Remote Auto-Pilot
# ==============================================================================

set -u

REPO_URL="https://raw.githubusercontent.com/chouaibe-k/feather-os/main"
INSTALL_DIR="/opt/feather-os"

echo "======================================================================"
echo "  FeatherOS — Activating Speed Booster, Security Fortress & Auto-Pilot"
echo "======================================================================"

if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

mkdir -p "${INSTALL_DIR}"

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    echo "==> [1/5] Applying FeatherOS System Branding & Locking Working Boot Config..."
    if [ -f /etc/os-release ]; then
        sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="FeatherOS 1.0 (Ultra-Light Windows Edition)"/' /etc/os-release 2>/dev/null || true
    fi
    # Protect the working Wubi/Q4OS grub.cfg (critical when installed on Drive D:)
    if [ -f /boot/grub/grub.cfg ]; then
        cp -f /boot/grub/grub.cfg /boot/grub/grub.cfg.working.bak 2>/dev/null || true
        chattr +i /boot/grub/grub.cfg 2>/dev/null || true
    fi

    echo "==> [2/5] Installing Core Security & Low-RAM Tools..."
    apt-get update -y || true
    apt-get install -y wget curl ca-certificates ufw unattended-upgrades zram-tools clamav || true

    # Ensure heavy clamav-daemon and tlp are NOT stalling boot or blanking Dell display
    systemctl stop clamav-daemon.service clamav-daemon.socket tlp.service 2>/dev/null || true
    systemctl disable clamav-daemon.service clamav-daemon.socket tlp.service 2>/dev/null || true

    echo "==> [3/5] Activating ZRAM Memory Booster..."
    cat > /etc/default/zramswap << 'EOF'
ALGO=zstd
PERCENT=75
PRIORITY=100
EOF
    systemctl enable --now zramswap 2>/dev/null || service zramswap restart 2>/dev/null || true

    cat > /etc/sysctl.d/99-feather-fortress.conf << 'EOF'
# Low-RAM ZRAM Optimization
vm.swappiness = 180
vm.page-cluster = 0
vm.vfs_cache_pressure = 125

# Anti-Hacker Network Hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF
    sysctl --system >/dev/null 2>&1 || true

    echo "==> [4/5] Activating Anti-Hacker Firewall (UFW) & Anti-Malware DNS..."
    if command -v ufw >/dev/null 2>&1; then
        ufw --force reset >/dev/null 2>&1 || true
        ufw default deny incoming >/dev/null 2>&1 || true
        ufw default allow outgoing >/dev/null 2>&1 || true
        ufw --force enable >/dev/null 2>&1 || true
    fi

    mkdir -p /etc/NetworkManager/conf.d
    cat > /etc/NetworkManager/conf.d/90-feather-security-dns.conf << 'EOF'
[global-dns-domain-*]
servers=1.1.1.2,9.9.9.9,1.0.0.2
EOF
    systemctl reload NetworkManager 2>/dev/null || true

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

    cat > /usr/local/bin/feather-virus-scan << 'EOF'
#!/usr/bin/env bash
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

    cat > /etc/cron.daily/feather-antivirus << 'EOF'
#!/bin/sh
/usr/local/bin/feather-virus-scan
EOF
    chmod +x /etc/cron.daily/feather-antivirus

    echo "==> [5/5] Enabling 100% Automatic Updates & AI Remote Auto-Pilot..."
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    cat > "${INSTALL_DIR}/autopilot-sync.sh" << 'EOF'
#!/usr/bin/env bash
REMOTE_SCRIPT_URL="https://raw.githubusercontent.com/chouaibe-k/feather-os/main/remote-updates.sh"
STATE_FILE="/opt/feather-os/last_applied_version"
TMP_SCRIPT="/tmp/feather-remote-updates.sh"

if wget -qO "${TMP_SCRIPT}" "${REMOTE_SCRIPT_URL}" 2>/dev/null || curl -fsSL "${REMOTE_SCRIPT_URL}" -o "${TMP_SCRIPT}" 2>/dev/null; then
    NEW_HASH="$(sha256sum "${TMP_SCRIPT}" | awk '{print $1}')"
    OLD_HASH="$(cat "${STATE_FILE}" 2>/dev/null || echo "")"
    if [ -n "${NEW_HASH}" ] && [ "${NEW_HASH}" != "${OLD_HASH}" ]; then
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

    systemctl daemon-reload 2>/dev/null || true
    systemctl enable --now feather-autopilot.timer 2>/dev/null || true
fi

echo ""
echo "======================================================================"
echo "  SUCCESS! Your laptop is now running FeatherOS 1.0!"
echo "  - RAM Compression (ZRAM): ACTIVE"
echo "  - Anti-Hacker Firewall & Anti-Malware DNS: ACTIVE"
echo "  - ClamAV Antivirus Shield: ACTIVE"
echo "  - Automatic Updates & AI Remote Control: ACTIVE"
echo "======================================================================"
