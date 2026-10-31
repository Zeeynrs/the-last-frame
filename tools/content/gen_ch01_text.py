"""Generate localization/ch01_text.csv and data/documents/ch01/*.tres from narrative/ch01/CH01_TEXT.md.

The markdown is the single source of truth (TLF-024). Run from the repo root:
    python tools/content/gen_ch01_text.py
It fails (exit code 1) on: duplicate keys, empty text, non-ASCII text, length violations, or a
document row that references a key missing from the text table.
"""
import csv
import io
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "narrative", "ch01", "CH01_TEXT.md")
OUT_CSV = os.path.join(ROOT, "localization", "ch01_text.csv")
OUT_DOCS = os.path.join(ROOT, "data", "documents", "ch01")

LIMITS = {"OP_": 120, "EL_": 120, "JRN_": 120, "FRAG_": 160}
FEEDBACK_LIMIT = 80
PAGE_LINES, PAGE_WIDTH = 6, 48
KINDS = {"DOCUMENT": 0, "AUDIO_LOG": 1, "PLAQUE": 2, "TERMINAL": 3}


def table(text, heading):
    section = text.split(heading, 1)[1]
    rows = []
    for line in section.splitlines()[1:]:
        if line.startswith("## "):
            break
        if not line.startswith("|") or set(line.replace("|", "").strip()) <= {"-", " "}:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows[1:]  # drop header


def main():
    src = io.open(SRC, encoding="utf-8").read()
    errors = []
    texts = {}
    for cells in table(src, "## Text table"):
        key, text = cells[0], cells[5].replace("<br>", "\n")
        if key in texts:
            errors.append(f"duplicate key {key}")
        if not text.strip():
            errors.append(f"{key}: empty text")
        if any(ord(c) > 126 or (ord(c) < 32 and c != "\n") for c in text):
            errors.append(f"{key}: non-ASCII character")
        if "_FB_" in key and len(text) > FEEDBACK_LIMIT:
            errors.append(f"{key}: {len(text)} > {FEEDBACK_LIMIT} chars")
        for prefix, limit in LIMITS.items():
            if key.startswith(prefix) and len(text) > limit:
                errors.append(f"{key}: {len(text)} > {limit} chars")
        if re.search(r"_BODY_\d+$", key) and key.startswith("DOC_"):
            lines = text.split("\n")
            if len(lines) > PAGE_LINES or any(len(l) > PAGE_WIDTH for l in lines):
                errors.append(f"{key}: page exceeds {PAGE_LINES}x{PAGE_WIDTH}")
        texts[key] = text

    docs = table(src, "## Documents")
    for d in docs:
        for k in [d[2]] + d[3].split(",") + ([d[6]] if d[6] else []):
            if k.strip() and k.strip() not in texts:
                errors.append(f"document {d[0]} references missing key {k.strip()}")
        if d[1] not in KINDS:
            errors.append(f"document {d[0]}: unknown kind {d[1]}")

    if errors:
        print("\n".join(errors))
        sys.exit(1)

    os.makedirs(os.path.dirname(OUT_CSV), exist_ok=True)
    with io.open(OUT_CSV, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
        w.writerow(["keys", "en"])
        for key, text in texts.items():
            w.writerow([key, text])

    os.makedirs(OUT_DOCS, exist_ok=True)
    for d in docs:
        doc_id, kind, title, bodies, flag, fragment, journal, category = d
        name = doc_id.split(".")[-1]
        tres = (
            '[gd_resource type="Resource" script_class="DocumentDef" load_steps=2 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/narrative/document_def.gd" id="1_def"]\n\n'
            "[resource]\n"
            'script = ExtResource("1_def")\n'
            f'document_id = &"{doc_id}"\n'
            f"kind = {KINDS[kind]}\n"
            f'title_key = "{title}"\n'
            f'body_key = "{bodies.split(",")[0].strip()}"\n'
            f'flag_id = &"{flag}"\n'
            f'fragment_id = &"{fragment}"\n'
            f'journal_entry_key = "{journal}"\n'
            f'journal_category = "{category or "observation"}"\n'
        )
        io.open(os.path.join(OUT_DOCS, f"{name}.tres"), "w", encoding="utf-8", newline="\n").write(tres)
    print(f"ok: {len(texts)} keys -> {os.path.relpath(OUT_CSV, ROOT)}, {len(docs)} documents -> {os.path.relpath(OUT_DOCS, ROOT)}")


if __name__ == "__main__":
    main()
