#!/usr/bin/env python3
"""Check that relative links in Markdown and HTML files point to files that exist.

  python3 tools/check_links.py            # whole repository
  python3 tools/check_links.py lunches    # one folder

Checks Markdown links/images `[text](path)` and HTML `href="..."`/`src="..."` values that are
relative paths. External links (http/https/mailto), in-page anchors (#...) and the
YOUR-GITHUB-USERNAME placeholder links are skipped, and so are site-absolute paths
("/images/") used by the sample web apps. The templates/ folder is skipped because its
links are placeholders. Links inside code blocks are ignored.
Standard library only. Exit code 1 if any link is broken.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

REPO = Path(__file__).resolve().parents[1]
MD_LINK = re.compile(r"!?\[(?:[^\]\[]|\[[^\]]*\])*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
HTML_LINK = re.compile(r"""(?:href|src)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)
FENCE = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE = re.compile(r"`[^`\n]*`")
SKIP_DIRS = {".git", "node_modules", ".venv", "__pycache__", "templates"}


def candidates(root: Path):
    for path in sorted(root.rglob("*")):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.is_file() and path.suffix.lower() in (".md", ".html", ".htm"):
            yield path


def is_relative(target: str) -> bool:
    t = target.strip()
    if not t or t.startswith(("#", "/", "http://", "https://", "mailto:", "data:", "javascript:", "tel:")):
        return False
    if ("YOUR-" + "GITHUB-USERNAME") in t or t.startswith(("{", "$")):
        return False
    return True


def check_file(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    problems: list[str] = []
    if path.suffix.lower() == ".md":
        body = FENCE.sub("", text)
        body = INLINE_CODE.sub("", body)
        targets = MD_LINK.findall(body) + HTML_LINK.findall(body)
    else:
        body = re.sub(r"<script\b[^>]*>.*?</script>", "", text, flags=re.DOTALL | re.IGNORECASE)
        targets = HTML_LINK.findall(body)
    for target in targets:
        if not is_relative(target):
            continue
        clean = unquote(target.split("#", 1)[0].split("?", 1)[0])
        if not clean:
            continue
        resolved = (path.parent / clean).resolve()
        if not resolved.exists():
            problems.append(f"{path.relative_to(REPO)}: broken link → {target}")
    return problems


def main(argv: list[str]) -> int:
    roots = [REPO / a for a in argv[1:]] or [REPO]
    problems: list[str] = []
    count = 0
    for root in roots:
        files = [root] if root.is_file() else list(candidates(root))
        for f in files:
            count += 1
            problems.extend(check_file(f))
    for p in problems:
        print(f"✗ {p}")
    print(f"\nChecked {count} files: {len(problems)} broken link(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
