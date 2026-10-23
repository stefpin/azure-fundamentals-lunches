#!/usr/bin/env python3
"""Rebuild the course tables in README.md and labs/README.md.

(The GitHub Pages site — landing page, episode and lab pages, demo gallery — is built by
tools/build_site.py, which also imports the LUNCHES list from this file.)

    python3 tools/build_index.py

The course structure (numbers, slugs, titles, parts) lives in the LUNCHES list below.
Lab titles, times and cost bands are read from each lab README header when present
(lines starting with "# Lab NN · ..." and "**Time:** ... · **Cost:** ..."), so the tables
stay in sync with the labs. Generated content goes between marker comments, for example
<!-- COURSE-TABLE:START --> ... <!-- COURSE-TABLE:END -->. Standard library only.
"""
from __future__ import annotations

import html
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PAGES = "https://stefpin.github.io/azure-fundamentals-lunches"
GITHUB = "https://github.com/stefpin/azure-fundamentals-lunches/blob/main"

PARTS = {
    1: "Part 1 · Foundations",
    2: "Part 2 · Core infrastructure",
    3: "Part 3 · Platform services and data",
    4: "Part 4 · Secure, operate and govern",
    5: "Part 5 · Deep dives",
}

# (number, slug, lunch title, level, part, default lab title, default time, default cost)
LUNCHES = [
    (1, "01-before-you-begin", "Before You Begin: Your Azure Lab, Tools and Cost Guardrails", "Basic", 1, "Set up your lab environment", "about 30 minutes", "💲"),
    (2, "02-cloud-concepts", "Cloud Concepts", "Basic", 1, "Make the business case", "about 40 minutes", "💲"),
    (3, "03-global-infrastructure", "Azure Global Infrastructure: Regions, Availability Zones and Region Pairs", "Basic", 1, "Explore regions and zones", "about 35 minutes", "💲"),
    (4, "04-resource-hierarchy-basic", "Resource Hierarchy and Azure Resource Manager", "Basic", 1, "Organise Nusantara Retail", "about 40 minutes", "💲"),
    (5, "05-identity-access-basic", "Identity and Access", "Basic", 1, "Give a contractor just enough access", "about 40 minutes", "💲"),
    (6, "06-virtual-machines-basic", "Virtual Machines", "Basic", 2, "Your first web server VM", "about 45 minutes", "💲💲"),
    (7, "07-storage-basic", "Storage", "Basic", 2, "Store product images and invoices", "about 45 minutes", "💲"),
    (8, "08-networking-basic", "Virtual Networking", "Basic", 2, "Build Nusantara Retail's network", "about 50 minutes", "💲💲"),
    (9, "09-load-balancing-basic", "Load Balancing: Azure Load Balancer", "Basic", 2, "Keep the shop open when a server fails", "about 50 minutes", "💲💲"),
    (10, "10-app-service", "Web Apps with Azure App Service", "Basic", 3, "Move the storefront to PaaS", "about 45 minutes", "💲"),
    (11, "11-relational-databases-basic", "Relational Databases: Azure SQL", "Basic", 3, "Nusantara Retail's orders database", "about 45 minutes", "💲"),
    (12, "12-cosmos-db", "NoSQL with Azure Cosmos DB", "Basic", 3, "A product catalogue that scales", "about 45 minutes", "💲"),
    (13, "13-containers-basic", "Containers: Container Registry, Container Instances and Container Apps", "Basic", 3, "Package the storefront", "about 45 minutes", "💲"),
    (14, "14-serverless", "Serverless: Azure Functions, Logic Apps and Event Grid", "Basic", 3, "React to new orders automatically", "about 50 minutes", "💲"),
    (15, "15-security-essentials", "Security Essentials: Defense in Depth, Key Vault and Defender for Cloud", "Basic", 4, "Get the password out of the config file", "about 45 minutes", "💲💲"),
    (16, "16-monitoring-basic", "Monitoring: Azure Monitor, Alerts, Service Health and Advisor", "Basic", 4, "Know before customers do", "about 45 minutes", "💲💲"),
    (17, "17-backup-disaster-recovery", "Backup and Disaster Recovery", "Basic", 4, "The restore drill", "60–90 minutes (mostly waiting)", "💲💲"),
    (18, "18-governance-compliance-basic", "Governance and Compliance: Azure Policy, Locks, Tags and Microsoft Purview", "Basic", 4, "Keep data in the right place", "about 45 minutes", "💲"),
    (19, "19-cost-management", "Cost Management", "Basic", 4, "Find the waste you made yourself", "about 40 minutes", "💲"),
    (20, "20-infrastructure-as-code-bicep", "Infrastructure as Code with Bicep", "Basic", 4, "Nineteen lunches of clicks in one file", "about 50 minutes", "💲"),
    (21, "21-core-capstone", "Core Capstone: Putting It All Together", "Basic", 4, "Capstone project", "2–3 hours (can be split)", "💲💲"),
    (22, "22-identity-access-advanced", "Identity and Access", "Advanced", 5, "Passwordless pipelines and least privilege", "about 50 minutes", "💲"),
    (23, "23-virtual-machines-advanced", "Virtual Machines", "Advanced", 5, "Ready for the 12.12 sale", "about 60 minutes", "💲💲"),
    (24, "24-storage-advanced", "Storage", "Advanced", 5, "Ransomware-proof invoices", "about 60 minutes", "💲💲"),
    (25, "25-networking-advanced", "Virtual Networking", "Advanced", 5, "Hub and spoke for Nusantara Retail", "about 60 minutes", "💲💲"),
    (26, "26-hybrid-connectivity", "Hybrid Connectivity: VPN Gateway, ExpressRoute and Virtual WAN", "Advanced", 5, "Connect head office", "about 90 minutes (incl. waiting)", "💲💲💲"),
    (27, "27-load-balancing-advanced", "Load Balancing: Application Gateway, Front Door and Traffic Manager", "Advanced", 5, "Protect and route the storefront", "about 75 minutes", "💲💲💲"),
    (28, "28-relational-databases-advanced", "Relational Databases", "Advanced", 5, "Orders that survive a regional outage", "about 60 minutes", "💲💲"),
    (29, "29-containers-advanced-aks", "Containers: Azure Kubernetes Service", "Advanced", 5, "Kubernetes for the microservices team", "about 60 minutes", "💲💲💲"),
    (30, "30-monitoring-advanced", "Monitoring: Log Analytics, KQL and Application Insights", "Advanced", 5, "Why was checkout slow on Friday?", "about 60 minutes", "💲💲"),
    (31, "31-governance-at-scale", "Resource Hierarchy and Governance: Governance at Scale", "Advanced", 5, "Governance for the whole company", "about 60 minutes", "💲"),
]
CAPSTONE = ("32-advanced-capstone-challenge", "Advanced capstone challenge", "a multi-session project", "💲💲💲")


def lab_info(slug: str, default_title: str, default_time: str, default_cost: str) -> tuple[str, str, str]:
    readme = REPO / "labs" / slug / "README.md"
    title, time, cost = default_title, default_time, default_cost
    if readme.exists():
        text = readme.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^#\s*Lab\s*\d+\s*[·:\-–]\s*(.+?)\s*$", text, re.MULTILINE)
        if m:
            title = m.group(1).strip()
        m = re.search(r"\*\*Time:\*\*\s*([^·\n|]+)", text)
        if m:
            # Keep the table short: "about 50 minutes (including setup)" -> "about 50 minutes"
            time = re.split(r"\s\(|,|;|\sincluding\b", m.group(1).strip())[0].strip().rstrip(".")
        m = re.search(r"\*\*Cost:\*\*\s*(💲+)", text)
        if m:
            cost = m.group(1)
    return title, time, cost


def exists(rel: str) -> bool:
    return (REPO / rel).exists()


def course_tables() -> str:
    out: list[str] = []
    for part_no, part_name in PARTS.items():
        rows = [l for l in LUNCHES if l[4] == part_no]
        month = "Core month" if part_no < 5 else "Deep-dive month"
        out.append(f"### {month} — {part_name}\n")
        out.append("| # | Lunch (reading) | Level | Online | Lab | Lab time | Cost |")
        out.append("|---:|---|---|---|---|---|---|")
        for n, slug, title, level, _p, lt, ltime, lcost in rows:
            ltitle, ltime, lcost = lab_info(slug, lt, ltime, lcost)
            reading = f"[{title}](lunches/{slug}/README.md)"
            demo = (f"[🌐 Episode]({PAGES}/lunches/{slug}.html) · [▶ Demo]({PAGES}/demos/{slug}.html)"
                    if exists(f"docs/demos/{slug}.html") else f"[🌐 Episode]({PAGES}/lunches/{slug}.html)")
            lab = f"[{ltitle}](labs/{slug}/README.md)"
            out.append(f"| {n:02d} | {reading} | {level} | {demo} | {lab} | {ltime} | {lcost} |")
        out.append("")
    slug, title, time, cost = CAPSTONE
    out.append(f"**Then:** [{title}](labs/{slug}/README.md) — {time}, {cost}. Requirements only: design it, build it, prove it.\n")
    return "\n".join(out)


def lab_table() -> str:
    out = ["| Lab | Pairs with | Time | Cost |", "|---|---|---|---|"]
    for n, slug, title, level, _p, lt, ltime, lcost in LUNCHES:
        ltitle, ltime, lcost = lab_info(slug, lt, ltime, lcost)
        out.append(f"| [Lab {n:02d} · {ltitle}]({slug}/README.md) | [Lunch {n:02d} · {title}"
                   f"{' (Advanced)' if level == 'Advanced' else (' (Basic)' if slug.endswith('-basic') else '')}](../lunches/{slug}/README.md) | {ltime} | {lcost} |")
    slug, title, time, cost = CAPSTONE
    out.append(f"| [{title}]({slug}/README.md) | Lunches 22–31 | {time} | {cost} |")
    return "\n".join(out) + "\n"


def replace_between(path: Path, marker: str, content: str) -> bool:
    text = path.read_text(encoding="utf-8")
    start, end = f"<!-- {marker}:START -->", f"<!-- {marker}:END -->"
    pattern = re.compile(re.escape(start) + r".*?" + re.escape(end), re.DOTALL)
    if not pattern.search(text):
        print(f"! markers {marker} not found in {path.relative_to(REPO)}")
        return False
    new = pattern.sub(lambda _m: f"{start}\n{content}{end}", text)
    if new != text:
        path.write_text(new, encoding="utf-8")
        print(f"updated {path.relative_to(REPO)} ({marker})")
    else:
        print(f"unchanged {path.relative_to(REPO)} ({marker})")
    return True


def main() -> int:
    ok = True
    ok &= replace_between(REPO / "README.md", "COURSE-TABLE", course_tables())
    ok &= replace_between(REPO / "labs" / "README.md", "LAB-TABLE", lab_table())
    missing = [s for _n, s, *_ in LUNCHES if not exists(f"lunches/{s}/README.md")]
    if missing:
        print(f"! readings not found yet: {', '.join(missing)}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
