# Lunch 28 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — a failover group in the portal, its listeners, a
> planned failover, the point-in-time restore page and the masking and auditing settings. The animation explains the
> mechanism; this video shows where everything lives.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses (your account is the **Microsoft Entra admin**
> of both servers), public IP addresses (firewall rules), and the real customer data columns if you use your own data.

## Setup before you press record

- In Cloud Shell, run the lab's starting point at least **40 minutes** before recording, so that the database already
  has restore points:
  `cd azure-fundamentals-lunches/labs/28-relational-databases-advanced && bash setup.sh`
- Apply the masking script once, so the masking page has something to show:
  `source ../common/config.sh && source azsql.sh && azsql "sql-nusa-main-${SUFFIX}.database.windows.net" sqldb-orders -i masking.sql`
- Decide whether to create the failover group live (it needs a few minutes of seeding — cut the wait in editing) or
  beforehand with the Task 3 command from the lab.
- Browser tabs open in advance: the main server (`sql-nusa-main-…`) *Overview*, the database `sqldb-orders`
  *Overview*, and Cloud Shell.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:30 Two servers in two regions
01:00 Create a failover group
02:10 The two listener names
02:45 A planned failover from the portal
03:45 Point-in-time restore: the earliest restore point
04:30 Masking and auditing pages
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 28 · Orders that survive a regional outage" | "Ibu Sari asked how many orders we would lose if a whole region failed. In the next five minutes we set up the answer in the portal: a failover group, a failover drill and the undo button for mistakes." |
| 00:30 | *SQL servers* list filtered on `sql-nusa-`: one server in Southeast Asia, one in East Asia | "We start with two logical servers in two regions, both with Microsoft Entra-only authentication. The orders database lives on the main server in Southeast Asia." |
| 01:00 | Main server › *Data management › Failover groups* › **+ Add group** | "A failover group needs a globally unique name, because it becomes a DNS name. I pick the East Asia server as the secondary." |
| 01:25 | Failover policy: **Customer managed**; database selection: `sqldb-orders` | "The failover policy stays customer managed, which Microsoft recommends: we decide when to fail over. I add the orders database and create the group." |
| 01:50 | Failover group page: the map with both regions; the database list showing seeding, then synchronised | "Azure seeds the secondary, then streams changes continuously. The map shows which region holds the primary." *(Cut the seeding wait.)* |
| 02:10 | Zoom on the **read/write listener endpoint** and **read-only listener endpoint** | "These two names are what applications use: the read-write listener always points at the primary, the read-only listener at the secondary. They never change, even after a failover." |
| 02:45 | **Failover** button › confirmation dialog | "Now a drill. A planned failover synchronises fully, then swaps the roles, so nothing is lost. This is what a quarterly DR test looks like." |
| 03:15 | The map again: East Asia is now primary; switch to Cloud Shell and run the Task 4 `@@SERVERNAME` query through the read-write listener | "East Asia is primary now. Same connection string, new server behind it — that is the whole point of the listener." |
| 03:45 | Database › *Overview* › **Restore** | "Replication copies mistakes too, so here is the undo button. Point-in-time restore shows the earliest restore point and lets me pick any moment since then." |
| 04:10 | The restore form: restore point, new database name; then **Cancel** | "The restore always creates a new database next to the original, so you can compare before you copy anything back. A brand-new database has no restore point until its first backup completes." |
| 04:30 | Database › *Security › Dynamic Data Masking* | "The masking page lists the rules our T-SQL script created: e-mail and phone are masked for everyone without the UNMASK permission. Admins still see real values." |
| 04:55 | Server › *Security › Auditing*: destinations Storage, Log Analytics, Event Hub | "Auditing is configured per server, so set it on both servers of a failover group. Log Analytics is the easiest place to query who did what." |
| 05:20 | Recap slide: zone · region · mistakes | "Zone redundancy for a failed zone, a failover group with listeners for a failed region, point-in-time restore for a failed human. Lab 28 walks you through all of it from Cloud Shell." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *failover group*, *listener*, *geo-secondary*, *Entra*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in the lab folder (it removes the failover group first)
