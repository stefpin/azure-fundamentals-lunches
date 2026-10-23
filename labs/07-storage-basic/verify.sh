#!/usr/bin/env bash
# =============================================================================
# Lab 07 · Store product images and invoices — checks your work
#   bash verify.sh
# Read-only: it creates nothing. Data-plane checks use your Entra sign-in
# (--auth-mode login), so they need the data role from Task 2.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 07)"
ACCOUNT="${ACCOUNT:-stnusa07${SUFFIX}}"

banner "Storage account"
if ! az storage account show --name "$ACCOUNT" --resource-group "$RG" --output none 2>/dev/null; then
  other="$(az_q storage account list --resource-group "$RG" --query "[0].name")"
  if [[ -n "$other" ]]; then
    note "No account named ${ACCOUNT}; checking ${other} instead."
    ACCOUNT="$other"
  fi
fi
props="$(az_q storage account show --name "$ACCOUNT" --resource-group "$RG" \
  --query "[kind, sku.name, minimumTlsVersion, allowBlobPublicAccess, enableHttpsTrafficOnly, id]")"
if [[ -z "$props" ]]; then
  fail "Storage account ${ACCOUNT} in ${RG} (Task 1)"
  summary
  exit 1
fi
mapfile -t p <<< "$props"
pass "Storage account ${ACCOUNT} exists in ${RG}"
check_eq "Account kind is StorageV2 (general-purpose v2) — Task 1" "StorageV2" "${p[0]}"
check_eq "Redundancy is Standard_LRS — Task 1" "Standard_LRS" "${p[1]}"
check_eq "Minimum TLS version is TLS1_2 — Task 1" "TLS1_2" "${p[2]}"
check_eq "Anonymous blob access is disallowed — Task 1" "false" "${p[3]}"
check_eq "Only HTTPS traffic is allowed — Task 1" "true" "${p[4]}"
ACCOUNT_ID="${p[5]}"

banner "Your data role"
ME="$(my_object_id)"
roles="$(az_q role assignment list --assignee "$ME" --scope "$ACCOUNT_ID" --include-inherited \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor' || roleDefinitionName=='Storage Blob Data Owner'] | length(@)")"
check_ge "You hold Storage Blob Data Contributor or Owner on the account — Task 2" 1 "${roles:-0}"

banner "Blob containers and tiers"
containers="$(az_q storage container list --account-name "$ACCOUNT" --auth-mode login --query "[].name")"
if [[ -z "$containers" ]]; then
  fail "Listing containers with your Entra sign-in (needs the data role from Task 2 and at least one container)"
else
  most=0; cool=0; archive=0; best=""
  while IFS= read -r c; do
    [[ -z "$c" ]] && continue
    tiers="$(az_q storage blob list --account-name "$ACCOUNT" --container-name "$c" --auth-mode login \
      --query "[].properties.blobTier")"
    n=0
    if [[ -n "$tiers" ]]; then n="$(grep -c . <<< "$tiers")"; fi
    if (( n > most )); then most=$n; best="$c"; fi
    cool=$(( cool + $(grep -cx "Cool" <<< "$tiers" || true) ))
    archive=$(( archive + $(grep -cx "Archive" <<< "$tiers" || true) ))
  done <<< "$containers"
  check_ge "A container with at least 2 blobs (most: ${best:-none}) — Tasks 3 and 4" 2 "$most"
  check_ge "At least one blob in the Cool tier — Task 5" 1 "$cool"
  if (( archive >= 1 )); then
    info "${archive} blob(s) in the Archive tier — nice (Task 5)."
  else
    note "No blob in the Archive tier yet. Task 5 archives INV-2026-0001.txt."
  fi
fi

banner "Azure Files"
shares="$(az_q storage share-rm list --resource-group "$RG" --storage-account "$ACCOUNT" --query "[].name")"
check_contains "File share store-docs exists — Task 7" "store-docs" "$shares"

summary
