#!/usr/bin/env bash
# =============================================================================
# Lab 25 · cleanup.sh — deletes everything the lab created.
#   bash cleanup.sh
# Removes the resource group rg-lunch25-<suffix>: three VMs with their disks
# and NICs, three virtual networks with their peerings, the route tables and,
# if you took the optional path, Azure Firewall, its policy and public IP.
# Deletion continues in the background for a few minutes.
# =============================================================================
set -euo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Lab 25 · Clean up"
delete_lunch_rgs 25

info "Nothing else to remove: the lab creates no resources outside its resource group."
info "Network Watcher (resource group NetworkWatcherRG) is a free, shared regional resource that Azure"
info "enabled for you; other labs use it too, so it stays. Your SSH key in ~/.ssh is reused by other labs."
info "Check progress with:  az group list --tag lunch=25 -o table"
