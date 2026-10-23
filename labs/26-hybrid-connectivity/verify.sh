#!/usr/bin/env bash
# =============================================================================
# Lab 26 · verify.sh — checks the Challenge brief and prints PASS/FAIL per check.
# It changes nothing. It reads the effective routes of vm-azure-1 and runs a small
# ping/HTTP test inside each VM through Run Command (2-3 minutes in total).
#   bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 26)"

banner "Lab 26 · verify (resource group ${RG})"
check "Resource group ${RG} exists" az group show --name "$RG"

banner "Address plan"
az_space="$(az_q network vnet show --resource-group "$RG" --name vnet-nusa-azure --query "addressSpace.addressPrefixes[0]")"
check_eq "vnet-nusa-azure uses 10.40.0.0/16" "10.40.0.0/16" "$az_space"
hq_space="$(az_q network vnet show --resource-group "$RG" --name vnet-nusa-hq --query "addressSpace.addressPrefixes[0]")"
check_eq "vnet-nusa-hq (head office) uses 10.0.0.0/16" "10.0.0.0/16" "$hq_space"
for vnet in vnet-nusa-azure vnet-nusa-hq; do
  prefix="$(az_q network vnet subnet show --resource-group "$RG" --vnet-name "$vnet" --name GatewaySubnet \
    --query "addressPrefix || addressPrefixes[0]")"
  bits="${prefix##*/}"
  if [[ "$bits" =~ ^[0-9]+$ ]] && (( bits <= 27 )); then
    pass "${vnet} has a GatewaySubnet of /27 or larger (${prefix})"
  else
    fail "${vnet} has a GatewaySubnet of /27 or larger (found '${prefix:-none}')"
  fi
done

banner "VPN gateways"
for gw in vgw-nusa-azure vgw-nusa-hq; do
  state="$(az_q network vnet-gateway show --resource-group "$RG" --name "$gw" --query provisioningState)"
  check_eq "${gw} is provisioned" "Succeeded" "$state"
  vtype="$(az_q network vnet-gateway show --resource-group "$RG" --name "$gw" --query vpnType)"
  check_eq "${gw} is route-based" "RouteBased" "$vtype"
  sku="$(az_q network vnet-gateway show --resource-group "$RG" --name "$gw" --query sku.name)"
  if [[ "$sku" == VpnGw*AZ ]]; then
    pass "${gw} uses an AZ SKU (${sku})"
  else
    fail "${gw} uses an AZ SKU such as VpnGw1AZ (found '${sku:-none}')"
  fi
done
for pip in pip-vgw-nusa-azure pip-vgw-nusa-hq; do
  psku="$(az_q network public-ip show --resource-group "$RG" --name "$pip" --query sku.name)"
  check_eq "${pip} is a Standard public IP" "Standard" "$psku"
  zones="$(az_q network public-ip show --resource-group "$RG" --name "$pip" --query "length(zones || \`[]\`)")"
  if [[ "${zones:-0}" -ge 3 ]]; then
    pass "${pip} is zone-redundant"
  else
    note "${pip} is not zone-redundant (acceptable only in a region without availability zones)"
  fi
done

banner "Connections"
for con in con-azure-to-hq con-hq-to-azure; do
  ctype="$(az_q network vpn-connection show --resource-group "$RG" --name "$con" --query connectionType)"
  check_eq "${con} exists and is a VNet-to-VNet connection" "Vnet2Vnet" "$ctype"
  status="$(az_q network vpn-connection show --resource-group "$RG" --name "$con" --query connectionStatus)"
  check_eq "${con} is Connected" "Connected" "$status"
done

banner "Routing and traffic (Run Command, 2-3 minutes)"
running() {
  [[ "$(az_q vm get-instance-view --resource-group "$RG" --name "$1" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]")" == "PowerState/running" ]]
}
if running vm-azure-1; then
  NIC_AZ="$(az_q vm show --resource-group "$RG" --name vm-azure-1 --query "networkProfile.networkInterfaces[0].id")"
  hop="$(az_q network nic show-effective-route-table --ids "$NIC_AZ" \
    --query "value[?contains(addressPrefix, '10.0.0.0/16') && state=='Active'].nextHopType | [0]")"
  check_eq "vm-azure-1 routes 10.0.0.0/16 to the virtual network gateway" "VirtualNetworkGateway" "$hop"
  out="$(az vm run-command invoke --resource-group "$RG" --name vm-azure-1 --command-id RunShellScript \
    --scripts 'if ping -c 3 -W 2 10.0.1.10 > /dev/null; then echo PING-OK; else echo PING-FAILED; fi; echo "HTTP-$(curl -s --max-time 5 http://10.0.1.10/health)"' \
    --query "value[0].message" --output tsv 2>&1)"
  check_contains "vm-azure-1 can ping vm-hq-1 (10.0.1.10) through the tunnel" "PING-OK" "$out"
  check_contains "vm-azure-1 gets HTTP 'ok' from vm-hq-1's /health" "HTTP-ok" "$out"
else
  fail "vm-azure-1 is running (start it: az vm start -g ${RG} -n vm-azure-1)"
fi
if running vm-hq-1; then
  out="$(az vm run-command invoke --resource-group "$RG" --name vm-hq-1 --command-id RunShellScript \
    --scripts 'if ping -c 3 -W 2 10.40.1.10 > /dev/null; then echo PING-OK; else echo PING-FAILED; fi; echo "HTTP-$(curl -s --max-time 5 http://10.40.1.10/health)"' \
    --query "value[0].message" --output tsv 2>&1)"
  check_contains "vm-hq-1 can ping vm-azure-1 (10.40.1.10) through the tunnel" "PING-OK" "$out"
  check_contains "vm-hq-1 gets HTTP 'ok' from vm-azure-1's /health" "HTTP-ok" "$out"
else
  fail "vm-hq-1 is running (start it: az vm start -g ${RG} -n vm-hq-1)"
fi

summary || true
note "Reminder: the gateways bill every hour. When you are done, run: bash cleanup.sh"
(( FAILED == 0 ))
