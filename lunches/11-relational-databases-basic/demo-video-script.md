# Lunch 11 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — creating an Azure SQL database whose server accepts only
> Microsoft Entra sign-ins, opening the firewall for one address, and querying it from the portal. The animation shows
> the concepts; this video shows the screens.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses (your account appears as the **Microsoft Entra
> admin** and in query results), public IP addresses (they appear in the firewall rules and in error messages).

## Setup before you press record

- A resource group for the recording, created in Cloud Shell:
  `az group create --name rg-lunch11-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=11`
- A globally unique server name written down, for example `sql-nusa-demo` plus four random characters.
- Make sure your subscription still has a free Azure SQL Database slot (*Azure SQL hub* shows the offer), or be ready
  to choose General Purpose **serverless** instead and say so in the narration.
- A text file with the single-batch script below, ready to paste into the Query editor:

  ```sql
  CREATE TABLE dbo.Orders (
      OrderId INT IDENTITY PRIMARY KEY,
      OrderDate DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      StoreCode VARCHAR(10) NOT NULL,
      CustomerName NVARCHAR(100) NOT NULL,
      TotalIdr DECIMAL(14,0) NOT NULL);
  INSERT INTO dbo.Orders (StoreCode, CustomerName, TotalIdr)
  VALUES ('JKT-01', N'Andi Pratama', 349000), ('SBY-01', N'Siti Rahmawati', 1250000), ('MDN-01', N'Yusuf Hakim', 89000);
  SELECT * FROM dbo.Orders;
  ```

- Browser tabs open in advance: the Azure portal home page, and the portal page *SQL databases*.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 A server that accepts only Microsoft Entra sign-ins
01:40 A free (serverless) database
02:40 Networking: one firewall rule, and a switch to leave off
03:30 Query editor: sign in as yourself, create and query Orders
04:45 Where auto-pause and the free allowance show up
05:25 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 11 · Azure SQL Database in five minutes" | "Nusantara Retail's orders still live on a server next to the pantry, protected by one shared password. In the next five minutes we create their new home in Azure SQL Database — with no shared password at all." |
| 00:25 | Portal › *SQL databases* › **+ Create** › Basics tab | "A database always lives on a logical server. I pick the resource group, name the database `sqldb-orders`, and select **Create new** for the server." |
| 00:45 | *Create SQL Database Server* pane: server name, location **Southeast Asia** | "The server name becomes a DNS name under `database.windows.net`, so it must be unique worldwide. It is not a virtual machine — it is where firewall rules and the admin live." |
| 01:05 | **Authentication method: Use Microsoft Entra-only authentication** › **Set admin** › choose own account (blurred) | "Here is the important choice. Entra-only authentication switches SQL logins off for the whole server. I set myself as the Microsoft Entra admin — in production this would be a group, not a person." |
| 01:40 | Back on Basics: the free-offer banner and the cost summary | "Because this subscription still has a free database left, the portal applies the free offer: a General Purpose serverless database with a monthly allowance. The cost card shows zero." |
| 02:00 | *Compute + storage* summary, then the **Behavior when free limit reached** setting | "The database scales between a minimum and maximum number of vCores and pauses when idle. When the free allowance runs out, I want it to pause until next month — not to bill me." |
| 02:25 | **Review + create** › **Create**; the deployment page | "Deployment takes a minute or two." *(Cut the waiting in editing.)* |
| 02:40 | The server › *Security › Networking* | "A new server lets nobody in. Under Networking I add one firewall rule for my current client address — this button adds my browser's public IP." |
| 03:00 | Highlight the **Allow Azure services and resources to access this server** checkbox (left unchecked) | "And this switch stays off. It would admit every address inside Azure, including other customers' resources. Save." |
| 03:30 | Database › *Query editor* › "Continue as …" (Microsoft Entra) | "Now the Query editor in the portal. I sign in with my Entra account — no password field. If my IP were not allowed, the editor would show the refused address and offer to add it." |
| 03:55 | Paste and run the prepared script; results grid with three orders | "I create the Orders table, insert three orders from Jakarta, Surabaya and Medan, and read them back. Same T-SQL as SQL Server, no server to patch." |
| 04:25 | Run `SELECT SUSER_SNAME();` | "And who am I inside the database? My Entra identity — that is what audit logs will show, instead of a shared login." |
| 04:45 | Database *Overview*: status, pricing tier, **Free monthly vCore amount** | "On the Overview page you can see the serverless tier and how many free vCore-seconds remain this month. Close the Query editor when you finish; open connections keep the database awake." |
| 05:10 | Database *Settings › Compute + storage*: auto-pause delay | "The auto-pause delay is here: after this many idle minutes the database pauses and compute billing stops." |
| 05:25 | Recap slide: choose · connect · pay | "Three things to remember: Azure SQL Database for relational data that speaks T-SQL; a firewall that allows only known addresses plus Entra-only sign-in; and serverless or the free offer for small databases. Lab 11 builds all of this from Cloud Shell." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Entra*, *serverless*, *vCore*, *T-SQL*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `az group delete --name rg-lunch11-demo --yes --no-wait`
