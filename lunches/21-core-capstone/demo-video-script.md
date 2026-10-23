# Lunch 21 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: the finished capstone
> platform in the portal, a real zone failure drill, and the guardrails reacting.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses (the action group, the alert e-mail, your SQL
> administrator name), and the storefront's public IP address and DNS name if you keep the environment after recording.

## Setup before you press record

- Deploy the lab at least 30 minutes before recording, so metrics, the first database backup and the Key Vault audit
  logs exist:

  ```bash
  cd azure-fundamentals-lunches/labs/21-core-capstone
  source ../common/config.sh && source lab.env
  bash deploy.sh
  az keyvault secret show --vault-name "$KV" -n "$SECRET" --query name -o tsv   # creates one audit log entry
  ```

- Create the budget `budget-lunch21` (Lab 21, Task 7) so the Budgets page is not empty.
- Check that both servers answer: `who_answers 6`.
- Browser tabs, in this order: (1) *rg-lunch21-&lt;suffix&gt;* overview, (2) the storefront URL from the deployment
  outputs, (3) *lb-nusa-shop › Monitoring › Insights*, (4) *vm-web-1* overview, (5) *Monitor › Alerts* filtered to the
  resource group, (6) *Policy › Assignments*, (7) *Cost Management › Budgets* for the resource group, (8) *kv-nusa-&lt;suffix&gt;*,
  (9) *sql-nusa-&lt;suffix&gt;*.
- Cloud Shell open in a side pane, in the lab folder, with the names loaded (`source ../common/config.sh && source lab.env`).
- An e-mail client open in a separate window that you can show with the address blurred.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 One deployment, six modules
01:05 Follow a request: storefront and load balancer insights
01:50 Lose zone 1 — the shop stays open
03:05 Monitoring: the alert that reached the inbox
03:40 Guardrails: policy denial and the budget
04:35 Security at a glance: Key Vault and Azure SQL
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 21 · The shop that stays open" | "In the next six minutes we tour Nusantara Retail's finished core platform, switch off one availability zone on purpose, and watch the shop keep selling." |
| 00:25 | Tab 1 › *Settings › Deployments*: `capstone` plus `network`, `web`, `sql`, `keyvault`, `monitoring`, `policy` | "Everything in this resource group came from one Bicep deployment. Each module shows up as its own nested deployment, in the order Bicep worked out from the outputs. Nobody clicked these resources into existence." |
| 00:45 | Tab 1 › *Resource visualizer* | "The resource visualizer draws how they connect: one public IP, one load balancer, two network cards, two VMs — plus the database, the vault and the monitoring pieces." |
| 01:05 | Tab 2: refresh the storefront a few times | "Here is the storefront. Each new connection can land on a different server: vm-web-1 in zone 1 or vm-web-2 in zone 2." |
| 01:25 | Tab 3: *Insights* diagram, hover over the probe and both backends | "Load balancer Insights shows the frontend, the rule on port 80, the health probe on slash-health, and both backends healthy." |
| 01:50 | Cloud Shell: start `watch_shop 120` | "Now the drill. In Cloud Shell, watch_shop requests the page every two seconds and prints which server answered." |
| 02:05 | Tab 4: *vm-web-1 › Stop*, confirm | "I stop vm-web-1 — everything we run in zone 1. This is the closest a customer can get to switching off a datacenter." |
| 02:25 | Cloud Shell: a mix, maybe one *(no answer)*, then only `vm-web-2` | "One or two requests miss while the probe notices, then every answer comes from zone 2. No setting changed. Those few seconds are our measured recovery time for a zone failure." |
| 02:45 | Tab 3 › *Metrics*: Health Probe Status, split by Backend IP Address | "The load balancer's view agrees: the line for vm-web-1 stops, because a stopped VM isn't probed at all." |
| 03:05 | Tab 5: the fired *alert-web-vm-stopped*; then the e-mail (address blurred) | "Within minutes the activity log alert fires and the action group e-mails the on-call engineer. Monitoring noticed before any shopper complained." |
| 03:25 | Tab 4: *vm-web-1 › Start* | "I start vm-web-1 again. As soon as it answers the probe, it rejoins the rotation by itself." |
| 03:40 | Cloud Shell: `az network nsg create -g "$RG" -n nsg-policy-test --location eastus` → `RequestDisallowedByPolicy` | "Now the guardrails. Even an empty network security group in East US is refused. The Allowed locations policy denies it, and the error carries the message we wrote into the assignment." |
| 04:05 | Tab 6: the `allowed-locations` assignment on the resource group | "The assignment sits on the resource group and allows only our region. Policy acts before anything is built." |
| 04:20 | Tab 7: `budget-lunch21` with its 50, 80 and 100 percent alerts | "And Cost Management watches the money: a budget with alerts at 50, 80 and 100 percent. It warns; it never switches anything off." |
| 04:35 | Tab 8: *Access control (IAM) › Role assignments*, then *Secrets* | "Key Vault uses Azure RBAC. I hold Key Vault Secrets Officer on this vault only, and the connection string inside contains no password at all…" |
| 04:55 | Tab 9: *Settings › Microsoft Entra ID*, "Support only Microsoft Entra authentication" checked | "…because Azure SQL accepts only Microsoft Entra identities. There is no SQL login to leak." |
| 05:15 | Recap slide: the RTO and RPO table from the reading | "Three things to remember. Spread the stateless tier across zones. Back up everything that holds state, and test the restore. And put the guardrails — alerts, policy, budget — into code from day one. Then run cleanup.sh." |
| 05:45 | End card with the Lab 21 link | "Build it yourself in Lab 21, and see you in the deep-dive month." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Microsoft Entra ID, Key Vault, Bicep, what-if)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in `labs/21-core-capstone`
