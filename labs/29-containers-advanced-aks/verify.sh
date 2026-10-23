#!/usr/bin/env bash
# =============================================================================
# Lab 29 · Kubernetes for the microservices team — checks the Challenge brief.
#   bash verify.sh
# Read-only for Azure resources. It refreshes your kubeconfig entry for the
# cluster (az aks get-credentials) so that kubectl can read the objects.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 29)"
AKS="aks-nusa"
NS="nusa"

# no_overlap_with_head_office <cidr>  -> succeeds when the range does NOT overlap 10.0.0.0/16
no_overlap_with_head_office() {
  python3 -c 'import ipaddress, sys; a = ipaddress.ip_network(sys.argv[1], strict=False); sys.exit(1 if a.overlaps(ipaddress.ip_network("10.0.0.0/16")) else 0)' "$1"
}

banner "Task 1 · AKS cluster"
check "Resource group ${RG} exists" az group show --name "$RG"
state="$(az_q aks show --resource-group "$RG" --name "$AKS" --query provisioningState)"
check_eq "Cluster ${AKS} provisioning state is Succeeded" "Succeeded" "$state"
if [[ -z "$state" ]]; then
  fail "Cluster ${AKS} not found in ${RG} — skipping the remaining checks (Task 1)"
  summary
  exit 1
fi

aq() { az_q aks show --resource-group "$RG" --name "$AKS" --query "$1"; }
check_eq "Pricing tier is Free" "Free" "$(aq sku.tier)"
check_eq "Network plugin is Azure CNI" "azure" "$(aq networkProfile.networkPlugin)"
check_eq "Network plugin mode is overlay (Azure CNI Overlay)" "overlay" "$(aq networkProfile.networkPluginMode)"

pod_cidr="$(aq networkProfile.podCidr)"
svc_cidr="$(aq networkProfile.serviceCidr)"
if [[ -n "$pod_cidr" ]] && no_overlap_with_head_office "$pod_cidr"; then
  pass "Pod range ${pod_cidr} does not overlap head office's 10.0.0.0/16"
else
  fail "Pod range '${pod_cidr:-<empty>}' does not overlap head office's 10.0.0.0/16"
fi
if [[ -n "$svc_cidr" ]] && no_overlap_with_head_office "$svc_cidr"; then
  pass "Service range ${svc_cidr} does not overlap head office's 10.0.0.0/16"
else
  fail "Service range '${svc_cidr:-<empty>}' does not overlap head office's 10.0.0.0/16 (the default 10.0.0.0/16 does)"
fi

sys_size="$(aq "agentPoolProfiles[?mode=='System'] | [0].vmSize")"
if [[ -n "$sys_size" && ! "${sys_size,,}" =~ ^standard_b ]]; then
  pass "System node pool uses a non-B-series size (${sys_size})"
else
  fail "System node pool uses a non-B-series size (got '${sys_size:-<empty>}')"
fi
node_rg="$(aq nodeResourceGroup)"
check_eq "Node resource group ${node_rg:-MC_...} exists" "true" "$(az group exists --name "${node_rg:-none}" 2>/dev/null)"

banner "Tasks 2–5 · Kubernetes objects"
if ! command -v kubectl >/dev/null 2>&1; then
  fail "kubectl is installed (Cloud Shell has it; on your own PC run: az aks install-cli)"
  summary
  exit 1
fi
az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing --only-show-errors >/dev/null 2>&1
KC=(kubectl --context "$AKS" --request-timeout=20s)
kq() { "${KC[@]}" "$@" 2>/dev/null || true; }

if [[ -z "$(kq get namespace "$NS" -o name)" ]]; then
  fail "Namespace ${NS} exists (Task 2)"
fi

dep_jp='{.spec.template.spec.containers[0]'
image="$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.image}")"
check_contains "Deployment storefront runs the sample image" "azuredocs/aks-helloworld" "$image"
check_ge "Deployment storefront has at least 3 ready replicas" 3 "$(kq get deployment storefront -n "$NS" -o jsonpath='{.status.readyReplicas}')"
check_nonempty "The container has a CPU request" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.resources.requests.cpu}")"
check_nonempty "The container has a memory request" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.resources.requests.memory}")"
check_nonempty "The container has a CPU limit" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.resources.limits.cpu}")"
check_nonempty "The container has a memory limit" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.resources.limits.memory}")"
check_nonempty "The container has a readiness probe" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.readinessProbe}")"
check_nonempty "The container has a liveness probe" "$(kq get deployment storefront -n "$NS" -o jsonpath="${dep_jp}.livenessProbe}")"

check_eq "Service storefront is of type LoadBalancer" "LoadBalancer" "$(kq get service storefront -n "$NS" -o jsonpath='{.spec.type}')"
ip="$(kq get service storefront -n "$NS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
check_nonempty "Service storefront has a public IP address" "$ip"
if [[ -n "$ip" ]]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "http://${ip}/" || true)"
  check_eq "http://${ip} answers with HTTP 200" "200" "$code"
fi

check_eq "HPA storefront targets the storefront deployment" "storefront" "$(kq get hpa storefront -n "$NS" -o jsonpath='{.spec.scaleTargetRef.name}')"
check_eq "HPA minimum replicas is 3" "3" "$(kq get hpa storefront -n "$NS" -o jsonpath='{.spec.minReplicas}')"
check_eq "HPA maximum replicas is 10" "10" "$(kq get hpa storefront -n "$NS" -o jsonpath='{.spec.maxReplicas}')"
check_nonempty "HPA has a CPU utilization target" \
  "$(kq get hpa storefront -n "$NS" -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}')"

waiting="$(kq get pods -n "$NS" -o jsonpath='{range .items[*]}{.status.containerStatuses[*].state.waiting.reason}{"\n"}{end}')"
stuck="$(grep -c -E 'ErrImagePull|ImagePullBackOff' <<<"$waiting" || true)"
check_eq "No pod is stuck pulling an image (Break it and fix it)" "0" "${stuck:-0}"

summary
