#!/usr/bin/env bash
# =============================================================================
# Lab 23 · Clean up — deletes everything the lab created.
#   bash cleanup.sh              # asks for confirmation
#   ASSUME_YES=1 bash cleanup.sh # no prompt (for scripts and CI)
#
# Removes every resource group tagged lunch=23. Everything the lab creates lives
# inside it: the scale set and its VMs, disks and NICs, the autoscale setting,
# the load balancer, the NAT gateway, both public IPs, the network security
# group, the virtual network and the optional Spot VM. Your SSH key pair in
# ~/.ssh is kept for other labs.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Lab 23 · clean up"
if ! confirm "Delete all Lab 23 resources (resource groups tagged lunch=23)?"; then
  info "Nothing was deleted."
  exit 0
fi

delete_lunch_rgs 23
info "Your SSH key pair in ~/.ssh is kept — other labs reuse it."
info "Check later with: az group list --tag lunch=23 -o table   (it should print nothing)"
