#!/usr/bin/env bash
# =============================================================================
# Lab 03 · Verify: checks the Challenge brief and prints PASS/FAIL per check.
#   bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 03)"
ST_LRS="stnusalrs${SUFFIX}"
ST_ZRS="stnusazrs${SUFFIX}"

banner "Region (Task 2)"
zone_count="$(az_q account list-locations --query "length([?name=='${LOCATION}'].availabilityZoneMappings[])")"
check_ge "LOCATION=${LOCATION} offers availability zones to this subscription" 3 "$zone_count"
pair="$(az_q account list-locations --query "[?name=='${LOCATION}'].metadata.pairedRegion[0].name | [0]")"
info "Paired region of ${LOCATION}: ${pair:-none}"

banner "Resource group (Task 3)"
check "Resource group ${RG} exists" az group show --name "$RG"
check_eq "Resource group is tagged lunch=03 (cleanup.sh relies on it)" "03" \
  "$(az_q group show --name "$RG" --query tags.lunch)"

banner "Standard public IPs (Task 3)"
# ip_zones <name>  -> the zones of a public IP, sorted and space-separated ("" if none)
ip_zones() {
  az_q network public-ip show --resource-group "$RG" --name "$1" --query "join(' ', sort(zones || \`[]\`))"
}
for ip in pip-nusa-zonal pip-nusa-zr; do
  check_eq "${ip} uses the Standard SKU" "Standard" \
    "$(az_q network public-ip show --resource-group "$RG" --name "$ip" --query sku.name)"
  check_eq "${ip} has a static address" "Static" \
    "$(az_q network public-ip show --resource-group "$RG" --name "$ip" --query publicIPAllocationMethod)"
done
check_eq "pip-nusa-zonal is zonal: pinned to zone 1 only" "1" "$(ip_zones pip-nusa-zonal)"
check_eq "pip-nusa-zr is zone-redundant: zones 1, 2 and 3" "1 2 3" "$(ip_zones pip-nusa-zr)"
if az network public-ip show --resource-group "$RG" --name pip-nusa-nozone --output none 2>/dev/null; then
  nozone="$(ip_zones pip-nusa-nozone)"
  info "pip-nusa-nozone lists zones '${nozone:-none}'. In a zone-enabled region it is zone-redundant either way."
fi

banner "Storage accounts (Task 4)"
check_eq "${ST_LRS} is locally redundant (Standard_LRS)" "Standard_LRS" \
  "$(az_q storage account show --resource-group "$RG" --name "$ST_LRS" --query sku.name)"
check_eq "${ST_ZRS} is zone-redundant (Standard_ZRS)" "Standard_ZRS" \
  "$(az_q storage account show --resource-group "$RG" --name "$ST_ZRS" --query sku.name)"
for st in "$ST_LRS" "$ST_ZRS"; do
  check_eq "${st} is a StorageV2 account" "StorageV2" \
    "$(az_q storage account show --resource-group "$RG" --name "$st" --query kind)"
  check_eq "${st} requires TLS 1.2 as the minimum" "TLS1_2" \
    "$(az_q storage account show --resource-group "$RG" --name "$st" --query minimumTlsVersion)"
  check_eq "${st} has anonymous blob access disabled" "false" \
    "$(az_q storage account show --resource-group "$RG" --name "$st" --query allowBlobPublicAccess)"
done

summary
