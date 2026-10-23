#!/usr/bin/env bash
# =============================================================================
# Lab 15 · verify.sh — checks the Challenge brief and prints PASS/FAIL per check.
# It changes nothing. Two read-only scripts run inside vm-app-1 through Run Command
# (about a minute in total). The secret value is never printed.
#   bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 15)"
VM="vm-app-1"
KV_NAME="kv-nusa-${SUFFIX}"
SECRET_NAME="sql-connection"

banner "Lab 15 · verify (resource group ${RG})"
check "Resource group ${RG} exists" az group show --name "$RG"

banner "Key vault"
KV_ID="$(az_q keyvault show --name "$KV_NAME" --resource-group "$RG" --query id)"
check_nonempty "Key vault ${KV_NAME} exists in ${RG}" "$KV_ID"
rbac="$(az_q keyvault show --name "$KV_NAME" --resource-group "$RG" --query properties.enableRbacAuthorization)"
check_eq "The vault uses the Azure RBAC permission model" "true" "$rbac"
softdelete="$(az_q keyvault show --name "$KV_NAME" --resource-group "$RG" --query properties.enableSoftDelete)"
if [[ "${softdelete,,}" == "false" ]]; then
  fail "Soft delete is on"
else
  pass "Soft delete is on (it can't be turned off for new vaults)"
fi

ME="$(my_object_id)"
if [[ -n "$KV_ID" && -n "$ME" ]]; then
  mine="$(az_q role assignment list --scope "$KV_ID" \
    --query "length([?principalId=='${ME}' && roleDefinitionName=='Key Vault Secrets Officer'])")"
  check_ge "You hold Key Vault Secrets Officer on the vault" 1 "$mine"
else
  note "Skipped your own role check (no vault, or not signed in with a user account)."
fi

secret_id="$(az_q keyvault secret list --vault-name "$KV_NAME" \
  --query "[?ends_with(id, '/secrets/${SECRET_NAME}')].id | [0]")"
check_nonempty "Secret ${SECRET_NAME} exists in the vault" "$secret_id"

banner "Managed identity and role assignment"
id_type="$(az_q vm show --resource-group "$RG" --name "$VM" --query identity.type)"
check_contains "${VM} has a system-assigned managed identity" "SystemAssigned" "$id_type"
PRINCIPAL_ID="$(az_q vm show --resource-group "$RG" --name "$VM" --query identity.principalId)"
if [[ -n "$PRINCIPAL_ID" && -n "$KV_ID" ]]; then
  vmrole="$(az_q role assignment list --scope "$KV_ID" \
    --query "length([?principalId=='${PRINCIPAL_ID}' && roleDefinitionName=='Key Vault Secrets User'])")"
  check_ge "The VM identity holds Key Vault Secrets User on the vault" 1 "$vmrole"
  extra="$(az_q role assignment list --all \
    --query "[?principalId=='${PRINCIPAL_ID}' && roleDefinitionName!='Key Vault Secrets User'].roleDefinitionName" \
    | sort -u | tr '\n' ' ')"
  extra="${extra% }"
  if [[ -z "$extra" ]]; then
    pass "Least privilege: the VM identity has no other role assignments"
  else
    fail "Least privilege: the VM identity also holds: ${extra}"
  fi
else
  fail "The VM identity holds Key Vault Secrets User on the vault (no identity or no vault found)"
fi

banner "Inside the VM (Run Command, about a minute)"
power="$(az_q vm get-instance-view --resource-group "$RG" --name "$VM" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]")"
if [[ "$power" != "PowerState/running" ]]; then
  fail "${VM} is running (state: ${power:-unknown}). Start it: az vm start -g ${RG} -n ${VM}"
  fail "Skipped the secret read and the config file check"
else
  out="$(az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunShellScript \
    --scripts @"${LAB_DIR}/vm/read-secret.sh" --parameters "$KV_NAME" \
    --query "value[0].message" --output tsv 2>&1)"
  result="$(grep -o 'RESULT: .*' <<<"$out" | head -n 1 | tr -d '\r')"
  check_eq "The VM reads ${SECRET_NAME} with its managed identity" "RESULT: HTTP 200" "$result"

  cfg="$(az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunShellScript \
    --scripts 'f=/etc/nusa/appsettings.json; if [ ! -f "$f" ]; then echo CONFIG-MISSING; elif grep -q "Password=" "$f"; then echo CONFIG-PASSWORD-PRESENT; else echo CONFIG-CLEAN; fi' \
    --query "value[0].message" --output tsv 2>&1)"
  check_contains "No password left in /etc/nusa/appsettings.json" "CONFIG-CLEAN" "$cfg"
fi

note "Task 8 (secure score and recommendations in Defender for Cloud) is not checked by this script."
summary
