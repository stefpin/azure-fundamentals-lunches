#!/usr/bin/env bash
# =============================================================================
# Checks that your environment is ready for the labs.
#   bash labs/common/check-environment.sh
# Safe to run any time: it only reads information, it creates nothing.
# =============================================================================
set -uo pipefail
AZL_QUIET=1 source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

banner "Azure CLI"
require_az
info "$(az version --query '"azure-cli"' --output tsv 2>/dev/null | sed 's/^/Azure CLI version: /')"

banner "Signed-in account and subscription"
az account show --query "{subscription:name, subscriptionId:id, tenant:tenantId, user:user.name}" --output table
state="$(az_q account show --query state)"
check_eq "Subscription is enabled" "Enabled" "$state"

banner "Lab settings"
info "LOCATION=${LOCATION}  SECONDARY_LOCATION=${SECONDARY_LOCATION}  SUFFIX=${SUFFIX}"
info "VM_SIZE=${VM_SIZE}  VM_SIZE_SMALL=${VM_SIZE_SMALL}  VM_IMAGE=${VM_IMAGE}"

banner "Region checks"
loc="$(az_q account list-locations --query "[?name=='${LOCATION}'].displayName | [0]")"
check_nonempty "Region '${LOCATION}' exists for your subscription" "$loc"
pair="$(az_q account list-locations --query "[?name=='${LOCATION}'].metadata.pairedRegion[0].name | [0]")"
if [[ -n "$pair" ]]; then info "Paired region of ${LOCATION}: ${pair}"; else info "${LOCATION} has no paired region listed."; fi

info "Checking VM sizes (this can take ~30 seconds)..."
for size in "$VM_SIZE" "$VM_SIZE_SMALL"; do
  avail="$(az_q vm list-skus --location "$LOCATION" --size "$size" --resource-type virtualMachines \
    --query "[?name=='${size}' && length(restrictions)==\`0\`].name | [0]")"
  if [[ -n "$avail" ]]; then
    zones="$(az_q vm list-skus --location "$LOCATION" --size "$size" --resource-type virtualMachines \
      --query "[?name=='${size}'].locationInfo[0].zones | [0] | join(',', @)")"
    pass "VM size ${size} is available in ${LOCATION} (zones: ${zones:-none})"
  else
    fail "VM size ${size} is not available to you in ${LOCATION} — set VM_SIZE / VM_SIZE_SMALL to another small size"
  fi
done

banner "Regional vCPU quota"
usage="$(az vm list-usage --location "$LOCATION" --query "[].[localName, currentValue, limit]" --output tsv 2>/dev/null || true)"
if [[ -n "$usage" ]]; then
  printf '   %-40s %6s %6s\n' "Quota" "Used" "Limit"
  grep -i -E "^Total Regional vCPUs|BASv2|BSv2|BPSv2|DSv5" <<<"$usage" | while IFS=$'\t' read -r name used limit; do
    printf '   %-40s %6s %6s\n' "$name" "$used" "$limit"
  done
  regional_limit="$(grep -i "^Total Regional vCPUs" <<<"$usage" | cut -f3 | head -n1)"
  if [[ "${regional_limit:-0}" =~ ^[0-9]+$ ]] && (( regional_limit < 6 )); then
    note "Your regional vCPU limit is ${regional_limit}. Most labs need 2–4 vCPUs; Lab 25 needs 6."
    note "Request more in the portal: Subscriptions › Usage + quotas (free trials may need an upgrade first)."
  fi
else
  note "Could not read quota information."
fi
info "Most labs need 4 vCPUs or fewer (each lab VM has 2 vCPUs). Free and trial subscriptions often have small quotas."

banner "Existing lab resource groups"
rgs="$(az_q group list --query "[?tags.course=='${COURSE_TAG}'].name")"
if [[ -n "$rgs" ]]; then
  note "These lab resource groups still exist (they may be costing money):"
  echo "$rgs" | sed 's/^/     - /'
else
  info "None. Your subscription is clean."
fi

summary
