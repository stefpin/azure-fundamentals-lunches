#!/usr/bin/env bash
# =============================================================================
# Lab 23 · Verify — checks the Challenge brief. Read-only: it changes nothing.
#   bash verify.sh
# Uses AS_MIN / AS_MAX (default 2 / 3) — export them if you used the small-quota
# settings (export AS_MIN=1 AS_MAX=2). VMSS_NAME overrides the scale set name.
# =============================================================================
set -uo pipefail
AZL_QUIET=1 source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 23)"
AS_MIN="${AS_MIN:-2}"
AS_MAX="${AS_MAX:-3}"
VMSS="${VMSS_NAME:-vmss-web}"

banner "Lab 23 · checking ${RG}"

if ! az group show -n "$RG" --output none 2>/dev/null; then
  fail "Resource group ${RG} exists (run: bash setup.sh)"
  summary
  exit 1
fi
pass "Resource group ${RG} exists"
check_eq "Resource group is tagged lunch=23 (so cleanup.sh can find it)" "23" "$(az_q group show -n "$RG" --query tags.lunch)"

# --- Scale set -----------------------------------------------------------------------
banner "Scale set"
if ! az vmss show -g "$RG" -n "$VMSS" --output none 2>/dev/null; then
  other="$(az_q vmss list -g "$RG" --query "[0].name")"
  if [[ -z "$other" ]]; then
    fail "A scale set named ${VMSS} exists (Task 2)"
    summary
    exit 1
  fi
  note "No scale set named ${VMSS} — checking ${other} instead."
  VMSS="$other"
fi
pass "Scale set ${VMSS} exists"
check_eq "Orchestration mode is Flexible (Task 2)" "Flexible" "$(az_q vmss show -g "$RG" -n "$VMSS" --query orchestrationMode)"
check_eq "Scale set spans availability zones 1, 2 and 3 (Task 2)" "1,2,3" \
  "$(az_q vmss show -g "$RG" -n "$VMSS" --query "join(',', sort(zones || \`[]\`))")"

RUNNING="$(az_q vm list -g "$RG" -d --query "length([?virtualMachineScaleSet && powerState=='VM running'])")"
check_ge "Running instances: at least ${AS_MIN} (Task 2)" "$AS_MIN" "$RUNNING"
ZONES_USED="$(az_q vm list -g "$RG" --query "[?virtualMachineScaleSet].zones[0]" | sort -u | grep -c . || true)"
if (( ${ZONES_USED:-0} >= 2 )); then
  pass "Instances run in ${ZONES_USED} different availability zones"
else
  note "Instances run in ${ZONES_USED:-0} zone(s). Azure balances zones as the set grows (not a failure)."
fi

# --- Autoscale -------------------------------------------------------------------------
banner "Autoscale"
AUTOSCALE="$(az_q monitor autoscale list -g "$RG" --query "[].[name, targetResourceUri]" \
  | grep -i "/virtualMachineScaleSets/${VMSS}\$" | head -n 1 | cut -f1 || true)"
if [[ -z "$AUTOSCALE" ]]; then
  fail "An autoscale setting targets ${VMSS} (Task 4)"
else
  pass "Autoscale setting ${AUTOSCALE} targets ${VMSS}"
  check_eq "Autoscale is enabled (Task 4)" "true" "$(az_q monitor autoscale show -g "$RG" -n "$AUTOSCALE" --query enabled)"
  DEFAULT_PROFILE="profiles[?!recurrence && !fixedDate] | [0]"
  read -r MIN MAX <<<"$(az_q monitor autoscale show -g "$RG" -n "$AUTOSCALE" \
    --query "${DEFAULT_PROFILE}.[capacity.minimum, capacity.maximum]" | tr '\n' ' ')"
  check_eq "Default profile: minimum instance count is ${AS_MIN} (Task 4)" "$AS_MIN" "${MIN:-}"
  check_eq "Default profile: maximum instance count is ${AS_MAX} (Task 4)" "$AS_MAX" "${MAX:-}"
  for direction in Increase Decrease; do
    count="$(az_q monitor autoscale show -g "$RG" -n "$AUTOSCALE" \
      --query "length(${DEFAULT_PROFILE}.rules[?metricTrigger.metricName=='Percentage CPU' && scaleAction.direction=='${direction}'])")"
    if [[ "$direction" == "Increase" ]]; then
      check_ge "A Percentage CPU scale-out rule exists (Task 4)" 1 "$count"
    else
      check_ge "A Percentage CPU scale-in rule exists (Task 4)" 1 "$count"
    fi
  done
fi

# --- Load balancer and outbound access ----------------------------------------------------
banner "Load balancer and outbound access"
IPCONFIG="virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0]"
POOL_ID="$(az_q vmss show -g "$RG" -n "$VMSS" --query "${IPCONFIG}.loadBalancerBackendAddressPools[0].id")"
SUBNET_ID="$(az_q vmss show -g "$RG" -n "$VMSS" --query "${IPCONFIG}.subnet.id")"
LB_ID="${POOL_ID%/[bB]ackend[aA]ddress[pP]ools/*}"
LB_IP=""

if [[ -z "$POOL_ID" ]]; then
  fail "Instances join a load balancer backend pool (Task 2: --lb and --backend-pool-name)"
else
  pass "Instances join backend pool ${POOL_ID##*/} of load balancer ${LB_ID##*/}"
  check_eq "The load balancer is Standard SKU" "Standard" "$(az_q network lb show --ids "$LB_ID" --query sku.name)"
  check_eq "The load balancer probes /health over HTTP" "/health" \
    "$(az_q network lb show --ids "$LB_ID" --query "probes[?requestPath=='/health'] | [0].requestPath")"
  PIP_ID="$(az_q network lb show --ids "$LB_ID" --query "frontendIPConfigurations[0].publicIPAddress.id")"
  [[ -n "$PIP_ID" ]] && LB_IP="$(az_q network public-ip show --ids "$PIP_ID" --query ipAddress)"
fi

NAT_ID=""
[[ -n "$SUBNET_ID" ]] && NAT_ID="$(az_q network vnet subnet show --ids "$SUBNET_ID" --query natGateway.id)"
OUTBOUND_RULES="0"
[[ -n "$POOL_ID" ]] && OUTBOUND_RULES="$(az_q network lb show --ids "$LB_ID" --query "length(outboundRules || \`[]\`)")"
if [[ -n "$NAT_ID" ]]; then
  pass "The instances' subnet has explicit outbound access through NAT gateway ${NAT_ID##*/}"
elif [[ "${OUTBOUND_RULES:-0}" =~ ^[1-9] ]]; then
  pass "The load balancer gives the instances explicit outbound access through outbound rules"
else
  fail "The instances have explicit outbound access (NAT gateway on the subnet — see Break it and fix it)"
fi

# --- Website -------------------------------------------------------------------------------
banner "Website"
if [[ -z "$LB_IP" ]]; then
  fail "The load balancer has a public IP address"
else
  CODE="000"
  for _ in 1 2 3 4 5 6; do
    CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://${LB_IP}/" || true)"
    [[ "$CODE" == "200" ]] && break
    sleep 10
  done
  check_eq "http://${LB_IP}/ returns HTTP 200 through the load balancer (Task 3)" "200" "$CODE"
  check_contains "The page says Nusantara Retail (shared cloud-init web server)" "Nusantara Retail" \
    "$(curl -s --max-time 10 "http://${LB_IP}/" || true)"
fi

summary
