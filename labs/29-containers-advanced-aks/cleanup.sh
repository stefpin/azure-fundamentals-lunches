#!/usr/bin/env bash
# =============================================================================
# Lab 29 · Kubernetes for the microservices team — removes everything the lab created.
#   bash cleanup.sh            (asks before deleting)
#   ASSUME_YES=1 bash cleanup.sh
# Run it as soon as you finish: the cluster costs money every hour it exists.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 29)"
AKS="aks-nusa"

banner "Lab 29 clean-up"
info "This deletes every resource group tagged for lunch 29, including the AKS cluster ${AKS}."
info "When the cluster is deleted, AKS also deletes its node resource group (MC_${RG}_${AKS}_<region>)"
info "with the node VM, its disk, the load balancer and the public IP addresses. You don't delete that group yourself."

if ! confirm "Delete the lab 29 resource groups now?"; then
  info "Nothing deleted. Remember that the cluster keeps costing money while it exists."
  exit 0
fi

delete_lunch_rgs 29

# A node resource group can only be left behind by a failed deployment. Remove it once the lab group is gone
# (on a second run of this script), never while AKS is still deleting the cluster.
if [[ "$(az group exists --name "$RG" 2>/dev/null)" == "false" ]]; then
  while IFS= read -r mc; do
    [[ -z "$mc" ]] && continue
    info "Deleting leftover node resource group ${mc}..."
    az group delete --name "$mc" --yes --no-wait || true
  done < <(az group list --query "[?starts_with(name, 'MC_${RG}_')].name" --output tsv 2>/dev/null)
fi

# Remove the cluster from your local kubeconfig.
if command -v kubectl >/dev/null 2>&1; then
  kubectl config delete-context "$AKS" >/dev/null 2>&1 || true
  kubectl config delete-cluster "$AKS" >/dev/null 2>&1 || true
  kubectl config delete-user "clusterUser_${RG}_${AKS}" >/dev/null 2>&1 || true
  info "Removed the ${AKS} entries from your kubeconfig (if they were there)."
fi

info "Deletion runs in the background and usually takes 5–10 minutes."
info "Run 'bash cleanup.sh' again later to confirm that nothing is left, or check with:"
info "  az group list --query \"[?starts_with(name, 'rg-lunch29') || starts_with(name, 'MC_rg-lunch29')].name\" --output table"
