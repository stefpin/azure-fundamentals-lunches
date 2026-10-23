#!/usr/bin/env bash
# =============================================================================
# Lab 07 · Store product images and invoices — reference solution (Tasks 1–7)
#   bash solution.sh
# Safe to re-run: every step checks or overwrites instead of failing on "exists".
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLES="${LAB_DIR}/sample-files"
WORK="${LAB_DIR}/work"
RG="$(rg_name 07)"
ACCOUNT="${ACCOUNT:-stnusa07${SUFFIX}}"
mkdir -p "$WORK"

banner "Task 1 · Resource group and secure storage account (${ACCOUNT})"
ensure_rg "$RG" 07
if az storage account show --name "$ACCOUNT" --resource-group "$RG" --output none 2>/dev/null; then
  info "Storage account already exists — enforcing the security settings."
  az storage account update --name "$ACCOUNT" --resource-group "$RG" \
    --min-tls-version TLS1_2 --allow-blob-public-access false --https-only true --output none
else
  az storage account create \
    --name "$ACCOUNT" \
    --resource-group "$RG" \
    --location "$LOCATION" \
    --kind StorageV2 \
    --sku Standard_LRS \
    --access-tier Hot \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true \
    --output none
fi
ACCOUNT_ID="$(az storage account show --name "$ACCOUNT" --resource-group "$RG" --query id --output tsv)"

banner "Task 2 · Storage Blob Data Contributor for you"
ME="$(my_object_id)"
if [[ -z "$ME" ]]; then
  echo "Could not read your object ID (az ad signed-in-user show). Sign in as a user, not a service principal."
  exit 1
fi
existing="$(az role assignment list --assignee "$ME" --scope "$ACCOUNT_ID" \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'] | length(@)" --output tsv)"
if [[ "$existing" == "0" ]]; then
  az role assignment create --assignee-object-id "$ME" --assignee-principal-type User \
    --role "Storage Blob Data Contributor" --scope "$ACCOUNT_ID" --output none
fi
info "Waiting for the data role to take effect (up to 10 minutes)…"
wait_until "data role" 600 az storage container list --account-name "$ACCOUNT" --auth-mode login \
  || { echo "The data role is not active yet. Wait a few minutes and run this script again."; exit 1; }

banner "Task 3 · Containers and invoice uploads with the Azure CLI"
for c in products invoices; do
  az storage container create --account-name "$ACCOUNT" --name "$c" --auth-mode login --output none
done
for f in "$SAMPLES"/invoices/*.txt; do
  name="$(basename "$f")"
  tier="$(az_q storage blob show --account-name "$ACCOUNT" --container-name invoices --name "$name" \
    --auth-mode login --query properties.blobTier)"
  if [[ "$tier" == "Archive" ]]; then
    info "${name} is archived already — skipping the re-upload."
    continue
  fi
  az storage blob upload --account-name "$ACCOUNT" --container-name invoices --name "$name" \
    --file "$f" --overwrite --auth-mode login --output none
done

banner "Task 4 · Product images with AzCopy (Azure CLI sign-in)"
if command -v azcopy >/dev/null 2>&1; then
  export AZCOPY_AUTO_LOGIN_TYPE=AZCLI
  AZCOPY_TENANT_ID="$(az account show --query tenantId --output tsv)"
  export AZCOPY_TENANT_ID
  azcopy copy "${SAMPLES}/products/*" "https://${ACCOUNT}.blob.core.windows.net/products/" \
    --overwrite=true --log-level=ERROR
else
  note "AzCopy not found — uploading the images with az storage blob upload-batch instead."
  az storage blob upload-batch --account-name "$ACCOUNT" --destination products \
    --source "${SAMPLES}/products" --overwrite --auth-mode login --output none
fi

banner "Task 5 · Cool and Archive tiers, then start a rehydration by copy"
az storage blob set-tier --account-name "$ACCOUNT" --container-name products \
  --name songket-scarf.svg --tier Cool --auth-mode login --output none
az storage blob set-tier --account-name "$ACCOUNT" --container-name invoices \
  --name INV-2026-0001.txt --tier Archive --auth-mode login --output none
if [[ -z "$(az_q storage blob show --account-name "$ACCOUNT" --container-name invoices \
      --name INV-2026-0001-rehydrated.txt --auth-mode login --query name)" ]]; then
  az storage blob copy start --account-name "$ACCOUNT" \
    --source-container invoices --source-blob INV-2026-0001.txt \
    --destination-container invoices --destination-blob INV-2026-0001-rehydrated.txt \
    --tier Hot --rehydrate-priority Standard --auth-mode login --output none
fi
az storage blob show --account-name "$ACCOUNT" --container-name invoices --name INV-2026-0001-rehydrated.txt \
  --auth-mode login --query "{tier:properties.blobTier, status:properties.rehydrationStatus}" --output table

banner "Task 6 · One-hour, read-only user delegation SAS"
EXPIRY="$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%MZ')"
SAS_URL="$(az storage blob generate-sas --account-name "$ACCOUNT" --container-name products \
  --name batik-shirt.svg --permissions r --expiry "$EXPIRY" --https-only \
  --auth-mode login --as-user --full-uri --output tsv)"
code_with="$(curl -s -o "${WORK}/batik-shirt.svg" -w '%{http_code}' "$SAS_URL" || true)"
code_without="$(curl -s -o /dev/null -w '%{http_code}' "https://${ACCOUNT}.blob.core.windows.net/products/batik-shirt.svg" || true)"
info "With the SAS: HTTP ${code_with} · without the SAS: HTTP ${code_without}"

banner "Task 7 · Azure Files share store-docs"
if ! az storage share-rm show --resource-group "$RG" --storage-account "$ACCOUNT" --name store-docs \
     --output none 2>/dev/null; then
  az storage share-rm create --resource-group "$RG" --storage-account "$ACCOUNT" --name store-docs \
    --quota 1 --enabled-protocols SMB --output none
fi
az storage file upload --account-name "$ACCOUNT" --share-name store-docs \
  --source "${SAMPLES}/store-docs/price-list-2026-10.csv" --auth-mode key --output none

banner "Done"
info "Run 'bash verify.sh' to check your work, then 'bash cleanup.sh' to remove everything."
