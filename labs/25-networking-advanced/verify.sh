#!/usr/bin/env bash
# =============================================================================
# Lab 25 · verify.sh — checks the Challenge brief and prints PASS/FAIL per check.
#   bash verify.sh
# Read-only: it creates nothing. Takes about 2 minutes, because it asks Network
# Watcher for next hops and sends real traffic through Run Command.
# =============================================================================
set -uo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 25)"

# run_on <vm> <script>  -> output of a Run Command script (empty if it could not run)
run_on() {
  az vm run-command invoke -g "$RG" -n "$1" --command-id RunShellScript \
    --scripts "$2" --query "value[0].message" -o tsv 2>/dev/null || true
}
nic_of() { az_q vm show -g "$RG" -n "$1" --query "networkProfile.networkInterfaces[0].id"; }
ip_of() {
  local nic
  nic="$(nic_of "$1")"
  [[ -n "$nic" ]] && az_q network nic show --ids "$nic" \
    --query "ipConfigurations[0].privateIPAddress || ipConfigurations[0].privateIpAddress"
}
running() {
  [[ "$(az_q vm get-instance-view -g "$RG" -n "$1" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]")" == "PowerState/running" ]]
}

banner "Resource group and starting point"
rg_exists="$(az_q group exists -n "$RG")"
if [[ "${rg_exists,,}" != "true" ]]; then
  fail "Resource group $RG not found — run 'bash setup.sh' first"
  summary
  exit 1
fi
pass "Resource group $RG exists"
for spec in "vnet-nusa-hub 10.30.0.0/16" "vnet-nusa-spoke1 10.31.0.0/16" "vnet-nusa-spoke2 10.32.0.0/16"; do
  read -r vnet space <<< "$spec"
  check_contains "$vnet exists with address space $space" "$space" \
    "$(az_q network vnet show -g "$RG" -n "$vnet" --query "join(',', addressSpace.addressPrefixes)")"
done

banner "Peerings (Task 2)"
check_ge "vnet-nusa-hub has 2 Connected peerings" 2 \
  "$(az_q network vnet peering list -g "$RG" --vnet-name vnet-nusa-hub --query "[?peeringState=='Connected'] | length(@)")"
for spoke in spoke1 spoke2; do
  vnet="vnet-nusa-$spoke"
  check_ge "$vnet has a Connected peering to the hub" 1 \
    "$(az_q network vnet peering list -g "$RG" --vnet-name "$vnet" \
      --query "[?peeringState=='Connected' && contains(remoteVirtualNetwork.id, 'vnet-nusa-hub')] | length(@)")"
  check_eq "$vnet's link to the hub allows forwarded traffic" "true" \
    "$(az_q network vnet peering list -g "$RG" --vnet-name "$vnet" \
      --query "[?contains(remoteVirtualNetwork.id, 'vnet-nusa-hub')].allowForwardedTraffic | [0]")"
done
check_eq "The spokes are not peered with each other directly" "0" \
  "$(az_q network vnet peering list -g "$RG" --vnet-name vnet-nusa-spoke1 \
    --query "[?contains(remoteVirtualNetwork.id, 'vnet-nusa-spoke2')] | length(@)")"

banner "Router in the hub (Task 4)"
HUB_NIC="$(nic_of vm-hub-nva)"
HUB_IP="$(ip_of vm-hub-nva)"
check_nonempty "vm-hub-nva exists" "$HUB_NIC"
if [[ -n "$HUB_NIC" ]]; then
  check_eq "IP forwarding is enabled on vm-hub-nva's network interface" "true" \
    "$(az_q network nic show --ids "$HUB_NIC" --query "enableIPForwarding || enableIpForwarding")"
  if running vm-hub-nva; then
    out="$(run_on vm-hub-nva 'echo "IP_FORWARD=$(sysctl -n net.ipv4.ip_forward)"; grep -rqsE "^[[:space:]]*net\.ipv4\.ip_forward[[:space:]]*=[[:space:]]*1" /etc/sysctl.conf /etc/sysctl.d && echo "PERSISTENT=yes" || echo "PERSISTENT=no"')"
    check_contains "Linux on vm-hub-nva forwards packets (net.ipv4.ip_forward = 1)" "IP_FORWARD=1" "$out"
    if [[ "$out" == *"PERSISTENT=no"* ]]; then
      note "ip_forward isn't saved in /etc/sysctl.d — it would be lost after a reboot (see Task 4)."
    fi
  else
    fail "vm-hub-nva is not running — start it with: az vm start -g $RG -n vm-hub-nva"
  fi
fi

banner "Route tables and next hops (Task 5)"
S1_IP="$(ip_of vm-spoke1)"
S2_IP="$(ip_of vm-spoke2)"
for spoke in spoke1 spoke2; do
  check_nonempty "vnet-nusa-$spoke/snet-workload has a route table" \
    "$(az_q network vnet subnet show -g "$RG" --vnet-name "vnet-nusa-$spoke" -n snet-workload --query routeTable.id)"
done
# Accepted next hops: the hub VM, or the private IP of an Azure Firewall in the resource group (optional path).
ALLOWED=" $HUB_IP "
while IFS= read -r fw_id; do
  [[ -z "$fw_id" ]] && continue
  ALLOWED+="$(az_q resource show --ids "$fw_id" --query "properties.ipConfigurations[0].properties.privateIPAddress") "
done < <(az_q resource list -g "$RG" --resource-type Microsoft.Network/azureFirewalls --query "[].id")
for pair in "vm-spoke1 $S1_IP $S2_IP" "vm-spoke2 $S2_IP $S1_IP"; do
  read -r vm src dst <<< "$pair"
  if [[ -z "$src" || -z "$dst" ]]; then
    fail "Could not read the spoke VMs' IP addresses — did setup.sh finish?"
    continue
  fi
  if ! running "$vm"; then
    fail "$vm is not running — start it with: az vm start -g $RG -n $vm"
    continue
  fi
  read -r hop_type hop_ip <<< "$(az_q network watcher show-next-hop -g "$RG" --vm "$vm" \
    --source-ip "$src" --dest-ip "$dst" --query "[nextHopType, nextHopIpAddress]" | tr '\n\t' '  ')"
  check_eq "Next hop from $vm to $dst is a virtual appliance" "VirtualAppliance" "${hop_type:-}"
  if [[ -n "${hop_ip:-}" && "$ALLOWED" == *" $hop_ip "* ]]; then
    pass "That appliance is the hub router or firewall ($hop_ip)"
  else
    fail "That appliance is the hub router or firewall (expected one of:${ALLOWED}got '${hop_ip:-<empty>}')"
  fi
done

banner "Spoke-to-spoke traffic through the hub (Task 6)"
if [[ -n "$S2_IP" ]] && running vm-spoke1; then
  out="$(run_on vm-spoke1 "ping -c 3 -W 2 $S2_IP >/dev/null && echo PING=OK || echo PING=FAILED; curl -s --max-time 5 http://$S2_IP/ | grep -q vm-spoke2 && echo HTTP=OK || echo HTTP=FAILED")"
  check_contains "vm-spoke1 can ping vm-spoke2 ($S2_IP)" "PING=OK" "$out"
  check_contains "vm-spoke1 can fetch vm-spoke2's web page on port 80" "HTTP=OK" "$out"
else
  fail "Connectivity test skipped: vm-spoke1 is not running or vm-spoke2's IP is unknown"
fi

summary
