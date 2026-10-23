#!/usr/bin/env bash
# =============================================================================
# Lab 03 · Reference solution: explore regions and zones.
# Runs Tasks 1-4 of the guide without prompts. Safe to run more than once.
#   bash solution.sh
# Task 5 (latency test in your browser) can't be scripted.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 03)"
ST_LRS="stnusalrs${SUFFIX}"
ST_ZRS="stnusazrs${SUFFIX}"

banner "Task 1 · Regions, geographies and pairs"
physical="$(az account list-locations --query "length([?metadata.regionType=='Physical'])" --output tsv)"
info "Physical regions visible to this subscription: ${physical}"
az account list-locations \
  --query "[?contains(['indonesiacentral','southeastasia','eastasia','malaysiawest'], name)].{region:name, geography:metadata.geography, city:metadata.physicalLocation, pair:metadata.pairedRegion[0].name}" \
  --output table
info "Physical regions without a paired region:"
az account list-locations \
  --query "[?metadata.regionType=='Physical' && !metadata.pairedRegion].displayName" \
  --output tsv | sort | sed 's/^/     - /'

banner "Task 2 · Zones, zone mapping and service availability in ${LOCATION}"
zone_count="$(az account list-locations --query "length([?name=='${LOCATION}'].availabilityZoneMappings[])" --output tsv)"
if [[ "${zone_count:-0}" -lt 3 ]]; then
  echo "LOCATION=${LOCATION} offers no availability zones to this subscription."
  echo "Choose a zone-enabled region, for example:  export LOCATION=southeastasia; source ../common/config.sh"
  exit 1
fi
az account list-locations --query "[?name=='${LOCATION}'].availabilityZoneMappings | [0]" --output table
info "Zone support for ${VM_SIZE} (this can take a minute)..."
az vm list-skus --location "$LOCATION" --resource-type virtualMachines --size "$VM_SIZE" --zone --output table || true
for rt in Microsoft.Network/natGateways Microsoft.App/managedEnvironments; do
  ns="${rt%%/*}"; type="${rt#*/}"
  info "Regions near Jakarta that offer ${rt}:"
  az provider show --namespace "$ns" \
    --query "resourceTypes[?resourceType=='${type}'].locations | [0]" --output tsv \
    | grep -i -E "indonesia|southeast asia|east asia" | sed 's/^/     - /' || info "   (not listed in these regions)"
done

banner "Task 3 · Zonal, zone-redundant and 'no zone' Standard public IPs"
ensure_rg "$RG" 03

# create_ip <name> [zone...]  -> creates a Standard static IPv4 address unless it already exists
create_ip() {
  local name="$1"; shift
  if az network public-ip show --resource-group "$RG" --name "$name" --output none 2>/dev/null; then
    info "${name} already exists"
    return 0
  fi
  local zone_args=()
  if (( $# > 0 )); then zone_args=(--zone "$@"); fi
  az network public-ip create --resource-group "$RG" --name "$name" --location "$LOCATION" \
    --sku Standard --version IPv4 --allocation-method Static ${zone_args[@]+"${zone_args[@]}"} --output none
  info "Created ${name}"
}
create_ip pip-nusa-zonal 1
create_ip pip-nusa-zr 1 2 3
create_ip pip-nusa-nozone
az network public-ip list --resource-group "$RG" \
  --query "[].{name:name, sku:sku.name, allocation:publicIPAllocationMethod, zones:join(', ', zones || \`[]\`)}" \
  --output table

banner "Task 4 · LRS and ZRS storage accounts"
# create_storage <name> <sku>  -> creates a secure StorageV2 account unless it already exists
create_storage() {
  local name="$1" sku="$2"
  if az storage account show --resource-group "$RG" --name "$name" --output none 2>/dev/null; then
    info "${name} already exists"
    return 0
  fi
  az storage account create --name "$name" --resource-group "$RG" --location "$LOCATION" \
    --sku "$sku" --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
    --output none
  info "Created ${name} (${sku})"
}
create_storage "$ST_LRS" Standard_LRS
create_storage "$ST_ZRS" Standard_ZRS
az storage account list --resource-group "$RG" \
  --query "[].{name:name, sku:sku.name, primary:primaryLocation, secondary:secondaryLocation, status:statusOfPrimary}" \
  --output table

banner "Done"
info "Task 5 (latency test) happens in your browser: https://www.azurespeed.com/Azure/Latency"
info "Now run:  bash verify.sh    and afterwards:  bash cleanup.sh"
