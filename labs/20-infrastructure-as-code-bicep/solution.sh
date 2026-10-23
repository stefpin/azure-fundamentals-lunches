#!/usr/bin/env bash
# =============================================================================
# Lab 20 · solution.sh — the reference solution, using solution/main.bicep.
#   Task 1  resource group, then build the Bicep file
#   Task 3  what-if before the first deployment
#   Task 4  deploy, show the outputs, deploy again (nothing changes)
#   Task 5  environment=test: what-if shows ~ Modify, then deploy
#   Task 6  deploy as a deployment stack with denyDelete; deleting the storage account is refused
# Task 7 (deleting the stack) is left to you, so that verify.sh can check the stack first.
# Takes about 6 minutes.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE="${LAB_DIR}/solution/main.bicep"
RG="$(rg_name 20)"
STACK="stack-nusa-iac"

banner "Task 1 · Resource group and build"
ensure_rg "$RG" 20
info "Resource group ${RG} in ${LOCATION}."
az bicep build --file "$TEMPLATE" --stdout > /dev/null
info "solution/main.bicep builds without errors."

banner "Task 3 · What-if before the first deployment"
az deployment group what-if --resource-group "$RG" --template-file "$TEMPLATE"

banner "Task 4 · Deploy, then deploy the same file again"
az deployment group create --resource-group "$RG" --name lab20-main --template-file "$TEMPLATE" \
  --query "properties.outputs" --output jsonc
az deployment group create --resource-group "$RG" --name lab20-main-again --template-file "$TEMPLATE" --output none
info "The second deployment created nothing new: the resources already matched the file."

banner "Task 5 · Change a parameter: environment=test"
az deployment group what-if --resource-group "$RG" --template-file "$TEMPLATE" --parameters environment=test
az deployment group create --resource-group "$RG" --name lab20-environment-test --template-file "$TEMPLATE" \
  --parameters environment=test --output none
info "Every resource now has the tag environment=test."

banner "Task 6 · The same file as a deployment stack with denyDelete"
az stack group create --name "$STACK" --resource-group "$RG" --template-file "$TEMPLATE" \
  --parameters environment=test \
  --action-on-unmanage deleteResources \
  --deny-settings-mode denyDelete \
  --yes --output none
az stack group show --name "$STACK" --resource-group "$RG" \
  --query "{state: provisioningState, denySettings: denySettings.mode, managedResources: resources[].id}" \
  --output jsonc || note "Could not show the stack."

STORAGE="$(az_q storage account list --resource-group "$RG" --query "[0].name")"
if [[ -z "$STORAGE" ]]; then
  note "No storage account found in ${RG}, so there is nothing to try deleting."
else
  info "Trying to delete storage account ${STORAGE} (this should be refused)..."
  if error_text="$(az storage account delete --name "$STORAGE" --resource-group "$RG" --yes 2>&1)"; then
    note "The delete succeeded, so the deny settings did not protect the storage account. Check the stack's deny settings."
  elif grep -q 'DenyAssignmentAuthorizationFailed' <<< "$error_text"; then
    info "Refused with DenyAssignmentAuthorizationFailed, as expected: the stack's deny assignment protects it."
  else
    info "Refused, but with a different error than expected:"
    printf '%s\n' "$error_text" | head -n 5 || true
  fi
fi

banner "Next"
info "Run: bash verify.sh"
info "Then Task 7: az stack group delete --name ${STACK} --resource-group ${RG} --action-on-unmanage deleteResources --yes"
info "(or simply run cleanup.sh, which deletes the stack and the resource group)."
