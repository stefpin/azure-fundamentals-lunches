#!/usr/bin/env bash
# =============================================================================
# Lab 13 · Package the storefront — reference solution for Tasks 1–5.
#   bash solution.sh
# Safe to re-run: every step checks what already exists before creating it.
# The Break-it-and-fix-it exercise is not included.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 13)"
ACR_NAME="acrnusa${SUFFIX}"
ACI_NAME="ci-nusa-storefront"
ENV_NAME="cae-nusa"
APP="ca-nusa-storefront"
SAMPLE_IMAGE="mcr.microsoft.com/azuredocs/aks-helloworld:v1"

banner "Preparing: resource providers and resource group"
for ns in Microsoft.ContainerRegistry Microsoft.ContainerInstance Microsoft.App Microsoft.OperationalInsights; do
  info "Registering ${ns} (no-op if already registered)..."
  az provider register --namespace "$ns" --wait --output none
done
ensure_rg "$RG" 13
info "Resource group: ${RG} (${LOCATION})"

# -----------------------------------------------------------------------------
banner "Task 1 · Registry and storefront image"
if ! az acr show --name "$ACR_NAME" --resource-group "$RG" --output none 2>/dev/null; then
  info "Creating registry ${ACR_NAME} (Basic)..."
  az acr create --resource-group "$RG" --name "$ACR_NAME" --sku Basic --location "$LOCATION" --output none
fi
LOGIN_SERVER="$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)"
ACR_ID="$(az acr show --name "$ACR_NAME" --query id --output tsv)"

if az acr repository show-tags --name "$ACR_NAME" --repository storefront --output tsv 2>/dev/null | grep -qx "v1"; then
  info "storefront:v1 is already in the registry."
else
  info "Importing ${SAMPLE_IMAGE} as storefront:v1..."
  az acr import --name "$ACR_NAME" --source "$SAMPLE_IMAGE" --image storefront:v1 --output none
fi
info "Image: ${LOGIN_SERVER}/storefront:v1"

# -----------------------------------------------------------------------------
banner "Task 2 · Container Instances"
if ! az container show --resource-group "$RG" --name "$ACI_NAME" --output none 2>/dev/null; then
  info "Creating container group ${ACI_NAME}..."
  az container create \
    --resource-group "$RG" \
    --name "$ACI_NAME" \
    --image "$SAMPLE_IMAGE" \
    --os-type Linux \
    --cpu 1 --memory 1.5 \
    --ports 80 \
    --dns-name-label "nusa-store-${SUFFIX}" \
    --environment-variables TITLE="Nusantara Retail storefront on Container Instances" \
    --output none
fi
ACI_FQDN="$(az container show --resource-group "$RG" --name "$ACI_NAME" --query ipAddress.fqdn --output tsv)"
info "Container Instances: http://${ACI_FQDN}"

# -----------------------------------------------------------------------------
banner "Task 3 · Container Apps environment and app"
if ! az containerapp env show --name "$ENV_NAME" --resource-group "$RG" --output none 2>/dev/null; then
  info "Creating environment ${ENV_NAME} (2–4 minutes)..."
  az containerapp env create --name "$ENV_NAME" --resource-group "$RG" --location "$LOCATION" --output none
fi

# The documented step-by-step path, used only if the one-step create fails:
# start from a public image, give the system-assigned identity AcrPull, then switch to the private image.
create_step_by_step() {
  if ! az containerapp show --name "$APP" --resource-group "$RG" --output none 2>/dev/null; then
    az containerapp create \
      --name "$APP" --resource-group "$RG" --environment "$ENV_NAME" \
      --image "$SAMPLE_IMAGE" \
      --ingress external --target-port 80 \
      --min-replicas 0 --max-replicas 5 \
      --scale-rule-name http-busy --scale-rule-type http --scale-rule-http-concurrency 10 \
      --env-vars TITLE="Nusantara Retail storefront v1" \
      --output none
  fi
  az containerapp identity assign --name "$APP" --resource-group "$RG" --system-assigned --output none
  local principal
  principal="$(az containerapp show --name "$APP" --resource-group "$RG" --query identity.principalId --output tsv)"
  az role assignment create --assignee-object-id "$principal" --assignee-principal-type ServicePrincipal \
    --role AcrPull --scope "$ACR_ID" --output none || true
  info "Waiting 60 seconds for the role assignment to propagate..."
  sleep 60
  az containerapp registry set --name "$APP" --resource-group "$RG" \
    --server "$LOGIN_SERVER" --identity system --output none
  az containerapp update --name "$APP" --resource-group "$RG" \
    --image "${LOGIN_SERVER}/storefront:v1" --output none
}

if ! az containerapp show --name "$APP" --resource-group "$RG" --output none 2>/dev/null; then
  info "Creating container app ${APP} from your registry (system-assigned identity)..."
  if ! az containerapp create \
      --name "$APP" \
      --resource-group "$RG" \
      --environment "$ENV_NAME" \
      --image "${LOGIN_SERVER}/storefront:v1" \
      --registry-server "$LOGIN_SERVER" \
      --registry-identity system \
      --ingress external \
      --target-port 80 \
      --min-replicas 0 \
      --max-replicas 5 \
      --scale-rule-name http-busy \
      --scale-rule-type http \
      --scale-rule-http-concurrency 10 \
      --env-vars TITLE="Nusantara Retail storefront v1" \
      --output none; then
    note "The one-step create failed; switching to the step-by-step path."
    create_step_by_step
  fi
fi

current_image="$(az_q containerapp show --name "$APP" --resource-group "$RG" --query "properties.template.containers[0].image")"
if [[ "$current_image" != "${LOGIN_SERVER}/storefront:"* ]]; then
  note "The app does not run an image from your registry yet (${current_image:-unknown}); fixing that."
  create_step_by_step
fi

FQDN="$(az containerapp show --name "$APP" --resource-group "$RG" --query properties.configuration.ingress.fqdn --output tsv)"
info "Container app: https://${FQDN}"
info "First request (may include a cold start):"
curl -s --max-time 60 "https://${FQDN}/" | grep -o "<title>[^<]*</title>" || note "No answer yet; try again in a minute."

# -----------------------------------------------------------------------------
banner "Task 4 · A short load test (about 90 seconds)"
end=$((SECONDS + 90))
while (( SECONDS < end )); do
  seq 1 400 | xargs -P 40 -I{} curl -s -o /dev/null --max-time 30 "https://${FQDN}/" || true
done &
load_pid=$!
for i in 1 2 3 4 5 6; do
  sleep 15
  info "$(date +%T)  replicas: $(az_q containerapp replica list --name "$APP" --resource-group "$RG" --query 'length(@)')"
done
wait "$load_pid" || true
info "Replicas fall back to 0 about 5–10 minutes after the load stops (300-second cool-down)."

# -----------------------------------------------------------------------------
banner "Task 5 · Two revisions and an 80/20 split"
mode="$(az containerapp show --name "$APP" --resource-group "$RG" --query properties.configuration.activeRevisionsMode --output tsv)"
if [[ "${mode,,}" != "multiple" ]]; then
  az containerapp revision set-mode --name "$APP" --resource-group "$RG" --mode multiple --output none
fi

REV2="${APP}--v2"
if az containerapp revision show --name "$APP" --resource-group "$RG" --revision "$REV2" --output none 2>/dev/null; then
  # v2 already exists (re-run): v1 is the newest other active revision.
  REV1="$(az containerapp revision list --name "$APP" --resource-group "$RG" \
    --query "sort_by([?name!='${REV2}' && properties.active], &properties.createdTime)[-1].name" --output tsv)"
else
  REV1="$(az containerapp show --name "$APP" --resource-group "$RG" --query properties.latestRevisionName --output tsv)"
  info "Pinning 100% of traffic to ${REV1} before deploying v2..."
  az containerapp ingress traffic set --name "$APP" --resource-group "$RG" --revision-weight "${REV1}=100" --output none
  info "Deploying revision ${REV2}..."
  az containerapp update --name "$APP" --resource-group "$RG" \
    --set-env-vars TITLE="Nusantara Retail storefront v2" \
    --revision-suffix v2 \
    --output none
fi

info "Splitting traffic: ${REV1}=80, ${REV2}=20"
az containerapp ingress traffic set --name "$APP" --resource-group "$RG" \
  --revision-weight "${REV1}=80" "${REV2}=20" --output none

az containerapp revision list --name "$APP" --resource-group "$RG" \
  --query "[].{revision:name, active:properties.active, traffic:properties.trafficWeight}" --output table

info "Sampling 20 requests:"
for i in $(seq 1 20); do
  curl -s --max-time 60 "https://${FQDN}/" | grep -o "<title>[^<]*</title>" || true
done | sort | uniq -c

banner "Done"
info "Run 'bash verify.sh' to check your work, then 'bash cleanup.sh' when you are finished."
