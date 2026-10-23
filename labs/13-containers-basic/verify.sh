#!/usr/bin/env bash
# =============================================================================
# Lab 13 · Package the storefront — checks the Challenge brief.
#   bash verify.sh
# Read-only: it creates and changes nothing. Every check prints PASS or FAIL.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 13)"
ACR_NAME="acrnusa${SUFFIX}"
ACI_NAME="ci-nusa-storefront"
ENV_NAME="cae-nusa"
APP="ca-nusa-storefront"

banner "Resource group"
check "Resource group ${RG} exists (Task 1)" az group show --name "$RG"

banner "Task 1 · Container registry"
acr_sku="$(az_q acr show --name "$ACR_NAME" --resource-group "$RG" --query sku.name)"
check_nonempty "Registry ${ACR_NAME} exists (tier: ${acr_sku:-none})" "$acr_sku"
login_server="$(az_q acr show --name "$ACR_NAME" --resource-group "$RG" --query loginServer)"
admin="$(az_q acr show --name "$ACR_NAME" --resource-group "$RG" --query adminUserEnabled)"
check_eq "Registry admin user is disabled" "false" "$admin"
tags="$(az_q acr repository show-tags --name "$ACR_NAME" --repository storefront)"
if grep -qx "v1" <<<"$tags"; then
  pass "Image storefront:v1 is in the registry"
else
  fail "Image storefront:v1 is in the registry (run the az acr import step in Task 1)"
fi

banner "Task 2 · Container Instances"
aci_state="$(az_q container show --resource-group "$RG" --name "$ACI_NAME" --query instanceView.state)"
check_eq "Container group ${ACI_NAME} is running" "Running" "$aci_state"
aci_fqdn="$(az_q container show --resource-group "$RG" --name "$ACI_NAME" --query ipAddress.fqdn)"
check_nonempty "Container group has a public DNS name" "$aci_fqdn"
if [[ -n "$aci_fqdn" ]]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "http://${aci_fqdn}/" || true)"
  check_eq "http://${aci_fqdn} answers with HTTP 200" "200" "$code"
fi

banner "Task 3 · Container Apps environment and app"
env_state="$(az_q containerapp env show --name "$ENV_NAME" --resource-group "$RG" --query properties.provisioningState)"
check_eq "Container Apps environment ${ENV_NAME} is provisioned" "Succeeded" "$env_state"

app_name="$(az_q containerapp show --name "$APP" --resource-group "$RG" --query name)"
if [[ -z "$app_name" ]]; then
  fail "Container app ${APP} exists (Task 3) — skipping the remaining app checks"
else
  pass "Container app ${APP} exists"
  q() { az_q containerapp show --name "$APP" --resource-group "$RG" --query "$1"; }

  check_eq "Ingress is external" "true" "$(q properties.configuration.ingress.external)"
  check_eq "Ingress target port is 80, the port the image listens on" "80" "$(q properties.configuration.ingress.targetPort)"

  image="$(q 'properties.template.containers[0].image')"
  if [[ -n "$login_server" ]]; then
    check_contains "The app runs an image from your registry" "${login_server}/storefront" "$image"
    reg_identity="$(q "properties.configuration.registries[?server=='${login_server}'] | [0].identity")"
    check_eq "The app pulls from your registry with its system-assigned identity" "system" "$reg_identity"
  else
    fail "The app runs an image from your registry (registry not found)"
  fi
  check_eq "The app has a system-assigned identity" "SystemAssigned" "$(q identity.type | sed 's/, *UserAssigned//')"

  min_replicas="$(q properties.template.scale.minReplicas)"
  check_eq "Minimum replicas is 0 (scale to zero)" "0" "${min_replicas:-0}"
  check_eq "Maximum replicas is 5" "5" "$(q properties.template.scale.maxReplicas)"
  check_ge "At least one HTTP scale rule" 1 "$(q 'length(properties.template.scale.rules[?http] || `[]`)')"

  banner "Task 5 · Revisions and traffic split"
  check_eq "Revision mode is Multiple" "Multiple" "$(q properties.configuration.activeRevisionsMode)"
  active="$(az_q containerapp revision list --name "$APP" --resource-group "$RG" --query 'length([?properties.active])')"
  check_ge "At least two active revisions" 2 "$active"

  mapfile -t weights < <(q 'properties.configuration.ingress.traffic[?weight > `0`].weight' | sort -n)
  check_eq "Traffic is split 80/20" "20 80" "${weights[*]}"

  latest="$(q properties.latestRevisionName)"
  rev20="$(q 'properties.configuration.ingress.traffic[?weight == `20`] | [0].revisionName')"
  latest20="$(q 'properties.configuration.ingress.traffic[?weight == `20`] | [0].latestRevision')"
  if [[ "${latest20,,}" == "true" || ( -n "$rev20" && "$rev20" == "$latest" ) ]]; then
    pass "The 20% share goes to the newest revision (${latest})"
  else
    fail "The 20% share goes to the newest revision (expected '${latest}', got '${rev20:-<none>}')"
  fi
  title="$(q "properties.template.containers[0].env[?name=='TITLE'] | [0].value")"
  check_nonempty "The newest revision sets the TITLE environment variable" "$title"

  banner "End to end"
  fqdn="$(q properties.configuration.ingress.fqdn)"
  if [[ -n "$fqdn" ]]; then
    info "Calling https://${fqdn} (allow up to a minute for a cold start)..."
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 "https://${fqdn}/" || true)"
    check_eq "https://${fqdn} answers with HTTP 200" "200" "$code"
  else
    fail "The app has a public FQDN"
  fi
fi

summary
