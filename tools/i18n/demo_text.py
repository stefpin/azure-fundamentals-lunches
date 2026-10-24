#!/usr/bin/env python3
"""Extract, check and inject the translatable words of the animated demos.

    python3 tools/i18n/demo_text.py extract [slug ...]   # docs/demos/<slug>.html -> tools/i18n/demos-src/<slug>.en.json
    python3 tools/i18n/demo_text.py check   [slug ...]   # tools/i18n/demos/<slug>.id.json against the English source
    python3 tools/i18n/demo_text.py inject  [slug ...]   # embed the translations in docs/demos/<slug>.html

With no slug, every demo is processed. The animation itself is shared by both languages: the demo player
(engine v1.1) reads the <script type="application/json" id="demo-i18n"> block and swaps the words when the page is
opened with ?lang=id or the reader chose Indonesian on the course website. Standard library only.
"""
from __future__ import annotations

import html
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DEMOS = REPO / "docs" / "demos"
SRC = REPO / "tools" / "i18n" / "demos-src"
OUT = REPO / "tools" / "i18n" / "demos"
PAGE_KEYS = ["doc_title", "kicker", "title", "lede", "svgTitle", "svgDesc"]
EN_STOP = {"the", "and", "of", "to", "is", "you", "your", "with", "that", "for", "this", "are", "it", "on", "be",
           "can", "will", "from", "when", "what", "which", "into", "they", "their", "have", "has", "not", "but"}
BAD_VOICE = re.compile(r"\b(kamu|kau|lo|gue|elo|milikmu|tugasmu|akunmu|datamu|servermu|aplikasimu)\b", re.I)
I18N_BLOCK = re.compile(r'\n?<script type="application/json" id="demo-i18n">.*?</script>\n?', re.S)


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", s))).strip()


def slugs(args: list[str]) -> list[str]:
    if args:
        return [Path(a).stem.replace(".id", "").replace(".en", "") for a in args]
    return sorted(p.stem for p in DEMOS.glob("[0-9][0-9]-*.html"))


def steps_of(doc: str) -> list[dict]:
    m = re.search(r'<script type="application/json" id="demo-steps">(.*?)</script>', doc, re.S)
    return json.loads(m.group(1)) if m else []


def first(pattern: str, doc: str, inner_html: bool = False) -> str:
    m = re.search(pattern, doc, re.S)
    if not m:
        return ""
    return m.group(1).strip() if inner_html else norm(m.group(1))


def svg_labels(doc: str) -> list[str]:
    m = re.search(r'<svg id="stage".*?</svg>', doc, re.S)
    body = m.group(0) if m else ""
    body = re.sub(r"<(title|desc)\b.*?</\1>", "", body, flags=re.S)
    out: list[str] = []
    for tm in re.finditer(r"<text\b[^>]*>(.*?)</text>", body, re.S):
        inner = tm.group(1)
        parts = re.findall(r"<tspan\b[^>]*>(.*?)</tspan>", inner, re.S) if "<tspan" in inner else [inner]
        for p in parts:
            t = norm(p)
            if t and not re.fullmatch(r"[\d\s.,:%/+\-–—×x()$€£¥₹]*", t) and t not in out:
                out.append(t)
    return out


def extract(slug: str) -> dict:
    doc = (DEMOS / f"{slug}.html").read_text(encoding="utf-8")
    page = {
        "doc_title": first(r"<title>(.*?)</title>", doc),
        "kicker": first(r'<p class="kicker">(.*?)</p>', doc),
        "title": first(r"<h1>(.*?)</h1>", doc),
        "lede": first(r'<p class="lede">(.*?)</p>', doc, inner_html=True),
        "svgTitle": first(r'<title id="svgTitle">(.*?)</title>', doc),
        "svgDesc": first(r'<desc id="svgDesc">(.*?)</desc>', doc),
    }
    steps = []
    for s in steps_of(doc):
        e = {"title": s.get("title", ""), "text": s.get("text", "")}
        if s.get("tip"):
            e["tip"] = s["tip"]
        if s.get("set"):
            e["set"] = s["set"]
        steps.append(e)
    return {"page": page, "steps": steps, "svg": svg_labels(doc)}


def english_ratio(s: str) -> float:
    ws = re.findall(r"[A-Za-z']+", s)
    return (sum(1 for w in ws if w.lower() in EN_STOP) / len(ws)) if len(ws) >= 10 else 0.0


def check(slug: str) -> tuple[list[str], list[str]]:
    errs, warns = [], []
    src_p, id_p = SRC / f"{slug}.en.json", OUT / f"{slug}.id.json"
    if not (DEMOS / f"{slug}.html").exists():
        return [f"demo docs/demos/{slug}.html not found"], []
    src = extract(slug) if not src_p.exists() else json.loads(src_p.read_text(encoding="utf-8"))
    if not id_p.exists():
        return [f"{id_p.relative_to(REPO)} is missing"], []
    try:
        tr = json.loads(id_p.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"{id_p.name} is not valid JSON: {exc}"], []
    page = tr.get("page") or {}
    for k in PAGE_KEYS:
        if not isinstance(page.get(k), str) or not page[k].strip():
            errs.append(f"page.{k} is missing or empty")
    extra = set(page) - set(PAGE_KEYS)
    if extra:
        errs.append(f"page has unknown keys {sorted(extra)}")
    if "<code>" in src["page"].get("lede", "") and page.get("lede") and "<code>" not in page["lede"]:
        warns.append("page.lede lost its <code> formatting")
    if re.search(r"<(?!/?(code|strong|em)>)", page.get("lede", "")):
        errs.append("page.lede may only contain <code>, <strong> or <em> tags")
    es, ts = src["steps"], tr.get("steps") or []
    if len(es) != len(ts):
        errs.append(f"steps: English has {len(es)}, Indonesian has {len(ts)}")
    for k, (a, b) in enumerate(zip(es, ts), 1):
        if not isinstance(b, dict):
            errs.append(f"step {k}: not an object")
            continue
        for key in ("title", "text"):
            if not isinstance(b.get(key), str) or not b[key].strip():
                errs.append(f"step {k}: '{key}' missing or empty")
        if bool(a.get("tip")) != bool(b.get("tip")):
            errs.append(f"step {k}: 'tip' must be present only where the English step has one")
        if set((a.get("set") or {})) != set((b.get("set") or {})):
            errs.append(f"step {k}: 'set' keys must be {sorted((a.get('set') or {}))}")
        unknown = set(b) - {"title", "text", "tip", "set"}
        if unknown:
            errs.append(f"step {k}: unknown keys {sorted(unknown)} (only title, text, tip, set)")
        n = len(f"{b.get('title', '')} {b.get('text', '')} {b.get('tip', '')}".split())
        if n > 95:
            warns.append(f"step {k}: {n} words — keep narration under about 70–90 words")
        for key in ("title", "text", "tip"):
            v = b.get(key) or ""
            if BAD_VOICE.search(v):
                errs.append(f"step {k}: informal voice in '{key}' — use 'Anda'")
            if english_ratio(v) > 0.15:
                warns.append(f"step {k}: '{key}' looks untranslated")
            if v and v == a.get(key) and len(v.split()) > 3:
                warns.append(f"step {k}: '{key}' is identical to English")
    sv = tr.get("svg") or {}
    if not isinstance(sv, dict):
        errs.append("svg must be an object {\"English label\": \"Indonesian label\"}")
        sv = {}
    for k, v in sv.items():
        if k not in src["svg"]:
            errs.append(f"svg key not found in the English labels: {k!r}")
        if not isinstance(v, str) or not v.strip():
            errs.append(f"svg value for {k!r} is empty")
    for k in ("page", "steps", "svg"):
        if k not in tr:
            errs.append(f"top-level key '{k}' missing")
    extra_top = set(tr) - {"page", "steps", "svg"}
    if extra_top:
        errs.append(f"unknown top-level keys {sorted(extra_top)}")
    for k in PAGE_KEYS:
        if BAD_VOICE.search(page.get(k, "")):
            errs.append(f"page.{k}: informal voice — use 'Anda'")
    return errs, warns


def inject(slug: str) -> bool:
    path = DEMOS / f"{slug}.html"
    id_p = OUT / f"{slug}.id.json"
    if not id_p.exists():
        return False
    data = json.loads(id_p.read_text(encoding="utf-8"))
    payload = json.dumps({"id": data}, ensure_ascii=False, indent=1).replace("</", "<\\/")
    block = f'\n<script type="application/json" id="demo-i18n">\n{payload}\n</script>\n'
    doc = path.read_text(encoding="utf-8")
    doc = I18N_BLOCK.sub("\n", doc)
    m = re.search(r'<script type="application/json" id="demo-steps">.*?</script>\n?', doc, re.S)
    if not m:
        raise SystemExit(f"{slug}: demo-steps block not found")
    doc = doc[:m.end()].rstrip("\n") + "\n" + block + doc[m.end():].lstrip("\n")
    path.write_text(doc, encoding="utf-8")
    return True


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] not in ("extract", "check", "inject"):
        print(__doc__)
        return 2
    mode, names = argv[1], slugs(argv[2:])
    if mode == "extract":
        SRC.mkdir(parents=True, exist_ok=True)
        for s in names:
            data = extract(s)
            (SRC / f"{s}.en.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"{s}: {len(data['steps'])} steps, {len(data['svg'])} SVG labels")
        return 0
    if mode == "inject":
        done = [s for s in names if inject(s)]
        print(f"Injected translations into {len(done)} demo(s); {len(names) - len(done)} without a translation.")
        return 0
    total = 0
    for s in names:
        errs, warns = check(s)
        if errs or warns:
            print(f"\n{s}")
            for e in errs:
                print(f"   ✗ {e}")
            for w in warns:
                print(f"   ! {w}")
        total += len(errs)
    print(f"\nChecked {len(names)} demo(s): {total} error(s).")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
