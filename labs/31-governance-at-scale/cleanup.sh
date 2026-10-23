#!/usr/bin/env bash
# =============================================================================
# Lab 31 · cleanup — removes everything the lab created, in this order:
#   1. policy exemptions in the lab resource groups
#   2. policy assignments (lab resource groups, your subscription — only the lab's —
#      and the lab management groups), with the role assignments of their identities
#   3. the lab's initiative and policy definitions (subscription and management groups)
#   4. your subscription moves back to where it was (only if Task 3 moved it)
#   5. the management groups, children first
#   6. the resource groups, and the files the lab generated in this folder
#   bash cleanup.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az
source "${LAB_DIR}/lab-vars.sh"

banner "Lab 31 cleanup"

LAB_MGS=("$MG_CORP" "$MG_LZ" "$MG_PLATFORM" "$MG_ROOT")   # children first

# delete_assignment <name> <scope> -> removes the identity's role assignments, then the assignment
delete_assignment() {
  local name="$1" scope="$2" pid ra_id
  pid="$(az_q policy assignment show --name "$name" --scope "$scope" --query identity.principalId)"
  if [[ -n "$pid" && "$pid" != "None" ]]; then
    while IFS= read -r ra_id; do
      if [[ -n "$ra_id" ]]; then
        info "Removing a role assignment of ${name}'s managed identity..."
        az role assignment delete --ids "$ra_id" --output none || note "Could not remove role assignment ${ra_id}"
      fi
    done < <(az_q role assignment list --all --query "[?principalId=='${pid}'].id")
  fi
  info "Deleting policy assignment ${name} at ${scope}..."
  az policy assignment delete --name "$name" --scope "$scope" --output none || note "Could not delete ${name} at ${scope}"
}

banner "1 · Policy exemptions"
# Exemptions on the lab resource groups or on resources inside them (the stretch goal); inherited ones are left alone.
for rg in "$SANDBOX_RG" "$CORP_RG"; do
  if az group show --name "$rg" --output none 2>/dev/null; then
    rg_id="${SUB_SCOPE}/resourceGroups/${rg}"
    while IFS= read -r ex_id; do
      if [[ -n "$ex_id" && "${ex_id,,}" == "${rg_id,,}/"* ]]; then
        ex_lc="${ex_id,,}"
        ex_scope_lc="${ex_lc%/providers/microsoft.authorization/policyexemptions/*}"
        info "Deleting exemption ${ex_id##*/} in ${rg}..."
        az policy exemption delete --name "${ex_id##*/}" --scope "${ex_id:0:${#ex_scope_lc}}" \
          --output none || note "Could not delete ${ex_id}"
      fi
    done < <(az_q policy exemption list --resource-group "$rg" --disable-scope-strict-match true --query "[].id")
  fi
done

banner "2 · Policy assignments"
for rg in "$CORP_RG" "$SANDBOX_RG"; do
  if az group show --name "$rg" --output none 2>/dev/null; then
    rg_id="${SUB_SCOPE}/resourceGroups/${rg}"
    while IFS=$'\t' read -r name scope; do
      if [[ -n "$name" && "${scope,,}" == "${rg_id,,}" ]]; then
        delete_assignment "$name" "$rg_id"
      fi
    done < <(az_q policy assignment list --resource-group "$rg" --query "[].[name, scope]")
  fi
done
# At subscription scope, only the lab's assignments: named nusa-baseline / nusa-scope-test, or using the lab initiative
while IFS=$'\t' read -r name def scope; do
  if [[ -z "$name" || "${scope,,}" != "${SUB_SCOPE,,}" ]]; then
    continue
  fi
  if [[ "$name" == "$ASSIGNMENT" || "$name" == "$SCOPE_TEST" || "${def,,}" == *"/policysetdefinitions/${INITIATIVE}" ]]; then
    delete_assignment "$name" "$SUB_SCOPE"
  fi
done < <(az_q policy assignment list --scope "$SUB_SCOPE" --query "[].[name, policyDefinitionId, scope]")
# Every assignment directly on a lab management group
for mg in "${LAB_MGS[@]}"; do
  mg_id="${MG_PREFIX}/${mg}"
  while IFS=$'\t' read -r name scope; do
    if [[ -n "$name" && "${scope,,}" == "${mg_id,,}" ]]; then
      delete_assignment "$name" "$mg_id"
    fi
  done < <(az_q policy assignment list --scope "$mg_id" --query "[].[name, scope]")
done

banner "3 · Initiative and policy definitions"
if [[ "$(az_q policy set-definition show --name "$INITIATIVE" --query id)" == /subscriptions/* ]]; then
  info "Deleting initiative ${INITIATIVE} from your subscription..."
  az policy set-definition delete --name "$INITIATIVE" --output none || note "Could not delete ${INITIATIVE}"
fi
if [[ "$(az_q policy definition show --name "$SCOPE_TEST" --query id)" == /subscriptions/* ]]; then
  info "Deleting policy definition ${SCOPE_TEST} from your subscription..."
  az policy definition delete --name "$SCOPE_TEST" --output none || note "Could not delete ${SCOPE_TEST}"
fi
for mg in "${LAB_MGS[@]}"; do
  prefix="${MG_PREFIX}/${mg}/providers/"
  while IFS=$'\t' read -r id name; do
    if [[ -n "$name" && "${id,,}" == "${prefix,,}"* ]]; then
      info "Deleting initiative ${name} from ${mg}..."
      az policy set-definition delete --name "$name" --management-group "$mg" --output none || note "Could not delete ${name}"
    fi
  done < <(az_q policy set-definition list --management-group "$mg" --query "[?policyType=='Custom'].[id, name]")
  while IFS=$'\t' read -r id name; do
    if [[ -n "$name" && "${id,,}" == "${prefix,,}"* ]]; then
      info "Deleting policy definition ${name} from ${mg}..."
      az policy definition delete --name "$name" --management-group "$mg" --output none || note "Could not delete ${name}"
    fi
  done < <(az_q policy definition list --management-group "$mg" --query "[?policyType=='Custom'].[id, name]")
done

banner "4 · Your subscription's place in the hierarchy"
current_mg=""
for mg in "${LAB_MGS[@]}"; do
  if sub_in_mg "$mg"; then
    current_mg="$mg"
    break
  fi
done
original_parent=""
if [[ -s "$LAB31_STATE_FILE" ]]; then
  original_parent="$(cat "$LAB31_STATE_FILE")"
fi
if [[ -n "$current_mg" ]]; then
  if [[ -n "$original_parent" && "$original_parent" != "$TENANT_ID" ]]; then
    info "Moving your subscription back to ${original_parent}..."
    if ! az account management-group subscription add --name "$original_parent" --subscription "$SUB_ID" --output none; then
      note "Could not move it back to ${original_parent}. Move it in the portal (Management groups), then run cleanup.sh again."
      exit 1
    fi
  else
    info "Moving your subscription back to the Tenant root group..."
    if ! az account management-group subscription remove --name "$current_mg" --subscription "$SUB_ID" --output none; then
      if ! az account management-group subscription add --name "$TENANT_ID" --subscription "$SUB_ID" --output none; then
        note "Could not move it back. Move it in the portal (Management groups), then run cleanup.sh again."
        exit 1
      fi
    fi
  fi
  info "Moved. The portal can take a few minutes to show the change."
else
  info "Your subscription is not in a lab management group — nothing to move."
fi
rm -f "$LAB31_STATE_FILE"

banner "5 · Management groups (children first)"
for mg in "${LAB_MGS[@]}"; do
  if ! az account management-group show --name "$mg" --output none 2>/dev/null; then
    continue
  fi
  deleted=0
  for i in $(seq 1 8); do
    if az account management-group delete --name "$mg" --output none 2>/dev/null; then
      deleted=1
      info "Deleted ${mg}."
      break
    fi
    info "${mg} cannot be deleted yet (attempt ${i} of 8; Azure may still see a child) — retrying in 30 seconds..."
    sleep 30
  done
  if (( deleted == 0 )); then
    note "Could not delete ${mg}. Wait a few minutes and run cleanup.sh again."
  fi
done

banner "6 · Resource groups and generated files"
delete_lunch_rgs 31
rm -rf "${LAB_DIR}/generated" "${LAB_DIR}/exported"
info "Done. Resource group deletion continues in the background for a few minutes."
info "Check with: az group list --tag lunch=31 --query \"[].name\" --output tsv"
info "and:        az account management-group list --query \"[?contains(name, '${SUFFIX}')].name\" --output tsv"
