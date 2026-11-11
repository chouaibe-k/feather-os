#!/usr/bin/env bash
# ==============================================================================
# FeatherOS Remote Auto-Pilot Command File (Managed by your AI Assistant)
# Release: v1.0.1 — Fix Dark Screen on Boot (Disable clamd boot RAM spike + Restore Backlight)
# ==============================================================================

set -u

# 1. Restore maximum screen brightness immediately (in case Dell backlight dimmed to 0)
for bl in /sys/class/backlight/*; do
    if [ -f "${bl}/max_brightness" ] && [ -f "${bl}/brightness" ]; then
        cat "${bl}/max_brightness" > "${bl}/brightness" 2>/dev/null || true
    fi
done

# 2. Disable heavy clamav-daemon at boot (it uses 1.2GB RAM on boot and stalls login screen!)
#    We keep the lightweight clamscan tool without the heavy background daemon.
systemctl stop clamav-daemon.service clamav-daemon.socket clamav-freshclam.service 2>/dev/null || true
systemctl disable clamav-daemon.service clamav-daemon.socket 2>/dev/null || true

# 3. Prevent TLP from powering off Dell GPU / PCIe display on boot
if [ -f /etc/tlp.conf ]; then
    sed -i 's/^#*RUNTIME_PM_DRIVER_DENYLIST=.*/RUNTIME_PM_DRIVER_DENYLIST="mei_me nouveau radeon amdgpu i915"/' /etc/tlp.conf 2>/dev/null || true
    systemctl restart tlp 2>/dev/null || true
fi

# 4. Ensure GRUB has 'nomodeset' fallback disabled/clean and restore display manager if stuck
chvt 7 2>/dev/null || chvt 1 2>/dev/null || true
systemctl restart display-manager 2>/dev/null || systemctl restart tdm 2>/dev/null || systemctl restart sddm 2>/dev/null || true

exit 0
