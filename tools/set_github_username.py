#!/usr/bin/env python3
"""Replace the GitHub user name in every link in the repository.

Run it once after you fork or publish the course:

    python3 tools/set_github_username.py your-github-name                  # from the YOUR-GITHUB-USERNAME placeholder
    python3 tools/set_github_username.py your-github-name --from stefpin   # from the original owner's name

It updates links such as https://YOUR-GITHUB-USERNAME.github.io/azure-fundamentals-lunches/
and https://github.com/YOUR-GITHUB-USERNAME/azure-fundamentals-lunches in Markdown, HTML,
shell scripts and YAML files. Use --dry-run to see what would change.
If you renamed the repository, pass --repo new-repo-name as well.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PLACEHOLDER = "YOUR-GITHUB-USERNAME"
DEFAULT_REPO_NAME = "azure-fundamentals-lunches"
SUFFIXES = {".md", ".html", ".htm", ".sh", ".yml", ".yaml", ".json", ".bicep", ".txt", ".py"}
SKIP_DIRS = {".git", "node_modules", ".venv", "__pycache__"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("username", help="your GitHub user or organisation name")
    parser.add_argument("--repo", default=DEFAULT_REPO_NAME, help="repository name if you renamed it")
    parser.add_argument("--from", dest="old", default=PLACEHOLDER, help="the user name to replace (default: the placeholder)")
    parser.add_argument("--dry-run", action="store_true", help="show the files that would change")
    args = parser.parse_args()

    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})", args.username):
        print("That does not look like a valid GitHub user name.")
        return 1

    changed = 0
    for path in sorted(REPO.rglob("*")):
        if any(part in SKIP_DIRS for part in path.parts) or not path.is_file():
            continue
        if path.suffix.lower() not in SUFFIXES or path.resolve() == Path(__file__).resolve():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if args.old == PLACEHOLDER:
            if PLACEHOLDER not in text and (args.repo == DEFAULT_REPO_NAME or DEFAULT_REPO_NAME not in text):
                continue
            new = text.replace(PLACEHOLDER, args.username)
        else:
            # only touch real links: github.com/<old>/ and <old>.github.io
            new = text.replace(f"github.com/{args.old}/", f"github.com/{args.username}/")
            new = new.replace(f"//{args.old}.github.io", f"//{args.username}.github.io")
            new = new.replace(f"{args.old}.github.io/", f"{args.username}.github.io/")
        if args.repo != DEFAULT_REPO_NAME:
            new = new.replace(f"/{DEFAULT_REPO_NAME}", f"/{args.repo}")
        if new != text:
            changed += 1
            print(("would update " if args.dry_run else "updated ") + str(path.relative_to(REPO)))
            if not args.dry_run:
                path.write_text(new, encoding="utf-8")
    print(f"\n{changed} file(s) {'would be ' if args.dry_run else ''}updated.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
