# Syllabus — Azure Fundamentals: One Lunch at a Time

🇮🇩 [Baca dalam Bahasa Indonesia](SYLLABUS.id.md)

This is the detailed outline of every lunch: what the reading covers, what the interactive demo shows, and what the
independent lab builds. The course has **31 lunches** in two "months":

- **Core month (Lunches 01–21, Basic):** every fundamental Azure service at the level you need to explain, choose and
  use it. About four weeks of weekday lunches. Aligned with the AZ-900 skills outline (skills measured as of July 20, 2026).
- **Deep-dive month (Lunches 22–31, Advanced):** the advanced half of every topic that is too big for one hour. About two
  weeks of weekday lunches. Leans towards day-to-day administrator and architect work (AZ-104 territory).
- **Advanced capstone challenge (lab only):** a requirements-only project that pulls the deep dives together.

Topics that do not fit into one hour are split into a **Basic** lunch (core month) and an **Advanced** lunch (deep-dive month):

| Topic | Basic (core month) | Advanced (deep-dive month) |
|---|---|---|
| Resource hierarchy & governance | 04 Resource hierarchy & ARM · 18 Governance & compliance | 31 Governance at scale |
| Identity & access | 05 Identity & access (Basic) | 22 Identity & access (Advanced) |
| Virtual machines | 06 Virtual machines (Basic) | 23 Virtual machines (Advanced) |
| Storage | 07 Storage (Basic) | 24 Storage (Advanced) |
| Networking | 08 Virtual networking (Basic) | 25 Virtual networking (Advanced) · 26 Hybrid connectivity |
| Load balancing | 09 Load balancing (Basic) | 27 Load balancing (Advanced) |
| Relational databases | 11 Relational databases (Basic) | 28 Relational databases (Advanced) |
| Containers | 13 Containers (Basic) | 29 Containers (Advanced): AKS |
| Monitoring | 16 Monitoring (Basic) | 30 Monitoring (Advanced) |

Single-lunch topics: cloud concepts, global infrastructure, App Service, Cosmos DB, serverless, security essentials,
backup & DR, cost management, infrastructure as code, and the core capstone.

**Running scenario.** You are the new cloud engineer at **Nusantara Retail** (PT Nusantara Retail), a mid-sized retailer
with forty stores and one e-commerce site that still runs on a single physical server in a small room next to the pantry.
Traffic has tripled; the server has not. At the last monthly meeting the director asked: *"If that server dies, how long
can't we sell?"* Nobody answered. Every lunch moves Nusantara Retail one step closer to an answer.

**Cost bands used by the labs:** 💲 free or close to free · 💲💲 small charges while running (typically cents per hour) ·
💲💲💲 noticeable charges while running or slow-to-create gateways — delete immediately after the lab.

---

## Core month — Part 1 · Foundations

### Lunch 01 · Before You Begin: Your Azure Lab, Tools and Cost Guardrails (Basic)
- **Reading:** how the course works (lunch anatomy, two months, independent labs); meet Nusantara Retail; getting an Azure
  subscription (free account, Azure for Students, pay-as-you-go; spending limit; use a personal or dedicated lab
  subscription, never a production or company one); the three ways in — Azure portal, Azure Cloud Shell (Bash/PowerShell),
  Azure CLI and Azure PowerShell on your PC (plus VS Code); what happens when you click "Create" (requests go through
  Azure Resource Manager to resource providers); lab conventions (one region, one resource group per lab, naming,
  tags, the random suffix); cost guardrails (budgets and alerts, auto-shutdown, cost bands, cleanup habit); account safety (MFA).
- **Demo (animation):** "From click to resource" — portal, CLI and PowerShell requests all flow through Azure Resource
  Manager to resource providers; a budget gauge fills to 50/80/100% and sends alerts; deleting a resource group removes
  everything inside it.
- **Video idea:** tour of the portal, opening Cloud Shell, cloning the repo, creating a budget.
- **Lab 01 · Set up your lab environment (≈30 min, 💲):** open Cloud Shell (Bash), clone the repo, run
  `check-environment.sh`; create a monthly budget with 50/80/100% alerts in Cost Management (portal); create a tagged
  resource group with the CLI, look at it in the portal, delete it; optional local tools. *Break & fix:* use a region
  name with a typo and read the error. Verify: signed in, subscription enabled, budget exists, no leftover lunch-01 group.

### Lunch 02 · Cloud Concepts (Basic)
- **Reading:** what cloud computing is; the shared responsibility model (on-premises vs IaaS vs PaaS vs SaaS); public,
  private, hybrid and multicloud; CapEx vs OpEx and the consumption-based model; benefits — high availability,
  scalability (vertical/horizontal), elasticity, reliability, predictability, security, governance, manageability;
  IaaS, PaaS, SaaS (and serverless) with use cases; applied to Nusantara Retail's single-server problem.
- **Demo (animation):** a shared-responsibility "slider" (on-prem → IaaS → PaaS → SaaS shows who owns each layer), then
  fixed on-prem capacity vs elastic cloud capacity under a traffic spike (wasted capacity vs outage vs right-sized).
- **Video idea:** using the Azure pricing calculator to compare a VM-based and a PaaS-based design.
- **Lab 02 · Make the business case (≈40 min, 💲, no resources created):** pricing-calculator estimates for two designs;
  a classification worksheet (IaaS/PaaS/SaaS, CapEx/OpEx, who-is-responsible) with answers in collapsible blocks;
  a one-page recommendation for the director. Optional: list Azure regions and resource providers with the CLI.

### Lunch 03 · Azure Global Infrastructure: Regions, Availability Zones and Region Pairs (Basic)
- **Reading:** datacenters, regions, geographies; availability zones (separate power, cooling, networking) and
  zonal vs zone-redundant vs regional services; region pairs (what they give you and what they don't — no automatic
  replication) and newer regions without a pair (for example Indonesia Central); sovereign clouds; how to choose a region
  (data residency and compliance, latency, service and SKU availability, price, zones, DR options).
- **Demo (animation):** zoom from the globe to a geography, a region, its three zones and datacenters; a zone failure
  takes out a zonal resource while a zone-redundant one survives; paired vs non-paired region DR choices.
- **Video idea:** regions map, checking service availability by region, zone options when creating resources.
- **Lab 03 · Explore regions and zones (≈35 min, 💲):** CLI queries for regions, pairs and zone-capable VM sizes;
  create a zone-redundant and a zonal Standard public IP and compare; create LRS vs ZRS storage accounts and compare
  their properties; optional latency test from your browser. Verify: two public IPs with the expected zone settings, a ZRS account.

### Lunch 04 · Resource Hierarchy and Azure Resource Manager (Basic)
- **Reading:** tenant (Microsoft Entra ID) → root management group → management groups → subscriptions → resource groups
  → resources; Azure Resource Manager (ARM) as the single control plane; control plane vs data plane; resource providers
  and resource types; anatomy of a resource ID; scopes and inheritance (RBAC, Policy, budgets, locks); subscriptions as
  billing and scale boundaries; resource group rules (lifecycle, location, moving resources); naming conventions
  (Cloud Adoption Framework abbreviations); tags (not inherited by default); locks (CanNotDelete, ReadOnly and their
  surprises); Azure Resource Graph. Advanced design is in Lunch 31.
- **Demo (animation):** build the hierarchy level by level; show inheritance cascading down (a role at a management
  group, a policy at a subscription, a lock on a resource group); dissect a resource ID.
- **Video idea:** navigating management groups/subscriptions/resource groups in the portal, tags, locks.
- **Lab 04 · Organise Nusantara Retail (≈40 min, 💲):** two tagged resource groups; a storage account; read its resource
  ID; CanNotDelete lock blocks deletion; ReadOnly lock blocks listing keys (a POST action); move a resource between
  groups; Resource Graph queries by tag; optional management group. *Break & fix:* the lock. Verify: tags, moved resource, no lock left behind.

### Lunch 05 · Identity and Access (Basic)
- **Reading:** authentication vs authorization; Microsoft Entra ID (tenants, users, groups, guests, app registrations at a
  glance), Entra ID vs on-premises AD DS (Entra Connect, Entra Domain Services); MFA, passwordless (Windows Hello, FIDO2
  security keys and passkeys, Microsoft Authenticator) and SSO; Conditional Access (signals → decision → enforcement);
  external identities; Azure RBAC — security principal, role definition, scope, role assignment; built-in roles (Owner,
  Contributor, Reader, User Access Administrator, Role Based Access Control Administrator); additive permissions and deny
  assignments; Entra roles vs Azure roles; least privilege; a first look at Zero Trust.
- **Demo (animation):** "Can Dewi restart the VM?" — authentication, then role assignments collected from every scope,
  union of permissions, allowed or denied; then a Conditional Access sign-in decision.
- **Video idea:** creating a user and group, assigning a role at resource-group scope, "Check access".
- **Lab 05 · Give a contractor just enough access (≈40 min, 💲):** in **your own** Entra tenant (not a company tenant):
  create a test user and group; assign Reader then Contributor at resource-group scope; sign in as the test user in a
  private browser window and see the difference; list effective assignments with the CLI. *Break & fix:* a role at the
  wrong scope. Verify: user, group membership, the expected role at the expected scope. Cleanup removes user, group and assignments.

## Core month — Part 2 · Core infrastructure

### Lunch 06 · Virtual Machines (Basic)
- **Reading:** when IaaS VMs are the right tool; building blocks — image, size (series families, burstable B-series),
  OS disk, temporary disk, data disks, managed disk types (Standard HDD, Standard SSD, Premium SSD, Premium SSD v2, Ultra
  Disk), NIC, virtual network and subnet, Standard public IP, NSG; authentication (SSH keys, passwords, Entra ID login);
  connecting (SSH, RDP, Azure Bastion, Run Command, serial console); VM states and billing (running, stopped,
  deallocated); resizing; auto-shutdown; cloud-init and extensions at a glance; pricing options (pay-as-you-go,
  reservations, savings plan, Spot, Azure Hybrid Benefit); explicit outbound access for new virtual networks.
- **Demo (animation):** "What really gets created when you create a VM" — resources appear one by one; an SSH packet
  passes the NSG while HTTP is blocked until port 80 is opened; deallocating stops the compute meter but not the disk meter.
- **Video idea:** creating a Linux VM in the portal and connecting from Cloud Shell.
- **Lab 06 · Your first web server VM (≈45 min, 💲💲):** Ubuntu VM with the CLI (portal path shown too); SSH in, install
  nginx, publish a Nusantara Retail page; open port 80; add and mount a data disk; resize; configure auto-shutdown;
  compare stopped vs deallocated. *Break & fix:* delete the port-80 rule. Verify: VM, rule, data disk, schedule, HTTP 200.

### Lunch 07 · Storage (Basic)
- **Reading:** storage accounts (types, performance tiers, endpoints, naming); redundancy — LRS, ZRS, GRS, GZRS and the
  read-access variants, and what each survives; services — Blob (containers; block, append and page blobs), Azure Files
  (SMB/NFS, Azure File Sync), Queue, Table; blob access tiers (hot, cool, cold, archive; early-deletion periods;
  rehydration); securing access — Microsoft Entra ID + RBAC data roles, shared keys, SAS (prefer user-delegation SAS),
  anonymous access off; tools and data movement — Storage browser, Azure Storage Explorer, AzCopy, Azure File Sync, Data Box.
- **Demo (animation):** redundancy chooser — copies across disks, zones and regions under failures (disk, datacenter,
  zone, region); then the access-tier seesaw (storage cost vs access cost).
- **Video idea:** creating an account, uploading with Storage browser, changing a tier, generating a SAS.
- **Lab 07 · Store product images and invoices (≈45 min, 💲):** secure StorageV2 account (TLS 1.2, no anonymous access);
  give yourself a data role; container upload with the CLI and AzCopy; change tiers; user-delegation SAS with expiry;
  Azure Files share. *Break & fix:* expired SAS → 403. Verify: account settings, blobs, a Cool blob, the file share.

### Lunch 08 · Virtual Networking (Basic)
- **Reading:** virtual networks and address spaces (CIDR, private ranges, planning for no overlap with on-premises);
  subnets (the five reserved addresses); NICs; private and public IP addresses (Standard SKU only); network security
  groups (rules, priorities, default rules, service tags, subnet vs NIC, effective rules) and application security groups;
  Azure DNS (public zones, Azure-provided name resolution); outbound connectivity (private subnets by default in new
  virtual networks; NAT gateway, load balancer outbound rules or a public IP); public vs private endpoints (intro);
  Network Watcher (IP flow verify, connection troubleshoot, flow logs).
- **Demo (animation):** an NSG rule evaluator — packets meet subnet and NIC NSGs, rules are checked by priority, first
  match wins; SSH from the internet, HTTP, VM-to-VM, and outbound internet from a private subnet with and without a NAT gateway.
- **Video idea:** building a virtual network with subnets and NSGs; IP flow verify.
- **Lab 08 · Build Nusantara Retail's network (≈50 min, 💲💲):** VNet 10.20.0.0/16 with web and app subnets; NSGs and an
  ASG; a web VM (public IP) and an app VM (private only) behind a NAT gateway; test traffic; diagnose with IP flow verify;
  public DNS zone and records. *Break & fix:* a higher-priority deny rule. Verify: VNet, subnets, NSGs, ASG, NAT gateway, DNS record.

### Lunch 09 · Load Balancing (Basic): Azure Load Balancer
- **Reading:** why load balance; layer 4 vs layer 7; Azure Load Balancer Standard (Basic SKU retired on September 30,
  2025); public vs internal; frontend IP configuration, backend pools, health probes, load-balancing rules and
  distribution (5-tuple hash, session persistence), inbound NAT rules, outbound rules and SNAT; zone-redundant frontends;
  HA ports; gateway and cross-region load balancers at a glance; a first look at choosing between Load Balancer,
  Application Gateway, Front Door and Traffic Manager (deep dive in Lunch 27).
- **Demo (animation):** requests spread across two VMs in two zones; one VM fails its health probe and drops out of
  rotation; recovery; outbound connections through an outbound rule.
- **Video idea:** creating a Standard load balancer in the portal and watching backend health.
- **Lab 09 · Keep the shop open when a server fails (≈50 min, 💲💲):** `setup.sh` creates a VNet and two web VMs in zones
  1 and 2 (no public IPs); you create a Standard public load balancer with a zone-redundant frontend, probe, rule,
  inbound NAT rule and outbound rule; watch traffic alternate; stop one web server and watch failover. Verify: SKU,
  probe, rule, two healthy backends, HTTP 200 through the frontend.

## Core month — Part 3 · Platform services and data

### Lunch 10 · Web Apps with Azure App Service
- **Reading:** PaaS for web apps and APIs; App Service plans (OS, region, pricing tiers, scale up vs scale out,
  autoscale); runtime stacks and containers; deployment options (`az webapp up`, zip deploy, GitHub Actions, deployment
  center); configuration (app settings, connection strings, Key Vault references); deployment slots and swap; custom
  domains and managed certificates; built-in authentication; access restrictions, VNet integration and private endpoints
  at a glance; log stream and Application Insights; App Service vs VMs vs Container Apps vs Static Web Apps.
- **Demo (animation):** requests through the App Service front ends to workers; scale out; a staging slot warms up and
  swaps into production with no downtime.
- **Video idea:** deploying from the CLI, app settings, log stream, a slot swap.
- **Lab 10 · Move the storefront to PaaS (≈45 min, 💲 / 💲💲 for the slot stretch):** deploy the provided small web app
  with `az webapp up` on the Free tier; app settings; HTTPS only; log stream; stretch: Standard plan, staging slot, swap.
  *Break & fix:* a broken app setting → error page. Verify: app running, setting present, HTTP 200 with the expected text.

### Lunch 11 · Relational Databases (Basic): Azure SQL
- **Reading:** relational vs non-relational data; choosing a database on Azure (Azure SQL family, Azure Database for
  PostgreSQL/MySQL flexible server, Azure Cosmos DB); Azure SQL deployment options (SQL Database single and elastic pool,
  SQL Managed Instance, SQL Server on Azure VMs); logical servers; purchasing models (DTU vs vCore), service tiers
  (General Purpose, Business Critical, Hyperscale), serverless auto-pause and the free offer; connectivity (server
  firewall rules, private endpoints later); Microsoft Entra authentication (Entra-only); built-in backups and point-in-time
  restore at a glance; tools (Query editor, VS Code, sqlcmd).
- **Demo (animation):** an interactive "which database?" decision tree; a connection passing the gateway and firewall;
  serverless auto-pause and resume.
- **Video idea:** creating a database with Entra-only authentication and querying it in the portal.
- **Lab 11 · Nusantara Retail's orders database (≈45 min, 💲):** logical server with Entra-only auth; serverless or
  free-offer database; firewall rule for your client; create and query an Orders table with sqlcmd and Query editor.
  *Break & fix:* connection blocked by the firewall. Verify: Entra-only auth, database, firewall rule, rows in the table.

### Lunch 12 · NoSQL with Azure Cosmos DB
- **Reading:** NoSQL data models (document, key-value, column-family, graph); Cosmos DB APIs; account → database →
  container → items; partitioning and choosing a partition key (avoid hot partitions); request units, provisioned
  (manual/autoscale) vs serverless capacity, free tier; global distribution, multi-region writes; the five consistency
  levels and their trade-offs; automatic indexing; change feed; when to choose Cosmos DB vs Azure SQL.
- **Demo (animation):** items landing in logical partitions by key (good vs hot partition key); a write in one region
  read from another under different consistency levels.
- **Video idea:** Data Explorer — create a container, add items, run queries and read the RU charge.
- **Lab 12 · A product catalogue that scales (≈45 min, 💲):** Cosmos DB for NoSQL (serverless or free tier); container
  partitioned by `/category`; load sample items with the provided script; point reads vs cross-partition queries and
  their RU cost; change default consistency. *Break & fix:* an expensive query, then add the partition key filter.
  Verify: account, API, container and partition key, item count.

### Lunch 13 · Containers (Basic): Container Registry, Container Instances and Container Apps
- **Reading:** containers vs VMs; images, registries, tags; Azure Container Registry (SKUs, authentication, import and
  build tasks); Azure Container Instances (fast single containers, per-second billing); Azure Container Apps
  (environments, revisions, ingress, scale rules, scale to zero, Dapr at a glance); when to move to AKS (Lunch 29);
  comparison table (ACI vs Container Apps vs AKS vs App Service for containers).
- **Demo (animation):** build → push → run; Container Apps scaling 0 → 1 → 5 → 0 replicas with HTTP load; a revision traffic split 80/20.
- **Video idea:** creating a container app from an image and watching replicas scale.
- **Lab 13 · Package the storefront (≈45 min, 💲):** registry; import a public sample image; run it in ACI; deploy it to
  Container Apps with external ingress and a scale rule (min 0); generate load; new revision with a traffic split.
  *Break & fix:* wrong target port. Verify: image in the registry, ACI running, container app with ingress and min replicas 0.

### Lunch 14 · Serverless: Azure Functions, Logic Apps and Event Grid
- **Reading:** what serverless means (event-driven, pay per execution, scale to zero); Azure Functions (triggers and
  bindings, languages, hosting plans: Flex Consumption, Premium, Dedicated, Container Apps; cold starts; Durable
  Functions); Logic Apps (Consumption vs Standard, connectors, the designer); events vs messages — Event Grid, Service
  Bus, Event Hubs, Storage queues (decision table); Functions vs Logic Apps.
- **Demo (animation):** a product image uploaded → event → function runs → thumbnail stored; a burst of events scales
  function instances out and back to zero; a Logic App workflow lighting up step by step.
- **Video idea:** creating a function app, testing an HTTP trigger, building a small Logic App.
- **Lab 14 · React to new orders automatically (≈50 min, 💲):** Flex Consumption function app with an HTTP-triggered
  function (provided code) that writes to a storage queue; a Consumption Logic App that calls it on a schedule or HTTP
  request. *Break & fix:* a missing app setting. Verify: function app, function responds, queue receives messages, Logic App enabled.

## Core month — Part 4 · Secure, operate and govern

### Lunch 15 · Security Essentials: Defense in Depth, Key Vault and Defender for Cloud
- **Reading:** defense in depth layers; Zero Trust principles (verify explicitly, least privilege, assume breach); the
  shared responsibility model revisited; Microsoft Defender for Cloud (free foundational CSPM, secure score,
  recommendations, Defender plans); Azure Key Vault (secrets, keys, certificates; RBAC permission model; soft delete and
  purge protection); managed identities (system- vs user-assigned) — no secrets in code; encryption at rest and in transit;
  Azure Firewall, DDoS Protection and WAF at a glance; Microsoft Sentinel at a glance.
- **Demo (animation):** an attacker path stopped at successive defense layers; a VM getting a token from the managed
  identity endpoint and reading a Key Vault secret — first denied, then allowed after a role assignment.
- **Video idea:** Key Vault with RBAC, a managed identity, secure score in Defender for Cloud.
- **Lab 15 · Get the password out of the config file (≈45 min, 💲💲):** Key Vault (RBAC model) and a secret; a VM with a
  system-assigned identity; read the secret from the VM with Run Command (403 before the role, success after); review
  secure score and recommendations. Verify: RBAC vault, secret, role assignment, successful read. Cleanup also purges the soft-deleted vault.

### Lunch 16 · Monitoring (Basic): Azure Monitor, Alerts, Service Health and Advisor
- **Reading:** why monitor; Azure Monitor — metrics vs logs, activity log, resource logs and diagnostic settings, Log
  Analytics workspaces (intro), alerts (metric, log search, activity log) and action groups, dashboards and workbooks;
  Application Insights at a glance; Azure Service Health vs Resource Health; Azure Advisor recommendations.
- **Demo (animation):** a CPU metric crosses a threshold → alert fires → action group emails the on-call engineer; the
  activity log answers "who deleted my VM?"; Service Health vs Resource Health scope.
- **Video idea:** creating an action group and a metric alert, reading the activity log.
- **Lab 16 · Know before customers do (≈45 min, 💲💲):** `setup.sh` creates a small VM; action group with your email;
  CPU metric alert; generate CPU load with Run Command and receive the alert; activity log alert; Service Health alert;
  Advisor recommendations. *Break & fix:* an alert that never fires. Verify: action group, alerts enabled.

### Lunch 17 · Backup and Disaster Recovery
- **Reading:** high availability vs disaster recovery vs backup; RPO and RTO; Azure Backup (Recovery Services vault vs
  Backup vault, policies, what can be protected, instant restore); protecting backups (soft delete, immutability,
  multi-user authorization); restore options (VM, disks, files); Azure Site Recovery (replication, test failover,
  zone-to-zone and region-to-region); built-in backups of PaaS services; DR planning for regions without a pair; test your restores.
- **Demo (animation):** RPO/RTO on a timeline; ransomware deletes backups — soft delete saves them; Site Recovery failover to a second region.
- **Video idea:** enabling VM backup, running a backup, file recovery.
- **Lab 17 · The restore drill (≈60–90 min, mostly waiting, 💲💲):** `setup.sh` creates a VM with an orders file;
  Recovery Services vault (soft delete disabled for the lab only, with a production warning); enable backup; on-demand
  backup; "lose" the file; restore it. Verify: vault, protected VM, recovery point. Cleanup stops protection, deletes data and vault.

### Lunch 18 · Governance and Compliance (Basic): Azure Policy, Locks, Tags and Microsoft Purview
- **Reading:** what governance means; Azure Policy (definitions, initiatives, assignments, scopes, parameters; effects
  Deny, Audit, Modify, Append, DeployIfNotExists, AuditIfNotExists, Disabled; compliance; exemptions; built-in and
  regulatory initiatives); resource locks revisited; tagging strategy and enforcement; Microsoft Purview (data governance
  and compliance) at a glance; Service Trust Portal and Microsoft's privacy statement; Azure Blueprints is retired (phased
  out from July 31, 2026, fully retired January 31, 2027) — use Azure Policy plus deployment stacks and template specs.
- **Demo (animation):** a deployment request meets the policy engine — allowed-locations deny; existing resources
  audited into a compliance view; a Modify policy adds a missing tag automatically.
- **Video idea:** assigning a built-in policy and watching a non-compliant deployment fail.
- **Lab 18 · Keep data in the right place (≈45 min, 💲):** assign "Allowed locations", "Require a tag on resources" and
  "Inherit a tag from the resource group if missing" at resource-group scope; prove denials; remediate; read compliance.
  Verify: assignments and compliance state.

### Lunch 19 · Cost Management
- **Reading:** what drives cost (resource type and size, consumption, region, data transfer out, licences); the pricing
  calculator; purchase options (pay-as-you-go, reservations, savings plan for compute, Spot, Azure Hybrid Benefit,
  dev/test pricing); Cost Management (cost analysis, budgets and alerts, anomaly alerts, exports); Advisor cost
  recommendations; tags for showback; FinOps basics; common waste (unattached disks, unused public IPs, oversized or idle resources).
- **Demo (animation):** a bill decomposed into compute, storage and network; an "orphan hunt" lighting up unused
  resources; budget alerts at 50/80/100%.
- **Video idea:** cost analysis grouped by tag and resource group; creating a budget.
- **Lab 19 · Find the waste you made yourself (≈40 min, 💲):** `setup.sh` creates cheap "waste" (an unattached disk, an
  unused public IP, an idle plan); find it with Resource Graph and Advisor; analyse costs by tag; create a resource-group
  budget; compare pay-as-you-go vs reservation prices in the calculator; remove the waste. Verify: no orphans left, budget exists.

### Lunch 20 · Infrastructure as Code with Bicep
- **Reading:** why infrastructure as code; declarative vs imperative; ARM templates, Bicep and Terraform; Bicep anatomy
  (parameters, variables, resources, symbolic names, implicit dependencies, outputs, modules, loops, conditions,
  decorators); deployment scopes and modes; what-if; template specs; deployment stacks (lifecycle + deny settings, the
  recommended replacement for Blueprints); Azure Verified Modules; GitHub Actions with OpenID Connect at a glance.
- **Demo (animation):** a Bicep file "types itself" while resources appear; a what-if diff (+ create, ~ modify, − delete);
  redeploying changes nothing; delete the group and rebuild in minutes.
- **Video idea:** writing a Bicep file in VS Code, what-if, deploy, redeploy.
- **Lab 20 · Nineteen lunches of clicks in one file (≈50 min, 💲):** complete a starter `main.bicep` (storage, VNet with two
  subnets, NSG, Log Analytics workspace); build, what-if, deploy, change, redeploy; deploy as a deployment stack with
  deny settings and watch a manual delete fail; delete the stack. *Break & fix:* a compile error. Verify: resources, tags, stack.

### Lunch 21 · Core Capstone: Putting It All Together
- **Reading:** the Azure Well-Architected Framework pillars (reliability, security, cost optimization, operational
  excellence, performance efficiency) and their trade-offs; the Cloud Adoption Framework at a glance (landing zones);
  Nusantara Retail's target architecture (zone-resilient web tier, Azure SQL, Key Vault, monitoring, backup, policy,
  budget, everything as code); answering the director's question with RTO and RPO; next steps — AZ-900 preparation and the deep-dive month.
- **Demo (animation):** an end-to-end request through the target architecture; a zone fails and the shop stays open;
  monitoring, budget and policy guardrails light up.
- **Video idea:** walking through the deployed capstone in the portal.
- **Lab 21 · Capstone project (≈2–3 hours, can be split, 💲💲):** deploy the core platform from the provided modular Bicep
  (network, two web VMs in two zones behind a Standard load balancer, Azure SQL, Key Vault, Log Analytics and an alert,
  an allowed-locations policy); prove zone resilience; check monitoring; self-review against a Well-Architected checklist.
  Challenge mode gives requirements only. Verify checks every component.

---

## Deep-dive month — Advanced lunches

### Lunch 22 · Identity and Access (Advanced)
- **Reading:** managed identities in depth (system vs user-assigned, lifecycle, `DefaultAzureCredential`); app
  registrations vs service principals; secrets and certificates vs workload identity federation (OpenID Connect for
  GitHub Actions and Kubernetes); Conditional Access policies (conditions, grant and session controls, report-only);
  Privileged Identity Management (eligible vs active, just-in-time activation, approval); custom roles (actions,
  notActions, dataActions, assignable scopes); access reviews; emergency-access accounts; licensing notes (Entra ID P1/P2);
  External ID for partners and customers.
- **Demo (animation):** GitHub Actions → OIDC token → federated credential → access token → deployment, with no stored
  secret; a PIM activation timeline (eligible → activate → active for two hours → expires).
- **Lab 22 · Passwordless pipelines and least privilege (≈50 min, 💲):** custom "VM Operator" role; user-assigned managed
  identity granted a data role; app registration with a federated credential for a GitHub repository plus a sample
  workflow; optional Conditional Access/PIM walkthrough (needs P1/P2 licences or trials). Verify: role definition,
  identity and role assignment, federated credential.

### Lunch 23 · Virtual Machines (Advanced)
- **Reading:** availability options and SLAs (single VM, availability sets with fault/update domains, availability zones);
  Virtual Machine Scale Sets (Flexible vs Uniform orchestration), autoscale (metric and schedule rules), upgrade policies,
  automatic instance repairs; images (Marketplace, custom, Azure Compute Gallery, VM Image Builder); extensions and
  cloud-init; Spot VMs and eviction; dedicated hosts and proximity placement groups; Azure Update Manager; Trusted Launch;
  Azure Virtual Desktop at a glance.
- **Demo (animation):** a shopping-festival traffic spike → autoscale adds instances across three zones → scale-in after
  cool-down; fault/update domains vs zones; a Spot eviction.
- **Lab 23 · Ready for the 12.12 sale (≈60 min, 💲💲):** Flexible scale set across zones behind a Standard load balancer
  (shared cloud-init web server); autoscale profile; generate CPU load and watch scale-out; a Spot VM with an eviction
  policy; patch assessment with Update Manager. Watch your vCPU quota. Verify: scale set mode, zones, autoscale, instances.

### Lunch 24 · Storage (Advanced)
- **Reading:** data protection (soft delete, versioning, point-in-time restore, change feed, immutability, object
  replication); lifecycle management; network security (firewall, trusted services, service endpoints vs private
  endpoints with private DNS); disabling shared keys and SAS expiration policy; encryption with customer-managed keys;
  Defender for Storage; Data Lake Storage (hierarchical namespace), SFTP and NFS; scalability targets; data movement at
  scale (AzCopy sync, Storage Mover, Data Box); Azure File Sync; static website hosting; redundancy changes and customer-managed failover.
- **Demo (animation):** a blob's lifecycle over ten years (hot → cool → cold → archive → delete); versioning and soft delete
  rescuing overwritten and deleted invoices; private endpoint traffic vs public endpoint traffic.
- **Lab 24 · Ransomware-proof invoices (≈60 min, 💲💲):** versioning, soft delete and change feed; overwrite and delete,
  then recover; lifecycle policy; time-based immutability (unlocked); private endpoint and private DNS zone, tested from a
  VM; disable public network access. Verify: data-protection settings, policy, private endpoint and DNS link.

### Lunch 25 · Virtual Networking (Advanced)
- **Reading:** VNet peering (regional and global, non-transitive, gateway transit); hub-and-spoke; system routes,
  user-defined routes, effective routes and next-hop types; Azure Firewall (SKUs, rules, DNAT, Firewall Manager) and
  network virtual appliances; NAT gateway in depth; Azure Bastion SKUs; service endpoints vs Private Link and private
  endpoints; private DNS zones and Azure DNS Private Resolver; Virtual Network Manager at a glance; Network Watcher
  (next hop, connection troubleshoot, VNet flow logs, traffic analytics); DDoS Network Protection.
- **Demo (animation):** hub with two spokes — spoke-to-spoke fails (non-transitive) until a route sends traffic through an
  appliance in the hub; private endpoint name resolution (name → privatelink alias → private IP).
- **Lab 25 · Hub and spoke for Nusantara Retail (≈60 min, 💲💲):** `setup.sh` creates a hub and two spokes with one small
  VM each (no public IPs); peer them; prove non-transitivity; turn a hub VM into a simple router (IP forwarding); add
  route tables; check effective routes and next hop; optional Azure Firewall path (💲💲💲). Verify: peerings, routes, forwarding, connectivity.

### Lunch 26 · Hybrid Connectivity: VPN Gateway, ExpressRoute and Virtual WAN
- **Reading:** why hybrid (head office and forty stores); site-to-site VPN (IPsec/IKE, route-based, active-active, BGP),
  point-to-site VPN (Entra ID authentication), VNet-to-VNet; VPN Gateway SKUs (zone-redundant AZ SKUs) and the
  GatewaySubnet; local network gateways; ExpressRoute (circuits, connectivity providers, peering locations, private and
  Microsoft peering, SKUs, Global Reach, FastPath, ExpressRoute Direct, resiliency, VPN as backup); Virtual WAN; IP
  address planning so networks never overlap (callback to Lunch 08).
- **Demo (animation):** a site-to-site tunnel forming and traffic flowing encrypted; ExpressRoute's private path vs the
  internet path; a Virtual WAN hub connecting branches.
- **Lab 26 · Connect head office (≈90 min including gateway creation, 💲💲💲):** simulate head office with a second VNet;
  `setup.sh` starts creating two VPN gateways (about 30–45 minutes, so read while you wait); create VNet-to-VNet
  connections with a shared key; test VM-to-VM traffic across the tunnel; delete immediately. Verify: gateways, connections Connected, traffic.

### Lunch 27 · Load Balancing (Advanced): Application Gateway, Front Door and Traffic Manager
- **Reading:** layer 7 load balancing; Application Gateway v2 (listeners, rules, backend settings, probes, path-based and
  multi-site routing, TLS termination, autoscale, zone redundancy, WAF policies); Azure Front Door (global edge,
  routing rules, origin groups, caching, WAF, Private Link origins); Traffic Manager (DNS-based routing methods and TTL
  caveats); cross-region Load Balancer; the decision tree (global vs regional, HTTP(S) vs not); common combinations.
- **Demo (animation):** an interactive decision tree; a shopper in Surabaya routed to the nearest edge and a healthy
  origin; WAF blocking a SQL-injection request; Traffic Manager priority failover through DNS.
- **Lab 27 · Protect and route the storefront (≈75 min, 💲💲💲):** two small web apps; Application Gateway WAF_v2 with
  path-based routing and a WAF policy in prevention mode (prove a blocked attack); Traffic Manager priority profile and a
  failover test; optional Front Door. Verify: gateway, WAF policy, path rule, Traffic Manager endpoints.

### Lunch 28 · Relational Databases (Advanced)
- **Reading:** Azure SQL high availability (General Purpose, Business Critical, Hyperscale architectures; zone
  redundancy); disaster recovery (active geo-replication, failover groups and listener endpoints, geo-restore); backups
  (point-in-time restore, long-term retention, backup storage redundancy); scaling (vCore, elastic pools, Hyperscale,
  read scale-out); security (Entra-only auth, TDE with service- or customer-managed keys, Always Encrypted, dynamic data
  masking, row-level security, auditing, Microsoft Defender for SQL, private endpoints); performance (Query Store,
  automatic tuning); Azure Database for PostgreSQL/MySQL flexible server HA and read replicas.
- **Demo (animation):** a failover group — asynchronous replication to a secondary region, the listener follows the
  primary through a failover, and RPO is the replication lag.
- **Lab 28 · Orders that survive a regional outage (≈60 min, 💲💲):** two logical servers in two regions; a small database;
  a failover group; connect through the listener; planned failover; point-in-time restore to a new database; dynamic data
  masking; auditing. Verify: failover group roles, restored database, masking rule.

### Lunch 29 · Containers (Advanced): Azure Kubernetes Service
- **Reading:** Kubernetes building blocks (cluster, control plane, nodes, pods, deployments, services, ingress,
  namespaces, ConfigMaps and Secrets, probes); AKS architecture and tiers; system vs user node pools; zones; networking
  (Azure CNI Overlay and friends); ingress options; scaling (HPA, cluster autoscaler, KEDA); identity (Entra
  integration, workload identity); ACR integration; upgrades; monitoring (Container insights, managed Prometheus and
  Grafana); AKS vs Container Apps.
- **Demo (animation):** a deployment's desired state (three replicas) scheduled onto nodes across zones; a node failure and
  rescheduling; the horizontal pod autoscaler adding pods under load; a rolling update.
- **Lab 29 · Kubernetes for the microservices team (≈60 min, 💲💲💲):** small AKS cluster; deploy the provided manifest
  (deployment + LoadBalancer service); scale; rolling update; HPA; optional ingress. *Break & fix:* a wrong image tag →
  ImagePullBackOff. Verify: cluster, ready replicas, external IP. Delete promptly.

### Lunch 30 · Monitoring (Advanced): Log Analytics, KQL and Application Insights
- **Reading:** workspace design, retention and table plans; data collection (diagnostic settings, Azure Monitor Agent and
  data collection rules, VM insights); KQL fundamentals (where, project, summarize, bin, render, join); log search
  alerts; Application Insights (workspace-based, OpenTelemetry, requests, dependencies, failures, availability tests,
  application map, live metrics); workbooks, dashboards and Azure Managed Grafana; controlling log costs.
- **Demo (animation):** telemetry flowing from VMs (agent + DCR), apps (Application Insights) and platform logs
  (diagnostic settings) into one workspace; a KQL query pipeline turning rows into a chart and an alert.
- **Lab 30 · Why was checkout slow on Friday? (≈60 min, 💲💲):** workspace; a VM connected through the Azure Monitor Agent
  and a data collection rule; diagnostic settings for a PaaS resource; KQL exercises with solutions; a log search alert;
  an availability test for a web app. Verify: DCR association, diagnostic setting, alert rule.

### Lunch 31 · Resource Hierarchy and Governance (Advanced): Governance at Scale
- **Reading:** management group design (Azure landing zone hierarchy: platform, landing zones, sandbox,
  decommissioned); subscriptions as units of scale and subscription vending; policy-driven governance (initiatives at
  management-group scope, parameters, exemptions, Modify and DeployIfNotExists remediation with managed identities,
  policy as code); regulatory compliance in Defender for Cloud; RBAC at scale (groups, PIM, custom roles); Resource Graph
  at scale; budgets at higher scopes; Azure landing zone accelerators; deployment stacks for governance artifacts; Azure
  Arc for servers and Kubernetes outside Azure; migrating away from Blueprints.
- **Demo (animation):** a landing-zone hierarchy builds out; an initiative assigned at a management group cascades down;
  a DeployIfNotExists remediation fixes non-compliant resources; an exemption.
- **Lab 31 · Governance for the whole company (≈60 min, 💲):** management groups (moving your subscription is optional);
  a custom initiative (allowed locations, required tag, inherited tag); assignment, remediation, exemption; Resource Graph
  compliance queries; export assignments as code. Verify: management groups, initiative, assignment, exemption.

### Advanced capstone challenge (lab only)
A requirements-only project: hub-and-spoke network with a firewall or appliance, private endpoints for SQL and storage,
a zone-redundant web tier behind Application Gateway WAF, a SQL failover group, everything in Bicep under a deployment
stack, a policy initiative, KQL-based alerts, backup and a DR plan for a region without a pair, and a Well-Architected
review. Learners design, build, verify with the provided checklist, and clean up.
