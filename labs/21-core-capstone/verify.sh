#!/usr/bin/env bash
# =============================================================================
# Lab 21 · verify.sh — checks every part of the capstone platform and the
# Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource group ${RG}"
rg_lunch="$(az_q group show --name "$RG" --query tags.lunch)"
check_eq "Resource group exists and is tagged lunch=21" "21" "$rg_lunch"
if [[ -z "$rg_lunch" ]]; then
  echo "Nothing to check yet. Deploy the platform first: bash deploy.sh (Task 2)."
  summary
  exit 1
fi

# ---------------------------------------------------------------------------
banner "Network · Lunch 08"
check_nonempty "Virtual network ${VNET} exists" "$(az_q network vnet show -g "$RG" -n "$VNET" --query name)"
check_contains "Subnet ${WEB_SUBNET} is protected by NSG ${NSG}" "/networkSecurityGroups/${NSG}" \
  "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$WEB_SUBNET" --query networkSecurityGroup.id)"
check_eq "Subnet ${WEB_SUBNET} is private (default outbound access disabled)" "false" \
  "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$WEB_SUBNET" --query defaultOutboundAccess)"

# http_rules <service tag>  -> number of inbound Allow rules for TCP 80 from that source
http_rules() {
  az_q network nsg rule list -g "$RG" --nsg-name "$NSG" --query \
    "length([?direction=='Inbound' && access=='Allow' && (destinationPortRange=='80' || contains(destinationPortRanges || \`[]\`, '80')) && (sourceAddressPrefix=='$1' || contains(sourceAddressPrefixes || \`[]\`, '$1'))])"
}
check_ge "NSG ${NSG} allows TCP 80 from Internet (shoppers)" 1 "$(http_rules Internet)"
check_ge "NSG ${NSG} allows TCP 80 from AzureLoadBalancer (health probes)" 1 "$(http_rules AzureLoadBalancer)"

# ---------------------------------------------------------------------------
banner "Web tier · Lunches 03, 06 and 09"
zone=1
for vm in "$VM1" "$VM2"; do
  check_eq "${vm} runs in availability zone ${zone}" "$zone" "$(az_q vm show -g "$RG" -n "$vm" --query 'zones[0]')"
  check_eq "${vm} is running" "VM running" \
    "$(az_q vm get-instance-view -g "$RG" -n "$vm" --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")"
  zone=$((zone + 1))
done
check_eq "No VM in ${RG} has its own public IP address" "0" "$(az_q vm list -g "$RG" -d --query 'length([?publicIps])')"

check_eq "Public IP ${PIP} is Standard SKU" "Standard" "$(az_q network public-ip show -g "$RG" -n "$PIP" --query sku.name)"
check_eq "Public IP ${PIP} is zone-redundant (zones 1,2,3)" "1,2,3" \
  "$(az_q network public-ip show -g "$RG" -n "$PIP" --query "join(',', sort(zones || \`[]\`))")"
check_eq "Load balancer ${LB} is Standard SKU" "Standard" "$(az_q network lb show -g "$RG" -n "$LB" --query sku.name)"
check_nonempty "Health probe sends HTTP GET /health" \
  "$(az_q network lb probe list -g "$RG" --lb-name "$LB" --query "[?protocol=='Http' && requestPath=='/health'].name | [0]")"
check_nonempty "A load-balancing rule forwards TCP 80" \
  "$(az_q network lb rule list -g "$RG" --lb-name "$LB" --query '[?frontendPort==`80` && backendPort==`80`].name | [0]')"
check_ge "An outbound rule gives the private VMs internet access" 1 \
  "$(az_q network lb outbound-rule list -g "$RG" --lb-name "$LB" --query 'length(@)')"
check_eq "The backend pool contains both web VMs" "2" \
  "$(az_q network lb show -g "$RG" -n "$LB" --query 'length(backendAddressPools[0].backendIPConfigurations || `[]`)')"

ip="$(lb_ip)"
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://${ip}/" 2>/dev/null || true)"
check_eq "Storefront answers HTTP 200 through the load balancer (http://${ip:-<no IP>}/)" "200" "$code"
seen=""
if [[ "$code" == "200" ]]; then
  for _ in {1..30}; do
    host="$(curl -s --max-time 3 "http://${ip}/" | grep -oE 'vm-web-[0-9]+' | head -n1)"
    [[ -n "$host" && "$seen" != *"$host"* ]] && seen="${seen} ${host}"
    [[ "$seen" == *vm-web-1* && "$seen" == *vm-web-2* ]] && break
  done
fi
if [[ "$seen" == *vm-web-1* && "$seen" == *vm-web-2* ]]; then
  pass "Both web servers answer through the load balancer (two zones in rotation)"
else
  fail "Only these servers answered:${seen:- none} — are both VMs running and healthy? (Task 4 restarts vm-web-1)"
fi

# ---------------------------------------------------------------------------
banner "Data · Lunches 11 and 17"
check_eq "SQL server ${SQL} accepts Microsoft Entra authentication only" "true" \
  "$(az_q sql server ad-only-auth get -g "$RG" -n "$SQL" --query azureAdOnlyAuthentication)"
check_nonempty "SQL server has a Microsoft Entra administrator" \
  "$(az_q sql server ad-admin list -g "$RG" -s "$SQL" --query '[0].sid')"
tls="$(az_q sql server show -g "$RG" -n "$SQL" --query minimalTlsVersion)"
if [[ "$tls" == "1.2" || "$tls" == "1.3" ]]; then
  pass "SQL server requires TLS ${tls} or later"
else
  fail "SQL server should require TLS 1.2 or later (got '${tls:-<empty>}')"
fi
check_contains "Database ${DB} is General Purpose serverless" "GP_S" \
  "$(az_q sql db show -g "$RG" -s "$SQL" -n "$DB" --query sku.name)"
check_ge "Point-in-time restore keeps at least 7 days of backups" 7 \
  "$(az_q sql db str-policy show -g "$RG" -s "$SQL" -n "$DB" --query retentionDays)"

# ---------------------------------------------------------------------------
banner "Secrets · Lunch 15"
check_eq "Key Vault ${KV} uses the Azure RBAC permission model" "true" \
  "$(az_q keyvault show -n "$KV" --query properties.enableRbacAuthorization)"
check_ge "Key Vault soft delete keeps deleted items for at least 7 days" 7 \
  "$(az_q keyvault show -n "$KV" --query properties.softDeleteRetentionInDays)"
secret_value="$(az_q keyvault secret show --vault-name "$KV" -n "$SECRET" --query value)"
if [[ -z "$secret_value" ]]; then
  fail "Secret ${SECRET} is readable by you (new role assignments can take ~10 minutes to work)"
elif [[ "${secret_value,,}" == *password* || "${secret_value,,}" == *pwd=* ]]; then
  fail "Secret ${SECRET} still contains a password — use Microsoft Entra authentication"
else
  pass "Secret ${SECRET} exists and contains no password"
fi
unset secret_value

# ---------------------------------------------------------------------------
banner "Operations · Lunch 16"
check_nonempty "Log Analytics workspace ${LAW} exists" \
  "$(az_q monitor log-analytics workspace show -g "$RG" -n "$LAW" --query name)"
check_eq "Action group ${AG} is enabled" "true" "$(az_q monitor action-group show -g "$RG" -n "$AG" --query enabled)"
check_ge "Action group ${AG} has an e-mail receiver" 1 \
  "$(az_q monitor action-group show -g "$RG" -n "$AG" --query 'length(emailReceivers)')"
check_ge "An enabled metric alert watches the VMs' Percentage CPU" 1 \
  "$(az_q monitor metrics alert list -g "$RG" --query "length([?enabled && criteria.allOf[?metricName=='Percentage CPU']])")"
check_ge "An enabled activity log alert watches for stopped VMs" 1 \
  "$(az_q monitor activity-log alert list -g "$RG" --query 'length([?enabled])')"
kv_id="$(az_q keyvault show -n "$KV" --query id)"
diag_count=""
[[ -n "$kv_id" ]] && diag_count="$(az_q monitor diagnostic-settings list --resource "$kv_id" --query 'length([?workspaceId])')"
check_ge "Key Vault sends its audit logs to a Log Analytics workspace" 1 "$diag_count"

# ---------------------------------------------------------------------------
banner "Governance and cost · Lunches 18 and 19"
info "Looking up the built-in 'Allowed locations' policy by its display name (a few seconds)..."
def_name="$(az_q policy definition list --query "[?displayName=='Allowed locations' && policyType=='BuiltIn'].name | [0]")"
allowed=""
if [[ -n "$def_name" ]]; then
  allowed="$(az_q policy assignment list -g "$RG" \
    --query "[?ends_with(policyDefinitionId, '/${def_name}')].parameters.listOfAllowedLocations.value | [0] | join(',', @)")"
fi
check_nonempty "Built-in 'Allowed locations' policy is assigned to ${RG}" "$allowed"
check_contains "The allowed locations include ${LOCATION}" "$LOCATION" "$allowed"

budget_count="$(az consumption budget list --resource-group "$RG" --query 'length(@)' --output tsv 2>/dev/null)"
if [[ "$budget_count" =~ ^[0-9]+$ ]]; then
  check_ge "A budget watches ${RG} (Task 7)" 1 "$budget_count"
else
  note "Could not read budgets with the CLI (preview command; not every offer supports it)."
  note "Check Task 7 in the portal instead: ${RG} > Cost Management > Budgets."
fi

summary
