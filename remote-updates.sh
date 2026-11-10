#!/usr/bin/env bash
# ==============================================================================
# FeatherOS Remote Auto-Pilot Command File (Managed by your AI Assistant)
# ==============================================================================
# Whenever Chouaibe asks the AI Assistant for an update, a new program, or a
# setting change, the AI updates this file on GitHub and the laptop applies it
# automatically within 15 minutes — zero coding required!
#
# Current Release: v1.0.0 (Initial Security & Performance Baseline)
# ==============================================================================

set -euo pipefail

# Ensure automatic cleanup of old cached packages so disk never fills up
if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get autoremove -y >/dev/null 2>&1 || true
    apt-get autoclean -y >/dev/null 2>&1 || true
fi

exit 0
