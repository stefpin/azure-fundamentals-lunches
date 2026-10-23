# Lunch 31 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Use a **personal demo tenant** you own. Management groups are tenant-wide, and this recording moves a subscription.
- About **one hour before** recording, build the starting point with the Lab 31 scripts (Path B), then remove the
  exemption so you can create it on camera:

  ```bash
  cd azure-fundamentals-lunches/labs/31-governance-at-scale
  source ../common/config.sh && source lab-vars.sh
  ASSUME_YES=1 bash setup.sh
  MOVE_SUBSCRIPTION=yes bash solution.sh      # hierarchy, move, initiative, assignment, remediation, exemption
  source lab-vars.sh
  az policy exemption delete --name "$EXEMPTION" --resource-group "$SANDBOX_RG"
  az policy state trigger-scan --resource-group "$SANDBOX_RG" --no-wait
  ```

- Browser tabs: **Management groups**, **Policy › Definitions**, **Policy › Compliance** (scope: the intermediate root
  `mg-nusa-<suffix>`), **Resource Graph Explorer**.
- Privacy: the tenant root group's ID is your **tenant ID**, and the Management groups page shows it next to your
  subscription IDs. Blur both in editing, or crop them out while you record.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 The management group tree
01:15 One initiative, saved high
02:05 The assignment at Landing zones
02:50 Compliance from the top
03:35 A Waiver for the sandbox
04:25 Resource Graph across the tenant
05:10 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 31 · Governance for the whole company" | "Nusantara Retail is heading for twenty subscriptions. In the next five minutes you'll see how one hierarchy and one initiative govern all of them — in the real portal." |
| 00:25 | Portal › Management groups; expand **Tenant root group** › *Nusantara Retail (lab)* › Platform, Landing zones › Corp (blur IDs) | "Here's a small landing-zone tree. Under the tenant root group sits our intermediate root, then Platform and Landing zones, and Corp below that. The real thing adds Security, Management, Connectivity, Identity, Online, Sandboxes and Decommissioned." |
| 00:50 | Open **Corp**: the demo subscription is listed as a child; open the **…** menu to show **Move** without using it | "My demo subscription lives in Corp, so it inherits everything assigned above it. Moving a subscription is one click — which is exactly why only the platform team should be allowed to do it." |
| 01:15 | Policy › Definitions; filter *Definition type: Initiative*, *Type: Custom*; open **Nusantara baseline** | "Next, the rules. This custom initiative bundles three built-in policies: allowed locations, a required costCenter tag, and the tag inherited from the resource group." |
| 01:35 | Point at **Definition location**: the intermediate root; scroll to the policies and their reference IDs, then the parameters | "Look at the definition location: the intermediate root. A definition can only be assigned at or below where it's saved, so saving it high lets every group underneath reuse it. Two initiative parameters feed all three policies." |
| 01:50 | Select **+ Initiative definition** and open the **Definition location** picker, then cancel | "When you create one yourself, this picker is the decision that matters most. Save it in a subscription and it can never reach a management group." |
| 02:05 | Policy › Assignments, scope **Landing zones**; open **Nusantara baseline (Lab 31)** | "The initiative is assigned once, at Landing zones. Every subscription that lands in Corp or Online gets it automatically — today's and next year's." |
| 02:20 | Show **Policy enforcement: Disabled**, the allowed locations parameter, the **Managed identity** section | "Two details. Policy enforcement is disabled — that's DoNotEnforce, the first ring of a safe rollout: report everything, block nothing. And there's a managed identity, because the Modify policy needs one to fix resources." |
| 02:50 | Policy › Compliance, scope the intermediate root; open the initiative's compliance page | "Compliance, viewed from the top of the tree. One page for every subscription below the intermediate root." |
| 03:05 | **Resource compliance** tab: corp resources **Compliant**; sandbox network security group **Non-compliant** for two policies | "The corp resources are compliant — a remediation task copied the costCenter tag from their resource group earlier. The sandbox experiment breaks two rules: wrong region, no tag." |
| 03:35 | Open the sandbox resource › **Create exemption**: scope = sandbox resource group; category **Waiver**; expiration date 30 days ahead; description with ticket NUSA-1042 | "Ibu Sari accepts that risk for thirty days. That's a Waiver: an accepted risk, with an end date and a reason, created by someone allowed to exempt — not a silent hole in the rules." |
| 04:05 | Policy › Exemptions: the new exemption; back in Compliance (after a refresh), the sandbox resource shows **Exempt** | "It shows up as Exempt, so auditors can still see it. When it expires, the resource turns non-compliant again — nobody has to remember to remove it." |
| 04:25 | Resource Graph Explorer: run the "results by member policy and state" query from Lab 31 Task 8 | "Finally, Resource Graph. One KQL query across every subscription I can read: compliance by policy and by state." |
| 04:50 | Run the "subscriptions and their parent" query; point at **Corp** | "And where each subscription sits in the hierarchy. With twenty subscriptions, this beats clicking through the tree." |
| 05:10 | Recap slide: hierarchy → initiative saved high → assignment at Landing zones → remediate → exempt → query | "Three things to remember: design the tree for policy, not for the org chart; save definitions high and assign them once, starting in DoNotEnforce; and make exceptions visible with time-boxed exemptions. Build it yourself in Lab 31." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *management group*, *initiative*, *DoNotEnforce*,
  *Waiver*, *Resource Graph*, *KQL*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources — `cleanup.sh` removes the exemption, the assignment and its identity's role, the
  initiative, moves the subscription back, deletes the management groups (children first) and the resource groups:

  ```bash
  cd azure-fundamentals-lunches/labs/31-governance-at-scale
  bash cleanup.sh
  ```
