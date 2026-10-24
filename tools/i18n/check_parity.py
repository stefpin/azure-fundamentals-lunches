#!/usr/bin/env python3
"""Check that Indonesian twins (*.id.md) match their English originals.

    python3 tools/i18n/check_parity.py                       # every twin in the repository
    python3 tools/i18n/check_parity.py lunches/06-virtual-machines-basic labs/06-virtual-machines-basic
    python3 tools/i18n/check_parity.py --strict              # missing link targets become errors

Compares: H2 sections (fixed Indonesian headings, same order), H3 count, fenced code blocks (byte-identical except
Mermaid, whose node IDs must match), callouts, tables, <details> blocks, links (Indonesian twins where they exist,
identical external links), in-file and cross-file anchors, required header labels, the language line, the
"Anda" voice, leftover English paragraphs and reading length. See TRANSLATION-GUIDE.md. Standard library only.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

REPO = Path(__file__).resolve().parents[2]
PAGES = "https://stefpin.github.io/azure-fundamentals-lunches"

LUNCH_H2 = {
    "🍱 Today's menu": "🍱 Menu hari ini",
    "🏪 Meanwhile at Nusantara Retail": "🏪 Sementara itu di Nusantara Retail",
    "📖 Reading (≈25 minutes)": "📖 Bacaan (≈25 menit)",
    "🎬 Demo (≈15 minutes)": "🎬 Demo (≈15 menit)",
    "✅ Knowledge check (≈5 minutes)": "✅ Uji pemahaman (≈5 menit)",
    "🧠 Key takeaways": "🧠 Poin penting",
    "🗒️ Field notes from Stefanus": "🗒️ Catatan lapangan dari Stefanus",
    "📚 Go further": "📚 Pelajari lebih lanjut",
}
LAB_H2 = {
    "🎯 What you'll build": "🎯 Yang akan Anda bangun",
    "✅ Before you start": "✅ Sebelum mulai",
    "🧭 Choose your mode": "🧭 Pilih mode Anda",
    "🔧 Break it and fix it": "🔧 Rusak lalu perbaiki",
    "🧪 Verify your work": "🧪 Verifikasi hasil kerja Anda",
    "🧹 Clean up (do not skip!)": "🧹 Bersihkan (jangan dilewati!)",
    "🩺 Troubleshooting": "🩺 Pemecahan masalah",
    "🚀 Stretch goals": "🚀 Tantangan tambahan",
    "🏁 Challenge brief": "🏁 Ringkasan tantangan",
    "🎯 The brief": "🎯 Ringkasan proyek",
    "🧭 How this challenge works": "🧭 Cara kerja tantangan ini",
    "📋 Requirements": "📋 Persyaratan",
    "🚧 Constraints": "🚧 Batasan",
    "🗺 Suggested architecture": "🗺 Arsitektur yang disarankan",
    "✅ Acceptance checklist": "✅ Daftar periksa penerimaan",
    "💡 Hints": "💡 Petunjuk",
    "🧹 Clean up": "🧹 Bersihkan",
    "📚 Where each piece is taught": "📚 Di mana setiap bagian diajarkan",
}
LUNCH_LABELS = ["**Jalur:**", "**Waktu:**", "**Makan siang prasyarat:**", "**Area keterampilan AZ-900:**", "**Lab:**",
                "**Penulis:**"]
LAB_LABELS = ["**Pasangan dari:**", "**Waktu:**", "**Biaya:**", "**Bisa dikerjakan terpisah:**", "**Penulis:**"]
EN_STOP = {"the", "and", "of", "to", "is", "you", "your", "with", "that", "for", "this", "are", "it", "on", "be",
           "can", "will", "from", "when", "what", "which", "into", "they", "their", "have", "has", "not", "but"}
BAD_VOICE = re.compile(r"\b(kamu|kau|lo|gue|elo|milikmu|tugasmu|akunmu|datamu|servermu|aplikasimu|timmu|"
                       r"tagihanmu|perusahaanmu|komputermu|labmu)\b", re.I)
LINK = re.compile(r"(?<!!)\[((?:[^\]\[]|\[[^\]]*\])*)\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
HTML_HREF = re.compile(r"""href\s*=\s*["']([^"']+)["']""")


def gh_slug(text: str) -> str:
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    s = re.sub(r"[`*_]", "", s).strip().lower()
    s = re.sub(r"[^\w\- ]", "", s)
    return s.replace(" ", "-")


class Doc:
    def __init__(self, path: Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8")
        self.lines = self.text.splitlines()
        self.h1, self.h2, self.h3, self.code, self.prose_lines = None, [], [], [], []
        fence, buf, lang = None, [], ""
        for line in self.lines:
            st = line.lstrip()
            m = re.match(r"(`{3,}|~{3,})(.*)$", st)
            if fence is None and m:
                fence, lang, buf = m.group(1), m.group(2).strip().split(" ")[0].lower(), []
                continue
            if fence is not None:
                if st.startswith(fence) and st.strip() == fence[0] * len(st.strip()):
                    self.code.append((lang, "\n".join(buf)))
                    fence = None
                else:
                    buf.append(line)
                continue
            if line.startswith("# ") and self.h1 is None:
                self.h1 = line[2:].strip()
            elif line.startswith("## "):
                self.h2.append(line[3:].strip())
            elif line.startswith("### "):
                self.h3.append(line[4:].strip())
            self.prose_lines.append(line)
        self.prose = "\n".join(self.prose_lines)
        used: dict[str, int] = {}
        self.anchors = set()
        for line in self.prose_lines:
            m = re.match(r"^(#{1,6})\s+(.*)$", line)
            if m:
                base = gh_slug(m.group(2))
                slug = base if base not in used else f"{base}-{used[base]}"
                used[base] = used.get(base, 0) + 1
                self.anchors.add(slug)
        self.links = [u for _t, u in LINK.findall(self.prose)] + HTML_HREF.findall(self.prose)
        self.callouts = re.findall(r"^>\s*\[!(\w+)\]", self.prose, re.M)
        self.tables = len(re.findall(r"^\|\s*:?-{3,}", self.prose, re.M))
        self.details = len(re.findall(r"<details", self.prose))

    def section(self, emoji: str) -> str:
        out, take = [], False
        for line in self.prose_lines:
            if line.startswith("## "):
                take = line[3:].strip().startswith(emoji)
                continue
            if take:
                out.append(line)
        return "\n".join(out)


def words(s: str) -> int:
    s = re.sub(r"`[^`]*`", " ", s)
    s = re.sub(r"\]\([^)]*\)", "]", s)
    s = re.sub(r"<[^>]+>", " ", s)
    return len(re.findall(r"[^\W\d_][\w'’\-]*", s))


def mermaid_skeleton(src: str) -> tuple:
    ids = set(re.findall(r"\b([A-Za-z_][\w]*)\s*(?=\[|\(|\{|>\s*\")", src))
    ids |= set(re.findall(r"subgraph\s+([A-Za-z_]\w*)", src))
    arrows = len(re.findall(r"-->|-\.->|==>|---|-\.-|--o|--x", src))
    return (frozenset(ids), arrows)


def twin_of(path: Path) -> Path:
    return path.with_name(path.name[:-3] + ".id.md")


def expected_link(en_url: str, en_file: Path, id_file: Path) -> tuple[str, bool]:
    """Return (expected Indonesian URL or pattern, is_relative_file)."""
    if en_url.startswith(PAGES + "/demos/"):
        base, _, frag = en_url.partition("#")
        return base + ("&" if "?" in base else "?") + "lang=id" + (f"#{frag}" if frag else ""), False
    if re.match(r"^[a-z][a-z0-9+.-]*:", en_url) or en_url.startswith("#"):
        return en_url, False
    path, _, frag = en_url.partition("#")
    target = (en_file.parent / unquote(path)).resolve() if path else en_file
    if target.is_dir() or path.endswith("/"):
        return path, True
    if target.suffix == ".md" and not target.name.endswith(".id.md") and target.name not in (
            "CONTRIBUTING.md", "LICENSE-CONTENT.md", "AUTHORING-GUIDE.md", "PUBLISHING.md", "TEST-PASS-NOTES.md",
            "COURSE-DESIGN.md", "TRANSLATION-GUIDE.md"):
        target = twin_of(target)
        exp = Path(os_relpath(target, id_file.parent))
        return exp.as_posix(), True
    return path, True


def os_relpath(target: Path, start: Path) -> str:
    import os
    return os.path.relpath(target, start)


def check_pair(en: Path, strict: bool) -> tuple[list[str], list[str]]:
    errs, warns = [], []
    idp = twin_of(en)
    rel = en.relative_to(REPO).as_posix()
    if not idp.exists():
        return [f"{rel}: Indonesian twin {idp.name} is missing"], []
    E, I = Doc(en), Doc(idp)
    is_lunch = en.parent.parent.name == "lunches" and en.name == "README.md"
    is_lab = en.parent.parent.name == "labs" and en.name == "README.md"
    # language line
    if not re.search(r"🇬🇧\s*\[Read in English\]\(" + re.escape(en.name) + r"\)", I.text):
        errs.append(f"language line '🇬🇧 [Read in English]({en.name})' missing after the H1")
    # H1
    if is_lunch and not (I.h1 or "").startswith("Makan Siang "):
        errs.append(f"H1 must start with 'Makan Siang NN ·' (found: {I.h1!r})")
    if is_lab and E.h1 and E.h1.startswith("Lab ") and not (I.h1 or "").startswith(E.h1.split("·")[0].strip()):
        errs.append(f"H1 must start with '{E.h1.split('·')[0].strip()} ·' (found: {I.h1!r})")
    # H2 sections
    if len(E.h2) != len(I.h2):
        errs.append(f"H2 count differs: English {len(E.h2)}, Indonesian {len(I.h2)}")
    for k, (eh, ih) in enumerate(zip(E.h2, I.h2)):
        fixed = (LUNCH_H2 if is_lunch else LAB_H2 if is_lab else {}).get(eh)
        if fixed and ih != fixed:
            errs.append(f"H2 #{k + 1}: expected '{fixed}' (for '{eh}'), found '{ih}'")
        elif is_lunch and eh.startswith("🔬 Your lab:") and not ih.startswith("🔬 Lab Anda:"):
            errs.append(f"H2 #{k + 1}: expected '🔬 Lab Anda: …', found '{ih}'")
        elif is_lab and re.match(r"Task \d+ ·", eh):
            n = re.match(r"Task (\d+)", eh).group(1)
            if not re.match(rf"Tugas {n} · .+", ih):
                errs.append(f"H2 #{k + 1}: expected 'Tugas {n} · …', found '{ih}'")
        else:
            lead = re.match(r"^[^\w\s(“\"'`*\[]+", eh)
            if lead and not ih.startswith(lead.group(0).strip()):
                errs.append(f"H2 #{k + 1}: must start with the same emoji '{lead.group(0).strip()}' ('{eh}' vs '{ih}')")
    if len(E.h3) != len(I.h3):
        errs.append(f"H3 count differs: English {len(E.h3)}, Indonesian {len(I.h3)}")
    # code
    ec = [c for c in E.code if c[0] != "mermaid"]
    ic = [c for c in I.code if c[0] != "mermaid"]
    if len(ec) != len(ic):
        errs.append(f"code block count differs: English {len(ec)}, Indonesian {len(ic)}")
    for k, (a, b) in enumerate(zip(ec, ic)):
        lines_a = [l for l in a[1].splitlines() if l.strip()]
        if not a[0] and lines_a and all(re.match(r"^\d{1,2}:\d{2}\b", l) for l in lines_a):
            stamps_b = [l[:5] for l in b[1].splitlines() if l.strip()]
            if [l[:5] for l in lines_a] != stamps_b:
                errs.append(f"code block #{k + 1}: video chapter list must keep the same timestamps")
            continue
        if a != b:
            first = next((i for i, (x, y) in enumerate(zip(a[1].splitlines(), b[1].splitlines())) if x != y), None)
            errs.append(f"code block #{k + 1} ({a[0] or 'text'}) is not identical to English"
                        + (f" (first difference at line {first + 1})" if first is not None else " (length differs)"))
    em = [c[1] for c in E.code if c[0] == "mermaid"]
    im = [c[1] for c in I.code if c[0] == "mermaid"]
    if len(em) != len(im):
        errs.append(f"Mermaid diagram count differs: English {len(em)}, Indonesian {len(im)}")
    for k, (a, b) in enumerate(zip(em, im)):
        sa, sb = mermaid_skeleton(a), mermaid_skeleton(b)
        if sa[0] != sb[0]:
            errs.append(f"Mermaid #{k + 1}: node IDs differ (missing {sorted(sa[0] - sb[0])[:5]}, extra {sorted(sb[0] - sa[0])[:5]})")
        if sa[1] != sb[1]:
            errs.append(f"Mermaid #{k + 1}: arrow count differs ({sa[1]} vs {sb[1]})")
    # callouts, tables, details
    if E.callouts != I.callouts:
        errs.append(f"callouts differ: English {E.callouts}, Indonesian {I.callouts}")
    if E.tables != I.tables:
        errs.append(f"table count differs: English {E.tables}, Indonesian {I.tables}")
    if E.details != I.details:
        errs.append(f"<details> count differs: English {E.details}, Indonesian {I.details}")
    for marker in re.findall(r"<!-- [A-Z-]+:(?:START|END) -->", E.text):
        if marker not in I.text:
            errs.append(f"generator marker {marker} missing (keep it exactly)")
    if is_lunch:
        fn_en = [k for k, h in enumerate(E.h2) if h.startswith("🗒️")]
        if not fn_en:
            errs.append("English field note '## 🗒️ Field notes from Stefanus' is missing (add it to README.md)")
        elif fn_en[0] == 0 or not E.h2[fn_en[0] - 1].startswith("🧠") or not E.h2[fn_en[0] + 1].startswith("🔬"):
            errs.append("field notes must sit between '🧠 Key takeaways' and '🔬 Your lab'")
        for doc, name in ((E, "English"), (I, "Indonesian")):
            note = doc.section("🗒️").strip()
            if fn_en and not re.match(r"^> \*\*[^*]+\*\*", note):
                errs.append(f"{name} field note must be a blockquote that starts with a bold headline")
            elif fn_en:
                n = words(note)
                if not 80 <= n <= 175:
                    warns.append(f"{name} field note has {n} words (aim for 90–140)")
        if "| ⏱ Menit | Segmen |" not in I.text:
            errs.append("timing table header must be '| ⏱ Menit | Segmen |'")
        if I.text.count("<summary>Lihat jawaban</summary>") != 5:
            errs.append("quiz must have five '<summary>Lihat jawaban</summary>' blocks")
        for lab in LUNCH_LABELS:
            if lab not in I.text:
                errs.append(f"header label {lab} missing")
        if "Terakhir divalidasi:" not in I.text:
            errs.append("footer '<sub>Terakhir divalidasi: …</sub>' missing")
        if "Pause and think" in E.text and "**Renungkan sejenak:**" not in I.text:
            errs.append("'**Pause and think:**' must become '**Renungkan sejenak:**'")
    if is_lab:
        for lab in LAB_LABELS:
            if lab not in I.text and lab.replace("**", "") not in E.text.replace("**", ""):
                pass
        need = [l for l in LAB_LABELS if l != "**Pasangan dari:**" or "**Pairs with:**" in E.text]
        for lab in need:
            if lab not in I.text:
                errs.append(f"header label {lab} missing")
        if "Terakhir divalidasi:" not in I.text:
            errs.append("footer '<sub>Terakhir divalidasi: …</sub>' missing")
        if "Checkpoint:**" in E.text and "**Pemeriksaan:**" not in I.text:
            errs.append("'✅ **Checkpoint:**' must become '✅ **Pemeriksaan:**'")
    # links
    def ext(u: str) -> str:
        u = re.sub(r"^https://[a-z]{2}\.linkedin\.com", "https://www.linkedin.com", u).rstrip("/")
        # the Indonesian twin of a site page lives under /id/ instead of /en/
        return u.replace(PAGES + "/id/", PAGES + "/en/")
    e_ext = sorted(ext(u) for u in E.links if re.match(r"^https?:", u) and not u.startswith(PAGES + "/demos/"))
    i_ext = sorted(ext(u) for u in I.links if re.match(r"^https?:", u) and not u.startswith(PAGES + "/demos/"))
    if e_ext != i_ext:
        missing = sorted(set(e_ext) - set(i_ext))
        extra = sorted(set(i_ext) - set(e_ext))
        if missing or extra:
            errs.append(f"external links differ (missing {missing[:3]}, extra {extra[:3]})")
        else:
            warns.append("external links repeat a different number of times than in English")
    e_demo = [u for u in E.links if u.startswith(PAGES + "/demos/")]
    i_demo = [u for u in I.links if u.startswith(PAGES + "/demos/")]
    for u in e_demo:
        exp, _ = expected_link(u, en, idp)
        if exp not in i_demo:
            errs.append(f"demo link should be {exp}")
    e_rel = [u for u in E.links if not re.match(r"^[a-z][a-z0-9+.-]*:", u) and not u.startswith("#")
             and u.partition("#")[0] != idp.name]
    i_rel = [u for u in I.links if not re.match(r"^[a-z][a-z0-9+.-]*:", u) and not u.startswith("#")]
    exp_rel = sorted(expected_link(u, en, idp)[0] for u in e_rel)
    got_rel = sorted(u.partition("#")[0] for u in i_rel if not u.startswith("README.md") or en.name != "README.md")
    exp_rel_paths = sorted(e.partition("#")[0] for e in exp_rel)
    lang_line = en.name
    got_rel_wo_lang = list(got_rel)
    if lang_line in got_rel_wo_lang:
        got_rel_wo_lang.remove(lang_line)
    if sorted(got_rel_wo_lang) != exp_rel_paths:
        miss = sorted(set(exp_rel_paths) - set(got_rel_wo_lang))
        extra = sorted(set(got_rel_wo_lang) - set(exp_rel_paths))
        if miss or extra:
            errs.append(f"relative links differ from the expected Indonesian targets (missing {miss[:4]}, extra {extra[:4]})")
    for u in I.links:
        if u.startswith("#"):
            if unquote(u[1:]) not in I.anchors:
                errs.append(f"in-page anchor {u} does not match any Indonesian heading")
            continue
        if re.match(r"^[a-z][a-z0-9+.-]*:", u):
            continue
        path, _, frag = u.partition("#")
        tgt = (idp.parent / unquote(path)).resolve()
        if not tgt.exists():
            (errs if strict else warns).append(f"link target not found yet: {u}")
            continue
        if frag and tgt.suffix == ".md":
            if unquote(frag) not in Doc(tgt).anchors:
                (errs if strict or tgt.name.endswith(".id.md") else warns).append(f"anchor #{frag} not found in {path}")
    # voice and leftovers
    for m in BAD_VOICE.finditer(I.prose):
        errs.append(f"informal voice: '{m.group(0)}' — use 'Anda'")
        break
    for para in re.split(r"\n\s*\n", re.sub(r"`[^`]*`", " ", I.prose)):
        ws = re.findall(r"[A-Za-z']+", re.sub(r"\]\([^)]*\)|<[^>]+>|https?://\S+", " ", para))
        if len(ws) >= 12:
            ratio = sum(1 for w in ws if w.lower() in EN_STOP) / len(ws)
            if ratio > 0.12:
                warns.append(f"paragraph looks untranslated: “{' '.join(ws[:12])}…”")
    if is_lunch:
        er, ir = words(E.section("📖")), words(I.section("📖"))
        if er:
            ratio = ir / er
            if not 0.9 <= ratio <= 1.3:
                (warns if 0.85 <= ratio <= 1.4 else errs).append(
                    f"Reading section length is {ratio:.0%} of English ({ir} vs {er} words); aim for 90–130%")
    return errs, warns


def candidates(args: list[str]) -> list[Path]:
    roots = [REPO / a for a in args] if args else [REPO / "lunches", REPO / "labs", REPO]
    out = []
    for r in roots:
        if r.is_file():
            out.append(r)
            continue
        globber = r.glob("*.md") if r == REPO else r.rglob("*.md")
        for p in sorted(globber):
            if p.name.endswith(".id.md") or "templates" in p.parts:
                continue
            if r == REPO and p.name not in ("README.md", "SYLLABUS.md"):
                continue
            if "common" in p.parts:
                continue
            out.append(p)
    return out


def main(argv: list[str]) -> int:
    strict = "--strict" in argv
    args = [a for a in argv[1:] if not a.startswith("--")]
    files = candidates(args)
    total_e = total_w = 0
    for en in files:
        errs, warns = check_pair(en, strict)
        if errs or warns:
            print(f"\n{en.relative_to(REPO).as_posix()}  →  {twin_of(en).name}")
            for e in errs:
                print(f"   ✗ {e}")
            for w in warns[:12]:
                print(f"   ! {w}")
            if len(warns) > 12:
                print(f"   ! … {len(warns) - 12} more warnings")
        total_e += len(errs)
        total_w += len(warns)
    print(f"\nChecked {len(files)} English file(s): {total_e} error(s), {total_w} warning(s).")
    return 1 if total_e else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
