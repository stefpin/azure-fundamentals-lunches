#!/usr/bin/env bash
# =============================================================================
# Lab 18 · verify — checks the Challenge brief and prints PASS/FAIL per item.
#   bash verify.sh
# Read-only: it creates and changes nothing.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
source "$(dirname "$0")/lab-vars.sh"

banner "Lab 18 · Keep data in the right place — verify (${RG})"

if ! az group show --name "$RG" --output none 2>/dev/null; then
  fail "Resource group ${RG} exists (run 'bash setup.sh' first)"
  summary
  exit 1
fi
pass "Resource group ${RG} exists"

info "Looking up the built-in definitions by display name (a few seconds)..."
lookup_builtin_ids

# All assignments created directly at the resource-group scope: name <TAB> definition id <TAB> scope
assignments="$(az_q policy assignment list --resource-group "$RG" --query "[].[name, policyDefinitionId, scope]")"

# find_assignment <definition id> -> prints the name of the RG-scope assignment that uses it
find_assignment() {
  local want="${1,,}" name def scope
  [[ -z "$want" ]] && return 0
  while IFS=$'\t' read -r name def scope; do
    if [[ -n "$name" && "${def,,}" == "$want" && "${scope,,}" == "${RG_ID,,}" ]]; then
      echo "$name"
      return 0
    fi
  done <<< "$assignments"
}

loc_name="$(find_assignment "$ALLOWED_LOCATIONS_ID")"
req_name="$(find_assignment "$REQUIRE_TAG_ID")"
inh_name="$(find_assignment "$INHERIT_TAG_ID")"

banner "Policy assignments at resource-group scope"
check_nonempty "'Allowed locations' is assigned to the resource group (Task 2)" "$loc_name"
if [[ -n "$loc_name" ]]; then
  locs="$(az_q policy assignment show --name "$loc_name" --scope "$RG_ID" \
    --query "join(',', parameters.listOfAllowedLocations.value)")"
  if [[ ",${locs,,}," == *",${LOCATION,,},"* ]]; then
    pass "Allowed locations include ${LOCATION} (${locs})"
  else
    fail "Allowed locations include ${LOCATION} (found '${locs:-<none>}') — Task 2"
  fi
  if [[ ",${locs,,}," == *",${DENIED_LOCATION,,},"* ]]; then
    fail "${DENIED_LOCATION} is NOT on the allowed list — Task 2"
  fi
fi

check_nonempty "'Require a tag on resources' is assigned to the resource group (Task 3)" "$req_name"
if [[ -n "$req_name" ]]; then
  check_eq "Required tag name is costCenter" "costCenter" \
    "$(az_q policy assignment show --name "$req_name" --scope "$RG_ID" --query parameters.tagName.value)"
fi

check_nonempty "'Inherit a tag from the resource group if missing' is assigned to the resource group (Task 4)" "$inh_name"
if [[ -n "$inh_name" ]]; then
  check_eq "Inherited tag name is costCenter" "costCenter" \
    "$(az_q policy assignment show --name "$inh_name" --scope "$RG_ID" --query parameters.tagName.value)"
  id_type="$(az_q policy assignment show --name "$inh_name" --scope "$RG_ID" --query identity.type)"
  check_contains "The inherit assignment has a system-assigned managed identity" "SystemAssigned" "$id_type"
  pid="$(az_q policy assignment show --name "$inh_name" --scope "$RG_ID" --query identity.principalId)"
  roles=0
  if [[ -n "$pid" ]]; then
    roles="$(az_q role assignment list --scope "$RG_ID" --include-inherited --query "length([?principalId=='${pid}'])")"
  fi
  check_ge "The managed identity holds a role on the resource group (Task 4)" 1 "${roles:-0}"
fi

banner "Tags and remediation"
rg_tag="$(az_q group show --name "$RG" --query "tags.costCenter || tags.CostCenter || tags.costcenter")"
check_nonempty "The resource group carries a costCenter tag (Task 6)" "$rg_tag"
sa_tag="$(az_q storage account show --name "$LEGACY_SA" --resource-group "$RG" \
  --query "tags.costCenter || tags.CostCenter || tags.costcenter")"
check_nonempty "Legacy storage account ${LEGACY_SA} now has costCenter (Task 7)" "$sa_tag"
nsg_tag="$(az_q network nsg show --name "$LEGACY_NSG" --resource-group "$RG" \
  --query "tags.costCenter || tags.CostCenter || tags.costcenter")"
check_nonempty "Legacy network security group ${LEGACY_NSG} now has costCenter (Task 7)" "$nsg_tag"
check_ge "A remediation task in ${RG} has succeeded (Task 7)" 1 \
  "$(az_q policy remediation list --resource-group "$RG" --query "length([?provisioningState=='Succeeded'])")"
check_ge "A compliant storage account (tagged, in ${LOCATION}) exists besides ${LEGACY_SA} (Task 6)" 1 \
  "$(az_q storage account list --resource-group "$RG" \
    --query "length([?name!='${LEGACY_SA}' && location=='${LOCATION,,}' && (tags.costCenter || tags.CostCenter || tags.costcenter)])")"

banner "Compliance data"
for name in "$loc_name" "$req_name" "$inh_name"; do
  [[ -z "$name" ]] && continue
  states="$(az_q policy state list --resource-group "$RG" --filter "policyAssignmentName eq '${name}'" --query "length(@)")"
  if [[ "${states:-0}" =~ ^[0-9]+$ ]] && (( states >= 1 )); then
    pass "Compliance results exist for ${name} (${states} records)"
  else
    fail "Compliance results exist for ${name} — run 'az policy state trigger-scan --resource-group ${RG}' and try again in a few minutes (Task 8)"
  fi
done

non_compliant="$(az_q policy state list --resource-group "$RG" --filter "complianceState eq 'NonCompliant'" --query "length(@)")"
info "Non-compliant policy states in ${RG} right now: ${non_compliant:-unknown}"
outside="$(az_q resource list --resource-group "$RG" --query "length([?location!='${LOCATION,,}'])")"
if [[ "${outside:-0}" =~ ^[0-9]+$ ]] && (( outside > 0 )); then
  note "${outside} resource(s) in ${RG} are outside ${LOCATION} — probably created before the policy was enforced. cleanup.sh removes them."
fi

summary
