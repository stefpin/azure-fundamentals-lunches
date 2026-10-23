#!/usr/bin/env bash
# =============================================================================
# Lab 26 · setup.sh — builds both "sites" and STARTS the two VPN gateways.
#
#   Azure side   vnet-nusa-azure 10.40.0.0/16
#                  snet-app 10.40.1.0/24 (nsg-azure-app) · GatewaySubnet 10.40.255.0/27
#                  vm-azure-1 10.40.1.10 — no public IP, tiny web server
#                  pip-vgw-nusa-azure (Standard, zone-redundant) · vgw-nusa-azure (VpnGw1AZ, route-based)
#   Head office  vnet-nusa-hq 10.0.0.0/16   (simulates Pak Budi's network)
#                  snet-hq-servers 10.0.1.0/24 (nsg-hq-servers) · GatewaySubnet 10.0.255.0/27
#                  vm-hq-1 10.0.1.10 — no public IP, tiny web server
#                  pip-vgw-nusa-hq (Standard, zone-redundant) · vgw-nusa-hq (VpnGw1AZ, route-based)
#
# The script takes about 5 minutes. The gateways keep building in Azure for
# 30-45 minutes or more after it finishes.
# COST: each VPN gateway bills for every hour it exists. Run cleanup.sh the same day.
# Safe to run again: existing resources are left as they are.
#   bash setup.sh
#   VPN_SKU=VpnGw2AZ bash setup.sh     # another AZ SKU (default VpnGw1AZ)
#   PIP_ZONES="" bash setup.sh         # only for a region WITHOUT availability zones
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 26)"
VPN_SKU="${VPN_SKU:-VpnGw1AZ}"
PIP_ZONES="${PIP_ZONES-1 2 3}"
case "$VPN_SKU" in
  VpnGw4AZ|VpnGw5AZ) VPN_GENERATION="Generation2" ;;  # offered as Generation2 only
  *)                 VPN_GENERATION="Generation1" ;;  # VpnGw1AZ is Generation1 only
esac

# build_network <vnet> <address-space> <subnet> <subnet-prefix> <gatewaysubnet-prefix> <nsg>
build_network() {
  local vnet="$1" space="$2" subnet="$3" subnet_prefix="$4" gw_prefix="$5" nsg="$6"
  if ! az network nsg show --resource-group "$RG" --name "$nsg" --output none 2>/dev/null; then
    az network nsg create --resource-group "$RG" --name "$nsg" --location "$LOCATION" --output none
  fi
  if ! az network vnet show --resource-group "$RG" --name "$vnet" --output none 2>/dev/null; then
    info "Creating ${vnet} (${space}) with subnet ${subnet} (${subnet_prefix})..."
    az network vnet create --resource-group "$RG" --name "$vnet" --location "$LOCATION" \
      --address-prefixes "$space" --subnet-name "$subnet" --subnet-prefixes "$subnet_prefix" \
      --output none
  fi
  # Only touch the subnet when needed: a re-run while a gateway builds must not modify the VNet.
  if [[ "$(az_q network vnet subnet show --resource-group "$RG" --vnet-name "$vnet" --name "$subnet" \
          --query networkSecurityGroup.id)" != *"/${nsg}" ]]; then
    az network vnet subnet update --resource-group "$RG" --vnet-name "$vnet" --name "$subnet" \
      --network-security-group "$nsg" --output none
  fi
  if ! az network vnet subnet show --resource-group "$RG" --vnet-name "$vnet" --name GatewaySubnet \
       --output none 2>/dev/null; then
    info "Adding GatewaySubnet (${gw_prefix}) to ${vnet} (never attach an NSG to this subnet)..."
    az network vnet subnet create --resource-group "$RG" --vnet-name "$vnet" --name GatewaySubnet \
      --address-prefixes "$gw_prefix" --output none
  fi
}

# create_pip <name>  -> Standard, static, zone-redundant unless PIP_ZONES is empty
create_pip() {
  local pip="$1"
  if az network public-ip show --resource-group "$RG" --name "$pip" --output none 2>/dev/null; then
    return 0
  fi
  info "Creating Standard public IP ${pip}${PIP_ZONES:+ in zones ${PIP_ZONES}}..."
  # shellcheck disable=SC2086  # PIP_ZONES must split into separate zone numbers
  az network public-ip create --resource-group "$RG" --name "$pip" --location "$LOCATION" \
    --sku Standard --allocation-method Static ${PIP_ZONES:+--zone $PIP_ZONES} --output none
}

# start_gateway <gateway> <vnet> <public-ip>  -> starts creation and returns immediately (--no-wait)
start_gateway() {
  local gw="$1" vnet="$2" pip="$3" state
  state="$(az_q network vnet-gateway show --resource-group "$RG" --name "$gw" --query provisioningState)"
  if [[ "$state" == "Failed" ]]; then
    note "${gw} is in state Failed. Delete it (az network vnet-gateway delete -g ${RG} -n ${gw}) and run setup.sh again."
    return 0
  elif [[ -n "$state" ]]; then
    info "${gw} already exists (provisioning state: ${state})."
    return 0
  fi
  info "Starting ${gw}: ${VPN_SKU}, ${VPN_GENERATION}, route-based. It keeps building for 30-45+ minutes."
  az network vnet-gateway create --resource-group "$RG" --name "$gw" --location "$LOCATION" \
    --vnet "$vnet" --public-ip-addresses "$pip" \
    --gateway-type Vpn --vpn-type RouteBased \
    --sku "$VPN_SKU" --vpn-gateway-generation "$VPN_GENERATION" \
    --no-wait --output none
}

# create_vm <vm> <vnet> <subnet> <private-ip>  -> starts creation (--no-wait)
create_vm() {
  local vm="$1" vnet="$2" subnet="$3" ip="$4"
  if az vm show --resource-group "$RG" --name "$vm" --output none 2>/dev/null; then
    info "${vm} already exists."
    return 0
  fi
  info "Creating ${vm} (${VM_SIZE_SMALL}, ${ip}, no public IP)..."
  az vm create --resource-group "$RG" --name "$vm" --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --vnet-name "$vnet" --subnet "$subnet" --private-ip-address "$ip" \
    --public-ip-address "" --nsg "" \
    --custom-data "${AZL_COMMON_DIR}/cloud-init-web.yml" \
    --no-wait --output none
}

banner "Lab 26 setup: Nusantara Retail's Azure network and a simulated head office"
ensure_rg "$RG" 26
info "Resource group: ${RG} (${LOCATION})"

banner "Networks"
build_network vnet-nusa-azure 10.40.0.0/16 snet-app        10.40.1.0/24 10.40.255.0/27 nsg-azure-app
build_network vnet-nusa-hq    10.0.0.0/16  snet-hq-servers 10.0.1.0/24  10.0.255.0/27  nsg-hq-servers

banner "Test VMs (one per side), created before the gateways so nothing else changes the networks later"
create_vm vm-azure-1 vnet-nusa-azure snet-app        10.40.1.10
create_vm vm-hq-1    vnet-nusa-hq    snet-hq-servers 10.0.1.10
for vm in vm-azure-1 vm-hq-1; do
  info "Waiting for ${vm}..."
  az vm wait --resource-group "$RG" --name "$vm" --created --timeout 1200 --output none
done

banner "Gateway public IPs and the two VPN gateways"
create_pip pip-vgw-nusa-azure
create_pip pip-vgw-nusa-hq
start_gateway vgw-nusa-azure vnet-nusa-azure pip-vgw-nusa-azure
start_gateway vgw-nusa-hq    vnet-nusa-hq    pip-vgw-nusa-hq

banner "Setup complete — the gateways are still building"
az network vnet-gateway list --resource-group "$RG" \
  --query "[].{gateway:name, sku:sku.name, vpnType:vpnType, state:provisioningState}" --output table || true
info "Expect 'Updating' for 30-45 minutes or more, then 'Succeeded'."
info "Your suffix is ${SUFFIX} (resource group ${RG}). Write it down in case Cloud Shell restarts."
info "COST: both gateways bill every hour from now on. Finish the lab today and run 'bash cleanup.sh'."
info "Next: README.md, Task 1."
