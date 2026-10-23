#!/usr/bin/env bash
# =============================================================================
# Lab 22 · Removes everything the lab created, in a safe order:
#   1. assignments of the custom role, then the custom role itself
#      (a custom role can't be deleted while it is still assigned)
#   2. the app registration: its role assignments, service principal and app
#      (purged from Deleted applications)
#   3. the managed identity's role assignments and the identity
#   4. the operators group
#   5. the lab resource group (storage account included) and the my-*.json files
#     bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 22)"
ROLE_NAME="Nusantara VM Operator ${SUFFIX}"
OPS_GROUP="grp-nusa-vm-operators-${SUFFIX}"
MI_NAME="id-nusa-reports"
APP_NAME="app-nusa-github-deploy-${SUFFIX}"
RG_ID="$(az_q group show --name "$RG" --query id)"

# remove_assignments <object-id> <label>   -> deletes every role assignment of that principal in this subscription
remove_assignments() {
  local id="$1" label="$2" ids
  [[ -z "$id" ]] && return 0
  ids="$(az_q role assignment list --assignee-object-id "$id" --all --fill-principal-name false --query "[].id")"
  if [[ -n "$ids" ]]; then
    info "Removing role assignments of ${label}..."
    # shellcheck disable=SC2086  # one argument per assignment ID
    az role assignment delete --ids $ids --output none || note "Some role assignments of ${label} could not be removed."
  fi
}

banner "Lab 22 · Clean up"

banner "1 · Custom role '${ROLE_NAME}'"
ROLE_GUID=""
[[ -n "$RG_ID" ]] && ROLE_GUID="$(az_q role definition list --name "$ROLE_NAME" --scope "$RG_ID" --query "[0].name")"
if [[ -n "$ROLE_GUID" ]]; then
  ids="$(az_q role assignment list --all --fill-principal-name false \
    --query "[?ends_with(roleDefinitionId, '/${ROLE_GUID}')].id")"
  if [[ -n "$ids" ]]; then
    info "Removing assignments of the custom role..."
    # shellcheck disable=SC2086
    az role assignment delete --ids $ids --output none || note "Some assignments could not be removed."
  fi
  info "Deleting the custom role (retries while the removed assignments replicate)..."
  deleted=0
  for attempt in 1 2 3 4 5 6; do
    if az role definition delete --name "$ROLE_GUID" --scope "$RG_ID" --output none 2>/dev/null; then
      deleted=1
      break
    fi
    sleep 20
  done
  if (( deleted == 1 )); then
    info "Deleted the custom role."
  else
    note "Could not delete the custom role yet. Run: az role definition delete --name ${ROLE_GUID} --scope ${RG_ID}"
  fi
elif [[ -z "$RG_ID" ]]; then
  note "Resource group ${RG} not found, so the custom role can't be looked up at its scope. If you deleted the"
  note "resource group yourself earlier, check the subscription's Access control (IAM) › Roles for '${ROLE_NAME}'."
else
  info "Custom role not found. Nothing to delete."
fi

banner "2 · App registration ${APP_NAME}"
APP_ID="$(az_q ad app list --display-name "$APP_NAME" --query "[?displayName=='${APP_NAME}'].appId | [0]")"
if [[ -n "$APP_ID" ]]; then
  APP_OBJECT_ID="$(az_q ad app show --id "$APP_ID" --query id)"
  SP_ID="$(az_q ad sp show --id "$APP_ID" --query id)"
  remove_assignments "$SP_ID" "service principal ${APP_NAME}"
  if [[ -n "$SP_ID" ]]; then
    az ad sp delete --id "$APP_ID" || note "Could not delete the service principal."
  fi
  info "Deleting the app registration (its federated credential goes with it)..."
  az ad app delete --id "$APP_ID" || note "Could not delete the app registration."
  sleep 5
  if [[ -n "$APP_OBJECT_ID" ]] && az rest --method delete \
       --url "https://graph.microsoft.com/v1.0/directory/deletedItems/${APP_OBJECT_ID}" --output none 2>/dev/null; then
    info "Purged the app from Deleted applications."
  else
    note "The app stays in Deleted applications for 30 days, then disappears automatically."
  fi
else
  info "App registration not found. Nothing to delete."
fi

banner "3 · Managed identity ${MI_NAME}"
MI_PID=""
[[ -n "$RG_ID" ]] && MI_PID="$(az_q identity show --name "$MI_NAME" --resource-group "$RG" --query principalId)"
if [[ -n "$MI_PID" ]]; then
  remove_assignments "$MI_PID" "managed identity ${MI_NAME}"
  az identity delete --name "$MI_NAME" --resource-group "$RG" || note "Could not delete the managed identity."
  info "Deleted the managed identity."
else
  info "Managed identity not found. Nothing to delete."
fi

banner "4 · Group ${OPS_GROUP}"
OPS_GROUP_ID="$(az_q ad group list --display-name "$OPS_GROUP" --query "[?displayName=='${OPS_GROUP}'].id | [0]")"
if [[ -n "$OPS_GROUP_ID" ]]; then
  remove_assignments "$OPS_GROUP_ID" "group ${OPS_GROUP}"
  az ad group delete --group "$OPS_GROUP_ID" || note "Could not delete the group."
  info "Deleted the group."
else
  info "Group not found. Nothing to delete."
fi

banner "5 · Resource group and local files"
delete_lunch_rgs 22
rm -f "$LAB_DIR"/my-*.json
info "Removed the generated my-*.json files."
info "Done. If you tried Task 7, also delete the workflow, secrets and variable from your GitHub repository."
