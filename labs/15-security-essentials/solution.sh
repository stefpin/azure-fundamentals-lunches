#!/usr/bin/env bash
# =============================================================================
# Lab 15 · solution.sh — reference solution for Tasks 2-7. Run setup.sh first.
#   Task 2  key vault kv-nusa-<suffix> with the Azure RBAC permission model
#   Task 3  Key Vault Secrets Officer for you, then a NEW sql-connection secret
#   Task 4  system-assigned managed identity for vm-app-1
#   Task 5  read the secret from inside the VM (HTTP 403: no role yet)
#   Task 6  Key Vault Secrets User for the VM identity, retry until HTTP 200
#   Task 7  remove the password from the VM's config file
# Task 8 (secure score and recommendations) happens in the portal.
# Safe to run again. Never prints the secret value.
#   bash solution.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 15)"
VM="vm-app-1"
KV_NAME="kv-nusa-${SUFFIX}"
SECRET_NAME="sql-connection"

# run_in_vm <script-in-lab-folder> <parameter...>  -> prints the Run Command output
run_in_vm() {
  local script="$1"; shift
  az vm run-command invoke --resource-group "$RG" --name "$VM" \
    --command-id RunShellScript --scripts @"${LAB_DIR}/${script}" \
    --parameters "$@" --query "value[0].message" --output tsv
}

# assign_role <principal-object-id> <User|ServicePrincipal> <role name>  (vault scope, idempotent)
assign_role() {
  local pid="$1" ptype="$2" role="$3" count
  count="$(az_q role assignment list --scope "$KV_ID" \
    --query "length([?principalId=='${pid}' && roleDefinitionName=='${role}'])")"
  if [[ "${count:-0}" == "0" ]]; then
    az role assignment create --assignee-object-id "$pid" --assignee-principal-type "$ptype" \
      --role "$role" --scope "$KV_ID" --output none
    info "Assigned '${role}' at vault scope."
  else
    info "'${role}' is already assigned at vault scope."
  fi
}

if ! az vm show --resource-group "$RG" --name "$VM" --output none 2>/dev/null; then
  echo "${VM} was not found in ${RG}. Run 'bash setup.sh' first."
  exit 1
fi

banner "Task 2 · Key vault ${KV_NAME} with the Azure RBAC permission model"
if az keyvault show --name "$KV_NAME" --output none 2>/dev/null; then
  info "The vault already exists."
else
  deleted="$(az_q keyvault list-deleted --resource-type vault --query "[?name=='${KV_NAME}'].name | [0]")"
  if [[ -n "$deleted" ]]; then
    echo "A soft-deleted vault named ${KV_NAME} is left over from an earlier attempt."
    echo "Run 'bash cleanup.sh' to purge it (or recover it: az keyvault recover --name ${KV_NAME}), then run this again."
    exit 1
  fi
  az keyvault create --name "$KV_NAME" --resource-group "$RG" --location "$LOCATION" \
    --enable-rbac-authorization true --retention-days 7 --output none
  info "Created ${KV_NAME} (RBAC permission model, soft delete with 7-day retention, no purge protection)."
fi
KV_ID="$(az keyvault show --name "$KV_NAME" --query id --output tsv)"

banner "Task 3 · Key Vault Secrets Officer for you, then the secret"
ME="$(my_object_id)"
if [[ -z "$ME" ]]; then
  echo "Could not read your object ID (az ad signed-in-user show). Sign in with a user account and try again."
  exit 1
fi
assign_role "$ME" User "Key Vault Secrets Officer"
info "Waiting until your data-plane role works (role assignments take a few minutes to propagate)..."
if ! wait_until "your Key Vault Secrets Officer role" 600 az keyvault secret list --vault-name "$KV_NAME"; then
  echo "Your role assignment has not taken effect yet. Wait a few minutes and run this script again."
  exit 1
fi
exists="$(az_q keyvault secret list --vault-name "$KV_NAME" \
  --query "length([?ends_with(id, '/secrets/${SECRET_NAME}')])")"
if [[ "${exists:-0}" == "0" ]]; then
  # The password in the VM's file must be treated as leaked, so the vault gets a NEW one.
  NEW_PW="$(openssl rand -base64 18)"
  CONN="Server=tcp:sql-nusa-orders.database.windows.net,1433;Database=orders;User ID=storefront;Password=${NEW_PW};Encrypt=True;"
  az keyvault secret set --vault-name "$KV_NAME" --name "$SECRET_NAME" --value "$CONN" --output none
  unset NEW_PW CONN
  info "Stored secret '${SECRET_NAME}' (value not shown)."
else
  info "Secret '${SECRET_NAME}' already exists."
fi

banner "Task 4 · System-assigned managed identity for ${VM}"
PRINCIPAL_ID="$(az_q vm show --resource-group "$RG" --name "$VM" --query identity.principalId)"
if [[ -z "$PRINCIPAL_ID" ]]; then
  az vm identity assign --resource-group "$RG" --name "$VM" --output none
  PRINCIPAL_ID="$(az vm show --resource-group "$RG" --name "$VM" --query identity.principalId --output tsv)"
fi
info "VM identity object ID: ${PRINCIPAL_ID}"

banner "Task 5 · First read from inside the VM (expect HTTP 403 while the VM has no role)"
run_in_vm vm/read-secret.sh "$KV_NAME" || true

banner "Task 6 · Key Vault Secrets User for the VM identity, then read again"
assign_role "$PRINCIPAL_ID" ServicePrincipal "Key Vault Secrets User"
ok=0
for ((attempt = 1; attempt <= 12; attempt++)); do
  out="$(run_in_vm vm/read-secret.sh "$KV_NAME" 2>&1 || true)"
  if grep -q "RESULT: HTTP 200" <<<"$out"; then
    echo "$out"
    ok=1
    break
  fi
  last="$(grep -o 'RESULT: .*' <<<"$out" | head -n 1 || true)"
  info "Attempt ${attempt}: ${last:-no result}. Waiting 30 seconds for the role assignment to propagate..."
  sleep 30
done
if (( ok == 0 )); then
  echo "The VM still cannot read the secret. See the Troubleshooting section in README.md."
  exit 1
fi

banner "Task 7 · Remove the password from the VM's config file"
run_in_vm vm/remove-password.sh "$KV_NAME"

banner "Done"
info "Task 8 is in the portal: Microsoft Defender for Cloud > Overview (secure score) and Recommendations."
info "Check your work with: bash verify.sh"
