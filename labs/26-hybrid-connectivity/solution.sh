#!/usr/bin/env bash
# =============================================================================
# Lab 26 · solution.sh — reference solution for Tasks 3-7. Run setup.sh first.
#   * waits until both VPN gateways are provisioned (can take 45+ minutes)
#   * generates a shared key at run time (stored in ~/.azlunches-lab26-psk, mode 600)
#   * creates the VNet-to-VNet connections in both directions
#   * waits until both connections are Connected
#   * tests ping and HTTP in both directions and shows the effective routes
# Safe to run again. Never prints the shared key.
#   bash solution.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 26)"
PSK_FILE="${HOME}/.azlunches-lab26-psk"

for gw in vgw-nusa-azure vgw-nusa-hq; do
  if [[ -z "$(az_q network vnet-gateway show --resource-group "$RG" --name "$gw" --query name)" ]]; then
    echo "${gw} was not found in ${RG}. Run 'bash setup.sh' first."
    exit 1
  fi
done

banner "Task 3 · Waiting for both gateways (checks every minute, up to 75 minutes)"
for ((minute = 0; minute <= 75; minute++)); do
  a="$(az_q network vnet-gateway show --resource-group "$RG" --name vgw-nusa-azure --query provisioningState)"
  h="$(az_q network vnet-gateway show --resource-group "$RG" --name vgw-nusa-hq --query provisioningState)"
  info "$(date +%H:%M)  vgw-nusa-azure: ${a:-?}   vgw-nusa-hq: ${h:-?}"
  if [[ "$a" == "Succeeded" && "$h" == "Succeeded" ]]; then break; fi
  if [[ "$a" == "Failed" || "$h" == "Failed" ]]; then
    echo "A gateway failed to provision. See Troubleshooting in README.md."
    exit 1
  fi
  if (( minute == 75 )); then
    echo "The gateways are still not ready. Run this script again later."
    exit 1
  fi
  sleep 60
done

banner "Task 4 · Shared key and VNet-to-VNet connections"
if [[ ! -s "$PSK_FILE" ]]; then
  existing="$(az_q network vpn-connection shared-key show --resource-group "$RG" \
    --connection-name con-azure-to-hq --query value)"
  ( umask 077
    if [[ -n "$existing" ]]; then printf '%s\n' "$existing" > "$PSK_FILE"; else openssl rand -hex 24 > "$PSK_FILE"; fi )
  chmod 600 "$PSK_FILE"
  info "Shared key stored in ${PSK_FILE} (readable only by you; never printed)."
fi
create_connection() {  # create_connection <name> <from-gateway> <to-gateway>
  if [[ -n "$(az_q network vpn-connection show --resource-group "$RG" --name "$1" --query name)" ]]; then
    info "Connection $1 already exists."
    return 0
  fi
  info "Creating connection $1 ($2 -> $3)..."
  az network vpn-connection create --resource-group "$RG" --name "$1" --location "$LOCATION" \
    --vnet-gateway1 "$2" --vnet-gateway2 "$3" \
    --shared-key "$(cat "$PSK_FILE")" --output none
}
create_connection con-azure-to-hq vgw-nusa-azure vgw-nusa-hq
create_connection con-hq-to-azure vgw-nusa-hq vgw-nusa-azure

banner "Task 5 · Waiting until both connections are Connected (up to 15 minutes)"
for ((i = 0; i <= 30; i++)); do
  s1="$(az_q network vpn-connection show --resource-group "$RG" --name con-azure-to-hq --query connectionStatus)"
  s2="$(az_q network vpn-connection show --resource-group "$RG" --name con-hq-to-azure --query connectionStatus)"
  info "$(date +%H:%M:%S)  con-azure-to-hq: ${s1:-?}   con-hq-to-azure: ${s2:-?}"
  if [[ "$s1" == "Connected" && "$s2" == "Connected" ]]; then break; fi
  if (( i == 30 )); then
    echo "The connections did not reach Connected. See Troubleshooting in README.md."
    exit 1
  fi
  sleep 30
done

banner "Task 6 · Traffic through the tunnel"
info "vm-azure-1 (10.40.1.10) -> vm-hq-1 (10.0.1.10):"
az vm run-command invoke --resource-group "$RG" --name vm-azure-1 --command-id RunShellScript \
  --scripts "ping -c 4 -W 2 10.0.1.10; curl -s --max-time 5 http://10.0.1.10/ | grep -o 'Served by <strong>[^<]*' | sed 's/<strong>//'" \
  --query "value[0].message" --output tsv
info "vm-hq-1 (10.0.1.10) -> vm-azure-1 (10.40.1.10):"
az vm run-command invoke --resource-group "$RG" --name vm-hq-1 --command-id RunShellScript \
  --scripts "ping -c 4 -W 2 10.40.1.10; echo \"health: \$(curl -s --max-time 5 http://10.40.1.10/health)\"" \
  --query "value[0].message" --output tsv

banner "Task 7 · Effective routes of vm-azure-1's network interface"
NIC_AZ="$(az vm show --resource-group "$RG" --name vm-azure-1 --query "networkProfile.networkInterfaces[0].id" --output tsv)"
az network nic show-effective-route-table --ids "$NIC_AZ" --output table

banner "Done"
info "Check your work with: bash verify.sh — then clean up right away: bash cleanup.sh"
