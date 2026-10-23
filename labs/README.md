# Hands-on labs

Every lunch has an **independent lab** that you do on your own time, at your own pace. Read the matching lunch first;
then build, break, fix and verify in your own Azure subscription.

## How the labs work

- **Independent.** No lab needs another lab. When a lab needs a starting point (for example two web servers for the load
  balancing lab), its `setup.sh` creates it.
- **Azure Cloud Shell (Bash)** is all you need: open [shell.azure.com](https://shell.azure.com), choose Bash, then:

  ```bash
  git clone https://github.com/stefpin/azure-fundamentals-lunches.git   # first time only
  cd azure-fundamentals-lunches
  bash labs/common/check-environment.sh                                               # checks region, VM sizes, quota
  ```

- **Two modes.** *Guided* walks you through each task with checkpoints. *Challenge* gives you only the requirements.
- **Scripts in every lab folder:**

  | Script | What it does |
  |---|---|
  | `setup.sh` | creates the starting point (only in labs that need one) |
  | `solution.sh` | the reference solution (in labs whose tasks can be scripted) |
  | `verify.sh` | checks your work and prints PASS or FAIL for each requirement |
  | `cleanup.sh` | deletes everything the lab created |

- **Shared settings** live in [`common/config.sh`](common/config.sh): region (`LOCATION`, default `southeastasia`),
  a second region for multi-region labs (`SECONDARY_LOCATION`, default `eastasia`), small VM sizes, and a random suffix
  that keeps globally unique names unique. Override them before you start, for example:

  ```bash
  export LOCATION=indonesiacentral        # Jakarta — check that each lab's services are offered there
  source labs/common/config.sh
  ```

## Cost bands

| Band | Meaning | What to do |
|---|---|---|
| 💲 | free or close to free (uses free tiers or tiny resources) | clean up anyway — good habit |
| 💲💲 | small charges while resources run, typically cents per hour | finish the lab in one sitting, then run `cleanup.sh` |
| 💲💲💲 | noticeable charges while running, or gateways that take long to create | plan the lab, then delete immediately afterwards |

Prices vary by region and change over time, so the labs do not quote them. Use the
[Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) when you want numbers, and set the budget
from Lab 01 before anything else.

> [!WARNING]
> Never run the labs in a company or production subscription. Several labs create users, role assignments, policies or
> management groups, which affect everything in that scope.

## All labs

<!-- LAB-TABLE:START -->
| Lab | Pairs with | Time | Cost |
|---|---|---|---|
| [Lab 01 · Set up your lab environment](01-before-you-begin/README.md) | [Lunch 01 · Before You Begin: Your Azure Lab, Tools and Cost Guardrails](../lunches/01-before-you-begin/README.md) | about 30 minutes | 💲 |
| [Lab 02 · Make the business case](02-cloud-concepts/README.md) | [Lunch 02 · Cloud Concepts](../lunches/02-cloud-concepts/README.md) | about 40 minutes | 💲 |
| [Lab 03 · Explore regions and zones](03-global-infrastructure/README.md) | [Lunch 03 · Azure Global Infrastructure: Regions, Availability Zones and Region Pairs](../lunches/03-global-infrastructure/README.md) | about 35 minutes | 💲 |
| [Lab 04 · Organise Nusantara Retail](04-resource-hierarchy-basic/README.md) | [Lunch 04 · Resource Hierarchy and Azure Resource Manager (Basic)](../lunches/04-resource-hierarchy-basic/README.md) | about 40 minutes | 💲 |
| [Lab 05 · Give a contractor just enough access](05-identity-access-basic/README.md) | [Lunch 05 · Identity and Access (Basic)](../lunches/05-identity-access-basic/README.md) | about 40 minutes | 💲 |
| [Lab 06 · Your first web server VM](06-virtual-machines-basic/README.md) | [Lunch 06 · Virtual Machines (Basic)](../lunches/06-virtual-machines-basic/README.md) | about 45 minutes | 💲💲 |
| [Lab 07 · Store product images and invoices](07-storage-basic/README.md) | [Lunch 07 · Storage (Basic)](../lunches/07-storage-basic/README.md) | about 45 minutes | 💲 |
| [Lab 08 · Build Nusantara Retail's network](08-networking-basic/README.md) | [Lunch 08 · Virtual Networking (Basic)](../lunches/08-networking-basic/README.md) | about 50 minutes | 💲💲 |
| [Lab 09 · Keep the shop open when a server fails](09-load-balancing-basic/README.md) | [Lunch 09 · Load Balancing: Azure Load Balancer (Basic)](../lunches/09-load-balancing-basic/README.md) | about 50 minutes | 💲💲 |
| [Lab 10 · Move the storefront to PaaS](10-app-service/README.md) | [Lunch 10 · Web Apps with Azure App Service](../lunches/10-app-service/README.md) | about 45 minutes | 💲 |
| [Lab 11 · Nusantara Retail's orders database](11-relational-databases-basic/README.md) | [Lunch 11 · Relational Databases: Azure SQL (Basic)](../lunches/11-relational-databases-basic/README.md) | about 45 minutes | 💲 |
| [Lab 12 · A product catalogue that scales](12-cosmos-db/README.md) | [Lunch 12 · NoSQL with Azure Cosmos DB](../lunches/12-cosmos-db/README.md) | about 45 minutes | 💲 |
| [Lab 13 · Package the storefront](13-containers-basic/README.md) | [Lunch 13 · Containers: Container Registry, Container Instances and Container Apps (Basic)](../lunches/13-containers-basic/README.md) | about 45 minutes | 💲 |
| [Lab 14 · React to new orders automatically](14-serverless/README.md) | [Lunch 14 · Serverless: Azure Functions, Logic Apps and Event Grid](../lunches/14-serverless/README.md) | about 50 minutes | 💲 |
| [Lab 15 · Get the password out of the config file](15-security-essentials/README.md) | [Lunch 15 · Security Essentials: Defense in Depth, Key Vault and Defender for Cloud](../lunches/15-security-essentials/README.md) | about 45 minutes | 💲💲 |
| [Lab 16 · Know before customers do](16-monitoring-basic/README.md) | [Lunch 16 · Monitoring: Azure Monitor, Alerts, Service Health and Advisor (Basic)](../lunches/16-monitoring-basic/README.md) | about 45 minutes | 💲💲 |
| [Lab 17 · The restore drill](17-backup-disaster-recovery/README.md) | [Lunch 17 · Backup and Disaster Recovery](../lunches/17-backup-disaster-recovery/README.md) | 60–90 minutes | 💲💲 |
| [Lab 18 · Keep data in the right place](18-governance-compliance-basic/README.md) | [Lunch 18 · Governance and Compliance: Azure Policy, Locks, Tags and Microsoft Purview (Basic)](../lunches/18-governance-compliance-basic/README.md) | about 45 minutes | 💲 |
| [Lab 19 · Find the waste you made yourself](19-cost-management/README.md) | [Lunch 19 · Cost Management](../lunches/19-cost-management/README.md) | about 40 minutes | 💲 |
| [Lab 20 · Nineteen lunches of clicks in one file](20-infrastructure-as-code-bicep/README.md) | [Lunch 20 · Infrastructure as Code with Bicep](../lunches/20-infrastructure-as-code-bicep/README.md) | about 50 minutes | 💲 |
| [Lab 21 · Capstone project](21-core-capstone/README.md) | [Lunch 21 · Core Capstone: Putting It All Together](../lunches/21-core-capstone/README.md) | about 2–3 hours | 💲💲 |
| [Lab 22 · Passwordless pipelines and least privilege](22-identity-access-advanced/README.md) | [Lunch 22 · Identity and Access (Advanced)](../lunches/22-identity-access-advanced/README.md) | about 50 minutes | 💲 |
| [Lab 23 · Ready for the 12.12 sale](23-virtual-machines-advanced/README.md) | [Lunch 23 · Virtual Machines (Advanced)](../lunches/23-virtual-machines-advanced/README.md) | about 60 minutes | 💲💲 |
| [Lab 24 · Ransomware-proof invoices](24-storage-advanced/README.md) | [Lunch 24 · Storage (Advanced)](../lunches/24-storage-advanced/README.md) | about 60 minutes | 💲💲 |
| [Lab 25 · Hub and spoke for Nusantara Retail](25-networking-advanced/README.md) | [Lunch 25 · Virtual Networking (Advanced)](../lunches/25-networking-advanced/README.md) | about 60 minutes | 💲💲 |
| [Lab 26 · Connect head office](26-hybrid-connectivity/README.md) | [Lunch 26 · Hybrid Connectivity: VPN Gateway, ExpressRoute and Virtual WAN (Advanced)](../lunches/26-hybrid-connectivity/README.md) | about 90 minutes | 💲💲💲 |
| [Lab 27 · Protect and route the storefront](27-load-balancing-advanced/README.md) | [Lunch 27 · Load Balancing: Application Gateway, Front Door and Traffic Manager (Advanced)](../lunches/27-load-balancing-advanced/README.md) | about 75 minutes | 💲💲💲 |
| [Lab 28 · Orders that survive a regional outage](28-relational-databases-advanced/README.md) | [Lunch 28 · Relational Databases (Advanced)](../lunches/28-relational-databases-advanced/README.md) | about 60 minutes | 💲💲 |
| [Lab 29 · Kubernetes for the microservices team](29-containers-advanced-aks/README.md) | [Lunch 29 · Containers: Azure Kubernetes Service (Advanced)](../lunches/29-containers-advanced-aks/README.md) | about 60 minutes | 💲💲💲 |
| [Lab 30 · Why was checkout slow on Friday?](30-monitoring-advanced/README.md) | [Lunch 30 · Monitoring: Log Analytics, KQL and Application Insights (Advanced)](../lunches/30-monitoring-advanced/README.md) | about 60 minutes | 💲💲 |
| [Lab 31 · Governance for the whole company](31-governance-at-scale/README.md) | [Lunch 31 · Resource Hierarchy and Governance: Governance at Scale (Advanced)](../lunches/31-governance-at-scale/README.md) | about 60 minutes | 💲 |
| [Advanced capstone challenge](32-advanced-capstone-challenge/README.md) | Lunches 22–31 | a multi-session project | 💲💲💲 |
<!-- LAB-TABLE:END -->

## When something goes wrong

1. Read the error message — most failures are a region that does not offer a VM size, a quota limit, or a name that is
   already taken. `bash labs/common/check-environment.sh` checks the first two.
2. Check the lab's **Troubleshooting** table.
3. Still stuck? [Report a lab problem](../CONTRIBUTING.md) with the lab number, the command and the full error.

---

🏠 [Course home](../README.md)
