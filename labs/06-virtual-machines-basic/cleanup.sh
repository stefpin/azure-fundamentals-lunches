#!/usr/bin/env bash
# =============================================================================
# Lab 06 · Clean up — deletes everything the lab created.
#   bash cleanup.sh              # asks for confirmation
#   ASSUME_YES=1 bash cleanup.sh # no prompt (for scripts and CI)
#
# Removes: every resource group tagged lunch=06 (VM, disks, NIC, NSG, public IP,
# virtual network and the auto-shutdown schedule live inside it), any role
# assignments made on the VM for the Entra ID stretch goal, and the VM's entry
# in ~/.ssh/known_hosts. Your SSH key pair is kept for other labs.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 06)"
VM="vm-web-1"

banner "Lab 06 · clean up"
if ! confirm "Delete all Lab 06 resources (resource groups tagged lunch=06)?"; then
  info "Nothing was deleted."
  exit 0
fi

IP="$(az_q vm show -d -g "$RG" -n "$VM" --query publicIps)"
VM_ID="$(az_q vm show -g "$RG" -n "$VM" --query id)"

# Role assignments scoped to the VM (stretch goal: Microsoft Entra ID login).
if [[ -n "$VM_ID" ]]; then
  while IFS= read -r ra; do
    [[ -z "$ra" ]] && continue
    if az role assignment delete --ids "$ra" --output none 2>/dev/null; then
      info "Removed role assignment ${ra##*/}"
    fi
  done < <(az_q role assignment list --scope "$VM_ID" --query "[].id")
fi

delete_lunch_rgs 06

if [[ -n "$IP" ]]; then
  ssh-keygen -R "$IP" >/dev/null 2>&1 || true
  info "Removed ${IP} from ~/.ssh/known_hosts."
fi
info "Your SSH key pair in ~/.ssh is kept — other labs reuse it."
info "Check later with: az group list --tag lunch=06 -o table   (it should print nothing)"
