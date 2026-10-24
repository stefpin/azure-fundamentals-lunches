# Lunch 19 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Cost Management experience — cost analysis grouped by service, resource group and tag, an
> orphan hunt in Resource Graph Explorer, Advisor's cost tab and creating a budget — the parts the animation can only simulate.
> **Length target:** about 5 minutes 45 seconds.
> **Record in:** a personal or dedicated demo subscription — never a company subscription. Use a pay-as-you-go or free
> account subscription; Azure for Students isn't supported by Cost Management.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses (including budget recipients), billing account and
> invoice details, public IP addresses you will keep using.

## Setup before you press record

- **At least a day before:** in Cloud Shell, run `bash labs/19-cost-management/setup.sh` so the three orphans exist long
  enough for their first costs to reach Cost Management (typically 8–24 hours, up to 72 hours for some pay-as-you-go
  subscriptions). Keep a few other tagged resource groups so the cost views have something to show.
- Decide on a demo email alias for the budget alerts and make sure you can blur it in editing.
- Open these tabs in advance:
  1. **Cost Management › Cost analysis** at subscription scope, on the **Services** smart view.
  2. **Resource Graph Explorer** with an empty query.
  3. **Advisor › Cost**.
  4. The lab resource group `rg-lunch19-<suffix>` › **Budgets**.
  5. The [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) with an empty estimate.
- Have the three orphan queries from the lab README ready to paste.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Cost analysis: the bill by service
01:10 Group by resource group and by tag
02:00 The orphan hunt in Resource Graph Explorer
02:55 Advisor's cost tab
03:25 A budget with 50/80/100% alerts
04:40 Pay-as-you-go vs a one-year reservation
05:25 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 19 · Cost Management" | "In the next five minutes we'll take an Azure bill apart, hunt for the waste in it, and set up alerts so next month holds no surprises." |
| 00:25 | Cost analysis, subscription scope, **Services** smart view; point at the date range and the total | "This is cost analysis for the whole subscription. The Services view groups one total by service: virtual machines, storage, networking. Notice that today's usage isn't here yet — cost data arrives in batches, typically 8 to 24 hours later." |
| 00:55 | Expand the top service row to show its meters | "Expand a row and you see the meters behind it: compute hours, disk capacity, data transfer. Every line on the invoice is just quantity times price." |
| 01:10 | Switch to the **Resource groups** view, then open a customizable view and set **Group by** to the tag `costCenter` | "Group by resource group to see which environment costs what. Then group by the costCenter tag — this is showback. Anything without the tag lands in an untagged bucket, which is the to-do list for your tagging policy." |
| 01:45 | Save the view and show the **Share** option | "Save the view and share it with finance, so everyone reads the same numbers at the monthly meeting." |
| 02:00 | Resource Graph Explorer: paste the unattached-disk query, select **Run query** | "Cost data can't tell you what exists right now; Resource Graph can. This query lists every disk whose state is Unattached, across every subscription I can read, in about a second." |
| 02:25 | Run the public IP query, then the empty App Service plan query | "Same idea for public IPs with no IP configuration, and for App Service plans with zero apps. Three orphans, all tagged retail-lab, all still billing." |
| 02:55 | Advisor › **Cost** tab; filter to the demo subscription | "Advisor's cost tab adds right-sizing, reservation and savings plan recommendations, plus checks for unattached disks and empty plans. These rules need days of history, so fresh waste may not appear yet — that's why we hunt with Resource Graph too." |
| 03:25 | Lab resource group › **Budgets** › **Add**; monthly reset, amount, expiration date | "Now prevention. On the resource group I add a monthly budget. The amount is in the subscription's billing currency." |
| 03:55 | **Alert conditions**: Actual 50, 80, 100 percent; add the (blurred) email; mention **Manage action group** | "Three actual-cost alerts at 50, 80 and 100 percent, sent to the owners. A budget never stops resources — it's an alarm, not a brake. For automatic action, attach an action group that runs automation." |
| 04:25 | Select **Create**; show the budget in the list | "Budgets are evaluated about once a day, so think of this as an early warning, not a real-time meter." |
| 04:40 | Pricing calculator: add **Virtual machines**, region Southeast Asia, Linux, a small size; switch **Savings options** from pay as you go to one-year reserved | "Last, the purchase options. Same small VM, pay-as-you-go versus a one-year reservation. Note the monthly difference — but remember the order: remove waste and right-size first, commit last." |
| 05:25 | Recap slide: three bullets | "Three things to remember: cost data is hours behind; Resource Graph finds waste right now; budgets are alarms, not brakes. In Lab 19 you'll do all of this yourself — and then delete the waste." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Resource Graph, Advisor, savings plan, App Service plan)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: run `bash labs/19-cost-management/cleanup.sh`, which also removes the budget
