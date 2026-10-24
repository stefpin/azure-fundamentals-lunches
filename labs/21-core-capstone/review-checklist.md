# Lab 21 · Well-Architected self-review

🇮🇩 [Baca dalam Bahasa Indonesia](review-checklist.id.md)

> **Use it in:** [Task 9](README.md#task-9--do-a-well-architected-self-review-20-min) of [Lab 21 · Capstone project](README.md)
> **Time:** about 20 minutes · **Based on:** the five pillars of the [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)

A review is only useful when it is honest. For every check, look at the evidence, then mark it:

- ✅ **done** — the design does this, and you saw the proof
- ⚠️ **partly, or an accepted risk** — write down why it is acceptable *for now*
- ❌ **missing** — it goes on the improvement list

The **Lab build** column says what the provided Bicep does, so you can compare your own build (Challenge mode) as well.
Run the commands from the lab folder after `source ../common/config.sh && source lab.env`.

## Reliability — does the shop keep selling when something breaks?

| # | Check | How to see it | Lab build | Your mark | Notes / next step |
|---|---|---|---|---|---|
| R1 | The web tier runs in at least two availability zones | `az vm list -g "$RG" --query "[].{vm:name, zone:zones[0]}" -o table` | ✅ zones 1 and 2 | | |
| R2 | The entry point survives the loss of a zone | `az network public-ip show -g "$RG" -n "$PIP" --query zones` | ✅ zone-redundant IP (1, 2, 3) | | |
| R3 | The health probe tests the application, not only the port | `az network lb probe list -g "$RG" --lb-name "$LB" -o table` | ✅ HTTP GET `/health` every 5 s | | |
| R4 | The database survives the loss of a zone | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query zoneRedundant` | ⚠️ `false` to keep the lab cheap | | Production: zone-redundant |
| R5 | Backups exist **and** a restore has been tested | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query earliestRestoreDate` | ⚠️ point-in-time restore (7 days); no restore tested here | | Practise in Lab 17 |
| R6 | RTO and RPO are agreed with the business, including a region-loss plan | your Task 8 notes | ⚠️ written down; no second region | | Lunch 28: failover group |
| R7 | Resilience was tested on purpose, not assumed | your Task 4 output | ✅ zone-1 VM stopped, shop stayed open | | Repeat after every big change |

## Security — can only the right people and code reach the data?

| # | Check | How to see it | Lab build | Your mark | Notes / next step |
|---|---|---|---|---|---|
| S1 | No VM has its own public IP; no inbound SSH or RDP | `az vm list -g "$RG" -d --query "[].{vm:name, publicIp:publicIps}" -o table` | ✅ Run Command for admin tasks | | |
| S2 | The NSG allows only what the workload needs | `az network nsg rule list -g "$RG" --nsg-name "$NSG" -o table` | ✅ TCP 80 from Internet and AzureLoadBalancer | | |
| S3 | Shoppers use HTTPS | open the storefront URL | ❌ HTTP only | | TLS at Application Gateway or Front Door (Lunch 27) |
| S4 | The database accepts Microsoft Entra identities only, over TLS 1.2+ | `az sql server ad-only-auth get -g "$RG" -n "$SQL"` | ✅ | | |
| S5 | The database is not reachable from the internet | `az sql server firewall-rule list -g "$RG" -s "$SQL" -o table` | ⚠️ public endpoint on, but no firewall rules | | Private endpoint (Lunch 28) |
| S6 | Secrets live in Key Vault; roles are assigned at the narrowest scope | `az role assignment list --scope "$(az keyvault show -n "$KV" --query id -o tsv)" -o table` | ✅ Secrets Officer on the vault only | | |
| S7 | Deleted secrets and vaults cannot be purged by an attacker | `az keyvault show -n "$KV" --query properties.enablePurgeProtection` | ❌ off so cleanup can purge the lab | | Production: purge protection on |
| S8 | Defender for Cloud recommendations were reviewed | Portal › Microsoft Defender for Cloud › Recommendations | ⚠️ not part of the lab | | Free foundational CSPM (Lunch 15) |

## Cost Optimization — are we paying only for what creates value?

| # | Check | How to see it | Lab build | Your mark | Notes / next step |
|---|---|---|---|---|---|
| C1 | A budget with alerts watches the spending | `az consumption budget list -g "$RG" -o table` | ✅ after Task 7 | | |
| C2 | VM sizes fit the load | `az vm list -g "$RG" --query "[].hardwareProfile.vmSize" -o tsv` | ✅ burstable B-series | | Watch CPU credits under steady load |
| C3 | Idle resources pause or scale in | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query autoPauseDelay` | ✅ serverless pauses after 60 min | | |
| C4 | Every resource is tagged for cost reports | `az resource list -g "$RG" --query "[?tags.workload==null].name" -o tsv` (should print nothing) | ✅ `workload`, `environment` tags | | |
| C5 | Log ingestion has a ceiling and a sensible retention | `az monitor log-analytics workspace show -g "$RG" -n "$LAW" --query "{cap:workspaceCapping.dailyQuotaGb, days:retentionInDays}"` | ✅ 1 GB/day cap, 30 days | | |
| C6 | Commitment discounts are considered for steady production load | [pricing calculator](https://azure.microsoft.com/pricing/calculator/) | ⚠️ not for a lab | | Reservations or savings plan (Lunch 19) |
| C7 | Nothing runs when nobody needs it | `bash cleanup.sh` at the end | ⚠️ depends on you | | |

## Operational Excellence — can we deploy, change, observe and fix it safely?

| # | Check | How to see it | Lab build | Your mark | Notes / next step |
|---|---|---|---|---|---|
| O1 | Everything is deployed from code, previewed with what-if | `infra/` and `deploy.sh` | ✅ | | |
| O2 | Drift is detected and corrected | the Break it and fix it exercise | ⚠️ redeploy fixes drift; manual changes are still possible | | Deployment stack with deny settings (Lunch 20) |
| O3 | Alerts reach a human who can act | `az monitor action-group show -g "$RG" -n "$AG" --query emailReceivers` | ⚠️ one personal e-mail address | | Team mailbox, second channel |
| O4 | Logs are collected centrally for investigations | Task 6 KQL query | ⚠️ Key Vault audit logs only | | Azure Monitor Agent for VMs (Lunch 30) |
| O5 | A runbook exists for zone failure and for restores | your notes | ❌ | | Turn Task 4 and Task 8 notes into one page |
| O6 | Guardrails stop common mistakes before they happen | `az policy assignment list -g "$RG" -o table` | ✅ allowed locations | | Add required tags (Lunch 18) |
| O7 | Operating system patches are planned | Portal › Azure Update Manager | ⚠️ not configured | | Lunch 23 |

## Performance Efficiency — does it keep up when demand changes?

| # | Check | How to see it | Lab build | Your mark | Notes / next step |
|---|---|---|---|---|---|
| P1 | The web tier scales out, not only up | `az vm list -g "$RG" -o table` | ⚠️ fixed at two VMs | | Scale set with autoscale (Lunch 23) |
| P2 | CPU pressure is visible before shoppers feel it | `az monitor metrics alert list -g "$RG" -o table` | ✅ alert at 80% CPU | | |
| P3 | The shop was load-tested before a peak such as 12.12 | — | ❌ | | Load test in a copy of the environment |
| P4 | Static content is cached close to shoppers | — | ❌ | | Front Door caching (Lunch 27) |
| P5 | The database tier matches the workload | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query currentServiceObjectiveName` | ⚠️ the first request after a pause waits for resume | | Production: minimum capacity that never pauses |

## Trade-offs you accepted

Write each one as a single line. Future you (and the auditor) will thank you.

| Decision | Pillar it helps | Pillar it costs | Why it is acceptable here | Revisit when… |
|---|---|---|---|---|
| Database not zone-redundant | Cost | Reliability | Lab, no real orders | Real customers use it |
| Purge protection off | Operational excellence (clean teardown) | Security | Lab, no real secrets | Any production vault |
| HTTP instead of HTTPS | Simplicity | Security | No personal data in the lab | Before the first real shopper |
| | | | | |

## Your top three improvements

Pick the three marks that would hurt Nusantara Retail most, and say what you would do first.

1. …
2. …
3. …

## Score

| Pillar | ✅ | ⚠️ | ❌ |
|---|---:|---:|---:|
| Reliability | | | |
| Security | | | |
| Cost Optimization | | | |
| Operational Excellence | | | |
| Performance Efficiency | | | |

Want a second opinion? Take the free [Azure Well-Architected Review](https://learn.microsoft.com/assessments/azure-architecture-review/)
assessment for the storefront and compare its recommendations with your list.

---

⬅️ [Back to Lab 21](README.md) · 🏠 [All labs](../README.md) · 🏠 [Course home](../../README.md)

<sub>Last validated: October 2026 · Something broken? [Report a lab problem](../../CONTRIBUTING.md).</sub>
