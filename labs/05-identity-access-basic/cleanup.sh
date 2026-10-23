#!/usr/bin/env bash
# =============================================================================
# Lab 05 · Removes everything the lab created:
#   1. role assignments of the contractors group and the test user, at ANY scope
#      (including a forgotten subscription-scope one from "Break it and fix it")
#   2. the test user (also purged from Deleted users, so the name can be reused)
#   3. the contractors group
#   4. the lab resource group rg-lunch05-<suffix>
# Order matters: assignments go first, otherwise they linger as "Identity not found".
#     bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 05)"
GROUP_NAME="grp-nusa-contractors-${SUFFIX}"
DOMAIN="$(az_q rest --method get --url https://graph.microsoft.com/v1.0/domains --query "value[?isDefault].id")"
TEST_UPN="rizky-${SUFFIX}@${DOMAIN}"

banner "Lab 05 · Clean up"
USER_ID=""
[[ -n "$DOMAIN" ]] && USER_ID="$(az_q ad user show --id "$TEST_UPN" --query id)"
GROUP_ID="$(az_q ad group list --display-name "$GROUP_NAME" --query "[?displayName=='${GROUP_NAME}'].id | [0]")"

# remove_assignments <object-id> <label>   -> deletes every role assignment of that principal in this subscription
remove_assignments() {
  local id="$1" label="$2" ids
  [[ -z "$id" ]] && return 0
  ids="$(az_q role assignment list --assignee-object-id "$id" --all --fill-principal-name false --query "[].id")"
  if [[ -n "$ids" ]]; then
    info "Removing role assignments of ${label}..."
    # shellcheck disable=SC2086  # word splitting is intended: one argument per assignment ID
    az role assignment delete --ids $ids --output none || note "Some role assignments could not be removed."
  else
    info "No role assignments found for ${label}."
  fi
}

remove_assignments "$GROUP_ID" "group ${GROUP_NAME}"
remove_assignments "$USER_ID" "user ${TEST_UPN}"

if [[ -n "$USER_ID" ]]; then
  info "Deleting user ${TEST_UPN}..."
  az ad user delete --id "$USER_ID" || note "Could not delete the user."
  sleep 5
  if az rest --method delete --url "https://graph.microsoft.com/v1.0/directory/deletedItems/${USER_ID}" \
       --output none 2>/dev/null; then
    info "Purged the user from Deleted users."
  else
    note "Could not purge the user from Deleted users yet; it is removed automatically after 30 days."
  fi
else
  info "User ${TEST_UPN} not found. Nothing to delete."
fi

if [[ -n "$GROUP_ID" ]]; then
  info "Deleting group ${GROUP_NAME}..."
  az ad group delete --group "$GROUP_ID" || note "Could not delete the group."
else
  info "Group ${GROUP_NAME} not found. Nothing to delete."
fi

delete_lunch_rgs 05

info "Done. Also remove the test account from the Microsoft Authenticator app on your phone."
