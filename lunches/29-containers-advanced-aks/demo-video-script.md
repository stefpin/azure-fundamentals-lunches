# Lunch 29 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: a real AKS cluster
> and its node resource group, `kubectl` talking to the API server, a deleted pod replaced within seconds, a rolling
> update that never drops a request, and the Horizontal Pod Autoscaler adding pods under real load.
> **Length target:** about 5½ minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using. The
> storefront's public IP is deleted with the cluster after recording, but never show your own network's address.

## Setup before you press record

- Create the cluster in advance from Cloud Shell, exactly as in Lab 29, Task 1. It takes 5 to 10 minutes and costs
  money from now on, so record the same day:

  ```bash
  cd azure-fundamentals-lunches/labs/29-containers-advanced-aks
  source ../common/config.sh
  RG=$(rg_name 29); AKS=aks-nusa; AKS_NODE_SIZE=${AKS_NODE_SIZE:-Standard_D2s_v5}
  ensure_rg "$RG" 29
  az aks create --resource-group "$RG" --name "$AKS" --location "$LOCATION" --tier free \
    --node-count 1 --node-vm-size "$AKS_NODE_SIZE" --zones 1 2 3 \
    --network-plugin azure --network-plugin-mode overlay \
    --pod-cidr 192.168.0.0/16 --service-cidr 172.16.0.0/16 --dns-service-ip 172.16.0.10 \
    --generate-ssh-keys --output none
  az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing
  ```

- Don't apply the manifests yet; the video does that. Keep these commands ready in a text editor so you can paste
  them: the `az aks show … --output table` command and the `kubectl apply` lines from Lab 29, Tasks 1 and 2; the
  delete-pod lines from Task 3; the background shopper loop, `kubectl set env` and `kubectl rollout undo` from Task 4;
  and the HPA watch loop from Task 5.
- Browser tabs to open in advance: the Azure portal on **Kubernetes services › aks-nusa**; Cloud Shell (Bash) in a
  second tab, font size increased; an empty tab for the storefront page.
- The recording has three waits: the public IP (1–2 minutes), the rollout (about a minute) and the HPA (1–2 minutes).
  Cut them or speed them up in editing rather than talking over them.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 The cluster and its node resource group
01:10 Deploy the storefront with kubectl
02:05 Self-healing: delete a pod
02:30 A rolling update and a rollback
03:35 The HPA under load
04:50 The same objects in the portal
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 29 · A Kubernetes cluster that heals, updates and scales itself" | "In the next five minutes you'll see a real AKS cluster run Nusantara Retail's storefront: Kubernetes replacing a pod we delete, a rolling update that never drops a request, and the autoscaler adding pods under load." |
| 00:20 | Cloud Shell: the `az aks show … --output table` command from Lab 29, Task 1 (state, version, tier, plugin, mode, ranges) | "Here's our cluster. Free tier: no charge for the control plane and no uptime SLA, which is fine for a lab. Azure CNI Overlay gives pods addresses from a private range, and we moved the service range away from head office's 10.0.0.0/16." |
| 00:45 | Portal › aks-nusa › **Settings › Node pools**: one pool, one node, Standard_D2s_v5 | "One system node pool with a single two-vCPU node. Production would run at least three, spread across zones." |
| 00:55 | **Settings › Properties** › the infrastructure resource group link → the `MC_…` group: virtual machine scale set, load balancer, public IP, virtual network, network security group | "Notice what's missing: the control plane. Azure runs it for us. Our node lives here, in the node resource group that AKS created and owns. We look, but we don't change anything in here." |
| 01:10 | Cloud Shell: `kubectl get nodes -L topology.kubernetes.io/zone`, then the two `kubectl apply` lines from Task 2 | "kubectl talks to the cluster's API server. One node, Ready, with its zone label. Now we hand Kubernetes our desired state: a namespace, a Deployment with three replicas, a LoadBalancer Service and a disruption budget." |
| 01:35 | `kubectl get pods --namespace nusa -o wide`: three pods `Running`, `READY 1/1`; then `kubectl get service storefront --namespace nusa --watch` (cut the wait) | "Three pods, scheduled and started. READY one of one means the readiness probe answered. The Service asks Azure for a public IP address, which takes a minute or two." |
| 01:55 | Browser: `http://<EXTERNAL-IP>` shows the storefront page | "And there's the shop, served by whichever of the three ready pods the Service picks." |
| 02:05 | `kubectl delete pod <first pod> --namespace nusa --wait=false`, then `kubectl get pods --namespace nusa --watch` | "Now let's break something. We delete a pod, as if it had crashed. The Deployment wants three, sees two, and creates a replacement with a new name within seconds. Nobody had to do anything." |
| 02:30 | Start the background shopper loop from Task 4; `kubectl set env deployment/storefront --namespace nusa TITLE="Nusantara Retail storefront v2"`; `kubectl rollout status …` | "Time for v2. A shopper in the background calls the site twice a second while we change the pod template. Kubernetes starts one new pod, waits for its readiness probe, removes an old one, and repeats." |
| 03:00 | The shopper's tally: only `200`; `curl -s "http://${IP}/" \| grep -o "<title>[^<]*</title>"` shows v2 | "Every request got a 200. There were never fewer than three ready pods behind the Service, and the page title now says v2." |
| 03:15 | `kubectl rollout undo deployment/storefront --namespace nusa`; `kubectl rollout history …` | "If v2 had a bug, one command takes us back to the previous ReplicaSet in seconds, and the history keeps every revision." |
| 03:35 | `kubectl top pods --namespace nusa`; `kubectl apply -f k8s/hpa.yaml`; `kubectl get hpa storefront --namespace nusa` | "Now the 12.12 sale. The autoscaler measures CPU as a percentage of each pod's request, fifty millicores here, and aims for fifty percent." |
| 03:55 | `kubectl apply -f k8s/load-generator.yaml`; the 15-second `kubectl get hpa` loop from Task 5 (speed it up) | "A load generator inside the cluster plays the crowd. CPU climbs far above the target, and the HPA raises the replica count towards its maximum of ten." |
| 04:30 | `kubectl get pods --namespace nusa -o wide`: about ten pods `Running` on the node | "The new pods start in seconds because the node still has room. If it didn't, they would wait in Pending, and the cluster autoscaler would add a node." |
| 04:50 | Portal › aks-nusa › **Kubernetes resources › Workloads** › storefront: the pod list, then the deployment's events | "The portal shows the same objects without kubectl: the Deployment, its pods, and the events that explain every change." |
| 05:15 | Recap slide: "Desired state → scheduler → self-healing → rolling update → HPA" | "Three things to remember. You describe the desired state, and Kubernetes keeps making it true. Probes and requests are what let it heal, update and scale safely. And Azure runs the control plane, but the nodes are yours to pay for, so delete this cluster when you're done. Now it's your turn in Lab 29." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: AKS, kubectl, kubelet, ReplicaSet, HPA, Azure CNI
  Overlay)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources straight away, because the cluster costs money every hour:
  `bash labs/29-containers-advanced-aks/cleanup.sh` (the `MC_…` node resource group is deleted with the cluster)
