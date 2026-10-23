#!/usr/bin/env bash
# =============================================================================
# Lab 31 · verify — checks the Challenge brief and prints PASS/FAIL per item.
#   bash verify.sh
# Read-only: it creates and changes nothing. Works for Path A and Path B.
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az
source "${LAB_DIR}/lab-vars.sh"

banner "Lab 31 · Governance for the whole company — verify"

banner "Management group hierarchy (Task 2)"
if az account management-group show --name "$MG_ROOT" --output none 2>/dev/null; then
  pass "Intermediate root ${MG_ROOT} exists (parent: $(mg_parent "$MG_ROOT"))"
else
  fail "Intermediate root ${MG_ROOT} exists"
fi
check_eq "${MG_PLATFORM} sits under ${MG_ROOT}" "$MG_ROOT" "$(mg_parent "$MG_PLATFORM")"
check_eq "${MG_LZ} sits under ${MG_ROOT}" "$MG_ROOT" "$(mg_parent "$MG_LZ")"
check_eq "${MG_CORP} sits under ${MG_LZ}" "$MG_LZ" "$(mg_parent "$MG_CORP")"

moved_to=""
for mg in "$MG_CORP" "$MG_LZ" "$MG_PLATFORM" "$MG_ROOT"; do
  if sub_in_mg "$mg"; then
    moved_to="$mg"
    break
  fi
done
if [[ -n "$moved_to" ]]; then
  note "Your subscription sits in ${moved_to} (Path B). cleanup.sh moves it back."
else
  info "Your subscription is outside the lab hierarchy (Path A)."
fi

banner "Initiative (Task 4)"
info "Looking up the built-in definitions by display name (a few seconds)..."
lookup_builtin_ids

# Custom initiatives in the subscription and in the lab management groups: id <TAB> name <TAB> member definition ids
initiatives="$(
  {
    az_q policy set-definition list --query "[?policyType=='Custom'].[id, name, join(' ', policyDefinitions[].policyDefinitionId)]"
    for mg in "$MG_ROOT" "$MG_LZ" "$MG_CORP"; do
      az_q policy set-definition list --management-group "$mg" \
        --query "[?policyType=='Custom'].[id, name, join(' ', policyDefinitions[].policyDefinitionId)]"
    done
  } | sort -u
)"

init_id=""
init_name=""
init_count=0
while IFS=$'\t' read -r id name members; do
  [[ -z "$id" ]] && continue
  members_lc=" ${members,,} "
  if [[ -n "$ALLOWED_LOCATIONS_ID" && "$members_lc" == *" ${ALLOWED_LOCATIONS_ID,,} "* &&
        -n "$REQUIRE_TAG_ID" && "$members_lc" == *" ${REQUIRE_TAG_ID,,} "* &&
        -n "$INHERIT_TAG_ID" && "$members_lc" == *" ${INHERIT_TAG_ID,,} "* ]]; then
    init_id="$id"
    init_name="$name"
    init_count="$(wc -w <<< "$members" | tr -d ' ')"
    if [[ "$name" == "$INITIATIVE" ]]; then
      break
    fi
  fi
done <<< "$initiatives"

check_nonempty "A custom initiative contains Allowed locations, Require a tag and Inherit a tag" "$init_name"
if [[ -n "$init_id" ]]; then
  check_ge "Initiative ${init_name} holds at least 3 policies" 3 "$init_count"
  if [[ "${init_id,,}" == /providers/microsoft.management/* ]]; then
    info "Saved at management-group scope: ${init_id%%/providers/Microsoft.Authorization*}"
  else
    info "Saved at subscription scope: ${init_id%%/providers/Microsoft.Authorization*}"
  fi
fi

banner "Assignment (Task 5)"
a_name=""
a_scope=""
if [[ -n "$init_id" ]]; then
  for scope in "$SUB_SCOPE" "${MG_PREFIX}/${MG_ROOT}" "${MG_PREFIX}/${MG_LZ}" "${MG_PREFIX}/${MG_CORP}"; do
    while IFS=$'\t' read -r name def s; do
      if [[ -n "$name" && "${def,,}" == "${init_id,,}" && "${s,,}" == "${scope,,}" ]]; then
        a_name="$name"
        a_scope="$s"
        break 2
      fi
    done < <(az_q policy assignment list --scope "$scope" --query "[].[name, policyDefinitionId, scope]")
  done
fi
check_nonempty "The initiative is assigned to your subscription or to a lab management group" "$a_name"
a_id=""
pid=""
if [[ -n "$a_name" ]]; then
  info "Assignment ${a_name} at ${a_scope}"
  a_id="$(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query id)"
  locs="$(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query "join(',', parameters.allowedLocations.value)")"
  if [[ ",${locs,,}," == *",${LOCATION,,},"* ]]; then
    pass "Allowed locations include ${LOCATION} (${locs})"
  else
    fail "Allowed locations include ${LOCATION} (found '${locs:-<none>}')"
  fi
  if [[ ",${locs,,}," == *",${SECONDARY_LOCATION,,},"* ]]; then
    fail "${SECONDARY_LOCATION} is NOT on the allowed list (the sandbox needs an exemption instead)"
  fi
  check_eq "The tag parameter is costCenter" "costCenter" \
    "$(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query "parameters.tagName.value || 'costCenter'")"
  id_type="$(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query identity.type)"
  check_nonempty "The assignment has a managed identity (needed for Modify)" "$id_type"
  pid="$(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query identity.principalId)"
  roles=0
  if [[ -n "$pid" ]]; then
    roles="$(az_q role assignment list --scope "$CORP_RG_ID" --include-inherited --query "length([?principalId=='${pid}'])")"
  fi
  check_ge "The managed identity holds a role on ${CORP_RG}" 1 "${roles:-0}"
  info "Enforcement mode: $(az_q policy assignment show --name "$a_name" --scope "$a_scope" --query enforcementMode)"
fi

banner "Remediation (Task 6)"
check_ge "A remediation task in ${CORP_RG} has succeeded" 1 \
  "$(az_q policy remediation list --resource-group "$CORP_RG" --query "length([?provisioningState=='Succeeded'])")"
check_eq "Legacy storage account ${LEGACY_SA} inherited costCenter=${COST_CENTER}" "$COST_CENTER" \
  "$(az_q storage account show --name "$LEGACY_SA" --resource-group "$CORP_RG" --query tags.costCenter)"
check_eq "Legacy network security group ${LEGACY_NSG} inherited costCenter=${COST_CENTER}" "$COST_CENTER" \
  "$(az_q network nsg show --name "$LEGACY_NSG" --resource-group "$CORP_RG" --query tags.costCenter)"

banner "Exemption (Task 7)"
w_name=""
w_expires=""
while IFS=$'\t' read -r name assignment expires; do
  if [[ -n "$name" && -n "$a_id" && "${assignment,,}" == "${a_id,,}" ]]; then
    w_name="$name"
    w_expires="$expires"
    break
  fi
done < <(az_q policy exemption list --resource-group "$SANDBOX_RG" \
  --query "[?exemptionCategory=='Waiver'].[name, policyAssignmentId, expiresOn]")
check_nonempty "A Waiver exemption on ${SANDBOX_RG} points to the initiative assignment" "$w_name"
if [[ -n "$w_name" ]]; then
  if [[ -n "$w_expires" && "$w_expires" != "None" ]] && (( $(date -d "$w_expires" +%s 2>/dev/null || echo 0) > $(date +%s) )); then
    pass "The exemption expires in the future (${w_expires})"
  else
    fail "The exemption has a future expiry date (found '${w_expires:-<none>}')"
  fi
fi

banner "Compliance data (Task 8)"
if [[ -n "$a_name" ]]; then
  corp_states="$(az_q policy state list --resource-group "$CORP_RG" --filter "policyAssignmentName eq '${a_name}'" --query "length(@)")"
  check_ge "Compliance records exist for ${a_name} in ${CORP_RG}" 1 "${corp_states:-0}"
  info "Sandbox states: $(az_q policy state list --resource-group "$SANDBOX_RG" \
    --filter "policyAssignmentName eq '${a_name}'" --query "join(', ', [].complianceState)")"
fi

banner "Policy as code (Task 9)"
exports="$(find "${LAB_DIR}/exported" -type f -name 'assign.*.json' 2>/dev/null | head -n 1)"
check_nonempty "The assignment was exported to exported/…/assign.<name>.json" "$exports"

summary
