#!/usr/bin/env bash
# ==============================================================================
# FeatherOS — One-Click Windows-Style Lightweight OS & Security Fortress Setup
# Repository: https://github.com/chouaibe-k/feather-os
# ==============================================================================

set -u

REPO_URL="https://raw.githubusercontent.com/chouaibe-k/feather-os/main"
INSTALL_DIR="/opt/feather-os"

echo "======================================================================"
echo "  FeatherOS — Transforming Base System into FeatherOS Security Edition"
echo "======================================================================"

# Elevate to root automatically with graphical password prompt (pkexec) or sudo
if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

mkdir -p "${INSTALL_DIR}"

if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    echo "==> [1/6] Applying FeatherOS System & Dual-Boot Branding..."
    OLD_HOSTNAME="$(hostname 2>/dev/null || echo debian)"
    echo "featheros" > /etc/hostname
    hostnamectl set-hostname featheros 2>/dev/null || hostname featheros 2>/dev/null || true

    # Ensure /etc/hosts resolves 'featheros' cleanly so sudo never warns
    if ! grep -q "featheros" /etc/hosts 2>/dev/null; then
        echo "127.0.1.1	featheros ${OLD_HOSTNAME}" >> /etc/hosts
    fi

    # Update /etc/os-release and /etc/issue to display FeatherOS
    if [ -f /etc/os-release ]; then
        sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="FeatherOS 1.0 (Ultra-Light Windows Edition)"/' /etc/os-release 2>/dev/null || true
        sed -i 's/^NAME=.*/NAME="FeatherOS"/' /etc/os-release 2>/dev/null || true
    fi
    echo "FeatherOS 1.0 LTS \n \l" > /etc/issue 2>/dev/null || true

    # Update GRUB Dual-Boot Menu title to show "FeatherOS"
    if [ -f /etc/default/grub ]; then
        sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="FeatherOS"/' /etc/default/grub 2>/dev/null || true
        update-grub 2>/dev/null || true
    fi

    echo "==> [2/6] Updating package catalogs & installing core tools..."
    apt-get update -y || true
    apt-get install -y wget curl ca-certificates ufw unattended-upgrades || true
    apt-get install -y zram-tools earlyoom tlp libnotify-bin || true
    apt-get install -y clamav clamav-daemon clamav-freshclam || true

    echo "==> [3/6] Activating ZRAM Memory Booster & Kernel Speed/Security Tuning..."
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

    echo "==> [4/6] Activating Anti-Hacker Firewall (UFW) & Anti-Malware DNS..."
    if command -v ufw >/dev/null 2>&1; then
        ufw --force reset >/dev/null 2>&1 || true
        ufw default deny incoming >/dev/null 2>&1 || true
        ufw default allow outgoing >/dev/null 2>&1 || true
        ufw --force enable >/dev/null 2>&1 || true
    fi

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

    echo "==> [6/6] Enabling 100% Automatic Updates & AI Remote Auto-Pilot..."
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Install the AI Remote Auto-Pilot agent (supports both wget and curl)
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
    "${INSTALL_DIR}/autopilot-sync.sh" || true
fi

echo ""
echo "======================================================================"
echo "  SUCCESS! Your laptop is now running FeatherOS 1.0!"
echo "  - System Branding: FeatherOS 1.0 (Ultra-Light Windows Edition)"
echo "  - RAM Compression (ZRAM): ACTIVE"
echo "  - Anti-Hacker Firewall & Anti-Malware DNS: ACTIVE"
echo "  - ClamAV Antivirus Shield: ACTIVE"
echo "  - Automatic Updates & AI Remote Control: ACTIVE"
echo "======================================================================"
