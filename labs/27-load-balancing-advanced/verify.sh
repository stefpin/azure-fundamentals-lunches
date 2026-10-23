#!/usr/bin/env bash
# =============================================================================
# Lab 27 · verify.sh — checks the Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az
load_hosts >/dev/null

banner "Application Gateway ${AGW}"
agw_id="$(az_q network application-gateway show -g "$RG" -n "$AGW" --query id)"
check_nonempty "Application Gateway ${AGW} exists in ${RG}" "$agw_id"
check_eq "SKU is WAF_v2" "WAF_v2" "$(az_q network application-gateway show -g "$RG" -n "$AGW" --query sku.name)"
max_cap="$(az_q network application-gateway show -g "$RG" -n "$AGW" --query autoscaleConfiguration.maxCapacity)"
fixed_cap="$(az_q network application-gateway show -g "$RG" -n "$AGW" --query sku.capacity)"
cap="${max_cap:-$fixed_cap}"
if [[ "$cap" =~ ^[0-9]+$ ]] && ((cap <= 2)); then
  pass "Capacity is kept small for the lab (at most ${cap} instances)"
else
  fail "Capacity should be at most 2 instances in the lab (found '${cap:-not set}')"
fi

banner "WAF policy"
policy_id="$(az_q network application-gateway show -g "$RG" -n "$AGW" --query firewallPolicy.id)"
check_contains "A WAF policy is associated with the gateway" "ApplicationGatewayWebApplicationFirewallPolicies" "$policy_id"
if [[ -n "$policy_id" ]]; then
  check_eq "WAF policy is enabled" "Enabled" \
    "$(az_q network application-gateway waf-policy show --ids "$policy_id" --query policySettings.state)"
  check_eq "WAF policy is in Prevention mode" "Prevention" \
    "$(az_q network application-gateway waf-policy show --ids "$policy_id" --query policySettings.mode)"
  ruleset="$(az_q network application-gateway waf-policy show --ids "$policy_id" \
    --query "join(' ', managedRules.managedRuleSets[].[ruleSetType, ruleSetVersion][])")"
  check_nonempty "WAF policy uses a managed rule set (${ruleset:-none})" "$ruleset"
fi

banner "Backend settings and probe for App Service"
check_ge "Backend settings use HTTPS" 1 \
  "$(az_q network application-gateway http-settings list -g "$RG" --gateway-name "$AGW" --query "length([?protocol=='Https'])")"
check_ge "Backend settings pick the host name from the backend target" 1 \
  "$(az_q network application-gateway http-settings list -g "$RG" --gateway-name "$AGW" --query "length([?pickHostNameFromBackendAddress])")"
check_ge "A custom probe picks the host name from the backend settings" 1 \
  "$(az_q network application-gateway probe list -g "$RG" --gateway-name "$AGW" --query "length([?pickHostNameFromBackendHttpSettings])")"

banner "Path-based routing"
check_contains "A URL path map routes /images/*" "/images/*" \
  "$(az_q network application-gateway url-path-map list -g "$RG" --gateway-name "$AGW" --query "[].pathRules[].paths[]")"
img_pool_id="$(az_q network application-gateway url-path-map list -g "$RG" --gateway-name "$AGW" \
  --query "[0].pathRules[?contains(paths, '/images/*')].backendAddressPool.id | [0]")"
img_pool="${img_pool_id##*/}"
if [[ -n "$img_pool" ]]; then
  check_contains "/images/* goes to a pool that contains the images app" "${IMG_HOST:-app-nusa-img}" \
    "$(az_q network application-gateway address-pool show -g "$RG" --gateway-name "$AGW" -n "$img_pool" --query "backendAddresses[].fqdn")"
else
  fail "/images/* goes to a pool that contains the images app (no pool found for the path)"
fi
check_ge "A request routing rule uses path-based routing" 1 \
  "$(az_q network application-gateway rule list -g "$RG" --gateway-name "$AGW" --query "length([?ruleType=='PathBasedRouting'])")"

banner "Traffic through the gateway"
GW_IP="$(gw_ip)"
if [[ -z "$GW_IP" ]]; then
  fip_id="$(az_q network application-gateway show -g "$RG" -n "$AGW" --query "frontendIPConfigurations[?publicIPAddress] | [0].publicIPAddress.id")"
  [[ -n "$fip_id" ]] && GW_IP="$(az_q network public-ip show --ids "$fip_id" --query ipAddress)"
fi
if [[ -n "$GW_IP" ]]; then
  info "Gateway address: ${GW_IP}"
  home="$(curl -s --max-time 15 "http://${GW_IP}/" || true)"
  check_contains "http://${GW_IP}/ is answered by the storefront app" "STOREFRONT app" "$home"
  images="$(curl -s --max-time 15 "http://${GW_IP}/images/" || true)"
  check_contains "http://${GW_IP}/images/ is answered by the images app" "IMAGES app" "$images"
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "http://${GW_IP}/?id=1%27%20OR%201%3D1--" || true)"
  check_eq "A SQL-injection probe is blocked by the WAF" "403" "$code"
else
  fail "No public IP found for the gateway, so traffic could not be tested"
fi

banner "Traffic Manager ${TM_PROFILE}"
check_eq "Routing method is Priority" "Priority" \
  "$(az_q network traffic-manager profile show -g "$RG" -n "$TM_PROFILE" --query trafficRoutingMethod)"
check_eq "Health checks use HTTPS" "HTTPS" \
  "$(az_q network traffic-manager profile show -g "$RG" -n "$TM_PROFILE" --query monitorConfig.protocol)"
check_ge "The profile has two endpoints" 2 \
  "$(az_q network traffic-manager endpoint list -g "$RG" --profile-name "$TM_PROFILE" --query "length(@)")"
check_eq "Priority 1 is the storefront app" "${STORE_HOST:-<storefront host>}" \
  "$(az_q network traffic-manager endpoint list -g "$RG" --profile-name "$TM_PROFILE" --query "[?priority==\`1\`].target | [0]")"
check_eq "Priority 2 is the images app (the standby)" "${IMG_HOST:-<images host>}" \
  "$(az_q network traffic-manager endpoint list -g "$RG" --profile-name "$TM_PROFILE" --query "[?priority==\`2\`].target | [0]")"
check_contains "The endpoints are external endpoints" "externalEndpoints" \
  "$(az_q network traffic-manager endpoint list -g "$RG" --profile-name "$TM_PROFILE" --query "[].type")"
statuses="$(az_q network traffic-manager endpoint list -g "$RG" --profile-name "$TM_PROFILE" \
  --query "[].[name, endpointMonitorStatus]" | tr '\t\n' ': ')"
info "Endpoint health right now: ${statuses:-unknown}"
if command -v dig >/dev/null 2>&1; then
  info "DNS answer for ${TM_DNS}.trafficmanager.net: $(dig +short "${TM_DNS}.trafficmanager.net" | head -n1)"
fi

banner "Optional · Front Door"
afd_sku="$(az_q afd profile show -g "$RG" --profile-name "$AFD_PROFILE" --query sku.name)"
if [[ -n "$afd_sku" ]]; then
  note "Front Door profile ${AFD_PROFILE} found (${afd_sku}) — not required; it is deleted by cleanup.sh."
else
  info "No Front Door profile (optional Task 9)."
fi

summary
