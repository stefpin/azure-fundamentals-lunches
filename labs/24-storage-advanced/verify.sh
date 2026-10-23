#!/usr/bin/env bash
# =============================================================================
# Lab 24 · Ransomware-proof invoices — checks your work
#   bash verify.sh
# Read-only, and it uses only management (control-plane) calls, so it still works
# after you disable public network access in Task 9.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 24)"
ACCOUNT="${ACCOUNT:-stnusa24${SUFFIX}}"
VNET="vnet-nusa-lab24"
ZONE="privatelink.blob.core.windows.net"

banner "Lab environment (setup.sh)"
check "Virtual network ${VNET} exists in ${RG}" az network vnet show --resource-group "$RG" --name "$VNET"
check "VM vm-dns-1 exists in ${RG}" az vm show --resource-group "$RG" --name vm-dns-1

banner "Storage account"
if ! az storage account show --name "$ACCOUNT" --resource-group "$RG" --output none 2>/dev/null; then
  other="$(az_q storage account list --resource-group "$RG" --query "[0].name")"
  if [[ -n "$other" ]]; then
    note "No account named ${ACCOUNT}; checking ${other} instead."
    ACCOUNT="$other"
  fi
fi
props="$(az_q storage account show --name "$ACCOUNT" --resource-group "$RG" --query "[kind, publicNetworkAccess]")"
if [[ -z "$props" ]]; then
  fail "Storage account ${ACCOUNT} in ${RG} (Task 1)"
  summary
  exit 1
fi
mapfile -t p <<< "$props"
pass "Storage account ${ACCOUNT} exists in ${RG}"
check_eq "Account kind is StorageV2 (general-purpose v2) — Task 1" "StorageV2" "${p[0]:-}"

banner "Data protection (Task 2)"
bsp="$(az_q storage account blob-service-properties show --account-name "$ACCOUNT" --resource-group "$RG" \
  --query "[isVersioningEnabled, deleteRetentionPolicy.enabled, deleteRetentionPolicy.days, containerDeleteRetentionPolicy.enabled, containerDeleteRetentionPolicy.days, changeFeed.enabled]")"
mapfile -t b <<< "$bsp"
check_eq "Blob versioning is enabled" "true" "${b[0]:-}"
check_eq "Blob soft delete is enabled" "true" "${b[1]:-}"
check_ge "Blob soft delete keeps deleted data for at least 7 days" 7 "${b[2]:-}"
check_eq "Container soft delete is enabled" "true" "${b[3]:-}"
check_ge "Container soft delete keeps deleted containers for at least 7 days" 7 "${b[4]:-}"
check_eq "Change feed is enabled" "true" "${b[5]:-}"

banner "Lifecycle management (Task 5)"
tiering="$(az_q storage account management-policy show --account-name "$ACCOUNT" --resource-group "$RG" \
  --query "length(policy.rules[?enabled && (definition.actions.baseBlob.tierToCool || definition.actions.baseBlob.tierToCold || definition.actions.baseBlob.tierToArchive)])")"
check_ge "An enabled lifecycle rule moves blobs to cooler tiers" 1 "${tiering:-0}"
deleting="$(az_q storage account management-policy show --account-name "$ACCOUNT" --resource-group "$RG" \
  --query "length(policy.rules[?enabled && definition.actions.baseBlob.delete])")"
check_ge "An enabled lifecycle rule deletes blobs at the end of their life" 1 "${deleting:-0}"

banner "Immutability (Task 6)"
imm="$(az_q storage container-rm show --storage-account "$ACCOUNT" --resource-group "$RG" --name invoices-2025 \
  --query "[hasImmutabilityPolicy, immutabilityPolicy.state]")"
mapfile -t im <<< "$imm"
check_eq "Container invoices-2025 has a time-based retention policy" "true" "${im[0]:-}"
case "${im[1]:-}" in
  Unlocked) info "The policy is Unlocked — right for a lab, because cleanup.sh can remove it." ;;
  Locked)   note "The policy is LOCKED: the account can't be deleted until it expires. See README › Clean up." ;;
esac

banner "Private endpoint and private DNS (Task 7)"
approved="$(az_q storage account show --name "$ACCOUNT" --resource-group "$RG" \
  --query "length(privateEndpointConnections[?privateLinkServiceConnectionState.status=='Approved'])")"
check_ge "The account has an approved private endpoint connection" 1 "${approved:-0}"
groups="$(az_q network private-endpoint list --resource-group "$RG" \
  --query "[].privateLinkServiceConnections[].groupIds[]")"
check_contains "A private endpoint in ${RG} targets the blob sub-resource" "blob" "$groups"
check "Private DNS zone ${ZONE} exists in ${RG}" \
  az network private-dns zone show --resource-group "$RG" --name "$ZONE"
links="$(az_q network private-dns link vnet list --resource-group "$RG" --zone-name "$ZONE" \
  --query "[].virtualNetwork.id")"
check_contains "The private DNS zone is linked to ${VNET}" "/virtualNetworks/${VNET}" "$links"
arec="$(az_q network private-dns record-set a show --resource-group "$RG" --zone-name "$ZONE" --name "$ACCOUNT" \
  --query "aRecords[0].ipv4Address")"
check_contains "The zone has an A record for ${ACCOUNT} in snet-pe (10.24.2.x)" "10.24.2." "$arec"

banner "Network lockdown (Task 9)"
check_eq "Public network access is Disabled" "Disabled" "${p[1]:-}"

summary
