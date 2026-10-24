# Lunch 12 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: Data Explorer, items
> with different shapes, and the request charge of every query.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, the account's keys and connection strings
> (never open the **Keys** blade while recording), and your Cloud Shell prompt if it shows your user name.

## Setup before you press record

- A **serverless** Azure Cosmos DB for NoSQL account with no databases yet, created about 15 minutes before recording
  (account creation takes several minutes):

  ```bash
  cd azure-fundamentals-lunches/labs/12-cosmos-db
  source ../common/config.sh && source lab.env
  ensure_rg "$RG" 12
  az cosmosdb create --name "$ACCOUNT" --resource-group "$RG" \
    --locations regionName="$LOCATION" failoverPriority=0 isZoneRedundant=False \
    --capabilities EnableServerless --default-consistency-level Session --output none
  ```

- Three small JSON items copied from [`labs/12-cosmos-db/app/products.json`](../../labs/12-cosmos-db/app/products.json)
  into a text editor: one coffee, one batik shirt and one snack (`p-coffee-001`, `p-batik-001`, `p-snacks-004`).
- Browser tabs: the Cosmos DB account **Overview** page, and the same account's **Data Explorer**.
- Afterwards, delete everything with `bash cleanup.sh` from the lab folder.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 The account: API, capacity mode, region, consistency
01:05 Create the catalog database and products container
01:55 Add items with different shapes
02:50 Query and read the request charge
03:50 Cross-partition query and the cost of fan-out
04:35 Where the default consistency level lives
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 12 · Cosmos DB in five minutes" | "In the next five minutes we'll build Nusantara Retail's product catalogue in Azure Cosmos DB, add products of different shapes, and see exactly what each query costs in request units." |
| 00:25 | Portal › the Cosmos DB account › **Overview** | "This is a Cosmos DB account using the API for NoSQL. It's serverless, so we pay only for the request units we use. It lives in one region — serverless accounts can't add more." |
| 00:45 | Overview: point at **Read Locations**, then open **Settings › Default consistency** briefly | "The default consistency is session, the default for every new account. We'll come back to this page at the end." |
| 01:05 | **Data Explorer › New Container** | "In Data Explorer I create a new database called catalog and a container called products." |
| 01:25 | The New Container pane: type `/category` in **Partition key**; point out there is no throughput box | "The partition key is the one decision I can't change later. Our category pages ask for one category at a time, so I choose slash category. Notice there's no throughput setting — this account is serverless." |
| 01:55 | **products › Items › New Item**: paste the coffee item, **Save** | "Here's a coffee. It has a roast level and a grind." |
| 02:15 | New Item: paste the batik item, **Save**; then the snack | "And here's a batik shirt with a fabric and a list of sizes — different fields, same container, no schema change. The snack has yet another shape." |
| 02:35 | Items list: point at the `id` and `category` columns | "Every item has an id and a category. Together they identify the item, and the category decides its logical partition." |
| 02:50 | **New SQL Query**: `SELECT * FROM c WHERE c.category = 'coffee'` › **Execute Query** | "Now a category page. The query filters on the partition key, so it goes to exactly one partition." |
| 03:10 | Open the **Query Stats** tab; zoom into **Request Charge** | "Query Stats shows the request charge: a few request units. That number is the currency of Cosmos DB — every operation reports it." |
| 03:30 | Query: `SELECT * FROM c WHERE c.id = 'p-coffee-001' AND c.category = 'coffee'` › Execute › Query Stats | "Even a query for one item costs a couple of RUs. In the lab you'll do a true point read with the SDK, which costs about one RU." |
| 03:50 | Query: `SELECT * FROM c WHERE CONTAINS(LOWER(c.name), 'kopi')` › Execute › Query Stats | "This search doesn't mention the category, so it becomes a cross-partition query. With three items, the cost difference is tiny." |
| 04:15 | Back to the Query Stats panel; draw a box around **Request Charge** and **Retrieved document count** | "But look at the retrieved document count: it read every item to answer. With a million products across fifty partitions, this is the query that gets expensive. In the lab you'll fix it by adding the partition key." |
| 04:35 | **Settings › Default consistency**: hover over the five options without saving | "Back to consistency. Five levels, from strong to eventual. Strong reads cost about twice the RUs; session lets each user read their own writes at the price of the weaker levels. You'll change this setting in the lab and watch a read's cost double." |
| 05:15 | Recap slide: three bullets | "Three things to remember: choose the partition key from your busiest queries; read the request charge of everything you run; and start with session consistency. Then go and build it yourself in Lab 12." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Cosmos DB, RU, NoSQL, partition key, Data Explorer)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in `labs/12-cosmos-db`
