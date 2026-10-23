#!/usr/bin/env bash
# =============================================================================
# Lab 25 · solution.sh — reference solution for Tasks 2–6 (Guided mode).
#   bash setup.sh && bash solution.sh
# Safe to re-run: every create step checks whether the resource already exists.
# Takes about 5 minutes, mostly Run Command and Network Watcher calls.
# Not included: the Break-it-and-fix-it exercise and the optional Azure Firewall path.
# =============================================================================
set -euo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 25)"
HUB_IP="10.30.1.4"

# run_on <vm> <script>  -> runs a shell script inside the VM through the VM agent and prints its output
run_on() {
  az vm run-command invoke -g "$RG" -n "$1" --command-id RunShellScript \
    --scripts "$2" --query "value[0].message" -o tsv
}
# exists <az show command...>  -> true when the resource exists
exists() { "$@" --output none >/dev/null 2>&1; }
nic_of() { az vm show -g "$RG" -n "$1" --query "networkProfile.networkInterfaces[0].id" -o tsv; }

if ! exists az vm show -g "$RG" -n vm-spoke2; then
  echo "The starting point is missing. Run 'bash setup.sh' first."
  exit 1
fi

# -----------------------------------------------------------------------------
banner "Task 2 · Peer the hub with each spoke (both directions)"
# peer <local vnet> <remote vnet> <link name>
peer() {
  if exists az network vnet peering show -g "$RG" --vnet-name "$1" -n "$3"; then
    az network vnet peering update -g "$RG" --vnet-name "$1" -n "$3" \
      --allow-vnet-access true --allow-forwarded-traffic true --output none
    info "$3 already exists (settings refreshed)"
  else
    az network vnet peering create -g "$RG" -n "$3" --vnet-name "$1" --remote-vnet "$2" \
      --allow-vnet-access true --allow-forwarded-traffic true --output none
    info "Created $3"
  fi
}
for spoke in spoke1 spoke2; do
  peer vnet-nusa-hub "vnet-nusa-$spoke" "peer-hub-to-$spoke"
  peer "vnet-nusa-$spoke" vnet-nusa-hub "peer-$spoke-to-hub"
done
for v in vnet-nusa-hub vnet-nusa-spoke1 vnet-nusa-spoke2; do
  az network vnet peering list -g "$RG" --vnet-name "$v" \
    --query "[].{vnet:'$v', link:name, state:peeringState, forwarded:allowForwardedTraffic}" -o table
done

# -----------------------------------------------------------------------------
banner "Task 3 · Peering is not transitive"
RT1_EXISTS="$(az_q network vnet subnet show -g "$RG" --vnet-name vnet-nusa-spoke1 -n snet-workload --query routeTable.id)"
if [[ -z "$RT1_EXISTS" ]]; then
  run_on vm-spoke1 'ping -c 3 -W 2 10.30.1.4 >/dev/null && echo "spoke1 -> hub: REACHABLE" || echo "spoke1 -> hub: UNREACHABLE"'
  run_on vm-spoke1 'ping -c 3 -W 2 10.32.1.4 >/dev/null && echo "spoke1 -> spoke2: REACHABLE" || echo "spoke1 -> spoke2: UNREACHABLE"'
  az network watcher show-next-hop -g "$RG" --vm vm-spoke1 --source-ip 10.31.1.4 --dest-ip 10.32.1.4 -o table \
    || note "Next hop failed — is Network Watcher enabled in $LOCATION?"
else
  info "Route tables already exist, so the 'before' test is skipped."
fi

# -----------------------------------------------------------------------------
banner "Task 4 · Turn vm-hub-nva into a router"
HUB_NIC="$(nic_of vm-hub-nva)"
az network nic update --ids "$HUB_NIC" --ip-forwarding true --output none
info "IP forwarding on the hub NIC: $(az_q network nic show --ids "$HUB_NIC" --query "enableIPForwarding || enableIpForwarding")"
run_on vm-hub-nva 'sysctl -w net.ipv4.ip_forward=1 >/dev/null && echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nusa-router.conf && echo "ip_forward=$(sysctl -n net.ipv4.ip_forward)"'

# -----------------------------------------------------------------------------
banner "Task 5 · Route tables: each spoke reaches the other through the hub"
# route_via_hub <route table> <route name> <destination prefix> <spoke vnet>
route_via_hub() {
  local rt="$1" route="$2" prefix="$3" vnet="$4"
  # 'route-table create' replaces existing routes, so only create when missing.
  if ! exists az network route-table show -g "$RG" -n "$rt"; then
    az network route-table create -g "$RG" -n "$rt" --location "$LOCATION" --output none
  fi
  az network route-table route create -g "$RG" --route-table-name "$rt" -n "$route" \
    --address-prefix "$prefix" --next-hop-type VirtualAppliance --next-hop-ip-address "$HUB_IP" --output none
  az network vnet subnet update -g "$RG" --vnet-name "$vnet" -n snet-workload --route-table "$rt" --output none
  info "$rt: $prefix -> VirtualAppliance $HUB_IP, associated with $vnet/snet-workload"
}
route_via_hub rt-spoke1 to-spoke2-via-hub 10.32.0.0/16 vnet-nusa-spoke1
route_via_hub rt-spoke2 to-spoke1-via-hub 10.31.0.0/16 vnet-nusa-spoke2

info "Effective routes of vm-spoke1's NIC:"
az network nic show-effective-route-table --ids "$(nic_of vm-spoke1)" -o table || note "Effective routes need a running VM."
for pair in "vm-spoke1 10.31.1.4 10.32.1.4" "vm-spoke2 10.32.1.4 10.31.1.4"; do
  read -r vm src dst <<< "$pair"
  info "Next hop from $vm ($src) to $dst:"
  az network watcher show-next-hop -g "$RG" --vm "$vm" --source-ip "$src" --dest-ip "$dst" -o table \
    || note "Next hop failed — is Network Watcher enabled in $LOCATION?"
done

# -----------------------------------------------------------------------------
banner "Task 6 · Prove that spoke-to-spoke traffic flows through the hub"
info "Giving the new routes 30 seconds to apply..."
sleep 30
info "Hub forwarded-packet counter before:"
run_on vm-hub-nva 'nstat -az IpForwDatagrams'
run_on vm-spoke1 'ping -c 5 -W 2 10.32.1.4; curl -s --max-time 5 http://10.32.1.4/ | grep -q vm-spoke2 && echo "HTTP from vm-spoke2: OK" || echo "HTTP: FAILED"'
info "Hub forwarded-packet counter after:"
run_on vm-hub-nva 'nstat -az IpForwDatagrams'

banner "Done"
info "Every task is complete. Check it with:  bash verify.sh"
info "Delete everything afterwards with:     bash cleanup.sh"
