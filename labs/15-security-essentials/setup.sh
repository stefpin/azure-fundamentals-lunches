#!/usr/bin/env bash
# =============================================================================
# Lab 15 · setup.sh — builds the starting point (about 4 minutes):
#   * resource group rg-lunch15-<suffix>
#   * virtual network vnet-nusa-app (10.15.0.0/16) with subnet snet-app (10.15.1.0/24)
#       - network security group nsg-app: default rules only, nothing exposed
#       - a service endpoint for Microsoft.KeyVault, so the VM can reach Key Vault
#         over the Azure backbone although it has no public IP and the subnet has
#         no outbound internet access
#   * vm-app-1: a small Ubuntu VM without a public IP. Its config file
#     /etc/nusa/appsettings.json holds the orders database password in plain
#     text — the problem you fix in this lab.
# Safe to run again: existing resources are left as they are.
#   bash setup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 15)"
VNET="vnet-nusa-app"
SUBNET="snet-app"
NSG="nsg-app"
VM="vm-app-1"

banner "Lab 15 setup: Nusantara Retail's storefront app server"
ensure_rg "$RG" 15
info "Resource group: ${RG} (${LOCATION})"

if ! az network nsg show --resource-group "$RG" --name "$NSG" --output none 2>/dev/null; then
  info "Creating network security group ${NSG} (default rules only)..."
  az network nsg create --resource-group "$RG" --name "$NSG" --location "$LOCATION" --output none
fi

if ! az network vnet show --resource-group "$RG" --name "$VNET" --output none 2>/dev/null; then
  info "Creating virtual network ${VNET} (10.15.0.0/16) with subnet ${SUBNET} (10.15.1.0/24)..."
  az network vnet create --resource-group "$RG" --name "$VNET" --location "$LOCATION" \
    --address-prefixes 10.15.0.0/16 \
    --subnet-name "$SUBNET" --subnet-prefixes 10.15.1.0/24 \
    --output none
fi

info "Attaching ${NSG} and a Microsoft.KeyVault service endpoint to ${SUBNET}..."
az network vnet subnet update --resource-group "$RG" --vnet-name "$VNET" --name "$SUBNET" \
  --network-security-group "$NSG" \
  --service-endpoints Microsoft.KeyVault \
  --output none

if az vm show --resource-group "$RG" --name "$VM" --output none 2>/dev/null; then
  info "${VM} already exists. Skipping."
else
  info "Creating ${VM} (${VM_SIZE_SMALL}, ${VM_IMAGE}, no public IP). This takes 2-4 minutes..."
  az vm create --resource-group "$RG" --name "$VM" --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --vnet-name "$VNET" --subnet "$SUBNET" \
    --public-ip-address "" --nsg "" \
    --custom-data "${LAB_DIR}/cloud-init-app.yml" \
    --output none
fi

PRIVATE_IP="$(az_q vm list-ip-addresses --resource-group "$RG" --name "$VM" \
  --query "[0].virtualMachine.network.privateIpAddresses[0]")"

banner "Setup complete"
info "VM            : ${VM} (private IP ${PRIVATE_IP:-unknown}, no public IP)"
info "Your suffix   : ${SUFFIX}  ->  your key vault will be kv-nusa-${SUFFIX}"
info "The VM's config file /etc/nusa/appsettings.json contains a plain-text password."
info "Next: open README.md and start with Task 1. Remember to run 'bash cleanup.sh' at the end."
