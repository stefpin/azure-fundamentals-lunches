#!/usr/bin/env bash
# =============================================================================
# Lab 18 · setup
# Creates the lab resource group plus two "legacy" resources that existed before
# Nusantara Retail had any guardrails: a storage account and a network security
# group, both deliberately WITHOUT tags. Both are free or close to free.
#   bash setup.sh        (about 2 minutes)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
source "$(dirname "$0")/lab-vars.sh"

banner "Lab 18 setup · ${RG}"

info "Registering the Microsoft.PolicyInsights resource provider (compliance data and remediation)..."
az provider register --namespace Microsoft.PolicyInsights --output none

if az group show --name "$RG" --output none 2>/dev/null; then
  info "Resource group ${RG} already exists — keeping it and its tags."
else
  info "Creating resource group ${RG} in ${LOCATION}..."
  ensure_rg "$RG" 18
fi

policy_hint() {
  echo
  echo "Azure refused to create a legacy resource. If you already assigned the lab policies,"
  echo "run 'bash cleanup.sh', wait a few minutes for the deletion to finish, then run 'bash setup.sh' again."
}

if az storage account show --name "$LEGACY_SA" --resource-group "$RG" --output none 2>/dev/null; then
  info "Legacy storage account ${LEGACY_SA} already exists."
else
  info "Creating legacy storage account ${LEGACY_SA} (no tags, on purpose)..."
  if ! az storage account create --name "$LEGACY_SA" --resource-group "$RG" --location "$LOCATION" \
      --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
      --output none; then
    policy_hint
    exit 1
  fi
fi

if az network nsg show --name "$LEGACY_NSG" --resource-group "$RG" --output none 2>/dev/null; then
  info "Legacy network security group ${LEGACY_NSG} already exists."
else
  info "Creating legacy network security group ${LEGACY_NSG} (no tags, on purpose)..."
  if ! az network nsg create --name "$LEGACY_NSG" --resource-group "$RG" --location "$LOCATION" --output none; then
    policy_hint
    exit 1
  fi
fi

banner "Setup complete"
az resource list --resource-group "$RG" --query "[].{name:name, type:type, location:location, costCenter:tags.costCenter}" --output table
info "Both resources have no costCenter tag. Continue with Task 1 in the lab README."
