"""Interface text for the course website, in English and Bahasa Indonesia.

Used by tools/build_site.py (page text) and shipped to the browser in docs/assets/course-data.<lang>.js
(the "js" table, used by docs/assets/site.js). Placeholders use Python str.format syntax: {n}, {title}…
Keep both languages in step: every key must exist in both tables.
"""

AUTHOR = {
    "name": "Stefanus Pinarta",
    "initials": "SP",
    "email": "stefanus.pinarta@gmail.com",
    "linkedin": {"en": "https://www.linkedin.com/in/stefanus-pinarta-8193512/",
                 "id": "https://id.linkedin.com/in/stefanus-pinarta-8193512"},
    "photo": "",  # optional: path under docs/assets/, e.g. "author.jpg"; empty = monogram
}

EN = {
    "html_lang": "en", "og_locale": "en_US", "lang_name": "English", "lang_short": "EN",
    "course": "Azure Fundamentals: One Lunch at a Time",
    "brand_main": "One Lunch at a Time", "brand_small": "Azure Fundamentals",
    "skip": "Skip to content",
    "nav_journey": "Journey", "nav_episodes": "Episodes", "nav_labs": "Labs", "nav_demos": "Demos",
    "nav_lunchbox": "My lunchbox", "nav_main": "Main",
    "hud_title": "Your progress", "theme_toggle": "Switch between light and dark mode", "menu_open": "Open the menu",
    "switch_to": "Baca dalam Bahasa Indonesia",
    "footer_blurb": ("Thirty-one lunch-sized episodes, animated demos and hands-on labs that take one fictional "
                     "Indonesian retailer from a server next to the pantry to a governed, resilient Azure platform."),
    "f_learn": "Learn", "f_all_episodes": "All episodes", "f_labs": "Hands-on labs", "f_demos": "Demo gallery",
    "f_lunchbox": "My lunchbox", "f_repo": "Repository", "f_source": "Source on GitHub", "f_syllabus": "Syllabus",
    "f_syllabus_file": "SYLLABUS.md", "f_design": "Course design", "f_report": "Report a problem",
    "f_author": "Author", "f_about_author": "About the author", "f_email": "Email",
    "fine": ("An independent, personal learning project — not official Microsoft training, documentation or "
             "certification material, and not endorsed by Microsoft. Azure changes often: check the current "
             '<a href="https://learn.microsoft.com/azure/" target="_blank" rel="noopener">Azure documentation</a> '
             "and pricing before relying on a detail. Microsoft, Azure and related names are trademarks of the "
             "Microsoft group of companies. Nusantara Retail and its people are fictional. Text and demos: {cc} · code: {mit}."),
    "privacy": ("Progress, badges and notes are stored only in your browser. Visits are counted anonymously "
                "with GoatCounter: no cookies and no personal data."),
    "privacy_nocount": "Progress, badges and notes are stored only in your browser.",
    "visits_label": "visitors so far",
    # markdown rendering
    "callout_note": "Note", "callout_tip": "Tip", "callout_important": "Important", "callout_warning": "Warning",
    "callout_caution": "Caution", "callout_think": "Pause and think", "copy": "Copy",
    "zoom": "⤢ Zoom", "zoom_label": "Zoom into the diagram", "anchor_label": "Link to this section",
    # levels, costs
    "level_basic": "Basic", "level_advanced": "Advanced", "capstone": "Capstone",
    "cost_1": "free or close to free", "cost_2": "small charges while running", "cost_3": "noticeable charges while running",
    # svg art
    "pantry": "The pantry server", "pantry_moods": ["sweating", "worried", "calmer", "happy", "relaxed"],
    "pantry_mood": "The pantry server, {mood}", "pantry_progress": "The pantry server — it gets happier as you progress",
    "pantry_overheat": "The pantry server, overheating", "pantry_still": "The pantry server, still sweating",
    "gauge_label": "Readiness to answer the director's question", "gauge_low": "Days?", "gauge_high": "Answered",
    "clock_label": ("The 60-minute lunch: 5 minutes scenario, 25 reading, 15 demo, 5 knowledge check, 5 takeaways, "
                    "5 buffer"),
    "clock_min": "min", "clock_center": "60 min", "clock_sub": "one lunch",
    "segments": [
        ("Scenario & objectives", "Meet the problem of the day at Nusantara Retail and the five things you will be able to do by the end."),
        ("Reading", "Six short scenes with diagrams, tables, tips and pause-and-think moments. No walls of text."),
        ("Animated demo", "Watch the idea move: packets, permissions and failovers you can play, pause and step through."),
        ("Knowledge check", "Five scenario questions. Answer in your head, reveal, grade yourself honestly and earn XP."),
        ("Takeaways & lab ticket", "Pin the key points to your notebook and pick up the ticket for today's hands-on lab."),
        ("Buffer", "Finish your lunch. Seriously. The lab waits for you, whenever suits you."),
    ],
    # episode page
    "prev_first": ("Nothing yet. It's your first Monday at PT Nusantara Retail, and something is humming loudly next "
                   "to the pantry."),
    "prev_label": "Previously on Nusantara Retail", "prev_recap": "Season 1 recap",
    "previously": "In Episode {n} · {ep}, {outcome}",
    "chip_s1_finale": "🏆 Season 1 finale", "chip_s2_premiere": "🌊 Season 2 premiere", "chip_last": "🎬 Last episode",
    "ep_pill": "Episode {n}", "ep_meta": "Season {s} · {icon} Part {p} · {part}", "lunch_label": "Lunch {n} · {title}",
    "chip_60": "⏱ 60-minute lunch", "chip_az900": "AZ-900 · {area}", "beyond_prefix": "Beyond",
    "chip_lab": "🔬 Lab · {time} · {cost}", "chip_builds_on": "Builds on", "chip_no_prereq": "No prerequisites",
    "cta_start": "🍱 Start the 60-minute lunch", "cta_demo": "🎬 Jump to the demo", "cta_finish": "✓ Mark lunch finished",
    "byline": "Written by", "byline_role": "Senior Solutions Engineer · 20+ years in enterprise IT",
    "meter": "The director's question · {pct}% ready", "meter_say": "After this episode you can say: “{answer}”",
    "scene_of": "Scene {i} of {n}", "obj_lead": "By the end of this lunch you will be able to:",
    "obj_btn": "I can do this now", "obj_hint": "Tick an objective when you can really do it. Each one is worth 5 XP.",
    "demo_default": "Interactive demo",
    "reveal": "Reveal answer", "got_it_q": "Did you get it?", "got_it": "👍 I got it", "not_quite": "👎 Not quite",
    "pin": "📌 Pin to notebook", "this_course": "this course",
    "next_ep": "Next episode · {n}", "watch_ep": "Watch Episode {n} →", "season_finale": "Season finale",
    "take_capstone": "Take the capstone challenge →",
    "nav_prev_ep": "← Previous episode", "nav_home": "← Course home", "nav_journey_map": "The journey map",
    "nav_next_ep": "Next episode →", "nav_finale": "Season finale →", "capstone_title": "Advanced capstone challenge",
    "rail_label": "Lunch clock", "rail_menu": "Today's menu", "rail_story": "Meanwhile…", "rail_reading": "Reading",
    "rail_demo": "Demo", "rail_quiz": "Knowledge check", "rail_take": "Takeaways", "rail_notes": "Field notes",
    "rail_lab": "Your lab", "rail_finish": "Finish", "rail_timer": "🍱 Start the lunch timer", "rail_open_lab": "🔬 Open Lab {n}",
    "mob_label": "Sections of this lunch", "mob_menu": "🍱 Menu", "mob_story": "🏪 Story", "mob_reading": "📖 Reading",
    "mob_demo": "🎬 Demo", "mob_quiz": "✅ Quiz", "mob_take": "🧠 Takeaways", "mob_notes": "🗒️ Notes", "mob_lab": "🔬 Lab",
    "mob_finish": "🏁 Finish",
    "h_menu": "Today's menu", "min_menu": "Minutes 0–5", "story_tag": "🏪 Meanwhile at Nusantara Retail · Episode {n}",
    "h_reading": "Reading", "min_reading": "Minutes 5–30 · {k} scenes", "h_demo": "Demo", "min_demo": "Minutes 30–45",
    "theatre_live": "Interactive demo · {title}", "open_tab": "↗ Open in a new tab", "theatre": "⤢ Theatre mode",
    "iframe_title": "Interactive demo: {title}",
    "watch_hint": "Press <b>▶ Play</b>, or step through with the arrow keys. Watch it to the last step to earn 30 XP.",
    "video_script": 'Prefer video? Read the <a href="{href}" target="_blank" rel="noopener">walkthrough video script</a>.',
    "h_quiz": "Knowledge check", "min_quiz": "Minutes 45–50", "quiz_head": "{k} scenario questions. Honest grading.",
    "quiz_note": "Answer in your head, reveal, then be honest with yourself.",
    "h_take": "Key takeaways", "min_take": "Minutes 50–55",
    "h_notes": "Field notes from Stefanus", "notes_sub": "Senior Solutions Engineer · 20+ years in enterprise IT",
    "notes_more": "More about the author", "h_lab": "Your lab", "min_lab": "Any time · your own pace",
    "admit": "Admit one", "works_alone": "✅ Works on its own", "modes": "🧭 Guided or challenge mode",
    "start_lab": "Start Lab {n} →", "h_further": "Go further",
    "finish_kicker": "Finish line · badge to earn", "finish_btn": "🏁 I finished this lunch",
    "undo": "Undo — mark as not finished", "finish_answer": "After this episode you can tell Ibu Sari: <b>“{answer}”</b>",
    "validated": "Last validated: {v} · ", "read_lunch_gh": "Read this lunch on GitHub",
    "out_of_date": "Spotted something out of date?", "timer_now": "Now: Scenario", "timer_stop": "Stop the lunch timer",
    "ep_nav": "Episodes",
    "lunch_page_title": "Episode {n} · {ep} — Lunch {n}: {title}",
    "lunch_page_desc": "Lunch {n} · {title}. {hook} A 60-minute reading, animated demo, knowledge check and a hands-on Azure lab.",
    # lab page
    "task": "Task {n}", "mark_done": "Mark done", "cleanup_btn": "🧹 I ran cleanup.sh",
    "cleanup_xp": "Worth 25 XP — and it keeps your bill at zero.",
    "nav_prev_lab": "← Previous lab", "nav_all_labs": "← All labs", "lab_hub": "The lab hub", "nav_next_lab": "Next lab →",
    "nav_done": "Done? →", "open_lunchbox": "Open your lunchbox", "read_the_lunch": "Read the lunch",
    "lab_mode": "Lab mode", "mode_guided": "🧭 Guided", "mode_challenge": "🏁 Challenge",
    "kicker_finale": "Season finale · capstone challenge", "kicker_lab": "Hands-on lab · pairs with Episode {n}",
    "stub_lab": "Lab", "stub_finale": "Finale", "difficulty": "Difficulty {d}", "lab_complete": "🏆 Mark lab complete",
    "lab_rail": "Lab steps", "lab_progress": "Your progress", "lab_tasks": "0 of {k} tasks", "lab_files": "Lab files",
    "lab_folder": "Open the folder on GitHub ↗", "lab_finished_q": "Finished?",
    "lab_finished_p": "Run the verify script, clean up, then claim your XP.", "labs_nav": "Labs",
    "read_lab_gh": "Read this lab on GitHub", "report_lab": "Report a lab problem",
    "cleanup_banner": ('🧹 Lab resources may still be running. When you are done, run <code>bash cleanup.sh</code> — '
                       '<a href="#{id}">go to clean up</a>.'),
    "lab_page_title": "Lab {num} · {title}",
    "lab_page_desc": ("Hands-on Azure lab {num}: {title}. {time}, cost {cost}. Guided steps or a challenge brief, "
                      "with verify and cleanup scripts."),
    "pairs_episode": "Episode {n} · {ep}", "pairs_finale": "Season finale · requirements only",
    # labs hub
    "hub_how": "How the labs work", "hub_cost": "Cost bands", "hub_wrong": "When something goes wrong",
    "hub_cost_id": "cost-bands", "not_started": "○ Not started",
    "hub_kicker": "Hands-on labs · 32 tickets",
    "hub_h1": 'Labs you can do <span class="grad-text">on your own time.</span>',
    "hub_lead": ("Every lunch comes with a lab ticket. Each lab is independent — no earlier lab needed — and runs in "
                 "Azure Cloud Shell with the Azure CLI. Go <b>guided</b> with copy-paste steps, or flip to "
                 "<b>challenge</b> mode and build it from the brief."),
    "hub_stats": [("32", "independent labs"), ("2", "modes: guided or challenge"), ("✓", "verify script per lab"),
                  ("🧹", "one-command clean-up")],
    "f_cost": "Filter by cost", "all_costs": "All costs", "f_part": "Filter by part", "all_parts": "All parts",
    "search_labs": "Search labs…", "hub_title": "Hands-on labs",
    "hub_desc": "32 independent Azure CLI labs with guided and challenge modes, verify scripts and one-command clean-up.",
    # demos hub
    "demo_preview": "Preview of the demo for Lunch {n}", "demo_meta": "Episode {n} · {part} · {level}",
    "demo_steps": "{k} steps", "demos_kicker": "Demo gallery · 31 animations",
    "demos_h1": 'Watch Azure <span class="grad-text">move.</span>',
    "demos_lead": ("Each lunch has an animated, step-through demo: packets crossing a network security group, a scale "
                   "set growing for the 12.12 sale, a failover group switching regions. Press play, pause on any step, "
                   "or drive it with the arrow keys. Every demo is a single HTML file that also works offline."),
    "demos_title": "Demo gallery", "demos_desc": "31 animated, step-through Azure demos — one for every lunch.",
    "demo_footer_course": "Azure Fundamentals: One Lunch at a Time",
    # landing
    "home_kicker": "A story-driven Azure course · 31 episodes · free",
    "home_h1": 'Learn Azure <span class="accent">one lunch</span> at a time.',
    "home_lead": ("PT Nusantara Retail sells to customers of forty stores through one tired server in the room next "
                  "to the pantry. The director has asked a question nobody can answer. Over 31 lunch breaks you'll "
                  "move the shop into Azure — and learn every fundamental service on the way: VMs, storage, "
                  "networking, databases, load balancers, identity, governance and more."),
    "home_by": "A free course by {author}", "start_ep1": "▶ Start Episode 01", "see_journey": "🗺 See the journey",
    "home_stats": [("31", "lunch-sized episodes"), ("31", "animated demos"), ("32", "hands-on labs"),
                   ("60′", "per lunch, max")],
    "scene_label": "Illustration: the pantry server, a coffee machine and the Azure cloud",
    "server_sign": "Server room · do not unplug", "bubble_who": "{name} · {role}",
    "strip": [("🏪", "Meet Nusantara Retail", "A mid-sized Indonesian retailer: forty stores, a head office in Jakarta, "
               "and an online storefront that tripled its traffic this year."),
              ("🔥", "One server. One pantry.", "The whole shop runs on one physical server. The UPS beeps when the "
               "coffee machine starts. Backups go home on Fridays on a USB drive."),
              ("❓", "", "Ibu Sari asked at last month's meeting. Nobody answered. Every episode moves your answer "
               "forward — watch the meter.")],
    "how_kicker": "How a lunch works", "how_h2": "Sixty minutes. Six courses. Zero filler.",
    "how_lead": ("Inspired by the classic “month of lunches” format: every episode fits a lunch break. Hover the clock "
                 "to see what each slice holds."),
    "journey_kicker": "The journey", "journey_h2": "31 stations from the pantry to production.",
    "journey_lead": "{s1} Then Season 2: {s2} Hover a station for the episode hook; your position is saved as you go.",
    "finale_legend": "★ Finale", "metro_text": "0 / 31 lunches",
    "director_kicker": "The director's question", "director_h2": "Every episode earns you a better answer.",
    "director_asked": "Asked at last month's meeting", "director_when": "Your answer today, before Episode 01",
    "director_foot": "By the end of Season 1 you can answer in a meeting, with numbers. By the end of Season 2 you can answer in an audit.",
    "cast_kicker": "The cast", "cast_h2": "The same people, every lunch.",
    "cast_lead": "Real-world problems arrive as people with opinions. You'll learn to answer all of them.",
    "eps_kicker": "Episodes", "eps_h2": "Pick up where you left off.",
    "eps_lead": ("Season 1 is the core month (Basic). Season 2 is the deep-dive month (Advanced): topics that are too "
                 "big for one lunch get a second, advanced episode."),
    "f_eps": "Filter episodes", "f_all": "All", "f_s1": "Season 1 · Basic", "f_s2": "Season 2 · Advanced",
    "f_todo": "To do", "f_done": "Finished", "search_eps": "Search: VM, storage, KQL…", "search_eps_label": "Search episodes",
    "done_flag": "✓ Done", "ep_short": "EP {n}", "finale_tag": "★ Season finale", "badge_title": "Badge: {name}",
    "finale_time": "🔬 8–12 hours · 💲💲💲",
    "badges_kicker": "Trophy cabinet", "badges_count0": "0 of 40", "badges_h2": "Collect a badge every lunch.",
    "badges_lead": ("Finish an episode to earn its badge. Ace a quiz, clean up after your labs and keep a streak for "
                    "the specials. Everything counts toward your XP and your level, from <i>{first}</i> to <i>{last}</i>."),
    "open_lunchbox_btn": "🍱 Open my lunchbox",
    "labs_kicker": "Hands-on labs", "labs_h2": "Labs that respect your wallet and your calendar.",
    "labs_lead": "Every lab is independent, runs in Azure Cloud Shell and ends with a clean-up script. Do it the same day or next weekend.",
    "cost_cards": [("💲", "Free or nearly free", "Free tiers and tiny resources. Clean up anyway — it is a good habit."),
                   ("💲💲", "Small charges while running", "Finish in one sitting, then run <code>cleanup.sh</code>. Typically cents per hour."),
                   ("💲💲💲", "Plan it, then delete", "Gateways, firewalls and clusters. Read the brief first and delete straight after.")],
    "features": [("🧭", "Guided or challenge", "Copy-paste steps with checkpoints — or hide them and build from the brief."),
                 ("🧪", "Verify scripts", "Every lab ships <code>verify.sh</code>, so you know it really works."),
                 ("🔧", "Break it, fix it", "A deliberate fault in every lab teaches you to troubleshoot.")],
    "browse_labs": "Browse all 32 labs →",
    "faq_kicker": "FAQ", "faq_h2": "Before you grab your lunch",
    "faq": [
        ("Do I need an Azure subscription?", "Not for the readings, demos and quizzes. For the labs, yes — Episode 01 walks you through the options (a free account, a pay-as-you-go subscription or a sandbox your employer provides) and sets up a budget alert before you create anything."),
        ("How much will the labs cost?", "Every lab shows a cost band: 💲 is free or close to free, 💲💲 means small charges while resources run, 💲💲💲 means noticeable charges. Every lab ends with a one-command clean-up, and the lab page reminds you if you forget. Prices vary by region, so the labs never quote numbers — use the Azure pricing calculator."),
        ("Does this prepare me for AZ-900?", "Season 1 (Episodes 01–21) covers the AZ-900 skill areas; every episode shows which skill area it belongs to. Season 2 goes deliberately beyond AZ-900 into what you need on the job: hub-and-spoke networks, Kubernetes, KQL and governance at scale."),
        ("Is this official Microsoft training?", "No. It is an independent, personal learning project, not endorsed by Microsoft. Azure changes often, so every episode links to Microsoft Learn for the details — and every page shows when it was last validated."),
        ("Who wrote this course?", "Stefanus Pinarta, a Jakarta-based solutions engineer with more than twenty years in enterprise IT who has worked inside all three major cloud providers. See “About the author” below; for any further inquiries, email stefanus.pinarta@gmail.com."),
        ("Is there an Indonesian version?", "Yes. Every episode, lab, demo and badge is available in Bahasa Indonesia: use the language switch at the top of any page. Your progress is shared between both languages."),
        ("Where is my progress stored?", "Only in this browser (local storage). Nothing about you is sent anywhere. In My lunchbox you can export your progress to a file and import it on another device."),
        ("I only have 30 minutes today. Now what?", "Start the lunch timer, do the scenario and reading, and come back for the demo and quiz tomorrow. The timer and every checkbox remember where you were."),
    ],
    "cta_h2": "The server is still humming. Episode 01 starts now.",
    "cta_p": "Grab your lunch, open Cloud Shell, and make sure the next time someone asks “how long can't we sell?”, the answer comes from you.",
    "home_desc": ("Learn every fundamental Azure service in 31 lunch-sized episodes: story-driven readings, animated "
                  "demos, quizzes and independent hands-on labs. A free course by Stefanus Pinarta."),
    # author section
    "author_kicker": "About the author", "author_h2": "Written by someone who has built it for real.",
    "author_role": "Senior Solutions Engineer, Cloud and AI Infrastructure at Microsoft · Jakarta, Indonesia",
    "author_chips": ["20+ years in enterprise IT", "Worked inside all 3 major clouds", "18 cloud certifications",
                     "Former university lecturer"],
    "author_bio": [
        ("Stefanus has spent more than twenty years designing and running enterprise systems, and he has worked inside "
         "all three major cloud providers: today at Microsoft, before that as a Customer Solutions Consultant at Google "
         "Cloud and a Senior Solutions Architect at AWS. Before the cloud, he was Vice President of IT Architecture at "
         "HSBC Indonesia, accountable for the bank's enterprise architecture, and earlier an enterprise architect and IT "
         "division head at Maybank Indonesia, a banking technology consultant at Accenture and an analyst in Citibank's "
         "operations and technology group."),
        ("He holds 18 cloud certifications across AWS, Google Cloud, Alibaba Cloud and Microsoft, plus TOGAF 9, CCNA and "
         "PRINCE2, a Master of Engineering Science from UNSW Sydney (Australian Development Scholarship, High Distinction "
         "average) and a Bachelor of Engineering in Informatics from ITB (cum laude). As a lecturer at BINUS "
         "International he designed and taught university courses — and this course follows the same rule he used in "
         "the classroom: one clear idea at a time, then practice."),
    ],
    "author_inquiries": "For any further inquiries, email",
    "author_linkedin": "Connect on LinkedIn", "author_email_btn": "Email Stefanus",
    "author_note": "This is a personal project. The views and content are the author's own and do not represent his employer.",
    # lunchbox
    "lb_kicker": "My lunchbox", "lb_h1": 'Your progress, badges <span class="grad-text">and notes.</span>',
    "lb_lead": "Everything here lives only in this browser — nothing is sent anywhere. Export it to move to another device.",
    "lb_level": "Your level",
    "lb_kpis": [("data-k-lunches", "0/31", "lunches finished"), ("data-k-labs", "0/32", "labs complete"),
                ("data-k-quiz", "—", "quiz accuracy"), ("data-k-streak", "0 🔥", "day streak (weekends are free)")],
    "lb_seasons": "Seasons", "lb_director": "The director's question", "lb_trophy": "Trophy cabinet",
    "lb_notebook": "My notebook", "lb_copy_md": "📋 Copy as Markdown", "lb_download_md": "⬇ Download .md",
    "lb_cert": "Certificate", "cert_name_ph": "Your name for the certificate", "cert_print": "🖨 Print or save as PDF",
    "cert_share": "Share on LinkedIn", "cert_kick": "Azure Fundamentals · One Lunch at a Time",
    "cert_title": "Certificate of Progress", "cert_certifies": "This certifies that", "cert_name": "Your name here",
    "cert_body": "has started Azure Fundamentals: One Lunch at a Time.", "cert_date": "Date",
    "cert_director": "Director, PT Nusantara Retail (fictional)",
    "cert_author_label": "Course author",
    "cert_fine": "A just-for-fun progress certificate from a self-study course. It is not a Microsoft certification.",
    "lb_data": "Your data", "export": "⬇ Export progress", "import": "⬆ Import progress", "reset": "Reset everything",
    "lb_title": "My lunchbox", "lb_desc": "Your XP, level, badges, notebook and certificate for Azure Fundamentals: One Lunch at a Time.",
    # share pages
    "share_badge_title": "{icon} “{name}” badge · {course}",
    "share_badge_desc": "{desc} Earned in {course}, a free, story-driven Azure course by {author}: 31 lunch-sized episodes, animated demos and hands-on labs.",
    "share_cert_title": "Certificate of Progress · {course}",
    "share_cert_desc": "Learning Azure one lunch at a time with {course}, a free, story-driven course by {author}: 31 episodes, animated demos and hands-on labs.",
    "share_done_title": "Certificate of Completion · {course}",
    "share_done_desc": "Completed all 31 lunches of {course}, a free, story-driven Azure course by {author}.",
    "share_redirect": "Opening the course…", "share_open": "Open the course",
    # 404
    "nf_title": "Page not found", "nf_h1": "This page went down with the pantry server.",
    "nf_lead": "Nobody knows how long it will take to come back. (That is exactly the problem Episode 01 starts to fix.)",
    "nf_home": "🏠 Back to the course", "nf_labs": "🔬 All labs",
    # root chooser
    "choose_title": "Choose your language",
}

ID = {
    "html_lang": "id", "og_locale": "id_ID", "lang_name": "Bahasa Indonesia", "lang_short": "ID",
    "course": "Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran",
    "brand_main": "Satu Makan Siang", "brand_small": "Dasar-Dasar Azure",
    "skip": "Lewati ke konten",
    "nav_journey": "Perjalanan", "nav_episodes": "Episode", "nav_labs": "Lab", "nav_demos": "Demo",
    "nav_lunchbox": "Kotak bekal", "nav_main": "Utama",
    "hud_title": "Progres Anda", "theme_toggle": "Beralih antara mode terang dan gelap", "menu_open": "Buka menu",
    "switch_to": "Read in English",
    "footer_blurb": ("Tiga puluh satu episode seukuran makan siang, demo animasi, dan lab praktik yang membawa satu "
                     "peritel fiktif Indonesia dari server di samping pantry ke platform Azure yang tertata dan tangguh."),
    "f_learn": "Belajar", "f_all_episodes": "Semua episode", "f_labs": "Lab praktik", "f_demos": "Galeri demo",
    "f_lunchbox": "Kotak bekal saya", "f_repo": "Repositori", "f_source": "Kode sumber di GitHub", "f_syllabus": "Silabus",
    "f_syllabus_file": "SYLLABUS.id.md", "f_design": "Desain kursus (bahasa Inggris)", "f_report": "Laporkan masalah",
    "f_author": "Penulis", "f_about_author": "Tentang penulis", "f_email": "Email",
    "fine": ("Proyek belajar pribadi yang independen — bukan pelatihan, dokumentasi, atau materi sertifikasi resmi "
             "Microsoft, dan tidak didukung oleh Microsoft. Azure sering berubah: selalu periksa "
             '<a href="https://learn.microsoft.com/azure/" target="_blank" rel="noopener">dokumentasi Azure</a> '
             "dan harga terbaru sebelum mengandalkan suatu detail. Microsoft, Azure, dan nama terkait adalah merek "
             "dagang grup perusahaan Microsoft. Nusantara Retail dan para tokohnya adalah fiktif. Teks dan demo: {cc} · kode: {mit}."),
    "privacy": ("Progres, lencana, dan catatan hanya disimpan di browser Anda. Kunjungan halaman dihitung secara anonim "
                "dengan GoatCounter: tanpa cookie dan tanpa data pribadi."),
    "privacy_nocount": "Progres, lencana, dan catatan hanya disimpan di browser Anda.",
    "visits_label": "pengunjung sejauh ini",
    "callout_note": "Catatan", "callout_tip": "Tips", "callout_important": "Penting", "callout_warning": "Peringatan",
    "callout_caution": "Hati-hati", "callout_think": "Renungkan sejenak", "copy": "Salin",
    "zoom": "⤢ Perbesar", "zoom_label": "Perbesar diagram", "anchor_label": "Tautan ke bagian ini",
    "level_basic": "Dasar", "level_advanced": "Lanjutan", "capstone": "Capstone",
    "cost_1": "gratis atau hampir gratis", "cost_2": "biaya kecil selama berjalan", "cost_3": "biaya yang terasa selama berjalan",
    "pantry": "Server pantry", "pantry_moods": ["berkeringat", "cemas", "lebih tenang", "senang", "santai"],
    "pantry_mood": "Server pantry, {mood}", "pantry_progress": "Server pantry — makin ceria seiring progres Anda",
    "pantry_overheat": "Server pantry, kepanasan", "pantry_still": "Server pantry, masih berkeringat",
    "gauge_label": "Kesiapan menjawab pertanyaan direktur", "gauge_low": "Berhari-hari?", "gauge_high": "Terjawab",
    "clock_label": ("Makan siang 60 menit: 5 menit skenario, 25 bacaan, 15 demo, 5 uji pemahaman, 5 poin penting, "
                    "5 waktu cadangan"),
    "clock_min": "mnt", "clock_center": "60 mnt", "clock_sub": "satu makan siang",
    "segments": [
        ("Skenario & tujuan", "Kenali masalah hari ini di Nusantara Retail dan lima hal yang akan Anda kuasai di akhir sesi."),
        ("Bacaan", "Enam adegan singkat dengan diagram, tabel, tips, dan momen renungan. Tanpa tembok teks."),
        ("Demo animasi", "Lihat idenya bergerak: paket data, izin akses, dan failover yang bisa Anda putar, jeda, dan telusuri langkah demi langkah."),
        ("Uji pemahaman", "Lima pertanyaan skenario. Jawab dalam hati, buka jawabannya, nilai diri Anda dengan jujur, dan kumpulkan XP."),
        ("Poin penting & tiket lab", "Sematkan poin kunci ke catatan Anda dan ambil tiket lab praktik hari ini."),
        ("Waktu cadangan", "Habiskan makan siang Anda. Sungguh. Lab menunggu kapan pun Anda sempat."),
    ],
    "prev_first": ("Belum ada apa-apa. Ini hari Senin pertama Anda di PT Nusantara Retail, dan ada sesuatu yang berdengung "
                   "keras di samping pantry."),
    "prev_label": "Sebelumnya di Nusantara Retail", "prev_recap": "Rekap Season 1",
    "previously": "Di Episode {n} · {ep}, {outcome}",
    "chip_s1_finale": "🏆 Final Season 1", "chip_s2_premiere": "🌊 Pembuka Season 2", "chip_last": "🎬 Episode terakhir",
    "ep_pill": "Episode {n}", "ep_meta": "Season {s} · {icon} Bagian {p} · {part}", "lunch_label": "Makan Siang {n} · {title}",
    "chip_60": "⏱ Makan siang 60 menit", "chip_az900": "AZ-900 · {area}", "beyond_prefix": "Di luar",
    "chip_lab": "🔬 Lab · {time} · {cost}", "chip_builds_on": "Melanjutkan", "chip_no_prereq": "Tanpa prasyarat",
    "cta_start": "🍱 Mulai makan siang 60 menit", "cta_demo": "🎬 Langsung ke demo", "cta_finish": "✓ Tandai selesai",
    "byline": "Ditulis oleh", "byline_role": "Senior Solutions Engineer · 20+ tahun di TI enterprise",
    "meter": "Pertanyaan direktur · {pct}% siap", "meter_say": "Setelah episode ini Anda bisa menjawab: “{answer}”",
    "scene_of": "Adegan {i} dari {n}", "obj_lead": "Setelah makan siang ini, Anda akan mampu:",
    "obj_btn": "Saya sudah bisa melakukan ini",
    "obj_hint": "Centang sebuah tujuan jika Anda benar-benar sudah bisa melakukannya. Masing-masing bernilai 5 XP.",
    "demo_default": "Demo interaktif",
    "reveal": "Lihat jawaban", "got_it_q": "Jawaban Anda benar?", "got_it": "👍 Saya benar", "not_quite": "👎 Belum tepat",
    "pin": "📌 Sematkan ke catatan", "this_course": "kursus ini",
    "next_ep": "Episode berikutnya · {n}", "watch_ep": "Tonton Episode {n} →", "season_finale": "Final musim",
    "take_capstone": "Ikuti tantangan capstone →",
    "nav_prev_ep": "← Episode sebelumnya", "nav_home": "← Beranda kursus", "nav_journey_map": "Peta perjalanan",
    "nav_next_ep": "Episode berikutnya →", "nav_finale": "Final musim →", "capstone_title": "Tantangan capstone lanjutan",
    "rail_label": "Jam makan siang", "rail_menu": "Menu hari ini", "rail_story": "Sementara itu…", "rail_reading": "Bacaan",
    "rail_demo": "Demo", "rail_quiz": "Uji pemahaman", "rail_take": "Poin penting", "rail_notes": "Catatan lapangan",
    "rail_lab": "Lab Anda", "rail_finish": "Selesai", "rail_timer": "🍱 Mulai timer makan siang", "rail_open_lab": "🔬 Buka Lab {n}",
    "mob_label": "Bagian makan siang ini", "mob_menu": "🍱 Menu", "mob_story": "🏪 Cerita", "mob_reading": "📖 Bacaan",
    "mob_demo": "🎬 Demo", "mob_quiz": "✅ Kuis", "mob_take": "🧠 Poin", "mob_notes": "🗒️ Catatan", "mob_lab": "🔬 Lab",
    "mob_finish": "🏁 Selesai",
    "h_menu": "Menu hari ini", "min_menu": "Menit 0–5", "story_tag": "🏪 Sementara itu di Nusantara Retail · Episode {n}",
    "h_reading": "Bacaan", "min_reading": "Menit 5–30 · {k} adegan", "h_demo": "Demo", "min_demo": "Menit 30–45",
    "theatre_live": "Demo interaktif · {title}", "open_tab": "↗ Buka di tab baru", "theatre": "⤢ Mode teater",
    "iframe_title": "Demo interaktif: {title}",
    "watch_hint": "Tekan <b>▶ Putar</b>, atau telusuri dengan tombol panah. Tonton sampai langkah terakhir untuk mendapat 30 XP.",
    "video_script": 'Lebih suka video? Baca <a href="{href}" target="_blank" rel="noopener">naskah video panduan</a>.',
    "h_quiz": "Uji pemahaman", "min_quiz": "Menit 45–50", "quiz_head": "{k} pertanyaan skenario. Nilai diri dengan jujur.",
    "quiz_note": "Jawab dalam hati, buka jawabannya, lalu jujurlah pada diri sendiri.",
    "h_take": "Poin penting", "min_take": "Menit 50–55",
    "h_notes": "Catatan lapangan dari Stefanus", "notes_sub": "Senior Solutions Engineer · 20+ tahun di TI enterprise",
    "notes_more": "Tentang penulis", "h_lab": "Lab Anda", "min_lab": "Kapan saja · sesuai ritme Anda",
    "admit": "Tiket masuk", "works_alone": "✅ Bisa dikerjakan terpisah", "modes": "🧭 Mode terpandu atau tantangan",
    "start_lab": "Mulai Lab {n} →", "h_further": "Pelajari lebih lanjut",
    "finish_kicker": "Garis finis · lencana yang menanti", "finish_btn": "🏁 Saya sudah menyelesaikan makan siang ini",
    "undo": "Batalkan — tandai belum selesai",
    "finish_answer": "Setelah episode ini Anda bisa berkata kepada Ibu Sari: <b>“{answer}”</b>",
    "validated": "Terakhir divalidasi: {v} · ", "read_lunch_gh": "Baca makan siang ini di GitHub",
    "out_of_date": "Menemukan informasi yang usang?", "timer_now": "Sekarang: Skenario", "timer_stop": "Hentikan timer makan siang",
    "ep_nav": "Episode",
    "lunch_page_title": "Episode {n} · {ep} — Makan Siang {n}: {title}",
    "lunch_page_desc": "Makan Siang {n} · {title}. {hook} Bacaan 60 menit, demo animasi, uji pemahaman, dan lab Azure praktik.",
    "task": "Tugas {n}", "mark_done": "Tandai selesai", "cleanup_btn": "🧹 Saya sudah menjalankan cleanup.sh",
    "cleanup_xp": "Bernilai 25 XP — dan menjaga tagihan Anda tetap nol.",
    "nav_prev_lab": "← Lab sebelumnya", "nav_all_labs": "← Semua lab", "lab_hub": "Pusat lab", "nav_next_lab": "Lab berikutnya →",
    "nav_done": "Sudah selesai? →", "open_lunchbox": "Buka kotak bekal Anda", "read_the_lunch": "Baca makan siangnya",
    "lab_mode": "Mode lab", "mode_guided": "🧭 Terpandu", "mode_challenge": "🏁 Tantangan",
    "kicker_finale": "Final musim · tantangan capstone", "kicker_lab": "Lab praktik · pasangan Episode {n}",
    "stub_lab": "Lab", "stub_finale": "Final", "difficulty": "Tingkat kesulitan {d}", "lab_complete": "🏆 Tandai lab selesai",
    "lab_rail": "Langkah lab", "lab_progress": "Progres Anda", "lab_tasks": "0 dari {k} tugas", "lab_files": "Berkas lab",
    "lab_folder": "Buka foldernya di GitHub ↗", "lab_finished_q": "Sudah selesai?",
    "lab_finished_p": "Jalankan skrip verifikasi, bersihkan resource, lalu klaim XP Anda.", "labs_nav": "Lab",
    "read_lab_gh": "Baca lab ini di GitHub", "report_lab": "Laporkan masalah lab",
    "cleanup_banner": ('🧹 Resource lab mungkin masih berjalan. Setelah selesai, jalankan <code>bash cleanup.sh</code> — '
                       '<a href="#{id}">ke bagian pembersihan</a>.'),
    "lab_page_title": "Lab {num} · {title}",
    "lab_page_desc": ("Lab Azure praktik {num}: {title}. {time}, biaya {cost}. Langkah terpandu atau ringkasan tantangan, "
                      "lengkap dengan skrip verifikasi dan pembersihan."),
    "pairs_episode": "Episode {n} · {ep}", "pairs_finale": "Final musim · hanya persyaratan",
    "hub_how": "Cara kerja lab", "hub_cost": "Kelompok biaya", "hub_wrong": "Jika terjadi masalah",
    "hub_cost_id": "kelompok-biaya", "not_started": "○ Belum dimulai",
    "hub_kicker": "Lab praktik · 32 tiket",
    "hub_h1": 'Lab yang bisa Anda kerjakan <span class="grad-text">kapan saja.</span>',
    "hub_lead": ("Setiap makan siang dilengkapi tiket lab. Setiap lab berdiri sendiri — tidak perlu lab sebelumnya — dan "
                 "berjalan di Azure Cloud Shell dengan Azure CLI. Pilih mode <b>terpandu</b> dengan langkah salin-tempel, "
                 "atau mode <b>tantangan</b> dan bangun sendiri dari ringkasannya."),
    "hub_stats": [("32", "lab mandiri"), ("2", "mode: terpandu atau tantangan"), ("✓", "skrip verifikasi di tiap lab"),
                  ("🧹", "bersih-bersih dengan satu perintah")],
    "f_cost": "Saring menurut biaya", "all_costs": "Semua biaya", "f_part": "Saring menurut bagian", "all_parts": "Semua bagian",
    "search_labs": "Cari lab…", "hub_title": "Lab praktik",
    "hub_desc": "32 lab Azure CLI mandiri dengan mode terpandu dan tantangan, skrip verifikasi, dan pembersihan satu perintah.",
    "demo_preview": "Pratinjau demo Makan Siang {n}", "demo_meta": "Episode {n} · {part} · {level}",
    "demo_steps": "{k} langkah", "demos_kicker": "Galeri demo · 31 animasi",
    "demos_h1": 'Saksikan Azure <span class="grad-text">bergerak.</span>',
    "demos_lead": ("Setiap makan siang punya demo animasi yang bisa ditelusuri langkah demi langkah: paket data melintasi "
                   "network security group, scale set yang membesar menjelang promo 12.12, failover group yang berpindah "
                   "region. Tekan putar, jeda di langkah mana pun, atau kendalikan dengan tombol panah. Setiap demo adalah "
                   "satu berkas HTML yang juga berjalan offline."),
    "demos_title": "Galeri demo", "demos_desc": "31 demo Azure animasi yang bisa ditelusuri langkah demi langkah — satu untuk setiap makan siang.",
    "demo_footer_course": "Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran",
    "home_kicker": "Kursus Azure berbasis cerita · 31 episode · gratis",
    "home_h1": 'Belajar Azure, <span class="accent">satu makan siang</span> demi satu.',
    "home_lead": ("PT Nusantara Retail melayani pelanggan empat puluh toko lewat satu server yang kelelahan di ruangan "
                  "sebelah pantry. Sang direktur mengajukan pertanyaan yang tak bisa dijawab siapa pun. Dalam 31 jam "
                  "makan siang, Anda akan memindahkan toko itu ke Azure — sambil mempelajari setiap layanan dasarnya: "
                  "VM, penyimpanan, jaringan, database, load balancer, identitas, tata kelola, dan banyak lagi."),
    "home_by": "Kursus gratis oleh {author}", "start_ep1": "▶ Mulai Episode 01", "see_journey": "🗺 Lihat perjalanannya",
    "home_stats": [("31", "episode seukuran makan siang"), ("31", "demo animasi"), ("32", "lab praktik"),
                   ("60′", "maksimal per makan siang")],
    "scene_label": "Ilustrasi: server pantry, mesin kopi, dan cloud Azure",
    "server_sign": "Ruang server · jangan dicabut", "bubble_who": "{name} · {role}",
    "strip": [("🏪", "Kenalan dengan Nusantara Retail", "Peritel Indonesia skala menengah: empat puluh toko, kantor pusat "
               "di Jakarta, dan toko online yang trafiknya naik tiga kali lipat tahun ini."),
              ("🔥", "Satu server. Satu pantry.", "Seluruh toko berjalan di satu server fisik. UPS berbunyi setiap kali "
               "mesin kopi dinyalakan. Cadangan data dibawa pulang setiap Jumat di flashdisk."),
              ("❓", "", "Ibu Sari menanyakannya di rapat bulan lalu. Tak ada yang menjawab. Setiap episode memajukan "
               "jawaban Anda — perhatikan meterannya.")],
    "how_kicker": "Cara kerja satu makan siang", "how_h2": "Enam puluh menit. Enam hidangan. Tanpa basa-basi.",
    "how_lead": ("Terinspirasi format klasik “month of lunches”: setiap episode muat dalam satu jam makan siang. Arahkan "
                 "kursor ke jam untuk melihat isi setiap potongannya."),
    "journey_kicker": "Perjalanannya", "journey_h2": "31 stasiun dari pantry menuju produksi.",
    "journey_lead": "{s1} Lalu Season 2: {s2} Arahkan kursor ke sebuah stasiun untuk melihat cuplikan episodenya; posisi Anda tersimpan otomatis.",
    "finale_legend": "★ Final", "metro_text": "0 / 31 makan siang",
    "director_kicker": "Pertanyaan sang direktur", "director_h2": "Setiap episode memberi Anda jawaban yang lebih baik.",
    "director_asked": "Ditanyakan di rapat bulan lalu", "director_when": "Jawaban Anda hari ini, sebelum Episode 01",
    "director_foot": "Di akhir Season 1, Anda bisa menjawabnya di rapat, lengkap dengan angka. Di akhir Season 2, Anda bisa menjawabnya di depan auditor.",
    "cast_kicker": "Para tokoh", "cast_h2": "Orang-orang yang sama, di setiap makan siang.",
    "cast_lead": "Masalah dunia nyata datang dalam wujud orang-orang dengan pendapatnya masing-masing. Anda akan belajar menjawab semuanya.",
    "eps_kicker": "Episode", "eps_h2": "Lanjutkan dari tempat Anda berhenti.",
    "eps_lead": ("Season 1 adalah bulan inti (Dasar). Season 2 adalah bulan pendalaman (Lanjutan): topik yang terlalu "
                 "besar untuk satu makan siang mendapat episode kedua tingkat lanjutan."),
    "f_eps": "Saring episode", "f_all": "Semua", "f_s1": "Season 1 · Dasar", "f_s2": "Season 2 · Lanjutan",
    "f_todo": "Belum", "f_done": "Selesai", "search_eps": "Cari: VM, storage, KQL…", "search_eps_label": "Cari episode",
    "done_flag": "✓ Selesai", "ep_short": "EP {n}", "finale_tag": "★ Final musim", "badge_title": "Lencana: {name}",
    "finale_time": "🔬 8–12 jam · 💲💲💲",
    "badges_kicker": "Lemari trofi", "badges_count0": "0 dari 40", "badges_h2": "Kumpulkan satu lencana setiap makan siang.",
    "badges_lead": ("Selesaikan sebuah episode untuk mendapatkan lencananya. Raih nilai sempurna di kuis, bersihkan "
                    "resource setelah lab, dan jaga streak untuk lencana spesial. Semuanya menambah XP dan level Anda, "
                    "dari <i>{first}</i> sampai <i>{last}</i>."),
    "open_lunchbox_btn": "🍱 Buka kotak bekal saya",
    "labs_kicker": "Lab praktik", "labs_h2": "Lab yang menghargai dompet dan jadwal Anda.",
    "labs_lead": "Setiap lab berdiri sendiri, berjalan di Azure Cloud Shell, dan diakhiri skrip pembersihan. Kerjakan hari itu juga atau akhir pekan depan.",
    "cost_cards": [("💲", "Gratis atau hampir gratis", "Tier gratis dan resource mungil. Tetap bersihkan — itu kebiasaan yang baik."),
                   ("💲💲", "Biaya kecil selama berjalan", "Selesaikan dalam sekali duduk, lalu jalankan <code>cleanup.sh</code>. Biasanya hanya beberapa sen per jam."),
                   ("💲💲💲", "Rencanakan, lalu hapus", "Gateway, firewall, dan cluster. Baca ringkasannya dulu dan langsung hapus setelah selesai.")],
    "features": [("🧭", "Terpandu atau tantangan", "Langkah salin-tempel dengan titik pemeriksaan — atau sembunyikan dan bangun sendiri dari ringkasannya."),
                 ("🧪", "Skrip verifikasi", "Setiap lab menyertakan <code>verify.sh</code>, jadi Anda tahu hasilnya benar-benar berfungsi."),
                 ("🔧", "Rusak lalu perbaiki", "Satu gangguan yang disengaja di setiap lab melatih Anda memecahkan masalah.")],
    "browse_labs": "Jelajahi ke-32 lab →",
    "faq_kicker": "Tanya jawab", "faq_h2": "Sebelum Anda mengambil makan siang",
    "faq": [
        ("Apakah saya perlu langganan Azure?", "Tidak untuk bacaan, demo, dan kuis. Untuk lab, ya — Episode 01 memandu Anda memilih opsinya (akun gratis, langganan pay-as-you-go, atau sandbox dari kantor Anda) dan memasang peringatan anggaran sebelum Anda membuat apa pun."),
        ("Berapa biaya lab-nya?", "Setiap lab menampilkan kelompok biaya: 💲 berarti gratis atau hampir gratis, 💲💲 berarti biaya kecil selama resource berjalan, 💲💲💲 berarti biaya yang terasa. Setiap lab diakhiri pembersihan dengan satu perintah, dan halaman lab akan mengingatkan Anda jika lupa. Harga berbeda per region, jadi lab tidak pernah menyebut angka — gunakan kalkulator harga Azure."),
        ("Apakah kursus ini menyiapkan saya untuk AZ-900?", "Season 1 (Episode 01–21) mencakup semua area keterampilan AZ-900; setiap episode menunjukkan area keterampilannya. Ujian AZ-900 juga tersedia dalam bahasa Indonesia. Season 2 sengaja melampaui AZ-900 menuju hal yang Anda butuhkan di pekerjaan: jaringan hub-and-spoke, Kubernetes, KQL, dan tata kelola berskala besar."),
        ("Apakah ini pelatihan resmi Microsoft?", "Bukan. Ini proyek belajar pribadi yang independen dan tidak didukung oleh Microsoft. Azure sering berubah, jadi setiap episode menautkan ke Microsoft Learn untuk detailnya — dan setiap halaman menunjukkan kapan terakhir divalidasi."),
        ("Siapa penulis kursus ini?", "Stefanus Pinarta, solutions engineer yang berbasis di Jakarta dengan lebih dari dua puluh tahun pengalaman di TI enterprise dan pernah bekerja di dalam ketiga penyedia cloud terbesar. Lihat “Tentang penulis” di bawah; untuk pertanyaan lebih lanjut, kirim email ke stefanus.pinarta@gmail.com."),
        ("Apakah ada versi bahasa Inggris?", "Ada. Setiap episode, lab, demo, dan lencana tersedia dalam bahasa Inggris dan bahasa Indonesia: gunakan tombol bahasa di bagian atas setiap halaman. Progres Anda tersimpan untuk kedua bahasa."),
        ("Di mana progres saya disimpan?", "Hanya di browser ini (local storage). Tidak ada data tentang Anda yang dikirim ke mana pun. Di Kotak bekal, Anda bisa mengekspor progres ke sebuah berkas dan mengimpornya di perangkat lain."),
        ("Hari ini saya hanya punya 30 menit. Lalu bagaimana?", "Mulai timer makan siang, kerjakan skenario dan bacaannya, lalu kembali besok untuk demo dan kuisnya. Timer dan setiap kotak centang mengingat posisi Anda."),
    ],
    "cta_h2": "Servernya masih berdengung. Episode 01 dimulai sekarang.",
    "cta_p": "Ambil makan siang Anda, buka Cloud Shell, dan pastikan saat ada yang bertanya lagi “berapa lama kita tidak bisa jualan?”, jawabannya datang dari Anda.",
    "home_desc": ("Pelajari setiap layanan dasar Azure dalam 31 episode seukuran makan siang: bacaan berbasis cerita, demo "
                  "animasi, kuis, dan lab praktik mandiri. Kursus gratis oleh Stefanus Pinarta."),
    "author_kicker": "Tentang penulis", "author_h2": "Ditulis oleh orang yang benar-benar pernah membangunnya.",
    "author_role": "Senior Solutions Engineer, Cloud and AI Infrastructure di Microsoft · Jakarta, Indonesia",
    "author_chips": ["20+ tahun di TI enterprise", "Pernah bekerja di 3 penyedia cloud terbesar", "18 sertifikasi cloud",
                     "Mantan dosen universitas"],
    "author_bio": [
        ("Stefanus telah lebih dari dua puluh tahun merancang dan menjalankan sistem enterprise, dan ia pernah bekerja "
         "langsung di dalam ketiga penyedia cloud terbesar: kini di Microsoft, sebelumnya sebagai Customer Solutions "
         "Consultant di Google Cloud dan Senior Solutions Architect di AWS. Sebelum era cloud, ia menjabat Vice President "
         "IT Architecture di HSBC Indonesia dan bertanggung jawab atas arsitektur enterprise bank tersebut; sebelumnya ia "
         "menjadi enterprise architect sekaligus kepala divisi TI di Maybank Indonesia, konsultan teknologi perbankan di "
         "Accenture, serta analis di grup operasional dan teknologi Citibank."),
        ("Ia memegang 18 sertifikasi cloud dari AWS, Google Cloud, Alibaba Cloud, dan Microsoft, ditambah TOGAF 9, CCNA, "
         "dan PRINCE2; meraih Master of Engineering Science dari UNSW Sydney (beasiswa Australian Development "
         "Scholarship, rata-rata High Distinction) dan Sarjana Teknik Informatika dari ITB (cum laude). Sebagai dosen di "
         "BINUS International, ia merancang dan mengajar mata kuliah universitas — dan kursus ini mengikuti prinsip yang "
         "sama yang ia pakai di kelas: satu ide yang jelas dalam satu waktu, lalu langsung praktik."),
    ],
    "author_inquiries": "Untuk pertanyaan lebih lanjut, silakan kirim email ke",
    "author_linkedin": "Terhubung di LinkedIn", "author_email_btn": "Kirim email",
    "author_note": "Ini adalah proyek pribadi. Pandangan dan isi kursus ini sepenuhnya milik penulis dan tidak mewakili pemberi kerjanya.",
    "lb_kicker": "Kotak bekal saya", "lb_h1": 'Progres, lencana, <span class="grad-text">dan catatan Anda.</span>',
    "lb_lead": "Semua yang ada di sini hanya tersimpan di browser ini — tidak dikirim ke mana pun. Ekspor untuk memindahkannya ke perangkat lain.",
    "lb_level": "Level Anda",
    "lb_kpis": [("data-k-lunches", "0/31", "makan siang selesai"), ("data-k-labs", "0/32", "lab tuntas"),
                ("data-k-quiz", "—", "akurasi kuis"), ("data-k-streak", "0 🔥", "hari berturut-turut (akhir pekan tidak dihitung)")],
    "lb_seasons": "Season", "lb_director": "Pertanyaan sang direktur", "lb_trophy": "Lemari trofi",
    "lb_notebook": "Catatan saya", "lb_copy_md": "📋 Salin sebagai Markdown", "lb_download_md": "⬇ Unduh .md",
    "lb_cert": "Sertifikat", "cert_name_ph": "Nama Anda untuk sertifikat", "cert_print": "🖨 Cetak atau simpan sebagai PDF",
    "cert_share": "Bagikan di LinkedIn", "cert_kick": "Dasar-Dasar Azure · Satu Makan Siang, Satu Pelajaran",
    "cert_title": "Sertifikat Progres", "cert_certifies": "Dengan ini menyatakan bahwa", "cert_name": "Nama Anda di sini",
    "cert_body": "telah memulai Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran.", "cert_date": "Tanggal",
    "cert_director": "Direktur, PT Nusantara Retail (fiktif)",
    "cert_author_label": "Penulis kursus",
    "cert_fine": "Sertifikat progres untuk bersenang-senang dari kursus belajar mandiri. Ini bukan sertifikasi Microsoft.",
    "lb_data": "Data Anda", "export": "⬇ Ekspor progres", "import": "⬆ Impor progres", "reset": "Atur ulang semuanya",
    "lb_title": "Kotak bekal saya", "lb_desc": "XP, level, lencana, catatan, dan sertifikat Anda untuk Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran.",
    "share_badge_title": "{icon} Lencana “{name}” · {course}",
    "share_badge_desc": "{desc} Diraih di {course}, kursus Azure gratis berbasis cerita oleh {author}: 31 episode seukuran makan siang, demo animasi, dan lab praktik.",
    "share_cert_title": "Sertifikat Progres · {course}",
    "share_cert_desc": "Belajar Azure satu makan siang demi satu bersama {course}, kursus gratis berbasis cerita oleh {author}: 31 episode, demo animasi, dan lab praktik.",
    "share_done_title": "Sertifikat Kelulusan · {course}",
    "share_done_desc": "Menuntaskan ke-31 makan siang {course}, kursus Azure gratis berbasis cerita oleh {author}.",
    "share_redirect": "Membuka kursus…", "share_open": "Buka kursus",
    "nf_title": "Halaman tidak ditemukan", "nf_h1": "Halaman ini ikut tumbang bersama server pantry.",
    "nf_lead": "Tak ada yang tahu berapa lama sampai halaman ini kembali. (Itulah persis masalah yang mulai diperbaiki Episode 01.)",
    "nf_home": "🏠 Kembali ke kursus", "nf_labs": "🔬 Semua lab",
    "choose_title": "Pilih bahasa Anda",
}

# --------------------------------------------------------------------------- browser (site.js)
JS = {
    "en": {
        "hud": "{xp} XP · {level}", "hudTitle": "{done} of {total} lunches · {xp} XP · {level}",
        "mermaidFail": "Diagram source (the diagram renderer could not be loaded).", "close": "Close",
        "you": "You", "afterEp": "after Episode {n}", "dayOne": "on day one",
        "continueEp": "▶ Continue: Episode {n}", "finaleGo": "🌟 Take the season finale",
        "min": "{m} min", "clockCenter": "60 min", "clockSub": "one lunch",
        "answerAfter": "Your answer after Episode {n} · {ep}", "answerToday": "Your answer today, before Episode 01",
        "episodeN": "Episode {n}", "finished": "✓ Finished", "upNext": "● Up next", "notStarted": "○ Not started",
        "capstone": "Advanced capstone challenge", "journeyAria": "Journey map: {done} of {total} lunches finished",
        "stationAria": "Episode {n}: {ep}", "finishedSuffix": " (finished)", "here": "YOU ARE HERE",
        "metroText": "{done} / {total} lunches", "earnedOn": "Earned {date}", "earned": "Earned", "locked": "Locked",
        "ofTotal": "{got} of {total}", "canDo": "You can do this now", "thought": "✓ Thought about it",
        "think": "💭 I have thought about it", "goodThinking": "Good thinking",
        "quizNote": "Answer in your head, reveal, then be honest with yourself.",
        "quizPerfect": "Perfect score! 🎯 You are ready for the lab.",
        "quizSolid": "Solid. Re-read the scenes behind the ones you missed.",
        "quizAgain": "Worth a second look — the takeaways below will help.",
        "hide": "Hide answer", "reveal": "Reveal answer", "correct": "Correct answer", "perfect": "🎯 Perfect score!",
        "pinned": "📌 Pinned", "pin": "📌 Pin to notebook", "savedNote": "Saved to your notebook",
        "exitTheatre": "✕ Exit theatre", "theatre": "⤢ Theatre mode", "demoDone": "Demo watched to the end 🎬",
        "lunchDone": "✓ Lunch finished", "nextEp": "Next episode · {n}", "watchEp": "Watch Episode {n} →",
        "seasonFinale": "Season finale", "takeChallenge": "Take the challenge →", "badgeUnlocked": "Badge unlocked",
        "tellSari": "Now you could tell Ibu Sari: “{answer}”", "notFinished": "Marked as not finished",
        "segs": ["Scenario", "Reading", "Demo", "Knowledge check", "Takeaways & lab", "Buffer — finish your lunch"],
        "lunchOver": "Lunch is over 🍵", "now": "Now: {seg}", "timeFor": "⏱ Time for {seg}", "jump": "jump there",
        "lunchStarted": "🍱 Lunch started. Enjoy — 60 minutes on the clock.",
        "labDoneClean": "✓ Done · cleaned up", "labDone": "✓ Done", "inProgress": "◐ In progress · {n} task(s) done",
        "taskDone": "✓ Done", "markDone": "Mark done", "tasksOf": "{done} of {total} tasks", "taskComplete": "Task complete",
        "cleaned": "✓ Cleaned up — nothing left running", "cleanup": "🧹 I ran cleanup.sh", "cleanPlate": "Clean plate",
        "labComplete": "✓ Lab complete", "labCompleteK": "Lab complete", "handsOn": "Hands-on win",
        "cleanedNote": "And you cleaned up. Ibu Sari approves. 🧹",
        "cleanupNote": "<b>One last thing:</b> run <code>bash cleanup.sh</code> so nothing keeps costing money.",
        "xpTo": "{n} XP to “{name}”", "topLevel": "Top level reached. Legendary.",
        "nbEmpty": "Your notebook is empty. Pin key takeaways at the end of any lunch and they will appear here.",
        "removeNote": "Remove note", "nbTitle": "My Azure lunch notebook", "copiedMd": "Copied as Markdown ✓",
        "copied": "Copied ✓", "copy": "Copy", "certName": "Your name here", "certDone": "Certificate of Completion",
        "certProgress": "Certificate of Progress",
        "certBodyDone": "has completed all {total} lunches of Azure Fundamentals: One Lunch at a Time — from the pantry server to governance at scale.",
        "certBodyProgress": "has completed {done} of {total} lunches of Azure Fundamentals: One Lunch at a Time, and earned {xp} XP as a {level}.",
        "badFile": "That file does not look like a progress export.",
        "resetConfirm": "Reset all progress, badges and notes in this browser?",
        "share": "Share on LinkedIn", "shareCopied": "Post text copied — paste it into LinkedIn.",
        "shareBadge": "I just earned the “{name}” badge {icon} in “Azure Fundamentals: One Lunch at a Time”, a free, story-driven Azure course by Stefanus Pinarta. One lunch break at a time! ☁️🍱\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #LearningInPublic",
        "shareCert": "I'm learning Azure one lunch at a time: {done} of 31 lunches done in “Azure Fundamentals: One Lunch at a Time”, a free, story-driven course by Stefanus Pinarta. ☁️🍱\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #LearningInPublic",
        "shareCertDone": "I completed all 31 lunches of “Azure Fundamentals: One Lunch at a Time”, a free, story-driven Azure course by Stefanus Pinarta — from a server next to the pantry to governance at scale. ☁️🍱🎓\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #LearningInPublic",
        "visits": "{n} visitors so far",
    },
    "id": {
        "hud": "{xp} XP · {level}", "hudTitle": "{done} dari {total} makan siang · {xp} XP · {level}",
        "mermaidFail": "Sumber diagram (penggambar diagram tidak dapat dimuat).", "close": "Tutup",
        "you": "Anda", "afterEp": "setelah Episode {n}", "dayOne": "di hari pertama",
        "continueEp": "▶ Lanjutkan: Episode {n}", "finaleGo": "🌟 Ikuti final musim",
        "min": "{m} mnt", "clockCenter": "60 mnt", "clockSub": "satu makan siang",
        "answerAfter": "Jawaban Anda setelah Episode {n} · {ep}", "answerToday": "Jawaban Anda hari ini, sebelum Episode 01",
        "episodeN": "Episode {n}", "finished": "✓ Selesai", "upNext": "● Berikutnya", "notStarted": "○ Belum dimulai",
        "capstone": "Tantangan capstone lanjutan", "journeyAria": "Peta perjalanan: {done} dari {total} makan siang selesai",
        "stationAria": "Episode {n}: {ep}", "finishedSuffix": " (selesai)", "here": "ANDA DI SINI",
        "metroText": "{done} / {total} makan siang", "earnedOn": "Diraih {date}", "earned": "Diraih", "locked": "Terkunci",
        "ofTotal": "{got} dari {total}", "canDo": "Anda sudah bisa melakukannya", "thought": "✓ Sudah direnungkan",
        "think": "💭 Saya sudah merenungkannya", "goodThinking": "Renungan yang bagus",
        "quizNote": "Jawab dalam hati, buka jawabannya, lalu jujurlah pada diri sendiri.",
        "quizPerfect": "Nilai sempurna! 🎯 Anda siap untuk lab.",
        "quizSolid": "Bagus. Baca ulang adegan di balik soal yang Anda lewatkan.",
        "quizAgain": "Layak dibaca sekali lagi — poin penting di bawah akan membantu.",
        "hide": "Sembunyikan jawaban", "reveal": "Lihat jawaban", "correct": "Jawaban benar", "perfect": "🎯 Nilai sempurna!",
        "pinned": "📌 Tersemat", "pin": "📌 Sematkan ke catatan", "savedNote": "Tersimpan di catatan Anda",
        "exitTheatre": "✕ Keluar mode teater", "theatre": "⤢ Mode teater", "demoDone": "Demo ditonton sampai akhir 🎬",
        "lunchDone": "✓ Makan siang selesai", "nextEp": "Episode berikutnya · {n}", "watchEp": "Tonton Episode {n} →",
        "seasonFinale": "Final musim", "takeChallenge": "Ikuti tantangannya →", "badgeUnlocked": "Lencana terbuka",
        "tellSari": "Sekarang Anda bisa berkata kepada Ibu Sari: “{answer}”", "notFinished": "Ditandai belum selesai",
        "segs": ["Skenario", "Bacaan", "Demo", "Uji pemahaman", "Poin penting & lab", "Waktu cadangan — habiskan makan siang Anda"],
        "lunchOver": "Waktu makan siang habis 🍵", "now": "Sekarang: {seg}", "timeFor": "⏱ Waktunya {seg}", "jump": "ke sana",
        "lunchStarted": "🍱 Makan siang dimulai. Selamat menikmati — 60 menit di jam.",
        "labDoneClean": "✓ Selesai · sudah dibersihkan", "labDone": "✓ Selesai", "inProgress": "◐ Sedang dikerjakan · {n} tugas selesai",
        "taskDone": "✓ Selesai", "markDone": "Tandai selesai", "tasksOf": "{done} dari {total} tugas", "taskComplete": "Tugas selesai",
        "cleaned": "✓ Sudah dibersihkan — tidak ada yang tersisa", "cleanup": "🧹 Saya sudah menjalankan cleanup.sh", "cleanPlate": "Piring bersih",
        "labComplete": "✓ Lab selesai", "labCompleteK": "Lab selesai", "handsOn": "Kemenangan praktik",
        "cleanedNote": "Dan Anda sudah bersih-bersih. Ibu Sari setuju. 🧹",
        "cleanupNote": "<b>Satu hal lagi:</b> jalankan <code>bash cleanup.sh</code> agar tidak ada yang terus menagih biaya.",
        "xpTo": "{n} XP lagi menuju “{name}”", "topLevel": "Level tertinggi tercapai. Legendaris.",
        "nbEmpty": "Catatan Anda masih kosong. Sematkan poin penting di akhir makan siang mana pun dan semuanya akan muncul di sini.",
        "removeNote": "Hapus catatan", "nbTitle": "Catatan makan siang Azure saya", "copiedMd": "Tersalin sebagai Markdown ✓",
        "copied": "Tersalin ✓", "copy": "Salin", "certName": "Nama Anda di sini", "certDone": "Sertifikat Kelulusan",
        "certProgress": "Sertifikat Progres",
        "certBodyDone": "telah menuntaskan ke-{total} makan siang Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran — dari server pantry hingga tata kelola berskala besar.",
        "certBodyProgress": "telah menyelesaikan {done} dari {total} makan siang Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran, dan meraih {xp} XP sebagai {level}.",
        "badFile": "Berkas itu sepertinya bukan hasil ekspor progres.",
        "resetConfirm": "Atur ulang semua progres, lencana, dan catatan di browser ini?",
        "share": "Bagikan di LinkedIn", "shareCopied": "Teks postingan tersalin — tempelkan di LinkedIn.",
        "shareBadge": "Saya baru saja meraih lencana “{name}” {icon} di “Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran”, kursus Azure gratis berbasis cerita oleh Stefanus Pinarta. Satu jam makan siang demi satu! ☁️🍱\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #BelajarAzure",
        "shareCert": "Saya sedang belajar Azure satu makan siang demi satu: {done} dari 31 makan siang selesai di “Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran”, kursus gratis berbasis cerita oleh Stefanus Pinarta. ☁️🍱\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #BelajarAzure",
        "shareCertDone": "Saya telah menuntaskan ke-31 makan siang “Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran”, kursus Azure gratis berbasis cerita oleh Stefanus Pinarta — dari server di samping pantry hingga tata kelola berskala besar. ☁️🍱🎓\n\n{url}\n\n#Azure #AzureFundamentals #CloudComputing #BelajarAzure",
        "visits": "{n} pengunjung sejauh ini",
    },
}

STRINGS = {"en": EN, "id": ID}


def check() -> list[str]:
    """Return problems: keys missing in one language, or placeholder mismatches."""
    import string
    problems = []
    for a, b in (("en", "id"), ("id", "en")):
        for k in STRINGS[a]:
            if k not in STRINGS[b]:
                problems.append(f"{k} missing in {b}")
        for k in JS[a]:
            if k not in JS[b]:
                problems.append(f"js.{k} missing in {b}")

    def fields(v):
        if isinstance(v, str):
            return {f for _, f, _, _ in string.Formatter().parse(v) if f}
        return set()
    for k, v in EN.items():
        if k in ID and fields(v) != fields(ID[k]):
            problems.append(f"{k}: placeholders differ {sorted(fields(v))} vs {sorted(fields(ID[k]))}")
    return problems


if __name__ == "__main__":
    print(check() or "strings ok")
