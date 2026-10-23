#!/usr/bin/env bash
# =============================================================================
# Lab 20 · verify.sh — checks the Challenge brief as it stands at the end of Task 6:
#   * a storage account, a virtual network with snet-web (with an NSG that allows TCP 80 in) and
#     snet-app, and a Log Analytics workspace in the lab resource group
#   * every resource tagged costCenter=retail-lab and with an environment tag
#   * a deployment stack with deny settings mode denyDelete and action on unmanage deleteResources
#     that manages the storage account
# Read-only: it changes nothing. Task 7 deletes the stack and its resources, so run this before Task 7.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 20)"

banner "Lab resource group"
if [[ "$(az_q group exists --name "$RG")" != "true" ]]; then
  fail "Resource group ${RG} not found — create it in Task 1 (or cleanup.sh already ran)"
  summary
  exit $?
fi
pass "Resource group ${RG} exists"

storage="$(az_q storage account list --resource-group "$RG" --query "[0].name")"
vnet="$(az_q network vnet list --resource-group "$RG" --query "[?subnets[?name=='snet-web']].name | [0]")"
workspace="$(az_q monitor log-analytics workspace list --resource-group "$RG" --query "[0].name")"
stack="$(az_q stack group list --resource-group "$RG" --query "[0].name")"
others="$(az_q resource list --resource-group "$RG" --query "length(@)")"

if [[ -z "${storage}${vnet}${workspace}${stack}" && "${others:-0}" == "0" ]]; then
  fail "Nothing from main.bicep is deployed in ${RG}"
  info "Not deployed yet? Complete Tasks 2 to 6 first."
  info "Already did Task 7? Deleting the stack removed every resource. verify.sh checks the state at the end"
  info "of Task 6: run the 'az stack group create' command from Task 6 again, then run verify.sh."
  summary
  exit $?
fi

banner "Resources from main.bicep (Tasks 2-4)"
check_nonempty "Storage account in ${RG}" "$storage"
if [[ -n "$storage" ]]; then
  check_eq "Storage account ${storage} uses Standard_LRS" "Standard_LRS" \
    "$(az_q storage account show --resource-group "$RG" --name "$storage" --query "sku.name")"
  check_eq "Storage account ${storage} is StorageV2" "StorageV2" \
    "$(az_q storage account show --resource-group "$RG" --name "$storage" --query "kind")"
fi

check_nonempty "Virtual network with a subnet named snet-web" "$vnet"
if [[ -n "$vnet" ]]; then
  check_eq "Virtual network ${vnet} has two subnets" "2" \
    "$(az_q network vnet show --resource-group "$RG" --name "$vnet" --query "length(subnets)")"
  check_eq "Virtual network ${vnet} has a subnet named snet-app" "snet-app" \
    "$(az_q network vnet show --resource-group "$RG" --name "$vnet" --query "subnets[?name=='snet-app'].name | [0]")"
  web_nsg="$(az_q network vnet show --resource-group "$RG" --name "$vnet" \
    --query "subnets[?name=='snet-web'].networkSecurityGroup.id | [0]")"
  check_nonempty "snet-web has a network security group" "$web_nsg"
  if [[ -n "$web_nsg" ]]; then
    http_rules="$(az_q network nsg show --ids "$web_nsg" \
      --query "length(securityRules[?access=='Allow' && direction=='Inbound' && (destinationPortRange=='80' || contains(destinationPortRanges || \`[]\`, '80'))])")"
    check_ge "The NSG on snet-web allows inbound traffic to port 80" 1 "$http_rules"
  fi
fi

check_nonempty "Log Analytics workspace in ${RG}" "$workspace"

banner "Tags (Tasks 4-5)"
tag_rows="$(az_q resource list --resource-group "$RG" \
  --query "[].join('|', [name, tags.costCenter || '-', tags.environment || '-'])")"
if [[ -z "$tag_rows" ]]; then
  fail "No resources found in ${RG} to check tags on"
fi
while IFS='|' read -r name cost_center environment; do
  [[ -z "$name" ]] && continue
  check_eq "${name} has the tag costCenter=retail-lab" "retail-lab" "$cost_center"
  if [[ "$environment" == "-" || -z "$environment" ]]; then
    fail "${name} has an environment tag (add it to the tags in main.bicep — see Task 5)"
  else
    pass "${name} has the tag environment=${environment}"
  fi
done <<< "$tag_rows"

banner "Deployment stack (Task 6)"
if [[ -z "$stack" ]]; then
  fail "A deployment stack in ${RG} (create it in Task 6 with az stack group create)"
else
  pass "Deployment stack ${stack} exists"
  mode="$(az_q stack group show --resource-group "$RG" --name "$stack" \
    --query "denySettings.mode || properties.denySettings.mode")"
  check_eq "Stack ${stack} uses deny settings mode denyDelete" "denyDelete" "$mode"
  unmanage="$(az_q stack group show --resource-group "$RG" --name "$stack" \
    --query "actionOnUnmanage.resources || properties.actionOnUnmanage.resources")"
  check_eq "Stack ${stack} deletes resources that leave the file (action on unmanage)" "delete" "$unmanage"
  if [[ -n "$storage" ]]; then
    managed="$(az_q stack group show --resource-group "$RG" --name "$stack" \
      --query "(resources || properties.resources)[].id")"
    check_contains "Stack ${stack} manages storage account ${storage}" "/storageAccounts/${storage}" "$managed"
  fi
fi

summary
