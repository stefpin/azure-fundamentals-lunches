#!/usr/bin/env bash
# =============================================================================
# Lab 08 · cleanup.sh — deletes everything the lab created.
#   bash cleanup.sh
# Removes the resource group rg-lunch08-<suffix> (VMs, disks, NICs, public IPs,
# NAT gateway, NSGs, ASG, virtual network and DNS zone). Deletion continues in
# the background for a few minutes.
# =============================================================================
set -euo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Lab 08 · Clean up"
delete_lunch_rgs 08

info "Nothing else to remove: the lab creates no resources outside its resource group."
info "Network Watcher (resource group NetworkWatcherRG) is a free, shared regional resource that Azure"
info "enabled for you; other labs use it too, so it stays. Your SSH key in ~/.ssh is reused by other labs."
info "Check progress with:  az group list --tag lunch=08 -o table"
