# Course design

Why the course looks the way it does. Read this if you maintain the course, want to add a lunch, or wonder why the demos
are animated web pages instead of long videos. The outline of every lunch is in [SYLLABUS.md](SYLLABUS.md); the writing
rules are in [AUTHORING-GUIDE.md](AUTHORING-GUIDE.md).

## 1. Goals

1. **Cover every fundamental Azure service** a new cloud engineer meets: the hierarchy and Azure Resource Manager,
   identity, virtual machines, storage, networking, load balancing, App Service, relational and NoSQL databases,
   containers, serverless, security, monitoring, backup, governance, cost and infrastructure as code.
2. **Fit each lesson into one lunch break** of 60 minutes, so busy people can learn steadily without giving up evenings.
3. **Separate learning from doing.** Reading and the demo fit in the lunch; the hands-on lab is done later, alone, at the
   learner's own pace — and every lab works without the others.
4. **Be honest about cost and safety.** Every lab says what it costs, cleans up after itself and never needs a company
   subscription.
5. **Stay current and easy to maintain** in a public GitHub repository.

## 2. Two months of lunches

| | Core month | Deep-dive month |
|---|---|---|
| Lunches | 01–21 | 22–31 (+ advanced capstone challenge) |
| Level | Basic | Advanced |
| Calendar | about 4 weeks of weekday lunches | about 2 weeks of weekday lunches |
| Aim | understand, choose and use every fundamental service; ready for AZ-900 | operate and design like an administrator or architect (AZ-104 territory) |

**Splitting rule.** When a topic needs more than one hour to teach properly, it becomes a **Basic** lunch in the core
month and an **Advanced** lunch in the deep-dive month. That happened for identity, virtual machines, storage,
networking (two advanced lunches: routing/security and hybrid connectivity), load balancing, relational databases,
containers, monitoring, and resource hierarchy and governance. Keeping the advanced halves in a second month means a
learner can stop after the core month with a complete, coherent picture — nothing in Lunches 01–21 depends on 22–31.

## 3. Anatomy of a lunch (60 minutes)

| Minutes | Segment | Purpose |
|---:|---|---|
| 5 | Scenario and objectives | a story beat from Nusantara Retail, plus 3–4 measurable objectives |
| 25 | Reading | 2,600–3,400 words with diagrams and tables, one idea per subsection |
| 15 | Demo | an interactive animation (4–8 minutes) and, where useful, a walkthrough video (≤ 6 minutes) |
| 5 | Knowledge check | five scenario questions with hidden answers |
| 5 | Key takeaways and lab preview | five takeaways and what the lab will build |
| 5 | Buffer | finish your lunch |

The reading length assumes a technical reading pace of about 120–140 words per minute: 25 minutes is roughly
3,000–3,500 words, so the 2,600–3,400-word target leaves room to study the diagrams.

## 4. How the demos are shown: interactive animation first, short video second

Each lunch has an **interactive animated HTML demo** as its primary demo, and an **optional walkthrough video** (≤ 6
minutes) with a ready-to-record script.

| Option | Strengths | Weaknesses | Role in this course |
|---|---|---|---|
| **Interactive animated HTML** (this course's demo player) | shows what screens cannot: packets, zones, failovers, scopes; learner controls the pace (play, pause, step back); tiny files; works offline and on phones; text is searchable and translatable; easy to update in a pull request; no Azure subscription needed to watch | no real portal screens; needs care to build | **primary demo for every lunch** |
| **Screencast video** | shows the real portal and CLI; builds confidence before the lab; familiar | goes stale whenever the portal changes; slow to update; large files; not searchable; GitHub caps video attachments (10 MB on free plans) | **optional companion**, ≤ 6 minutes, hosted on YouTube (or similar) and linked from the reading |
| **Terminal recording** (for example asciinema) | perfect for CLI-only demos; text-based and small | no visuals for concepts; needs an external player | optional, for CLI-heavy topics |
| **Animated GIF** | plays inline on GitHub | large files, no pause or controls, poor accessibility | avoid, except tiny loops |
| **Static diagrams** (Mermaid) | render natively on GitHub; easy to maintain | no motion | used inside every reading |

Why this split works:

- **Concepts need motion more than screens.** "What happens when a zone fails?" or "Which NSG rule wins?" is clearer as
  an animation than as a screen recording, and the animation never goes stale when the portal is redesigned.
- **Short videos keep attention.** In a large study of 6.9 million video sessions on edX, Guo, Kim and Rubin (2014)
  found that shorter videos are much more engaging and recommend chunks shorter than six minutes; median engagement
  time was at most six minutes regardless of video length. Hence the ≤ 6-minute limit for walkthrough videos and 4–8
  minutes for each interactive demo, which the learner can pause and step through.
- **Videos are easy to add later.** The course is complete without them. Each lunch ships a video script
  (`demo-video-script.md`), so recording one is a 30–60-minute job when you have time.
- **GitHub-friendly.** Demos are single self-contained HTML files served by **GitHub Pages** together with the course
  website, which is generated from the Markdown into the `docs/` folder
  (published sites can be up to 1 GB with a soft bandwidth limit of 100 GB per month — far more than this course needs).
  Videos live on a video platform because GitHub is not built for video hosting.

### The demo player

All demos share one small engine (in [`templates/demo-template.html`](templates/demo-template.html)): an SVG "stage", a
narration panel and a list of steps written as JSON. Steps can show, highlight, mark healthy or failed, dim, animate
traffic along paths, change labels, and move the camera. Learners get Play/Pause, Back/Next, a step list, three speeds,
keyboard shortcuts, deep links to a step (`#step=4`), a mobile layout, dark mode, and reduced-motion support. Because the
engine is identical everywhere, `tools/validate_demo.py` can check every demo automatically.

## 5. Labs: independent by design

- **Self-contained.** Each lab creates everything it needs (with `setup.sh` when the starting point is not the point of
  the lab). Learners can do Lab 24 without Labs 1–23.
- **One command environment.** Azure Cloud Shell (Bash) — nothing to install. A dev container is included for people who
  prefer VS Code or GitHub Codespaces.
- **Two modes.** *Guided* (step by step, with checkpoints) and *Challenge* (requirements only). `verify.sh` checks both.
- **Learning by breaking.** Every lab has a "Break it and fix it" exercise, a troubleshooting table and stretch goals.
- **Safe by default.** Shared settings (`labs/common/config.sh`): one region, small VM sizes, a random suffix for globally
  unique names, tags on every resource group, and `cleanup.sh` that removes everything — including things outside the
  resource group such as role and policy assignments.
- **Cost bands, not prices.** 💲 free or close to free · 💲💲 small charges while running · 💲💲💲 noticeable charges or
  slow-to-create gateways. Prices change and vary by region, so labs point to the pricing calculator instead of quoting numbers.

## 6. The running scenario

Every lunch advances one story: **Nusantara Retail**, a retailer with forty stores whose online shop runs on one server
in a small room next to the pantry. A single scenario gives the learner a reason for every service ("Why do we need a
load balancer? Because the director asked how long we would be offline"), makes trade-offs concrete, and ends in two
capstones that answer the director's question.

## 7. Alignment with AZ-900

The core month covers the AZ-900 skills outline (skills measured as of July 20, 2026): describe cloud concepts
(25–30%), describe Azure architecture and services (35–40%), and describe Azure management and governance (30–35%).
Lunch 21 maps every lunch to those skill areas and points to the free practice assessment on Microsoft Learn. The
course teaches beyond the exam in the labs, because hands-on experience is what makes the knowledge stick.

## 8. Publishing and maintenance

- **GitHub repository** for everything; **GitHub Pages** for the course website and the demos, built from the
  Markdown by `tools/build_site.py`.
- **Continuous checks and publishing** (`.github/workflows/publish.yml`): demo validation, shell syntax checks and
  internal link checks, then the site build and deployment, on every push to `main`.
- **Freshness.** Every reading and lab ends with "Last validated: October 2026". Review the course every quarter: Azure
  retires features (Basic public IPs and Basic Load Balancer in 2025, default outbound access for new virtual networks
  in 2026, Azure Blueprints in early 2027), renames products and changes free offers. `AUTHORING-GUIDE.md` §7 lists the
  facts most likely to change.
- **Feedback.** Issue templates let learners report a broken lab or an outdated fact.

## 9. Accessibility

Plain language, alt text and text equivalents for diagrams, narration that never relies on colour alone, keyboard
control and reduced-motion support in demos, captions on videos, and a light/dark theme that follows the reader's system.

## Reference

Guo, P. J., Kim, J., and Rubin, R. (2014). *How video production affects student engagement: An empirical study of MOOC
videos.* Proceedings of the first ACM Conference on Learning @ Scale (L@S 2014). https://doi.org/10.1145/2556325.2566239
