#!/usr/bin/env bash
# =============================================================================
# Lab 31 · setup
# Creates the starting point: two resource groups with "legacy" resources that
# existed before Nusantara Retail had company-wide rules.
#   rg-lunch31-corp-<suffix>     tagged costCenter=CC-2001, holds an untagged storage
#                                account and network security group
#   rg-lunch31-sandbox-<suffix>  untagged, holds an untagged network security group
#                                in SECONDARY_LOCATION (an "experiment")
# Also registers the resource providers and installs the Resource Graph extension.
# Everything is free or close to free.
#   bash setup.sh        (about 2–3 minutes)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
source "$(dirname "$0")/lab-vars.sh"

banner "Lab 31 setup"
az account show --query "{tenant:tenantId, subscription:name, signedInAs:user.name}" --output table
echo
echo "This lab creates MANAGEMENT GROUPS in the tenant shown above. Management groups are"
echo "tenant-wide objects. Use a tenant you own (for example the one created with your free"
echo "account) — never your employer's tenant, and never move a company subscription."
if ! confirm "Is this your own lab tenant and subscription?"; then
  echo "Stopped. Switch with 'az login --tenant <tenant-id>' or 'az account set --subscription <id>'."
  exit 1
fi

info "Registering resource providers (Microsoft.PolicyInsights, Microsoft.Management)..."
az provider register --namespace Microsoft.PolicyInsights --output none
az provider register --namespace Microsoft.Management --output none

info "Installing or updating the Azure CLI extension for Resource Graph..."
if ! az extension add --name resource-graph --upgrade --only-show-errors --output none 2>/dev/null; then
  note "Could not install the resource-graph extension now; 'az graph query' will offer to install it later."
fi

policy_hint() {
  echo
  echo "Azure refused to create a legacy resource. If the lab policy is already enforced,"
  echo "run 'bash cleanup.sh', wait a few minutes, then run 'bash setup.sh' again."
}

info "Creating resource group ${CORP_RG} with costCenter=${COST_CENTER}..."
ensure_rg "$CORP_RG" 31
az tag update --resource-id "$CORP_RG_ID" --operation Merge --tags costCenter="$COST_CENTER" --output none

info "Creating resource group ${SANDBOX_RG} (no costCenter tag)..."
ensure_rg "$SANDBOX_RG" 31

if az storage account show --name "$LEGACY_SA" --resource-group "$CORP_RG" --output none 2>/dev/null; then
  info "Legacy storage account ${LEGACY_SA} already exists."
else
  info "Creating legacy storage account ${LEGACY_SA} (no tags, on purpose)..."
  if ! az storage account create --name "$LEGACY_SA" --resource-group "$CORP_RG" --location "$LOCATION" \
      --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
      --output none; then
    policy_hint
    exit 1
  fi
fi

if az network nsg show --name "$LEGACY_NSG" --resource-group "$CORP_RG" --output none 2>/dev/null; then
  info "Legacy network security group ${LEGACY_NSG} already exists."
else
  info "Creating legacy network security group ${LEGACY_NSG} (no tags, on purpose)..."
  if ! az network nsg create --name "$LEGACY_NSG" --resource-group "$CORP_RG" --location "$LOCATION" --output none; then
    policy_hint
    exit 1
  fi
fi

if az network nsg show --name "$SANDBOX_NSG" --resource-group "$SANDBOX_RG" --output none 2>/dev/null; then
  info "Sandbox network security group ${SANDBOX_NSG} already exists."
else
  info "Creating ${SANDBOX_NSG} in ${SECONDARY_LOCATION} (an experiment outside the approved region)..."
  if ! az network nsg create --name "$SANDBOX_NSG" --resource-group "$SANDBOX_RG" --location "$SECONDARY_LOCATION" \
      --output none; then
    policy_hint
    exit 1
  fi
fi

banner "Setup complete"
for rg in "$CORP_RG" "$SANDBOX_RG"; do
  echo "${rg}  (resource group tag costCenter: $(az_q group show --name "$rg" --query tags.costCenter))"
  az resource list --resource-group "$rg" \
    --query "[].{name:name, type:type, location:location, costCenter:tags.costCenter}" --output table
  echo
done
info "No resource has a costCenter tag yet. Continue with Task 1 in the lab README."
