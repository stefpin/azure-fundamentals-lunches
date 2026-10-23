#!/usr/bin/env bash
# =============================================================================
# Lab 22 · Reference solution:
#   - custom role "Nusantara VM Operator <suffix>" (assignable only in the lab RG)
#     assigned to a test group
#   - user-assigned managed identity with Storage Blob Data Reader on a storage account
#   - app registration + service principal with NO secret, Reader on the lab RG,
#     and a federated credential for GitHub Actions (main branch)
#
#     GITHUB_REPO="<owner>/<repo>" bash solution.sh
#
# GITHUB_REPO is the part of the subject between "repo:" and ":ref:". Without it the
# script uses nusa-lab-<suffix>/storefront, a placeholder that only you know.
# Run it in your own tenant, as Owner of the subscription. Safe to re-run.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 22)"
ROLE_NAME="Nusantara VM Operator ${SUFFIX}"
OPS_GROUP="grp-nusa-vm-operators-${SUFFIX}"
MI_NAME="id-nusa-reports"
ST_NAME="stnusareports${SUFFIX}"
APP_NAME="app-nusa-github-deploy-${SUFFIX}"
GITHUB_REPO="${GITHUB_REPO:-nusa-lab-${SUFFIX}/storefront}"

# assign <object-id> <principal-type> <role name or GUID> <scope> <label>
# Idempotent; retries while a new principal or a new custom role replicates.
assign() {
  local pid="$1" ptype="$2" role="$3" scope="$4" label="$5" attempt
  if [[ -n "$(az_q role assignment list --assignee-object-id "$pid" --role "$role" --scope "$scope" \
       --fill-principal-name false --query "[0].id")" ]]; then
    info "Already assigned: ${label}"
    return 0
  fi
  for attempt in 1 2 3 4 5 6 7 8; do
    if az role assignment create --assignee-object-id "$pid" --assignee-principal-type "$ptype" \
         --role "$role" --scope "$scope" --output none 2>/dev/null; then
      info "Assigned: ${label}"
      return 0
    fi
    info "Waiting for replication before assigning ${label} (attempt ${attempt} of 8)..."
    sleep 20
  done
  echo "Could not assign ${label}. Run 'az role assignment create' by hand to see the error."
  return 1
}

banner "Task 1 · Resource group and IDs"
ensure_rg "$RG" 22
SUB_ID="$(az account show --query id --output tsv)"
TENANT_ID="$(az account show --query tenantId --output tsv)"
RG_ID="$(az group show --name "$RG" --query id --output tsv)"
info "Resource group: ${RG_ID}"

banner "Task 2 · Custom role '${ROLE_NAME}'"
sed -e "s|__SUFFIX__|${SUFFIX}|" -e "s|__SUBSCRIPTION_ID__|${SUB_ID}|" -e "s|__RESOURCE_GROUP__|${RG}|" \
  "$LAB_DIR/vm-operator-role.json" > "$LAB_DIR/my-vm-operator-role.json"
ROLE_GUID="$(az_q role definition list --name "$ROLE_NAME" --scope "$RG_ID" --query "[0].name")"
if [[ -z "$ROLE_GUID" ]]; then
  ROLE_GUID="$(az role definition create --role-definition "@$LAB_DIR/my-vm-operator-role.json" \
    --query name --output tsv)"
  info "Created the custom role (ID ${ROLE_GUID}). New roles can take a minute or two to replicate."
else
  info "The custom role already exists (ID ${ROLE_GUID})."
fi

banner "Task 3 · Assign the custom role to ${OPS_GROUP}"
OPS_GROUP_ID="$(az_q ad group list --display-name "$OPS_GROUP" --query "[?displayName=='${OPS_GROUP}'].id | [0]")"
if [[ -z "$OPS_GROUP_ID" ]]; then
  OPS_GROUP_ID="$(az ad group create --display-name "$OPS_GROUP" --mail-nickname "$OPS_GROUP" \
    --description "Lab 22: night-shift operators who start, restart and deallocate VMs" --query id --output tsv)"
  info "Created the group."
fi
assign "$OPS_GROUP_ID" Group "$ROLE_GUID" "$RG_ID" "${ROLE_NAME} for ${OPS_GROUP} on ${RG}"

banner "Task 4 · Managed identity ${MI_NAME} with a data role"
if ! az identity show --name "$MI_NAME" --resource-group "$RG" --output none 2>/dev/null; then
  az identity create --name "$MI_NAME" --resource-group "$RG" --location "$LOCATION" --output none
  info "Created the user-assigned managed identity."
fi
MI_PRINCIPAL_ID="$(az identity show --name "$MI_NAME" --resource-group "$RG" --query principalId --output tsv)"
if ! az storage account show --name "$ST_NAME" --resource-group "$RG" --output none 2>/dev/null; then
  az storage account create --name "$ST_NAME" --resource-group "$RG" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --output none
  info "Created storage account ${ST_NAME}."
fi
ST_ID="$(az storage account show --name "$ST_NAME" --resource-group "$RG" --query id --output tsv)"
assign "$MI_PRINCIPAL_ID" ServicePrincipal "Storage Blob Data Reader" "$ST_ID" \
  "Storage Blob Data Reader for ${MI_NAME} on ${ST_NAME}"

banner "Task 5 · App registration ${APP_NAME} (no secret)"
APP_ID="$(az_q ad app list --display-name "$APP_NAME" --query "[?displayName=='${APP_NAME}'].appId | [0]")"
if [[ -z "$APP_ID" ]]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)"
  info "Created the app registration."
fi
if ! az ad sp show --id "$APP_ID" --output none 2>/dev/null; then
  az ad sp create --id "$APP_ID" --output none
  info "Created the service principal."
fi
SP_ID="$(az ad sp show --id "$APP_ID" --query id --output tsv)"
assign "$SP_ID" ServicePrincipal "Reader" "$RG_ID" "Reader for ${APP_NAME} on ${RG}"

banner "Task 6 · Federated credential for repo:${GITHUB_REPO}"
sed "s|__GITHUB_REPO__|${GITHUB_REPO}|" "$LAB_DIR/federated-credential.json" > "$LAB_DIR/my-federated-credential.json"
if [[ "$(az_q ad app federated-credential list --id "$APP_ID" --query "[?name=='github-main-branch'] | length(@)")" == "1" ]]; then
  info "Replacing the existing credential github-main-branch with the current subject."
  az ad app federated-credential delete --id "$APP_ID" --federated-credential-id github-main-branch
fi
az ad app federated-credential create --id "$APP_ID" --parameters "$LAB_DIR/my-federated-credential.json" --output none
az ad app federated-credential list --id "$APP_ID" --query "[].{name:name, subject:subject}" --output table

banner "Values for GitHub (Task 7, optional)"
info "Repository secrets:  AZURE_CLIENT_ID=${APP_ID}"
info "                     AZURE_TENANT_ID=${TENANT_ID}"
info "                     AZURE_SUBSCRIPTION_ID=${SUB_ID}"
info "Repository variable: AZURE_RESOURCE_GROUP=${RG}"
info "Workflow: copy github-workflow-example.yml to .github/workflows/azure-oidc.yml on main."
info "Next: bash verify.sh — and bash cleanup.sh when you are done."
