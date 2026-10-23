#!/usr/bin/env bash
# =============================================================================
# Lab 04 · Verify: checks the Challenge brief and prints PASS/FAIL per check.
#   bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG_SHOP="$(rg_name 04 shop)"
RG_SHARED="$(rg_name 04 shared)"
ST="stnusaimg${SUFFIX}"

# rg_tag <resource group> <tag name>  -> the tag's value ("" if the tag or the group is missing)
rg_tag() { az_q group show --name "$1" --query "tags.\"$2\""; }

banner "Resource groups and their tags (Task 1)"
check "Resource group ${RG_SHOP} exists" az group show --name "$RG_SHOP"
check "Resource group ${RG_SHARED} exists" az group show --name "$RG_SHARED"
for pair in "lunch=04" "project=storefront" "env=lab" "costCenter=ecommerce"; do
  check_eq "${RG_SHOP} has the tag ${pair}" "${pair#*=}" "$(rg_tag "$RG_SHOP" "${pair%%=*}")"
done
for pair in "lunch=04" "project=shared-services" "env=lab" "costCenter=it"; do
  check_eq "${RG_SHARED} has the tag ${pair}" "${pair#*=}" "$(rg_tag "$RG_SHARED" "${pair%%=*}")"
done

banner "Storage account (Tasks 2 and 6)"
st_rg="$(az_q storage account list --query "[?name=='${ST}'].resourceGroup | [0]")"
check_nonempty "Storage account ${ST} exists" "$st_rg"
check_eq "${ST} now lives in ${RG_SHARED} (moved there from the shop group)" "$RG_SHARED" "$st_rg"
if [[ -n "$st_rg" ]]; then
  # st_show <JMESPath query>  -> one property of the storage account
  st_show() { az_q storage account show --name "$ST" --resource-group "$st_rg" --query "$1"; }
  check_eq "${ST} is a StorageV2 account" "StorageV2" "$(st_show kind)"
  check_eq "${ST} uses Standard_LRS" "Standard_LRS" "$(st_show sku.name)"
  check_eq "${ST} requires TLS 1.2 as the minimum" "TLS1_2" "$(st_show minimumTlsVersion)"
  check_eq "${ST} has anonymous blob access disabled" "false" "$(st_show allowBlobPublicAccess)"
  check_eq "${ST} has its own tag app=product-images" "product-images" "$(st_show 'tags.app')"
  check_eq "${ST} has its own tag env=lab" "lab" "$(st_show 'tags.env')"
fi

banner "No locks left behind (Tasks 4 and 5, Break it and fix it)"
if lock_ids="$(az lock list --query "[].id" --output tsv 2>/dev/null)"; then
  pattern="/resourcegroups/(${RG_SHOP}|${RG_SHARED})(/|$)"
  left="$(grep -ciE "$pattern" <<<"$lock_ids" || true)"
  check_eq "No resource locks remain on the Lab 04 resource groups or the storage account" "0" "${left:-0}"
  if [[ "${left:-0}" != "0" ]]; then
    grep -iE "$pattern" <<<"$lock_ids" | sed 's/^/     still locked: /'
  fi
else
  fail "Could not list resource locks (do you have permission to read locks?)"
fi

banner "Optional: management group (Task 8)"
if az account management-group show --name "mg-nusa-lab-${SUFFIX}" --no-register --output none 2>/dev/null; then
  note "Management group mg-nusa-lab-${SUFFIX} exists; cleanup.sh will delete it."
else
  info "No lab management group found (Task 8 is optional)."
fi

summary
