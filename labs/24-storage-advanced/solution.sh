#!/usr/bin/env bash
# =============================================================================
# Lab 24 · Ransomware-proof invoices — reference solution (Tasks 1–9)
#   bash solution.sh          (runs setup.sh first if the lab VM doesn't exist yet)
# Safe to re-run. If public network access is already Disabled from an earlier run,
# it is opened again for the data-plane tasks and closed again in Task 9.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
SAMPLES="${LAB_DIR}/sample-files"
WORK="${LAB_DIR}/work"
RG="$(rg_name 24)"
ACCOUNT="${ACCOUNT:-stnusa24${SUFFIX}}"
VNET="vnet-nusa-lab24"
VM="vm-dns-1"
PE="pe-stnusa24-blob"
ZONE="privatelink.blob.core.windows.net"
BLOB_HOST="${ACCOUNT}.blob.core.windows.net"
mkdir -p "$WORK"

# version_of <blob> <first|last>  -> oldest or newest version ID of a blob in the invoices container
version_of() {
  local idx=0
  [[ "$2" == "last" ]] && idx=-1
  az storage blob list --account-name "$ACCOUNT" --container-name invoices --include v --prefix "$1" \
    --auth-mode login --query "sort_by([?name=='$1'], &versionId)[${idx}].versionId" --output tsv
}

# promote <blob> <version-id>  -> copies a previous version over the blob, making it current again
promote() {
  az storage blob copy start --account-name "$ACCOUNT" \
    --destination-container invoices --destination-blob "$1" \
    --source-uri "https://${BLOB_HOST}/invoices/$1?versionId=$2" \
    --auth-mode login --output none
  wait_until "copy of $1" 120 copy_done "$1" || note "The copy of $1 hasn't finished yet."
}

copy_done() {
  [[ "$(az_q storage blob show --account-name "$ACCOUNT" --container-name invoices --name "$1" \
        --auth-mode login --query properties.copy.status)" == "success" ]]
}

# first_line <container> <blob>  -> downloads a blob into work/ and prints its first line
first_line() {
  rm -f "${WORK}/peek.txt"
  az storage blob download --account-name "$ACCOUNT" --container-name "$1" --name "$2" \
    --file "${WORK}/peek.txt" --auth-mode login --output none
  head -n 1 "${WORK}/peek.txt"
}

# restore_container <name>  -> restores a soft-deleted container (fails while the delete is still in progress)
restore_container() {
  local v
  for v in $(az_q storage container list --account-name "$ACCOUNT" --include-deleted --auth-mode login \
               --query "[?name=='$1' && deleted].version"); do
    if az storage container restore --account-name "$ACCOUNT" --name "$1" --deleted-version "$v" \
         --auth-mode login --output none 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

blob_exists() {
  [[ "$(az_q storage blob exists --account-name "$ACCOUNT" --container-name "$1" --name "$2" \
        --auth-mode login --query exists)" == "true" ]]
}

# vm_run "<script>"  -> runs a shell script on the VM through Run Command and prints the output
vm_run() {
  az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunShellScript \
    --scripts "$1" --query "value[0].message" --output tsv
}

if ! az vm show --resource-group "$RG" --name "$VM" --output none 2>/dev/null; then
  info "The lab VM doesn't exist yet — running setup.sh first."
  bash "${LAB_DIR}/setup.sh"
fi

banner "Task 1 · Storage account ${ACCOUNT} and your data role"
if ! az storage account show --name "$ACCOUNT" --resource-group "$RG" --output none 2>/dev/null; then
  az storage account create --name "$ACCOUNT" --resource-group "$RG" --location "$LOCATION" \
    --kind StorageV2 --sku Standard_LRS --min-tls-version TLS1_2 \
    --allow-blob-public-access false --https-only true --output none
fi
ACCOUNT_ID="$(az storage account show --name "$ACCOUNT" --resource-group "$RG" --query id --output tsv)"
if [[ "$(az_q storage account show --name "$ACCOUNT" --resource-group "$RG" --query publicNetworkAccess)" == "Disabled" ]]; then
  note "Public network access is Disabled from an earlier run — opening it again for the data-plane tasks."
  az storage account update --name "$ACCOUNT" --resource-group "$RG" \
    --public-network-access Enabled --default-action Allow --output none
fi
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
info "Waiting for data-plane access (data role and network) — up to 10 minutes…"
wait_until "data-plane access" 600 az storage container list --account-name "$ACCOUNT" --auth-mode login \
  || { echo "No data-plane access yet. Wait a few minutes and run this script again."; exit 1; }

banner "Task 2 · Versioning, soft delete (14 days) and change feed"
az storage account blob-service-properties update --account-name "$ACCOUNT" --resource-group "$RG" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 14 \
  --enable-container-delete-retention true --container-delete-retention-days 14 \
  --enable-change-feed true \
  --output none
az storage account blob-service-properties show --account-name "$ACCOUNT" --resource-group "$RG" \
  --query "{versioning:isVersioningEnabled, blobSoftDeleteDays:deleteRetentionPolicy.days, containerSoftDeleteDays:containerDeleteRetentionPolicy.days, changeFeed:changeFeed.enabled}" \
  --output table

banner "Task 3 · Upload invoices, simulate ransomware, restore the original version"
wait_until "container invoices" 120 az storage container create --account-name "$ACCOUNT" --name invoices --auth-mode login \
  || { echo "Could not create the invoices container."; exit 1; }
for name in INV-2026-0042.txt INV-2026-0043.txt; do
  if ! blob_exists invoices "$name"; then
    az storage blob upload --account-name "$ACCOUNT" --container-name invoices --name "$name" \
      --file "${SAMPLES}/${name}" --auth-mode login --output none
  fi
done
printf 'ENCRYPTED BY RANSOMWARE - pay by Friday to get your invoice back\n' > "${WORK}/INV-2026-0042.txt"
az storage blob upload --account-name "$ACCOUNT" --container-name invoices --name INV-2026-0042.txt \
  --file "${WORK}/INV-2026-0042.txt" --overwrite --auth-mode login --output none
info "After the attack:   $(first_line invoices INV-2026-0042.txt)"
ORIGINAL="$(version_of INV-2026-0042.txt first)"
promote INV-2026-0042.txt "$ORIGINAL"
info "After the restore:  $(first_line invoices INV-2026-0042.txt)"
az storage blob list --account-name "$ACCOUNT" --container-name invoices --include v --prefix INV-2026-0042 \
  --auth-mode login --query "[].{name:name, versionId:versionId, current:isCurrentVersion}" --output table

banner "Task 4 · Delete an invoice, then the whole container — and recover both"
if blob_exists invoices INV-2026-0043.txt; then
  az storage blob delete --account-name "$ACCOUNT" --container-name invoices --name INV-2026-0043.txt \
    --auth-mode login --output none
fi
info "Current blobs after the delete: $(az_q storage blob list --account-name "$ACCOUNT" --container-name invoices \
  --auth-mode login --query "[].name" | tr '\n' ' ')"
LATEST="$(version_of INV-2026-0043.txt last)"
promote INV-2026-0043.txt "$LATEST"
info "Current blobs after promoting the version: $(az_q storage blob list --account-name "$ACCOUNT" \
  --container-name invoices --auth-mode login --query "[].name" | tr '\n' ' ')"

az storage container delete --account-name "$ACCOUNT" --name invoices --auth-mode login --output none
info "Container invoices deleted. Restoring it from container soft delete (can take a minute)…"
wait_until "restore of container invoices" 300 restore_container invoices \
  || { echo "The container couldn't be restored yet. Restore it by hand (Task 4) and re-run the script."; exit 1; }
wait_until "restored container" 120 az storage blob list --account-name "$ACCOUNT" --container-name invoices \
  --auth-mode login --num-results 1 || true
info "Back again: $(az_q storage blob list --account-name "$ACCOUNT" --container-name invoices \
  --auth-mode login --query "[].name" | tr '\n' ' ')"

banner "Task 5 · Ten-year lifecycle policy from lifecycle-policy.json"
az storage account management-policy create --account-name "$ACCOUNT" --resource-group "$RG" \
  --policy "@${LAB_DIR}/lifecycle-policy.json" --output none
az storage account management-policy show --account-name "$ACCOUNT" --resource-group "$RG" \
  --query "policy.rules[].{rule:name, enabled:enabled, cool:definition.actions.baseBlob.tierToCool.daysAfterModificationGreaterThan, cold:definition.actions.baseBlob.tierToCold.daysAfterModificationGreaterThan, archive:definition.actions.baseBlob.tierToArchive.daysAfterModificationGreaterThan, delete:definition.actions.baseBlob.delete.daysAfterModificationGreaterThan}" \
  --output table

banner "Task 6 · Time-based retention policy (unlocked) on invoices-2025"
wait_until "container invoices-2025" 120 az storage container create --account-name "$ACCOUNT" --name invoices-2025 \
  --auth-mode login || { echo "Could not create the invoices-2025 container."; exit 1; }
if ! blob_exists invoices-2025 INV-2025-0999.txt; then
  az storage blob upload --account-name "$ACCOUNT" --container-name invoices-2025 --name INV-2025-0999.txt \
    --file "${SAMPLES}/INV-2025-0999.txt" --auth-mode login --output none
fi
has_policy="$(az_q storage container-rm show --storage-account "$ACCOUNT" --resource-group "$RG" \
  --name invoices-2025 --query hasImmutabilityPolicy)"
if [[ "${has_policy,,}" != "true" ]]; then
  az storage container immutability-policy create --account-name "$ACCOUNT" --resource-group "$RG" \
    --container-name invoices-2025 --period 1 --output none
  info "Waiting 45 seconds for the policy to take effect…"
  sleep 45
fi
az storage container immutability-policy show --account-name "$ACCOUNT" --resource-group "$RG" \
  --container-name invoices-2025 --query "{state:state, days:immutabilityPeriodSinceCreationInDays}" --output table
if az storage blob delete --account-name "$ACCOUNT" --container-name invoices-2025 --name INV-2025-0999.txt \
     --auth-mode login --output none 2> "${WORK}/worm-delete.txt"; then
  note "The delete succeeded — the policy wasn't active yet. Run this script again in a minute."
else
  info "Delete refused as expected: $(grep -o 'BlobImmutableDueToPolicy' "${WORK}/worm-delete.txt" | head -n 1)"
fi

banner "Task 7 · Private endpoint and private DNS zone"
if ! az network private-endpoint show --resource-group "$RG" --name "$PE" --output none 2>/dev/null; then
  az network private-endpoint create --resource-group "$RG" --name "$PE" --location "$LOCATION" \
    --vnet-name "$VNET" --subnet snet-pe \
    --private-connection-resource-id "$ACCOUNT_ID" --group-id blob \
    --connection-name pec-stnusa24-blob --output none
fi
if ! az network private-dns zone show --resource-group "$RG" --name "$ZONE" --output none 2>/dev/null; then
  az network private-dns zone create --resource-group "$RG" --name "$ZONE" --output none
fi
if ! az network private-dns link vnet show --resource-group "$RG" --zone-name "$ZONE" \
     --name link-vnet-nusa-lab24 --output none 2>/dev/null; then
  az network private-dns link vnet create --resource-group "$RG" --zone-name "$ZONE" \
    --name link-vnet-nusa-lab24 --virtual-network "$VNET" --registration-enabled false --output none
fi
if ! az network private-endpoint dns-zone-group show --resource-group "$RG" --endpoint-name "$PE" \
     --name default --output none 2>/dev/null; then
  az network private-endpoint dns-zone-group create --resource-group "$RG" --endpoint-name "$PE" \
    --name default --private-dns-zone "$ZONE" --zone-name blob --output none
fi
wait_until "A record for ${ACCOUNT}" 120 az network private-dns record-set a show --resource-group "$RG" \
  --zone-name "$ZONE" --name "$ACCOUNT" || true
info "Private endpoint IP: $(az_q network private-dns record-set a show --resource-group "$RG" --zone-name "$ZONE" \
  --name "$ACCOUNT" --query "aRecords[0].ipv4Address")"

banner "Task 8 · DNS from Cloud Shell (public) and from the VM (private)"
info "Cloud Shell:"
nslookup "$BLOB_HOST" 2>/dev/null || getent hosts "$BLOB_HOST" || true
info "vm-dns-1 through Run Command (about 30 seconds):"
vm_run "nslookup ${BLOB_HOST} || getent hosts ${BLOB_HOST}" \
  || note "Run Command failed — see Troubleshooting in README.md."

banner "Task 9 · Data-plane work first, then disable public network access"
EXPIRY="$(date -u -d '+1 hour' '+%Y-%m-%dT%H:%MZ')"
SAS_URL="$(az storage blob generate-sas --account-name "$ACCOUNT" --container-name invoices \
  --name INV-2026-0042.txt --permissions r --expiry "$EXPIRY" --https-only \
  --auth-mode login --as-user --full-uri --output tsv)"
info "Cloud Shell, public access still on:  HTTP $(curl -s -o /dev/null -w '%{http_code}' "$SAS_URL" || true)"
az storage account update --name "$ACCOUNT" --resource-group "$RG" --public-network-access Disabled --output none
blocked() { [[ "$(curl -s -o /dev/null -w '%{http_code}' "$SAS_URL")" == "403" ]]; }
wait_until "the public endpoint to refuse requests" 180 blocked \
  || note "Requests aren't blocked yet — network changes can take a minute or two."
info "Cloud Shell, public access Disabled:  HTTP $(curl -s -o /dev/null -w '%{http_code}' "$SAS_URL" || true)"
info "vm-dns-1 through the private endpoint:"
vm_run "curl -s -w '\nHTTP %{http_code}\n' '${SAS_URL}'" \
  || note "Run Command failed — see Troubleshooting in README.md."

banner "Done"
info "Run 'bash verify.sh' to check your work, then 'bash cleanup.sh' to remove everything."
