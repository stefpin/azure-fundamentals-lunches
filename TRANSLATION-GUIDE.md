# Translation guide: the Bahasa Indonesia edition

How the Indonesian edition of **Azure Fundamentals: One Lunch at a Time** is written and kept in step with the English
original. Read this before you translate or update any `*.id.md` file, a demo narration or the story layer.

The Indonesian edition is called **Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran**.

---

## 1. Voice: write it, don't just translate it

The Indonesian text is a **native adaptation**, not a word-for-word translation. A reader should feel that it was
written in Indonesian for Indonesian engineers.

- **Address the reader as "Anda"** — professional and warm. Never "kamu", "-mu", "lo" or "gue".
  Use "kita" when the narrator and reader do something together ("Mari kita lihat…").
- **Engaging and clear.** Short sentences, active voice, concrete verbs. Keep the humour of the story, but
  translate the joke, not the words: if an English idiom doesn't work, use an Indonesian one.
- **Beginner-first.** Assume the reader is new to cloud and reads every word. When a concept appears for the first
  time, explain it in plain Indonesian in one or two sentences *before* the technical detail, spell out every
  acronym, and never leave a term unexplained. A novice must be able to follow without guessing.
- **Make it stick.** Where a concept is abstract, add a short everyday example or analogy from Indonesian life
  (warung, ojek online, kos-kosan, token listrik PLN, antrean bank, pasar, mudik, banjir, parkir mal…), typically
  two to four per lunch, each a few sentences. Use clearly illustrative framing ("Bayangkan…", "Ibaratnya…"), never
  a claim that something really happened. Examples explain; they never change a fact, and they never replace the
  precise technical statement.
- **Facts stay identical.** Numbers, limits, SKUs, commands, quiz answers, costs, region names and the order of steps
  must match the English exactly. If you think the English is wrong, do not "fix" it silently in Indonesian —
  keep the English fact and add a line to your hand-back report.
- **No customer stories.** Do not add real companies, real incidents or anything that sounds like a story from
  the author's employer or clients. The fictional PT Nusantara Retail and its people are the only "customers".
- **No Microsoft logos, no claims of being official.** Keep every disclaimer.
- **Numbers and times, Indonesian style in prose:** `99,9%`, `1.000 GB`, `Rp12.000`, `19.00 WIB`. Inside code,
  commands, JSON and CLI output, keep numbers exactly as in English.

## 2. Golden rules

1. **Same structure.** Same H2 sections in the same order, same number of H3 scenes, same number of quiz questions,
   takeaways, tasks, callouts, tables and diagrams. The website generator and the automated checks depend on it.
2. **Code is never translated.** Every fenced code block (except `mermaid`) is copied **byte for byte** — including
   comments and blank lines. Inline code (`` `az vm create` ``) stays as is.
3. **Links point to the Indonesian twin** wherever one exists (see §6).
4. **Fixed phrases are fixed** (see §4). The website parses them.

## 3. Files

| English | Indonesian twin |
|---|---|
| `lunches/NN-slug/README.md` | `lunches/NN-slug/README.id.md` |
| `lunches/NN-slug/demo-video-script.md` | `lunches/NN-slug/demo-video-script.id.md` |
| `labs/NN-slug/README.md` (and other `*.md` in the lab folder) | `labs/NN-slug/README.id.md` (`worksheet.id.md`, …) |
| `README.md`, `labs/README.md`, `SYLLABUS.md` | `README.id.md`, `labs/README.id.md`, `SYLLABUS.id.md` |
| demo narration inside `docs/demos/NN-slug.html` | `tools/i18n/demos/NN-slug.id.json` (see §8) |
| `tools/site/series.json` (story layer, badges) | `tools/site/series.id.json` (same keys) |

Lab scripts (`*.sh`, `*.bicep`, `*.json`, `app/…`) are shared by both editions and are **not** translated.
Maintainer documents (this guide, AUTHORING-GUIDE, PUBLISHING, TEST-PASS-NOTES, COURSE-DESIGN, CONTRIBUTING) stay
in English.

Every Indonesian Markdown file starts with the H1, then this line, then the rest:

```text
🇬🇧 [Read in English](README.md)
```

(link to the English twin's file name, e.g. `demo-video-script.md`).

## 4. Fixed phrases

### Lunch readings (`lunches/*/README.id.md`)

| English | Indonesian (use exactly) |
|---|---|
| `# Lunch 06 · Virtual Machines (Basic)` | `# Makan Siang 06 · Virtual Machines (Dasar)` |
| (Advanced) | (Lanjutan) |
| header `**Track:** Core month · **Level:** Basic · **Part 2:** Core infrastructure` | `**Jalur:** Bulan inti · **Level:** Dasar · **Bagian 2:** Infrastruktur inti` |
| Deep-dive month | Bulan pendalaman |
| `**Time:** 60 minutes · **Prerequisite lunches:** 01, 03, 04` | `**Waktu:** 60 menit · **Makan siang prasyarat:** 01, 03, 04` (none → tidak ada) |
| `**AZ-900 skill area:** …` | `**Area keterampilan AZ-900:** …` (see skill areas below) |
| `**Lab:** [Lab 06 · …](…) — about 45 minutes · cost 💲💲` | `**Lab:** [Lab 06 · …](…README.id.md) — sekitar 45 menit · biaya 💲💲` |
| `**Author:** Stefanus Pinarta · [About the author](…)` | `**Penulis:** Stefanus Pinarta · [Tentang penulis](../../README.id.md#tentang-penulis)` |
| timing table `⏱ Minutes` / `Segment` | `⏱ Menit` / `Segmen` |
| Scenario and objectives · Reading · Demo: interactive animation (+ optional walkthrough video) · Knowledge check · Key takeaways and lab preview · Buffer — finish your lunch 🍜 | Skenario dan tujuan · Bacaan · Demo: animasi interaktif (+ video panduan opsional) · Uji pemahaman · Poin penting dan pratinjau lab · Waktu cadangan — habiskan makan siang Anda 🍜 |
| `## 🍱 Today's menu` | `## 🍱 Menu hari ini` |
| By the end of this lunch you will be able to: | Setelah makan siang ini, Anda akan mampu: |
| `## 🏪 Meanwhile at Nusantara Retail` | `## 🏪 Sementara itu di Nusantara Retail` |
| `## 📖 Reading (≈25 minutes)` | `## 📖 Bacaan (≈25 menit)` |
| `## 🎬 Demo (≈15 minutes)` | `## 🎬 Demo (≈15 menit)` |
| What to watch for: | Yang perlu diperhatikan: |
| `## ✅ Knowledge check (≈5 minutes)` | `## ✅ Uji pemahaman (≈5 menit)` |
| `<details><summary>Show answer</summary>` | `<details><summary>Lihat jawaban</summary>` |
| `*why:*` | `*alasannya:*` |
| `## 🧠 Key takeaways` | `## 🧠 Poin penting` |
| `## 🗒️ Field notes from Stefanus` | `## 🗒️ Catatan lapangan dari Stefanus` |
| `## 🔬 Your lab: <lab title>` | `## 🔬 Lab Anda: <judul lab>` |
| `👉 [Start Lab 06](…)` | `👉 [Mulai Lab 06](…README.id.md)` |
| `## 📚 Go further` | `## 📚 Pelajari lebih lanjut` |
| `> [!NOTE]` + `**Pause and think:**` | `> [!NOTE]` + `**Renungkan sejenak:**` |
| footer `⬅️ [Lunch 05 · …](…) · 🏠 [Course home](../../README.md) · [Lunch 07 · …](…) ➡️` | `⬅️ [Makan Siang 05 · …](…README.id.md) · 🏠 [Beranda kursus](../../README.id.md) · [Makan Siang 07 · …](…README.id.md) ➡️` |
| `<sub>Last validated: October 2026 · Spotted something out of date? [Open an issue](../../CONTRIBUTING.md).</sub>` | `<sub>Terakhir divalidasi: Oktober 2026 · Menemukan informasi yang sudah usang? [Buka issue](../../CONTRIBUTING.md).</sub>` |

Demo section lines:
- `Interactive animation (≈6–8 min): [Open the demo](https://stefpin.github.io/azure-fundamentals-lunches/demos/NN-slug.html)`
  → `Animasi interaktif (≈6–8 menit): [Buka demo](https://stefpin.github.io/azure-fundamentals-lunches/demos/NN-slug.html?lang=id)`
- `Walkthrough video (≤ 6 min): _coming soon_ — [read the walkthrough script](demo-video-script.md).`
  → `Video panduan (≤ 6 menit): _segera hadir_ — [baca naskah video](demo-video-script.id.md).`

AZ-900 skill areas (official Indonesian wording from the Microsoft Learn study guide):
Describe cloud concepts → **Menjelaskan konsep cloud** · Describe Azure architecture and services → **Menjelaskan
arsitektur dan layanan Azure** · Describe Azure management and governance → **Menjelaskan manajemen dan tata kelola
Azure** · Beyond AZ-900 → **Di luar cakupan AZ-900**.

Parts: Foundations → Fondasi · Core infrastructure → Infrastruktur inti · Platform services and data → Layanan
platform dan data · Secure, operate and govern → Keamanan, operasional, dan tata kelola · Deep dives → Pendalaman.

### Lab guides (`labs/*/README.id.md`)

| English | Indonesian (use exactly) |
|---|---|
| `# Lab 06 · Your first web server VM` | `# Lab 06 · <judul dalam bahasa Indonesia>` (keep "Lab NN ·") |
| `**Pairs with:**` | `**Pasangan dari:**` |
| `**Time:** about 45 minutes · **Cost:** 💲💲 (see [cost bands](../README.md#cost-bands)) · **Difficulty:** ★☆☆` | `**Waktu:** sekitar 45 menit · **Biaya:** 💲💲 (lihat [kelompok biaya](../README.id.md#kelompok-biaya)) · **Tingkat kesulitan:** ★☆☆` |
| `**Works on its own:**` | `**Bisa dikerjakan terpisah:**` |
| `**Author:** …` | `**Penulis:** Stefanus Pinarta · [Tentang penulis](../../README.id.md#tentang-penulis)` |
| `## 🎯 What you'll build` | `## 🎯 Yang akan Anda bangun` |
| `## ✅ Before you start` | `## ✅ Sebelum mulai` |
| `## 🧭 Choose your mode` (Guided / Challenge) | `## 🧭 Pilih mode Anda` (Terpandu / Tantangan) |
| `## Task 3 · Install nginx …` | `## Tugas 3 · Memasang nginx …` |
| `## Task 7 (optional) · …` | `## Tugas 7 (opsional) · …` |
| `## 🔧 Break it and fix it` | `## 🔧 Rusak lalu perbaiki` |
| `## 🔥 Optional · …` | `## 🔥 Opsional · …` |
| `## 🧪 Verify your work` | `## 🧪 Verifikasi hasil kerja Anda` |
| `## 🧹 Clean up (do not skip!)` | `## 🧹 Bersihkan (jangan dilewati!)` |
| `## 🩺 Troubleshooting` (Symptom / Likely cause / Fix) | `## 🩺 Pemecahan masalah` (Gejala / Kemungkinan penyebab / Perbaikan) |
| `## 🚀 Stretch goals` | `## 🚀 Tantangan tambahan` |
| `## 🏁 Challenge brief` | `## 🏁 Ringkasan tantangan` |
| `> ✅ **Checkpoint:**` | `> ✅ **Pemeriksaan:**` |
| footer `⬅️ [Lunch 06 reading](…) · 🏠 [All labs](../README.md) · 🏠 [Course home](../../README.md)` | `⬅️ [Bacaan Makan Siang 06](…README.id.md) · 🏠 [Semua lab](../README.id.md) · 🏠 [Beranda kursus](../../README.id.md)` |
| `<sub>Last validated: October 2026 · Something broken? [Report a lab problem](../../CONTRIBUTING.md).</sub>` | `<sub>Terakhir divalidasi: Oktober 2026 · Ada yang tidak berfungsi? [Laporkan masalah lab](../../CONTRIBUTING.md).</sub>` |

Capstone (lab 32): `# Tantangan capstone lanjutan · <subjudul>`; 🎯 The brief → Ringkasan proyek · ✅ Before you start →
Sebelum mulai · 🧭 How this challenge works → Cara kerja tantangan ini · 📋 Requirements → Persyaratan · 🚧 Constraints →
Batasan · 🗺 Suggested architecture → Arsitektur yang disarankan · ✅ Acceptance checklist → Daftar periksa penerimaan ·
💡 Hints → Petunjuk · 🧹 Clean up → Bersihkan · 🩺 Troubleshooting → Pemecahan masalah · 🚀 Stretch goals → Tantangan
tambahan · 📚 Where each piece is taught → Di mana setiap bagian diajarkan.

Labs hub (`labs/README.id.md`): `# Lab praktik` · `## Cara kerja lab` · `## Kelompok biaya` · `## Semua lab` ·
`## Jika terjadi masalah`. Cost bands: 💲 gratis atau hampir gratis · 💲💲 biaya kecil selama resource berjalan ·
💲💲💲 biaya yang terasa selama berjalan.

### The story

PT Nusantara Retail, Ibu Sari (direktur), Pak Budi (TI kantor pusat), Dewi (developer), Rizky (kontraktor). The
director's question is always: **"Kalau server itu mati, berapa lama kita tidak bisa jualan?"** Head office → kantor
pusat; storefront → toko online (the app is still called "storefront" in code and resource names).

## 5. Terminology

Rule of thumb: **technical terms stay as Azure shows them in the portal and CLI** (resource group, subnet,
availability zone, storage account…); the sentences around them are Indonesian. The first time a key term appears
in a lunch, add the **official Indonesian exam term** in italics in brackets, because the AZ-900 exam can be taken
in Indonesian: *"Setiap resource harus berada di dalam sebuah resource group (*grup sumber daya*)."* After that,
use the English term only.

- Azure product and feature names never change (Azure Key Vault, Microsoft Entra ID, Azure Policy, App Service…).
- Portal labels are quoted exactly as the English portal shows them, e.g. **Create a resource**, then explained.
- Indonesian affixes on English words take a hyphen and no italics: *di-deploy, men-deploy, di-restart,
  di-scale, ter-deallocate*. Prefer a natural Indonesian verb when one exists (menyalakan, mematikan, menghapus).
- Generic words are translated: network → jaringan, storage → penyimpanan, cost → biaya, security → keamanan,
  backup → cadangan (backup), monitoring → pemantauan, outage → gangguan, bill → tagihan, budget → anggaran (budget).

| English term (keep in text) | Official exam term — add once, in italics | Notes |
|---|---|---|
| cloud computing | *komputasi awan* | in prose "cloud" is fine |
| shared responsibility model | *model tanggung jawab bersama* | translate fully |
| public / private / hybrid cloud | *cloud publik / privat / hibrid* | translate fully |
| consumption-based model, pay-as-you-go | *model berbasis penggunaan* | |
| high availability · scalability · elasticity | *ketersediaan tinggi · skalabilitas · elastisitas* | translate fully |
| reliability · predictability | *keandalan · prediktabilitas* | translate fully |
| governance · compliance | *tata kelola · kepatuhan* | translate fully |
| IaaS · PaaS · SaaS | *infrastruktur / platform / perangkat lunak sebagai layanan* | keep acronyms |
| CapEx · OpEx | belanja modal (CapEx) · belanja operasional (OpEx) | |
| region · region pair · sovereign region | *wilayah · pasangan wilayah · wilayah berdaulat* | keep "region" in text |
| availability zone | *zona ketersediaan* | |
| datacenter | *pusat data* | "pusat data" in prose |
| subscription | *langganan* | keep "subscription" |
| management group | *grup manajemen* | |
| resource · resource group | *sumber daya · grup sumber daya* | keep English |
| Azure Resource Manager (ARM) · ARM template | *templat ARM* | |
| virtual machine (VM) | *komputer virtual* | keep "virtual machine"/"VM" |
| virtual machine scale set | *Kumpulan Skala Komputer Virtual* | |
| availability set | *set ketersediaan* | |
| container · function · web app | *kontainer · fungsi · aplikasi web* | keep product names |
| virtual network (VNet) | *jaringan virtual* | |
| public / private endpoint | *titik akhir publik / privat* | |
| network security group (NSG) | — | keep |
| storage account · access tier · redundancy | *akun penyimpanan · tingkatan penyimpanan · opsi redundansi* | |
| Microsoft Entra ID | *ID Microsoft Entra* | |
| multifactor authentication (MFA) · single sign-on (SSO) · passwordless | *autentikasi multifaktor · sistem masuk tunggal · tanpa kata sandi* | |
| Conditional Access | *Akses Bersyarat* | |
| role-based access control (RBAC) | *kontrol akses berbasis peran* | |
| least privilege | prinsip hak akses minimum (least privilege) | |
| defense in depth · Zero Trust | *pertahanan mendalam* · Zero Trust | |
| Microsoft Defender for Cloud | *Microsoft Defender untuk Cloud* | |
| cost management · pricing calculator | *manajemen biaya · kalkulator harga* | |
| tag · resource lock | tag · *kunci sumber daya* | |
| infrastructure as code (IaC) | *infrastruktur sebagai kode* | |
| alert (Azure Monitor) | *pemberitahuan* | keep "alert" in text |
| disaster recovery (DR) · RTO · RPO | pemulihan bencana (disaster recovery) | explain RTO/RPO in Indonesian |
| deallocate · stop | deallocate · stop | explain the billing difference in Indonesian |

## 6. Links and anchors

- Lunch → lab: `../../labs/NN-slug/README.id.md`; lunch → lunch: `../NN-slug/README.id.md`; → course home:
  `../../README.id.md`; lab → labs hub: `../README.id.md`. `CONTRIBUTING.md`, `LICENSE*` and the maintainer documents
  stay English: keep those links unchanged.
- Demo links on GitHub Pages get `?lang=id` before any `#`: `…/demos/06-virtual-machines-basic.html?lang=id`.
  Links to the demo *file* in the repo (`../../docs/demos/….html`) stay unchanged.
- External links (Microsoft Learn, pricing pages) stay unchanged. Microsoft Learn links without a locale already
  open in the reader's language.
- Headings get new anchors when they are translated. Fix every `#anchor` in your file to the GitHub slug of the
  **Indonesian** heading (lower case, punctuation and emoji removed, spaces → hyphens; `## 🏁 Ringkasan tantangan` →
  `#-ringkasan-tantangan`). Shared targets: `../README.id.md#kelompok-biaya`, `../../README.id.md#tentang-penulis`.

## 7. Markdown details

- **Mermaid:** keep the diagram type, node IDs, arrows, `subgraph` IDs, `<br/>` and HTML entities (`&lt;suffix&gt;`)
  exactly; translate only the quoted labels and edge labels, keeping resource names in English.
- **GitHub alerts:** keep `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]` in English.
- **Tables:** same number of rows and columns; code and resource names inside cells unchanged.
- **Quiz:** five numbered questions, each followed by the `<details>` block; answer text ends with `*alasannya:* …`.
- **Emoji, ★ ratings and 💲 cost bands** stay as they are.

## 8. Demo narration (`tools/i18n/demos/NN-slug.id.json`)

The demo animation is shared; only its words change. Start from the extracted source
`tools/i18n/demos-src/NN-slug.en.json` and write the Indonesian file with **the same shape**:

```json
{
  "page":  {"doc_title": "…", "kicker": "…", "title": "…", "lede": "…", "svgTitle": "…", "svgDesc": "…"},
  "steps": [ {"title": "…", "text": "…", "tip": "…", "set": {"same-id": "…"}} ],
  "svg":   {"exact English label": "label Indonesia"}
}
```

- `steps`: exactly the same number of steps, in the same order. Every step has `title` and `text`; include `tip`
  only where the English step has one; `set` must have exactly the same element IDs as the English step.
- Narration may be slightly richer than English (it is read on screen), but keep each step close to the English
  length and under about 90 words (title + text + tip).
- `svg`: translate only descriptive labels ("Azure region · Southeast Asia" → "Region Azure · Southeast Asia",
  "Shopper's browser" → "Browser pembeli"). Leave out labels that are resource names, IP ranges, commands or product
  names — they stay English automatically. Keys must be copied exactly from the English source list.
- Valid JSON (UTF-8, double quotes, no trailing commas).

## 9. Field notes from Stefanus

Every lunch has a short first-person note from the author, in both languages, placed between **Key takeaways** and
**Your lab**:

```markdown
## 🗒️ Field notes from Stefanus

> **<A short, memorable headline.>** <90–140 words in the first person.>
```

Indonesian: `## 🗒️ Catatan lapangan dari Stefanus`, same blockquote format, written natively (not a literal
translation).

What makes a good note: a practical habit, a rule of thumb, a question the author always asks, or a common trap and
how to avoid it — something a reader remembers next week. Rules: first person ("I", "saya"); no customer, employer
or project names; no invented incidents, dates or statistics; no "hire me"; technically consistent with the lunch.

Example (Lunch 06):

> **Stopped is not the same as switched off.** In design reviews I ask one question about every VM: *what state
> should it be in at two in the morning?* If the answer is "off", I want auto-shutdown or a schedule, not a promise.
> If the answer is "gone", I delete the resource group, not just the VM, because orphaned disks and public IP
> addresses are the quiet line items that survive a hasty cleanup. And when a small VM suddenly feels slow, I check
> the size family before I touch the code: a burstable VM that has used up its CPU credits looks exactly like a bug.

## 10. Length and reading time

Each lunch must still fit its 60-minute plan. Keep the Indonesian **Reading** section within about 90–130% of the
English word count (the extra room is for explanations and examples); trim an analogy rather than overrun. Quiz,
takeaways and lab structure match the English.

**Video scripts** (`demo-video-script.id.md`) are written for recording the walkthrough in Indonesian: translate the
narration, the on-screen notes and the chapter list (keep every timestamp), keep portal labels and commands in
English exactly as they appear on screen.

## 11. Check your work

```bash
python3 tools/i18n/check_parity.py lunches/06-virtual-machines-basic labs/06-virtual-machines-basic
python3 tools/i18n/demo_text.py check 06-virtual-machines-basic
```

The checks compare structure, code blocks, links, anchors, quiz items and demo steps with the English original,
flag leftover English sentences and any "kamu". Fix every error before you hand back. Before publishing, run the
whole set with `python3 tools/i18n/check_parity.py --strict` (missing link targets become errors) and rebuild the
site with `python3 tools/build_site.py`, which embeds the demo translations and builds `docs/id/`.
