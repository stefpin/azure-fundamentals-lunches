#!/usr/bin/env bash
# =============================================================================
# Lab 28 · Reference solution — runs setup.sh (if needed) and Guided tasks 2–6.
#   bash solution.sh                    # core tasks
#   WITH_AUDITING=1 bash solution.sh    # also the optional Task 7 (auditing to Log Analytics)
# Expect 30–60 minutes, mostly waiting for the first backup and the restore.
# Run it in Azure Cloud Shell (Bash): it needs sqlcmd.
# =============================================================================
set -euo pipefail
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
FOG_RO="${FOG}.secondary.database.windows.net"
DB="sqldb-orders"
RESTORED="sqldb-orders-restored"

# primary_side -> prints "main", "dr", or nothing when the failover group does not exist
primary_side() {
  if [[ "$(az_q sql failover-group show --resource-group "$RG_DR" --server "$SQL_DR" --name "$FOG" --query replicationRole)" == "Primary" ]]; then
    echo dr
  elif [[ "$(az_q sql failover-group show --resource-group "$RG" --server "$SQL_MAIN" --name "$FOG" --query replicationRole)" == "Primary" ]]; then
    echo main
  fi
}

banner "Starting point"
bash "${LAB_DIR}/setup.sh"

banner "Task 2 · Dynamic data masking on dbo.Customers"
if [[ -n "$(primary_side)" ]]; then WRITE_FQDN="$FOG_RW"; else WRITE_FQDN="$MAIN_FQDN"; fi
azsql "$WRITE_FQDN" "$DB" -b -i "${LAB_DIR}/masking.sql"
info "What the support team sees:"
azsql "$WRITE_FQDN" "$DB" -b -W -Q "EXECUTE AS USER = 'support_agent'; SELECT TOP (3) FullName, Email, Phone FROM dbo.Customers ORDER BY CustomerId; REVERT;"

banner "Task 3 · Failover group ${FOG}"
if [[ -n "$(primary_side)" ]]; then
  info "Failover group ${FOG} already exists."
else
  az sql failover-group create \
    --name "$FOG" \
    --resource-group "$RG" \
    --server "$SQL_MAIN" \
    --partner-server "$SQL_DR" \
    --partner-resource-group "$RG_DR" \
    --failover-policy Manual \
    --add-db "$DB" \
    --output none
  info "Created ${FOG} with ${DB}; seeding the secondary in ${SECONDARY_LOCATION}..."
fi
if ! wait_until "the geo-secondary answers through the read-only listener" 1200 \
     azsql "$FOG_RO" "$DB" -K ReadOnly -b -Q "SELECT COUNT(*) FROM dbo.Orders;"; then
  echo "The read-only listener did not answer within 20 minutes. Check the failover group in the portal."
  exit 1
fi

banner "Task 4 · Connect through the listeners"
azsql "$FOG_RW" "$DB" -b -W -Q "SELECT @@SERVERNAME AS server_name, DATABASEPROPERTYEX(DB_NAME(), 'Updateability') AS updateability;"
azsql "$FOG_RO" "$DB" -K ReadOnly -b -W -Q "SELECT @@SERVERNAME AS server_name, DATABASEPROPERTYEX(DB_NAME(), 'Updateability') AS updateability;"
azsql "$FOG_RW" "$DB" -b -W -Q "SELECT partner_server, role_desc, replication_state_desc, replication_lag_sec, last_replication FROM sys.dm_geo_replication_link_status;"

banner "Task 5 · Oops! Point-in-time restore to ${RESTORED}"
if az sql db show --resource-group "$RG" --server "$SQL_MAIN" --name "$RESTORED" --output none 2>/dev/null; then
  info "Database ${RESTORED} already exists."
else
  if [[ "$(primary_side)" != "main" ]]; then
    echo "Point-in-time restore must start from the primary, and ${SQL_MAIN} is not the primary right now."
    echo "Fail back first (az sql failover-group set-primary ... --server ${SQL_MAIN}) and run the script again."
    exit 1
  fi
  restore_point_exists() {
    [[ -n "$(az_q sql db show --resource-group "$RG" --server "$SQL_MAIN" --name "$DB" --query earliestRestoreDate)" ]]
  }
  info "Waiting until the database has its first restore point (up to about 30 minutes after creation)..."
  if ! wait_until "the first restore point" 2700 restore_point_exists; then
    echo "No restore point appeared yet. Run the script again later."
    exit 1
  fi

  BEFORE_OOPS="$(date -u +%Y-%m-%dT%H:%M:%S)"
  sleep 5
  azsql "$FOG_RW" "$DB" -b -Q "DELETE FROM dbo.Orders WHERE StoreCode = 'SBY-01';"
  info "Deleted the Surabaya orders. Restore point chosen: ${BEFORE_OOPS} UTC."
  info "Replication is not a backup — the secondary lost them too:"
  sleep 10
  azsql "$FOG_RO" "$DB" -K ReadOnly -b -W -Q "SELECT COUNT(*) AS sby_orders_on_secondary FROM dbo.Orders WHERE StoreCode = 'SBY-01';"

  attempt=1
  until az sql db restore \
          --resource-group "$RG" --server "$SQL_MAIN" --name "$DB" \
          --dest-name "$RESTORED" \
          --time "$BEFORE_OOPS" \
          --service-objective Basic \
          --backup-storage-redundancy Local \
          --output none; do
    if (( attempt >= 4 )); then
      echo "The restore failed four times. Check the earliest restore point and try Task 5 by hand."
      exit 1
    fi
    note "Restore not possible yet (a log backup may still be pending). Trying again in 5 minutes..."
    sleep 300
    attempt=$((attempt + 1))
  done
  info "Restored ${RESTORED} on ${SQL_MAIN}."
fi
azsql "$MAIN_FQDN" "$RESTORED" -b -W -Q "SELECT COUNT(*) AS sby_orders_in_restored_copy FROM dbo.Orders WHERE StoreCode = 'SBY-01';"

banner "Task 6 · Planned failover to ${SQL_DR}"
if [[ "$(primary_side)" == "dr" ]]; then
  info "${SQL_DR} is already the primary."
else
  az sql failover-group set-primary --name "$FOG" --resource-group "$RG_DR" --server "$SQL_DR" --output none
  info "Failover complete. Waiting for the listener's DNS record (30-second TTL) to follow..."
  sleep 45
fi
# The insert fails with error 3906 while the listener still resolves to the old primary, so retry.
if ! wait_until "a write through the read-write listener" 300 \
     azsql "$FOG_RW" "$DB" -b -Q "INSERT INTO dbo.Orders (CustomerId, StoreCode, TotalIdr) VALUES (4, 'JKT-02', 315000);"; then
  echo "Could not write through ${FOG_RW}. Wait a minute and run the script again."
  exit 1
fi
azsql "$FOG_RW" "$DB" -b -W -Q "SELECT @@SERVERNAME AS server_name, DATABASEPROPERTYEX(DB_NAME(), 'Updateability') AS updateability;"

if [[ "${WITH_AUDITING:-}" == "1" ]]; then
  banner "Task 7 (optional) · Server auditing to Log Analytics"
  az monitor log-analytics workspace create --resource-group "$RG" --workspace-name log-nusa \
    --location "$LOCATION" --output none
  LAW_ID="$(az monitor log-analytics workspace show --resource-group "$RG" --workspace-name log-nusa --query id --output tsv)"
  az sql server audit-policy update --resource-group "$RG" --name "$SQL_MAIN" \
    --state Enabled --lats Enabled --lawri "$LAW_ID" --output none
  az sql server audit-policy update --resource-group "$RG_DR" --name "$SQL_DR" \
    --state Enabled --lats Enabled --lawri "$LAW_ID" --output none
  info "Auditing enabled on both servers; records reach the workspace after a few minutes."
fi

banner "Done"
info "Check your work with:  bash verify.sh"
info "Delete everything with: bash cleanup.sh"
