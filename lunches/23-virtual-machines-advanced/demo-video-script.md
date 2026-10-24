# Lunch 23 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the scale set creation wizard (zones, autoscale, Spot,
> health and repairs), a live scale set scaling out under load with its run history, and a patch assessment in Azure
> Update Manager. These are the parts the animation cannot show.
> **Length target:** about 5 minutes 30 seconds (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- A live scale set to show, built from the lab about 30 minutes in advance (quota: up to 6 vCPUs with the default 2-vCPU size):

  ```bash
  cd ~/azure-fundamentals-lunches/labs/23-virtual-machines-advanced
  bash setup.sh && bash solution.sh
  ```

- About **10 minutes before recording**, start CPU load on the instances so a scale-out happens while you record:

  ```bash
  source ../common/config.sh && RG=$(rg_name 23)
  for vm in $(az vm list -g "$RG" --query "[?virtualMachineScaleSet].name" -o tsv); do
    az vm run-command invoke -g "$RG" -n "$vm" --command-id RunShellScript \
      --scripts @load-cpu.sh --parameters 900 --query "value[0].message" -o tsv
  done
  ```

- Browser tabs: (1) *Virtual machine scale sets › Create* (you will cancel at the end); (2) the lab's `vmss-web`
  › *Instances*; (3) `vmss-web` › *Scaling* › *Run history*; (4) *Azure Update Manager › Machines*.
- If the scale-out hasn't happened yet when you reach chapter 5, pause recording and resume when the run history shows
  it — don't fake it.

## Chapters (paste into the video description)

```
00:00 What we'll see
00:20 A Flexible scale set across three zones
01:20 Autoscale rules in the wizard
02:00 Spot, networking, health and automatic repairs
02:40 A live scale set: instances in every zone
03:20 Load, scale-out and the run history
04:20 Patch assessment with Azure Update Manager
05:10 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 23 · Ready for 12.12" | "Nusantara Retail's 12.12 sale is coming. In five minutes you'll see how a scale set grows by itself, survives a zone failure and stays patched." |
| 00:20 | Tab 1, **Basics**: orchestration mode *Flexible*; availability zones *1, 2, 3*; security type *Trusted launch*; image *Ubuntu Server 24.04 LTS* | "Flexible orchestration is the recommended mode: every instance is an ordinary VM. I pick all three zones, so Azure spreads instances across three datacenters. Trusted Launch is on by default." |
| 00:55 | Size selector; *Instance count* 2 | "One small size for the whole set. Two instances to start — we never want fewer than two zones serving customers." |
| 01:20 | **Scaling** section: scaling mode *Autoscaling* › *Configure*: minimum 2, maximum 3, scale out when CPU > 70% for 5 minutes, scale in when CPU < 30% | "Autoscale lives in Azure Monitor. A minimum, a maximum, and two rules with a wide gap between them — out above 70, in below 30 — so the set doesn't flap." |
| 02:00 | **Spot** tab: point at *Run with Azure Spot discount*, the eviction policy and the price history link (leave it off) | "Spot capacity is much cheaper but can be taken back with about 30 seconds' notice. Fine for batch jobs; never for checkout — so I leave it off here." |
| 02:15 | **Networking** tab: virtual network, NIC network security group allowing HTTP; *Load balancing* › Azure load balancer › existing backend pool | "Instances join the load balancer's backend pool automatically. And remember: Flexible instances have no default outbound access — this subnet has a NAT gateway." |
| 02:30 | **Health** tab: *Enable application health monitoring* (HTTP, port 80, path `/health`); *Automatic repairs* on, grace period 10 minutes. Then **Cancel** the wizard | "The Application Health extension asks each instance for /health. If an instance stays unhealthy after the grace period, automatic repairs replace it. I'll cancel this one and switch to the set I built earlier." |
| 02:40 | Tab 2, `vmss-web` › **Instances**: name, zone and status columns | "Here is the live set from the lab. Each instance is a normal VM with its own name, in a different zone." |
| 03:00 | Click one instance › **Overview** › Metrics: *Percentage CPU* | "Ten minutes ago I started a CPU load on every instance. Here's the CPU at 100%." |
| 03:20 | Tab 3, **Scaling** › **Run history**: the chart of instance count and the scale-out event | "And here's autoscale's decision: average CPU stayed above 70% for five minutes, so it added an instance — straight into the zone that didn't have one." |
| 03:50 | Back to **Instances**: the new instance appears in zone 3, status *Running* | "The new VM came from the same model: same image, same cloud-init, same load balancer pool. After the cool-down and once the load stops, autoscale removes it again." |
| 04:20 | Tab 4, **Azure Update Manager › Machines**, filter to the lab's resource group; select one instance › *Check for updates*; then open the result | "Patching a fleet: Update Manager assesses the instances on demand — or every 24 hours — and shows critical, security and other updates. It needs outbound access to the Ubuntu mirrors, which the NAT gateway provides." |
| 04:50 | *Schedule updates* button, show the maintenance configuration form (don't save) | "For production you'd create a maintenance configuration — say, Tuesdays at 02:00 Jakarta time — and let it patch the whole set." |
| 05:10 | Recap slide: three bullets | "Three things to remember: zones beat availability sets for surviving a datacenter outage; autoscale needs wide thresholds and cool-downs; and Flexible instances need explicit outbound access to stay patched. Now try Lab 23 — and run its cleanup script when you're done." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Flexible orchestration*, *autoscale*, *Spot*,
  *Update Manager*, *NAT gateway*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `bash cleanup.sh` in the lab folder (it removes the resource group and everything in it).
