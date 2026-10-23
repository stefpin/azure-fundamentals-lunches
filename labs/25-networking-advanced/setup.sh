#!/usr/bin/env bash
# =============================================================================
# Lab 25 · setup.sh — creates the starting point for the hub-and-spoke lab:
#   * resource group rg-lunch25-<suffix>
#   * three virtual networks, NOT peered yet, each with one private subnet:
#       vnet-nusa-hub     10.30.0.0/16   snet-nva       10.30.1.0/24
#       vnet-nusa-spoke1  10.31.0.0/16   snet-workload  10.31.1.0/24   (storefront)
#       vnet-nusa-spoke2  10.32.0.0/16   snet-workload  10.32.1.0/24   (back office)
#   * three Ubuntu VMs ($VM_SIZE_SMALL, 2 vCPUs each by default — 6 vCPUs in total), no public IPs,
#     no NIC-level NSGs:
#       vm-hub-nva 10.30.1.4 · vm-spoke1 10.31.1.4 · vm-spoke2 10.32.1.4
#     The spoke VMs run the course's shared cloud-init web server on port 80.
#
#   bash setup.sh        # about 8 minutes; safe to re-run
# =============================================================================
set -euo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 25)"
# exists <az show command...>  -> true when the resource exists
exists() { "$@" --output none >/dev/null 2>&1; }

banner "Pre-flight: vCPU quota for three VMs"
vcpus="$(az_q vm list-skus --location "$LOCATION" --size "$VM_SIZE_SMALL" --resource-type virtualMachines \
  --query "[?name=='${VM_SIZE_SMALL}'] | [0].capabilities[?name=='vCPUs'].value | [0]")"
vcpus="${vcpus:-2}"
existing="$(az_q vm list -g "$RG" --query "length(@)")"
[[ "$existing" =~ ^[0-9]+$ ]] || existing=0
[[ "$vcpus" =~ ^[0-9]+$ ]] || vcpus=2
need=$(( vcpus * (3 - ${existing:-0}) ))
used=""; limit=""
read -r used limit < <(az_q vm list-usage --location "$LOCATION" --query "[?name.value=='cores'] | [0].[currentValue, limit]" | tr '\t' ' ') || true
if [[ "${limit:-}" =~ ^[0-9]+$ && "${used:-}" =~ ^[0-9]+$ ]]; then
  free=$(( limit - used ))
  if (( need > 0 && free < need )); then
    echo "This lab needs ${need} more vCPUs (three ${VM_SIZE_SMALL} VMs), but only ${free} of ${limit} are free in ${LOCATION}."
    echo "Delete VMs left over from other labs, or request more quota (portal: Subscriptions › Usage + quotas),"
    echo "then run 'bash setup.sh' again. To try anyway, run: FORCE=1 bash setup.sh"
    [[ "${FORCE:-}" == "1" ]] || exit 1
  else
    info "Total regional vCPUs: ${free} of ${limit} free; this lab needs ${need} more."
  fi
else
  note "Could not read your vCPU quota — continuing."
fi

banner "Resource group"
ensure_rg "$RG" 25
info "$RG in $LOCATION"

banner "Virtual networks (private subnets, no peerings yet)"
# create_vnet <vnet> <address space> <subnet> <subnet prefix>
create_vnet() {
  local vnet="$1" space="$2" snet="$3" prefix="$4"
  if exists az network vnet show -g "$RG" -n "$vnet"; then
    info "$vnet already exists"
  else
    az network vnet create -g "$RG" -n "$vnet" --location "$LOCATION" \
      --address-prefixes "$space" --output none
    info "Created $vnet ($space)"
  fi
  if exists az network vnet subnet show -g "$RG" --vnet-name "$vnet" -n "$snet"; then
    info "$vnet/$snet already exists"
  else
    az network vnet subnet create -g "$RG" --vnet-name "$vnet" -n "$snet" \
      --address-prefixes "$prefix" --default-outbound-access false --output none
    info "Created private subnet $vnet/$snet ($prefix)"
  fi
}
create_vnet vnet-nusa-hub    10.30.0.0/16 snet-nva      10.30.1.0/24
create_vnet vnet-nusa-spoke1 10.31.0.0/16 snet-workload 10.31.1.0/24
create_vnet vnet-nusa-spoke2 10.32.0.0/16 snet-workload 10.32.1.0/24

banner "Virtual machines (3 x $VM_SIZE_SMALL, no public IPs) — 2 to 3 minutes each"
# create_vm <vm> <vnet> <subnet> <private ip> [cloud-init file]
create_vm() {
  local vm="$1" vnet="$2" snet="$3" ip="$4" init="${5:-}"
  if exists az vm show -g "$RG" -n "$vm"; then
    info "$vm already exists"
    return 0
  fi
  local extra=()
  if [[ -n "$init" ]]; then
    extra=(--custom-data "$init")
  fi
  info "Creating $vm ($ip)..."
  az vm create -g "$RG" -n "$vm" --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --vnet-name "$vnet" --subnet "$snet" --private-ip-address "$ip" \
    --public-ip-address "" --nsg "" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    ${extra[@]+"${extra[@]}"} --output none
}
create_vm vm-hub-nva vnet-nusa-hub    snet-nva      10.30.1.4
create_vm vm-spoke1  vnet-nusa-spoke1 snet-workload 10.31.1.4 "$AZL_COMMON_DIR/cloud-init-web.yml"
create_vm vm-spoke2  vnet-nusa-spoke2 snet-workload 10.32.1.4 "$AZL_COMMON_DIR/cloud-init-web.yml"

banner "Network Watcher"
nw_count="$(az_q network watcher list --query "[?location=='${LOCATION}'] | length(@)")"
if [[ "${nw_count:-0}" =~ ^[0-9]+$ ]] && (( nw_count >= 1 )); then
  info "Network Watcher is enabled in $LOCATION (you need it for next hop in Tasks 3 and 5)."
else
  note "Network Watcher is not enabled in $LOCATION. Enable it with:"
  info "az network watcher configure -g NetworkWatcherRG -l $LOCATION --enabled true"
fi

banner "Starting point ready"
az vm list -g "$RG" -d --query "[].{VM:name, PrivateIP:privateIps, PublicIP:publicIps, State:powerState}" -o table
info "Three networks, three VMs, no peerings and no route tables yet. Continue with Task 1 in README.md."
