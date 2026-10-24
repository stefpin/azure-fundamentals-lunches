#!/usr/bin/env python3
"""Validate interactive demo files (docs/demos/*.html) against the demo player contract.

Checks, per demo:
  * the shared engine <script> is byte-identical to templates/demo-template.html
  * the steps JSON (<script type="application/json" id="demo-steps">) parses
  * every step has a title and text, and only uses known keys
  * every id a step references exists (show/hide targets must carry data-el,
    packet targets must be <path> elements)
  * camera "view" values have four numbers
  * the optional translations (<script type="application/json" id="demo-i18n">) match the steps:
    same number of steps, title and text in each, only existing "set" ids, SVG labels that exist
  * required player controls exist, <html lang> is set, the file is self-contained
    (no external scripts/styles/images, no inline on* handlers, no javascript: URLs)

Usage:
  python3 tools/validate_demo.py                 # all demos in docs/demos
  python3 tools/validate_demo.py docs/demos/06-virtual-machines-basic.html

Standard library only. Exit code 1 if any demo has errors.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from html import unescape
from html.parser import HTMLParser
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TEMPLATE = REPO / "templates" / "demo-template.html"
ENGINE_MARKER = "LUNCH DEMO PLAYER · v1.1 · engine"
REQUIRED_IDS = ["stage", "packets", "stepCount", "stepTitle", "stepText", "stepTip",
                "prev", "play", "next", "restart", "speed", "bar", "stepsList", "demo-steps"]
LIST_KEYS = ["show", "hide", "highlight", "ok", "bad", "flow", "dim"]
ALLOWED_KEYS = set(LIST_KEYS) | {"title", "text", "tip", "packets", "set", "view", "duration"}


class DemoParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ids: dict[str, dict] = {}
        self.lang = None
        self.scripts: list[dict] = []
        self._script: dict | None = None
        self.issues: list[str] = []

    def handle_starttag(self, tag, attrs):
        a = {k: (v if v is not None else "") for k, v in attrs}
        if tag == "html":
            self.lang = a.get("lang")
        if "id" in a:
            if a["id"] in self.ids:
                self.issues.append(f"duplicate id '{a['id']}'")
            self.ids[a["id"]] = {"tag": tag, "data-el": "data-el" in a}
        for k, v in a.items():
            if k.lower().startswith("on"):
                self.issues.append(f"inline event handler '{k}' on <{tag}> (use addEventListener)")
            if isinstance(v, str) and v.strip().lower().startswith("javascript:"):
                self.issues.append(f"javascript: URL in <{tag} {k}>")
        if tag == "script":
            if a.get("src"):
                self.issues.append(f"external script '{a['src']}' (demos must be self-contained)")
            self._script = {"type": a.get("type", ""), "id": a.get("id", ""), "text": ""}
        if tag == "link" and a.get("href") and "stylesheet" in a.get("rel", ""):
            self.issues.append(f"external stylesheet '{a['href']}'")
        if tag in ("img", "image", "iframe", "video", "audio", "source") and a.get("src", "").startswith(("http:", "https:", "//")):
            self.issues.append(f"external media '{a['src']}'")

    handle_startendtag = handle_starttag

    def handle_endtag(self, tag):
        if tag == "script" and self._script is not None:
            self.scripts.append(self._script)
            self._script = None

    def handle_data(self, data):
        if self._script is not None:
            self._script["text"] += data


def engine_text(scripts: list[dict]) -> str | None:
    for s in scripts:
        if ENGINE_MARKER in s["text"]:
            return s["text"].strip()
    return None


def template_engine_hash() -> str | None:
    if not TEMPLATE.exists():
        return None
    p = DemoParser()
    p.feed(TEMPLATE.read_text(encoding="utf-8"))
    txt = engine_text(p.scripts)
    return hashlib.sha256(txt.encode("utf-8")).hexdigest() if txt else None


def step_seconds(step: dict) -> float:
    if step.get("duration"):
        return float(step["duration"]) / 1000
    words = len(" ".join(str(step.get(k, "")) for k in ("title", "text", "tip")).split())
    return max(5000, words * 340) / 1000


def validate(path: Path, tmpl_hash: str | None) -> tuple[list[str], list[str], dict]:
    errors: list[str] = []
    warnings: list[str] = []
    html = path.read_text(encoding="utf-8")
    p = DemoParser()
    p.feed(html)
    errors.extend(p.issues)
    if not p.lang:
        errors.append("<html> has no lang attribute")
    if re.search(r"@import|url\(\s*['\"]?(https?:)?//", html):
        errors.append("CSS references an external resource (@import or url(http...))")
    for rid in REQUIRED_IDS:
        if rid not in p.ids:
            errors.append(f"required element id='{rid}' is missing")

    eng = engine_text(p.scripts)
    if not eng:
        errors.append("shared engine script not found (copy it from templates/demo-template.html)")
    elif tmpl_hash and hashlib.sha256(eng.encode("utf-8")).hexdigest() != tmpl_hash:
        errors.append("shared engine script differs from templates/demo-template.html (do not edit the engine)")

    steps_json = next((s["text"] for s in p.scripts if s["id"] == "demo-steps"), None)
    info = {"steps": 0, "minutes": 0.0}
    if steps_json is None:
        errors.append("steps JSON block <script type=\"application/json\" id=\"demo-steps\"> not found")
        return errors, warnings, info
    try:
        steps = json.loads(steps_json)
    except json.JSONDecodeError as exc:
        errors.append(f"steps JSON does not parse: {exc}")
        return errors, warnings, info
    if not isinstance(steps, list) or not steps:
        errors.append("steps JSON must be a non-empty array")
        return errors, warnings, info

    info["steps"] = len(steps)
    info["minutes"] = round(sum(step_seconds(s) for s in steps if isinstance(s, dict)) / 60, 1)
    if len(steps) < 5:
        warnings.append(f"only {len(steps)} steps — aim for 6 to 14")
    if len(steps) > 18:
        warnings.append(f"{len(steps)} steps — consider splitting the story")

    for n, s in enumerate(steps, 1):
        where = f"step {n}"
        if not isinstance(s, dict):
            errors.append(f"{where}: must be an object")
            continue
        unknown = set(s) - ALLOWED_KEYS
        if unknown:
            errors.append(f"{where}: unknown key(s) {sorted(unknown)}")
        if not str(s.get("title", "")).strip():
            errors.append(f"{where}: missing title")
        if not str(s.get("text", "")).strip():
            errors.append(f"{where}: missing text")
        for key in LIST_KEYS:
            val = s.get(key, [])
            if not isinstance(val, list):
                errors.append(f"{where}: '{key}' must be a list of ids")
                continue
            for rid in val:
                if rid not in p.ids:
                    errors.append(f"{where}: {key} → unknown id '{rid}'")
                elif key in ("show", "hide") and not p.ids[rid]["data-el"]:
                    errors.append(f"{where}: {key} → '{rid}' has no data-el attribute")
        for pk in s.get("packets", []) or []:
            pid = pk if isinstance(pk, str) else (pk.get("path") if isinstance(pk, dict) else None)
            if not pid or pid not in p.ids:
                errors.append(f"{where}: packets → unknown path '{pid}'")
            elif p.ids[pid]["tag"] != "path":
                errors.append(f"{where}: packets → '{pid}' is a <{p.ids[pid]['tag']}>, not a <path>")
        if "set" in s:
            if not isinstance(s["set"], dict):
                errors.append(f"{where}: 'set' must be an object of id → text")
            else:
                for rid in s["set"]:
                    if rid not in p.ids:
                        errors.append(f"{where}: set → unknown id '{rid}'")
        if "view" in s:
            parts = re.split(r"[\s,]+", str(s["view"]).strip())
            try:
                ok = len(parts) == 4 and all(float(x) == float(x) for x in parts)
            except ValueError:
                ok = False
            if not ok:
                errors.append(f"{where}: view must be 'x y width height'")
        if len(str(s.get("text", "")).split()) > 90:
            warnings.append(f"{where}: narration is long ({len(str(s['text']).split())} words) — keep steps short")
    check_translations(html, p, steps, errors, warnings)
    return errors, warnings, info


def svg_labels(html: str) -> set[str]:
    m = re.search(r'<svg id="stage".*?</svg>', html, re.S)
    body = re.sub(r"<(title|desc)\b.*?</\1>", "", m.group(0) if m else "", flags=re.S)
    out: set[str] = set()
    for tm in re.finditer(r"<text\b[^>]*>(.*?)</text>", body, re.S):
        inner = tm.group(1)
        parts = re.findall(r"<tspan\b[^>]*>(.*?)</tspan>", inner, re.S) if "<tspan" in inner else [inner]
        for part in parts:
            out.add(re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", "", part))).strip())
    return out


def check_translations(html: str, p: "DemoParser", steps: list, errors: list[str], warnings: list[str]) -> None:
    raw = next((s["text"] for s in p.scripts if s["id"] == "demo-i18n"), None)
    if raw is None:
        warnings.append("no translations embedded (run: python3 tools/i18n/demo_text.py inject)")
        return
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        errors.append(f"demo-i18n JSON does not parse: {exc}")
        return
    if not isinstance(data, dict) or not data:
        errors.append("demo-i18n must be an object such as {\"id\": {page, steps, svg}}")
        return
    labels = svg_labels(html)
    for lang, tr in data.items():
        where = f"translation '{lang}'"
        if not re.fullmatch(r"[a-z]{2}", str(lang)) or not isinstance(tr, dict):
            errors.append(f"{where}: key must be a two-letter language code with an object value")
            continue
        page = tr.get("page") or {}
        for k in ("doc_title", "kicker", "title", "lede", "svgTitle", "svgDesc"):
            if not str(page.get(k, "")).strip():
                warnings.append(f"{where}: page.{k} is empty")
        ts = tr.get("steps") or []
        if len(ts) != len(steps):
            errors.append(f"{where}: {len(ts)} steps, but the demo has {len(steps)}")
        for n, (s, t) in enumerate(zip(steps, ts), 1):
            if not isinstance(t, dict) or not str(t.get("title", "")).strip() or not str(t.get("text", "")).strip():
                errors.append(f"{where}: step {n} needs a title and text")
                continue
            extra = set(t.get("set") or {}) - set((s.get("set") or {}) if isinstance(s, dict) else {})
            if extra:
                errors.append(f"{where}: step {n} sets unknown ids {sorted(extra)}")
            if len(str(t.get("text", "")).split()) > 100:
                warnings.append(f"{where}: step {n} narration is long ({len(str(t['text']).split())} words)")
        for key in (tr.get("svg") or {}):
            if key not in labels:
                warnings.append(f"{where}: SVG label not found in the drawing: {key!r}")


def main(argv: list[str]) -> int:
    targets: list[Path] = []
    if len(argv) > 1:
        for a in argv[1:]:
            pth = Path(a)
            targets.extend(sorted(x for x in pth.glob("*.html") if x.name != "index.html") if pth.is_dir() else [pth])
    else:
        targets = sorted(x for x in (REPO / "docs" / "demos").glob("*.html") if x.name != "index.html")  # index.html is the gallery
    if not targets:
        print("No demo files found.")
        return 1
    tmpl_hash = template_engine_hash()
    failed = 0
    for t in targets:
        errors, warnings, info = validate(t, tmpl_hash)
        status = "PASS" if not errors else "FAIL"
        print(f"{status}  {t.name}  ({info['steps']} steps, ~{info['minutes']} min autoplay)")
        for e in errors:
            print(f"   ✗ {e}")
        for w in warnings:
            print(f"   ! {w}")
        failed += bool(errors)
    print(f"\n{len(targets) - failed}/{len(targets)} demos passed.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
