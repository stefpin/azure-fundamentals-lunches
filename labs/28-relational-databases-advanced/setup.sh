#!/usr/bin/env bash
# =============================================================================
# Lab 28 · Setup — creates the starting point (about 10 minutes):
#   * rg-lunch28-<suffix>     in $LOCATION            -> logical server sql-nusa-main-<suffix>
#   * rg-lunch28-dr-<suffix>  in $SECONDARY_LOCATION  -> logical server sql-nusa-dr-<suffix>
#     Both servers: Microsoft Entra-only authentication, you as the Entra admin,
#     and a firewall rule for your current public IP address.
#   * sqldb-orders (Basic tier) on the main server, with sample customers and orders.
#
#   bash setup.sh
# Safe to run again — for example to refresh the firewall rules when Cloud Shell's
# public IP address has changed.
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
DB="sqldb-orders"

if [[ "$LOCATION" == "$SECONDARY_LOCATION" ]]; then
  echo "LOCATION and SECONDARY_LOCATION are both '${LOCATION}'. A disaster recovery copy needs a second region."
  echo "Set SECONDARY_LOCATION to another region and source ../common/config.sh again."
  exit 1
fi

MY_UPN="$(my_upn)"
MY_OID="$(my_object_id)"
if [[ -z "$MY_UPN" || -z "$MY_OID" ]]; then
  echo "Could not read your signed-in user. Sign in as a user (not a service principal): az login"
  exit 1
fi
MY_IP="$(my_public_ip)"
if [[ ! "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Could not detect your public IPv4 address (got '${MY_IP}')."
  exit 1
fi

banner "Resource groups"
ensure_rg "$RG" 28 "$LOCATION"
ensure_rg "$RG_DR" 28 "$SECONDARY_LOCATION"
info "${RG} (${LOCATION}) and ${RG_DR} (${SECONDARY_LOCATION})"

# create_server <resource group> <server name> <region>
create_server() {
  local rg="$1" name="$2" region="$3"
  if az sql server show --resource-group "$rg" --name "$name" --output none 2>/dev/null; then
    info "Server ${name} already exists."
    return 0
  fi
  az sql server create \
    --name "$name" \
    --resource-group "$rg" \
    --location "$region" \
    --enable-ad-only-auth \
    --external-admin-principal-type User \
    --external-admin-name "$MY_UPN" \
    --external-admin-sid "$MY_OID" \
    --output none
  info "Created ${name} in ${region}."
}

banner "Two logical servers with Microsoft Entra-only authentication (2–5 minutes)"
info "Admin: ${MY_UPN}. Creating both servers in parallel..."
create_server "$RG" "$SQL_MAIN" "$LOCATION" &
pid_main=$!
create_server "$RG_DR" "$SQL_DR" "$SECONDARY_LOCATION" &
pid_dr=$!
wait "$pid_main"
wait "$pid_dr"

banner "Firewall rules for your current IP (${MY_IP}) on BOTH servers"
for pair in "${RG}:${SQL_MAIN}" "${RG_DR}:${SQL_DR}"; do
  rg="${pair%%:*}"
  server="${pair##*:}"
  az sql server firewall-rule create \
    --resource-group "$rg" --server "$server" --name AllowMyClientIP \
    --start-ip-address "$MY_IP" --end-ip-address "$MY_IP" \
    --output none
  info "${server}: AllowMyClientIP -> ${MY_IP}"
done
info "Server-level firewall rules are NOT replicated, so the disaster recovery server needs its own."

banner "Database ${DB} (Basic tier, locally redundant backups)"
if az sql db show --resource-group "$RG" --server "$SQL_MAIN" --name "$DB" --output none 2>/dev/null; then
  info "Database ${DB} already exists."
else
  az sql db create \
    --resource-group "$RG" --server "$SQL_MAIN" --name "$DB" \
    --service-objective Basic \
    --backup-storage-redundancy Local \
    --output none
  info "Created ${DB}. Its first full backup starts now; point-in-time restore is usually possible within about 30 minutes."
fi

banner "Sample customers and orders"
info "Waiting until the database accepts your connection (new firewall rules can take a minute)..."
if ! wait_until "a connection to ${DB}" 300 azsql "$MAIN_FQDN" "$DB" -b -Q "SELECT 1;"; then
  echo "Could not connect to ${MAIN_FQDN} with sqlcmd. Check the firewall rule and run setup.sh again."
  exit 1
fi
azsql "$MAIN_FQDN" "$DB" -b -i "${LAB_DIR}/orders-dr.sql"

banner "Setup complete"
info "Main server:  ${SQL_MAIN} (${LOCATION})"
info "DR server:    ${SQL_DR} (${SECONDARY_LOCATION})"
info "Database:     ${DB} on the main server"
info "Continue with Task 1 in the lab guide."
