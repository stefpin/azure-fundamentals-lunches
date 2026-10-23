#!/usr/bin/env bash
# =============================================================================
# Lab 05 · Checks the Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 05)"
GROUP_NAME="grp-nusa-contractors-${SUFFIX}"
DOMAIN="$(az_q rest --method get --url https://graph.microsoft.com/v1.0/domains --query "value[?isDefault].id")"
TEST_UPN="rizky-${SUFFIX}@${DOMAIN}"

banner "Lab 05 · Identity and access"
info "Looking for user ${TEST_UPN}, group ${GROUP_NAME} and resource group ${RG}"

banner "Identities in Microsoft Entra ID"
check_nonempty "Your tenant's default domain can be read" "$DOMAIN"
USER_ID="$(az_q ad user show --id "$TEST_UPN" --query id)"
check_nonempty "Test user ${TEST_UPN} exists" "$USER_ID"

GROUP_ID="$(az_q ad group list --display-name "$GROUP_NAME" --query "[?displayName=='${GROUP_NAME}'].id | [0]")"
check_nonempty "Security group ${GROUP_NAME} exists" "$GROUP_ID"
if [[ -n "$GROUP_ID" ]]; then
  check_eq "The group is a security group" "true" "$(az_q ad group show --group "$GROUP_ID" --query securityEnabled)"
fi

if [[ -n "$USER_ID" && -n "$GROUP_ID" ]]; then
  MEMBERS="$(az_q ad group member list --group "$GROUP_ID" --query "[].id")"
  check_contains "The test user is a member of the group" "$USER_ID" "$MEMBERS"
else
  fail "The test user is a member of the group (the user or the group is missing)"
fi

banner "Resource group"
RG_ID="$(az_q group show --name "$RG" --query id)"
check_nonempty "Resource group ${RG} exists" "$RG_ID"
if [[ -n "$RG_ID" ]]; then
  check_eq "Resource group carries the lab tag lunch=05 (so cleanup.sh can find it)" "05" \
    "$(az_q group show --name "$RG" --query tags.lunch)"
  check_ge "Resource group contains a network security group" 1 \
    "$(az_q network nsg list --resource-group "$RG" --query "length(@)")"
fi

banner "Role assignments"
if [[ -n "$GROUP_ID" && -n "$RG_ID" ]]; then
  CONTRIBUTOR="$(az_q role assignment list --assignee-object-id "$GROUP_ID" --scope "$RG_ID" \
    --fill-principal-name false --query "[?roleDefinitionName=='Contributor'] | length(@)")"
  check_ge "The group holds Contributor at the resource-group scope" 1 "$CONTRIBUTOR"

  READER="$(az_q role assignment list --assignee-object-id "$GROUP_ID" --scope "$RG_ID" \
    --fill-principal-name false --query "[?roleDefinitionName=='Reader'] | length(@)")"
  if [[ "${READER:-0}" =~ ^[0-9]+$ ]] && (( READER > 0 )); then
    note "Reader is still assigned at the resource group. Contributor already includes read access; remove it (Task 7)."
  fi

  OUTSIDE=0
  while IFS= read -r scope; do
    [[ -z "$scope" ]] && continue
    if [[ "${scope,,}" != "${RG_ID,,}" && "${scope,,}" != "${RG_ID,,}/"* ]]; then
      OUTSIDE=$((OUTSIDE + 1))
      info "Found an assignment outside the lab resource group: ${scope}"
    fi
  done < <(az_q role assignment list --assignee-object-id "$GROUP_ID" --all --fill-principal-name false --query "[].scope")
  check_eq "The group has no role assignments outside the lab resource group" "0" "$OUTSIDE"
else
  fail "The group holds Contributor at the resource-group scope (the group or the resource group is missing)"
fi

if [[ -n "$USER_ID" ]]; then
  check_eq "The test user has no direct role assignments (access comes through the group)" "0" \
    "$(az_q role assignment list --assignee-object-id "$USER_ID" --all --fill-principal-name false --query "length(@)")"
fi

summary
