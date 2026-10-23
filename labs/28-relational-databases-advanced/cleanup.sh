#!/usr/bin/env bash
# =============================================================================
# Lab 28 · Clean up — deletes everything this lab created, in a safe order:
#   1. the failover group (it ties the two servers together),
#   2. the geo-replication link (deleting a failover group does NOT stop replication),
#   3. both lab resource groups (servers, databases, restored copy, Log Analytics workspace).
#   bash cleanup.sh            (set ASSUME_YES=1 to skip the question)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 28)"
RG_DR="$(rg_name 28 dr)"
SQL_MAIN="sql-nusa-main-${SUFFIX}"
SQL_DR="sql-nusa-dr-${SUFFIX}"
FOG="fog-nusa-${SUFFIX}"
DB="sqldb-orders"

banner "Lab 28 · Clean up"
if ! confirm "Delete failover group ${FOG}, both SQL servers and the lab 28 resource groups?"; then
  echo "Cancelled. Nothing was deleted."
  exit 0
fi

banner "1 · Failover group"
fog_found=0
for spec in "${RG}|${SQL_MAIN}" "${RG_DR}|${SQL_DR}"; do
  IFS='|' read -r rg server <<< "$spec"
  role="$(az_q sql failover-group show --resource-group "$rg" --server "$server" --name "$FOG" --query replicationRole)"
  if [[ "$role" == "Primary" ]]; then
    fog_found=1
    info "Deleting ${FOG} from its primary server ${server}..."
    if ! az sql failover-group delete --resource-group "$rg" --server "$server" --name "$FOG" --output none; then
      note "Could not delete the failover group; the resource group deletion below will try to remove everything anyway."
    fi
  fi
done
if (( fog_found == 0 )); then info "No failover group found."; fi

banner "2 · Geo-replication link"
link_removed=0
for spec in "${RG}|${SQL_MAIN}|${RG_DR}|${SQL_DR}" "${RG_DR}|${SQL_DR}|${RG}|${SQL_MAIN}"; do
  IFS='|' read -r rg server partner_rg partner_server <<< "$spec"
  role="$(az_q sql db replica list-links --resource-group "$rg" --server "$server" --name "$DB" --query "[0].role")"
  if [[ "$role" == "Primary" ]]; then
    info "Stopping replication from ${server} to ${partner_server}..."
    if az sql db replica delete-link --resource-group "$rg" --server "$server" --name "$DB" \
         --partner-server "$partner_server" --partner-resource-group "$partner_rg" --yes --output none; then
      link_removed=1
    else
      note "Could not remove the replication link; the resource group deletion below will try anyway."
    fi
    break
  fi
done
if (( link_removed == 0 )); then info "No active geo-replication link found."; fi

banner "3 · Resource groups"
delete_lunch_rgs 28

rm -f "${HOME}"/.azsql-token-* 2>/dev/null || true

info "Nothing else was created outside the two resource groups."
info "Check in a few minutes with: az group list --tag lunch=28 --output table"
