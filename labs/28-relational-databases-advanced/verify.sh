#!/usr/bin/env bash
# =============================================================================
# Lab 28 · Verify — checks every requirement of the Challenge brief.
#   bash verify.sh
# By default it expects the failover drill to be done (the DR server is primary).
# If you failed back afterwards, run:   EXPECTED_PRIMARY=main bash verify.sh
# Every check runs, even when an earlier one fails.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/azsql.sh"

RG="$(rg_name 28)"
RG_DR="$(rg_name 28 dr)"
SQL_MAIN="sql-nusa-main-${SUFFIX}"
SQL_DR="sql-nusa-dr-${SUFFIX}"
MAIN_FQDN="${SQL_MAIN}.database.windows.net"
FOG="fog-nusa-${SUFFIX}"
FOG_RW="${FOG}.database.windows.net"
DB="sqldb-orders"
RESTORED="sqldb-orders-restored"
EXPECTED_PRIMARY="${EXPECTED_PRIMARY:-dr}"

ip_to_int() {
  local IFS=. a b c d
  read -r a b c d <<< "$1"
  echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}
is_ipv4() { [[ "${1:-}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; }

# sql_scalar <server fqdn> <database> <query> -> prints a number, or the error text if the query fails
sql_scalar() {
  local raw="" value="" attempt
  for attempt in 1 2 3; do
    raw="$(azsql "$1" "$2" -h-1 -W -Q "SET NOCOUNT ON; $3" 2>&1)"
    value="$(tr -d '[:space:]' <<< "$raw")"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      echo "$value"
      return 0
    fi
    (( attempt < 3 )) && sleep 10
  done
  tr '\n' ' ' <<< "$raw" | cut -c1-200
}

MY_IP="$(my_public_ip)"

banner "Lab 28 · Two regions, two Entra-only servers"
for spec in "${RG}|${SQL_MAIN}|${LOCATION}" "${RG_DR}|${SQL_DR}|${SECONDARY_LOCATION}"; do
  IFS='|' read -r rg server region <<< "$spec"
  rg_lunch="$(az_q group show --name "$rg" --query tags.lunch)"
  check_eq "Resource group ${rg} exists with tag lunch=28" "28" "$rg_lunch"

  server_loc="$(az_q sql server show --resource-group "$rg" --name "$server" --query location)"
  server_loc="${server_loc// /}"
  check_eq "Server ${server} exists in ${region}" "${region}" "$server_loc"

  entra_only="$(az_q sql server ad-only-auth get --resource-group "$rg" --name "$server" --query azureAdOnlyAuthentication)"
  check_eq "${server}: Microsoft Entra-only authentication is enabled" "true" "$entra_only"

  covered=""
  while IFS=$'\t' read -r name start end; do
    [[ -z "${name:-}" ]] && continue
    if is_ipv4 "$MY_IP" && is_ipv4 "$start" && is_ipv4 "$end"; then
      ip_n="$(ip_to_int "$MY_IP")"
      if (( $(ip_to_int "$start") <= ip_n && ip_n <= $(ip_to_int "$end") )); then covered="$name"; fi
    fi
  done <<< "$(az_q sql server firewall-rule list --resource-group "$rg" --server "$server" --query "[].[name, startIpAddress, endIpAddress]")"
  if [[ -n "$covered" ]]; then
    pass "${server}: a firewall rule allows your current IP ${MY_IP} (rule '${covered}')"
  else
    fail "${server}: no firewall rule allows your current IP ${MY_IP:-<unknown>} — server-level rules do not replicate; re-run 'bash setup.sh' to refresh them"
  fi
done

banner "Failover group ${FOG}"
role_dr="$(az_q sql failover-group show --resource-group "$RG_DR" --server "$SQL_DR" --name "$FOG" --query replicationRole)"
role_main="$(az_q sql failover-group show --resource-group "$RG" --server "$SQL_MAIN" --name "$FOG" --query replicationRole)"
if [[ -n "$role_dr" || -n "$role_main" ]]; then
  pass "Failover group ${FOG} exists (Task 3)"
else
  fail "Failover group ${FOG} exists (Task 3)"
fi

if [[ "$role_dr" == "Primary" ]]; then
  fog_rg="$RG_DR"; fog_server="$SQL_DR"; actual_primary="dr"
elif [[ "$role_main" == "Primary" ]]; then
  fog_rg="$RG"; fog_server="$SQL_MAIN"; actual_primary="main"
else
  fog_rg=""; fog_server=""; actual_primary=""
fi

if [[ -n "$fog_server" ]]; then
  fog_dbs="$(az_q sql failover-group show --resource-group "$fog_rg" --server "$fog_server" --name "$FOG" --query "databases[]")"
  if grep -qi "/databases/${DB}\$" <<< "$fog_dbs"; then
    pass "${DB} is in the failover group (Task 3)"
  else
    fail "${DB} is in the failover group (Task 3)"
  fi
  policy="$(az_q sql failover-group show --resource-group "$fog_rg" --server "$fog_server" --name "$FOG" --query readWriteEndpoint.failoverPolicy)"
  check_eq "Failover policy is customer managed (Manual) (Task 3)" "Manual" "$policy"
else
  fail "${DB} is in the failover group (Task 3) — no primary found"
fi

if [[ "$EXPECTED_PRIMARY" == "main" ]]; then
  expected_server="$SQL_MAIN"
  hint="fail back with a planned failover to ${SQL_MAIN}, or run verify.sh without EXPECTED_PRIMARY"
else
  expected_server="$SQL_DR"
  hint="run the planned failover (Task 6), or set EXPECTED_PRIMARY=main if you failed back on purpose"
fi
if [[ -n "$actual_primary" && "$actual_primary" == "$EXPECTED_PRIMARY" ]]; then
  pass "The primary is ${expected_server} (Task 6)"
else
  fail "The primary is ${expected_server} (Task 6) — ${hint}"
fi

banner "Point-in-time restore"
restored_status="$(az_q sql db show --resource-group "$RG" --server "$SQL_MAIN" --name "$RESTORED" --query status)"
check_eq "Database ${RESTORED} exists on ${SQL_MAIN} and is online (Task 5)" "Online" "$restored_status"

banner "Dynamic data masking and data"
if command -v sqlcmd >/dev/null 2>&1; then
  masked="$(sql_scalar "$FOG_RW" "$DB" "SELECT COUNT(*) FROM sys.masked_columns WHERE OBJECT_NAME(object_id) = 'Customers' AND name = 'Email';")"
  check_eq "dbo.Customers.Email has a masking rule (Task 2)" "1" "$masked"
  if [[ -n "$restored_status" ]]; then
    sby="$(sql_scalar "$MAIN_FQDN" "$RESTORED" "SELECT COUNT(*) FROM dbo.Orders WHERE StoreCode = 'SBY-01';")"
    check_ge "The restored copy still holds the Surabaya (SBY-01) orders (Task 5)" 1 "$sby"
  fi
else
  note "sqlcmd is not installed here, so masking and data were not checked. Run verify.sh in Azure Cloud Shell."
fi

banner "Optional · auditing"
for spec in "${RG}|${SQL_MAIN}" "${RG_DR}|${SQL_DR}"; do
  IFS='|' read -r rg server <<< "$spec"
  state="$(az_q sql server audit-policy show --resource-group "$rg" --name "$server" --query state)"
  if [[ "$state" == "Enabled" ]]; then
    info "${server}: server auditing is enabled."
  else
    info "${server}: server auditing is not enabled (optional Task 7)."
  fi
done

summary
