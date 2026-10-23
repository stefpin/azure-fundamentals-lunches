#!/usr/bin/env bash
# =============================================================================
# Lab 21 · deploy.sh — deploys the capstone platform from infra/main.bicep.
#   1. finds out who you are (UPN and object ID) for the Azure SQL Entra admin
#      and the Key Vault role, and where alert e-mails should go
#   2. makes sure you have an SSH public key for the web VMs
#   3. compiles the Bicep files and shows a what-if preview
#   4. asks before deploying, deploys, and waits for the storefront to answer
#
#     bash deploy.sh
#
# Re-runnable: a second run only changes what drifted away from the templates.
# Optional overrides (set them in front of the command):
#   ALERT_EMAIL=you@example.com          where alert e-mails go
#   SQL_ADMIN_UPN=... SQL_ADMIN_OBJECT_ID=...   if your directory profile cannot be read
#   USE_FREE_SQL_OFFER=false             use a small paid serverless database instead
#   VM_SIZE_SMALL=Standard_B2ats_v2      another allowed size (see infra/main.bicep)
#   ASSUME_YES=1                         do not ask before deploying
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

TEMPLATE="${LAB_DIR}/infra/main.bicep"

banner "Who is deploying?"
SQL_ADMIN_UPN="${SQL_ADMIN_UPN:-$(my_upn || true)}"
SQL_ADMIN_OBJECT_ID="${SQL_ADMIN_OBJECT_ID:-$(my_object_id || true)}"
if [[ -z "$SQL_ADMIN_UPN" || -z "$SQL_ADMIN_OBJECT_ID" ]]; then
  echo "Could not read your Microsoft Entra profile (az ad signed-in-user show)."
  echo "Set both values yourself and run the script again, for example:"
  echo "  SQL_ADMIN_UPN=you@contoso.com SQL_ADMIN_OBJECT_ID=<your-object-id> bash deploy.sh"
  exit 1
fi
ALERT_EMAIL="${ALERT_EMAIL:-$(az account show --query user.name --output tsv 2>/dev/null || true)}"
ALERT_EMAIL="${ALERT_EMAIL##*#}"     # personal accounts can appear as live.com#name@example.com
if [[ "$ALERT_EMAIL" != *@* ]]; then
  echo "Set ALERT_EMAIL to an address that can receive alert e-mails, then run again:"
  echo "  ALERT_EMAIL=you@example.com bash deploy.sh"
  exit 1
fi
info "Azure SQL Entra administrator : ${SQL_ADMIN_UPN}"
info "Alert e-mails go to           : ${ALERT_EMAIL}"
info "Region / VM size              : ${LOCATION} / ${VM_SIZE_SMALL}"

banner "SSH key for the web VMs"
SSH_KEY_FILE="${SSH_KEY_FILE:-${HOME}/.ssh/id_rsa.pub}"
if [[ ! -f "$SSH_KEY_FILE" ]]; then
  info "No SSH key at ${SSH_KEY_FILE}; creating one (lab use only)..."
  mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
  ssh-keygen -t rsa -b 4096 -N "" -q -f "${SSH_KEY_FILE%.pub}"
fi
SSH_PUBLIC_KEY="$(cat "$SSH_KEY_FILE")"
info "Using ${SSH_KEY_FILE} (you will not need it: the VMs have no public IP; use Run Command)."

banner "Resource group"
ensure_rg "$RG" 21
info "${RG} in ${LOCATION}"

# A vault deleted by an earlier run stays soft-deleted for 7 days and blocks the name.
deleted_kv_location="$(az_q keyvault list-deleted --query "[?name=='${KV}'].properties.location | [0]")"
if [[ -n "$deleted_kv_location" ]] && ! az keyvault show --name "$KV" --output none 2>/dev/null; then
  note "Key Vault ${KV} is still soft-deleted from an earlier run."
  if confirm "Purge it now so the name can be reused?"; then
    az keyvault purge --name "$KV" --location "$deleted_kv_location"
  else
    echo "Cannot continue while ${KV} is soft-deleted. Purge it or wait until it expires."
    exit 1
  fi
fi

PARAMS=(
  location="$LOCATION"
  suffix="$SUFFIX"
  vmSize="$VM_SIZE_SMALL"
  adminUsername="$ADMIN_USER"
  sshPublicKey="$SSH_PUBLIC_KEY"
  sqlAdminLogin="$SQL_ADMIN_UPN"
  sqlAdminObjectId="$SQL_ADMIN_OBJECT_ID"
  alertEmail="$ALERT_EMAIL"
  useFreeSqlOffer="${USE_FREE_SQL_OFFER:-true}"
)

banner "Compile check"
az bicep build --file "$TEMPLATE" --stdout > /dev/null
info "main.bicep and its six modules compile."

banner "What-if: what would change?"
az deployment group what-if \
  --resource-group "$RG" \
  --name "$DEPLOYMENT" \
  --template-file "$TEMPLATE" \
  --parameters "${PARAMS[@]}"

if ! confirm "Deploy these changes now?"; then
  info "Nothing deployed. Run 'bash deploy.sh' again when you are ready."
  exit 0
fi

banner "Deploying (about 10-15 minutes; watch it in the portal: ${RG} > Settings > Deployments)"
az deployment group create \
  --resource-group "$RG" \
  --name "$DEPLOYMENT" \
  --template-file "$TEMPLATE" \
  --parameters "${PARAMS[@]}" \
  --output none

banner "Deployment outputs"
az deployment group show --resource-group "$RG" --name "$DEPLOYMENT" \
  --query "properties.outputs.{storefront:storefrontUrl.value, publicIp:publicIpAddress.value, sqlServer:sqlServerFqdn.value, keyVault:keyVaultName.value, workspace:workspaceName.value}" \
  --output table

IP="$(lb_ip)"
SITE_URL="$(az_q deployment group show --resource-group "$RG" --name "$DEPLOYMENT" --query properties.outputs.storefrontUrl.value)"

banner "Waiting for the web servers to finish booting (cloud-init, 1-3 minutes)"
if wait_until "storefront answers on http://${IP}/" 600 curl -fsS --max-time 5 "http://${IP}/"; then
  info "The storefront answers: ${SITE_URL}  (or http://${IP}/)"
else
  note "No answer yet. Give the VMs a few more minutes, then try: curl http://${IP}/"
fi

echo
info "Next: Task 3 in README.md. Load the names and helpers in your shell with:"
info "  source ../common/config.sh && source lab.env"
