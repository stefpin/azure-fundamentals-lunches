#!/usr/bin/env bash
# =============================================================================
# Lab 19 · setup.sh — creates three cheap pieces of deliberate waste.
#
#   disk-nusa-orphan   unattached Standard HDD managed disk (32 GiB, the smallest billing tier)
#   pip-nusa-orphan    Standard public IP address that isn't associated with anything
#   asp-nusa-idle      App Service plan with no apps (Basic B1 on Linux; Free F1 if B1 isn't available)
#
# Every resource is tagged costCenter=retail-lab. Takes about 2 minutes and is safe to re-run.
# The waste costs a little every hour until you delete it in Task 7 (or run cleanup.sh).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 19)"
TAG="costCenter=retail-lab"
DISK="disk-nusa-orphan"
PIP="pip-nusa-orphan"
PLAN="asp-nusa-idle"

# exists <az list arguments...>  -> true when the list query returns a name
exists() { [[ -n "$(az_q "$@")" ]]; }

banner "Resource group ${RG} in ${LOCATION}"
ensure_rg "$RG" 19
# Merge the cost tag onto the group as well (the course and lunch tags stay in place).
az tag update --resource-id "$(az group show --name "$RG" --query id --output tsv)" \
  --operation Merge --tags "$TAG" --output none
info "Tagged the resource group with ${TAG}."

banner "Waste 1/3 · an unattached managed disk"
if exists disk list --resource-group "$RG" --query "[?name=='${DISK}'].name | [0]"; then
  info "${DISK} already exists."
else
  az disk create --resource-group "$RG" --name "$DISK" --location "$LOCATION" \
    --size-gb 32 --sku Standard_LRS --tags "$TAG" --output none
  info "Created ${DISK}: Standard HDD, 32 GiB, attached to nothing."
fi

banner "Waste 2/3 · an unassociated Standard public IP"
if exists network public-ip list --resource-group "$RG" --query "[?name=='${PIP}'].name | [0]"; then
  info "${PIP} already exists."
else
  az network public-ip create --resource-group "$RG" --name "$PIP" --location "$LOCATION" \
    --sku Standard --allocation-method Static --tags "$TAG" --output none
  info "Created ${PIP}: Standard, static, associated with nothing."
fi

banner "Waste 3/3 · an App Service plan with no apps"
if exists appservice plan list --resource-group "$RG" --query "[?name=='${PLAN}'].name | [0]"; then
  info "${PLAN} already exists."
elif az appservice plan create --resource-group "$RG" --name "$PLAN" --location "$LOCATION" \
       --sku B1 --is-linux --tags "$TAG" --output none 2>/dev/null; then
  info "Created ${PLAN}: Basic B1 on Linux, zero apps."
elif az appservice plan create --resource-group "$RG" --name "$PLAN" --location "$LOCATION" \
       --sku F1 --is-linux --tags "$TAG" --output none; then
  note "Basic B1 isn't available to your subscription in ${LOCATION}, so ${PLAN} uses the Free tier (F1)."
  note "A Free plan costs nothing, but the hunt works exactly the same."
else
  note "Could not create an App Service plan in ${LOCATION}. Continue with the disk and the public IP."
fi

banner "Done — the waste is in place"
az resource list --resource-group "$RG" \
  --query "[].{name:name, type:type, costCenter:tags.costCenter}" --output table
info "Next: Task 1 in the README. These resources cost a little every hour until you delete them."
