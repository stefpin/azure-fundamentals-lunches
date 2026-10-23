#!/usr/bin/env bash
# =============================================================================
# Lab 11 · Reference solution — builds what Guided tasks 1–4 build.
#   bash solution.sh
# Safe to run more than once. Run it in Azure Cloud Shell (Bash): it needs sqlcmd.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/azsql.sh"

RG="$(rg_name 11)"
SQL_SERVER="sql-nusa-${SUFFIX}"
SQL_FQDN="${SQL_SERVER}.database.windows.net"
DB="sqldb-orders"

banner "Task 1 · Logical server ${SQL_SERVER} with Microsoft Entra-only authentication"
ensure_rg "$RG" 11
MY_UPN="$(my_upn)"
MY_OID="$(my_object_id)"
if [[ -z "$MY_UPN" || -z "$MY_OID" ]]; then
  echo "Could not read your signed-in user. Sign in as a user (not a service principal): az login"
  exit 1
fi
if az sql server show --resource-group "$RG" --name "$SQL_SERVER" --output none 2>/dev/null; then
  info "Server ${SQL_SERVER} already exists."
else
  az sql server create \
    --name "$SQL_SERVER" \
    --resource-group "$RG" \
    --location "$LOCATION" \
    --enable-ad-only-auth \
    --external-admin-principal-type User \
    --external-admin-name "$MY_UPN" \
    --external-admin-sid "$MY_OID" \
    --output none
  info "Created ${SQL_SERVER} with ${MY_UPN} as the Microsoft Entra admin."
fi

banner "Task 2 · Database ${DB} (free offer first, serverless as the fallback)"
if az sql db show --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" --output none 2>/dev/null; then
  info "Database ${DB} already exists."
elif az sql db create \
       --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" \
       --edition GeneralPurpose --family Gen5 --capacity 2 \
       --compute-model Serverless \
       --use-free-limit --free-limit-exhaustion-behavior AutoPause \
       --output none; then
  info "Created ${DB} with the Azure SQL Database free offer."
else
  note "The free offer was not available here. Creating a serverless database with auto-pause instead."
  az sql db create \
    --resource-group "$RG" --server "$SQL_SERVER" --name "$DB" \
    --edition GeneralPurpose --family Gen5 --capacity 1 \
    --compute-model Serverless --min-capacity 0.5 --auto-pause-delay 60 \
    --backup-storage-redundancy Local \
    --output none
  info "Created ${DB} (General Purpose serverless, auto-pause after 60 minutes)."
fi

banner "Task 3 · Server firewall rule for this machine's public IP address"
MY_IP="$(my_public_ip)"
if [[ ! "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Could not detect your public IPv4 address (got '${MY_IP}')."
  exit 1
fi
az sql server firewall-rule create \
  --resource-group "$RG" --server "$SQL_SERVER" --name AllowMyClientIP \
  --start-ip-address "$MY_IP" --end-ip-address "$MY_IP" \
  --output none
info "Rule AllowMyClientIP allows ${MY_IP}."

banner "Task 4 · Create and query dbo.Orders with sqlcmd and your Entra token"
info "Waiting until the database accepts connections (a new rule or a paused database can take a minute)..."
if ! wait_until "a connection to ${DB}" 300 azsql "$SQL_FQDN" "$DB" -b -Q "SELECT 1;"; then
  echo "Could not connect to ${SQL_FQDN}. Check the firewall rule and run the script again."
  exit 1
fi
azsql "$SQL_FQDN" "$DB" -b -i "${LAB_DIR}/orders.sql"
azsql "$SQL_FQDN" "$DB" -b -W -Q "SET NOCOUNT ON; SELECT TOP (5) OrderId, StoreCode, CustomerName, TotalIdr, Status FROM dbo.Orders ORDER BY OrderId;"

banner "Done"
info "Task 5 (portal Query editor) is a portal-only step — try it in the browser."
info "Check your work with:  bash verify.sh"
info "Delete everything with: bash cleanup.sh"
