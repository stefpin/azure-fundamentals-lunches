#!/usr/bin/env bash
# =============================================================================
# Lab 23 · Setup — creates the starting point for the scale set (about 3 minutes):
#   1. pre-flight checks: is VM_SIZE_SMALL offered in all three zones, and is
#      there enough vCPU quota for the autoscale maximum?
#   2. resource group rg-lunch23-<suffix>
#   3. NAT gateway ng-nusa-web (explicit outbound access for the instances)
#   4. virtual network vnet-nusa-web with subnet snet-web (private, uses the NAT gateway)
#   5. network security group nsg-web (allows HTTP 80 from the internet; the scale
#      set puts it on each instance's network interface)
#   6. Standard load balancer lb-nusa-web: zone-redundant public IP, backend pool
#      bep-web, HTTP probe on /health, rule for port 80 without outbound SNAT
#
#   bash setup.sh
# Safe to re-run: existing resources are kept (and the NAT gateway is re-attached).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 23)"
AS_MAX="${AS_MAX:-3}"
VNET="vnet-nusa-web"
SUBNET="snet-web"
NSG="nsg-web"
NATGW="ng-nusa-web"
NAT_PIP="pip-ng-web"
LB="lb-nusa-web"
LB_PIP="pip-lb-web"

exists() { az "$@" --output none >/dev/null 2>&1; }

# --- 1. Pre-flight checks ---------------------------------------------------------
banner "Pre-flight: ${VM_SIZE_SMALL} in ${LOCATION}"
info "Reading VM size information (this can take ~30 seconds)..."
problems=0
sku_line="$(az_q vm list-skus --location "$LOCATION" --size "$VM_SIZE_SMALL" --resource-type virtualMachines \
  --query "[?name=='${VM_SIZE_SMALL}'] | [0].[family, capabilities[?name=='vCPUs'].value | [0], join(',', sort(locationInfo[0].zones || \`[]\`)) || 'none', length(restrictions[?type=='Location'] || \`[]\`), join(',', restrictions[?type=='Zone'].restrictionInfo.zones[] || \`[]\`) || 'none']")"

if [[ -z "$sku_line" ]]; then
  fail "${VM_SIZE_SMALL} is not offered in ${LOCATION}"
  problems=1
else
  read -r family vcpus zones loc_restricted zone_restricted <<<"$sku_line"
  if [[ "$loc_restricted" != "0" ]]; then
    fail "${VM_SIZE_SMALL} is restricted for your subscription in ${LOCATION}"
    problems=1
  elif [[ ",${zones}," == *",1,"* && ",${zones}," == *",2,"* && ",${zones}," == *",3,"* && "$zone_restricted" == "none" ]]; then
    pass "${VM_SIZE_SMALL} (${vcpus} vCPU) is available in zones 1, 2 and 3"
  else
    fail "${VM_SIZE_SMALL} is not available in all three zones (offered: ${zones}; restricted for you: ${zone_restricted})"
    problems=1
  fi

  need=$(( ${vcpus:-1} * AS_MAX ))
  while read -r qname used limit; do
    [[ -z "${qname:-}" ]] && continue
    free=$(( ${limit%.*} - ${used%.*} ))
    if (( free >= need )); then
      pass "Quota ${qname}: ${free} of ${limit%.*} vCPUs free; the scale set needs up to ${need}"
    else
      fail "Quota ${qname}: ${free} of ${limit%.*} vCPUs free; the scale set needs up to ${need}"
      problems=1
    fi
  done < <(az_q vm list-usage --location "$LOCATION" \
    --query "[?name.value=='cores' || name.value=='${family}'].[name.value, currentValue, limit]")
fi

if [[ "$VM_SIZE_SMALL" =~ ^Standard_B[0-9]+(l|m)?s$ ]]; then
  note "${VM_SIZE_SMALL} is a B-series v1 size. New subscriptions can't deploy B-series v1 any more,"
  info "        so Task 2 may fail with SkuNotAvailable even when the check above passes."
  info "        Use the lab default instead: export VM_SIZE_SMALL=Standard_B2ats_v2"
fi
if (( problems > 0 )); then
  note "Small-quota settings that stay within 4 vCPUs — run this, then run 'bash setup.sh' again to re-check:"
  info "        export VM_SIZE_SMALL=Standard_B2ats_v2 INSTANCES=1 AS_MIN=1 AS_MAX=2"
  info "        (or pick another small size: az vm list-skus -l ${LOCATION} --size Standard_B --zone -o table)"
  info "        Setup continues: the network and load balancer don't depend on the VM size."
fi

# --- 2. Resource group -------------------------------------------------------------
banner "Resource group ${RG}"
ensure_rg "$RG" 23
info "Tagged course=${COURSE_TAG} lunch=23"

# --- 3. NAT gateway ----------------------------------------------------------------
banner "NAT gateway ${NATGW} (explicit outbound access)"
exists network public-ip show -g "$RG" -n "$NAT_PIP" ||
  az network public-ip create -g "$RG" -n "$NAT_PIP" --location "$LOCATION" --sku Standard --output none
exists network nat gateway show -g "$RG" -n "$NATGW" ||
  az network nat gateway create -g "$RG" -n "$NATGW" --location "$LOCATION" \
    --public-ip-addresses "$NAT_PIP" --idle-timeout 4 --output none
info "NAT gateway ready."

# --- 4. Virtual network and subnet ---------------------------------------------------
banner "Virtual network ${VNET} and subnet ${SUBNET}"
exists network vnet show -g "$RG" -n "$VNET" ||
  az network vnet create -g "$RG" -n "$VNET" --location "$LOCATION" \
    --address-prefixes 10.20.0.0/16 --subnet-name "$SUBNET" --subnet-prefixes 10.20.1.0/24 --output none
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n "$SUBNET" --nat-gateway "$NATGW" --output none
if ! az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n "$SUBNET" --default-outbound false \
     --output none 2>/dev/null; then
  note "Your Azure CLI can't set --default-outbound. That's fine: Flexible scale sets get no default outbound access."
fi
info "Subnet ${SUBNET} (10.20.1.0/24) is private and sends outbound traffic through ${NATGW}."

# --- 5. Network security group -------------------------------------------------------
banner "Network security group ${NSG}"
exists network nsg show -g "$RG" -n "$NSG" ||
  az network nsg create -g "$RG" -n "$NSG" --location "$LOCATION" --output none
exists network nsg rule show -g "$RG" --nsg-name "$NSG" -n allow-http-internet ||
  az network nsg rule create -g "$RG" --nsg-name "$NSG" -n allow-http-internet --priority 100 \
    --direction Inbound --access Allow --protocol Tcp \
    --source-address-prefixes Internet --source-port-ranges '*' \
    --destination-address-prefixes '*' --destination-port-ranges 80 --output none
info "Rule allow-http-internet: TCP 80 from Internet (load balancer probes are allowed by a default rule)."

# --- 6. Standard load balancer ---------------------------------------------------------
banner "Standard load balancer ${LB}"
exists network public-ip show -g "$RG" -n "$LB_PIP" ||
  az network public-ip create -g "$RG" -n "$LB_PIP" --location "$LOCATION" --sku Standard \
    --zone 1 2 3 --output none
exists network lb show -g "$RG" -n "$LB" ||
  az network lb create -g "$RG" -n "$LB" --location "$LOCATION" --sku Standard \
    --public-ip-address "$LB_PIP" --frontend-ip-name fe-web --backend-pool-name bep-web --output none
exists network lb probe show -g "$RG" --lb-name "$LB" -n probe-health ||
  az network lb probe create -g "$RG" --lb-name "$LB" -n probe-health \
    --protocol Http --port 80 --path /health --output none
exists network lb rule show -g "$RG" --lb-name "$LB" -n rule-http ||
  az network lb rule create -g "$RG" --lb-name "$LB" -n rule-http --protocol Tcp \
    --frontend-port 80 --backend-port 80 --frontend-ip-name fe-web --backend-pool-name bep-web \
    --probe-name probe-health --disable-outbound-snat true --output none
info "Frontend fe-web (zone-redundant), pool bep-web, probe /health, rule for port 80 without outbound SNAT."

LB_IP="$(az_q network public-ip show -g "$RG" -n "$LB_PIP" --query ipAddress)"
banner "Starting point ready"
info "Load balancer: http://${LB_IP}/  (no instances yet — Task 2 creates the scale set)"
az resource list -g "$RG" --query "[].{type:type, name:name}" --output table
