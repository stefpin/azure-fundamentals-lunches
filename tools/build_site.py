#!/usr/bin/env python3
"""Build the GitHub Pages site in docs/ from the Markdown course.

    pip install -r tools/requirements-site.txt      # markdown-it-py
    python3 tools/build_site.py

Inputs (edit these, then rebuild):
  lunches/*/README.md        the readings          -> docs/lunches/<slug>.html  (episode pages)
  labs/*/README.md           the lab guides        -> docs/labs/<slug>.html     (lab pages)
  labs/README.md             cost bands, how labs work -> docs/labs/index.html
  docs/demos/*.html          the animated demos    -> docs/demos/index.html     (gallery)
  tools/site/series.json     story layer: episode titles, hooks, badges, cast, levels
  tools/build_index.py       course structure (numbers, slugs, titles, parts)

Hand-written (not generated): docs/assets/site.css, docs/assets/site.js.
Generated: docs/index.html, docs/lunchbox.html, docs/404.html, docs/assets/course-data.js,
docs/assets/favicon.svg, docs/assets/social-card.png (if Pillow is installed).
"""
from __future__ import annotations

import functools
import hashlib
import html
import json
import math
import os
import re
import sys
import textwrap
from pathlib import Path
from urllib.parse import quote, unquote, urlparse

try:
    from markdown_it import MarkdownIt
    from markdown_it.token import Token
except ImportError:  # pragma: no cover
    sys.exit("This tool needs markdown-it-py. Install it with:  pip install -r tools/requirements-site.txt")

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
DOCS = REPO / "docs"
sys.path.insert(0, str(TOOLS))
import build_index as bi  # noqa: E402  (course structure lives there)

PAGES = bi.PAGES.rstrip("/")
REPO_URL = bi.GITHUB.split("/blob/")[0]
SERIES = json.loads((TOOLS / "site" / "series.json").read_text(encoding="utf-8"))
PARTS = {p["id"]: p for p in SERIES["parts"]}
E = html.escape
PLACEHOLDER = "YOUR-" + "GITHUB-USERNAME"   # split so tools/set_github_username.py leaves this line alone
COURSE_NAME = "Azure Fundamentals: One Lunch at a Time"
COST_TEXT = {1: "free or close to free", 2: "small charges while running", 3: "noticeable charges while running"}

# Lunch clock segments: (minutes, name, description, colour, anchor)
SEGMENTS = [
    (5, "Scenario & objectives", "Meet the problem of the day at Nusantara Retail and the five things you will be able to do by the end.", "#e2482f", "#menu"),
    (25, "Reading", "Six short scenes with diagrams, tables, tips and pause-and-think moments. No walls of text.", "#1665d8", "#reading"),
    (15, "Animated demo", "Watch the idea move: packets, permissions and failovers you can play, pause and step through.", "#7b4ff0", "#demo"),
    (5, "Knowledge check", "Five scenario questions. Answer in your head, reveal, grade yourself honestly and earn XP.", "#11935a", "#quiz"),
    (5, "Takeaways & lab ticket", "Pin the key points to your notebook and pick up the ticket for today's hands-on lab.", "#d98a00", "#takeaways"),
    (5, "Buffer", "Finish your lunch. Seriously. The lab waits for you, whenever suits you.", "#0f9fb0", "#finish"),
]


# ============================================================================ helpers
def rel_url(target: Path, from_dir: Path) -> str:
    return os.path.relpath(target, from_dir).replace(os.sep, "/")


def gh_slug(text: str) -> str:
    """GitHub-style heading anchor: lower-case, drop punctuation and emoji, spaces to hyphens."""
    s = text.strip().lower()
    s = re.sub(r"[^\w\- ]", "", s)
    return s.replace(" ", "-")


def plain(md_text: str) -> str:
    """Very small Markdown-to-plain-text for headings and titles."""
    s = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", md_text)
    s = re.sub(r"[`*_]", "", s)
    return s.strip()


def strip_emoji_prefix(s: str) -> str:
    return re.sub(r"^[^\w(“\"']+\s*", "", s).strip()


def fence_aware_split(text: str, level: int) -> list[tuple[str | None, str]]:
    """Split Markdown at headings of exactly `level`, ignoring fenced code blocks."""
    prefix = "#" * level + " "
    out: list[tuple[str | None, str]] = []
    title: str | None = None
    buf: list[str] = []
    fence = None
    for line in text.splitlines():
        s = line.lstrip()
        m = re.match(r"(`{3,}|~{3,})", s)
        if m:
            if fence is None:
                fence = m.group(1)[0] * len(m.group(1))
            elif s.startswith(fence) and s.strip() == s.strip()[0] * len(s.strip()):
                fence = None
        if fence is None and not m and line.startswith(prefix):
            out.append((title, "\n".join(buf)))
            title, buf = line[len(prefix):].strip(), []
        else:
            buf.append(line)
    out.append((title, "\n".join(buf)))
    return out


def trim_rules(body: str) -> str:
    """Remove trailing horizontal rules and blank lines."""
    lines = body.rstrip().splitlines()
    while lines and lines[-1].strip() in ("---", "***", ""):
        lines.pop()
    return "\n".join(lines).strip("\n")


def strip_footer(body: str) -> tuple[str, str]:
    """Remove the Markdown page footer (nav line and <sub>Last validated…</sub>); return (body, validated)."""
    validated = ""
    keep = []
    for line in body.splitlines():
        st = line.strip()
        m = re.search(r"Last validated:\s*([^·<]+)", st)
        if st.startswith("<sub>") and m:
            validated = m.group(1).strip()
            continue
        if st.startswith("⬅️") or ("🏠" in st and ("Course home" in st or "All labs" in st)):
            continue
        keep.append(line)
    return trim_rules("\n".join(keep)), validated


def rx(pattern: str, text: str, default: str = "") -> str:
    m = re.search(pattern, text)
    return m.group(1).strip() if m else default


def short_hash(*paths: Path) -> str:
    h = hashlib.sha1()
    for p in paths:
        if p.exists():
            h.update(p.read_bytes())
    return h.hexdigest()[:10]


# ============================================================================ markdown
CALLOUTS = {
    "note": ("Note", "ℹ️"), "tip": ("Tip", "💡"), "important": ("Important", "❗"),
    "warning": ("Warning", "⚠️"), "caution": ("Caution", "🛑"),
}
LANG_LABEL = {"bash": "bash", "sh": "shell", "shell": "shell", "console": "console", "json": "json", "jsonc": "json",
              "yaml": "yaml", "yml": "yaml", "bicep": "bicep", "kql": "KQL", "kusto": "KQL", "sql": "SQL",
              "tsql": "T-SQL", "python": "python", "py": "python", "powershell": "PowerShell", "ps1": "PowerShell",
              "text": "text", "txt": "text", "dockerfile": "Dockerfile", "html": "html", "javascript": "javascript",
              "js": "javascript", "ini": "ini", "csv": "csv", "http": "http", "xml": "xml"}


@functools.lru_cache(maxsize=None)
def _is_dir(p: Path) -> bool:
    return p.is_dir()


@functools.lru_cache(maxsize=None)
def _exists(p: Path) -> bool:
    return p.exists()


def page_for(target: Path) -> Path | None:
    """Map a repository file to the generated site page that represents it."""
    try:
        target.relative_to(REPO)
    except ValueError:
        return None
    if _is_dir(target):
        if _exists(target / "README.md"):
            target = target / "README.md"
        else:
            return None
    if target == REPO / "README.md":
        return DOCS / "index.html"
    if target == REPO / "labs" / "README.md":
        return DOCS / "labs" / "index.html"
    if target.name == "README.md" and target.parent.parent == REPO / "lunches":
        return DOCS / "lunches" / f"{target.parent.name}.html"
    if target.name == "README.md" and target.parent.parent == REPO / "labs" and target.parent.name != "common":
        return DOCS / "labs" / f"{target.parent.name}.html"
    try:
        target.relative_to(DOCS)
        return target
    except ValueError:
        return None


def map_href(href: str, env: dict) -> tuple[str, bool]:
    """Return (new_href, is_external)."""
    if not href or href.startswith(("#", "mailto:", "javascript:")):
        return href, False
    out_dir = env["out"].parent
    if href.startswith(PAGES):
        rest = href[len(PAGES):].lstrip("/")
        path, _, frag = rest.partition("#")
        target = DOCS / (path or "index.html")
        return rel_url(target, out_dir) + (f"#{frag}" if frag else ""), False
    if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", href):
        return href, True
    path, _, frag = href.partition("#")
    target = Path(os.path.normpath(env["src"].parent / unquote(path))) if path else env["src"]
    page = page_for(target)
    if page is not None:
        return rel_url(page, out_dir) + (f"#{frag}" if frag else ""), False
    try:
        rp = target.relative_to(REPO).as_posix()
    except ValueError:
        return href, False
    kind = "tree" if _is_dir(target) else "blob"
    return f"{REPO_URL}/{kind}/main/{quote(rp)}" + (f"#{frag}" if frag else ""), True


def _inline_text(tok) -> str:
    return "".join(c.content for c in (tok.children or []) if c.type in ("text", "code_inline"))


def _find_close(tokens, i):
    depth = 0
    for j in range(i, len(tokens)):
        if tokens[j].type == "blockquote_open":
            depth += 1
        elif tokens[j].type == "blockquote_close":
            depth -= 1
            if depth == 0:
                return j
    return len(tokens) - 1


def core_rule(state):
    toks = state.tokens
    used = state.env.setdefault("ids", {})
    for i, t in enumerate(toks):
        if t.type == "heading_open":
            base = gh_slug(_inline_text(toks[i + 1])) or "section"
            sid = base
            if sid in used:
                used[base] += 1
                sid = f"{base}-{used[base]}"
            used.setdefault(sid, 0)
            t.attrSet("id", sid)
        elif t.type == "blockquote_open":
            j = i + 1
            while j < len(toks) and toks[j].type != "inline":
                j += 1
            if j >= len(toks):
                continue
            inl = toks[j]
            close = _find_close(toks, i)
            m = re.match(r"^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]", inl.content)
            if m:
                kind = m.group(1).lower()
                title, icon = CALLOUTS[kind]
                ch = inl.children or []
                if ch and ch[0].type == "text":
                    ch[0].content = re.sub(r"^\[!\w+\]\s*", "", ch[0].content)
                while ch and ((ch[0].type == "text" and not ch[0].content.strip()) or ch[0].type in ("softbreak", "hardbreak")):
                    ch.pop(0)
                rest = inl.content[m.end():].lstrip()
                if kind == "note" and rest.startswith("**Pause and think:**"):
                    kind, title, icon = "think", "Pause and think", "💭"
                    if len(ch) >= 3 and ch[0].type == "strong_open" and ch[2].type == "strong_close":
                        del ch[0:3]
                        if ch and ch[0].type == "text":
                            ch[0].content = ch[0].content.lstrip()
                            if ch[0].content:
                                ch[0].content = ch[0].content[0].upper() + ch[0].content[1:]
                head = Token("html_inline", "", 0)
                head.content = f'<span class="callout-title">{E(title)}</span>'
                ch.insert(0, head)
                inl.children = ch
                t.tag = toks[close].tag = "aside"
                t.attrSet("class", f"callout {kind}")
                t.attrSet("data-icon", icon)
            elif inl.content.startswith("✅ **Checkpoint"):
                t.tag = toks[close].tag = "div"
                t.attrSet("class", "checkpoint")


def r_fence(self, tokens, idx, options, env):
    tok = tokens[idx]
    info = tok.info.strip().split()[0].lower() if tok.info and tok.info.strip() else ""
    code = tok.content
    if info == "mermaid":
        return ('<figure class="diagram"><pre class="mermaid">' + E(code) + "</pre>"
                '<button class="btn btn-sm zoom-btn" type="button" aria-label="Zoom into the diagram">⤢ Zoom</button></figure>\n')
    label = LANG_LABEL.get(info, info or "text")
    return (f'<div class="code" data-lang="{E(info)}"><div class="code-head"><span><span class="dots"><i></i><i></i><i></i></span>'
            f'{E(label)}</span><button class="copy-btn" type="button">Copy</button></div><pre><code>{E(code)}</code></pre></div>\n')


def r_code_block(self, tokens, idx, options, env):
    code = tokens[idx].content
    return (f'<div class="code" data-lang=""><div class="code-head"><span><span class="dots"><i></i><i></i><i></i></span>text</span>'
            f'<button class="copy-btn" type="button">Copy</button></div><pre><code>{E(code)}</code></pre></div>\n')


def r_link_open(self, tokens, idx, options, env):
    tok = tokens[idx]
    new, external = map_href(tok.attrGet("href") or "", env)
    tok.attrSet("href", new)
    if external:
        tok.attrSet("target", "_blank")
        tok.attrSet("rel", "noopener")
    return self.renderToken(tokens, idx, options, env)


def r_heading_close(self, tokens, idx, options, env):
    hid = tokens[idx - 2].attrGet("id") if idx >= 2 else None
    a = f' <a class="h-anchor" href="#{E(hid)}" aria-label="Link to this section">#</a>' if hid else ""
    return f"{a}</{tokens[idx].tag}>\n"


def make_md() -> MarkdownIt:
    md = MarkdownIt("commonmark", {"html": True}).enable(["table", "strikethrough"])
    md.core.ruler.push("lunch_callouts", core_rule)
    md.add_render_rule("fence", r_fence)
    md.add_render_rule("code_block", r_code_block)
    md.add_render_rule("link_open", r_link_open)
    md.add_render_rule("heading_close", r_heading_close)
    md.add_render_rule("table_open", lambda self, t, i, o, e: '<div class="table-wrap"><table>\n')
    md.add_render_rule("table_close", lambda self, t, i, o, e: "</table></div>\n")
    return md


MD = make_md()


def render(md_text: str, env: dict) -> str:
    out = MD.render(textwrap.dedent(md_text).strip("\n") + "\n", env)
    return out.replace("<details>", '<details class="plain">')


def render_inline(md_text: str, env: dict) -> str:
    out = render(md_text, env).strip()
    m = re.fullmatch(r"<p>(.*)</p>", out, flags=re.S)
    return m.group(1) if m else out


# ============================================================================ svg art
LOGO = ('<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="2" y="7" width="36" height="28" rx="8" fill="#e2482f"/>'
        '<rect x="5" y="10" width="15" height="22" rx="5" fill="#fff6e8"/><rect x="22" y="10" width="13" height="10" rx="4" fill="#ffc14a"/>'
        '<rect x="22" y="22" width="13" height="10" rx="4" fill="#45cf8c"/>'
        '<path d="M8.4 26.2h7.9a2.7 2.7 0 0 0 .2-5.4 3.8 3.8 0 0 0-7.2-1.1 3.2 3.2 0 0 0-.9 6.5z" fill="#1665d8"/></svg>')

FAVICON = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><rect x="2" y="7" width="36" height="28" rx="8" fill="#e2482f"/>'
           '<rect x="5" y="10" width="15" height="22" rx="5" fill="#fff6e8"/><rect x="22" y="10" width="13" height="10" rx="4" fill="#ffc14a"/>'
           '<rect x="22" y="22" width="13" height="10" rx="4" fill="#45cf8c"/>'
           '<path d="M8.4 26.2h7.9a2.7 2.7 0 0 0 .2-5.4 3.8 3.8 0 0 0-7.2-1.1 3.2 3.2 0 0 0-.9 6.5z" fill="#1665d8"/></svg>\n')


def pantry(mood: int = 0, extra: str = "", label: str = "The pantry server") -> str:
    blade = '<path d="M0 0C3-8 10-8 9-2S3 2 0 0z"/>'
    return (
        f'<svg class="pantry mood-{mood}" {extra} viewBox="0 0 200 236" role="img" aria-label="{E(label)}">'
        '<g class="heat"><path d="M70 36c-7-6 7-11 0-18"/><path d="M100 30c-7-6 7-11 0-18"/><path d="M130 36c-7-6 7-11 0-18"/></g>'
        '<ellipse cx="100" cy="228" rx="72" ry="7" fill="currentColor" opacity=".1"/>'
        '<rect class="body" x="38" y="46" width="124" height="172" rx="22"/>'
        '<rect class="bay" x="56" y="64" width="88" height="20" rx="6"/><circle class="led" cx="132" cy="74" r="4"/>'
        '<rect class="bay" x="56" y="92" width="88" height="20" rx="6"/><circle class="led l2" cx="132" cy="102" r="4"/>'
        '<circle class="eye" cx="80" cy="142" r="7.5"/><circle class="eye" cx="120" cy="142" r="7.5"/>'
        '<g class="shades"><rect x="61" y="130" width="35" height="19" rx="7" fill="#16203a"/><rect x="104" y="130" width="35" height="19" rx="7" fill="#16203a"/>'
        '<path d="M96 137h8" stroke="#16203a" stroke-width="4"/><path d="M66 135h9" stroke="#fff" stroke-width="2" opacity=".6"/></g>'
        '<circle class="cheek" cx="66" cy="162" r="7"/><circle class="cheek" cx="134" cy="162" r="7"/>'
        '<path class="mouth sad" d="M84 178q16-13 32 0"/><path class="mouth flat" d="M86 172h28"/><path class="mouth smile" d="M82 165q18 18 36 0"/>'
        '<path class="sweat" d="M152 118c-6 10-8 14-4 18a6 6 0 0 0 8 0c4-4 2-8-4-18z"/>'
        '<path d="M58 196h22M58 204h22M120 196h22M120 204h22" stroke="currentColor" stroke-width="3" stroke-linecap="round" opacity=".25"/>'
        f'<g transform="translate(100 200)"><g class="fan">{blade}<g transform="rotate(120)">{blade}</g><g transform="rotate(240)">{blade}</g>'
        '<circle r="2.6" fill="#f2a007"/></g></g></svg>'
    )


CLOUD = ('<svg class="cloud" viewBox="0 0 220 140" aria-hidden="true"><defs><linearGradient id="cloudGrad" x1="0" y1="0" x2="1" y2="1">'
         '<stop offset="0" stop-color="#5ab0ff"/><stop offset="1" stop-color="#1665d8"/></linearGradient></defs>'
         '<path d="M58 124h112a40 40 0 0 0 4-79.8A52 52 0 0 0 76 36a36 36 0 0 0-18 88z" fill="url(#cloudGrad)"/>'
         '<circle cx="98" cy="86" r="5" fill="#fff"/><circle cx="134" cy="86" r="5" fill="#fff"/>'
         '<path d="M104 101q12 10 24 0" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round"/>'
         '<g fill="#ffc14a"><path d="M200 14l3 8 8 3-8 3-3 8-3-8-8-3 8-3z"/><path d="M22 26l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/></g></svg>')

COFFEE = ('<svg class="coffee" viewBox="0 0 100 130" aria-hidden="true"><g class="steam"><path d="M38 32c-6-6 6-10 0-16"/>'
          '<path d="M52 28c-6-6 6-10 0-16"/><path d="M66 32c-6-6 6-10 0-16"/></g>'
          '<rect x="16" y="40" width="68" height="80" rx="12" fill="#e2482f" stroke="#16203a" stroke-width="3"/>'
          '<rect x="28" y="52" width="44" height="22" rx="6" fill="#fff6e8" stroke="#16203a" stroke-width="2.5"/>'
          '<circle cx="40" cy="63" r="4" fill="#45cf8c"/><circle cx="52" cy="63" r="4" fill="#ffc14a"/>'
          '<path d="M36 86h28l-3 22H39z" fill="#fff" stroke="#16203a" stroke-width="2.5"/></svg>')


def skyline() -> str:
    stars = "".join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y, r in [
        (60, 18, 1.4), (150, 34, 1), (240, 14, 1.6), (330, 40, 1), (420, 20, 1.3), (520, 30, 1), (690, 16, 1.5),
        (760, 38, 1), (850, 22, 1.2), (940, 12, 1), (1010, 44, 1.3), (1140, 20, 1.5), (1170, 50, 1)])
    blds = [(0, 70, 60), (64, 52, 46), (114, 80, 40), (158, 44, 54), (216, 66, 38), (258, 36, 60), (322, 58, 44),
            (370, 74, 36), (410, 48, 50), (464, 62, 44), (650, 54, 48), (702, 40, 56), (762, 68, 40), (806, 30, 52),
            (862, 58, 46), (912, 46, 40), (956, 72, 44), (1004, 38, 58), (1066, 62, 48), (1118, 50, 82)]
    rects = "".join(f'<rect x="{x}" y="{y}" width="{w}" height="{120 - y}"/>' for x, y, w in blds)
    wins = "".join(f'<rect x="{x + 8 + (k % 3) * 12}" y="{y + 10 + (k // 3) * 14}" width="5" height="6"/>'
                   for i, (x, y, w) in enumerate(blds) if i % 2 == 0 for k in range(3 if w < 45 else 6) if y + 10 + (k // 3) * 14 < 112)
    return ('<svg class="skyline" viewBox="0 0 1200 120" preserveAspectRatio="xMidYMax slice" aria-hidden="true">'
            '<defs><linearGradient id="skyGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22325f"/>'
            '<stop offset="1" stop-color="#16203a"/></linearGradient></defs><rect width="1200" height="120" fill="url(#skyGrad)"/>'
            f'<g fill="#ffd58a" opacity=".8">{stars}</g>'
            '<circle cx="1060" cy="30" r="14" fill="#ffe7a8"/><circle cx="1067" cy="25" r="13" fill="#22325f"/>'
            f'<g fill="#0b1328">{rects}<path d="M560 120l14-18h52l14 18z"/><rect x="592" y="58" width="16" height="46"/>'
            '<path d="M588 60h24l-4-6h-16z"/></g>'
            '<path d="M600 30c-7 9-7 17 0 26 7-9 7-17 0-26z" fill="#ffc14a"/><path d="M600 40c-3 5-3 9 0 13 3-4 3-8 0-13z" fill="#fff3c4"/>'
            f'<g fill="#ffd58a" opacity=".55">{wins}</g></svg>')


def clock_svg() -> str:
    r, cx = 140, 200
    circ = 2 * math.pi * r
    segs, start = [], 0
    for i, (mins, name, _d, color, _a) in enumerate(SEGMENTS):
        length = circ * mins / 60
        gap = 5
        segs.append(f'<circle class="seg" cx="{cx}" cy="{cx}" r="{r}" fill="none" stroke="{color}" stroke-width="58" '
                    f'stroke-dasharray="{length - gap:.2f} {circ - length + gap:.2f}" stroke-dashoffset="{-start:.2f}">'
                    f'<title>{E(name)} · {mins} min</title></circle>')
        start += length
    ticks = ""
    for m, a in [(0, 0), (15, 90), (30, 180), (45, 270)]:
        tx = cx + 186 * math.sin(math.radians(a))
        ty = cx - 186 * math.cos(math.radians(a)) + 5
        ticks += (f'<text x="{tx:.1f}" y="{ty:.1f}" text-anchor="middle" font-size="13" font-weight="800" '
                  f'fill="currentColor" opacity=".55">{m}</text>')
    return ('<svg viewBox="0 0 400 400" role="img" aria-label="The 60-minute lunch: 5 minutes scenario, 25 reading, 15 demo, '
            '5 knowledge check, 5 takeaways, 5 buffer">' + f'<g transform="rotate(-90 {cx} {cx})">' + "".join(segs) + "</g>" + ticks +
            f'<circle cx="{cx}" cy="{cx}" r="104" fill="var(--surface)"/>'
            f'<text class="center-label" x="{cx}" y="{cx + 4}" text-anchor="middle" font-size="46" fill="currentColor" data-clock-label>60 min</text>'
            f'<text x="{cx}" y="{cx + 34}" text-anchor="middle" font-size="15" font-weight="700" fill="currentColor" opacity=".6" data-clock-sub>one lunch</text></svg>')


def gauge_svg() -> str:
    return ('<svg viewBox="0 0 300 205" role="img" aria-label="Readiness to answer the director\'s question" data-gauge>'
            '<defs><linearGradient id="gaugeGrad" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e2482f"/>'
            '<stop offset=".5" stop-color="#f2a007"/><stop offset="1" stop-color="#11935a"/></linearGradient></defs>'
            '<path class="track" d="M30 150A120 120 0 0 1 270 150"/><path class="fill" d="M30 150A120 120 0 0 1 270 150"/>'
            '<g class="needle" style="transform:rotate(-90deg)"><path d="M146 150L150 52L154 150z" style="fill:var(--ink)"/>'
            '<circle cx="150" cy="150" r="11" style="fill:var(--ink)"/><circle cx="150" cy="150" r="4" style="fill:var(--surface)"/></g>'
            '<text class="pct" x="150" y="198" text-anchor="middle">0%</text>'
            '<text class="pct-l" x="34" y="176" text-anchor="middle">Days?</text><text class="pct-l" x="266" y="176" text-anchor="middle">Answered</text></svg>')


def mood_for(pct: int) -> int:
    return 0 if pct < 10 else 1 if pct < 35 else 2 if pct < 60 else 3 if pct < 90 else 4


# ============================================================================ course data
def course_lunches() -> list[dict]:
    out = []
    for (n, slug, title, level, part, lt, ltime, lcost) in bi.LUNCHES:
        ep = SERIES["episodes"][f"{n:02d}"]
        ltitle, ltime2, lcost2 = bi.lab_info(slug, lt, ltime, lcost)
        out.append({
            "n": f"{n:02d}", "num": n, "slug": slug, "title": title, "level": level, "part": part,
            "season": 1 if n <= 21 else 2, "ep": ep["ep"], "station": ep["station"], "hook": ep["hook"],
            "outcome": ep["outcome"], "badge": ep["badge"], "answer": ep["answer"], "readiness": ep["readiness"],
            "lab": {"title": ltitle, "time": ltime2, "cost": lcost2},
        })
    return out


def write_course_data(lunches: list[dict]) -> None:
    keep = ("n", "slug", "title", "level", "part", "ep", "station", "hook", "badge", "answer", "readiness", "lab")
    data = {
        "title": SERIES["title"], "lunches": [{k: l[k] for k in keep} for l in lunches],
        "parts": SERIES["parts"], "seasons": SERIES["seasons"], "cast": SERIES["cast"], "levels": SERIES["levels"],
        "specialBadges": SERIES["specialBadges"], "director": SERIES["director"], "finale": SERIES["finale"],
    }
    js = ("/* Generated by tools/build_site.py from tools/site/series.json and the course structure. Do not edit. */\n"
          "window.COURSE = " + json.dumps(data, ensure_ascii=False, indent=1) + ";\n")
    (DOCS / "assets" / "course-data.js").write_text(js, encoding="utf-8")


# ============================================================================ page shell
class Shell:
    def __init__(self):
        a = DOCS / "assets"
        self.v = short_hash(a / "site.css", a / "site.js", a / "course-data.js")

    def page(self, *, out: Path, title: str, desc: str, main: str, body_attrs: dict | None = None, active: str = "",
             root: str | None = None) -> None:
        if root is None:
            root = rel_url(DOCS, out.parent)
            root = "" if root == "." else root + "/"
        attrs = {"data-root": root}
        attrs.update(body_attrs or {})
        battrs = " ".join(f'{k}="{E(str(v))}"' for k, v in attrs.items())
        url = PAGES + "/" + rel_url(out, DOCS).replace("index.html", "")
        nav = [("index.html#journey", "Journey", "journey"), ("index.html#episodes", "Episodes", "episodes"),
               ("labs/index.html", "Labs", "labs"), ("demos/index.html", "Demos", "demos"),
               ("lunchbox.html", "My lunchbox", "lunchbox")]
        cur = ' aria-current="page"'
        nav_html = "".join(f'<a href="{root}{h}"{cur if k == active else ""}>{E(t)}</a>' for h, t, k in nav)
        nav_html += f'<a href="{REPO_URL}" target="_blank" rel="noopener">GitHub ↗</a>'
        full_title = title if title.endswith(COURSE_NAME) else f"{title} · {COURSE_NAME}"
        doc = f"""<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{E(full_title)}</title>
<meta name="description" content="{E(desc)}">
<meta name="theme-color" content="#1665d8">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{E(COURSE_NAME)}">
<meta property="og:title" content="{E(title)}">
<meta property="og:description" content="{E(desc)}">
<meta property="og:url" content="{E(url)}">
<meta property="og:image" content="{PAGES}/assets/social-card.png">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="{root}assets/favicon.svg" type="image/svg+xml">
<script>(function(){{var d=document.documentElement;d.classList.add('js');try{{var t=localStorage.getItem('azlunch.theme');if(!t)t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';d.setAttribute('data-theme',t);}}catch(e){{}}}})();</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="{root}assets/site.css?v={self.v}">
</head>
<body {battrs}>
<a class="skip" href="#main">Skip to content</a>
<div class="read-progress" aria-hidden="true"><span></span></div>
<header class="site-header">
  <div class="container">
    <a class="brand" href="{root}index.html">{LOGO}<span>One Lunch at a Time<small>Azure Fundamentals</small></span></a>
    <nav class="nav-links" id="site-nav" aria-label="Main">{nav_html}</nav>
    <div class="hud">
      <a class="hud-pill" href="{root}lunchbox.html" data-hud-title title="Your progress"><span class="ring" data-hud-ring></span><span class="hud-text" data-hud-text>0 XP · Curious visitor</span></a>
      <button class="icon-btn" type="button" data-theme-toggle aria-label="Switch between light and dark mode">🌙</button>
      <button class="icon-btn menu-toggle" type="button" data-menu-toggle aria-controls="site-nav" aria-expanded="false" aria-label="Open the menu">☰</button>
    </div>
  </div>
</header>
<main id="main">
{main}
</main>
{self.footer(root)}
<script src="{root}assets/course-data.js?v={self.v}" defer></script>
<script src="{root}assets/site.js?v={self.v}" defer></script>
</body>
</html>
"""
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(doc, encoding="utf-8")

    @staticmethod
    def footer(root: str) -> str:
        return f"""<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a class="brand" href="{root}index.html">{LOGO}<span>One Lunch at a Time<small>Azure Fundamentals</small></span></a>
        <p style="margin-top:14px;max-inline-size:44ch">Thirty-one lunch-sized episodes, animated demos and hands-on labs that take one fictional
        Indonesian retailer from a server next to the pantry to a governed, resilient Azure platform.</p>
      </div>
      <div>
        <h4>Learn</h4>
        <ul><li><a href="{root}index.html#episodes">All episodes</a></li><li><a href="{root}labs/index.html">Hands-on labs</a></li>
        <li><a href="{root}demos/index.html">Demo gallery</a></li><li><a href="{root}lunchbox.html">My lunchbox</a></li></ul>
      </div>
      <div>
        <h4>Repository</h4>
        <ul><li><a href="{REPO_URL}" target="_blank" rel="noopener">Source on GitHub</a></li>
        <li><a href="{REPO_URL}/blob/main/SYLLABUS.md" target="_blank" rel="noopener">Syllabus</a></li>
        <li><a href="{REPO_URL}/blob/main/COURSE-DESIGN.md" target="_blank" rel="noopener">Course design</a></li>
        <li><a href="{REPO_URL}/issues" target="_blank" rel="noopener">Report a problem</a></li></ul>
      </div>
    </div>
    <p class="fine">An independent, personal learning project — not official Microsoft training, documentation or certification material,
    and not endorsed by Microsoft. Azure changes often: check the current <a href="https://learn.microsoft.com/azure/" target="_blank" rel="noopener">Azure documentation</a>
    and pricing before relying on a detail. Microsoft, Azure and related names are trademarks of the Microsoft group of companies.
    Nusantara Retail and its people are fictional. Text and demos: <a href="{REPO_URL}/blob/main/LICENSE-CONTENT.md" target="_blank" rel="noopener">CC BY-NC-SA 4.0</a> ·
    code: <a href="{REPO_URL}/blob/main/LICENSE" target="_blank" rel="noopener">MIT</a>. Progress, badges and notes are stored only in your browser.</p>
  </div>
</footer>"""


# ============================================================================ lunch pages
def parse_quiz(md_text: str) -> list[tuple[str, str]]:
    items = re.split(r"(?m)^\d+\.\s+", md_text.strip())
    out = []
    for it in items:
        if "<details>" not in it:
            continue
        q, rest = it.split("<details>", 1)
        a = re.sub(r"(?s)^.*?</summary>", "", rest, count=1)
        a = a.split("</details>")[0]
        out.append((textwrap.dedent(q).strip(), textwrap.dedent(a).strip()))
    return out


def parse_bullets(md_text: str) -> list[str]:
    items, cur = [], None
    for line in md_text.splitlines():
        if re.match(r"^[-*] ", line):
            if cur is not None:
                items.append(cur)
            cur = line[2:].strip()
        elif cur is not None and line.startswith("  ") and line.strip():
            cur += " " + line.strip()
        elif cur is not None and not line.strip():
            items.append(cur)
            cur = None
    if cur is not None:
        items.append(cur)
    return items


def lunch_page(shell: Shell, L: dict, prev: dict | None, nxt: dict | None) -> None:
    src = REPO / "lunches" / L["slug"] / "README.md"
    out = DOCS / "lunches" / f"{L['slug']}.html"
    env = {"src": src, "out": out, "ids": {}}
    text = src.read_text(encoding="utf-8")
    parts = fence_aware_split(text, 2)
    header = parts[0][1]
    full_title = rx(r"(?m)^#\s*Lunch\s*\d+\s*·\s*(.+)$", header, L["title"])
    prereq = rx(r"\*\*Prerequisite lunches:\*\*\s*([^·\n]+)", header, "none")
    az900 = rx(r"\*\*AZ-900 skill area:\*\*\s*([^·\n]+)", header, "")

    def sec(key: str) -> str:
        for t, b in parts[1:]:
            if t and key in t:
                return trim_rules(b)
        return ""

    menu, story, reading = sec("Today's menu"), sec("Meanwhile"), sec("Reading")
    demo, quiz, take = sec("Demo"), sec("Knowledge check"), sec("Key takeaways")
    labsec = sec("Your lab")
    further, validated = strip_footer(sec("Go further"))
    part = PARTS[L["part"]]
    color = part["color"]
    n = L["n"]

    # ---------- hero
    if prev is None:
        previously = "Nothing yet. It's your first Monday at PT Nusantara Retail, and something is humming loudly next to the pantry."
        prev_label = "Previously on Nusantara Retail"
    else:
        previously = f"In Episode {prev['n']} · {prev['ep']}, {prev['outcome']}"
        prev_label = "Season 1 recap" if L["num"] == 22 else "Previously on Nusantara Retail"
    pre_nums = re.findall(r"\d{2}", prereq)
    lunches_by_n = {x["n"]: x for x in ALL}
    pre_chips = "".join(
        f'<a class="chip" href="{lunches_by_n[p]["slug"]}.html" title="{E(lunches_by_n[p]["ep"])}">↩ {p}</a>'
        for p in pre_nums if p in lunches_by_n)
    special = ""
    if L["num"] == 21:
        special = '<span class="chip ok">🏆 Season 1 finale</span>'
    elif L["num"] == 22:
        special = '<span class="chip advanced">🌊 Season 2 premiere</span>'
    elif L["num"] == 31:
        special = '<span class="chip advanced">🎬 Last episode</span>'
    lab = L["lab"]
    cost_n = len(lab["cost"])
    hero = f"""<section class="ep-hero">
  <div class="container ep-hero-grid">
    <div>
      <div class="ep-num"><span class="pill">Episode {n}</span> Season {L['season']} · {E(part['icon'])} Part {L['part']} · {E(part['name'])}</div>
      <h1>{E(L['ep'])}</h1>
      <div class="lunch-title">Lunch {n} · {E(full_title)}</div>
      <div class="chips">
        {special}<span class="chip {L['level'].lower()}">{E(L['level'])}</span>
        <span class="chip">⏱ 60-minute lunch</span>
        {f'<span class="chip">🎓 {E(az900 if az900.startswith("Beyond") else "AZ-900 · " + az900)}</span>' if az900 else ''}
        <span class="chip cost">🔬 Lab · {E(lab['time'])} · {lab['cost']}</span>
        {('<span class="chip">Builds on</span>' + pre_chips) if pre_chips else '<span class="chip ok">No prerequisites</span>'}
      </div>
      <div class="previously"><b>{E(prev_label)}</b>{E(previously)}</div>
      <div class="ctas">
        <button class="btn btn-warm" type="button" data-timer-start>🍱 Start the 60-minute lunch</button>
        <a class="btn" href="#demo">🎬 Jump to the demo</a>
        <button class="btn btn-ghost" type="button" data-finish>✓ Mark lunch finished</button>
      </div>
    </div>
    <div class="mini-art" aria-hidden="false">
      {pantry(mood_for(L['readiness']), label="The pantry server, " + ["sweating", "worried", "calmer", "happy", "relaxed"][mood_for(L['readiness'])])}
      <div class="mini-meter"><b>The director's question · {L['readiness']}% ready</b>After this episode you can say: “{E(L['answer'])}”</div>
    </div>
  </div>
</section>"""

    # ---------- reading scenes
    rparts = fence_aware_split(reading, 3)
    intro = trim_rules(rparts[0][1])
    scenes = [(t, trim_rules(b)) for t, b in rparts[1:] if t]
    scene_html, rail_scenes = [], []
    for i, (t, b) in enumerate(scenes, 1):
        sid = gh_slug(plain(t))
        env["ids"].setdefault(sid, 0)
        title_md = re.sub(r"^\d+\.\s*", "", t)
        scene_html.append(
            f'<article class="scene-card" id="{E(sid)}" data-spy><span class="scene-no">Scene {i} of {len(scenes)}</span>'
            f'<h3>{render_inline(title_md, env)}</h3><div class="prose">{render(b, env)}</div></article>')
        rail_scenes.append(f'<li class="sub" style="--sc:#1665d8"><a href="#{E(sid)}">{E(plain(title_md))}</a></li>')

    # ---------- objectives
    objs = parse_bullets(menu)
    menu_lead = rx(r"(?m)^(By the end[^\n]*)$", menu, "By the end of this lunch you will be able to:")
    obj_html = "".join(f'<li><button type="button" data-obj="{i}" aria-pressed="false" aria-label="I can do this now">✓</button>'
                       f'<span>{render_inline(o, env)}</span></li>' for i, o in enumerate(objs))

    # ---------- demo
    watch = ""
    m = re.search(r"(?s)(What to watch for:.*)$", demo)
    if m:
        watch = render(m.group(1), env)
    script_link = ""
    if (REPO / "lunches" / L["slug"] / "demo-video-script.md").exists():
        script_link = f'{REPO_URL}/blob/main/lunches/{L["slug"]}/demo-video-script.md'
    demo_title = DEMO_TITLES.get(L["slug"], "Interactive demo")

    # ---------- quiz
    qs = parse_quiz(quiz)
    q_html = []
    for i, (q, a) in enumerate(qs, 1):
        q_html.append(
            f'<article class="qcard" data-q="{i}"><div class="q"><span class="qn">Q{i}</span><div class="qtext">{render(q, env)}'
            f'<button class="btn btn-sm reveal-btn" type="button" aria-expanded="false">Reveal answer</button></div></div>'
            f'<div class="a"><div><div class="a-inner">{render(a, env)}<div class="grade"><span class="muted">Did you get it?</span>'
            f'<button class="btn btn-sm yes" type="button" data-grade="1">👍 I got it</button>'
            f'<button class="btn btn-sm no" type="button" data-grade="0">👎 Not quite</button></div></div></div></div></article>')

    # ---------- takeaways
    tks = parse_bullets(take)
    tk_html = "".join(f'<div class="tk"><p>{render_inline(t, env)}</p><button class="btn btn-sm pin" type="button" data-pin="{i}">📌 Pin to notebook</button></div>'
                      for i, t in enumerate(tks))

    # ---------- lab ticket
    lab_par = "\n".join(l for l in labsec.splitlines() if not re.match(r"^\s*[-*] ", l)).strip()

    # ---------- further reading
    fur = []
    for item in parse_bullets(further):
        mm = re.match(r"^\[([^\]]+)\]\(([^)]+)\)\s*[—–-]?\s*(.*)$", item)
        if not mm:
            continue
        href, ext = map_href(mm.group(2), env)
        dom = urlparse(href).netloc.replace("www.", "") if ext else "this course"
        tgt = ' target="_blank" rel="noopener"' if ext else ""
        desc_md = mm.group(3).strip()
        if desc_md[:1].islower():
            desc_md = desc_md[0].upper() + desc_md[1:]
        fur.append(f'<a href="{E(href)}"{tgt}><b>{E(plain(mm.group(1)))}</b><span>{render_inline(desc_md, env) if desc_md else ""}</span><small>{E(dom)} ↗</small></a>')

    # ---------- finish + teaser
    if nxt:
        teaser = (f'<div class="teaser"><b>Next episode · {nxt["n"]}</b><h4>{E(nxt["ep"])}</h4><p>{E(nxt["hook"])}</p>'
                  f'<p style="margin-top:10px"><a href="{nxt["slug"]}.html">Watch Episode {nxt["n"]} →</a></p></div>')
    else:
        fin = SERIES["finale"]
        teaser = (f'<div class="teaser"><b>Season finale</b><h4>{E(fin["ep"])}</h4><p>{E(fin["hook"])}</p>'
                  f'<p style="margin-top:10px"><a href="../labs/{fin["slug"]}.html">Take the capstone challenge →</a></p></div>')
    nav_prev = (f'<a href="{prev["slug"]}.html"><small>← Previous episode</small>{prev["n"]} · {E(prev["ep"])}</a>' if prev
                else '<a href="../index.html"><small>← Course home</small>The journey map</a>')
    nav_next = (f'<a class="next" href="{nxt["slug"]}.html"><small>Next episode →</small>{nxt["n"]} · {E(nxt["ep"])}</a>' if nxt
                else f'<a class="next" href="../labs/{SERIES["finale"]["slug"]}.html"><small>Season finale →</small>Advanced capstone challenge</a>')

    rail = f"""<aside class="rail" aria-label="Lunch clock">
      <h4>Lunch clock <span>60 min</span></h4>
      <ol>
        <li style="--sc:#e2482f"><a href="#menu">Today's menu <span class="mins">0–5</span></a></li>
        <li style="--sc:#e2482f"><a href="#story">Meanwhile…</a></li>
        <li style="--sc:#1665d8"><a href="#reading">Reading <span class="mins">5–30</span></a></li>
        {''.join(rail_scenes)}
        <li style="--sc:#7b4ff0"><a href="#demo">Demo <span class="mins">30–45</span></a></li>
        <li style="--sc:#11935a"><a href="#quiz">Knowledge check <span class="mins">45–50</span></a></li>
        <li style="--sc:#d98a00"><a href="#takeaways">Takeaways <span class="mins">50–55</span></a></li>
        <li style="--sc:#d98a00"><a href="#lab">Your lab</a></li>
        <li style="--sc:#0f9fb0"><a href="#finish">Finish <span class="mins">55–60</span></a></li>
      </ol>
      <div class="rail-foot">
        <button class="btn btn-sm btn-warm" type="button" data-timer-start>🍱 Start the lunch timer</button>
        <a class="btn btn-sm" href="../labs/{L['slug']}.html">🔬 Open Lab {n}</a>
      </div>
    </aside>"""

    main = f"""{hero}
<nav class="mobile-seg" aria-label="Sections of this lunch"><div class="container">
  <a href="#menu">🍱 Menu</a><a href="#story">🏪 Story</a><a href="#reading">📖 Reading</a><a href="#demo">🎬 Demo</a>
  <a href="#quiz">✅ Quiz</a><a href="#takeaways">🧠 Takeaways</a><a href="#lab">🔬 Lab</a><a href="#finish">🏁 Finish</a>
</div></nav>
<div class="container ep-layout">
  {rail}
  <div class="ep-main">
    <section class="block" id="menu" data-spy>
      <div class="block-head"><span class="icon">🍱</span><h2>Today's menu</h2><span class="minute">Minutes 0–5</span></div>
      <div class="menu-card">
        <h3>{E(menu_lead.rstrip(':'))}</h3>
        <ul class="objectives">{obj_html}</ul>
        <p class="hint">Tick an objective when you can really do it. Each one is worth 5 XP.</p>
      </div>
    </section>

    <section class="block" id="story" data-spy>
      <div class="story">
        {skyline()}
        <span class="tag">🏪 Meanwhile at Nusantara Retail · Episode {n}</span>
        <div class="story-body">{render(story, env)}</div>
      </div>
    </section>

    <section class="block" id="reading" data-spy>
      <div class="block-head"><span class="icon">📖</span><h2>Reading</h2><span class="minute">Minutes 5–30 · {len(scenes)} scenes</span></div>
      {f'<div class="prose intro">{render(intro, env)}</div>' if intro.strip() else ''}
      {''.join(scene_html)}
    </section>

    <section class="block" id="demo" data-spy>
      <div class="block-head"><span class="icon">🎬</span><h2>Demo</h2><span class="minute">Minutes 30–45</span></div>
      <div class="theatre">
        <div class="theatre-bar">
          <span class="live"><i></i> Interactive demo · {E(demo_title)}</span>
          <span class="tb-actions"><a class="btn btn-sm" href="../demos/{L['slug']}.html" target="_blank" rel="noopener">↗ Open in a new tab</a>
          <button class="btn btn-sm" type="button" data-fullscreen>⤢ Theatre mode</button></span>
        </div>
        <div class="theatre-frame"><iframe src="../demos/{L['slug']}.html" title="Interactive demo: {E(demo_title)}" loading="lazy"></iframe></div>
      </div>
      <div class="watch-for prose">
        <p class="muted">Press <b>▶ Play</b>, or step through with the arrow keys. Watch it to the last step to earn 30 XP.
        {f'Prefer video? Read the <a href="{script_link}" target="_blank" rel="noopener">walkthrough video script</a>.' if script_link else ''}</p>
        {watch}
      </div>
    </section>

    <section class="block" id="quiz" data-spy>
      <div class="block-head"><span class="icon">✅</span><h2>Knowledge check</h2><span class="minute">Minutes 45–50</span></div>
      <div class="quiz-head"><div class="score-ring" data-score-ring><span data-score-text>0/{len(qs)}</span></div>
        <div><b>{len(qs)} scenario questions. Honest grading.</b><p class="muted" style="margin:0" data-score-note>Answer in your head, reveal, then be honest with yourself.</p></div></div>
      <div class="qcards">{''.join(q_html)}</div>
    </section>

    <section class="block" id="takeaways" data-spy>
      <div class="block-head"><span class="icon">🧠</span><h2>Key takeaways</h2><span class="minute">Minutes 50–55</span></div>
      <div class="takeaways">{tk_html}</div>
    </section>

    <section class="block" id="lab" data-spy>
      <div class="block-head"><span class="icon">🔬</span><h2>Your lab</h2><span class="minute">Any time · your own pace</span></div>
      <div class="ticket">
        <div class="stub"><span>Lab</span><b>{n}</b><span>Admit one</span></div>
        <div class="main">
          <h3>{E(lab['title'])}</h3>
          <div class="prose">{render(lab_par, env)}</div>
          <div class="meta"><span class="chip">⏱ {E(lab['time'])}</span><span class="chip cost">{lab['cost']} {E(COST_TEXT.get(cost_n, ''))}</span>
            <span class="chip ok">✅ Works on its own</span><span class="chip">🧭 Guided or challenge mode</span></div>
          <a class="btn btn-primary" href="../labs/{L['slug']}.html">Start Lab {n} →</a>
        </div>
      </div>
    </section>

    {f'<section class="block" id="further"><div class="block-head"><span class="icon">📚</span><h2>Go further</h2></div><div class="further">{"".join(fur)}</div></section>' if fur else ''}

    <section class="block" id="finish" data-spy>
      <div class="finish">
        <div class="big-medal" aria-hidden="true">{L['badge']['icon']}</div>
        <p class="kicker" style="justify-content:center">Finish line · badge to earn</p>
        <h2>{E(L['badge']['name'])}</h2>
        <p class="muted">{E(L['badge']['desc'])}</p>
        <p><button class="btn btn-warm btn-lg" type="button" data-finish>🏁 I finished this lunch</button></p>
        <p><a href="#finish" data-undo hidden>Undo — mark as not finished</a></p>
        <p class="finish-answer">After this episode you can tell Ibu Sari: <b>“{E(L['answer'])}”</b></p>
        {teaser}
      </div>
    </section>

    <nav class="ep-nav" aria-label="Episodes">{nav_prev}{nav_next}</nav>
    <p class="validated">{f'Last validated: {E(validated)} · ' if validated else ''}<a href="{REPO_URL}/blob/main/lunches/{L['slug']}/README.md" target="_blank" rel="noopener">Read this lunch on GitHub</a> ·
      <a href="{REPO_URL}/issues" target="_blank" rel="noopener">Spotted something out of date?</a></p>
  </div>
</div>
<div class="timer" role="status" aria-live="polite"><div class="t-ring"></div><div><div class="t-time">60:00</div><div class="t-seg">Now: Scenario</div></div>
  <button class="btn btn-sm" type="button" data-timer-stop aria-label="Stop the lunch timer">■</button></div>"""
    shell.page(out=out, title=f"Episode {n} · {L['ep']} — Lunch {n}: {full_title}",
               desc=f"Lunch {n} · {full_title}. {L['hook']} A 60-minute reading, animated demo, knowledge check and a hands-on Azure lab.",
               main=main, body_attrs={"data-page": "lunch", "data-lunch": n, "style": f"--c:{color}"}, active="episodes")


# ============================================================================ lab pages
def lab_kind(title: str) -> str:
    t = title
    if re.match(r"^Task \d+", t):
        return "task"
    for key, kind in (("Challenge brief", "challenge"), ("Clean up", "cleanup"), ("Choose your mode", "mode"),
                      ("How this challenge works", "mode-info"), ("Before you start", "setup"),
                      ("Verify your work", "verify"), ("Acceptance checklist", "verify"), ("Break it and fix it", "bonus"),
                      ("Optional", "bonus"), ("Troubleshooting", "trouble"), ("Stretch goals", "stretch"),
                      ("What you'll build", "intro"), ("The brief", "intro")):
        if key in t:
            return kind
    return "other"


KIND_COLOR = {"task": "var(--c)", "bonus": "#e2482f", "verify": "#11935a", "cleanup": "#e2482f", "challenge": "#7b4ff0",
              "setup": "#1665d8", "intro": "#1665d8", "mode": "#68738c", "trouble": "#68738c", "stretch": "#d98a00"}


def lab_meta(slug: str) -> dict:
    src = REPO / "labs" / slug / "README.md"
    text = src.read_text(encoding="utf-8")
    h1 = rx(r"(?m)^#\s+(.+)$", text)
    m = re.match(r"Lab\s+(\d+)\s*·\s*(.+)", h1)
    num, title = (m.group(1), m.group(2).strip()) if m else ("32", h1.split("·", 1)[-1].strip() if "·" in h1 else h1)
    head = []
    for line in text.splitlines()[1:]:
        if line.startswith(">"):
            head.append(line[1:].strip())
        elif head and not line.strip():
            break
    header = "\n".join(head)
    return {
        "src": src, "text": text, "num": num, "title": title, "h1": h1, "header": header,
        "pairs": rx(r"\*\*Pairs with:\*\*\s*(.+)", header),
        "time": rx(r"\*\*Time:\*\*\s*([^·\n]+)", header),
        "cost": rx(r"\*\*Cost:\*\*\s*(💲+)", header, "💲"),
        "difficulty": rx(r"\*\*Difficulty:\*\*\s*([★☆]+)", header),
        "alone": rx(r"\*\*Works on its own:\*\*\s*(.+)", header),
    }


def lab_files(slug: str) -> list[tuple[str, int]]:
    base = REPO / "labs" / slug
    files = []
    for p in sorted(base.rglob("*")):
        if p.is_file() and p.name != "README.md" and "__pycache__" not in p.parts:
            files.append((p.relative_to(base).as_posix(), p.stat().st_size))
    return files


def lab_page(shell: Shell, slug: str, L: dict | None, lab_list: list[dict]) -> None:
    meta = lab_meta(slug)
    out = DOCS / "labs" / f"{slug}.html"
    env = {"src": meta["src"], "out": out, "ids": {}}
    body = meta["text"]
    # drop the H1 and the header blockquote that follows it (later blockquotes are content)
    lines = body.splitlines()
    i = next((k for k, ln in enumerate(lines) if ln.startswith("# ")), -1) + 1
    while i < len(lines) and not lines[i].strip():
        i += 1
    while i < len(lines) and lines[i].startswith(">"):
        i += 1
    rest = "\n".join(lines[i:])
    secs = fence_aware_split(rest, 2)
    pre = trim_rules(secs[0][1])
    sections = [(t, b) for t, b in secs[1:] if t]
    if sections:
        last_t, last_b = sections[-1]
        last_b, validated = strip_footer(last_b)
        sections[-1] = (last_t, last_b)
    else:
        validated = ""
    part = PARTS[L["part"]] if L else PARTS[5]
    color = part["color"]
    is_final = meta["num"] == "32"

    sec_html, rail_items, n_tasks = [], [], 0
    for t, b in sections:
        kind = lab_kind(t)
        sid = gh_slug(plain(t))
        env["ids"].setdefault(sid, 0)
        b = trim_rules(b)
        toggle, tag, title_txt = "", "", t
        mt = re.match(r"^Task (\d+)\s*·\s*(.+)$", t)
        if kind == "task" and mt:
            n_tasks += 1
            tag = f'<span class="task-tag">Task {mt.group(1)}</span>'
            title_txt = mt.group(2)
        if kind in ("task", "bonus", "verify"):
            toggle = f'<button class="btn btn-sm done-toggle" type="button" data-task="{E(sid)}" aria-pressed="false">Mark done</button>'
        extra = ""
        if kind == "cleanup":
            extra = ('<p class="cleanup-cta"><button class="btn btn-warm" type="button" data-cleanup aria-pressed="false">🧹 I ran cleanup.sh</button> '
                     '<span class="muted">Worth 25 XP — and it keeps your bill at zero.</span></p>')
        sec_html.append(
            f'<section class="lab-section" id="{E(sid)}" data-kind="{kind}"><h2>{tag}<span class="title">{render_inline(title_txt, env)}</span>{toggle}</h2>'
            f'<div class="prose wide">{render(b, env)}</div>{extra}</section>')
        label = plain(strip_emoji_prefix(t)) if kind != "task" else plain(t)
        icon = {"task": "", "bonus": "🔧 ", "verify": "🧪 ", "cleanup": "🧹 ", "challenge": "🏁 ", "setup": "✅ ", "intro": "🎯 ",
                "mode": "🧭 ", "trouble": "🩺 ", "stretch": "🚀 "}.get(kind, "")
        rail_items.append(f'<li data-kind="{kind}" style="--sc:{KIND_COLOR.get(kind, "var(--c)")}"><a href="#{E(sid)}">{icon}{E(label)}</a></li>')

    cleanup_id = next((gh_slug(plain(t)) for t, _ in sections if lab_kind(t) == "cleanup"), "")
    files = lab_files(slug)
    files_html = "".join(
        f'<li><a href="{REPO_URL}/blob/main/labs/{slug}/{quote(f)}" target="_blank" rel="noopener"><span>{E(f)}</span><small>{max(1, round(s / 1024))} KB</small></a></li>'
        for f, s in files)
    pairs_html = render_inline(meta["pairs"], env) if meta["pairs"] else ""
    alone_html = render_inline(meta["alone"], env) if meta["alone"] else ""
    cost_n = len(meta["cost"])
    idx = [x["slug"] for x in lab_list].index(slug)
    prev_l = lab_list[idx - 1] if idx > 0 else None
    next_l = lab_list[idx + 1] if idx + 1 < len(lab_list) else None
    nav_prev = (f'<a href="{prev_l["slug"]}.html"><small>← Previous lab</small>{prev_l["num"]} · {E(prev_l["title"])}</a>' if prev_l
                else '<a href="index.html"><small>← All labs</small>The lab hub</a>')
    nav_next = (f'<a class="next" href="{next_l["slug"]}.html"><small>Next lab →</small>{next_l["num"]} · {E(next_l["title"])}</a>' if next_l
                else '<a class="next" href="../lunchbox.html"><small>Done? →</small>Open your lunchbox</a>')
    story = ""
    if L:
        story = (f'<p class="lab-story">🏪 <b>Episode {L["n"]} · {E(L["ep"])}</b> — {E(L["hook"])} '
                 f'<a href="../lunches/{L["slug"]}.html">Read the lunch</a></p>')
    else:
        fin = SERIES["finale"]
        story = f'<p class="lab-story">🌟 <b>{E(fin["ep"])}</b> — {E(fin["hook"])}</p>'
    mode_switch = "" if is_final else (
        '<div class="mode-switch" role="group" aria-label="Lab mode"><button type="button" data-mode="guided" aria-pressed="true">🧭 Guided</button>'
        '<button type="button" data-mode="challenge" aria-pressed="false">🏁 Challenge</button></div>')
    hero = f"""<section class="lab-hero" style="--c:{color}">
  <div class="container">
    <p class="kicker"><span class="dot"></span>{'Season finale · capstone challenge' if is_final else f'Hands-on lab · pairs with Episode {L["n"]}'}</p>
    <div class="ticket">
      <div class="stub"><span>Lab</span><b>{meta['num']}</b><span>{'Finale' if is_final else 'Admit one'}</span></div>
      <div class="main">
        <h1 class="lab-title">{E(meta['title'])}</h1>
        {story}
        <div class="meta">
          <span class="chip">⏱ {E(meta['time'])}</span>
          <span class="chip cost">{meta['cost']} {E(COST_TEXT.get(cost_n, ''))}</span>
          {f'<span class="chip">Difficulty {E(meta["difficulty"])}</span>' if meta['difficulty'] else ''}
          <span class="chip ok">✅ Works on its own</span>
        </div>
        <div class="lab-actions">{mode_switch}<button class="btn btn-primary" type="button" data-lab-complete>🏆 Mark lab complete</button></div>
        {f'<p class="muted small">{pairs_html}</p>' if pairs_html and is_final else ''}
      </div>
    </div>
  </div>
</section>"""
    rail = f"""<aside class="rail" aria-label="Lab steps">
      <h4>Your progress <span data-task-text>0 of {sum(1 for t, _ in sections if lab_kind(t) in ('task', 'bonus', 'verify'))} tasks</span></h4>
      <div class="bar" style="margin-bottom:14px"><span data-task-bar></span></div>
      <ol>{''.join(rail_items)}</ol>
      <div class="rail-foot">
        <p class="muted small" style="margin:0">Lab files</p>
        <ul class="files">{files_html}</ul>
        <a class="btn btn-sm" href="{REPO_URL}/tree/main/labs/{slug}" target="_blank" rel="noopener">Open the folder on GitHub ↗</a>
      </div>
    </aside>"""
    main = f"""{hero}
<div class="container lab-layout">
  {rail}
  <div class="lab-main">
    {f'<div class="prose wide lab-pre">{render(pre, env)}</div>' if pre.strip() else ''}
    {f'<p class="lab-alone">{alone_html}</p>' if alone_html else ''}
    {''.join(sec_html)}
    <div class="lab-done card">
      <div><h3 style="margin:0">Finished?</h3><p class="muted" style="margin:0">Run the verify script, clean up, then claim your XP.</p></div>
      <button class="btn btn-primary" type="button" data-lab-complete>🏆 Mark lab complete</button>
    </div>
    <nav class="ep-nav" aria-label="Labs">{nav_prev}{nav_next}</nav>
    <p class="validated">{f'Last validated: {E(validated)} · ' if validated else ''}<a href="{REPO_URL}/blob/main/labs/{slug}/README.md" target="_blank" rel="noopener">Read this lab on GitHub</a> ·
      <a href="{REPO_URL}/issues" target="_blank" rel="noopener">Report a lab problem</a></p>
  </div>
</div>
<div class="cleanup-banner" role="status">🧹 Lab resources may still be running. When you are done, run <code>bash cleanup.sh</code> — <a href="#{E(cleanup_id)}">go to clean up</a>.</div>"""
    shell.page(out=out, title=f"Lab {meta['num']} · {meta['title']}",
               desc=f"Hands-on Azure lab {meta['num']}: {meta['title']}. {meta['time']}, cost {meta['cost']}. Guided steps or a challenge brief, with verify and cleanup scripts.",
               main=main, body_attrs={"data-page": "lab", "data-lab": meta["num"], "style": f"--c:{color}"}, active="labs")


# ============================================================================ hubs
def labs_hub(shell: Shell, lab_list: list[dict]) -> None:
    out = DOCS / "labs" / "index.html"
    src = REPO / "labs" / "README.md"
    env = {"src": src, "out": out, "ids": {}}
    text = src.read_text(encoding="utf-8")
    secs = {t: trim_rules(b) for t, b in fence_aware_split(text, 2) if t}
    how = render(secs.get("How the labs work", ""), env)
    env["ids"].setdefault("cost-bands", 0)
    cost = render(secs.get("Cost bands", ""), env)
    wrong = render(secs.get("When something goes wrong", ""), env)
    cards = []
    for x in lab_list:
        cost_n = len(x["cost"])
        diff = f'<span class="chip">{E(x["diff"])}</span>' if x.get("diff") else ""
        cards.append(
            f'<a class="tcard reveal" href="{x["slug"]}.html" data-n="{x["num"]}" data-cost="{cost_n}" data-part="{x["part"]}" style="--c:{PARTS[x["part"]]["color"]}">'
            f'<div class="stub"><small>Lab</small><b>{x["num"]}</b></div><div class="body"><span class="status st-new">○ Not started</span>'
            f'<h3>{E(x["title"])}</h3><p>{E(x["pairs"])}</p><div class="chips"><span class="chip">⏱ {E(x["time"])}</span>'
            f'<span class="chip cost">{x["cost"]}</span>{diff}</div></div></a>')
    part_btns = "".join(f'<button type="button" data-part-filter="{p["id"]}" aria-pressed="false">{p["icon"]} {E(p["short"])}</button>' for p in SERIES["parts"])
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>Hands-on labs · 32 tickets</p>
    <h1>Labs you can do <span class="grad-text">on your own time.</span></h1>
    <p class="lead">Every lunch comes with a lab ticket. Each lab is independent — no earlier lab needed — and runs in Azure Cloud Shell with
    the Azure CLI. Go <b>guided</b> with copy-paste steps, or flip to <b>challenge</b> mode and build it from the brief.</p>
    <div class="hub-stats stats">
      <div class="stat"><b>32</b><span>independent labs</span></div><div class="stat"><b>2</b><span>modes: guided or challenge</span></div>
      <div class="stat"><b>✓</b><span>verify script per lab</span></div><div class="stat"><b>🧹</b><span>one-command clean-up</span></div>
    </div>
  </div>
</section>
<section class="section" style="padding-top:40px">
  <div class="container">
    <div class="toolbar">
      <div class="seg-tabs" role="group" aria-label="Filter by cost"><button type="button" data-cost-filter="all" aria-pressed="true">All costs</button>
        <button type="button" data-cost-filter="1" aria-pressed="false">💲</button><button type="button" data-cost-filter="2" aria-pressed="false">💲💲</button>
        <button type="button" data-cost-filter="3" aria-pressed="false">💲💲💲</button></div>
      <div class="seg-tabs" role="group" aria-label="Filter by part"><button type="button" data-part-filter="all" aria-pressed="true">All parts</button>{part_btns}</div>
      <input class="search" type="search" placeholder="Search labs…" aria-label="Search labs" data-lab-search>
    </div>
    <div class="ticket-grid" data-ticket-grid>{''.join(cards)}</div>
  </div>
</section>
<section class="section band">
  <div class="container hub-docs">
    <article class="card doc-card"><h2>How the labs work</h2><div class="prose wide">{how}</div></article>
    <article class="card doc-card" id="cost-bands"><h2>Cost bands</h2><div class="prose wide">{cost}</div></article>
    <article class="card doc-card"><h2>When something goes wrong</h2><div class="prose wide">{wrong}</div></article>
  </div>
</section>"""
    shell.page(out=out, title="Hands-on labs", desc="32 independent Azure CLI labs with guided and challenge modes, verify scripts and one-command clean-up.",
               main=main, body_attrs={"data-page": "labs"}, active="labs")


DEMO_TITLES: dict[str, str] = {}


def load_demo_titles() -> None:
    for p in sorted((DOCS / "demos").glob("*.html")):
        if p.name == "index.html":
            continue
        t = p.read_text(encoding="utf-8")
        m = re.search(r"<h1[^>]*>(.*?)</h1>", t, re.S)
        steps = 0
        sm = re.search(r'<script type="application/json" id="demo-steps">(.*?)</script>', t, re.S)
        if sm:
            try:
                steps = len(json.loads(sm.group(1)))
            except ValueError:
                steps = 0
        DEMO_TITLES[p.stem] = html.unescape(re.sub(r"<[^>]+>", "", m.group(1)).strip()) if m else p.stem
        DEMO_STEPS[p.stem] = steps


DEMO_STEPS: dict[str, int] = {}


def demos_hub(shell: Shell, lunches: list[dict]) -> None:
    out = DOCS / "demos" / "index.html"
    cards = []
    for L in lunches:
        steps = DEMO_STEPS.get(L["slug"], 0)
        mid = max(1, (steps + 1) // 2) if steps else 1
        cards.append(
            f'<a class="dcard reveal" href="{L["slug"]}.html" data-n="{L["n"]}" data-part="{L["part"]}" style="--c:{PARTS[L["part"]]["color"]}">'
            f'<div class="dthumb"><iframe data-src="{L["slug"]}.html#step={mid}" title="Preview of the demo for Lunch {L["n"]}" tabindex="-1" aria-hidden="true" loading="lazy"></iframe>'
            f'<span class="play" aria-hidden="true">▶</span></div><div class="dbody"><small>Episode {L["n"]} · {E(PARTS[L["part"]]["short"])} · {L["level"]}</small>'
            f'<h3>{E(DEMO_TITLES.get(L["slug"], L["title"]))}</h3><p class="muted small" style="margin:.3em 0 0">{steps} steps · <span>{E(L["ep"])}</span></p></div></a>')
    part_btns = "".join(f'<button type="button" data-demo-filter="{p["id"]}" aria-pressed="false">{p["icon"]} {E(p["short"])}</button>' for p in SERIES["parts"])
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>Demo gallery · 31 animations</p>
    <h1>Watch Azure <span class="grad-text">move.</span></h1>
    <p class="lead">Each lunch has an animated, step-through demo: packets crossing a network security group, a scale set growing for the
    12.12 sale, a failover group switching regions. Press play, pause on any step, or drive it with the arrow keys. Every demo is a single
    HTML file that also works offline.</p>
  </div>
</section>
<section class="section" style="padding-top:40px">
  <div class="container">
    <div class="toolbar"><div class="seg-tabs" role="group" aria-label="Filter by part"><button type="button" data-demo-filter="all" aria-pressed="true">All parts</button>{part_btns}</div></div>
    <div class="demo-grid" data-demo-grid>{''.join(cards)}</div>
  </div>
</section>"""
    shell.page(out=out, title="Demo gallery", desc="31 animated, step-through Azure demos — one for every lunch.", main=main,
               body_attrs={"data-page": "demos"}, active="demos")


def fix_demo_footers(lunches: list[dict]) -> int:
    changed = 0
    for L in lunches:
        p = DOCS / "demos" / f"{L['slug']}.html"
        t = p.read_text(encoding="utf-8")
        new = re.sub(
            r'<p>Part of <strong>Azure Fundamentals: One Lunch at a Time</strong> · .*?</p>',
            (f'<p>Part of <strong>Azure Fundamentals: One Lunch at a Time</strong> · <a href="../lunches/{L["slug"]}.html" target="_top">Read the episode</a>'
             f' · <a href="index.html" target="_top">All demos</a> · <a href="{REPO_URL}" target="_blank" rel="noopener">Course repository</a></p>'),
            t, count=1, flags=re.S)
        if new != t:
            p.write_text(new, encoding="utf-8")
            changed += 1
    return changed


# ============================================================================ landing
def landing(shell: Shell, lunches: list[dict]) -> None:
    out = DOCS / "index.html"
    clock_items = "".join(
        f'<div class="seg-item" tabindex="0" style="--seg-color:{c}" data-min="{m}" data-name="{E(nm)}"><div class="min">{m}<small>min</small></div>'
        f'<div><h4>{E(nm)}</h4><p>{E(d)}</p></div></div>' for m, nm, d, c, _a in SEGMENTS)
    legend = "".join(f'<span><i style="background:{p["color"]}"></i>{p["icon"]} {E(p["short"])}</span>' for p in SERIES["parts"])
    cast = "".join(
        f'<div class="person reveal"><div class="avatar" style="--c:{c["color"]}">{E(c["initials"])}</div><h4>{E(c["name"])}</h4>'
        f'<div class="role">{E(c["role"])}</div><q>{E(c["quote"])}</q><p>{E(c["bio"])}</p></div>' for c in SERIES["cast"])
    cards = []
    for L in lunches:
        p = PARTS[L["part"]]
        cards.append(
            f'<a class="ep-card reveal" href="lunches/{L["slug"]}.html" data-n="{L["n"]}" style="--c:{p["color"]}"><span class="done-flag">✓ Done</span>'
            f'<div class="ep-top"><span>EP {L["n"]} · {p["icon"]} {E(p["short"])}</span><span class="state">{E(L["level"])}</span></div>'
            f'<h3>{E(L["ep"])}</h3><p class="sub">Lunch {L["n"]} · {E(L["title"])}</p><p class="hook">{E(L["hook"])}</p>'
            f'<div class="ep-foot"><span>🔬 {E(L["lab"]["time"])} · {L["lab"]["cost"]}</span><span class="medal" title="Badge: {E(L["badge"]["name"])}">{L["badge"]["icon"]}</span></div></a>')
    fin = SERIES["finale"]
    cards.append(
        f'<a class="ep-card finale reveal" href="labs/{fin["slug"]}.html" data-n="32" style="--c:#7b4ff0">'
        f'<div class="ep-top"><span>★ Season finale</span><span class="state">Capstone</span></div><h3>{E(fin["ep"])}</h3>'
        f'<p class="sub">Advanced capstone challenge</p><p class="hook">{E(fin["hook"])}</p>'
        f'<div class="ep-foot"><span>🔬 8–12 hours · 💲💲💲</span><span class="medal">{fin["badge"]["icon"]}</span></div></a>')
    s1, s2 = SERIES["seasons"]
    first = lunches[0]
    faq = [
        ("Do I need an Azure subscription?", "Not for the readings, demos and quizzes. For the labs, yes — Episode 01 walks you through the options (a free account, a pay-as-you-go subscription or a sandbox your employer provides) and sets up a budget alert before you create anything."),
        ("How much will the labs cost?", "Every lab shows a cost band: 💲 is free or close to free, 💲💲 means small charges while resources run, 💲💲💲 means noticeable charges. Every lab ends with a one-command clean-up, and the lab page reminds you if you forget. Prices vary by region, so the labs never quote numbers — use the Azure pricing calculator."),
        ("Does this prepare me for AZ-900?", "Season 1 (Episodes 01–21) covers the AZ-900 skill areas; every episode shows which skill area it belongs to. Season 2 goes deliberately beyond AZ-900 into what you need on the job: hub-and-spoke networks, Kubernetes, KQL and governance at scale."),
        ("Is this official Microsoft training?", "No. It is an independent, personal learning project, not endorsed by Microsoft. Azure changes often, so every episode links to Microsoft Learn for the details — and every page shows when it was last validated."),
        ("Where is my progress stored?", "Only in this browser (local storage). Nothing is sent anywhere. In My lunchbox you can export your progress to a file and import it on another device."),
        ("I only have 30 minutes today. Now what?", "Start the lunch timer, do the scenario and reading, and come back for the demo and quiz tomorrow. The timer and every checkbox remember where you were."),
    ]
    faq_html = "".join(f"<details><summary>{E(q)}</summary><p>{E(a)}</p></details>" for q, a in faq)
    main = f"""<section class="hero">
  <div class="container hero-grid">
    <div>
      <p class="kicker"><span class="dot"></span>A story-driven Azure course · 31 episodes · free</p>
      <h1>Learn Azure <span class="accent">one lunch</span> at a time.</h1>
      <p class="lead">PT Nusantara Retail sells to customers of forty stores through one tired server in the room next to the pantry.
      The director has asked a question nobody can answer. Over 31 lunch breaks you'll move the shop into Azure — and learn every
      fundamental service on the way: VMs, storage, networking, databases, load balancers, identity, governance and more.</p>
      <div class="ctas">
        <a class="btn btn-primary btn-lg" href="lunches/{first['slug']}.html" data-continue>▶ Start Episode 01</a>
        <a class="btn btn-lg" href="#journey">🗺 See the journey</a>
      </div>
      <div class="stats">
        <div class="stat"><b>31</b><span>lunch-sized episodes</span></div>
        <div class="stat"><b>31</b><span>animated demos</span></div>
        <div class="stat"><b>32</b><span>hands-on labs</span></div>
        <div class="stat"><b>60′</b><span>per lunch, max</span></div>
      </div>
    </div>
    <div class="scene-art" aria-label="Illustration: the pantry server, a coffee machine and the Azure cloud">
      <div class="room"></div>
      <span class="sign">Server room · do not unplug</span>
      <div class="bubble" aria-live="off"><span class="who" data-who>Ibu Sari · The director</span><span class="typed" data-typed>{E(SERIES['director']['question'])}</span></div>
      {pantry(0, 'data-mascot="progress"', "The pantry server — it gets happier as you progress")}
      {COFFEE}
      {CLOUD}
    </div>
  </div>
</section>

<section class="section" style="padding-top:20px">
  <div class="container">
    <div class="strip">
      <div class="panel reveal"><span class="num">01</span><div class="emoji">🏪</div><h3>Meet Nusantara Retail</h3>
        <p>A mid-sized Indonesian retailer: forty stores, a head office in Jakarta, and an online storefront that tripled its traffic this year.</p></div>
      <div class="panel reveal"><span class="num">02</span><div class="emoji">🔥</div><h3>One server. One pantry.</h3>
        <p>The whole shop runs on one physical server. The UPS beeps when the coffee machine starts. Backups go home on Fridays on a USB drive.</p></div>
      <div class="panel quote reveal"><span class="num">03</span><div class="emoji">❓</div><h3>“{E(SERIES['director']['question'])}”</h3>
        <p>Ibu Sari asked at last month's meeting. Nobody answered. Every episode moves your answer forward — watch the meter.</p></div>
    </div>
  </div>
</section>

<section class="section band" id="how">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>How a lunch works</p>
      <h2>Sixty minutes. Six courses. Zero filler.</h2>
      <p class="lead">Inspired by the classic “month of lunches” format: every episode fits a lunch break. Hover the clock to see what each slice holds.</p></div>
    <div class="clock-wrap">
      <div class="lunch-clock">{clock_svg()}</div>
      <div class="seg-list">{clock_items}</div>
    </div>
  </div>
</section>

<section class="section" id="journey">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>The journey</p>
      <h2>31 stations from the pantry to production.</h2>
      <p class="lead">{E(s1['blurb'])} Then Season 2: {E(s2['blurb'][0].lower() + s2['blurb'][1:])} Hover a station for the episode hook; your position is saved as you go.</p></div>
    <div class="card metro-card">
      <div class="metro-top"><div class="legend">{legend}<span><i style="background:#7b4ff0;block-size:12px;inline-size:12px;border-radius:50%"></i>★ Finale</span></div>
        <div class="metro-progress"><span data-metro-text>0 / 31 lunches</span><div class="bar"><span data-metro-bar></span></div></div></div>
      <div data-metro><ol class="metro-fallback">{''.join(f'<li><a href="lunches/{L["slug"]}.html">{L["n"]} · {E(L["ep"])}</a></li>' for L in lunches)}</ol></div>
    </div>
  </div>
</section>

<section class="section band" id="director">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>The director's question</p>
      <h2>Every episode earns you a better answer.</h2></div>
    <div class="card director">
      <div class="gauge">{gauge_svg()}</div>
      <div>
        <p class="q">Asked at last month's meeting</p>
        <blockquote>“{E(SERIES['director']['question'])}”</blockquote>
        <p class="muted" data-director-when style="margin-bottom:4px">Your answer today, before Episode 01</p>
        <p class="director-answer" data-director-answer>“{E(SERIES['director']['start'])}”</p>
        <div class="answer-log" data-answer-log aria-hidden="true"></div>
        <p class="muted small" style="margin-top:14px">By the end of Season 1 you can answer in a meeting, with numbers. By the end of Season 2 you can answer in an audit.</p>
      </div>
    </div>
  </div>
</section>

<section class="section" id="cast">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>The cast</p><h2>The same people, every lunch.</h2>
      <p class="lead">Real-world problems arrive as people with opinions. You'll learn to answer all of them.</p></div>
    <div class="cast">{cast}</div>
  </div>
</section>

<section class="section band" id="episodes">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>Episodes</p><h2>Pick up where you left off.</h2>
      <p class="lead">Season 1 is the core month (Basic). Season 2 is the deep-dive month (Advanced): topics that are too big for one lunch get a second, advanced episode.</p></div>
    <div class="toolbar">
      <div class="seg-tabs" role="group" aria-label="Filter episodes">
        <button type="button" data-filter="all" aria-pressed="true">All</button>
        <button type="button" data-filter="s1" aria-pressed="false">Season 1 · Basic</button>
        <button type="button" data-filter="s2" aria-pressed="false">Season 2 · Advanced</button>
        <button type="button" data-filter="todo" aria-pressed="false">To do</button>
        <button type="button" data-filter="done" aria-pressed="false">Finished</button>
      </div>
      <input class="search" type="search" placeholder="Search: VM, storage, KQL…" aria-label="Search episodes" data-ep-search>
    </div>
    <div class="ep-grid" data-ep-grid>{''.join(cards)}</div>
  </div>
</section>

<section class="section" id="badges">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>Trophy cabinet · <span data-badge-count>0 of 40</span></p>
      <h2>Collect a badge every lunch.</h2>
      <p class="lead">Finish an episode to earn its badge. Ace a quiz, clean up after your labs and keep a streak for the specials.
      Everything counts toward your XP and your level, from <i>Curious visitor</i> to <i>Lunch legend</i>.</p></div>
    <div class="badges" data-badges="16"></div>
    <p style="margin-top:20px"><a class="btn" href="lunchbox.html">🍱 Open my lunchbox</a></p>
  </div>
</section>

<section class="section band" id="labs">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>Hands-on labs</p><h2>Labs that respect your wallet and your calendar.</h2>
      <p class="lead">Every lab is independent, runs in Azure Cloud Shell and ends with a clean-up script. Do it the same day or next weekend.</p></div>
    <div class="cost-grid">
      <div class="card cost-card reveal"><b>💲</b><h3>Free or nearly free</h3><p>Free tiers and tiny resources. Clean up anyway — it is a good habit.</p></div>
      <div class="card cost-card reveal"><b>💲💲</b><h3>Small charges while running</h3><p>Finish in one sitting, then run <code>cleanup.sh</code>. Typically cents per hour.</p></div>
      <div class="card cost-card reveal"><b>💲💲💲</b><h3>Plan it, then delete</h3><p>Gateways, firewalls and clusters. Read the brief first and delete straight after.</p></div>
    </div>
    <div class="feature-row">
      <div class="feature"><span>🧭</span><div><b>Guided or challenge</b><p>Copy-paste steps with checkpoints — or hide them and build from the brief.</p></div></div>
      <div class="feature"><span>🧪</span><div><b>Verify scripts</b><p>Every lab ships <code>verify.sh</code>, so you know it really works.</p></div></div>
      <div class="feature"><span>🔧</span><div><b>Break it, fix it</b><p>A deliberate fault in every lab teaches you to troubleshoot.</p></div></div>
    </div>
    <p style="margin-top:24px"><a class="btn btn-primary" href="labs/index.html">Browse all 32 labs →</a></p>
  </div>
</section>

<section class="section" id="faq">
  <div class="container narrow">
    <div class="section-head"><p class="kicker"><span class="dot"></span>FAQ</p><h2>Before you grab your lunch</h2></div>
    <div class="faq">{faq_html}</div>
  </div>
</section>

<section class="cta-band">
  <div class="container">
    <div>{pantry(1, label="The pantry server, still sweating")}</div>
    <div><h2>The server is still humming. Episode 01 starts now.</h2>
      <p>Grab your lunch, open Cloud Shell, and make sure the next time someone asks “how long can't we sell?”, the answer comes from you.</p>
      <a class="btn btn-warm btn-lg" href="lunches/{first['slug']}.html" data-continue>▶ Start Episode 01</a></div>
  </div>
</section>"""
    shell.page(out=out, title=COURSE_NAME,
               desc="Learn every fundamental Azure service in 31 lunch-sized episodes: story-driven readings, animated demos, quizzes and independent hands-on labs.",
               main=main, body_attrs={"data-page": "home"}, active="")


def lunchbox(shell: Shell) -> None:
    out = DOCS / "lunchbox.html"
    s1, s2 = SERIES["seasons"]
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>My lunchbox</p>
    <h1>Your progress, badges <span class="grad-text">and notes.</span></h1>
    <p class="lead">Everything here lives only in this browser — nothing is sent anywhere. Export it to move to another device.</p>
  </div>
</section>
<div class="container lunchbox">
  <section class="card profile">
    <div class="level-badge" data-level-icon aria-hidden="true">🌱</div>
    <div><p class="kicker" style="margin-bottom:.2rem">Your level</p><h2 data-level-name style="margin:0">Curious visitor</h2>
      <div class="xpbar"><span data-xp-bar></span></div><p class="muted" style="margin:0"><b data-xp>0 XP</b> · <span data-xp-next></span></p></div>
    <div class="profile-art">{pantry(0, 'data-mascot="progress"', "The pantry server")}</div>
  </section>
  <div class="kpis">
    <div class="kpi"><b data-k-lunches>0/31</b><span>lunches finished</span></div>
    <div class="kpi"><b data-k-labs>0/32</b><span>labs complete</span></div>
    <div class="kpi"><b data-k-quiz>—</b><span>quiz accuracy</span></div>
    <div class="kpi"><b data-k-streak>0 🔥</b><span>day streak (weekends are free)</span></div>
  </div>

  <section class="lb-section">
    <h2>Seasons</h2>
    <div class="season-row"><div><b>{E(s1['name'])}</b><span class="muted">{E(s1['month'])} · Basic</span></div><div class="bar"><span data-season-bar="1-21"></span></div><b data-season-text="1-21">0 / 21</b></div>
    <div class="season-row"><div><b>{E(s2['name'])}</b><span class="muted">{E(s2['month'])} · Advanced</span></div><div class="bar"><span data-season-bar="22-31"></span></div><b data-season-text="22-31">0 / 10</b></div>
  </section>

  <section class="lb-section">
    <h2>The director's question</h2>
    <div class="card director">
      <div class="gauge">{gauge_svg()}</div>
      <div><p class="q">“{E(SERIES['director']['question'])}”</p>
        <p class="muted" data-director-when style="margin-bottom:4px">Your answer today, before Episode 01</p>
        <p class="director-answer" data-director-answer>“{E(SERIES['director']['start'])}”</p>
        <div class="answer-log" data-answer-log aria-hidden="true"></div></div>
    </div>
  </section>

  <section class="lb-section">
    <h2>Trophy cabinet <span class="muted" style="font-size:1rem" data-badge-count></span></h2>
    <div class="badges" data-badges></div>
  </section>

  <section class="lb-section">
    <div class="lb-head"><h2>My notebook</h2><div class="chips"><button class="btn btn-sm" type="button" data-notes-copy>📋 Copy as Markdown</button>
      <button class="btn btn-sm" type="button" data-notes-download>⬇ Download .md</button></div></div>
    <div class="notebook" data-notebook></div>
  </section>

  <section class="lb-section">
    <div class="lb-head"><h2>Certificate</h2><div class="chips"><input class="search" type="text" maxlength="60" placeholder="Your name for the certificate" aria-label="Your name for the certificate" data-cert-name>
      <button class="btn btn-sm" type="button" data-cert-print>🖨 Print or save as PDF</button></div></div>
    <div class="cert">
      <div class="c-kick">Azure Fundamentals · One Lunch at a Time</div>
      <h2 data-c-title>Certificate of Progress</h2>
      <p>This certifies that</p>
      <div class="c-name" data-c-name>Your name here</div>
      <p data-c-body>has started Azure Fundamentals: One Lunch at a Time.</p>
      <div class="c-medals" data-c-medals>🍱</div>
      <div class="c-foot"><div><b>Date</b><br><span data-c-date></span></div>
        <div style="text-align:end"><b>Ibu Sari</b><br>Director, PT Nusantara Retail (fictional)</div></div>
      <p class="cert-fine">A just-for-fun progress certificate from a self-study course. It is not a Microsoft certification.</p>
    </div>
  </section>

  <section class="lb-section">
    <h2>Your data</h2>
    <div class="chips"><button class="btn btn-sm" type="button" data-export>⬇ Export progress</button>
      <label class="btn btn-sm">⬆ Import progress<input type="file" accept="application/json,.json" data-import hidden></label>
      <button class="btn btn-sm btn-ghost" type="button" data-reset>Reset everything</button></div>
  </section>
</div>"""
    shell.page(out=out, title="My lunchbox", desc="Your XP, level, badges, notebook and certificate for Azure Fundamentals: One Lunch at a Time.",
               main=main, body_attrs={"data-page": "lunchbox"}, active="lunchbox")


def not_found(shell: Shell) -> None:
    out = DOCS / "404.html"
    main = f"""<section class="lost"><div>
  {pantry(0, label="The pantry server, overheating")}
  <h1>This page went down with the pantry server.</h1>
  <p class="lead" style="margin-inline:auto">Nobody knows how long it will take to come back. (That is exactly the problem Episode 01 starts to fix.)</p>
  <p><a class="btn btn-primary" href="{PAGES}/index.html">🏠 Back to the course</a> <a class="btn" href="{PAGES}/labs/index.html">🔬 All labs</a></p>
</div></section>"""
    shell.page(out=out, title="Page not found", desc="This page does not exist.", main=main, body_attrs={"data-page": "404"},
               root=PAGES + "/")


# ============================================================================ social card
def social_card() -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("  (Pillow not installed: skipped social-card.png)")
        return
    W, H = 1200, 630
    img = Image.new("RGB", (W, H), "#fbf7f1")
    d = ImageDraw.Draw(img)
    stops = [(0, (22, 101, 216)), (0.5, (123, 79, 240)), (1, (226, 72, 47))]
    for x in range(W):
        t = x / (W - 1)
        for (a, ca), (b, cb) in zip(stops, stops[1:]):
            if a <= t <= b:
                k = (t - a) / (b - a)
                col = tuple(int(ca[i] + (cb[i] - ca[i]) * k) for i in range(3))
                d.line([(x, 0), (x, 14)], fill=col)
                d.line([(x, H - 14), (x, H)], fill=col)
                break

    def font(size, bold=True):
        try:
            import matplotlib
            base = Path(matplotlib.get_data_path()) / "fonts" / "ttf"
            return ImageFont.truetype(str(base / ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf")), size)
        except Exception:
            return ImageFont.load_default()

    d.rounded_rectangle([70, 150, 270, 330], radius=34, fill="#e2482f")
    d.rounded_rectangle([88, 168, 172, 312], radius=22, fill="#fff6e8")
    d.rounded_rectangle([184, 168, 252, 232], radius=18, fill="#ffc14a")
    d.rounded_rectangle([184, 246, 252, 312], radius=18, fill="#45cf8c")
    d.ellipse([100, 236, 132, 268], fill="#1665d8")
    d.ellipse([118, 222, 156, 260], fill="#1665d8")
    d.rectangle([108, 250, 158, 268], fill="#1665d8")
    d.text((320, 140), "Azure Fundamentals", font=font(40, False), fill="#68738c")
    d.text((320, 190), "One Lunch at a Time", font=font(72), fill="#16203a")
    line, size = "31 lunch-sized episodes · animated demos · hands-on labs", 30
    while size > 18 and d.textlength(line, font=font(size, False)) > W - 320 - 50:
        size -= 1
    d.text((320, 292), line, font=font(size, False), fill="#3b4763")
    d.text((320, 340), "Move one tired pantry server into Azure — and learn every", font=font(28, False), fill="#3b4763")
    d.text((320, 378), "fundamental service on the way.", font=font(28, False), fill="#3b4763")
    chips = ["VMs", "Storage", "Networking", "Databases", "Load balancing", "Identity", "Governance"]
    x = 320
    for c in chips:
        w = d.textlength(c, font=font(24)) + 36
        if x + w > W - 60:
            break
        d.rounded_rectangle([x, 450, x + w, 496], radius=23, fill="#e6f0ff")
        d.text((x + 18, 459), c, font=font(24), fill="#1665d8")
        x += w + 12
    site = PAGES.split("://", 1)[-1]
    d.text((70, 560), site if PLACEHOLDER not in PAGES else "github.com", font=font(22, False), fill="#68738c")
    img.save(DOCS / "assets" / "social-card.png", optimize=True)


# ============================================================================ main
ALL: list[dict] = []


def main() -> int:
    global ALL
    if PLACEHOLDER in PAGES:
        print("Note: links still use the placeholder user name (run tools/set_github_username.py first).")
    lunches = course_lunches()
    ALL = lunches
    (DOCS / "assets").mkdir(parents=True, exist_ok=True)
    (DOCS / "assets" / "favicon.svg").write_text(FAVICON, encoding="utf-8")
    write_course_data(lunches)
    load_demo_titles()
    social_card()
    shell = Shell()
    for i, L in enumerate(lunches):
        lunch_page(shell, L, lunches[i - 1] if i else None, lunches[i + 1] if i + 1 < len(lunches) else None)
    lab_list = []
    by_slug = {L["slug"]: L for L in lunches}
    for slug in [L["slug"] for L in lunches] + [bi.CAPSTONE[0]]:
        m = lab_meta(slug)
        L = by_slug.get(slug)
        lab_list.append({"slug": slug, "num": m["num"], "title": m["title"], "time": m["time"], "cost": m["cost"],
                         "part": L["part"] if L else 5, "diff": m["difficulty"],
                         "pairs": f"Episode {L['n']} · {L['ep']}" if L else "Season finale · requirements only"})
    for x in lab_list:
        lab_page(shell, x["slug"], by_slug.get(x["slug"]), lab_list)
    labs_hub(shell, lab_list)
    demos_hub(shell, lunches)
    changed = fix_demo_footers(lunches)
    landing(shell, lunches)
    lunchbox(shell)
    not_found(shell)
    n_pages = len(list(DOCS.rglob("*.html")))
    print(f"Built the site: {len(lunches)} episode pages, {len(lab_list)} lab pages, hubs, lunchbox and 404 "
          f"({n_pages} HTML files in docs/; demo footers updated: {changed}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
