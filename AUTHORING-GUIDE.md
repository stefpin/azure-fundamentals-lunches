# Authoring guide

How to write and maintain lunches, demos and labs for **Azure Fundamentals: One Lunch at a Time** so every lesson feels
like it came from the same hand. Read this before you add or change content. The design rationale lives in
[COURSE-DESIGN.md](COURSE-DESIGN.md); the outline of every lunch lives in [SYLLABUS.md](SYLLABUS.md).

---

## 1. Folders, names and links

| What | Path | Notes |
|---|---|---|
| Reading | `lunches/NN-slug/README.md` | one file per lunch |
| Walkthrough video script | `lunches/NN-slug/demo-video-script.md` | ≤ 6-minute screencast plan |
| Interactive demo | `docs/demos/NN-slug.html` | served by GitHub Pages |
| Lab guide | `labs/NN-slug/README.md` | independent, self-paced |
| Lab scripts | `labs/NN-slug/*.sh` (+ `*.bicep`, `app/`, sample files) | Bash + Azure CLI |
| Shared lab settings | `labs/common/config.sh`, `helpers.sh`, `cloud-init-web.yml` | do not duplicate them |

- `NN` is always two digits. The slug is lowercase-with-hyphens and identical in all three places
  (for example `06-virtual-machines-basic`).
- Use **relative links** inside the repository (`../../labs/06-virtual-machines-basic/README.md`).
- Link to a demo with its GitHub Pages address **and** the file in the repo:
  `https://stefpin.github.io/azure-fundamentals-lunches/demos/NN-slug.html` and `../../docs/demos/NN-slug.html`.
  These links use the owner's user name (`stefpin`); a fork switches all of them with
  `python3 tools/set_github_username.py <your-name> --from stefpin`.
- Previous/next navigation at the bottom of every reading follows the lunch numbers 01 → 31.

## 2. The reading (`lunches/NN-slug/README.md`)

Start from [`templates/lunch-template.md`](templates/lunch-template.md) and keep every section in the same order.

**Length.** The reading section (from "📖 Reading" to the end of the last reading subsection) is **2,600–3,400 words**:
about 25 minutes at a technical reading pace of 120–140 words per minute. The whole file, including the knowledge check,
is usually 3,300–4,300 words. Do not pad; do not overflow — split the topic instead.

**Shape.**
- 4–6 numbered `###` subsections, each one idea. The last one ties the ideas back to Nusantara Retail.
- At least two diagrams (Mermaid renders natively on GitHub) and at least two tables.
- Two to four GitHub alerts (`> [!TIP]`, `> [!NOTE]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`).
  Use one `> [!NOTE]` for a "**Pause and think**" question.
- Exactly **5 knowledge-check questions**, scenario-style where possible, answers in `<details>` blocks with a one-line *why*.
- Exactly **5 key takeaways**.
- **2–4 "Go further" links**, each one checked to exist (Microsoft Learn preferred). Never invent a URL; if you cannot
  verify a deep link, link the product's documentation landing page instead.

**Voice.**
- Friendly, direct, second person ("you"). Short sentences. Explain *why* before *how*.
- Every new term in **bold** the first time, then used consistently.
- Concrete Nusantara Retail examples beat abstract ones. Keep the story light; keep the facts exact.
- Technical terms stay in their official form (resource group, availability zone, Microsoft Entra ID).
- No marketing language ("revolutionary", "seamless"). No emojis inside paragraphs (section headings use the fixed set from the template).

**Originality.** Write everything in your own words. Do not copy or closely paraphrase Microsoft Learn, the Azure
documentation, books (including the Manning "Month of Lunches" series) or blog posts. A short quotation (under 15 words)
with attribution is fine when wording matters.

**Accuracy.** Azure changes monthly.
- Only state numbers you are sure of (SLAs, limits, durations). If a limit is likely to change, say "at the time of
  writing (October 2026)" or point to the documentation instead of quoting it.
- Use current product names (see §7) and current SKUs (Standard public IPs and load balancers only).
- Never teach retired features as current (see §7). Mention them only as "retired — use X instead".
- End every reading with `Last validated: October 2026`.

## 3. The interactive demo (`docs/demos/NN-slug.html`)

Every demo is a **single self-contained HTML file** built from [`templates/demo-template.html`](templates/demo-template.html).

**Never change** the shared style block or the engine script ("LUNCH DEMO PLAYER · v1.0"). `tools/validate_demo.py`
fails any demo whose engine differs from the template. You edit only:
1. `<title>`, the header (kicker, `h1`, lede) and the footer stays as is;
2. the `<svg id="stage">` drawing (keep `id="stage"`, `<defs>` with the arrow marker, and `<g id="packets">` as the last child);
3. the steps JSON in `<script type="application/json" id="demo-steps">`;
4. optionally a few lines in the "DEMO-SPECIFIC STYLES" block (use the CSS variables).

**Drawing vocabulary.** Coordinate space `viewBox="0 0 960 560"`. Build with simple labelled shapes:
- `<g class="node compute|network|data|security|identity|ops|ext" id="…">` wrapping a `<rect rx="12">` and `<text>` labels
  (`text-anchor="middle"`; class `small`, `title`, `big`, `mono` for variants).
- `<g class="region">` and `<g class="zone">` for containers; `<path class="wire" marker-end="url(#arrow)">` for connections;
  `<g class="badge">` and `<g class="callout">` for labels.
- Anything that appears/disappears gets `data-el`; add `data-start` if it is visible on step 1. Static scenery has neither.
- Every path that carries traffic needs an `id` so steps can animate it (`flow`) or send `packets` along it.
- Use short ids with prefixes: `n-` nodes, `w-` wires, `z-` zones, `t-` text you change with `set`.
- Keep text ≥ 12.5 px, labels short, and nothing outside the 960 × 560 canvas. Leave 20 px margins.
- Draw your own shapes; do not embed images or external fonts. (If you later swap in official Azure architecture icons,
  Microsoft permits them in training materials — never crop, flip, rotate or distort them.)

**Story.** 8–14 steps, 4–8 minutes when autoplayed. Each step: a 3–7-word title and 35–80 words of narration. Arc:
1. set the scene (Nusantara Retail's problem); 2. introduce the parts; 3. show the mechanism moving; 4. show a failure,
attack or misconfiguration; 5. show the fix or the better design; 6. recap with a `tip` that points to the lab.
Use `highlight`, `ok`, `bad`, `dim`, `flow`, `packets` (with `stopAt` and `cls: "bad"` for blocked traffic), `set` for
changing labels and counters, and `view` to zoom the camera. Do not rely on colour alone — say it in the narration too.

**Check it.**

```bash
python3 tools/validate_demo.py docs/demos/NN-slug.html
```

It must print `PASS`. Then open the file in a browser and step through it once on a narrow window (mobile layout).

## 4. The walkthrough video script (`lunches/NN-slug/demo-video-script.md`)

From [`templates/demo-video-script-template.md`](templates/demo-video-script-template.md): a ≤ 6-minute screencast that
shows the real portal or CLI experience the animation cannot show. Include setup steps, a chapter list, a
time/on-screen/narration table, and privacy reminders. Record in a personal or dedicated demo subscription only.

## 5. The lab (`labs/NN-slug/`)

Start from [`templates/lab-template.md`](templates/lab-template.md).

**Independence is the rule.** A learner must be able to do Lab 17 without ever having done Labs 1–16. Anything a lab
needs that is not the point of the lab is created by `setup.sh`. Never reference resources from another lab.

**Files.**

| File | Required? | Purpose |
|---|---|---|
| `README.md` | always | the guide (Guided mode tasks, Challenge brief, verify, clean up, troubleshooting) |
| `setup.sh` | when the lab needs a starting point | creates prerequisites (for example two web VMs for the load-balancer lab) |
| `solution.sh` | when the tasks can be scripted with the CLI | the reference solution; lets CI smoke-test the lab |
| `verify.sh` | whenever the lab creates Azure resources | prints PASS/FAIL per check and a summary |
| `cleanup.sh` | whenever the lab creates Azure resources | removes everything, including things outside the resource group |
| `*.bicep`, `app/`, `*.json`, `*.yml` | as needed | sample code, templates, policy rules, cloud-init |

**Script conventions.**
- `#!/usr/bin/env bash`; `setup.sh`, `solution.sh` and `cleanup.sh` use `set -euo pipefail`; `verify.sh` uses
  `set -uo pipefail` (no `-e`) so every check runs.
- Start with `source "$(dirname "$0")/../common/config.sh"` and `require_az`. Learners run scripts as `bash verify.sh`.
- Resource group: `RG="$(rg_name NN)"` (or `rg_name NN purpose` for extra groups) created with `ensure_rg "$RG" NN`, so
  `delete_lunch_rgs NN` can find it.
- Names follow Cloud Adoption Framework abbreviations plus the suffix: `vnet-nusa-…`, `snet-web`, `nsg-web`, `pip-…`,
  `vm-web-1`, `lb-…`, `st<name>${SUFFIX}` (storage: lowercase letters and digits, ≤ 24 chars), `kv-nusa-${SUFFIX}`,
  `sql-nusa-${SUFFIX}`, `app-nusa-${SUFFIX}`, `log-nusa`, `rsv-nusa`, `acrnusa${SUFFIX}`, `aks-nusa`.
- Use `$LOCATION` (and `$SECONDARY_LOCATION` only when two regions are needed), `$VM_SIZE` / `$VM_SIZE_SMALL`,
  `$VM_IMAGE`, `$ADMIN_USER` from `config.sh`. Never hard-code retired or restricted sizes (B-series v1 such as
  `Standard_B1s`, Dv2/Dv3/Dsv3, F/Fsv2, Av2 — see §7). Keep concurrent vCPUs ≤ 4 where possible (free and trial
  quotas are small); every lab VM has 2 vCPUs, so that means at most two VMs at a time unless the lab says otherwise.
- Web servers: `--custom-data "$AZL_COMMON_DIR/cloud-init-web.yml"` (works without outbound internet; `/health` for probes).
- Prefer `az … --output none` for creates and `az_q …` for reads. Make scripts re-runnable (check before create, or use
  idempotent commands).
- Never hard-code secrets or print them. Generate SSH keys with `--generate-ssh-keys`. If a password is unavoidable,
  generate it at runtime (`openssl rand -base64 18`) and tell the learner where it is stored.
- Look up built-in role and policy definitions by display name, never by hard-coded GUIDs.
- `cleanup.sh` calls `delete_lunch_rgs NN` **and** removes anything outside resource groups: role assignments at
  subscription scope, policy assignments/definitions, Entra users/groups/app registrations, management groups,
  budgets, and soft-deleted Key Vaults (`az keyvault purge`). Order matters for backup vaults (stop protection and
  delete backup data first).

**Guide conventions.**
- Guided tasks are CLI-first (stable, copy-pasteable) with a `> [!TIP] **Prefer the portal?**` path where the portal
  teaches something visual. Portal-only steps are fine where the CLI has no equivalent (budgets, designer tools).
- Each task ends with a `> ✅ **Checkpoint:**` that tells the learner what they should see and how to check it.
- Include one **Break it and fix it** exercise, a troubleshooting table with real error messages, stretch goals, and a
  requirements-only **Challenge brief** that `verify.sh` can check.
- State time (realistic, including waiting), cost band, difficulty, and "Works on its own: ✅" in the header.
- Long-running steps (gateways, backups, clusters) say how long to expect and what to read while waiting.

**Cost bands.** 💲 free or close to free · 💲💲 small charges while running (typically cents per hour) · 💲💲💲 noticeable
charges while running or slow-to-create gateways — delete immediately after the lab. Do not quote exact prices; point
learners to the pricing calculator when they want numbers.

## 6. Running scenario: Nusantara Retail

PT Nusantara Retail is a mid-sized retailer with forty stores and one e-commerce site (the "storefront") that runs on a
single physical server in a small room next to the pantry. Traffic has tripled; the server has not. The director asked:
*"If that server dies, how long can't we sell?"* You are the new cloud engineer.

Cast you may use: **Ibu Sari** (the director, cares about risk and cost), **Dewi** (the developer, wants to ship fast),
**Pak Budi** (head-office IT, owns the on-premises network 10.0.0.0/16), **Rizky** (an outsourced contractor), and the
finance team. Head office is in Jakarta; stores are across Indonesia. Keep the story to the hook, the transitions and the
examples — never let it crowd out the technology.

Data residency matters for Nusantara Retail's customer data, so production would run in **Indonesia Central** (Jakarta).
The labs default to **Southeast Asia** for the broadest service availability; readings can explain the difference.

## 7. Platform facts as of October 2026

Verified facts you can rely on (re-check before a new edition):

- **AZ-900** skills measured as of July 20, 2026: Describe cloud concepts (25–30%), Describe Azure architecture and
  services (35–40%), Describe Azure management and governance (30–35%). Governance and compliance covers Microsoft
  Purview, Azure Policy and resource locks; management and deployment tools cover the portal, Cloud Shell, CLI and
  PowerShell, Azure Arc, infrastructure as code and ARM templates. A free practice assessment is available on Microsoft Learn.
- **Basic SKU public IPs and Basic Load Balancer were retired on September 30, 2025.** Use Standard. Standard public IPs
  are secure by default (closed to inbound traffic until an NSG allows it). A Standard load balancer gives backends no
  outbound access unless you add outbound rules or a NAT gateway.
- **Default outbound access:** virtual networks created with API versions released after **March 31, 2026** default to
  **private subnets** with no default outbound internet access; the portal already does this. VMs that need to reach the
  internet need an explicit method: NAT gateway, load balancer outbound rules, or a public IP on the VM. Existing virtual
  networks are not changed.
- **Azure Blueprints (preview) is being retired:** new definitions blocked from July 31, 2026; new assignments blocked from
  October 31, 2026; fully retired January 31, 2027. The recommended replacement is **deployment stacks** (plus template
  specs or Git for versioning).
- **Free account:** US$200 credit for the first 30 days, popular services free for 12 months (for example 750 hours each of
  B2pts v2 and B2ats v2 burstable VMs per month), and 65+ always-free services (for example Azure Functions 1 million
  requests per month, App Service up to 10 apps with 1 GB storage and 1 hour per day, AKS cluster management). The
  12-month services are for new customers who move to pay-as-you-go within 30 days. **Azure for Students:** US$100 credit,
  no credit card, academic email required. Always tell learners to check the current offer page.
- **VM sizes:** since July 2026 older series (B and Bs = B-series v1 such as `Standard_B1s`, D/Ds/Dv2/Dsv2/Dv3/Dsv3,
  F/Fs/Fsv2, Av2/Amv2, Ev3/Esv3, G/Gs) are under capacity growth restrictions: **new subscriptions can't deploy
  them**, and B-series v1 retires on November 15, 2028. Use current sizes: `Standard_B2ats_v2` (AMD) or
  `Standard_B2pts_v2` (Arm, needs an Arm64 image) for labs, `Standard_D2s_v5`/v6 where a D-series is required.
- **Indonesia Central** (Jakarta) opened May 27, 2025 with three availability zones and has **no paired region**.
  **Southeast Asia** (Singapore) has three zones and is paired with **East Asia** (Hong Kong). Even in a region with zones,
  some services may not support zones there.
- **GitHub limits** that affect the course: GitHub Pages sites ≤ 1 GB with a soft 100 GB/month bandwidth limit; video
  attachments in GitHub are capped at 10 MB on free plans. Host videos on YouTube (or similar) and link them.

Current names (use these): Microsoft Entra ID (not Azure AD), Microsoft Defender for Cloud (not Azure Security Center),
Microsoft Sentinel, Microsoft Purview, Azure Monitor Agent (the legacy Log Analytics agent is retired), Azure Update
Manager (replaces Automation Update Management), Microsoft Foundry (AI), Azure Cloud Shell.

**Verify before you state** (these change often — check the documentation, and phrase carefully or link instead):
service SKU/tier names and what each tier includes; free-tier amounts; CLI flags you have not used recently; VPN
Gateway SKUs; Front Door and Application Gateway SKU details; AKS networking defaults and feature GA status; Functions
hosting plans; Cosmos DB API list; Azure SQL free-offer limits; TCO calculator availability; any "retired on" date.

## 8. Before you call it done

- [ ] Reading follows the template, 2,600–3,400 words of reading, 2+ diagrams, 2+ tables, 5 questions, 5 takeaways, verified links, navigation, "Last validated".
- [ ] Demo passes `python3 tools/validate_demo.py`, 8–14 steps, story arc complete, readable on a phone.
- [ ] Video script ≤ 6 minutes with chapters and privacy reminders.
- [ ] Lab works on its own, has checkpoints, break & fix, troubleshooting, stretch goals and a Challenge brief.
- [ ] `bash -n` passes for every script; `verify.sh` checks the Challenge brief; `cleanup.sh` removes everything.
- [ ] No retired features taught as current; no invented numbers or URLs; no copied text.

## 9. The website (`docs/`)

The GitHub Pages site is generated: never edit `docs/index.html`, `docs/lunches/`, `docs/labs/`, `docs/demos/index.html`
or `docs/lunchbox.html` by hand. `tools/build_site.py` turns every reading and lab into an interactive page, so keep the
structure it relies on:

- **Readings:** the H2 sections in template order — 🍱 Today's menu, 🏪 Meanwhile at Nusantara Retail, 📖 Reading (one
  `###` heading per scene), 🎬 Demo (with a "What to watch for:" list), ✅ Knowledge check (five numbered questions, each
  with a `<details>` answer), 🧠 Key takeaways, 🔬 Your lab and 📚 Go further.
- **Labs:** `## Task N · Title` for each guided task, plus the standard 🔧 Break it and fix it, 🧪 Verify your work,
  🧹 Clean up, 🩺 Troubleshooting, 🚀 Stretch goals and 🏁 Challenge brief sections.
- **Callouts:** GitHub alerts (`> [!TIP]` and friends). A NOTE that starts with `**Pause and think:**` becomes a
  reflection card, and `> ✅ **Checkpoint:**` becomes a checkpoint strip.
- **Story layer:** an episode's title, hook, badge, metro-map station and "answer to the director" live in
  `tools/site/series.json`. Update it when a lunch changes what Nusantara Retail can do.

Rebuild with `python3 tools/build_site.py` (run `pip install -r tools/requirements-site.txt` first) and preview with
`python3 -m http.server --directory docs 8000`.

