#!/usr/bin/env bash
# =============================================================================
# Lab 26 · cleanup.sh — removes everything the lab created:
#   * the lab resource group: both VPN gateways, connections, public IPs, VMs,
#     disks, NICs, NSGs and virtual networks (deletion runs in the background;
#     gateways can take 10-20 minutes or more to disappear);
#   * the shared key file ~/.azlunches-lab26-psk in your Cloud Shell home.
# Nothing is created outside the resource group, so nothing else needs removing.
#   bash cleanup.sh            (asks first; ASSUME_YES=1 bash cleanup.sh skips the question)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 26)"
PSK_FILE="${HOME}/.azlunches-lab26-psk"

banner "Lab 26 cleanup"
if ! confirm "Delete resource group ${RG} (VPN gateways, connections, VMs, networks)?"; then
  info "Nothing deleted. Remember: the gateways keep billing every hour until you delete them."
  exit 0
fi

delete_lunch_rgs 26

if [[ -f "$PSK_FILE" ]]; then
  rm -f "$PSK_FILE"
  info "Removed the shared key file ${PSK_FILE}."
fi

banner "Cleanup started"
info "Gateway deletion takes a while (often 10-20 minutes). Billing stops once the gateways are gone."
info "Check later that nothing is left: az group list --tag lunch=26 --output table"
