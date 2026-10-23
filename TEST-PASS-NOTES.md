# Test-pass notes (for the course owner)

The labs were written and checked offline: shell syntax, script logic against a stand-in Azure CLI, demo validation and
links. They have **not yet run against a live Azure subscription**, and the Bicep files have not been compiled. While you
do the first test pass (see [PUBLISHING.md](PUBLISHING.md#1-before-the-first-push-a-test-pass-in-azure)), confirm the
items below — they are the details the authors could not verify. Tick them off, fix what differs, then delete this file
or keep it as a maintenance log.

## Shared

- [ ] `labs/common/check-environment.sh`: quota rows print correctly (`az vm list-usage` names for Basv2/Bsv2/Dsv5).
- [ ] Default lab size `Standard_B2ats_v2` is available in your region and zones; Lab 25 needs 6 vCPUs (three VMs).
- [ ] The random suffix lives in `~/.azlunches-suffix`; ephemeral Cloud Shell sessions lose it, so learners must note it.

## Lunch-by-lunch

| Lab | Confirm |
|---|---|
| 01 | `az consumption budget list` output (`timeGrain`, notification thresholds; REST fallback); budgets on Azure for Students; wording of the invalid-region error |
| 02 | Pricing-calculator labels, and whether D2s v5, D4s v5, P1v3 and Azure SQL General Purpose are offered in Indonesia Central |
| 03 | Error when creating ZRS storage in a region without zones; the break-and-fix query finds a region without zones |
| 04 | `ScopeLocked` error wording; `az account management-group show` parent field; time for a lock to take effect (scripts wait 15–20 s) |
| 05 | Re-using a user name after deletion; whether deleting the resource group also removes its role assignments |
| 06 | Rule name and priority created by `az vm open-port`; default address range from `az vm create` |
| 07 | Error code for an anonymous request without a SAS (409 or 401); `--auth-mode key` file-share upload |
| 08 | `enableIPForwarding`/`privateIPAddress` casing in CLI output; `nslookup`/`dig` in Cloud Shell; Run Command in a private subnet without outbound access |
| 09 | SNAT error code; portal metric name "Health Probe Status" |
| 10 | `az webapp up` deprecation (CLI 2.87) and the replacement commands in `solution.sh` |
| 11 | sqlcmd flavour in Cloud Shell (`-G` with a token file); `iconv` availability; free-offer limit (CLI help vs docs); property `useFreeLimit` |
| 12 | Cloud Shell token for Cosmos DB data-plane RBAC; RU charge of a strong read; query-metrics header in the Python SDK |
| 13 | `--registry-identity system` grants AcrPull; `az containerapp ingress update --target-port`; whether `containerapp env create` creates a workspace |
| 14 | `az logic workflow create --definition` file format; Flex Consumption plan name in output (`Flex`/`FC1`); `__queueServiceUri` setting and queue role |
| 15 | Run Command output from a private-subnet VM; Key Vault reached through the service endpoint; `az security secure-scores` output; `purgeProtectionEnabled` field |
| 16 | Activity-log alert condition `status=Succeeded`; Service Health alert creation |
| 17 | Recovery Services vault JSON fields (security settings, job phases, recovery-point time); attaching a restored Trusted Launch OS disk as a data disk; soft-delete refusal text |
| 18 | Deny checks during `az deployment group validate`; `az policy state summarize` output shape; DeployIfNotExists evaluation delay |
| 19 | `az consumption budget create-with-rg` notification JSON (preview command); reservation prices for B2ats_v2 in your region; Resource Graph `isnull()` on public IPs |
| 20 | **Compile** `starter/` and `solution/main.bicep`; error code of the typo exercise (BCP057 or BCP082); `az stack group show` fields |
| 21 | **Compile** `infra/main.bicep` and modules; `useFreeLimit` in `az sql db show`; Key Vault log table name; `az vm wait --custom`; background CPU loop via Run Command |
| 22 | `az role definition update` with the JSON file; azure/login error when `id-token: write` is missing |
| 23 | `az vmss create` (Flexible) with the existing load balancer and NSG; `az vm assess-patches` on scale-set instances; `az vm simulate-eviction` timing; Spot quota row name |
| 24 | `--include v` on `az storage blob list`; immutability policy apply time (lab waits 45 s); `nslookup` on Ubuntu 24.04 |
| 25 | Peering next-hop label in effective routes; `az network firewall policy create` default tier (optional path) |
| 26 | Gateway SKU availability; tunnel drop after a wrong shared key; `vnet-gateway reset` duration; `connectionProtocol` value |
| 27 | `rule update` to PathBasedRouting; DRS 2.2 in your region (falls back to 2.1); F1 plan availability (`APP_SKU=B1` override); Traffic Manager failover time |
| 28 | Output fields `replicationRole`, `readWriteEndpoint.failoverPolicy`, `currentBackupStorageRedundancy`; `audit-policy update` without storage options; masking test user on an Entra-only server |
| 29 | Minimum system node pool size (docs differ); kubeconfig user name removed by `cleanup.sh`; busybox `wget` in the load generator |
| 30 | Output shapes of DCR, diagnostic-setting, web-test and scheduled-query commands; `--nsg-rule NONE`; availability-test location IDs; Syslog `SeverityLevel` value |
| 31 | `--definitions`/`--params` from files; `managementGroupAncestorsChain[0]` and `extract()` in Resource Graph; `subscription remove` returns to the root group; "Exempt" compliance state |
| 32 | `--query` paths in the acceptance checks (backend health, Entra-only auth, LTR backups); `nic show-effective-route-table --ids`; what-if for deployment stacks |
