# Publishing and maintaining the course

A checklist for the course owner: first publication on GitHub, the optional walkthrough videos, and keeping the
material current.

## 1. Before the first push: a test pass in Azure

The readings, demos and lab guides were written and checked offline (demo validation, script syntax, links). The lab
scripts have **not yet been run against a live Azure subscription**, and Azure CLI behaviour changes between versions.
Before you announce the course, run every lab once in a personal test subscription:

```bash
cd labs/NN-slug
bash setup.sh        # if present
bash solution.sh     # if present — otherwise follow the guided tasks
bash verify.sh       # every check should PASS
bash cleanup.sh      # then confirm the resource groups are gone
```

[TEST-PASS-NOTES.md](TEST-PASS-NOTES.md) lists, lab by lab, the CLI flags, output fields and messages the authors could
not verify offline — confirm them as you go. Keep a simple log (lab, date, region, CLI version from `az version`,
result). Fix and re-test anything that fails, then
update the "Last validated" line at the end of the lab and the reading. Also scan
[AUTHORING-GUIDE.md §7](AUTHORING-GUIDE.md#7-platform-facts-as-of-october-2026) — the facts most likely to change.

> [!TIP]
> Run the labs that create gateways or clusters (26, 27, 29) last, on one day, and delete them immediately.

## 2. Publish on GitHub

The repository publishes itself: the workflow [`.github/workflows/publish.yml`](.github/workflows/publish.yml) runs on
every push to `main`. It validates the content (demos, shell syntax, links), builds the website from the Markdown with
`tools/build_site.py`, and deploys it to GitHub Pages.

1. Create a **public** repository named `azure-fundamentals-lunches` under your personal GitHub account.
2. If you publish your own copy, switch the user name in every link, then check what changed:

   ```bash
   python3 tools/set_github_username.py <your-github-user-name> --from stefpin
   git diff --stat
   ```

3. Commit and push:

   ```bash
   git init -b main
   git add .
   git commit -m "Azure Fundamentals: One Lunch at a Time — first edition"
   git remote add origin https://github.com/<your-github-user-name>/azure-fundamentals-lunches.git
   git push -u origin main
   ```

4. Turn on **GitHub Pages**: *Settings › Pages › Build and deployment › Source: **GitHub Actions***. Then run the
   workflow once more (*Actions › Publish the course site › Run workflow*). After a minute or two the site is live at
   `https://<your-github-user-name>.github.io/azure-fundamentals-lunches/`.
5. Optional but helpful: add topics (`azure`, `az-900`, `cloud`, `learning`, `hands-on-labs`), a short description and
   the website link in the repository's *About* box, and pin the repository on your profile.

### No Git on your computer? Upload a bundle

The workflow also accepts a complete new version of the course as one zip file:

1. Zip the repository folder as `course-bundle.zip` (a top-level `azure-fundamentals-lunches/` folder inside the zip is
   fine).
2. On GitHub, open the repository › *Add file › Upload files*, drop `course-bundle.zip` into the root and commit.
3. The workflow unpacks the zip over the repository (removing files that are no longer in the bundle), commits the
   result as *Unpack course bundle*, then validates, builds and deploys the site.

A bundle never changes files in `.github/workflows/` (the workflow token is not allowed to), so edit workflows on
GitHub directly.

## 3. Rebuild after changes

The README tables and the website are generated from the lunches and labs:

```bash
python3 tools/build_index.py                       # tables in README.md and labs/README.md
pip install -r tools/requirements-site.txt         # once: markdown-it-py (Pillow is optional, for the social card)
python3 tools/build_site.py                        # the website in docs/
python3 -m http.server --directory docs 8000       # preview at http://localhost:8000
python3 tools/validate_demo.py
python3 tools/check_links.py
```

The workflow rebuilds and redeploys the site on every push, so the website stays in sync even when you edit a reading
directly on GitHub. Commit the regenerated `docs/` as well, so the repository copy stays browsable offline.

What the site generator reads:

| Source | Becomes |
|---|---|
| `lunches/NN-slug/README.md` | the episode page `docs/lunches/NN-slug.html`: menu, story, scenes, demo theatre, quiz, takeaways, lab ticket |
| `labs/NN-slug/README.md` | the lab page `docs/labs/NN-slug.html`: guided or challenge mode, task check-offs, clean-up reminder |
| `labs/README.md` | the lab hub `docs/labs/index.html` |
| `docs/demos/NN-slug.html` | the demo gallery `docs/demos/index.html` |
| `tools/site/series.json` | the story layer: episode titles, hooks, badges, cast, XP levels and the director's question |
| `docs/assets/site.css`, `docs/assets/site.js` | the hand-written design system and behaviour (not generated) |

Learners' progress, XP, badges and notes are stored only in their own browser (`localStorage`); the site collects
nothing.

## 4. Record the optional walkthrough videos

Each lunch folder has a `demo-video-script.md`: a ≤ 6-minute screencast plan with setup steps, chapters and narration.

1. Record in your **personal or a dedicated demo subscription**. Hide subscription IDs, tenant names, e-mail addresses
   and anything personal; turn notifications off; zoom the browser to 125–150%.
2. Keep each video under six minutes. If a script runs long, split it into two videos.
3. Upload to YouTube (or a similar platform) as *Unlisted* or *Public*. Add captions (auto-generate, then fix Azure
   terms), the chapter list from the script, and a link back to the lunch.
4. Paste the link into the lunch README, section **🎬 Demo**, replacing "_coming soon_".

GitHub is not a video host: attachments are capped (10 MB for videos on free plans), so always link out.

## 5. Keep it current

- **Every quarter:** re-run a few labs, re-check AUTHORING-GUIDE §7, scan Azure updates for retirements and renames,
  and update "Last validated".
- **When Azure changes:** fix the reading, the demo narration and the lab together, so they never disagree.
- **Issues:** the issue templates collect lab problems and content corrections. Label them, fix them, and thank the
  reporter — it builds the community around the course.
- **Editions:** tag a release (`v2026.10`, `v2027.04`, …) when you finish a review, so learners can see what changed.

## 6. Personal project hygiene

- Use your **personal** GitHub account and a **personal** Azure subscription for everything in this repository.
- Keep the disclaimer in `README.md` (independent project, not official Microsoft content).
- If you work for a company with a policy on personal open-source projects or public writing, check it before you
  publish.
- Licences: written content is under CC BY-NC-SA 4.0 and code under MIT (see `LICENSE-CONTENT.md` and `LICENSE`).
  Change them before publishing if you prefer different terms, for example if you plan to turn the course into a book.
