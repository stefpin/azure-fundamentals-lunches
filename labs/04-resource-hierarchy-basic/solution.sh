#!/usr/bin/env bash
# =============================================================================
# Lab 04 · Reference solution: organise Nusantara Retail.
# Runs Tasks 1-7 of the guide without prompts and leaves no locks behind.
# Task 8 (management group, own tenant only) runs only when you ask for it:
#   CREATE_MG=1 bash solution.sh
# Safe to run more than once.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG_SHOP="$(rg_name 04 shop)"
RG_SHARED="$(rg_name 04 shared)"
ST="stnusaimg${SUFFIX}"
ST_TYPE="Microsoft.Storage/storageAccounts"
MG="mg-nusa-lab-${SUFFIX}"

# expect_blocked "description" <command...>  -> returns 0 when a lock refuses the command
expect_blocked() {
  local d="$1"; shift
  local out
  if out="$("$@" 2>&1)"; then
    note "UNEXPECTED: '${d}' succeeded. Is the lock in place?"
    return 1
  fi
  if grep -qi "locked" <<<"$out"; then
    info "Blocked by the lock, as expected: ${d}"
  else
    note "'${d}' failed, but not because of a lock:"
    printf '%s\n' "$out" | head -n 5
  fi
}

# storage_rg  -> the resource group the storage account is in now ("" if it doesn't exist)
storage_rg() { az storage account list --query "[?name=='${ST}'].resourceGroup | [0]" --output tsv 2>/dev/null || true; }

# create_storage <resource group>
create_storage() {
  az storage account create --name "$ST" --resource-group "$1" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
    --output none
}

# lock_storage <resource group> <lock name> <CanNotDelete|ReadOnly>  /  unlock_storage <resource group> <lock name>
lock_storage() {
  az lock create --name "$2" --lock-type "$3" --resource-group "$1" \
    --resource "$ST" --resource-type "$ST_TYPE" --output none
}
unlock_storage() {
  az lock delete --name "$2" --resource-group "$1" --resource "$ST" --resource-type "$ST_TYPE" \
    || note "Could not delete lock $2 (it may already be gone)."
}

# A lock left behind by an interrupted earlier run would make this run fail: remove it first.
leftover="$(az lock list --query "[].id" --output tsv 2>/dev/null | grep -iE "/resourcegroups/(${RG_SHOP}|${RG_SHARED})(/|$)" || true)"
for lock_id in $leftover; do
  info "Removing a lock left behind by an earlier run: ${lock_id##*/}"
  az lock delete --ids "$lock_id"
done
if [[ -n "$leftover" ]]; then sleep 20; fi

banner "Task 1 · Two tagged resource groups"
ensure_rg "$RG_SHOP" 04
ensure_rg "$RG_SHARED" 04
az tag update --resource-id "$(az group show --name "$RG_SHOP" --query id --output tsv)" \
  --operation Merge --tags project=storefront env=lab costCenter=ecommerce --output none
az tag update --resource-id "$(az group show --name "$RG_SHARED" --query id --output tsv)" \
  --operation Merge --tags project=shared-services env=lab costCenter=it --output none
az group list --query "[?tags.lunch=='04'].{name:name, location:location, project:tags.project, costCenter:tags.costCenter}" \
  --output table

banner "Task 2 · A storage account, and tags that don't flow down"
CUR_RG="$(storage_rg)"
if [[ -z "$CUR_RG" ]]; then
  create_storage "$RG_SHOP"
  CUR_RG="$RG_SHOP"
  info "Created ${ST} in ${RG_SHOP}"
  info "Tags on the new account: $(az storage account show --name "$ST" --resource-group "$CUR_RG" --query tags --output json | tr -d ' \n')"
else
  info "${ST} already exists in ${CUR_RG}"
fi
ST_ID="$(az storage account show --name "$ST" --resource-group "$CUR_RG" --query id --output tsv)"
az tag update --resource-id "$ST_ID" --operation Merge --tags app=product-images env=lab --output none
info "Tags after tagging the resource itself: $(az tag list --resource-id "$ST_ID" --query properties.tags --output json | tr -d ' \n')"

banner "Task 3 · The resource ID, taken apart"
echo "   ${ST_ID}"
IFS='/' read -r -a parts <<< "$ST_ID"
for i in "${!parts[@]}"; do printf '   %2d  %s\n' "$i" "${parts[$i]}"; done
az provider show --namespace Microsoft.Storage --query "{namespace:namespace, state:registrationState}" --output table
info "Newest API versions of storageAccounts:"
az provider show --namespace Microsoft.Storage \
  --query "resourceTypes[?resourceType=='storageAccounts'].apiVersions | [0][:3]" --output tsv | sed 's/^/     /'

banner "Task 4 · A CanNotDelete lock blocks deletion"
lock_storage "$CUR_RG" lock-nodelete CanNotDelete
sleep 20
if ! expect_blocked "delete the storage account" \
     az storage account delete --name "$ST" --resource-group "$CUR_RG" --yes; then
  note "The account was deleted. Re-creating it so the lab can continue."
  create_storage "$CUR_RG"
  ST_ID="$(az storage account show --name "$ST" --resource-group "$CUR_RG" --query id --output tsv)"
  az tag update --resource-id "$ST_ID" --operation Merge --tags app=product-images env=lab --output none
fi
az tag update --resource-id "$ST_ID" --operation Merge --tags owner=dewi --output none
info "Tag update worked: a CanNotDelete lock still allows changes."
unlock_storage "$CUR_RG" lock-nodelete

banner "Task 5 · A ReadOnly lock blocks more than you expect"
lock_storage "$CUR_RG" lock-readonly ReadOnly
sleep 20
az storage account show --name "$ST" --resource-group "$CUR_RG" --query "{name:name, sku:sku.name}" --output table
expect_blocked "list the account keys (a POST action)" \
  az storage account keys list --account-name "$ST" --resource-group "$CUR_RG" --query "length(@)" --output tsv || true
expect_blocked "change a tag (a write)" \
  az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none || true
unlock_storage "$CUR_RG" lock-readonly
sleep 20
info "Number of keys listed after removing the lock: $(az storage account keys list --account-name "$ST" --resource-group "$CUR_RG" --query "length(@)" --output tsv 2>/dev/null || echo "not yet, try again shortly")"

banner "Task 6 · Move the account to ${RG_SHARED}"
if [[ "${CUR_RG,,}" != "${RG_SHARED,,}" ]]; then
  OLD_ID="$ST_ID"
  info "Moving ${ST} (this takes a minute or two)..."
  az resource move --destination-group "$RG_SHARED" --ids "$OLD_ID"
  CUR_RG="$RG_SHARED"
  ST_ID="$(az storage account show --name "$ST" --resource-group "$RG_SHARED" --query id --output tsv)"
  info "old ID: ${OLD_ID}"
  info "new ID: ${ST_ID}"
else
  info "${ST} is already in ${RG_SHARED}"
fi
az storage account show --name "$ST" --resource-group "$RG_SHARED" \
  --query "{group:resourceGroup, location:primaryLocation, tags:tags}" --output json

banner "Task 7 · Azure Resource Graph"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az graph query -q "ResourceContainers | where type =~ 'microsoft.resources/subscriptions/resourcegroups' | where tags.lunch == '04' | project name, location, project=tostring(tags.project), costCenter=tostring(tags.costCenter)" \
  --query "data[]" --output table || note "Resource Graph query failed; try again in a minute."
az graph query -q "Resources | where tags.app == 'product-images' | project name, type, resourceGroup, location" \
  --query "data[]" --output table || note "Resource Graph query failed; try again in a minute."
info "Resources tagged costCenter=it (expect none: tags don't inherit):"
az graph query -q "Resources | where tags.costCenter == 'it' | project name, resourceGroup" \
  --query "data[]" --output table || note "Resource Graph query failed; try again in a minute."

if [[ "${CREATE_MG:-0}" == "1" ]]; then
  banner "Task 8 · Management group ${MG} (own tenant only)"
  if az account management-group show --name "$MG" --no-register --output none 2>/dev/null; then
    info "${MG} already exists"
  else
    info "Creating ${MG}; the first management group in a tenant can take up to 15 minutes..."
    az account management-group create --name "$MG" --display-name "Nusantara Retail (lab)" --output none
  fi
  az account management-group show --name "$MG" \
    --query "{name:name, displayName:displayName, parent:details.parent.displayName}" --output table
else
  info "Task 8 (management group) skipped. Include it with:  CREATE_MG=1 bash solution.sh  (own tenant only)"
fi

banner "Done"
info "Now run:  bash verify.sh    and afterwards:  bash cleanup.sh"
