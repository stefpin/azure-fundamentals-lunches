# Lunch 30 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, connection strings and instrumentation keys.

## Setup before you press record

- About an hour before recording, build the whole lab and let data accumulate (setup takes about 10 minutes,
  the solution about 10 more):

  ```bash
  cd azure-fundamentals-lunches/labs/30-monitoring-advanced
  bash setup.sh
  bash solution.sh
  source ../common/config.sh && source lab.env
  nohup bash traffic.sh 45 > "$OUT_DIR/traffic.log" 2>&1 &
  ```

- Check that the tables have rows (`bash verify.sh` prints the counts at the end) and that `alert-slow-checkout` has
  fired at least once.
- Browser tabs to open in advance: `log-nusa` › *Tables*, *Monitor › Data Collection Rules* › `dcr-linux-nusa`, the
  storage account's *Diagnostic settings*, `log-nusa` › *Logs* (KQL mode), `appi-nusa-shop` › *Application map*,
  *Performance*, *Failures* and *Availability*, and *Monitor › Alerts*.
- Paste the queries you'll use into a text file: solutions 1, 4, 8 and 9 from Lab 30, Task 6.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 One workspace, many tables
00:55 VM data: the Azure Monitor Agent and a data collection rule
01:40 Platform logs: a diagnostic setting
02:05 KQL: from thousands of rows to one chart
03:15 Application Insights: performance, failures, availability
04:30 From query to alert
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 30 · Why was checkout slow on Friday?" | "Last Friday checkout took four seconds and every CPU chart looked fine. In the next five minutes we'll put the evidence in one place and let the data tell us who was right." |
| 00:20 | `log-nusa` › *Settings › Tables*: sort by name, point at the *Plan* and *Retention* columns for `AppRequests`, `Syslog` and `StorageBlobLogs` | "This Log Analytics workspace is our evidence room. Every source writes into its own table, and every table has a plan and a retention period — that's where the bill is decided." |
| 00:55 | VM › *Extensions + applications*: `AzureMonitorLinuxAgent`, Succeeded | "On the order-jobs VM, the Azure Monitor Agent is installed as an extension. It signs in with the VM's managed identity." |
| 01:10 | *Monitor › Data Collection Rules* › `dcr-linux-nusa` › *Data sources* (Syslog, minimum level Warning; Performance counters), then *Resources* (vm-nusa-app), then *JSON View* briefly | "The agent does nothing until a data collection rule says what to collect and where to send it: Syslog warnings and above, and a few counters every minute. The rule is plain JSON, so it lives in source control." |
| 01:40 | Storage account › *Monitoring › Diagnostic settings* › blob › `diag-blob-to-log-nusa`: *allLogs* to `log-nusa` | "Platform logs need a diagnostic setting. This one sends every blob read and write to the same workspace — Dewi's product images are now on the record." |
| 02:05 | `log-nusa` › *Logs*, KQL mode: type solution 1 (Heartbeat) and run it | "Now the questions. KQL starts with a table and pipes rows through operators. Is the agent alive? One row per computer, last seen a minute ago." |
| 02:30 | Run solution 4 (Perf CPU timechart); hover the flat line | "Was Pak Budi's VM busy? Average CPU in five-minute buckets — flat and low. Innocent." |
| 02:50 | Build solution 8 step by step: `AppRequests` (show the row count), add `where Name has "checkout"`, add the `summarize … by bin`, add `render timechart` | "Watch the row count drop with each line, until a chart remains. The median checkout is fast, but the ninety-fifth percentile sits near three seconds. An average would have hidden that." |
| 03:15 | `appi-nusa-shop` › *Application map*: the storefront node with request rate, duration and failure rate | "Application Insights collected this without a single line of monitoring code — App Service autoinstrumentation, built on OpenTelemetry." |
| 03:35 | *Performance* › `POST /checkout` › select a slow sample in the duration distribution › end-to-end transaction with the warning trace | "Drill into one slow checkout and you get its whole story: the request, and the warning the code logged — the payment gateway took two and a half seconds." |
| 04:00 | *Failures* › `POST /checkout` › exception type `PaymentGatewayTimeout`; then *Availability*: the standard test's green results per location | "The failures have the same cause. And the availability test checks the shop from five locations every five minutes — from Singapore to the US West Coast." |
| 04:30 | Back in *Logs*: run solution 9 (join); then *Monitor › Alerts* › `alert-slow-checkout` fired; open the rule's condition | "One join puts each failed checkout next to its exception: Rizky was right — the payment provider. And the same query, saved as a log search alert, now checks every five minutes, looking back ten minutes so late rows still count." |
| 05:15 | Recap slide: one workspace · three pipes (agent + DCR, diagnostic settings, Application Insights) · KQL pipeline · alert | "Three things to remember: design one workspace and choose your table plans, connect each source through the right pipe, and turn the query that found the problem into the alert that catches it next time. The lab builds all of it." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in `labs/30-monitoring-advanced`
