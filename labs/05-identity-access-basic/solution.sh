#!/usr/bin/env bash
# =============================================================================
# Lab 05 · Reference solution: a contractor test user and group, Reader and then
# Contributor at resource-group scope.
#
# Run it ONLY in your own Microsoft Entra tenant (the one that came with your
# personal free account), never in a company or school tenant:
#     bash solution.sh
# Safe to re-run: existing objects are reused. Set ASSUME_YES=1 to skip the prompt.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 05)"
GROUP_NAME="grp-nusa-contractors-${SUFFIX}"

banner "Task 1 · Check the tenant"
DOMAIN="$(az rest --method get --url https://graph.microsoft.com/v1.0/domains \
  --query "value[?isDefault].id" --output tsv)"
TENANT_NAME="$(az rest --method get --url https://graph.microsoft.com/v1.0/organization \
  --query "value[0].displayName" --output tsv)"
if [[ -z "$DOMAIN" ]]; then
  echo "Could not read your tenant's default domain. Are you signed in to the right tenant?"
  exit 1
fi
info "Tenant: ${TENANT_NAME} · default domain: ${DOMAIN}"
if ! confirm "Is this YOUR OWN lab tenant (not a company or school tenant)?"; then
  echo "Stopping. Run this lab only in a tenant that you own."
  exit 1
fi
TEST_UPN="rizky-${SUFFIX}@${DOMAIN}"

banner "Task 2 · Resource group ${RG} with a free network security group"
ensure_rg "$RG" 05
if ! az network nsg show --resource-group "$RG" --name nsg-web --output none 2>/dev/null; then
  az network nsg create --resource-group "$RG" --name nsg-web --location "$LOCATION" --output none
fi
RG_ID="$(az group show --name "$RG" --query id --output tsv)"
info "Scope for role assignments: ${RG_ID}"

banner "Task 3 · Test user ${TEST_UPN}"
# random_part -> 20 random base64 characters (openssl is in Cloud Shell; /dev/urandom is the fallback)
random_part() { { openssl rand -base64 15 2>/dev/null || head -c 15 /dev/urandom | base64; } | tr -d '/+=\n'; }
NEW_PASSWORD=""
if az ad user show --id "$TEST_UPN" --output none 2>/dev/null; then
  info "The user already exists; keeping it and its current password."
else
  NEW_PASSWORD="Lab5-$(random_part)-x9"
  az ad user create \
    --display-name "Rizky (Lab 05 test user)" \
    --user-principal-name "$TEST_UPN" \
    --password "$NEW_PASSWORD" \
    --force-change-password-next-sign-in true \
    --output none
  info "Created the user."
fi
USER_ID="$(az ad user show --id "$TEST_UPN" --query id --output tsv)"

banner "Task 4 · Group ${GROUP_NAME}"
GROUP_ID="$(az_q ad group list --display-name "$GROUP_NAME" --query "[?displayName=='${GROUP_NAME}'].id | [0]")"
if [[ -z "$GROUP_ID" ]]; then
  GROUP_ID="$(az ad group create \
    --display-name "$GROUP_NAME" \
    --mail-nickname "$GROUP_NAME" \
    --description "Lab 05: contractors working on the storefront test environment" \
    --query id --output tsv)"
  info "Created the group."
fi
IS_MEMBER="$(az_q ad group member check --group "$GROUP_ID" --member-id "$USER_ID" --query value)"
if [[ "${IS_MEMBER,,}" != "true" ]]; then
  az ad group member add --group "$GROUP_ID" --member-id "$USER_ID"
  info "Added the user to the group."
fi

# has_role <role> <scope>   -> succeeds when the group already holds that role at exactly that scope
has_role() {
  [[ -n "$(az_q role assignment list --assignee-object-id "$GROUP_ID" --role "$1" --scope "$2" \
    --fill-principal-name false --query "[0].id")" ]]
}

# assign_role <role> <scope>   -> retries while a newly created group replicates
assign_role() {
  local role="$1" scope="$2" attempt
  for attempt in 1 2 3 4 5 6; do
    if az role assignment create --assignee-object-id "$GROUP_ID" --assignee-principal-type Group \
         --role "$role" --scope "$scope" --output none 2>/dev/null; then
      info "Assigned ${role} to the group."
      return 0
    fi
    info "Waiting for the group to replicate before assigning ${role} (attempt ${attempt} of 6)..."
    sleep 20
  done
  echo "Could not assign ${role}. Run the az role assignment create command by hand to see the error."
  return 1
}

banner "Task 5 · Reader at resource-group scope"
has_role "Reader" "$RG_ID" || assign_role "Reader" "$RG_ID"

banner "Task 6 · (manual) Sign in as the test user"
info "In the guided lab you now sign in as Rizky in a private window and try to add a rule to nsg-web (refused)."

banner "Task 7 · Contributor instead of Reader"
has_role "Contributor" "$RG_ID" || assign_role "Contributor" "$RG_ID"
if has_role "Reader" "$RG_ID"; then
  az role assignment delete --assignee-object-id "$GROUP_ID" --role "Reader" --scope "$RG_ID"
  info "Removed the Reader assignment (Contributor already includes read access)."
fi

banner "Task 8 · Rizky's effective access"
az role assignment list --assignee "$TEST_UPN" --all --include-groups \
  --query "[].{role:roleDefinitionName, scope:scope, via:principalName}" --output table

banner "Sign in as the test user"
info "Private browser window: https://portal.azure.com"
info "User name: ${TEST_UPN}"
if [[ -n "$NEW_PASSWORD" ]]; then
  info "Temporary password (shown only now and saved nowhere): ${NEW_PASSWORD}"
  info "Rizky must choose a new password and register MFA at first sign-in."
else
  info "The user already existed, so its password was not changed. To set a new temporary password:"
  info "  P=\"Lab5-\$(openssl rand -base64 15 | tr -d '/+=')-x9\"; az ad user update --id ${TEST_UPN} --password \"\$P\" --force-change-password-next-sign-in true; echo \"\$P\""
fi
info "Next: bash verify.sh — and bash cleanup.sh when you are done."
