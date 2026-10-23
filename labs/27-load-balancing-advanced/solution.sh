#!/usr/bin/env bash
# =============================================================================
# Lab 27 · solution.sh — reference solution for Tasks 2–7 (run setup.sh first)
#
#   WAF policy (DRS 2.2, Detection, then Prevention) · public IP · Application Gateway
#   WAF_v2 (autoscale 1–2) · HTTPS backend settings that pick the host name from the
#   backend target + custom probe · /images/* path rule · Traffic Manager priority profile
#   with two external endpoints.
#
# Takes 10–20 minutes, mostly waiting for the gateway. Safe to run again.
#     bash solution.sh
#     WITH_FRONT_DOOR=1 bash solution.sh      # also builds the optional Front Door (Task 9)
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

load_hosts
if [[ -z "${STORE_HOST}" || -z "${IMG_HOST}" ]]; then
  echo "The starting point is missing. Run: bash setup.sh"
  exit 1
fi

banner "Task 2 · WAF policy ${WAF_POLICY} (Detection first)"
if [[ -z "$(az_q network application-gateway waf-policy show -g "$RG" -n "$WAF_POLICY" --query id)" ]]; then
  if ! az network application-gateway waf-policy create -g "$RG" -n "$WAF_POLICY" -l "$LOCATION" \
      --type Microsoft_DefaultRuleSet --version 2.2 --output none; then
    note "DRS 2.2 was refused here; falling back to DRS 2.1."
    az network application-gateway waf-policy create -g "$RG" -n "$WAF_POLICY" -l "$LOCATION" \
      --type Microsoft_DefaultRuleSet --version 2.1 --output none
  fi
fi
az network application-gateway waf-policy policy-setting update -g "$RG" --policy-name "$WAF_POLICY" \
  --mode Detection --state Enabled --request-body-check true --output none

banner "Task 3 · Public IP ${PIP_AGW} and Application Gateway ${AGW} (5–15 minutes)"
if [[ -z "$(az_q network public-ip show -g "$RG" -n "$PIP_AGW" --query id)" ]]; then
  az network public-ip create -g "$RG" -n "$PIP_AGW" -l "$LOCATION" \
    --sku Standard --allocation-method Static --output none
fi
if [[ -z "$(az_q network application-gateway show -g "$RG" -n "$AGW" --query id)" ]]; then
  az network application-gateway create -g "$RG" -n "$AGW" -l "$LOCATION" \
    --sku WAF_v2 --min-capacity 1 --max-capacity 2 \
    --vnet-name "$VNET" --subnet "$SUBNET_AGW" \
    --public-ip-address "$PIP_AGW" --waf-policy "$WAF_POLICY" \
    --frontend-port 80 --http-settings-protocol Https --http-settings-port 443 \
    --servers "$STORE_HOST" --priority 100 --output none
fi
info "Gateway state: $(az_q network application-gateway show -g "$RG" -n "$AGW" --query operationalState)"

banner "Task 4 · Custom probe and host-name override for App Service"
if [[ -z "$(az_q network application-gateway probe show -g "$RG" --gateway-name "$AGW" -n "$PROBE_AGW" --query id)" ]]; then
  az network application-gateway probe create -g "$RG" --gateway-name "$AGW" -n "$PROBE_AGW" \
    --protocol Https --path / --host-name-from-http-settings true \
    --interval 30 --timeout 30 --threshold 3 --output none
fi
az network application-gateway http-settings update -g "$RG" --gateway-name "$AGW" \
  -n appGatewayBackendHttpSettings --host-name-from-backend-pool true --probe "$PROBE_AGW" --output none

banner "Task 5 · Path-based routing: /images/* -> ${APP_IMG}"
if [[ -z "$(az_q network application-gateway address-pool show -g "$RG" --gateway-name "$AGW" -n "$POOL_IMG" --query id)" ]]; then
  az network application-gateway address-pool create -g "$RG" --gateway-name "$AGW" -n "$POOL_IMG" \
    --servers "$IMG_HOST" --output none
fi
if [[ -z "$(az_q network application-gateway url-path-map show -g "$RG" --gateway-name "$AGW" -n "$PATH_MAP" --query id)" ]]; then
  az network application-gateway url-path-map create -g "$RG" --gateway-name "$AGW" -n "$PATH_MAP" \
    --rule-name images --paths "/images/*" \
    --address-pool "$POOL_IMG" --http-settings appGatewayBackendHttpSettings \
    --default-address-pool appGatewayBackendPool --default-http-settings appGatewayBackendHttpSettings \
    --output none
fi
az network application-gateway rule update -g "$RG" --gateway-name "$AGW" -n rule1 \
  --rule-type PathBasedRouting --url-path-map "$PATH_MAP" --output none

banner "Task 6 · WAF in Prevention mode"
az network application-gateway waf-policy policy-setting update -g "$RG" --policy-name "$WAF_POLICY" \
  --mode Prevention --state Enabled --request-body-check true --output none
info "Give it a minute or two, then test: curl -s -o /dev/null -w '%{http_code}\\n' \"http://$(gw_ip)/?id=1%27%20OR%201%3D1--\""

banner "Task 7 · Traffic Manager ${TM_PROFILE} (Priority, external endpoints)"
if [[ -z "$(az_q network traffic-manager profile show -g "$RG" -n "$TM_PROFILE" --query id)" ]]; then
  az network traffic-manager profile create -g "$RG" -n "$TM_PROFILE" \
    --routing-method Priority --unique-dns-name "$TM_DNS" --ttl 30 \
    --protocol HTTPS --port 443 --path "/" --interval 10 --timeout 9 --max-failures 2 --output none
fi
if [[ -z "$(az_q network traffic-manager endpoint show -g "$RG" --profile-name "$TM_PROFILE" -n ep-store --type ExternalEndpoints --query id)" ]]; then
  az network traffic-manager endpoint create -g "$RG" --profile-name "$TM_PROFILE" -n ep-store \
    --type externalEndpoints --target "$STORE_HOST" --priority 1 --endpoint-status Enabled --output none
fi
if [[ -z "$(az_q network traffic-manager endpoint show -g "$RG" --profile-name "$TM_PROFILE" -n ep-images --type ExternalEndpoints --query id)" ]]; then
  az network traffic-manager endpoint create -g "$RG" --profile-name "$TM_PROFILE" -n ep-images \
    --type externalEndpoints --target "$IMG_HOST" --priority 2 --endpoint-status Enabled --output none
fi

if [[ "${WITH_FRONT_DOOR:-0}" == "1" ]]; then
  banner "Task 9 (optional) · Front Door Standard in front of the storefront"
  az provider register -n Microsoft.Cdn --wait --output none
  if [[ -z "$(az_q afd profile show -g "$RG" --profile-name "$AFD_PROFILE" --query id)" ]]; then
    az afd profile create -g "$RG" --profile-name "$AFD_PROFILE" --sku Standard_AzureFrontDoor --output none
  fi
  if [[ -z "$(az_q afd endpoint show -g "$RG" --profile-name "$AFD_PROFILE" --endpoint-name "$AFD_ENDPOINT" --query id)" ]]; then
    az afd endpoint create -g "$RG" --profile-name "$AFD_PROFILE" --endpoint-name "$AFD_ENDPOINT" \
      --enabled-state Enabled --output none
  fi
  if [[ -z "$(az_q afd origin-group show -g "$RG" --profile-name "$AFD_PROFILE" --origin-group-name og-storefront --query id)" ]]; then
    az afd origin-group create -g "$RG" --profile-name "$AFD_PROFILE" --origin-group-name og-storefront \
      --probe-request-type GET --probe-protocol Https --probe-interval-in-seconds 60 --probe-path / \
      --sample-size 4 --successful-samples-required 3 --additional-latency-in-milliseconds 50 --output none
  fi
  if [[ -z "$(az_q afd origin show -g "$RG" --profile-name "$AFD_PROFILE" --origin-group-name og-storefront --origin-name storefront --query id)" ]]; then
    az afd origin create -g "$RG" --profile-name "$AFD_PROFILE" --origin-group-name og-storefront \
      --origin-name storefront --host-name "$STORE_HOST" --origin-host-header "$STORE_HOST" \
      --priority 1 --weight 1000 --enabled-state Enabled --http-port 80 --https-port 443 --output none
  fi
  if [[ -z "$(az_q afd route show -g "$RG" --profile-name "$AFD_PROFILE" --endpoint-name "$AFD_ENDPOINT" --route-name route-default --query id)" ]]; then
    az afd route create -g "$RG" --profile-name "$AFD_PROFILE" --endpoint-name "$AFD_ENDPOINT" \
      --route-name route-default --origin-group og-storefront --supported-protocols Http Https \
      --forwarding-protocol HttpsOnly --https-redirect Enabled --link-to-default-domain Enabled --output none
  fi
  info "Front Door endpoint: https://$(az_q afd endpoint show -g "$RG" --profile-name "$AFD_PROFILE" --endpoint-name "$AFD_ENDPOINT" --query hostName) (allow several minutes to propagate)"
fi

banner "Done"
info "Gateway       : http://$(gw_ip)/  and  http://$(gw_ip)/images/"
info "Traffic Mgr   : ${TM_DNS}.trafficmanager.net  (try: dig +short ${TM_DNS}.trafficmanager.net)"
info "Next          : bash verify.sh   (then bash cleanup.sh)"
