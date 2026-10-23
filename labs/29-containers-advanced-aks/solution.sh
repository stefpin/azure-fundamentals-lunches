#!/usr/bin/env bash
# =============================================================================
# Lab 29 · Kubernetes for the microservices team — reference solution (Tasks 1–5).
#   bash solution.sh
# Optional overrides (set them before running):
#   AKS_NODE_SIZE=Standard_D2as_v5   another 2-vCPU, non-B-series size
#   AKS_ZONES=""                     if your size is not offered in availability zones
# Safe to re-run. The Break-it-and-fix-it exercise and the stretch goals are not included.
# Remember: an AKS cluster costs money every hour. Run cleanup.sh when you are done.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl was not found. Cloud Shell has it; on your own PC run: az aks install-cli"
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 29)"
AKS="aks-nusa"
NS="nusa"
AKS_NODE_SIZE="${AKS_NODE_SIZE:-Standard_D2s_v5}"
AKS_ZONES="${AKS_ZONES-1 2 3}"

banner "Preparing: resource provider and resource group"
az provider register --namespace Microsoft.ContainerService --wait --output none
ensure_rg "$RG" 29
info "Resource group: ${RG} (${LOCATION})"

# -----------------------------------------------------------------------------
banner "Task 1 · AKS cluster (5–10 minutes)"
if az aks show --resource-group "$RG" --name "$AKS" --output none 2>/dev/null; then
  info "Cluster ${AKS} already exists."
else
  zone_args=()
  if [[ -n "$AKS_ZONES" ]]; then
    read -r -a zones <<<"$AKS_ZONES"
    zone_args=(--zones "${zones[@]}")
  fi
  info "Creating ${AKS}: Free tier, 1 × ${AKS_NODE_SIZE}, Azure CNI Overlay..."
  az aks create \
    --resource-group "$RG" \
    --name "$AKS" \
    --location "$LOCATION" \
    --tier free \
    --node-count 1 \
    --node-vm-size "$AKS_NODE_SIZE" \
    ${zone_args[@]+"${zone_args[@]}"} \
    --network-plugin azure \
    --network-plugin-mode overlay \
    --pod-cidr 192.168.0.0/16 \
    --service-cidr 172.16.0.0/16 \
    --dns-service-ip 172.16.0.10 \
    --generate-ssh-keys \
    --output none
fi

az aks show --resource-group "$RG" --name "$AKS" \
  --query "{state:provisioningState, version:currentKubernetesVersion, tier:sku.tier, plugin:networkProfile.networkPlugin, mode:networkProfile.networkPluginMode}" \
  --output table
NODE_RG="$(az aks show --resource-group "$RG" --name "$AKS" --query nodeResourceGroup --output tsv)"
info "Node resource group (owned by AKS): ${NODE_RG}"

az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing --only-show-errors
kubectl get nodes -L topology.kubernetes.io/zone

# -----------------------------------------------------------------------------
banner "Task 2 · Deploy the storefront"
kubectl apply -f "${HERE}/k8s/namespace.yaml"
kubectl apply -f "${HERE}/k8s/deployment.yaml" -f "${HERE}/k8s/service.yaml" -f "${HERE}/k8s/pdb.yaml"
kubectl rollout status deployment/storefront --namespace "$NS" --timeout=300s

info "Waiting for the service's public IP address..."
IP=""
for _ in $(seq 1 30); do
  IP="$(kubectl get service storefront --namespace "$NS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  [[ -n "$IP" ]] && break
  sleep 10
done
if [[ -z "$IP" ]]; then
  note "The service has no external IP yet. Check: kubectl describe service storefront --namespace ${NS}"
  exit 1
fi
info "Storefront: http://${IP}"
curl -s --max-time 20 "http://${IP}/" | grep -o "<title>[^<]*</title>" || note "No answer yet; try again in a minute."

# -----------------------------------------------------------------------------
banner "Task 3 · Self-healing and manual scaling"
POD="$(kubectl get pods --namespace "$NS" -l app=storefront -o jsonpath='{.items[0].metadata.name}')"
info "Deleting pod ${POD}; the Deployment controller replaces it."
kubectl delete pod "$POD" --namespace "$NS" --wait=false
sleep 10
kubectl get pods --namespace "$NS" -l app=storefront
kubectl scale deployment storefront --namespace "$NS" --replicas=5
kubectl rollout status deployment/storefront --namespace "$NS" --timeout=180s
kubectl scale deployment storefront --namespace "$NS" --replicas=3

# -----------------------------------------------------------------------------
banner "Task 4 · Rolling update to v2, then roll back"
kubectl set env deployment/storefront --namespace "$NS" TITLE="Nusantara Retail storefront v2"
kubectl rollout status deployment/storefront --namespace "$NS" --timeout=300s
curl -s --max-time 20 "http://${IP}/" | grep -o "<title>[^<]*</title>" || true
kubectl rollout history deployment/storefront --namespace "$NS"
kubectl rollout undo deployment/storefront --namespace "$NS"
kubectl rollout status deployment/storefront --namespace "$NS" --timeout=300s
curl -s --max-time 20 "http://${IP}/" | grep -o "<title>[^<]*</title>" || true

# -----------------------------------------------------------------------------
banner "Task 5 · Horizontal Pod Autoscaler under load"
kubectl apply -f "${HERE}/k8s/hpa.yaml"
kubectl delete pod load-generator --namespace "$NS" --ignore-not-found
kubectl apply -f "${HERE}/k8s/load-generator.yaml"
for _ in $(seq 1 12); do
  sleep 15
  kubectl get hpa storefront --namespace "$NS" --no-headers || true
done
kubectl get pods --namespace "$NS" -o wide
kubectl delete pod load-generator --namespace "$NS" --ignore-not-found --wait=false
info "The HPA scales back to 3 replicas about five minutes after the load stops."

banner "Done"
info "Run 'bash verify.sh' to check your work, then 'bash cleanup.sh' straight away: the cluster costs money every hour."
