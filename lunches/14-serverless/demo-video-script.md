# Lunch 14 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — choosing a Functions hosting plan, a function that turns
> an HTTP request into a queue message, a burst of orders in Live metrics, and a Logic App run whose steps you can
> open one by one. The animation can only simulate these.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using — and
> in this lunch also **function keys** and **storage connection strings**.

## Setup before you press record

- About 20 minutes before recording, build the finished lab (💲, about 10 minutes) and check it:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/14-serverless
  source ../common/config.sh && source lab.env
  bash solution.sh        # storage account + queue, workspace, Flex Consumption app, code, Logic App
  bash verify.sh          # every check should say PASS
  ```

- Empty the queue, so that viewers see only the orders you send on camera (the Logic App adds a heartbeat order every
  15 minutes; that's fine):

  ```bash
  az storage message clear --queue-name "$QUEUE" --account-name "$ST" --auth-mode key --only-show-errors
  ```

- In the same Cloud Shell session, load the URL and key from Lab Task 5, then clear the screen so the key never
  appears. Never `echo` the key on camera:

  ```bash
  ORDER_URL=$(az functionapp function show -g "$RG" -n "$FUNC" --function-name new_order --query invokeUrlTemplate --output tsv)
  FUNC_KEY=$(az functionapp function keys list -g "$RG" -n "$FUNC" --function-name new_order --query default --output tsv)
  clear
  ```

- Keep the three Task 5 `curl` commands and this burst command ready to paste (300 orders, 25 at a time):

  ```bash
  seq 1 300 | xargs -P 25 -I{} curl -s -o /dev/null -w "%{http_code}\n" -X POST "$ORDER_URL" \
    -H "x-functions-key: $FUNC_KEY" -H "Content-Type: application/json" \
    -d '{"orderId":"BURST-{}","store":"Jakarta - Kemang","items":[{"sku":"KOPI-TORAJA-250G","qty":1}]}' | sort | uniq -c
  ```

- Browser tabs: (1) the portal home page; (2) the function app `func-nusa-<suffix>`; (3) the storage account
  `stnusaorders<suffix>` › *Storage browser › Queues › orders*; (4) the Application Insights resource in
  `rg-lunch14-<suffix>` › *Live metrics*; (5) the Logic App `logic-nusa-orders` › *Logic app designer*.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Where functions run: the hosting options
01:05 A function app on Flex Consumption
01:50 Place an order with curl
02:20 The order waits in a queue
02:45 A burst of orders in Live metrics
03:35 A Logic App, step by step
04:50 Which messaging service?
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 14 · Serverless — Azure Functions and Logic Apps" | "Nusantara Retail's stores send orders all day, with quiet nights and wild sale-day peaks. In the next six minutes we look at a function that takes orders and puts them on a queue, watch it handle a burst, and add a workflow that tests the pipeline every fifteen minutes. No servers to manage anywhere." |
| 00:25 | Tab 1: *Create a resource* › *Create* under *Function App*: the *Select a hosting option* page; point at each option; then close the page | "When you create a function app, the first question is where it runs. Flex Consumption is the recommended serverless plan: it scales to zero, and out to many instances when events pour in. Functions Premium keeps instances warm, App Service runs functions on a plan you already pay for, and Container Apps runs them next to your containers. The Consumption plan is now legacy. I'll close this: our app already exists." |
| 01:05 | Tab 2: `func-nusa-<suffix>` › *Overview*: Flex Consumption, Python; the function list shows `new_order` (HTTP trigger) | "Here's the app from the lab: Flex Consumption, Python. It has one function, new_order, triggered by HTTP." |
| 01:15 | *Settings › Environment variables*: point at `OrdersStorage__queueServiceUri` (a URL) without revealing any other value; *Settings › Identity*: system-assigned **On**; *Settings › Scale and concurrency*: maximum instance count 10, instance memory 2,048 MB, no always-ready instances | "The function writes to a storage queue through an output binding. Its connection setting is just the queue's address: the app signs in with its managed identity, which has a queue role on the storage account. No connection string, no secret. Scale and concurrency shows the guard rails: at most ten instances of 2 GB each, and no always-ready instances, so idle time costs no compute." |
| 01:50 | Cloud Shell: the valid order from Task 5 → `{"status": "queued", …}` and `HTTP 200`; the order without items → `400` with the reasons; the call without a key → `401` | "Let's place an order the way the storefront would: a POST with JSON and the function key. Queued, with a tracking ID. The first call after a quiet spell can take a few seconds; that's a cold start. A broken order gets a 400 and the reasons. No key, no entry: 401." |
| 02:20 | Tab 3: *Storage browser › Queues › orders* › *Refresh*; open the message: the JSON with `receivedAtUtc` and `trackingId` | "And here's the order, waiting in the queue for the warehouse system. The function never called the storage SDK: the binding wrote the message when the function returned. If the warehouse is offline for an hour, orders simply wait here." |
| 02:45 | Tab 4: *Live metrics*; Cloud Shell: paste the burst command; watch the request rate and the server count rise; the command ends with `300 200` | "Now a burst: three hundred orders, twenty-five at a time. In Live metrics, the request rate jumps and the platform adds instances to keep up. How many depends on the load and on how many requests each instance accepts at once. Every order answers 200. When the burst ends, the instances go idle and, after a while, the app is back to zero." |
| 03:35 | Tab 5: the designer: **Recurrence** (every 15 minutes) → **HTTP** (POST to the function, two headers, JSON body); don't open *Code view* | "The other half of serverless is workflows. This Consumption Logic App is the lab's heartbeat: a Recurrence trigger every fifteen minutes and an HTTP action that posts a test order. You can build it here with drag and drop, or deploy it as JSON from the command line, which is how the lab does it." |
| 04:05 | *Overview* › *Run trigger* › *Run*; open the new entry under *Run history*: both steps green with durations; open the HTTP step's **outputs** (status 200, the `queued` body), not its inputs | "Run the trigger now instead of waiting. In the run history, each step lights up green with its duration, and the HTTP step's output shows the function's answer: queued. Every run keeps this step-by-step record, which makes failures easy to find." |
| 04:35 | Tab 3: *Refresh*: a message whose `orderId` starts with `HB-` | "Back in the queue, the heartbeat order has arrived. A function and a workflow, both pay-per-use, both idle most of the time." |
| 04:50 | Slide: Event Grid · Service Bus · Event Hubs · Storage queues, one line each | "One more decision before you build: which messaging service? Event Grid pushes notifications that something happened, like a new blob. Service Bus carries business messages, with ordering and transactions. Event Hubs ingests telemetry streams of millions of events per second. Storage queues are the simple, cheap buffer we just used." |
| 05:20 | Recap slide: "Flex Consumption for new functions · Bindings + managed identity · Logic Apps to connect services" | "Three things to remember. Choose Flex Consumption for new serverless functions. Let bindings and managed identities do the plumbing, with no secrets in settings. And use Logic Apps when the job is mostly connecting services. The lab builds all of this, and cleans it up." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Flex Consumption*, *output binding*, *managed
  identity*, *Logic App*, *Event Grid*, *Service Bus*, *Event Hubs*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `bash cleanup.sh` in `labs/14-serverless`. It also removes `~/lab14-out`, which holds the
  filled-in workflow file with the function key.
- Check every frame for the function key (*App keys*, *Code view*, the HTTP step's inputs, the filled-in
  `workflow.json`) and for the *Show value* of `AzureWebJobsStorage` or `DEPLOYMENT_STORAGE_CONNECTION_STRING`. Blur
  any you find, even though the key stops working once the app is deleted.
