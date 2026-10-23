# Lab 02 worksheet · Make the business case

Use this worksheet with [Lab 02](README.md). Copy it into your own notes (or print it) and fill in the **Your answer**
column. Answer each part *before* you open its answer block, then mark your work. Parts 1–5 have 40 questions in total.

---

## Part 1 · IaaS, PaaS, SaaS or serverless? (10)

| # | Service or situation at Nusantara Retail | Your answer |
|---:|---|---|
| 1 | Azure Virtual Machines running Ubuntu, with a web server that Pak Budi installed and patches | |
| 2 | Azure App Service hosting the storefront code that Dewi deploys | |
| 3 | Microsoft 365 mailboxes and Teams for head office | |
| 4 | An Azure Functions function that sends the order-confirmation e-mail whenever an order arrives | |
| 5 | Azure SQL Database holding the orders | |
| 6 | An online payroll application that HR signs in to; a vendor runs everything | |
| 7 | The virtual network and managed disks behind the lift-and-shift VMs | |
| 8 | An Azure Logic Apps workflow that posts a message to the stock team when an item sells out | |
| 9 | An Azure Storage account holding product photos | |
| 10 | Dynamics 365, used by the customer-service team | |

<details><summary>Answers to Part 1</summary>

| # | Answer | Why |
|---:|---|---|
| 1 | IaaS | You rent the VM and manage the operating system and everything on it. |
| 2 | PaaS | You bring code; Microsoft runs and patches the platform underneath. |
| 3 | SaaS | A finished application: you configure it and manage users, nothing else. |
| 4 | Serverless (a form of PaaS) | Event-driven code, no servers to manage, pay per execution. |
| 5 | PaaS | A managed database service: Microsoft patches the engine and handles backups. |
| 6 | SaaS | The vendor runs the whole application; HR only uses and configures it. |
| 7 | IaaS | Virtual networks and disks are infrastructure building blocks you configure yourself. |
| 8 | Serverless (a form of PaaS) | A workflow triggered by an event, scaled and billed per run. |
| 9 | PaaS | Storage is a managed platform service: you store data, Microsoft runs the service. |
| 10 | SaaS | A finished business application delivered as a subscription. |

</details>

---

## Part 2 · CapEx or OpEx? (8)

| # | Spending | Your answer |
|---:|---|---|
| 1 | Buying the bigger server for the pantry room | |
| 2 | The monthly Azure invoice for the storefront | |
| 3 | A new UPS and air conditioner for the server room | |
| 4 | Microsoft 365 licences, paid every month per user | |
| 5 | The electricity bill for the server room | |
| 6 | The yearly maintenance contract for the existing server | |
| 7 | Buying network switches for the forty stores | |
| 8 | Charges for data sent from Azure to customers on the internet | |

<details><summary>Answers to Part 2</summary>

| # | Answer | Why |
|---:|---|---|
| 1 | CapEx | A physical asset bought up front and depreciated over years. |
| 2 | OpEx | A service paid in the period it is consumed. |
| 3 | CapEx | Physical equipment that Nusantara Retail owns. |
| 4 | OpEx | A subscription paid as you go. |
| 5 | OpEx | On-premises IT has operating costs too, and they belong in a fair comparison. |
| 6 | OpEx | A service contract paid for each period, not an asset. |
| 7 | CapEx | Hardware bought and owned, even though it sits in the stores. |
| 8 | OpEx | Consumption-based charges that follow usage. |

</details>

---

## Part 3 · Who is responsible: Nusantara Retail, Microsoft or shared? (10)

| # | Task | Your answer |
|---:|---|---|
| 1 | Patching the operating system of the web VMs in Design A | |
| 2 | Replacing a failed physical disk in an Azure datacenter that hosts Design A | |
| 3 | Patching the operating system underneath App Service in Design B | |
| 4 | Deciding which HR staff may see salary data in the SaaS payroll application | |
| 5 | Requiring MFA for every store manager's account | |
| 6 | The firewall rules (network security groups) in front of the Design A VMs | |
| 7 | Network access to the storefront app in Design B: the platform's controls and how they are configured | |
| 8 | Security guards and access badges at the Azure datacenter | |
| 9 | Keeping the libraries in the storefront's own code up to date in Design B | |
| 10 | Protecting the finance team's laptops against malware | |

<details><summary>Answers to Part 3</summary>

| # | Answer | Why |
|---:|---|---|
| 1 | Nusantara Retail | In IaaS the operating system belongs to the customer. |
| 2 | Microsoft | Physical hosts are always Microsoft's job in the cloud. |
| 3 | Microsoft | In PaaS the provider runs and patches the operating system. |
| 4 | Nusantara Retail | Identities and access are always the customer's, even in SaaS. |
| 5 | Nusantara Retail | Account security is part of identities and access. |
| 6 | Nusantara Retail | In IaaS you configure all network controls in front of your VMs. |
| 7 | Shared | In PaaS, Microsoft provides and secures the platform's network features; you decide who can reach the app. |
| 8 | Microsoft | Physical security of datacenters always transfers to the provider. |
| 9 | Nusantara Retail | Applications are shared in PaaS, but the code you write, and its libraries, are your part. |
| 10 | Nusantara Retail | Devices are the customer's in on-premises, IaaS and PaaS (and shared at most in SaaS). |

</details>

---

## Part 4 · Which cloud model? (4)

| # | Situation | Your answer |
|---:|---|---|
| 1 | The storefront moves to Azure; the stores keep their local servers, connected to Azure | |
| 2 | Everything Nusantara Retail runs is in Azure; nothing is left on-premises | |
| 3 | A bank builds self-service virtual machines in its own datacenter, for its own departments only | |
| 4 | The storefront runs in Azure, and a marketing analytics tool runs on another cloud provider | |

<details><summary>Answers to Part 4</summary>

| # | Answer | Why |
|---:|---|---|
| 1 | Hybrid cloud | Public cloud and on-premises systems connected and working together. Azure Arc could manage the store servers too. |
| 2 | Public cloud | All workloads run on a provider's shared infrastructure. |
| 3 | Private cloud | Cloud-style self-service, dedicated to one organisation, on hardware it owns. |
| 4 | Multicloud | Two or more public cloud providers in use at the same time. |

</details>

---

## Part 5 · Name the benefit (8)

Choose from: **high availability, scalability, elasticity, reliability, predictability, security, governance,
manageability**. Each is used once.

| # | Statement | Your answer |
|---:|---|---|
| 1 | Two web instances in different availability zones keep the shop open when one zone fails | |
| 2 | During 12.12 the web tier grows from two to six instances automatically, then shrinks back | |
| 3 | When the catalogue doubles, you can move the database to a larger size | |
| 4 | Budgets and the pricing calculator tell finance roughly what next month will cost | |
| 5 | A policy blocks anyone from creating resources outside Indonesia Central | |
| 6 | Microsoft patches the platform under App Service, and Defender for Cloud flags a risky setting | |
| 7 | One template recreates the whole environment instead of forty clicks in the portal | |
| 8 | After a hardware failure, the service recovers on healthy infrastructure and keeps working | |

<details><summary>Answers to Part 5</summary>

| # | Answer | Why |
|---:|---|---|
| 1 | High availability | The service stays up despite the failure of a component or a zone. |
| 2 | Elasticity | Capacity grows *and* shrinks automatically with demand. |
| 3 | Scalability | The ability to add resources, here by scaling up (vertically). |
| 4 | Predictability | Cost predictability: forecasting and tracking spending. |
| 5 | Governance | Rules that keep deployments within company standards and regulations. |
| 6 | Security | The provider secures and patches its part; security tools help with yours. |
| 7 | Manageability | Managing resources consistently with templates and tools rather than by hand. |
| 8 | Reliability | The ability to recover from failures and continue to function. |

</details>

---

## Part 6 · Your estimates

Fill this in during Tasks 2–4. Use the same currency everywhere and write it in the first row.

| | Design A · lift and shift (IaaS) | Design B · PaaS |
|---|---|---|
| Currency and region used (note any Southeast Asia fallbacks) | | |
| Monthly total, pay-as-you-go | | |
| Largest line item | | |
| Monthly total with one-year commitments where offered | | |
| Which items offered a commitment? | | |
| Monthly total in Southeast Asia (pay-as-you-go) | | |
| Regular tasks Nusantara Retail still performs | | |
| Your estimate of people hours per month | | |
| Single points of failure left | | |
| If one web server fails, what do customers notice? | | |

Three questions to answer in one sentence each:

1. Which design is cheaper on the Azure bill?
2. Which design is cheaper once people time is included?
3. Which design has fewer single points of failure, and why?

---

## Part 7 · One-page recommendation (template)

Copy the template below into a document and fill it in. Keep it to one page.

> **To:** Ibu Sari, Director · **From:** *your name*, Cloud Engineer · **Date:** *today*
> **Subject:** Getting the storefront off the pantry server
>
> **1. The question.** "If that server dies, how long can't we sell?" Today the answer is: *until the server is repaired
> or replaced, which could take days*.
>
> **2. Recommendation (one sentence).** *We should …*
>
> **3. Options considered.**
>
> | Option | Monthly cost (pay-as-you-go) | With 1-year commitment | If one server fails | Who patches the servers |
> |---|---|---|---|---|
> | Buy a bigger server | *one-off purchase* | — | Sales stop until it is repaired | Nusantara Retail |
> | A · Lift and shift (IaaS) | | | | |
> | B · PaaS | | | | |
>
> **4. Why.** *Money (CapEx versus OpEx), risk (single points of failure), effort (people time), speed (time to go live).*
>
> **5. What stays our responsibility.** *Data, settings, identities and access (MFA), and our part of anything shared.*
>
> **6. Risks and how we reduce them.** *For example: skills, migration downtime, unexpected costs (budgets and alerts).*
>
> **7. Next steps.** *A pilot, who does what, and the decision needed by when.*

<details><summary>Example recommendation (one possible answer)</summary>

**Recommendation:** move the storefront to Design B (App Service and Azure SQL Database in Indonesia Central) within
two months, using a short lift-and-shift step only if the code needs more time to adapt.

**Why:** today one hardware failure stops online sales until the server is repaired. Both cloud designs remove that
single point of failure by running two web instances. The attached estimates show the monthly Azure bill for each
design. Design B needs fewer components and removes most of the operating-system patching and backup work, which frees
Pak Budi for the stores; in our estimate that is about *N* hours a month. Spending moves from a one-off server purchase
(CapEx) to a monthly bill (OpEx) that grows in December and shrinks in quiet months, and a one-year commitment can lower
it once usage is stable.

**What stays ours:** customer data, configuration, and who can sign in. We will require MFA for every account with
access and review permissions every quarter.

**Risks:** Dewi may need to change some code and configuration (we start with a pilot), and cloud costs can creep (a
budget with alerts at 50, 80 and 100% is already in place).

**Next steps:** a two-week pilot of the storefront on App Service, then a go/no-go decision at the next monthly meeting.

</details>

---

⬅️ [Back to Lab 02](README.md) · [Lunch 02 reading](../../lunches/02-cloud-concepts/README.md)
