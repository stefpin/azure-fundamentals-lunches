#!/usr/bin/env python3
"""Build the bilingual GitHub Pages site in docs/ from the Markdown course (English + Bahasa Indonesia).

    pip install -r tools/requirements-site.txt      # markdown-it-py (Pillow and matplotlib are optional)
    python3 tools/build_site.py

Inputs (edit these, then rebuild):
  lunches/*/README.md + README.id.md     the readings     -> docs/<lang>/lunches/<slug>.html  (episode pages)
  labs/*/README.md + README.id.md        the lab guides   -> docs/<lang>/labs/<slug>.html     (lab pages)
  labs/README.md + README.id.md          how labs work    -> docs/<lang>/labs/index.html
  docs/demos/*.html                      animated demos (shared by both languages; ?lang=id switches the words)
  tools/i18n/demos/*.id.json             Indonesian demo narration (embedded into the demos by this build)
  tools/site/series.json, series.id.json story layer: episode titles, hooks, badges, cast, levels
  tools/site/strings.py                  interface text in both languages and the author details
  tools/site/site-config.json            optional settings, e.g. {"goatcounter": "<code>"} for the visitor counter
  tools/build_index.py                   course structure (numbers, slugs, titles, parts)

Hand-written (not generated): docs/assets/site.css, docs/assets/site.js.
Generated: docs/index.html (language chooser), docs/en/**, docs/id/** (pages and LinkedIn share pages),
docs/404.html, redirect pages at the pre-2026-10-24 paths (docs/lunches, docs/labs, docs/lunchbox.html,
docs/demos/index.html), docs/assets/course-data.<lang>.js, docs/assets/favicon.svg and, if Pillow is installed,
docs/assets/social-card.png and social-card-id.png.
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
sys.path.insert(0, str(TOOLS / "site"))
sys.path.insert(0, str(TOOLS / "i18n"))
import build_index as bi  # noqa: E402  (course structure lives there)
import strings as ST  # noqa: E402  (interface text in both languages)

PAGES = bi.PAGES.rstrip("/")
REPO_URL = bi.GITHUB.split("/blob/")[0]
E = html.escape


def EC(text: str) -> str:
    """Escape text and show `code` spans from Markdown header fields as <code>."""
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", E(text))


def short_time(text: str) -> str:
    """'about 60 minutes (including ...)' -> 'about 60 minutes' for small cards."""
    return re.split(r"\s\(|,|;|\s(?:including|termasuk)\b", text.replace("`", ""))[0].strip().rstrip(".")


PLACEHOLDER = "YOUR-" + "GITHUB-USERNAME"   # split so tools/set_github_username.py leaves this line alone
LANGS = ("en", "id")
OTHER = {"en": "id", "id": "en"}
AUTHOR = ST.AUTHOR


def _load_series(lang: str) -> dict:
    p = TOOLS / "site" / ("series.json" if lang == "en" else f"series.{lang}.json")
    if not p.exists():
        p = TOOLS / "site" / "series.json"
    return json.loads(p.read_text(encoding="utf-8"))


SERIES_BY = {lang: _load_series(lang) for lang in LANGS}
_CFG = TOOLS / "site" / "site-config.json"
CONFIG = json.loads(_CFG.read_text(encoding="utf-8")) if _CFG.exists() else {}
GOAT = re.sub(r"[^a-z0-9-]", "", str(CONFIG.get("goatcounter", "")).strip().lower())

# ---- current language (set_lang switches all of these) ----
LANG = "en"
T: dict = ST.EN
SERIES: dict = SERIES_BY["en"]
PARTS: dict = {p["id"]: p for p in SERIES["parts"]}
OUT = DOCS / "en"
COURSE_NAME = T["course"]
FALLBACKS: set[str] = set()

# Lunch clock: (minutes, colour, anchor); names and descriptions come from strings.py
SEGMENT_META = [(5, "#e2482f", "#menu"), (25, "#1665d8", "#reading"), (15, "#7b4ff0", "#demo"), (5, "#11935a", "#quiz"),
                (5, "#d98a00", "#takeaways"), (5, "#0f9fb0", "#finish")]


def set_lang(lang: str) -> None:
    global LANG, T, SERIES, PARTS, OUT, COURSE_NAME
    LANG, T = lang, ST.STRINGS[lang]
    SERIES = SERIES_BY[lang]
    PARTS = {p["id"]: p for p in SERIES["parts"]}
    OUT = DOCS / lang
    COURSE_NAME = T["course"]


def tr(key: str, **kw) -> str:
    v = T[key]
    return v.format(**kw) if kw else v


def lang_src(p: Path) -> Path:
    """The current language's twin of an English Markdown file (README.md -> README.id.md), else the English file."""
    if LANG == "en":
        return p
    q = p.with_name(p.name[:-3] + f".{LANG}.md")
    if q.exists():
        return q
    if p.exists():
        FALLBACKS.add(p.relative_to(REPO).as_posix())
    return p


def segments() -> list[tuple]:
    return [(m, nm, d, c, a) for (m, c, a), (nm, d) in zip(SEGMENT_META, T["segments"])]


def level_label(level: str) -> str:
    return tr("level_basic") if level.lower().startswith("basic") else tr("level_advanced")


def cost_text(n: int) -> str:
    return T.get(f"cost_{n}", "")


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


def is_lang_line(line: str) -> bool:
    return line.lstrip().startswith(("🇬🇧", "🇮🇩"))


def strip_footer(body: str) -> tuple[str, str]:
    """Remove the Markdown page footer (nav line, language line, <sub>Last validated…</sub>); return (body, validated)."""
    validated = ""
    keep = []
    for line in body.splitlines():
        st = line.strip()
        m = re.search(r"(?:Last validated|Terakhir divalidasi):\s*([^·<]+)", st)
        if st.startswith("<sub>") and m:
            validated = m.group(1).strip()
            continue
        if st.startswith(("⬅️", "🏠")) or ("🏠" in st and "](" in st) or is_lang_line(st):
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


def write(path: Path, text: str) -> None:
    """Write a generated file, retrying once on a flaky network drive."""
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        path.write_text(text, encoding="utf-8")
    except OSError:
        import time
        time.sleep(1.5)
        path.write_text(text, encoding="utf-8")


# ============================================================================ markdown
CALLOUT_ICONS = {"note": "ℹ️", "tip": "💡", "important": "❗", "warning": "⚠️", "caution": "🛑"}
THINK_LABELS = ("**Pause and think:**", "**Renungkan sejenak:**")
CHECKPOINTS = ("✅ **Checkpoint", "✅ **Pemeriksaan")
LANG_LABEL = {"bash": "bash", "sh": "shell", "shell": "shell", "console": "console", "json": "json", "jsonc": "json",
              "yaml": "yaml", "yml": "yaml", "bicep": "bicep", "kql": "KQL", "kusto": "KQL", "sql": "SQL",
              "tsql": "T-SQL", "python": "python", "py": "python", "powershell": "PowerShell", "ps1": "PowerShell",
              "text": "text", "txt": "text", "dockerfile": "Dockerfile", "html": "html", "javascript": "javascript",
              "js": "javascript", "ini": "ini", "csv": "csv", "http": "http", "xml": "xml"}
AUTHOR_ANCHORS = {"about-the-author", "tentang-penulis"}


@functools.lru_cache(maxsize=None)
def _is_dir(p: Path) -> bool:
    return p.is_dir()


@functools.lru_cache(maxsize=None)
def _exists(p: Path) -> bool:
    return p.exists()


def page_for(target: Path) -> Path | None:
    """Map a repository file to the generated page (in the current language) that represents it."""
    try:
        target.relative_to(REPO)
    except ValueError:
        return None
    if _is_dir(target):
        if _exists(target / "README.md"):
            target = target / "README.md"
        else:
            return None
    base = re.sub(r"\.[a-z]{2}\.md$", ".md", target.name)
    if base == "README.md":
        parent = target.parent
        if parent == REPO:
            return OUT / "index.html"
        if parent == REPO / "labs":
            return OUT / "labs" / "index.html"
        if parent.parent == REPO / "lunches":
            return OUT / "lunches" / f"{parent.name}.html"
        if parent.parent == REPO / "labs" and parent.name != "common":
            return OUT / "labs" / f"{parent.name}.html"
    try:
        target.relative_to(DOCS)
        return target
    except ValueError:
        return None


def lang_query() -> str:
    return "" if LANG == "en" else f"?lang={LANG}"


def map_href(href: str, env: dict) -> tuple[str, bool]:
    """Return (new_href, is_external)."""
    if not href or href.startswith(("#", "mailto:", "javascript:")):
        return href, False
    out_dir = env["out"].parent
    if href.startswith(PAGES):
        rest = href[len(PAGES):].lstrip("/")
        path, _, frag = rest.partition("#")
        path, _, query = path.partition("?")
        if path.startswith("demos/") and path not in ("demos/", "demos/index.html"):
            target = DOCS / path
            if LANG != "en" and "lang=" not in query:
                query = (query + "&" if query else "") + f"lang={LANG}"
        elif re.match(r"^(en|id)(/|$)", path) or path.startswith("assets/"):
            target = DOCS / (path + ("index.html" if path.endswith("/") or path in ("en", "id") else ""))
        else:
            target = OUT / ((path + "index.html") if (not path or path.endswith("/")) else path)
        return rel_url(target, out_dir) + (f"?{query}" if query else "") + (f"#{frag}" if frag else ""), False
    if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", href):
        return href, True
    path, _, frag = href.partition("#")
    target = Path(os.path.normpath(env["src"].parent / unquote(path))) if path else env["src"]
    page = page_for(target)
    if page is not None:
        if page == OUT / "index.html" and frag in AUTHOR_ANCHORS:
            frag = "author"
        q = lang_query() if page.parent == DOCS / "demos" and page.name != "index.html" else ""
        return rel_url(page, out_dir) + q + (f"#{frag}" if frag else ""), False
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
                title, icon = tr(f"callout_{kind}"), CALLOUT_ICONS[kind]
                ch = inl.children or []
                if ch and ch[0].type == "text":
                    ch[0].content = re.sub(r"^\[!\w+\]\s*", "", ch[0].content)
                while ch and ((ch[0].type == "text" and not ch[0].content.strip()) or ch[0].type in ("softbreak", "hardbreak")):
                    ch.pop(0)
                rest = inl.content[m.end():].lstrip()
                if kind == "note" and rest.startswith(THINK_LABELS):
                    kind, title, icon = "think", tr("callout_think"), "💭"
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
            elif inl.content.startswith(CHECKPOINTS):
                t.tag = toks[close].tag = "div"
                t.attrSet("class", "checkpoint")


def r_fence(self, tokens, idx, options, env):
    tok = tokens[idx]
    info = tok.info.strip().split()[0].lower() if tok.info and tok.info.strip() else ""
    code = tok.content
    if info == "mermaid":
        return ('<figure class="diagram"><pre class="mermaid">' + E(code) + "</pre>"
                f'<button class="btn btn-sm zoom-btn" type="button" aria-label="{E(tr("zoom_label"))}">{E(tr("zoom"))}</button></figure>\n')
    label = LANG_LABEL.get(info, info or "text")
    return (f'<div class="code" data-lang="{E(info)}"><div class="code-head"><span><span class="dots"><i></i><i></i><i></i></span>'
            f'{E(label)}</span><button class="copy-btn" type="button">{E(tr("copy"))}</button></div><pre><code>{E(code)}</code></pre></div>\n')


def r_code_block(self, tokens, idx, options, env):
    code = tokens[idx].content
    return (f'<div class="code" data-lang=""><div class="code-head"><span><span class="dots"><i></i><i></i><i></i></span>text</span>'
            f'<button class="copy-btn" type="button">{E(tr("copy"))}</button></div><pre><code>{E(code)}</code></pre></div>\n')


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
    a = f' <a class="h-anchor" href="#{E(hid)}" aria-label="{E(tr("anchor_label"))}">#</a>' if hid else ""
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


def pantry(mood: int = 0, extra: str = "", label: str | None = None) -> str:
    label = label or tr("pantry")
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
    for i, (mins, name, _d, color, _a) in enumerate(segments()):
        length = circ * mins / 60
        gap = 5
        segs.append(f'<circle class="seg" cx="{cx}" cy="{cx}" r="{r}" fill="none" stroke="{color}" stroke-width="58" '
                    f'stroke-dasharray="{length - gap:.2f} {circ - length + gap:.2f}" stroke-dashoffset="{-start:.2f}">'
                    f'<title>{E(name)} · {mins} {E(tr("clock_min"))}</title></circle>')
        start += length
    ticks = ""
    for m, a in [(0, 0), (15, 90), (30, 180), (45, 270)]:
        tx = cx + 186 * math.sin(math.radians(a))
        ty = cx - 186 * math.cos(math.radians(a)) + 5
        ticks += (f'<text x="{tx:.1f}" y="{ty:.1f}" text-anchor="middle" font-size="13" font-weight="800" '
                  f'fill="currentColor" opacity=".55">{m}</text>')
    return (f'<svg viewBox="0 0 400 400" role="img" aria-label="{E(tr("clock_label"))}">' + f'<g transform="rotate(-90 {cx} {cx})">' + "".join(segs) + "</g>" + ticks +
            f'<circle cx="{cx}" cy="{cx}" r="104" fill="var(--surface)"/>'
            f'<text class="center-label" x="{cx}" y="{cx + 4}" text-anchor="middle" font-size="46" fill="currentColor" data-clock-label>{E(tr("clock_center"))}</text>'
            f'<text x="{cx}" y="{cx + 34}" text-anchor="middle" font-size="15" font-weight="700" fill="currentColor" opacity=".6" data-clock-sub>{E(tr("clock_sub"))}</text></svg>')


def gauge_svg() -> str:
    return (f'<svg viewBox="0 0 300 205" role="img" aria-label="{E(tr("gauge_label"))}" data-gauge>'
            '<defs><linearGradient id="gaugeGrad" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e2482f"/>'
            '<stop offset=".5" stop-color="#f2a007"/><stop offset="1" stop-color="#11935a"/></linearGradient></defs>'
            '<path class="track" d="M30 150A120 120 0 0 1 270 150"/><path class="fill" d="M30 150A120 120 0 0 1 270 150"/>'
            '<g class="needle" style="transform:rotate(-90deg)"><path d="M146 150L150 52L154 150z" style="fill:var(--ink)"/>'
            '<circle cx="150" cy="150" r="11" style="fill:var(--ink)"/><circle cx="150" cy="150" r="4" style="fill:var(--surface)"/></g>'
            '<text class="pct" x="150" y="198" text-anchor="middle">0%</text>'
            f'<text class="pct-l" x="34" y="176" text-anchor="middle">{E(tr("gauge_low"))}</text>'
            f'<text class="pct-l" x="266" y="176" text-anchor="middle">{E(tr("gauge_high"))}</text></svg>')


def mood_for(pct: int) -> int:
    return 0 if pct < 10 else 1 if pct < 35 else 2 if pct < 60 else 3 if pct < 90 else 4


# ============================================================================ course data
def lab_info_lang(slug: str, lt: str, ltime: str, lcost: str) -> tuple[str, str, str]:
    title, time, cost = bi.lab_info(slug, lt, ltime, lcost)
    if LANG == "en":
        return title, time, cost
    p = lang_src(REPO / "labs" / slug / "README.md")
    if p.name == "README.md":
        return title, time, cost
    text = p.read_text(encoding="utf-8")
    m = re.search(r"(?m)^#\s*Lab\s*\d+\s*·\s*(.+?)\s*$", text) or re.search(r"(?m)^#\s*[^·\n]+·\s*(.+?)\s*$", text)
    if m:
        title = m.group(1).strip()
    m = re.search(r"\*\*Waktu:\*\*\s*([^·\n|]+)", text)
    if m:
        time = re.split(r"\s\(|,|;|\stermasuk\b", m.group(1).strip())[0].strip().rstrip(".")
    return title, time, cost


def lunch_title(slug: str, default: str) -> str:
    if LANG == "en":
        return default
    p = lang_src(REPO / "lunches" / slug / "README.md")
    m = re.search(r"(?m)^#\s*(?:Lunch|Makan Siang)\s*\d+\s*·\s*(.+?)\s*$", p.read_text(encoding="utf-8"))
    if not m:
        return default
    title = m.group(1).strip()
    if not default.endswith(")"):  # the English card titles leave out "(Basic)" / "(Advanced)"; so do the Indonesian ones
        title = re.sub(r"\s*\((?:Dasar|Lanjutan)\)$", "", title)
    return title


def course_lunches() -> list[dict]:
    out = []
    for (n, slug, title, level, part, lt, ltime, lcost) in bi.LUNCHES:
        ep = SERIES["episodes"][f"{n:02d}"]
        ltitle, ltime2, lcost2 = lab_info_lang(slug, lt, ltime, lcost)
        out.append({
            "n": f"{n:02d}", "num": n, "slug": slug, "title": lunch_title(slug, title), "level": level_label(level),
            "level_key": "basic" if level.lower().startswith("basic") else "advanced", "part": part,
            "season": 1 if n <= 21 else 2, "ep": ep["ep"], "station": ep["station"], "hook": ep["hook"],
            "outcome": ep["outcome"], "badge": ep["badge"], "answer": ep["answer"], "readiness": ep["readiness"],
            "lab": {"title": ltitle, "time": ltime2, "cost": lcost2},
        })
    return out


def write_course_data(lunches: list[dict]) -> None:
    keep = ("n", "slug", "title", "level", "part", "ep", "station", "hook", "badge", "answer", "readiness", "lab")
    data = {
        "lang": LANG, "title": SERIES["title"], "lunches": [{k: l[k] for k in keep} for l in lunches],
        "parts": SERIES["parts"], "seasons": SERIES["seasons"], "cast": SERIES["cast"], "levels": SERIES["levels"],
        "specialBadges": SERIES["specialBadges"], "director": SERIES["director"], "finale": SERIES["finale"],
        "ui": ST.JS[LANG], "pages": PAGES, "goat": GOAT,
        "author": {"name": AUTHOR["name"], "linkedin": AUTHOR["linkedin"][LANG]},
    }
    js = ("/* Generated by tools/build_site.py from tools/site/series*.json, tools/site/strings.py and the course structure. "
          "Do not edit. */\nwindow.COURSE = " + json.dumps(data, ensure_ascii=False, indent=1) + ";\n")
    write(DOCS / "assets" / f"course-data.{LANG}.js", js)


# ============================================================================ page shell
def avatar(cls: str = "avatar-sp") -> str:
    if AUTHOR.get("photo"):
        return f'<img class="{cls}" src="{PAGES}/assets/{E(AUTHOR["photo"])}" alt="" width="48" height="48">'
    return f'<span class="{cls}" aria-hidden="true">{E(AUTHOR["initials"])}</span>'


class Shell:
    def __init__(self):
        a = DOCS / "assets"
        self.v = short_hash(a / "site.css", a / "site.js", a / "course-data.en.js", a / "course-data.id.js")

    def page(self, *, out: Path, title: str, desc: str, main: str, body_attrs: dict | None = None, active: str = "",
             absolute: bool = False, og_title: str | None = None, crumbs: list | None = None) -> None:
        if absolute:
            root, base = f"{PAGES}/{LANG}/", f"{PAGES}/"
            rel = ""
        else:
            root = rel_url(OUT, out.parent)
            root = "" if root == "." else root + "/"
            base = rel_url(DOCS, out.parent) + "/"
            rel = rel_url(out, OUT)
        page_rel = rel.replace("index.html", "")
        url = f"{PAGES}/{LANG}/{page_rel}"
        alt = OTHER[LANG]
        alt_href = f"{PAGES}/{alt}/" if absolute else rel_url(DOCS / alt / rel, out.parent)
        attrs = {"data-root": root, "data-base": base, "data-lang": LANG}
        attrs.update(body_attrs or {})
        battrs = " ".join(f'{k}="{E(str(v))}"' for k, v in attrs.items())
        nav = [("index.html#journey", tr("nav_journey"), "journey"), ("index.html#episodes", tr("nav_episodes"), "episodes"),
               ("labs/index.html", tr("nav_labs"), "labs"), ("demos/index.html", tr("nav_demos"), "demos"),
               ("lunchbox.html", tr("nav_lunchbox"), "lunchbox")]
        cur = ' aria-current="page"'
        nav_html = "".join(f'<a href="{root}{h}"{cur if k == active else ""}>{E(t)}</a>' for h, t, k in nav)
        nav_html += f'<a href="{REPO_URL}" target="_blank" rel="noopener">GitHub ↗</a>'
        full_title = title if title.endswith(COURSE_NAME) else f"{title} · {COURSE_NAME}"
        card = f"{PAGES}/assets/social-card{'' if LANG == 'en' else '-' + LANG}.png"
        alternates = "".join(f'<link rel="alternate" hreflang="{l}" href="{PAGES}/{l}/{page_rel}">\n' for l in LANGS)
        alternates += f'<link rel="alternate" hreflang="x-default" href="{PAGES}/en/{page_rel}">\n'
        if absolute:
            alternates = ""
        goat = (f'<script data-goatcounter="https://{GOAT}.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>\n'
                if GOAT and not absolute else "")
        level0 = SERIES["levels"][0]["name"]
        crumbs_html = self.crumb_trail(crumbs, root, url, absolute) if crumbs else ""
        doc = f"""<!DOCTYPE html>
<html lang="{T['html_lang']}" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{E(full_title)}</title>
<meta name="description" content="{E(desc)}">
<meta name="author" content="{E(AUTHOR['name'])}">
<meta name="theme-color" content="#1665d8">
{'' if absolute else f'<link rel="canonical" href="{url}">'}
{alternates}<meta property="og:type" content="website">
<meta property="og:site_name" content="{E(COURSE_NAME)}">
<meta property="og:title" content="{E(og_title or title)}">
<meta property="og:description" content="{E(desc)}">
<meta property="og:url" content="{E(url)}">
<meta property="og:locale" content="{T['og_locale']}">
<meta property="og:locale:alternate" content="{ST.STRINGS[alt]['og_locale']}">
<meta property="og:image" content="{card}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="{base}assets/favicon.svg" type="image/svg+xml">
<script>(function(){{var d=document.documentElement;d.classList.add('js');try{{var t=localStorage.getItem('azlunch.theme');if(!t)t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';d.setAttribute('data-theme',t);}}catch(e){{}}}})();</script>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="{base}assets/site.css?v={self.v}">
{goat}</head>
<body {battrs}>
<a class="skip" href="#main">{E(tr('skip'))}</a>
<div class="read-progress" aria-hidden="true"><span></span></div>
<header class="site-header">
  <div class="container">
    <a class="brand" href="{root}index.html">{LOGO}<span>{E(tr('brand_main'))}<small>{E(tr('brand_small'))}</small></span></a>
    <nav class="nav-links" id="site-nav" aria-label="{E(tr('nav_main'))}">{nav_html}</nav>
    <div class="hud">
      <a class="hud-pill" href="{root}lunchbox.html" data-hud-title title="{E(tr('hud_title'))}"><span class="ring" data-hud-ring></span><span class="hud-text" data-hud-text>0 XP · {E(level0)}</span></a>
      <a class="lang-switch" href="{alt_href}" hreflang="{alt}" lang="{alt}" data-lang-switch="{alt}" title="{E(tr('switch_to'))}" aria-label="{E(tr('switch_to'))}"><span aria-hidden="true">🌐</span>{ST.STRINGS[alt]['lang_short']}</a>
      <button class="icon-btn" type="button" data-theme-toggle aria-label="{E(tr('theme_toggle'))}">🌙</button>
      <button class="icon-btn menu-toggle" type="button" data-menu-toggle aria-controls="site-nav" aria-expanded="false" aria-label="{E(tr('menu_open'))}">☰</button>
    </div>
  </div>
</header>
<main id="main">
{crumbs_html}{main}
</main>
{self.footer(root, base)}
<script src="{base}assets/course-data.{LANG}.js?v={self.v}" defer></script>
<script src="{base}assets/site.js?v={self.v}" defer></script>
</body>
</html>
"""
        write(out, doc)

    @staticmethod
    def crumb_trail(items: list, root: str, url: str, absolute: bool) -> str:
        """Breadcrumb [(label, href relative to the language root, or None for this page), ...] + schema.org data."""
        lis, data = [], []
        for i, (label, href) in enumerate(items, 1):
            if href is None:
                lis.append(f'<li aria-current="page"><span>{E(label)}</span></li>')
                data.append({"@type": "ListItem", "position": i, "name": label, "item": url})
            else:
                icon = '<span class="crumb-home" aria-hidden="true">🏠</span>' if i == 1 else ""
                lis.append(f'<li><a href="{root}{href}">{icon}{E(label)}</a></li>')
                full = re.sub(r"index\.html(?=$|#)", "", f"{PAGES}/{LANG}/{href}")
                data.append({"@type": "ListItem", "position": i, "name": label, "item": full})
        nav = (f'<nav class="crumbs" aria-label="{E(tr("crumbs_label"))}"><div class="container"><ol>'
               + "".join(lis) + "</ol></div></nav>\n")
        if absolute:
            return nav
        ld = json.dumps({"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": data},
                        ensure_ascii=False).replace("</", "<\\/")
        return nav + f'<script type="application/ld+json">{ld}</script>\n'

    @staticmethod
    def footer(root: str, base: str) -> str:
        cc = f'<a href="{REPO_URL}/blob/main/LICENSE-CONTENT.md" target="_blank" rel="noopener">CC BY-NC-SA 4.0</a>'
        mit = f'<a href="{REPO_URL}/blob/main/LICENSE" target="_blank" rel="noopener">MIT</a>'
        privacy = tr("privacy") if GOAT else tr("privacy_nocount")
        visits = (f'<p class="visits" data-visits hidden><span aria-hidden="true">👀</span> <b data-visits-n></b> '
                  f'<span>{E(tr("visits_label"))}</span></p>') if GOAT else ""
        return f"""<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a class="brand" href="{root}index.html">{LOGO}<span>{E(tr('brand_main'))}<small>{E(tr('brand_small'))}</small></span></a>
        <p style="margin-top:14px;max-inline-size:44ch">{E(tr('footer_blurb'))}</p>
        {visits}
      </div>
      <div>
        <h4>{E(tr('f_learn'))}</h4>
        <ul><li><a href="{root}index.html#episodes">{E(tr('f_all_episodes'))}</a></li><li><a href="{root}labs/index.html">{E(tr('f_labs'))}</a></li>
        <li><a href="{root}demos/index.html">{E(tr('f_demos'))}</a></li><li><a href="{root}lunchbox.html">{E(tr('f_lunchbox'))}</a></li></ul>
      </div>
      <div>
        <h4>{E(tr('f_repo'))}</h4>
        <ul><li><a href="{REPO_URL}" target="_blank" rel="noopener">{E(tr('f_source'))}</a></li>
        <li><a href="{REPO_URL}/blob/main/{tr('f_syllabus_file')}" target="_blank" rel="noopener">{E(tr('f_syllabus'))}</a></li>
        <li><a href="{REPO_URL}/blob/main/COURSE-DESIGN.md" target="_blank" rel="noopener">{E(tr('f_design'))}</a></li>
        <li><a href="{REPO_URL}/issues" target="_blank" rel="noopener">{E(tr('f_report'))}</a></li></ul>
      </div>
      <div>
        <h4>{E(tr('f_author'))}</h4>
        <ul><li><a href="{root}index.html#author">{E(AUTHOR['name'])} · {E(tr('f_about_author'))}</a></li>
        <li><a href="{E(AUTHOR['linkedin'][LANG])}" target="_blank" rel="noopener">LinkedIn ↗</a></li>
        <li><a href="mailto:{E(AUTHOR['email'])}">{E(AUTHOR['email'])}</a></li></ul>
      </div>
    </div>
    <p class="fine">{tr('fine', cc=cc, mit=mit)} {E(privacy)}</p>
  </div>
</footer>"""


def byline(root: str) -> str:
    return (f'<a class="byline" href="{root}index.html#author">{avatar("by-avatar")}<span>{E(tr("byline"))} '
            f'<b>{E(AUTHOR["name"])}</b><small>{E(tr("byline_role"))}</small></span></a>')


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


SEC_EMOJI = {"menu": "🍱", "story": "🏪", "reading": "📖", "demo": "🎬", "quiz": "✅", "take": "🧠", "notes": "🗒",
             "lab": "🔬", "further": "📚"}


def lunch_page(shell: Shell, L: dict, prev: dict | None, nxt: dict | None) -> None:
    src = lang_src(REPO / "lunches" / L["slug"] / "README.md")
    out = OUT / "lunches" / f"{L['slug']}.html"
    env = {"src": src, "out": out, "ids": {}}
    root = "../"
    base = "../../"
    text = src.read_text(encoding="utf-8")
    parts = fence_aware_split(text, 2)
    header = parts[0][1]
    full_title = rx(r"(?m)^#\s*(?:Lunch|Makan Siang)\s*\d+\s*·\s*(.+)$", header, L["title"])
    prereq = rx(r"\*\*(?:Prerequisite lunches|Makan siang prasyarat):\*\*\s*([^·\n]+)", header, "none")
    az900 = rx(r"\*\*(?:AZ-900 skill area|Area keterampilan AZ-900):\*\*\s*([^·\n]+)", header, "")

    def sec(key: str) -> str:
        for t, b in parts[1:]:
            if t and t.startswith(SEC_EMOJI[key]):
                return trim_rules(b)
        return ""

    menu, story, reading = sec("menu"), sec("story"), sec("reading")
    demo, quiz, take = sec("demo"), sec("quiz"), sec("take")
    notes, labsec = sec("notes"), sec("lab")
    further, validated = strip_footer(sec("further"))
    part = PARTS[L["part"]]
    color = part["color"]
    n = L["n"]

    # ---------- hero
    if prev is None:
        previously, prev_label = tr("prev_first"), tr("prev_label")
    else:
        previously = tr("previously", n=prev["n"], ep=prev["ep"], outcome=prev["outcome"])
        prev_label = tr("prev_recap") if L["num"] == 22 else tr("prev_label")
    pre_nums = re.findall(r"\d{2}", prereq)
    lunches_by_n = {x["n"]: x for x in ALL}
    pre_chips = "".join(
        f'<a class="chip" href="{lunches_by_n[p]["slug"]}.html" title="{E(lunches_by_n[p]["ep"])}">↩ {p}</a>'
        for p in pre_nums if p in lunches_by_n)
    special = ""
    if L["num"] == 21:
        special = f'<span class="chip ok">{E(tr("chip_s1_finale"))}</span>'
    elif L["num"] == 22:
        special = f'<span class="chip advanced">{E(tr("chip_s2_premiere"))}</span>'
    elif L["num"] == 31:
        special = f'<span class="chip advanced">{E(tr("chip_last"))}</span>'
    lab = L["lab"]
    cost_n = len(lab["cost"])
    beyond = az900.startswith(("Beyond", "Di luar"))
    mood = mood_for(L["readiness"])
    hero = f"""<section class="ep-hero">
  <div class="container ep-hero-grid">
    <div>
      <div class="ep-num"><span class="pill">{E(tr('ep_pill', n=n))}</span> {E(tr('ep_meta', s=L['season'], icon=part['icon'], p=L['part'], part=part['name']))}</div>
      <h1>{E(L['ep'])}</h1>
      <div class="lunch-title">{E(tr('lunch_label', n=n, title=full_title))}</div>
      {byline(root)}
      <div class="chips">
        {special}<span class="chip {L['level_key']}">{E(L['level'])}</span>
        <span class="chip">{E(tr('chip_60'))}</span>
        {f'<span class="chip">🎓 {E(az900 if beyond else tr("chip_az900", area=az900))}</span>' if az900 else ''}
        <span class="chip cost">{E(tr('chip_lab', time=lab['time'], cost=lab['cost']))}</span>
        {('<span class="chip">' + E(tr('chip_builds_on')) + '</span>' + pre_chips) if pre_chips else '<span class="chip ok">' + E(tr('chip_no_prereq')) + '</span>'}
      </div>
      <div class="previously"><b>{E(prev_label)}</b>{E(previously)}</div>
      <div class="ctas">
        <button class="btn btn-warm" type="button" data-timer-start>{E(tr('cta_start'))}</button>
        <a class="btn" href="#demo">{E(tr('cta_demo'))}</a>
        <button class="btn btn-ghost" type="button" data-finish>{E(tr('cta_finish'))}</button>
      </div>
    </div>
    <div class="mini-art" aria-hidden="false">
      {pantry(mood, label=tr('pantry_mood', mood=T['pantry_moods'][mood]))}
      <div class="mini-meter"><b>{E(tr('meter', pct=L['readiness']))}</b>{E(tr('meter_say', answer=L['answer']))}</div>
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
            f'<article class="scene-card" id="{E(sid)}" data-spy><span class="scene-no">{E(tr("scene_of", i=i, n=len(scenes)))}</span>'
            f'<h3>{render_inline(title_md, env)}</h3><div class="prose">{render(b, env)}</div></article>')
        rail_scenes.append(f'<li class="sub" style="--sc:#1665d8"><a href="#{E(sid)}">{E(plain(title_md))}</a></li>')

    # ---------- objectives
    objs = parse_bullets(menu)
    leads = [ln.strip() for ln in menu.splitlines() if ln.strip() and not re.match(r"^([-*]|\d+\.)\s", ln.strip())]
    menu_lead = next((ln for ln in leads if ln.endswith(":")), tr("obj_lead"))
    obj_html = "".join(f'<li><button type="button" data-obj="{i}" aria-pressed="false" aria-label="{E(tr("obj_btn"))}">✓</button>'
                       f'<span>{render_inline(o, env)}</span></li>' for i, o in enumerate(objs))

    # ---------- demo
    watch = ""
    m = re.search(r"(?s)((?:What to watch for|Yang perlu diperhatikan):.*)$", demo)
    if m:
        watch = render(m.group(1), env)
    script_link = ""
    vs = lang_src(REPO / "lunches" / L["slug"] / "demo-video-script.md")
    if vs.exists():
        script_link = f'{REPO_URL}/blob/main/lunches/{L["slug"]}/{vs.name}'
    demo_title = DEMO_TITLES.get(LANG, {}).get(L["slug"]) or DEMO_TITLES.get("en", {}).get(L["slug"], tr("demo_default"))
    demo_src = f'{base}demos/{L["slug"]}.html{lang_query()}'

    # ---------- quiz
    qs = parse_quiz(quiz)
    q_html = []
    for i, (q, a) in enumerate(qs, 1):
        q_html.append(
            f'<article class="qcard" data-q="{i}"><div class="q"><span class="qn">Q{i}</span><div class="qtext">{render(q, env)}'
            f'<button class="btn btn-sm reveal-btn" type="button" aria-expanded="false">{E(tr("reveal"))}</button></div></div>'
            f'<div class="a"><div><div class="a-inner">{render(a, env)}<div class="grade"><span class="muted">{E(tr("got_it_q"))}</span>'
            f'<button class="btn btn-sm yes" type="button" data-grade="1">{E(tr("got_it"))}</button>'
            f'<button class="btn btn-sm no" type="button" data-grade="0">{E(tr("not_quite"))}</button></div></div></div></div></article>')

    # ---------- takeaways
    tks = parse_bullets(take)
    tk_html = "".join(f'<div class="tk"><p>{render_inline(t, env)}</p><button class="btn btn-sm pin" type="button" data-pin="{i}">{E(tr("pin"))}</button></div>'
                      for i, t in enumerate(tks))

    # ---------- field notes
    notes_html = ""
    if notes.strip():
        notes_md = "\n".join(re.sub(r"^>\s?", "", ln) for ln in notes.splitlines())
        notes_html = f"""<section class="block" id="field-notes" data-spy>
      <div class="field-note">
        <div class="fn-head">{avatar("fn-avatar")}<div><b>{E(tr('h_notes'))}</b><small>{E(tr('notes_sub'))}</small></div><span class="fn-pin" aria-hidden="true">🗒️</span></div>
        <div class="fn-body prose">{render(notes_md, env)}</div>
        <a class="fn-more" href="{root}index.html#author">{E(tr('notes_more'))} →</a>
      </div>
    </section>"""

    # ---------- lab ticket
    lab_par = "\n".join(ln for ln in labsec.splitlines() if not re.match(r"^\s*[-*] ", ln)).strip()

    # ---------- further reading
    fur = []
    for item in parse_bullets(further):
        mm = re.match(r"^\[([^\]]+)\]\(([^)]+)\)\s*[—–-]?\s*(.*)$", item)
        if not mm:
            continue
        href, ext = map_href(mm.group(2), env)
        dom = urlparse(href).netloc.replace("www.", "") if ext else tr("this_course")
        tgt = ' target="_blank" rel="noopener"' if ext else ""
        desc_md = mm.group(3).strip()
        if desc_md[:1].islower():
            desc_md = desc_md[0].upper() + desc_md[1:]
        fur.append(f'<a href="{E(href)}"{tgt}><b>{E(plain(mm.group(1)))}</b><span>{render_inline(desc_md, env) if desc_md else ""}</span><small>{E(dom)} ↗</small></a>')

    # ---------- finish + teaser
    fin = SERIES["finale"]
    if nxt:
        teaser = (f'<div class="teaser"><b>{E(tr("next_ep", n=nxt["n"]))}</b><h4>{E(nxt["ep"])}</h4><p>{E(nxt["hook"])}</p>'
                  f'<p style="margin-top:10px"><a href="{nxt["slug"]}.html">{E(tr("watch_ep", n=nxt["n"]))}</a></p></div>')
    else:
        teaser = (f'<div class="teaser"><b>{E(tr("season_finale"))}</b><h4>{E(fin["ep"])}</h4><p>{E(fin["hook"])}</p>'
                  f'<p style="margin-top:10px"><a href="../labs/{fin["slug"]}.html">{E(tr("take_capstone"))}</a></p></div>')
    nav_prev = (f'<a href="{prev["slug"]}.html"><small>{E(tr("nav_prev_ep"))}</small>{prev["n"]} · {E(prev["ep"])}</a>' if prev
                else f'<a href="../index.html"><small>{E(tr("nav_home"))}</small>{E(tr("nav_journey_map"))}</a>')
    nav_next = (f'<a class="next" href="{nxt["slug"]}.html"><small>{E(tr("nav_next_ep"))}</small>{nxt["n"]} · {E(nxt["ep"])}</a>' if nxt
                else f'<a class="next" href="../labs/{fin["slug"]}.html"><small>{E(tr("nav_finale"))}</small>{E(tr("capstone_title"))}</a>')
    notes_li = f'<li style="--sc:#d98a00"><a href="#field-notes">{E(tr("rail_notes"))}</a></li>' if notes_html else ""
    rail = f"""<aside class="rail" aria-label="{E(tr('rail_label'))}">
      <h4>{E(tr('rail_label'))} <span>{E(tr('clock_center'))}</span></h4>
      <ol>
        <li style="--sc:#e2482f"><a href="#menu">{E(tr('rail_menu'))} <span class="mins">0–5</span></a></li>
        <li style="--sc:#e2482f"><a href="#story">{E(tr('rail_story'))}</a></li>
        <li style="--sc:#1665d8"><a href="#reading">{E(tr('rail_reading'))} <span class="mins">5–30</span></a></li>
        {''.join(rail_scenes)}
        <li style="--sc:#7b4ff0"><a href="#demo">{E(tr('rail_demo'))} <span class="mins">30–45</span></a></li>
        <li style="--sc:#11935a"><a href="#quiz">{E(tr('rail_quiz'))} <span class="mins">45–50</span></a></li>
        <li style="--sc:#d98a00"><a href="#takeaways">{E(tr('rail_take'))} <span class="mins">50–55</span></a></li>
        {notes_li}
        <li style="--sc:#d98a00"><a href="#lab">{E(tr('rail_lab'))}</a></li>
        <li style="--sc:#0f9fb0"><a href="#finish">{E(tr('rail_finish'))} <span class="mins">55–60</span></a></li>
      </ol>
      <div class="rail-foot">
        <button class="btn btn-sm btn-warm" type="button" data-timer-start>{E(tr('rail_timer'))}</button>
        <a class="btn btn-sm" href="../labs/{L['slug']}.html">{E(tr('rail_open_lab', n=n))}</a>
      </div>
    </aside>"""
    mob_notes = f'<a href="#field-notes">{E(tr("mob_notes"))}</a>' if notes_html else ""
    main = f"""{hero}
<nav class="mobile-seg" aria-label="{E(tr('mob_label'))}"><div class="container">
  <a href="#menu">{E(tr('mob_menu'))}</a><a href="#story">{E(tr('mob_story'))}</a><a href="#reading">{E(tr('mob_reading'))}</a><a href="#demo">{E(tr('mob_demo'))}</a>
  <a href="#quiz">{E(tr('mob_quiz'))}</a><a href="#takeaways">{E(tr('mob_take'))}</a>{mob_notes}<a href="#lab">{E(tr('mob_lab'))}</a><a href="#finish">{E(tr('mob_finish'))}</a>
</div></nav>
<div class="container ep-layout">
  {rail}
  <div class="ep-main">
    <section class="block" id="menu" data-spy>
      <div class="block-head"><span class="icon">🍱</span><h2>{E(tr('h_menu'))}</h2><span class="minute">{E(tr('min_menu'))}</span></div>
      <div class="menu-card">
        <h3>{E(menu_lead.rstrip(':'))}</h3>
        <ul class="objectives">{obj_html}</ul>
        <p class="hint">{E(tr('obj_hint'))}</p>
      </div>
    </section>

    <section class="block" id="story" data-spy>
      <div class="story">
        {skyline()}
        <span class="tag">{E(tr('story_tag', n=n))}</span>
        <div class="story-body">{render(story, env)}</div>
      </div>
    </section>

    <section class="block" id="reading" data-spy>
      <div class="block-head"><span class="icon">📖</span><h2>{E(tr('h_reading'))}</h2><span class="minute">{E(tr('min_reading', k=len(scenes)))}</span></div>
      {f'<div class="prose intro">{render(intro, env)}</div>' if intro.strip() else ''}
      {''.join(scene_html)}
    </section>

    <section class="block" id="demo" data-spy>
      <div class="block-head"><span class="icon">🎬</span><h2>{E(tr('h_demo'))}</h2><span class="minute">{E(tr('min_demo'))}</span></div>
      <div class="theatre">
        <div class="theatre-bar">
          <span class="live"><i></i> {E(tr('theatre_live', title=demo_title))}</span>
          <span class="tb-actions"><a class="btn btn-sm" href="{demo_src}" target="_blank" rel="noopener">{E(tr('open_tab'))}</a>
          <button class="btn btn-sm" type="button" data-fullscreen>{E(tr('theatre'))}</button></span>
        </div>
        <div class="theatre-frame"><iframe src="{demo_src}" title="{E(tr('iframe_title', title=demo_title))}" loading="lazy"></iframe></div>
      </div>
      <div class="watch-for prose">
        <p class="muted">{tr('watch_hint')}
        {tr('video_script', href=script_link) if script_link else ''}</p>
        {watch}
      </div>
    </section>

    <section class="block" id="quiz" data-spy>
      <div class="block-head"><span class="icon">✅</span><h2>{E(tr('h_quiz'))}</h2><span class="minute">{E(tr('min_quiz'))}</span></div>
      <div class="quiz-head"><div class="score-ring" data-score-ring><span data-score-text>0/{len(qs)}</span></div>
        <div><b>{E(tr('quiz_head', k=len(qs)))}</b><p class="muted" style="margin:0" data-score-note>{E(tr('quiz_note'))}</p></div></div>
      <div class="qcards">{''.join(q_html)}</div>
    </section>

    <section class="block" id="takeaways" data-spy>
      <div class="block-head"><span class="icon">🧠</span><h2>{E(tr('h_take'))}</h2><span class="minute">{E(tr('min_take'))}</span></div>
      <div class="takeaways">{tk_html}</div>
    </section>

    {notes_html}

    <section class="block" id="lab" data-spy>
      <div class="block-head"><span class="icon">🔬</span><h2>{E(tr('h_lab'))}</h2><span class="minute">{E(tr('min_lab'))}</span></div>
      <div class="ticket">
        <div class="stub"><span>{E(tr('stub_lab'))}</span><b>{n}</b><span>{E(tr('admit'))}</span></div>
        <div class="main">
          <h3>{E(lab['title'])}</h3>
          <div class="prose">{render(lab_par, env)}</div>
          <div class="meta"><span class="chip">⏱ {E(lab['time'])}</span><span class="chip cost">{lab['cost']} {E(cost_text(cost_n))}</span>
            <span class="chip ok">{E(tr('works_alone'))}</span><span class="chip">{E(tr('modes'))}</span></div>
          <a class="btn btn-primary" href="../labs/{L['slug']}.html">{E(tr('start_lab', n=n))}</a>
        </div>
      </div>
    </section>

    {f'<section class="block" id="further"><div class="block-head"><span class="icon">📚</span><h2>{E(tr("h_further"))}</h2></div><div class="further">{"".join(fur)}</div></section>' if fur else ''}

    <section class="block" id="finish" data-spy>
      <div class="finish">
        <div class="big-medal" aria-hidden="true">{L['badge']['icon']}</div>
        <p class="kicker" style="justify-content:center">{E(tr('finish_kicker'))}</p>
        <h2>{E(L['badge']['name'])}</h2>
        <p class="muted">{E(L['badge']['desc'])}</p>
        <p><button class="btn btn-warm btn-lg" type="button" data-finish>{E(tr('finish_btn'))}</button></p>
        <p><a href="#finish" data-undo hidden>{E(tr('undo'))}</a></p>
        <p class="finish-answer">{tr('finish_answer', answer=E(L['answer']))}</p>
        {teaser}
      </div>
    </section>

    <nav class="ep-nav" aria-label="{E(tr('ep_nav'))}">{nav_prev}{nav_next}</nav>
    <p class="validated">{E(tr('validated', v=validated)) if validated else ''}<a href="{REPO_URL}/blob/main/lunches/{L['slug']}/{src.name}" target="_blank" rel="noopener">{E(tr('read_lunch_gh'))}</a> ·
      <a href="{REPO_URL}/issues" target="_blank" rel="noopener">{E(tr('out_of_date'))}</a></p>
  </div>
</div>
<div class="timer" role="status" aria-live="polite"><div class="t-ring"></div><div><div class="t-time">60:00</div><div class="t-seg">{E(tr('timer_now'))}</div></div>
  <button class="btn btn-sm" type="button" data-timer-stop aria-label="{E(tr('timer_stop'))}">■</button></div>"""
    shell.page(out=out, title=tr("lunch_page_title", n=n, ep=L["ep"], title=full_title),
               desc=tr("lunch_page_desc", n=n, title=full_title, hook=L["hook"]),
               main=main, body_attrs={"data-page": "lunch", "data-lunch": n, "style": f"--c:{color}"}, active="episodes",
               crumbs=[(tr("crumb_home"), "index.html"),
                       (SERIES["seasons"][L["season"] - 1]["name"], f"index.html#episodes-s{L['season']}"),
                       (tr("lunch_label", n=n, title=full_title), None)])


# ============================================================================ lab pages
LAB_KINDS = (
    ("Challenge brief", "challenge"), ("Ringkasan tantangan", "challenge"),
    ("Clean up", "cleanup"), ("Bersihkan", "cleanup"),
    ("Choose your mode", "mode"), ("Pilih mode Anda", "mode"),
    ("How this challenge works", "mode-info"), ("Cara kerja tantangan ini", "mode-info"),
    ("Before you start", "setup"), ("Sebelum mulai", "setup"),
    ("Verify your work", "verify"), ("Verifikasi hasil kerja Anda", "verify"),
    ("Acceptance checklist", "verify"), ("Daftar periksa penerimaan", "verify"),
    ("Break it and fix it", "bonus"), ("Rusak lalu perbaiki", "bonus"),
    ("Optional", "bonus"), ("Opsional", "bonus"),
    ("Troubleshooting", "trouble"), ("Pemecahan masalah", "trouble"),
    ("Stretch goals", "stretch"), ("Tantangan tambahan", "stretch"),
    ("What you'll build", "intro"), ("Yang akan Anda bangun", "intro"),
    ("The brief", "intro"), ("Ringkasan proyek", "intro"),
)
TASK_RE = re.compile(r"^(?:Task|Tugas)\s+(\d+)(\s*\([^)]*\))?\s*·\s*(.+)$")


def lab_kind(title: str) -> str:
    if re.match(r"^(?:Task|Tugas) \d+", title):
        return "task"
    for key, kind in LAB_KINDS:
        if key in title:
            return kind
    return "other"


KIND_COLOR = {"task": "var(--c)", "bonus": "#e2482f", "verify": "#11935a", "cleanup": "#e2482f", "challenge": "#7b4ff0",
              "setup": "#1665d8", "intro": "#1665d8", "mode": "#68738c", "trouble": "#68738c", "stretch": "#d98a00"}


def lab_meta(slug: str) -> dict:
    src = lang_src(REPO / "labs" / slug / "README.md")
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
        "pairs": rx(r"\*\*(?:Pairs with|Pasangan dari):\*\*\s*(.+)", header),
        "time": rx(r"\*\*(?:Time|Waktu):\*\*\s*([^·\n]+)", header),
        "cost": rx(r"\*\*(?:Cost|Biaya):\*\*\s*(💲+)", header, "💲"),
        "difficulty": rx(r"\*\*(?:Difficulty|Tingkat kesulitan):\*\*\s*([★☆]+)", header),
        "alone": rx(r"\*\*(?:Works on its own|Bisa dikerjakan terpisah):\*\*\s*(.+)", header),
    }


def lab_files(slug: str) -> list[tuple[str, int]]:
    base = REPO / "labs" / slug
    files = []
    for p in sorted(base.rglob("*")):
        if not p.is_file() or "__pycache__" in p.parts or re.fullmatch(r"README(\.[a-z]{2})?\.md", p.name):
            continue
        if p.suffix == ".md":
            is_twin = bool(re.search(r"\.[a-z]{2}\.md$", p.name))
            if LANG == "en" and is_twin:
                continue
            if LANG != "en":
                if is_twin and not p.name.endswith(f".{LANG}.md"):
                    continue
                if not is_twin and p.with_name(p.name[:-3] + f".{LANG}.md").exists():
                    continue
        files.append((p.relative_to(base).as_posix(), p.stat().st_size))
    return files


def lab_page(shell: Shell, slug: str, L: dict | None, lab_list: list[dict]) -> None:
    meta = lab_meta(slug)
    out = OUT / "labs" / f"{slug}.html"
    env = {"src": meta["src"], "out": out, "ids": {}}
    body = meta["text"]
    # drop the H1, the language line and the header blockquote that follows (later blockquotes are content)
    lines = body.splitlines()
    i = next((k for k, ln in enumerate(lines) if ln.startswith("# ")), -1) + 1
    while i < len(lines) and (not lines[i].strip() or is_lang_line(lines[i])):
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

    sec_html, rail_items = [], []
    for t, b in sections:
        kind = lab_kind(t)
        sid = gh_slug(plain(t))
        env["ids"].setdefault(sid, 0)
        b = trim_rules(b)
        toggle, tag, title_txt = "", "", t
        mt = TASK_RE.match(t)
        if kind == "task" and mt:
            tag = f'<span class="task-tag">{E(tr("task", n=mt.group(1)) + (mt.group(2) or ""))}</span>'
            title_txt = mt.group(3)
        if kind in ("task", "bonus", "verify"):
            toggle = f'<button class="btn btn-sm done-toggle" type="button" data-task="{E(sid)}" aria-pressed="false">{E(tr("mark_done"))}</button>'
        extra = ""
        if kind == "cleanup":
            extra = (f'<p class="cleanup-cta"><button class="btn btn-warm" type="button" data-cleanup aria-pressed="false">{E(tr("cleanup_btn"))}</button> '
                     f'<span class="muted">{E(tr("cleanup_xp"))}</span></p>')
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
    nav_prev = (f'<a href="{prev_l["slug"]}.html"><small>{E(tr("nav_prev_lab"))}</small>{prev_l["num"]} · {E(prev_l["title"])}</a>' if prev_l
                else f'<a href="index.html"><small>{E(tr("nav_all_labs"))}</small>{E(tr("lab_hub"))}</a>')
    nav_next = (f'<a class="next" href="{next_l["slug"]}.html"><small>{E(tr("nav_next_lab"))}</small>{next_l["num"]} · {E(next_l["title"])}</a>' if next_l
                else f'<a class="next" href="../lunchbox.html"><small>{E(tr("nav_done"))}</small>{E(tr("open_lunchbox"))}</a>')
    if L:
        story = (f'<p class="lab-story">🏪 <b>{E(tr("pairs_episode", n=L["n"], ep=L["ep"]))}</b> — {E(L["hook"])} '
                 f'<a href="../lunches/{L["slug"]}.html">{E(tr("read_the_lunch"))}</a></p>')
    else:
        fin = SERIES["finale"]
        story = f'<p class="lab-story">🌟 <b>{E(fin["ep"])}</b> — {E(fin["hook"])}</p>'
    mode_switch = "" if is_final else (
        f'<div class="mode-switch" role="group" aria-label="{E(tr("lab_mode"))}"><button type="button" data-mode="guided" aria-pressed="true">{E(tr("mode_guided"))}</button>'
        f'<button type="button" data-mode="challenge" aria-pressed="false">{E(tr("mode_challenge"))}</button></div>')
    n_tasks = sum(1 for t, _ in sections if lab_kind(t) in ("task", "bonus", "verify"))
    hero = f"""<section class="lab-hero" style="--c:{color}">
  <div class="container">
    <p class="kicker"><span class="dot"></span>{E(tr('kicker_finale')) if is_final else E(tr('kicker_lab', n=L["n"]))}</p>
    <div class="ticket">
      <div class="stub"><span>{E(tr('stub_lab'))}</span><b>{meta['num']}</b><span>{E(tr('stub_finale')) if is_final else E(tr('admit'))}</span></div>
      <div class="main">
        <h1 class="lab-title">{E(meta['title'])}</h1>
        {story}
        {byline("../")}
        <div class="meta">
          <span class="chip">⏱ {EC(meta['time'])}</span>
          <span class="chip cost">{meta['cost']} {E(cost_text(cost_n))}</span>
          {f'<span class="chip">{E(tr("difficulty", d=meta["difficulty"]))}</span>' if meta['difficulty'] else ''}
          <span class="chip ok">{E(tr('works_alone'))}</span>
        </div>
        <div class="lab-actions">{mode_switch}<button class="btn btn-primary" type="button" data-lab-complete>{E(tr('lab_complete'))}</button></div>
        {f'<p class="muted small">{pairs_html}</p>' if pairs_html and is_final else ''}
      </div>
    </div>
  </div>
</section>"""
    rail = f"""<aside class="rail" aria-label="{E(tr('lab_rail'))}">
      <h4>{E(tr('lab_progress'))} <span data-task-text>{E(tr('lab_tasks', k=n_tasks))}</span></h4>
      <div class="bar" style="margin-bottom:14px"><span data-task-bar></span></div>
      <ol>{''.join(rail_items)}</ol>
      <div class="rail-foot">
        <p class="muted small" style="margin:0">{E(tr('lab_files'))}</p>
        <ul class="files">{files_html}</ul>
        <a class="btn btn-sm" href="{REPO_URL}/tree/main/labs/{slug}" target="_blank" rel="noopener">{E(tr('lab_folder'))}</a>
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
      <div><h3 style="margin:0">{E(tr('lab_finished_q'))}</h3><p class="muted" style="margin:0">{E(tr('lab_finished_p'))}</p></div>
      <button class="btn btn-primary" type="button" data-lab-complete>{E(tr('lab_complete'))}</button>
    </div>
    <nav class="ep-nav" aria-label="{E(tr('labs_nav'))}">{nav_prev}{nav_next}</nav>
    <p class="validated">{E(tr('validated', v=validated)) if validated else ''}<a href="{REPO_URL}/blob/main/labs/{slug}/{meta['src'].name}" target="_blank" rel="noopener">{E(tr('read_lab_gh'))}</a> ·
      <a href="{REPO_URL}/issues" target="_blank" rel="noopener">{E(tr('report_lab'))}</a></p>
  </div>
</div>
<div class="cleanup-banner" role="status">{tr('cleanup_banner', id=E(cleanup_id))}</div>"""
    shell.page(out=out, title=tr("lab_page_title", num=meta["num"], title=meta["title"]),
               desc=tr("lab_page_desc", num=meta["num"], title=meta["title"], time=meta["time"].replace("`", ""),
                       cost=meta["cost"]),
               main=main, body_attrs={"data-page": "lab", "data-lab": meta["num"], "style": f"--c:{color}"}, active="labs",
               crumbs=[(tr("crumb_home"), "index.html"), (tr("nav_labs"), "labs/index.html"), (meta["h1"], None)])


# ============================================================================ hubs
def labs_hub(shell: Shell, lab_list: list[dict]) -> None:
    out = OUT / "labs" / "index.html"
    src = lang_src(REPO / "labs" / "README.md")
    env = {"src": src, "out": out, "ids": {}}
    text = src.read_text(encoding="utf-8")
    secs = {t: trim_rules(b) for t, b in fence_aware_split(text, 2) if t}

    def get(key: str) -> str:
        for name in (tr(key), ST.EN[key]):
            for t, b in secs.items():
                if strip_emoji_prefix(t).startswith(name):
                    return b
        return ""

    how = render(get("hub_how"), env)
    env["ids"].setdefault(tr("hub_cost_id"), 0)
    cost = render(get("hub_cost"), env)
    wrong = render(get("hub_wrong"), env)
    cards = []
    for x in lab_list:
        cost_n = len(x["cost"])
        diff = f'<span class="chip">{E(x["diff"])}</span>' if x.get("diff") else ""
        cards.append(
            f'<a class="tcard reveal" href="{x["slug"]}.html" data-n="{x["num"]}" data-cost="{cost_n}" data-part="{x["part"]}" style="--c:{PARTS[x["part"]]["color"]}">'
            f'<div class="stub"><small>{E(tr("stub_lab"))}</small><b>{x["num"]}</b></div><div class="body"><span class="status st-new">{E(tr("not_started"))}</span>'
            f'<h3>{E(x["title"])}</h3><p>{E(x["pairs"])}</p><div class="chips"><span class="chip">⏱ {E(short_time(x["time"]))}</span>'
            f'<span class="chip cost">{x["cost"]}</span>{diff}</div></div></a>')
    part_btns = "".join(f'<button type="button" data-part-filter="{p["id"]}" aria-pressed="false">{p["icon"]} {E(p["short"])}</button>' for p in SERIES["parts"])
    stats = "".join(f'<div class="stat"><b>{E(a)}</b><span>{E(b)}</span></div>' for a, b in T["hub_stats"])
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>{E(tr('hub_kicker'))}</p>
    <h1>{tr('hub_h1')}</h1>
    <p class="lead">{tr('hub_lead')}</p>
    <div class="hub-stats stats">{stats}</div>
  </div>
</section>
<section class="section" style="padding-top:40px">
  <div class="container">
    <div class="toolbar">
      <div class="seg-tabs" role="group" aria-label="{E(tr('f_cost'))}"><button type="button" data-cost-filter="all" aria-pressed="true">{E(tr('all_costs'))}</button>
        <button type="button" data-cost-filter="1" aria-pressed="false">💲</button><button type="button" data-cost-filter="2" aria-pressed="false">💲💲</button>
        <button type="button" data-cost-filter="3" aria-pressed="false">💲💲💲</button></div>
      <div class="seg-tabs" role="group" aria-label="{E(tr('f_part'))}"><button type="button" data-part-filter="all" aria-pressed="true">{E(tr('all_parts'))}</button>{part_btns}</div>
      <input class="search" type="search" placeholder="{E(tr('search_labs'))}" aria-label="{E(tr('search_labs'))}" data-lab-search>
    </div>
    <div class="ticket-grid" data-ticket-grid>{''.join(cards)}</div>
  </div>
</section>
<section class="section band">
  <div class="container hub-docs">
    <article class="card doc-card"><h2>{E(tr('hub_how'))}</h2><div class="prose wide">{how}</div></article>
    <article class="card doc-card" id="{E(tr('hub_cost_id'))}"><h2>{E(tr('hub_cost'))}</h2><div class="prose wide">{cost}</div></article>
    <article class="card doc-card"><h2>{E(tr('hub_wrong'))}</h2><div class="prose wide">{wrong}</div></article>
  </div>
</section>"""
    shell.page(out=out, title=tr("hub_title"), desc=tr("hub_desc"), main=main, body_attrs={"data-page": "labs"}, active="labs",
               crumbs=[(tr("crumb_home"), "index.html"), (tr("nav_labs"), None)])


DEMO_TITLES: dict[str, dict[str, str]] = {}
DEMO_STEPS: dict[str, int] = {}


def load_demo_titles() -> None:
    DEMO_TITLES.clear()
    DEMO_TITLES.update({lang: {} for lang in LANGS})
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
        DEMO_TITLES["en"][p.stem] = html.unescape(re.sub(r"<[^>]+>", "", m.group(1)).strip()) if m else p.stem
        DEMO_STEPS[p.stem] = steps
        for lang in LANGS[1:]:
            j = TOOLS / "i18n" / "demos" / f"{p.stem}.{lang}.json"
            if j.exists():
                try:
                    DEMO_TITLES[lang][p.stem] = json.loads(j.read_text(encoding="utf-8"))["page"]["title"]
                except (ValueError, KeyError, TypeError):
                    pass


def inject_demo_translations() -> int:
    try:
        import demo_text
    except ImportError:
        return 0
    n = 0
    for j in sorted((TOOLS / "i18n" / "demos").glob("*.id.json")) if (TOOLS / "i18n" / "demos").exists() else []:
        slug = j.name[:-len(".id.json")]
        if (DOCS / "demos" / f"{slug}.html").exists():
            errs, _w = demo_text.check(slug)
            if errs:
                print(f"  ! demo translation {j.name} has {len(errs)} problem(s); not embedded (run tools/i18n/demo_text.py check {slug})")
                continue
            before = (DOCS / "demos" / f"{slug}.html").read_text(encoding="utf-8")
            demo_text.inject(slug)
            n += (DOCS / "demos" / f"{slug}.html").read_text(encoding="utf-8") != before
    return n


def demos_hub(shell: Shell, lunches: list[dict]) -> None:
    out = OUT / "demos" / "index.html"
    q = lang_query()
    cards = []
    for L in lunches:
        steps = DEMO_STEPS.get(L["slug"], 0)
        mid = max(1, (steps + 1) // 2) if steps else 1
        title = DEMO_TITLES.get(LANG, {}).get(L["slug"]) or DEMO_TITLES["en"].get(L["slug"], L["title"])
        cards.append(
            f'<a class="dcard reveal" href="../../demos/{L["slug"]}.html{q}" data-n="{L["n"]}" data-part="{L["part"]}" style="--c:{PARTS[L["part"]]["color"]}">'
            f'<div class="dthumb"><iframe data-src="../../demos/{L["slug"]}.html{q}#step={mid}" title="{E(tr("demo_preview", n=L["n"]))}" tabindex="-1" aria-hidden="true" loading="lazy"></iframe>'
            f'<span class="play" aria-hidden="true">▶</span></div><div class="dbody"><small>{E(tr("demo_meta", n=L["n"], part=PARTS[L["part"]]["short"], level=L["level"]))}</small>'
            f'<h3>{E(title)}</h3><p class="muted small" style="margin:.3em 0 0">{E(tr("demo_steps", k=steps))} · <span>{E(L["ep"])}</span></p></div></a>')
    part_btns = "".join(f'<button type="button" data-demo-filter="{p["id"]}" aria-pressed="false">{p["icon"]} {E(p["short"])}</button>' for p in SERIES["parts"])
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>{E(tr('demos_kicker'))}</p>
    <h1>{tr('demos_h1')}</h1>
    <p class="lead">{E(tr('demos_lead'))}</p>
  </div>
</section>
<section class="section" style="padding-top:40px">
  <div class="container">
    <div class="toolbar"><div class="seg-tabs" role="group" aria-label="{E(tr('f_part'))}"><button type="button" data-demo-filter="all" aria-pressed="true">{E(tr('all_parts'))}</button>{part_btns}</div></div>
    <div class="demo-grid" data-demo-grid>{''.join(cards)}</div>
  </div>
</section>"""
    shell.page(out=out, title=tr("demos_title"), desc=tr("demos_desc"), main=main, body_attrs={"data-page": "demos"}, active="demos",
               crumbs=[(tr("crumb_home"), "index.html"), (tr("nav_demos"), None)])


DEMO_FOOTER = re.compile(r'<p>(?:<span data-i18n="partOf">)?Part of(?:</span>)? <strong[^>]*>Azure Fundamentals: One Lunch at a Time</strong> · .*?</p>', re.S)


def fix_demo_footers(lunches: list[dict]) -> int:
    changed = 0
    for L in lunches:
        p = DOCS / "demos" / f"{L['slug']}.html"
        t = p.read_text(encoding="utf-8")
        footer = (f'<p><span data-i18n="partOf">Part of</span> <strong data-i18n="course">{E(ST.EN["course"])}</strong> · '
                  f'<a href="../en/lunches/{L["slug"]}.html" data-href-id="../id/lunches/{L["slug"]}.html" target="_top" data-i18n="readEpisode">Read the episode</a> · '
                  f'<a href="../en/demos/index.html" data-href-id="../id/demos/index.html" target="_top" data-i18n="allDemos">All demos</a> · '
                  f'<a href="{REPO_URL}" target="_blank" rel="noopener" data-i18n="repo">Course repository</a></p>')
        new = DEMO_FOOTER.sub(lambda _m: footer, t, count=1)
        if new != t:
            write(p, new)
            changed += 1
    return changed


DEMO_CRUMBS = re.compile(r'\n?  <nav class="demo-crumbs".*?</nav>', re.S)
DEMO_CRUMBS_CSS = re.compile(r'<style data-crumbs>.*?</style>\n?', re.S)
CRUMBS_CSS = ('<style data-crumbs>'
              '.demo-crumbs ol{list-style:none;margin:0 0 12px;padding:0;display:flex;flex-wrap:wrap;align-items:center;'
              'gap:.2em .45em;font-size:.85rem;color:var(--muted)}'
              '.demo-crumbs li{display:inline-flex;align-items:center;gap:.45em;min-inline-size:0}'
              '.demo-crumbs li+li::before{content:"›";opacity:.7}'
              '.demo-crumbs a{color:var(--accent);text-decoration:none}'
              '.demo-crumbs a:hover{text-decoration:underline}'
              '.demo-crumbs [aria-current="page"]{color:var(--ink);font-weight:600}'
              '</style>\n')


def fix_demo_crumbs(lunches: list[dict]) -> int:
    """Breadcrumb at the top of every stand-alone demo. The demo player shows it only outside an episode page
    and swaps the words to the reader's language (data-text-id, data-href-id, data-aria-id)."""
    def h1(f: Path) -> str:
        return rx(r"(?m)^#\s+(.+)$", f.read_text(encoding="utf-8")) if f.exists() else ""
    changed = 0
    for L in lunches:
        p = DOCS / "demos" / f"{L['slug']}.html"
        t = p.read_text(encoding="utf-8")
        en_label = h1(REPO / "lunches" / L["slug"] / "README.md") or f"Lunch {L['n']}"
        id_label = h1(REPO / "lunches" / L["slug"] / "README.id.md") or en_label
        en, idn = ST.EN, ST.ID
        nav = (f'\n  <nav class="demo-crumbs" aria-label="{E(en["crumbs_label"])}" data-aria-id="{E(idn["crumbs_label"])}" hidden><ol>'
               f'<li><a href="../en/index.html" data-href-id="../id/index.html" target="_top"><span aria-hidden="true">🏠</span> '
               f'<span data-text-id="{E(idn["crumb_home"])}">{E(en["crumb_home"])}</span></a></li>'
               f'<li><a href="../en/demos/index.html" data-href-id="../id/demos/index.html" target="_top" '
               f'data-text-id="{E(idn["nav_demos"])}">{E(en["nav_demos"])}</a></li>'
               f'<li aria-current="page"><span data-text-id="{E(id_label)}">{E(en_label)}</span></li></ol></nav>')
        new = t
        if DEMO_CRUMBS.search(new):
            new = DEMO_CRUMBS.sub(lambda _m: nav, new, count=1)
        else:
            new = new.replace('<div class="wrap">', '<div class="wrap">' + nav, 1)
        if DEMO_CRUMBS_CSS.search(new):
            new = DEMO_CRUMBS_CSS.sub(lambda _m: CRUMBS_CSS, new, count=1)
        else:
            new = new.replace("</head>", CRUMBS_CSS + "</head>", 1)
        if new != t:
            write(p, new)
            changed += 1
    return changed


# ============================================================================ landing
def author_section(root: str) -> str:
    chips = "".join(f'<span class="chip">{E(c)}</span>' for c in T["author_chips"])
    bio = "".join(f"<p>{E(p)}</p>" for p in T["author_bio"])
    li = AUTHOR["linkedin"][LANG]
    return f"""<section class="section" id="author">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('author_kicker'))}</p><h2>{E(tr('author_h2'))}</h2></div>
    <div class="card author-card reveal">
      <div class="author-id">
        {avatar("author-avatar")}
        <div><h3>{E(AUTHOR['name'])}</h3><p class="muted">{E(tr('author_role'))}</p></div>
      </div>
      <div class="author-chips">{chips}</div>
      <div class="author-bio">{bio}</div>
      <div class="author-actions">
        <a class="btn btn-linkedin" href="{E(li)}" target="_blank" rel="noopener"><span class="in" aria-hidden="true">in</span> {E(tr('author_linkedin'))}</a>
        <a class="btn" href="mailto:{E(AUTHOR['email'])}">📧 {E(tr('author_email_btn'))}</a>
      </div>
      <p class="author-inquiries">{E(tr('author_inquiries'))} <a href="mailto:{E(AUTHOR['email'])}"><b>{E(AUTHOR['email'])}</b></a>.</p>
      <p class="muted small">{E(tr('author_note'))}</p>
    </div>
  </div>
</section>"""


def landing(shell: Shell, lunches: list[dict]) -> None:
    out = OUT / "index.html"
    root = ""
    clock_items = "".join(
        f'<div class="seg-item" tabindex="0" style="--seg-color:{c}" data-min="{m}" data-name="{E(nm)}"><div class="min">{m}<small>{E(tr("clock_min"))}</small></div>'
        f'<div><h4>{E(nm)}</h4><p>{E(d)}</p></div></div>' for m, nm, d, c, _a in segments())
    legend = "".join(f'<span><i style="background:{p["color"]}"></i>{p["icon"]} {E(p["short"])}</span>' for p in SERIES["parts"])
    cast = "".join(
        f'<div class="person reveal"><div class="avatar" style="--c:{c["color"]}">{E(c["initials"])}</div><h4>{E(c["name"])}</h4>'
        f'<div class="role">{E(c["role"])}</div><q>{E(c["quote"])}</q><p>{E(c["bio"])}</p></div>' for c in SERIES["cast"])
    cards = []
    for L in lunches:
        p = PARTS[L["part"]]
        cards.append(
            f'<a class="ep-card reveal" href="lunches/{L["slug"]}.html" data-n="{L["n"]}" style="--c:{p["color"]}"><span class="done-flag">{E(tr("done_flag"))}</span>'
            f'<div class="ep-top"><span>{E(tr("ep_short", n=L["n"]))} · {p["icon"]} {E(p["short"])}</span><span class="state">{E(L["level"])}</span></div>'
            f'<h3>{E(L["ep"])}</h3><p class="sub">{E(tr("lunch_label", n=L["n"], title=L["title"]))}</p><p class="hook">{E(L["hook"])}</p>'
            f'<div class="ep-foot"><span>🔬 {E(L["lab"]["time"])} · {L["lab"]["cost"]}</span><span class="medal" title="{E(tr("badge_title", name=L["badge"]["name"]))}">{L["badge"]["icon"]}</span></div></a>')
    fin = SERIES["finale"]
    cards.append(
        f'<a class="ep-card finale reveal" href="labs/{fin["slug"]}.html" data-n="32" style="--c:#7b4ff0">'
        f'<div class="ep-top"><span>{E(tr("finale_tag"))}</span><span class="state">{E(tr("capstone"))}</span></div><h3>{E(fin["ep"])}</h3>'
        f'<p class="sub">{E(tr("capstone_title"))}</p><p class="hook">{E(fin["hook"])}</p>'
        f'<div class="ep-foot"><span>{E(tr("finale_time"))}</span><span class="medal">{fin["badge"]["icon"]}</span></div></a>')
    s1, s2 = SERIES["seasons"]
    first = lunches[0]
    director = SERIES["director"]
    sari = next((c for c in SERIES["cast"] if c["name"] == "Ibu Sari"), SERIES["cast"][0])
    faq_html = "".join(f"<details><summary>{E(q)}</summary><p>{E(a)}</p></details>" for q, a in T["faq"])
    stats = "".join(f'<div class="stat"><b>{E(a)}</b><span>{E(b)}</span></div>' for a, b in T["home_stats"])
    strip = []
    for i, (emo, h, ptxt) in enumerate(T["strip"], 1):
        quote_cls = " quote" if not h else ""
        h3 = f"“{E(director['question'])}”" if not h else E(h)
        strip.append(f'<div class="panel{quote_cls} reveal"><span class="num">0{i}</span><div class="emoji">{emo}</div><h3>{h3}</h3><p>{E(ptxt)}</p></div>')
    cost_cards = "".join(f'<div class="card cost-card reveal"><b>{a}</b><h3>{E(b)}</h3><p>{c}</p></div>' for a, b, c in T["cost_cards"])
    features = "".join(f'<div class="feature"><span>{a}</span><div><b>{E(b)}</b><p>{c}</p></div></div>' for a, b, c in T["features"])
    s2b = s2["blurb"]
    levels = SERIES["levels"]
    ld = {"@context": "https://schema.org", "@type": "Course", "name": COURSE_NAME, "description": tr("home_desc"),
          "inLanguage": LANG, "isAccessibleForFree": True, "url": f"{PAGES}/{LANG}/",
          "author": {"@type": "Person", "name": AUTHOR["name"], "url": AUTHOR["linkedin"][LANG], "jobTitle": "Senior Solutions Engineer"},
          "provider": {"@type": "Person", "name": AUTHOR["name"], "url": AUTHOR["linkedin"][LANG]},
          "hasCourseInstance": {"@type": "CourseInstance", "courseMode": "online", "courseWorkload": "PT31H"}}
    main = f"""<section class="hero">
  <div class="container hero-grid">
    <div>
      <p class="kicker"><span class="dot"></span>{E(tr('home_kicker'))}</p>
      <h1>{tr('home_h1')}</h1>
      <p class="lead">{E(tr('home_lead'))}</p>
      <a class="byline hero-byline" href="#author">{avatar("by-avatar")}<span>{E(tr('home_by', author=''))}<b>{E(AUTHOR['name'])}</b><small>{E(tr('byline_role'))}</small></span></a>
      <div class="ctas">
        <a class="btn btn-primary btn-lg" href="lunches/{first['slug']}.html" data-continue>{E(tr('start_ep1'))}</a>
        <a class="btn btn-lg" href="#journey">{E(tr('see_journey'))}</a>
      </div>
      <div class="stats">{stats}</div>
    </div>
    <div class="scene-art" aria-label="{E(tr('scene_label'))}">
      <div class="room"></div>
      <span class="sign">{E(tr('server_sign'))}</span>
      <div class="bubble" aria-live="off"><span class="who" data-who>{E(tr('bubble_who', name=sari['name'], role=sari['role']))}</span><span class="typed" data-typed>{E(director['question'])}</span></div>
      {pantry(0, 'data-mascot="progress"', tr("pantry_progress"))}
      {COFFEE}
      {CLOUD}
    </div>
  </div>
</section>

<section class="section" style="padding-top:20px">
  <div class="container">
    <div class="strip">{''.join(strip)}</div>
  </div>
</section>

<section class="section band" id="how">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('how_kicker'))}</p>
      <h2>{E(tr('how_h2'))}</h2>
      <p class="lead">{E(tr('how_lead'))}</p></div>
    <div class="clock-wrap">
      <div class="lunch-clock">{clock_svg()}</div>
      <div class="seg-list">{clock_items}</div>
    </div>
  </div>
</section>

<section class="section" id="journey">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('journey_kicker'))}</p>
      <h2>{E(tr('journey_h2'))}</h2>
      <p class="lead">{E(tr('journey_lead', s1=s1['blurb'], s2=s2b[0].lower() + s2b[1:]))}</p></div>
    <div class="card metro-card">
      <div class="metro-top"><div class="legend">{legend}<span><i style="background:#7b4ff0;block-size:12px;inline-size:12px;border-radius:50%"></i>{E(tr('finale_legend'))}</span></div>
        <div class="metro-progress"><span data-metro-text>{E(tr('metro_text'))}</span><div class="bar"><span data-metro-bar></span></div></div></div>
      <div data-metro><ol class="metro-fallback">{''.join(f'<li><a href="lunches/{L["slug"]}.html">{L["n"]} · {E(L["ep"])}</a></li>' for L in lunches)}</ol></div>
    </div>
  </div>
</section>

<section class="section band" id="director">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('director_kicker'))}</p>
      <h2>{E(tr('director_h2'))}</h2></div>
    <div class="card director">
      <div class="gauge">{gauge_svg()}</div>
      <div>
        <p class="q">{E(tr('director_asked'))}</p>
        <blockquote>“{E(director['question'])}”</blockquote>
        <p class="muted" data-director-when style="margin-bottom:4px">{E(tr('director_when'))}</p>
        <p class="director-answer" data-director-answer>“{E(director['start'])}”</p>
        <div class="answer-log" data-answer-log aria-hidden="true"></div>
        <p class="muted small" style="margin-top:14px">{E(tr('director_foot'))}</p>
      </div>
    </div>
  </div>
</section>

<section class="section" id="cast">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('cast_kicker'))}</p><h2>{E(tr('cast_h2'))}</h2>
      <p class="lead">{E(tr('cast_lead'))}</p></div>
    <div class="cast">{cast}</div>
  </div>
</section>

<section class="section band" id="episodes">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('eps_kicker'))}</p><h2>{E(tr('eps_h2'))}</h2>
      <p class="lead">{E(tr('eps_lead'))}</p></div>
    <span class="anchor-target" id="episodes-s1"></span><span class="anchor-target" id="episodes-s2"></span>
    <div class="toolbar">
      <div class="seg-tabs" role="group" aria-label="{E(tr('f_eps'))}">
        <button type="button" data-filter="all" aria-pressed="true">{E(tr('f_all'))}</button>
        <button type="button" data-filter="s1" aria-pressed="false">{E(tr('f_s1'))}</button>
        <button type="button" data-filter="s2" aria-pressed="false">{E(tr('f_s2'))}</button>
        <button type="button" data-filter="todo" aria-pressed="false">{E(tr('f_todo'))}</button>
        <button type="button" data-filter="done" aria-pressed="false">{E(tr('f_done'))}</button>
      </div>
      <input class="search" type="search" placeholder="{E(tr('search_eps'))}" aria-label="{E(tr('search_eps_label'))}" data-ep-search>
    </div>
    <div class="ep-grid" data-ep-grid>{''.join(cards)}</div>
  </div>
</section>

<section class="section" id="badges">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('badges_kicker'))} · <span data-badge-count>{E(tr('badges_count0'))}</span></p>
      <h2>{E(tr('badges_h2'))}</h2>
      <p class="lead">{tr('badges_lead', first=E(levels[0]['name']), last=E(levels[-1]['name']))}</p></div>
    <div class="badges" data-badges="16"></div>
    <p style="margin-top:20px"><a class="btn" href="lunchbox.html">{E(tr('open_lunchbox_btn'))}</a></p>
  </div>
</section>

<section class="section band" id="labs">
  <div class="container">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('labs_kicker'))}</p><h2>{E(tr('labs_h2'))}</h2>
      <p class="lead">{E(tr('labs_lead'))}</p></div>
    <div class="cost-grid">{cost_cards}</div>
    <div class="feature-row">{features}</div>
    <p style="margin-top:24px"><a class="btn btn-primary" href="labs/index.html">{E(tr('browse_labs'))}</a></p>
  </div>
</section>

{author_section(root)}

<section class="section band" id="faq">
  <div class="container narrow">
    <div class="section-head"><p class="kicker"><span class="dot"></span>{E(tr('faq_kicker'))}</p><h2>{E(tr('faq_h2'))}</h2></div>
    <div class="faq">{faq_html}</div>
  </div>
</section>

<section class="cta-band">
  <div class="container">
    <div>{pantry(1, label=tr("pantry_still"))}</div>
    <div><h2>{E(tr('cta_h2'))}</h2>
      <p>{E(tr('cta_p'))}</p>
      <a class="btn btn-warm btn-lg" href="lunches/{first['slug']}.html" data-continue>{E(tr('start_ep1'))}</a></div>
  </div>
</section>
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>"""
    shell.page(out=out, title=COURSE_NAME, desc=tr("home_desc"), main=main, body_attrs={"data-page": "home"}, active="",
               og_title=f"{COURSE_NAME} · {tr('home_by', author=AUTHOR['name'])}")


def lunchbox(shell: Shell) -> None:
    out = OUT / "lunchbox.html"
    s1, s2 = SERIES["seasons"]
    director = SERIES["director"]
    kpis = "".join(f'<div class="kpi"><b {attr}>{E(v)}</b><span>{E(lbl)}</span></div>' for attr, v, lbl in T["lb_kpis"])
    level0 = SERIES["levels"][0]["name"]
    main = f"""<section class="lab-hero hub-hero">
  <div class="container">
    <p class="kicker"><span class="dot"></span>{E(tr('lb_kicker'))}</p>
    <h1>{tr('lb_h1')}</h1>
    <p class="lead">{E(tr('lb_lead'))}</p>
  </div>
</section>
<div class="container lunchbox">
  <section class="card profile">
    <div class="level-badge" data-level-icon aria-hidden="true">🌱</div>
    <div><p class="kicker" style="margin-bottom:.2rem">{E(tr('lb_level'))}</p><h2 data-level-name style="margin:0">{E(level0)}</h2>
      <div class="xpbar"><span data-xp-bar></span></div><p class="muted" style="margin:0"><b data-xp>0 XP</b> · <span data-xp-next></span></p></div>
    <div class="profile-art">{pantry(0, 'data-mascot="progress"')}</div>
  </section>
  <div class="kpis">{kpis}</div>

  <section class="lb-section">
    <h2>{E(tr('lb_seasons'))}</h2>
    <div class="season-row"><div><b>{E(s1['name'])}</b><span class="muted">{E(s1['month'])} · {E(tr('level_basic'))}</span></div><div class="bar"><span data-season-bar="1-21"></span></div><b data-season-text="1-21">0 / 21</b></div>
    <div class="season-row"><div><b>{E(s2['name'])}</b><span class="muted">{E(s2['month'])} · {E(tr('level_advanced'))}</span></div><div class="bar"><span data-season-bar="22-31"></span></div><b data-season-text="22-31">0 / 10</b></div>
  </section>

  <section class="lb-section">
    <h2>{E(tr('lb_director'))}</h2>
    <div class="card director">
      <div class="gauge">{gauge_svg()}</div>
      <div><p class="q">“{E(director['question'])}”</p>
        <p class="muted" data-director-when style="margin-bottom:4px">{E(tr('director_when'))}</p>
        <p class="director-answer" data-director-answer>“{E(director['start'])}”</p>
        <div class="answer-log" data-answer-log aria-hidden="true"></div></div>
    </div>
  </section>

  <section class="lb-section">
    <h2>{E(tr('lb_trophy'))} <span class="muted" style="font-size:1rem" data-badge-count></span></h2>
    <div class="badges" data-badges></div>
  </section>

  <section class="lb-section">
    <div class="lb-head"><h2>{E(tr('lb_notebook'))}</h2><div class="chips"><button class="btn btn-sm" type="button" data-notes-copy>{E(tr('lb_copy_md'))}</button>
      <button class="btn btn-sm" type="button" data-notes-download>{E(tr('lb_download_md'))}</button></div></div>
    <div class="notebook" data-notebook></div>
  </section>

  <section class="lb-section">
    <div class="lb-head"><h2>{E(tr('lb_cert'))}</h2><div class="chips"><input class="search" type="text" maxlength="60" placeholder="{E(tr('cert_name_ph'))}" aria-label="{E(tr('cert_name_ph'))}" data-cert-name>
      <button class="btn btn-sm" type="button" data-cert-print>{E(tr('cert_print'))}</button>
      <button class="btn btn-sm btn-linkedin" type="button" data-share-cert><span class="in" aria-hidden="true">in</span> {E(tr('cert_share'))}</button></div></div>
    <div class="cert">
      <div class="c-kick">{E(tr('cert_kick'))}</div>
      <h2 data-c-title>{E(tr('cert_title'))}</h2>
      <p>{E(tr('cert_certifies'))}</p>
      <div class="c-name" data-c-name>{E(tr('cert_name'))}</div>
      <p data-c-body>{E(tr('cert_body'))}</p>
      <div class="c-medals" data-c-medals>🍱</div>
      <div class="c-foot"><div><b>{E(tr('cert_date'))}</b><br><span data-c-date></span></div>
        <div style="text-align:center"><b>{E(AUTHOR['name'])}</b><br>{E(tr('cert_author_label'))}</div>
        <div style="text-align:end"><b>Ibu Sari</b><br>{E(tr('cert_director'))}</div></div>
      <p class="cert-fine">{E(tr('cert_fine'))}</p>
    </div>
  </section>

  <section class="lb-section">
    <h2>{E(tr('lb_data'))}</h2>
    <div class="chips"><button class="btn btn-sm" type="button" data-export>{E(tr('export'))}</button>
      <label class="btn btn-sm">{E(tr('import'))}<input type="file" accept="application/json,.json" data-import hidden></label>
      <button class="btn btn-sm btn-ghost" type="button" data-reset>{E(tr('reset'))}</button></div>
  </section>
</div>"""
    shell.page(out=out, title=tr("lb_title"), desc=tr("lb_desc"), main=main, body_attrs={"data-page": "lunchbox"}, active="lunchbox",
               crumbs=[(tr("crumb_home"), "index.html"), (tr("lb_title"), None)])


# ============================================================================ LinkedIn share pages
def share_page(out: Path, title: str, desc: str, go: str) -> None:
    url = f"{PAGES}/{LANG}/share/{out.name}"
    card = f"{PAGES}/assets/social-card{'' if LANG == 'en' else '-' + LANG}.png"
    doc = f"""<!DOCTYPE html>
<html lang="{T['html_lang']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{E(title)}</title>
<meta name="description" content="{E(desc)}">
<meta name="author" content="{E(AUTHOR['name'])}">
<link rel="canonical" href="{url}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{E(COURSE_NAME)}">
<meta property="og:title" content="{E(title)}">
<meta property="og:description" content="{E(desc)}">
<meta property="og:url" content="{url}">
<meta property="og:locale" content="{T['og_locale']}">
<meta property="og:image" content="{card}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="../../assets/favicon.svg" type="image/svg+xml">
<script>location.replace({json.dumps(go)});</script>
</head>
<body style="font-family:system-ui,sans-serif;padding:2rem">
<p>{E(tr('share_redirect'))} <a href="{E(go)}">{E(tr('share_open'))}</a></p>
</body>
</html>
"""
    write(out, doc)


def share_pages(lunches: list[dict]) -> int:
    d = OUT / "share"
    items = [(f"badge-l{L['n']}", L["badge"]) for L in lunches] + [("badge-finale", SERIES["finale"]["badge"])]
    items += [(f"badge-{b['id']}", b) for b in SERIES["specialBadges"]]
    for sid, b in items:
        share_page(d / f"{sid}.html", tr("share_badge_title", icon=b["icon"], name=b["name"], course=COURSE_NAME),
                   tr("share_badge_desc", desc=b["desc"], course=COURSE_NAME, author=AUTHOR["name"]), "../index.html#badges")
    share_page(d / "certificate.html", tr("share_cert_title", course=COURSE_NAME),
               tr("share_cert_desc", course=COURSE_NAME, author=AUTHOR["name"]), "../index.html")
    share_page(d / "certificate-complete.html", tr("share_done_title", course=COURSE_NAME),
               tr("share_done_desc", course=COURSE_NAME, author=AUTHOR["name"]), "../index.html")
    return len(items) + 2


# ============================================================================ 404, language chooser, redirects
def not_found(shell: Shell) -> None:
    out = DOCS / "404.html"
    en, idn = ST.EN, ST.ID
    main = f"""<section class="lost"><div>
  {pantry(0, label=en["pantry_overheat"])}
  <h1>{E(en['nf_h1'])}</h1>
  <p class="lead" style="margin-inline:auto">{E(en['nf_lead'])}</p>
  <p><a class="btn btn-primary" href="{PAGES}/en/index.html">{E(en['nf_home'])}</a> <a class="btn" href="{PAGES}/en/labs/index.html">{E(en['nf_labs'])}</a></p>
  <hr style="margin:28px auto;max-inline-size:420px;border:0;border-top:1px solid var(--line)">
  <h2 lang="id" style="font-size:1.3rem">{E(idn['nf_h1'])}</h2>
  <p lang="id" class="muted" style="margin-inline:auto;max-inline-size:60ch">{E(idn['nf_lead'])}</p>
  <p lang="id"><a class="btn" href="{PAGES}/id/index.html">{E(idn['nf_home'])}</a> <a class="btn" href="{PAGES}/id/labs/index.html">{E(idn['nf_labs'])}</a></p>
</div></section>"""
    shell.page(out=out, title=f"{en['nf_title']} · {idn['nf_title']}", desc="This page does not exist. Halaman ini tidak ada.",
               main=main, body_attrs={"data-page": "404"}, absolute=True,
               crumbs=[(en["crumb_home"], "index.html"), (f"{en['nf_title']} · {idn['nf_title']}", None)])


def root_index(v: str) -> None:
    en, idn = ST.EN, ST.ID
    title = f"{en['course']} · {idn['course']}"
    desc = f"{en['home_desc']} {idn['home_desc']}"
    card = f"{PAGES}/assets/social-card.png"
    doc = f"""<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{E(title)}</title>
<meta name="description" content="{E(desc)}">
<meta name="author" content="{E(AUTHOR['name'])}">
<link rel="canonical" href="{PAGES}/">
<link rel="alternate" hreflang="en" href="{PAGES}/en/">
<link rel="alternate" hreflang="id" href="{PAGES}/id/">
<link rel="alternate" hreflang="x-default" href="{PAGES}/">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{E(en['course'])}">
<meta property="og:title" content="{E(en['course'])} · {E(en['home_by'].format(author=AUTHOR['name']))}">
<meta property="og:description" content="{E(en['home_desc'])}">
<meta property="og:url" content="{PAGES}/">
<meta property="og:image" content="{card}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="assets/favicon.svg" type="image/svg+xml">
<script>(function(){{var d=document.documentElement;d.classList.add('js');try{{var t=localStorage.getItem('azlunch.theme');if(!t)t=matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';d.setAttribute('data-theme',t);}}catch(e){{}}
if(/[?&]choose\\b/.test(location.search))return;var l='';try{{l=localStorage.getItem('azlunch.lang')||'';}}catch(e){{}}
if(l!=='en'&&l!=='id'){{var n=((navigator.languages&&navigator.languages[0])||navigator.language||'').toLowerCase();l=/^id\\b/.test(n)?'id':'en';}}
location.replace(l+'/'+location.hash);}})();</script>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;800&display=swap">
<link rel="stylesheet" href="assets/site.css?v={v}">
</head>
<body class="chooser-page">
<main class="chooser">
  <div class="chooser-brand">{LOGO}<div><b>{E(en['brand_main'])}</b><small>{E(en['brand_small'])} · {E(AUTHOR['name'])}</small></div></div>
  <h1>{E(en['choose_title'])} <span lang="id">· {E(idn['choose_title'])}</span></h1>
  <div class="chooser-grid">
    <a class="chooser-card" href="en/" hreflang="en" data-pick="en"><span class="flag" aria-hidden="true">EN</span><b>English</b><span>{E(en['course'])}</span></a>
    <a class="chooser-card" href="id/" hreflang="id" lang="id" data-pick="id"><span class="flag" aria-hidden="true">ID</span><b>Bahasa Indonesia</b><span>{E(idn['course'])}</span></a>
  </div>
  <p class="muted small">{E(en['privacy_nocount'])}</p>
</main>
<script>Array.prototype.forEach.call(document.querySelectorAll('[data-pick]'),function(a){{a.addEventListener('click',function(){{try{{localStorage.setItem('azlunch.lang',a.getAttribute('data-pick'));}}catch(e){{}}}});}});</script>
</body>
</html>
"""
    write(DOCS / "index.html", doc)


def redirect_stub(out: Path, rel_target: str) -> None:
    up = rel_url(DOCS, out.parent)
    up = "" if up == "." else up + "/"
    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Azure Fundamentals: One Lunch at a Time</title>
<meta name="robots" content="noindex">
<link rel="canonical" href="{PAGES}/en/{rel_target}">
<script>(function(){{var l='';try{{l=localStorage.getItem('azlunch.lang')||'';}}catch(e){{}}if(l!=='en'&&l!=='id'){{l=/^id\\b/i.test(navigator.language||'')?'id':'en';}}location.replace('{up}'+l+'/{rel_target}'+location.search+location.hash);}})();</script>
<meta http-equiv="refresh" content="3;url={up}en/{rel_target}">
</head>
<body style="font-family:system-ui,sans-serif;padding:2rem">
<p>This page has moved · Halaman ini sudah pindah: <a href="{up}en/{rel_target}">English</a> · <a href="{up}id/{rel_target}" lang="id">Bahasa Indonesia</a></p>
</body>
</html>
"""
    write(out, doc)


def redirect_stubs(lunches: list[dict], lab_slugs: list[str]) -> int:
    n = 0
    for L in lunches:
        redirect_stub(DOCS / "lunches" / f"{L['slug']}.html", f"lunches/{L['slug']}.html")
        n += 1
    for slug in lab_slugs:
        redirect_stub(DOCS / "labs" / f"{slug}.html", f"labs/{slug}.html")
        n += 1
    for path in ("labs/index.html", "lunchbox.html", "demos/index.html"):
        redirect_stub(DOCS / path, path)
        n += 1
    return n


# ============================================================================ social card
def social_card(lang: str) -> None:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("  (Pillow not installed: skipped the social cards)")
        return
    texts = {
        "en": {"small": "Azure Fundamentals", "title": ["One Lunch at a Time"],
               "line": "31 lunch-sized episodes · animated demos · hands-on labs",
               "desc": ["Move one tired pantry server into Azure — and learn every", "fundamental service on the way."],
               "chips": ["VMs", "Storage", "Networking", "Databases", "Load balancing", "Identity", "Governance"],
               "by": "by Stefanus Pinarta", "role": "Free course · English + Bahasa Indonesia"},
        "id": {"small": "Dasar-Dasar Azure", "title": ["Satu Makan Siang,", "Satu Pelajaran"],
               "line": "31 episode seukuran makan siang · demo animasi · lab praktik",
               "desc": ["Pindahkan satu server pantry yang kelelahan ke Azure —", "dan kuasai setiap layanan dasarnya."],
               "chips": ["VM", "Storage", "Jaringan", "Database", "Load balancing", "Identitas", "Tata kelola"],
               "by": "oleh Stefanus Pinarta", "role": "Kursus gratis · Bahasa Indonesia + English"},
    }[lang]
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

    def fit(text, size, bold, width):
        while size > 16 and d.textlength(text, font=font(size, bold)) > width:
            size -= 1
        return size

    d.rounded_rectangle([70, 130, 270, 310], radius=34, fill="#e2482f")
    d.rounded_rectangle([88, 148, 172, 292], radius=22, fill="#fff6e8")
    d.rounded_rectangle([184, 148, 252, 212], radius=18, fill="#ffc14a")
    d.rounded_rectangle([184, 226, 252, 292], radius=18, fill="#45cf8c")
    d.ellipse([100, 216, 132, 248], fill="#1665d8")
    d.ellipse([118, 202, 156, 240], fill="#1665d8")
    d.rectangle([108, 230, 158, 248], fill="#1665d8")
    X, maxw = 320, W - 320 - 50
    y = 92
    d.text((X, y), texts["small"], font=font(38, False), fill="#68738c")
    y += 52
    tsize = min(fit(t, 70 if len(texts["title"]) == 1 else 62, True, maxw) for t in texts["title"])
    for t in texts["title"]:
        d.text((X, y), t, font=font(tsize), fill="#16203a")
        y += int(tsize * 1.12)
    y += 14
    s = fit(texts["line"], 29, False, maxw)
    d.text((X, y), texts["line"], font=font(s, False), fill="#3b4763")
    y += 46
    for t in texts["desc"]:
        d.text((X, y), t, font=font(fit(t, 26, False, maxw), False), fill="#3b4763")
        y += 36
    y += 16
    x = X
    for c in texts["chips"]:
        w = d.textlength(c, font=font(22)) + 32
        if x + w > W - 60:
            break
        d.rounded_rectangle([x, y, x + w, y + 42], radius=21, fill="#e6f0ff")
        d.text((x + 16, y + 8), c, font=font(22), fill="#1665d8")
        x += w + 10
    # author
    d.ellipse([70, 520, 124, 574], fill="#16203a")
    ini = AUTHOR["initials"]
    d.text((97 - d.textlength(ini, font=font(22)) / 2, 534), ini, font=font(22), fill="#ffffff")
    d.text((140, 520), texts["by"], font=font(26), fill="#16203a")
    d.text((140, 554), texts["role"], font=font(19, False), fill="#68738c")
    site = PAGES.split("://", 1)[-1]
    site = site if PLACEHOLDER not in PAGES else "github.com"
    sw = d.textlength(site, font=font(20, False))
    d.text((W - 60 - sw, 560), site, font=font(20, False), fill="#68738c")
    img.save(DOCS / "assets" / f"social-card{'' if lang == 'en' else '-' + lang}.png", optimize=True)


# ============================================================================ main
ALL: list[dict] = []


def main() -> int:
    global ALL
    if PLACEHOLDER in PAGES:
        print("Note: links still use the placeholder user name (run tools/set_github_username.py first).")
    (DOCS / "assets").mkdir(parents=True, exist_ok=True)
    write(DOCS / "assets" / "favicon.svg", FAVICON)
    injected = inject_demo_translations()
    load_demo_titles()
    for lang in LANGS:
        social_card(lang)
    by_lang: dict[str, list[dict]] = {}
    for lang in LANGS:
        set_lang(lang)
        by_lang[lang] = course_lunches()
        write_course_data(by_lang[lang])
    old = DOCS / "assets" / "course-data.js"
    if old.exists():
        old.unlink()
    shell = Shell()
    counts = {}
    lab_slugs = [L["slug"] for L in by_lang["en"]] + [bi.CAPSTONE[0]]
    for lang in LANGS:
        set_lang(lang)
        lunches = ALL = by_lang[lang]
        for i, L in enumerate(lunches):
            lunch_page(shell, L, lunches[i - 1] if i else None, lunches[i + 1] if i + 1 < len(lunches) else None)
        lab_list = []
        by_slug = {L["slug"]: L for L in lunches}
        for slug in lab_slugs:
            m = lab_meta(slug)
            L = by_slug.get(slug)
            lab_list.append({"slug": slug, "num": m["num"], "title": m["title"], "time": m["time"], "cost": m["cost"],
                             "part": L["part"] if L else 5, "diff": m["difficulty"],
                             "pairs": tr("pairs_episode", n=L["n"], ep=L["ep"]) if L else tr("pairs_finale")})
        for x in lab_list:
            lab_page(shell, x["slug"], by_slug.get(x["slug"]), lab_list)
        labs_hub(shell, lab_list)
        demos_hub(shell, lunches)
        landing(shell, lunches)
        lunchbox(shell)
        counts[lang] = share_pages(lunches)
    set_lang("en")
    changed = fix_demo_footers(by_lang["en"])
    crumbed = fix_demo_crumbs(by_lang["en"])
    not_found(shell)
    root_index(shell.v)
    stubs = redirect_stubs(by_lang["en"], lab_slugs)
    n_pages = len(list(DOCS.rglob("*.html")))
    print(f"Built the site in {', '.join(LANGS)}: {len(by_lang['en'])} episode pages and {len(lab_slugs)} lab pages per language, "
          f"hubs, lunchbox, {sum(counts.values())} share pages, {stubs} redirects, 404 and the language chooser "
          f"({n_pages} HTML files in docs/; demo footers updated: {changed}; demo breadcrumbs updated: {crumbed}; "
          f"demo translations embedded: {injected}).")
    if FALLBACKS:
        print(f"  ! {len(FALLBACKS)} page(s) fell back to English because the translation is missing, e.g. "
              + ", ".join(sorted(FALLBACKS)[:4]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
