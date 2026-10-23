#!/usr/bin/env bash
# =============================================================================
# Lab 09 · verify.sh — checks the Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Load balancer ${LB} in ${RG}"
lb_id="$(az_q network lb show -g "$RG" -n "$LB" --query id)"
check_nonempty "Load balancer ${LB} exists" "$lb_id"
check_eq "It uses the Standard SKU" "Standard" "$(az_q network lb show -g "$RG" -n "$LB" --query sku.name)"

banner "Frontend"
pip_id="$(az_q network lb show -g "$RG" -n "$LB" --query 'frontendIPConfigurations[0].publicIPAddress.id')"
check_nonempty "The frontend uses a public IP address (public load balancer)" "$pip_id"
LB_IP=""
if [[ -n "$pip_id" ]]; then
  check_eq "The frontend public IP is Standard SKU" "Standard" "$(az_q network public-ip show --ids "$pip_id" --query sku.name)"
  zones="$(az_q network public-ip show --ids "$pip_id" --query 'length(zones || `[]`)')"
  if [[ "$zones" == "3" ]]; then
    pass "The frontend public IP is zone-redundant (zones 1, 2, 3)"
  elif [[ "$zones" == "0" ]]; then
    pass "The frontend public IP is not pinned to a zone (zone-redundant in regions with zones)"
  else
    fail "The frontend public IP is zonal (pinned to one zone) — create it with --zone 1 2 3"
  fi
  LB_IP="$(az_q network public-ip show --ids "$pip_id" --query ipAddress)"
  info "Frontend IP address: ${LB_IP:-<none>}"
fi

banner "Health probe ${PROBE}"
check_eq "Probe protocol is HTTP" "Http" "$(az_q network lb probe show -g "$RG" --lb-name "$LB" -n "$PROBE" --query protocol)"
check_eq "Probe port is 80" "80" "$(az_q network lb probe show -g "$RG" --lb-name "$LB" -n "$PROBE" --query port)"
check_eq "Probe path is /health" "/health" "$(az_q network lb probe show -g "$RG" --lb-name "$LB" -n "$PROBE" --query requestPath)"

banner "Load-balancing rule ${RULE}"
check_eq "Rule protocol is TCP" "Tcp" "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query protocol)"
check_eq "Rule frontend port is 80" "80" "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query frontendPort)"
check_eq "Rule backend port is 80" "80" "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query backendPort)"
check_contains "Rule uses the health probe ${PROBE}" "/probes/${PROBE}" \
  "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query probe.id)"
check_eq "Outbound SNAT is disabled on the rule (an outbound rule handles it)" "true" \
  "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query disableOutboundSnat)"

banner "Backend pool ${POOL}"
check_ge "The backend pool has two members" 2 \
  "$(az_q network lb address-pool show -g "$RG" --lb-name "$LB" -n "$POOL" --query 'length(backendIPConfigurations || `[]`)')"

banner "Inbound NAT rule ${NAT_RULE}"
check_eq "Frontend port is ${NAT_PORT}" "$NAT_PORT" \
  "$(az_q network lb inbound-nat-rule show -g "$RG" --lb-name "$LB" -n "$NAT_RULE" --query frontendPort)"
check_eq "Backend port is 22 (SSH)" "22" \
  "$(az_q network lb inbound-nat-rule show -g "$RG" --lb-name "$LB" -n "$NAT_RULE" --query backendPort)"
check_contains "It forwards to ${VM1}'s network interface" "$NIC1" \
  "$(az_q network lb inbound-nat-rule show -g "$RG" --lb-name "$LB" -n "$NAT_RULE" --query backendIPConfiguration.id)"

banner "Outbound rule ${OUT_RULE}"
check_contains "Outbound rule uses the backend pool ${POOL}" "/backendAddressPools/${POOL}" \
  "$(az_q network lb outbound-rule show -g "$RG" --lb-name "$LB" -n "$OUT_RULE" --query backendAddressPool.id)"

banner "Traffic through the frontend"
if [[ -n "$LB_IP" ]]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${LB_IP}/" || true)"
  check_eq "HTTP 200 from http://${LB_IP}/" "200" "$code"
  seen=""
  for i in $(seq 1 30); do
    host="$(curl -s --max-time 3 "http://${LB_IP}/" | grep -o 'vm-web-[0-9]' | head -n1)"
    if [[ -n "$host" && "$seen" != *"$host"* ]]; then seen="${seen} ${host}"; fi
    if [[ "$seen" == *vm-web-1* && "$seen" == *vm-web-2* ]]; then break; fi
  done
  if [[ "$seen" == *vm-web-1* && "$seen" == *vm-web-2* ]]; then
    pass "Both web servers answer through the frontend (two healthy backends)"
  else
    fail "Only these servers answered:${seen:- none} — check the probe and that both VMs run the web server"
  fi
else
  fail "No frontend IP address, so traffic could not be tested"
fi

banner "Outbound internet through the outbound rule (about 30 seconds)"
out_ip="$(az vm run-command invoke -g "$RG" -n "$VM1" --command-id RunShellScript \
  --scripts "curl -s --max-time 10 https://api.ipify.org || echo no-outbound" \
  --query 'value[0].message' --output tsv 2>/dev/null \
  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|no-outbound' | head -n1)"
if [[ -z "$out_ip" ]]; then
  note "Could not run a command on ${VM1} — outbound check skipped."
elif [[ -n "$LB_IP" && "$out_ip" == "$LB_IP" ]]; then
  pass "${VM1} reaches the internet as ${out_ip} (the frontend IP)"
else
  fail "${VM1} outbound test returned '${out_ip}' (expected ${LB_IP:-the frontend IP})"
fi

summary
