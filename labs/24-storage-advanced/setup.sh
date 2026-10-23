#!/usr/bin/env bash
# =============================================================================
# Lab 24 · Ransomware-proof invoices — starting point (about 5 minutes)
#   bash setup.sh
# Creates: resource group, virtual network vnet-nusa-lab24 (snet-vm, snet-pe),
#          a NAT gateway for outbound traffic from snet-vm, and a small Linux VM
#          vm-dns-1 without a public IP, used to test DNS from inside the network.
# Safe to re-run.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 24)"
VNET="vnet-nusa-lab24"
VM="vm-dns-1"
NAT="ng-nusa-lab24"
NAT_PIP="pip-ng-lab24"

banner "Resource group ${RG}"
ensure_rg "$RG" 24

banner "Virtual network ${VNET}: snet-vm 10.24.1.0/24 and snet-pe 10.24.2.0/24"
if ! az network vnet show --resource-group "$RG" --name "$VNET" --output none 2>/dev/null; then
  az network vnet create --resource-group "$RG" --name "$VNET" --location "$LOCATION" \
    --address-prefixes 10.24.0.0/16 --subnet-name snet-vm --subnet-prefixes 10.24.1.0/24 --output none
fi
if ! az network vnet subnet show --resource-group "$RG" --vnet-name "$VNET" --name snet-pe --output none 2>/dev/null; then
  az network vnet subnet create --resource-group "$RG" --vnet-name "$VNET" --name snet-pe \
    --address-prefixes 10.24.2.0/24 --output none
fi

banner "NAT gateway ${NAT} (outbound access for snet-vm)"
# New subnets have no default outbound internet access, and Run Command needs outbound
# HTTPS to return its output. The NAT gateway gives the VM outbound access only.
if ! az network public-ip show --resource-group "$RG" --name "$NAT_PIP" --output none 2>/dev/null; then
  az network public-ip create --resource-group "$RG" --name "$NAT_PIP" --location "$LOCATION" \
    --sku Standard --allocation-method Static --output none
fi
if ! az network nat gateway show --resource-group "$RG" --name "$NAT" --output none 2>/dev/null; then
  az network nat gateway create --resource-group "$RG" --name "$NAT" --location "$LOCATION" \
    --public-ip-addresses "$NAT_PIP" --idle-timeout 4 --output none
fi
az network vnet subnet update --resource-group "$RG" --vnet-name "$VNET" --name snet-vm \
  --nat-gateway "$NAT" --output none

banner "Virtual machine ${VM} (${VM_SIZE_SMALL}, no public IP, no inbound rules)"
if ! az vm show --resource-group "$RG" --name "$VM" --output none 2>/dev/null; then
  info "Creating the VM takes 2–3 minutes…"
  az vm create --resource-group "$RG" --name "$VM" --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --vnet-name "$VNET" --subnet snet-vm \
    --public-ip-address "" --nsg-rule NONE \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --output none
fi

banner "Ready"
info "VM private IP: $(az_q vm show --show-details --resource-group "$RG" --name "$VM" --query privateIps)"
info "You reach the VM only through Run Command (az vm run-command invoke) — it has no public IP."
info "Continue with Task 1 in README.md."
