#!/usr/bin/env bash
# =============================================================================
# Lab 09 · cleanup.sh — deletes everything this lab created.
#     bash cleanup.sh            (asks for confirmation)
#     ASSUME_YES=1 bash cleanup.sh
# Everything lives in the resource group rg-lunch09-<suffix>; nothing is created
# outside it, so deleting the group is enough.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Clean up Lab 09"
ip="$(lb_ip || true)"

if ! confirm "Delete every resource group created for Lunch 09 (VMs, disks, load balancer, public IP, network)?"; then
  info "Nothing deleted."
  exit 0
fi

delete_lunch_rgs 09

# Forget the SSH host key you accepted through the inbound NAT rule (harmless if absent).
if [[ -n "$ip" && -f "${HOME}/.ssh/known_hosts" ]]; then
  ssh-keygen -R "[${ip}]:${NAT_PORT}" >/dev/null 2>&1 || true
fi

info "Any deletion started above continues in the background for a few minutes. Check with:"
info "  az group list --tag lunch=09 --output table"
