#!/usr/bin/env bash
# =============================================================================
# Lab 17 · setup.sh — creates the starting point for the restore drill
#
#   * resource group  rg-lunch17-<suffix>
#   * NSG             nsg-orders (no inbound rules of its own)
#   * VNet            vnet-nusa-orders 10.17.0.0/16 with a PRIVATE subnet snet-orders 10.17.1.0/24
#   * VM              vm-orders: Ubuntu, 2 vCPU, no public IP, no internet access
#   * the data        /data/orders.csv (50 orders) and its SHA-256 fingerprint,
#                     written inside the VM with Run Command
#
# Takes about 5 minutes. Safe to run again: it skips what already exists and
# never overwrites (or recreates) the orders file.
#     bash setup.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource providers"
info "Registering Microsoft.RecoveryServices (quick if it's already registered)..."
az provider register --namespace Microsoft.RecoveryServices --wait --output none

banner "Resource group ${RG}"
ensure_rg "$RG" 17
info "Region: ${LOCATION}"

banner "Network: ${VNET} with a private subnet ${SUBNET}"
if [[ -z "$(az_q network nsg show -g "$RG" -n "$NSG" --query id)" ]]; then
  az network nsg create -g "$RG" -n "$NSG" -l "$LOCATION" --output none
fi
if [[ -z "$(az_q network vnet show -g "$RG" -n "$VNET" --query id)" ]]; then
  az network vnet create -g "$RG" -n "$VNET" -l "$LOCATION" --address-prefixes 10.17.0.0/16 --output none
fi
if [[ -z "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$SUBNET" --query id)" ]]; then
  # A private subnet: no implicit internet access. Azure Backup doesn't need it, and the
  # restore in Task 7 works without it too.
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n "$SUBNET" \
    --address-prefixes 10.17.1.0/24 --network-security-group "$NSG" \
    --default-outbound-access false --output none
fi
if [[ -z "$(az_q network nic show -g "$RG" -n "$NIC" --query id)" ]]; then
  az network nic create -g "$RG" -n "$NIC" -l "$LOCATION" --vnet-name "$VNET" --subnet "$SUBNET" --output none
fi
info "Subnet ${SUBNET} 10.17.1.0/24 (private), NIC ${NIC} without a public IP"

banner "VM ${VM} (about 2 minutes)"
if [[ -n "$(az_q vm show -g "$RG" -n "$VM" --query id)" ]]; then
  info "${VM} already exists — skipping."
else
  # Azure Backup needs at least 2 vCPUs and 1 GB of memory, so the lab uses VM_SIZE, not VM_SIZE_SMALL.
  info "Creating ${VM} (${VM_SIZE}, ${VM_IMAGE})..."
  az vm create -g "$RG" -n "$VM" -l "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE" --nics "$NIC" \
    --storage-sku StandardSSD_LRS \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --output none
fi
power="$(az_q vm get-instance-view -g "$RG" -n "$VM" --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")"
if [[ "$power" != "VM running" ]]; then
  info "${VM} is '${power:-unknown}'. Starting it..."
  az vm start -g "$RG" -n "$VM" --output none
fi

banner "The orders file inside ${VM} (about 1 minute)"
out="$(az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts @"${LAB_DIR}/vm/write-orders.sh" --query "value[0].message" --output tsv 2>/dev/null || true)"
if grep -q "ORDERS_WRITTEN\|ORDERS_EXISTS" <<<"$out"; then
  pass "$(grep -m1 "ORDERS_WRITTEN\|ORDERS_EXISTS" <<<"$out")"
elif grep -q "ORDERS_MISSING" <<<"$out"; then
  note "$(grep -m1 "ORDERS_MISSING" <<<"$out")"
else
  note "Could not confirm the orders file yet. Wait a minute and run setup.sh again (see Troubleshooting)."
  [[ -n "$out" ]] && info "$out"
fi

banner "Starting point ready"
info "Resource group : ${RG}"
info "VM             : ${VM} — private IP only, no internet access"
info "Orders file    : /data/orders.csv (fingerprint in /var/lib/nusa/orders.sha256)"
info "Next           : follow Task 1 in README.md"
