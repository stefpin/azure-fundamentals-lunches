#!/usr/bin/env bash
# =============================================================================
# Lab 11 · Verify — checks every requirement of the Challenge brief.
#   bash verify.sh
# Every check runs, even when an earlier one fails.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/azsql.sh"

RG="$(rg_name 11)"
SQL_SERVER="sql-nusa-${SUFFIX}"
SQL_FQDN="${SQL_SERVER}.database.windows.net"
DB="sqldb-orders"

ip_to_int() {
  local IFS=. a b c d
  read -r a b c d <<< "$1"
  echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}
is_ipv4() { [[ "${1:-}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; }

banner "Lab 11 · Resource group and logical server"
rg_lunch="$(az_q group show --name "$RG" --query tags.lunch)"
check_eq "Resource group ${RG} exists with tag lunch=11" "11" "$rg_lunch"

server_state="$(az_q sql server show --resource-group "$RG" --name "$SQL_SERVER" --query state)"
check_eq "Logical server ${SQL_SERVER} exists" "Ready" "$server_state"

entra_only="$(az_q sql server ad-only-auth get --resource-group "$RG" --name "$SQL_SERVER" --query azureAdOnlyAuthentication)"
check_eq "Microsoft Entra-only authentication is enabled (Task 1)" "true" "$entra_only"

admin_sid="$(az_q sql server ad-admin list --resource-group "$RG" -s "$SQL_SERVER" --query "[0].sid")"
my_oid="$(my_object_id)"
check_eq "You are the server's Microsoft Entra admin (Task 1)" "${my_oid:-<your object id>}" "$admin_sid"

banner "Database ${DB}"
db_status="$(az_q sql db show --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" --query status)"
check_nonempty "Database ${DB} exists (Task 2)" "$db_status"
[[ -n "$db_status" ]] && info "Current status: ${db_status} (Online, Paused and Resuming are all fine)."

slo="$(az_q sql db show --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" --query currentServiceObjectiveName)"
check_contains "Database runs on General Purpose serverless compute (GP_S_…) (Task 2)" "GP_S_" "$slo"

pause_delay="$(az_q sql db show --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" --query autoPauseDelay)"
if [[ "$pause_delay" =~ ^[0-9]+$ ]] && (( pause_delay > 0 )); then
  pass "Auto-pause is enabled (after ${pause_delay} idle minutes) (Task 2)"
else
  fail "Auto-pause is enabled (Task 2) — got '${pause_delay:-<empty>}'; -1 means auto-pause is off"
fi

free_limit="$(az_q sql db show --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" --query useFreeLimit)"
if [[ "${free_limit,,}" == "true" ]]; then
  info "The Azure SQL Database free offer is applied to ${DB}."
else
  info "The free offer is not applied to ${DB}; normal serverless prices apply while it runs."
fi

banner "Server firewall"
MY_IP="$(my_public_ip)"
rules="$(az_q sql server firewall-rule list --resource-group "$RG" --server "$SQL_SERVER" \
  --query "[].[name, startIpAddress, endIpAddress]")"
covered="" azure_all="" whole_internet=""
while IFS=$'\t' read -r name start end; do
  [[ -z "${name:-}" ]] && continue
  if [[ "$start" == "0.0.0.0" && "$end" == "0.0.0.0" ]]; then
    azure_all="$name"
    continue
  fi
  if [[ "$start" == "0.0.0.0" && "$end" == "255.255.255.255" ]]; then
    whole_internet="$name"
  fi
  if is_ipv4 "$MY_IP" && is_ipv4 "$start" && is_ipv4 "$end"; then
    ip_n="$(ip_to_int "$MY_IP")"
    if (( $(ip_to_int "$start") <= ip_n && ip_n <= $(ip_to_int "$end") )); then
      covered="$name"
    fi
  fi
done <<< "$rules"

if [[ -n "$covered" ]]; then
  pass "A firewall rule allows your current IP ${MY_IP} (rule '${covered}') (Task 3)"
else
  fail "A firewall rule allows your current IP ${MY_IP:-<unknown>} (Task 3) — Cloud Shell's IP can change between sessions; re-run the Task 3 command"
fi
if [[ -z "$azure_all" ]]; then
  pass "'Allow Azure services and resources to access this server' is off"
else
  fail "'Allow Azure services' is on (rule '${azure_all}', 0.0.0.0) — it admits every Azure IP address; delete the rule"
fi
if [[ -z "$whole_internet" ]]; then
  pass "No firewall rule opens the server to the whole internet"
else
  fail "Rule '${whole_internet}' allows 0.0.0.0–255.255.255.255 — delete it"
fi

banner "Data in dbo.Orders"
if command -v sqlcmd >/dev/null 2>&1; then
  count="" raw=""
  for attempt in 1 2 3 4 5 6; do
    raw="$(azsql "$SQL_FQDN" "$DB" -h-1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.Orders;" 2>&1)"
    count="$(tr -d '[:space:]' <<< "$raw")"
    [[ "$count" =~ ^[0-9]+$ ]] && break
    # A paused serverless database wakes up on the first connection (error 40613), so try again.
    (( attempt < 6 )) && sleep 15
  done
  if [[ "$count" =~ ^[0-9]+$ ]]; then
    check_ge "Table dbo.Orders has at least one row (Task 4)" 1 "$count"
  else
    fail "Table dbo.Orders has at least one row (Task 4) — the query failed: $(tr '\n' ' ' <<< "$raw" | cut -c1-200)"
  fi
else
  note "sqlcmd is not installed here, so the rows in dbo.Orders were not checked. Run verify.sh in Azure Cloud Shell."
fi

summary
