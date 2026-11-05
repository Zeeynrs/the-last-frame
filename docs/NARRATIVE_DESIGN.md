# Narrative Design (canon, ADR-022)

How the story is delivered and reviewed. Part of the story canon; entry point `STORY_BIBLE.md`.

## 1. Show, don't explain
Deliver the story through:
- the environment
- character dialogue and audio logs
- memory fragments and Trace memories
- visual symbols
- the puzzle mechanics themselves
- **short** cutscenes
- rooms that change

No long dialogue explaining the background. Optional lore deepens the mystery but is never needed to understand a puzzle.

## 2. Progression
- **Pacing:** each chapter answers one question and opens a bigger one (`CHAPTER_BREAKDOWN.md`).
- **Revelations:**
  - Exactly **one major revelation per chapter**.
  - Smaller seeds are **questions, not answers**, e.g. "Did I do this?", a corrupted user field.
  - Don't give answers too early. Ch1 implicates Elias only as a question; Ch4 gives the answer about his responsibility; Ch5 reveals what Mira is.
- **Dual Elias:**
  - Ch1 teaches Echo (Elias Past, recorded actions).
  - Ch2 shows traces of earlier temporal interactions by Elias.
  - Ch3 makes it controllable.
  - Ch4: recordings that don't match his memory.
  - Ch5 questions identity and reconstruction.
  - Ch6 makes it part of the final puzzle.
- **The unbidden Elias Past:** in rare, foreshadowed, authored moments Elias Past does something the player didn't record. It is scripted and deterministic, never random or bug-like, and it has context and a consequence.

## 3. Dialogue rules
- **Characters:** stay consistent with `CHARACTER_BIBLE.md`; no line contradicts a character's motivation without a story reason.
- **Length and characters:**
  - ASCII only (the pixel font).
  - Elias/Operator lines ≤ 120 characters.
  - Puzzle feedback ≤ 80.
  - Documents ≤ 6 lines × 48 characters per page.
  - (Enforced by `tools/content/gen_ch01_text.py`.)
- **Elias:** short, thinking out loud, questions over statements; his certainty is not the truth.
- **Operator:** see `OPERATOR_MYSTERY_GUIDELINES.md`. Speaker label "VOICE".
- **Mira:** warm and firm; she asks Elias to live, not to cling.
- **Text sources:** text is data. Keys and text live in `narrative/chNN/CHNN_TEXT.md`, and the generators produce CSV/`.tres`. Never hand-edit generated files.

## 4. Environmental storytelling
- **Purpose:** every detail serves the story or a puzzle (no filler collectibles) and ties to a later revelation.
- **Ch1 motifs:**
  - 23:59 clocks
  - the 23:54 evacuation
  - "chronometric backflow"
  - the threshold index
  - suspended rain
  - frozen commuters whose time-stamped memories add up to "the five minutes"
  - the research link ("DESTINATION: NOWHERE - 23:59", "A1 → Research", "R&D Access"; TLF-063)
- **Rooms tell what happened between 23:54 and 23:59.**

## 5. Mystery and clue design (fair mystery)
- Every twist is supported by clues the player has actually seen, each with context.
- A player who finishes the game and replays Ch1 finds details they missed: the sighting, the shared phrase, the terminal that knows his hand, the column of identical matches.
- Journal categories keep things honest: **observation** (seen), **fact** (verified), **theory** (the player's or Elias's guess). Never mark a guess as a fact.

## 6. Review process
- **Author:** narrative canon and dialogue, the Lead (ADR-022 D5).
- **Gate for every narrative delivery:**
  1. canon check against the six documents
  2. Operator checklist (`OPERATOR_MYSTERY_GUIDELINES.md` §6)
  3. generator run and `validate.ps1` green
- Visual story elements (sightings, character art) also go through Sol's visual review.
