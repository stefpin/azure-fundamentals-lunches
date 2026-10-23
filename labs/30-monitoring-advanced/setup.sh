#!/usr/bin/env bash
# =============================================================================
# Lab 30 · Why was checkout slow on Friday? — starting point
#
# Creates resource group rg-lunch30-<suffix> with everything the lab monitors:
#   - Log Analytics workspace log-nusa (30-day retention): the evidence room.
#   - VM vm-nusa-app ($VM_SIZE_SMALL, $VM_IMAGE) that plays the order-jobs server.
#     A Standard public IP gives it outbound HTTPS (the monitoring agent needs it);
#     its network security group has NO inbound rules.
#   - Storage account stnusalog<suffix> with container product-images, and the
#     Storage Blob Data Contributor role for you on that account (for traffic.sh).
#   - Linux App Service plan ($APP_SKU) and web app app-nusa30-<suffix> running the
#     small Python storefront in app/ (no monitoring configured yet).
# It also installs or updates the Azure CLI extensions the lab uses.
#
# Takes about 6-10 minutes. Safe to run again: existing resources are kept.
#   bash setup.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Azure CLI extensions"
for ext in monitor-control-service application-insights scheduled-query log-analytics; do
  az extension add --name "$ext" --upgrade --only-show-errors --output none
  info "${ext}: $(az_q extension show --name "$ext" --query version)"
done

banner "Resource group"
ensure_rg "$RG" 30
info "Resource group ${RG} is ready in ${LOCATION}."

banner "Order-jobs VM ${VM} (started in the background)"
vm_started=0
if az vm show --resource-group "$RG" --name "$VM" --output none 2>/dev/null; then
  info "${VM} already exists, keeping it."
  state="$(az_q vm get-instance-view --resource-group "$RG" --name "$VM" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")"
  if [[ "$state" != "VM running" ]]; then
    info "Starting ${VM} (state: ${state:-unknown})..."
    az vm start --resource-group "$RG" --name "$VM" --output none
  fi
else
  info "Creating ${VM} (${VM_SIZE_SMALL}, ${VM_IMAGE}) while the other resources are built..."
  az vm create \
    --resource-group "$RG" \
    --name "$VM" \
    --location "$LOCATION" \
    --image "$VM_IMAGE" \
    --size "$VM_SIZE_SMALL" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --nsg-rule NONE \
    --tags course="$COURSE_TAG" lunch=30 role=order-jobs \
    --no-wait \
    --output none
  vm_started=1
fi

banner "Log Analytics workspace ${LAW}"
if az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --output none 2>/dev/null; then
  info "${LAW} already exists, keeping it."
else
  az monitor log-analytics workspace create \
    --resource-group "$RG" \
    --workspace-name "$LAW" \
    --location "$LOCATION" \
    --retention-time 30 \
    --tags course="$COURSE_TAG" lunch=30 \
    --output none
  info "Created ${LAW} with 30 days of analytics retention."
fi

banner "Storage account ${ST}"
if az storage account show --resource-group "$RG" --name "$ST" --output none 2>/dev/null; then
  info "${ST} already exists, keeping it."
else
  az storage account create \
    --resource-group "$RG" \
    --name "$ST" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --tags course="$COURSE_TAG" lunch=30 \
    --output none
fi
if ! az storage container-rm show --resource-group "$RG" --storage-account "$ST" --name "$CONTAINER" --output none 2>/dev/null; then
  az storage container-rm create --resource-group "$RG" --storage-account "$ST" --name "$CONTAINER" --output none
fi
ST_ID="$(az storage account show --resource-group "$RG" --name "$ST" --query id --output tsv)"
ME="$(my_object_id || true)"
if [[ -z "$ME" ]]; then
  note "Could not read your user object ID; traffic.sh's storage calls may fail with 'AuthorizationPermissionMismatch'."
elif [[ "$(az_q role assignment list --assignee "$ME" --role "Storage Blob Data Contributor" --scope "$ST_ID" --query 'length(@)')" == "0" ]]; then
  if az role assignment create \
       --assignee-object-id "$ME" \
       --assignee-principal-type User \
       --role "Storage Blob Data Contributor" \
       --scope "$ST_ID" \
       --output none; then
    info "Gave you Storage Blob Data Contributor on ${ST} (it can take a few minutes to apply)."
  else
    note "Couldn't assign Storage Blob Data Contributor (you need Owner or User Access Administrator)."
    note "traffic.sh's storage calls will then fail, but the failures still appear in StorageBlobLogs."
  fi
else
  info "You already have Storage Blob Data Contributor on ${ST}."
fi

banner "Storefront web app ${APP}"
if az appservice plan show --resource-group "$RG" --name "$PLAN" --output none 2>/dev/null; then
  info "Plan ${PLAN} already exists, keeping it."
else
  az appservice plan create --resource-group "$RG" --name "$PLAN" --location "$LOCATION" \
    --is-linux --sku "$APP_SKU" --tags course="$COURSE_TAG" lunch=30 --output none
fi
if az webapp show --resource-group "$RG" --name "$APP" --output none 2>/dev/null; then
  info "Web app ${APP} already exists, redeploying the code."
else
  az webapp create --resource-group "$RG" --name "$APP" --plan "$PLAN" --runtime "$RUNTIME" \
    --tags course="$COURSE_TAG" lunch=30 --output none
fi
az webapp config appsettings set --resource-group "$RG" --name "$APP" \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true --output none
az webapp update --resource-group "$RG" --name "$APP" --https-only true --output none

mkdir -p "$OUT_DIR"
rm -f "${OUT_DIR}/storefront.zip"
(cd "${LAB_DIR}/app" && python3 -m zipfile -c "${OUT_DIR}/storefront.zip" app.py requirements.txt)
info "Deploying the storefront (the build installs Flask; about 1-3 minutes)..."
if ! az webapp deploy --resource-group "$RG" --name "$APP" \
     --src-path "${OUT_DIR}/storefront.zip" --type zip --output none; then
  note "The deployment didn't report success (a slow build can time out). Waiting for the app anyway;"
  note "if it never answers, run 'bash setup.sh' again."
fi

HOST="$(az webapp show --resource-group "$RG" --name "$APP" --query defaultHostName --output tsv)"
if wait_until "the storefront to answer" 300 curl -fsS --max-time 10 "https://${HOST}/health"; then
  info "The storefront answers at https://${HOST}"
else
  note "The storefront isn't answering yet. Give it two minutes, then open https://${HOST}/health"
fi

banner "Waiting for ${VM}"
if (( vm_started == 1 )); then
  az vm wait --resource-group "$RG" --name "$VM" --created --timeout 900
fi
az vm show --resource-group "$RG" --name "$VM" --output none
info "${VM} is ready."

banner "Done"
info "Workspace:  ${LAW}"
info "VM:         ${VM}"
info "Storage:    ${ST} (container ${CONTAINER})"
info "Storefront: https://${HOST}"
info "Nothing is monitored yet: no agent, no data collection rule, no diagnostic setting, no Application Insights."
echo
info "Next: continue with Task 1 in README.md."
info "Remember: the VM and the App Service plan cost money while they exist. Finish with: bash cleanup.sh"
