#!/usr/bin/env bash
# =============================================================================
# Lab 02 · Make the business case — optional, read-only exploration
#   bash explore.sh
# Lists Azure regions (with their paired regions) and a few resource providers.
# It only reads information: it creates nothing and changes nothing.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Your subscription"
az account show --query "{subscription:name, state:state, user:user.name}" --output table

banner "Regions you can deploy to"
total="$(az_q account list-locations --query "[?metadata.regionType=='Physical'] | length(@)")"
info "Physical regions available to your subscription: ${total:-unknown}"
info "Regions in the Asia Pacific geography group (an empty Pair column means no paired region):"
asia="$(az account list-locations \
  --query "[?metadata.regionType=='Physical' && metadata.geographyGroup=='Asia Pacific'].{Region:name, Name:displayName, Location:metadata.physicalLocation, Pair:metadata.pairedRegion[0].name}" \
  --output table 2>/dev/null)"
if [[ -n "$asia" ]]; then
  echo "$asia"
else
  note "No regions matched the Asia Pacific filter; showing every physical region instead."
  az account list-locations \
    --query "[?metadata.regionType=='Physical'].{Region:name, Name:displayName, Pair:metadata.pairedRegion[0].name}" \
    --output table 2>/dev/null || note "Could not list regions."
fi

echo
for region in indonesiacentral southeastasia; do
  name="$(az_q account list-locations --query "[?name=='${region}'].displayName | [0]")"
  if [[ -z "$name" ]]; then
    info "${region}: not offered to your subscription"
    continue
  fi
  pair="$(az_q account list-locations --query "[?name=='${region}'].metadata.pairedRegion[0].name | [0]")"
  info "${region} (${name}): paired region = ${pair:-none}"
done
info "Lunch 03 explains why a region without a pair changes your disaster-recovery planning."

banner "Resource providers"
registered="$(az_q provider list --query "[?registrationState=='Registered'] | length(@)")"
all="$(az_q provider list --query "length(@)")"
info "Registered in this subscription: ${registered:-?} of ${all:-?} provider namespaces."
info "NotRegistered is normal: many providers are registered the first time you need them."
echo
printf '   %-24s %-14s %s\n' "Namespace" "State" "What it provides"
while IFS='|' read -r namespace what; do
  state="$(az_q provider show --namespace "$namespace" --query registrationState)"
  printf '   %-24s %-14s %s\n' "$namespace" "${state:-unknown}" "$what"
done <<'EOF'
Microsoft.Compute|IaaS: virtual machines and disks
Microsoft.Network|IaaS: virtual networks and load balancers
Microsoft.Storage|storage accounts (a platform service)
Microsoft.Web|PaaS: App Service and Azure Functions
Microsoft.Sql|PaaS: Azure SQL Database
Microsoft.Logic|serverless workflows: Azure Logic Apps
EOF

banner "Some resource types offered by Microsoft.Web (PaaS)"
az provider show --namespace Microsoft.Web --query "resourceTypes[0:12].resourceType" --output tsv 2>/dev/null \
  | sed 's/^/   - /' || note "Could not read Microsoft.Web."
info "Every one of these is created through Azure Resource Manager, the front door from Lunch 01."

echo
info "Nothing was created or changed, so there is nothing to clean up."
