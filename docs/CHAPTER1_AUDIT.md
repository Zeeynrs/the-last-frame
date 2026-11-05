# Chapter 1 Audit (Safe Enhancement Directive, deliverables 1, 2 and 5)

**Date:** 2026-11-05 · **Lead:** Agent 1 (Opus 5.5) · **Main:** `9df8c04` · **Inputs:** `docs/THE_LAST_FRAME_CHAPTER_1_SAFE_ENHANCEMENT_DIRECTIVE.md` (owner, v1.0), `docs/STORY_BIBLE_AND_NARRATIVE_MASTER_PROMPT.md` (v2.0), the owner's reference images in `ref/` (6 PNG, untracked), and the repository itself.
**Related:** story conflicts in detail: `docs/reviews/2026-11-05_STORY_BIBLE_V2_AUDIT.md` (C1-C17, open decisions D1-D6). Plan: `docs/CHAPTER1_SAFE_PLAN.md`. Later features: `docs/FUTURE_FEATURE_BACKLOG.md`.

Nothing was implemented for this audit.

## 1. Project state (evidence)

| Area | State | Evidence |
|---|---|---|
| Boot → title → Chapter 1 → chapter complete → title; Continue | **Works** | `scripts/core/`, `scenes/boot/`, `scenes/ui/title_screen.tscn`, `tests/core/`, `tests/ui/test_title_screen.gd` |
| Chapter scene | **Works**: 10 rooms, start to `chapter_complete` | `scenes/chapters/ch01/Chapter01.tscn`, `scenes/chapters/ch01/rooms/` (arrival_platform, concourse_west, maintenance_bay, security_crossing, waiting_lounge, signal_control, upper_vestibule, vestibule_niche, station_atrium, street_exit) |
| Movement / navigation | **Works**: 8-directional isometric, 120 px/s, collision. **No Camera2D**: each room is a fixed 640×360 screen (ADR-003) | `scripts/player/`, `tests/player/` |
| Pocket watch | **Works**: Trace, Rewind, Freeze, Echo through `InteractionService`; Fast-Forward only in the core, not in Ch1 content | `scripts/player/pocket_watch.gd`, `scripts/temporal/`, `scripts/echo/` |
| Progressive unlocks + `TraceMemory` | **Merged, not wired**: the game still starts with all four abilities and no room has a memory | TLF-050 `cf12b23`; wiring is TLF-055 |
| Ability wheel | **Art merged, UI not built** | TLF-053 `f432bca`; TLF-052 READY |
| Puzzles | **Works**: PZ-001…005 incl. the Echo puzzles; real-input playthrough; RISK-018 negative test | `scripts/puzzle/objects/`, `tests/puzzle/test_ch01_puzzles.gd`, `tests/chapters/ch01/` |
| **The Forgotten Sequence** (directive §2.8) | **Exists as CH1-PZ-004** "The Synchronized Substation": an Echo pulls breaker A while Elias pulls B, after Rewind+Freeze on the capacitor. 3 hints, reset anchor, SOLVED is permanent. Real-input solution and negative test without Echo are green | `design/ch01/puzzles/CH1-PZ-004.md`, `tests/chapters/ch01/` |
| Step 1 expansion (ISSUE-038, approved by the owner on 2026-11-01) | **Specified, being built**: SO-01, SO-02, PZ-006, revisions of PZ-001…005, 13 frozen commuters | TLF-054 (Opus), TLF-055 (Flash), TLF-056 (Opus), TLF-057 (Argon; Sol's direction on branch `tlf-057-art-direction` `cdb80d6`, not merged) |
| Save / load | **Works**: save v3, migrations v1→v2→v3, checkpoints, autosave, Continue, headless guard | `scripts/save/`, `tests/save/` |
| Journal | **Works**: observation / fact / theory, documents, memory fragments | `scenes/ui/JournalScreen.tscn`, `scripts/narrative/`, `tests/ui/` |
| Hints | **Works**: 3 tiers per puzzle, on request (`hint` action, H / joypad 10) | `scripts/puzzle/hint_service.gd`, `data/puzzles/ch01/` |
| Dialogue / documents | **Works**: blocking and non-blocking DialogueBox, DocumentViewer | `scripts/ui/`, `narrative/ch01/CH01_TEXT.md` → `localization/ch01_text.csv` |
| Playtest telemetry | **Works** | TLF-048 |
| Audio | **Missing**: no audio files, no `AudioStreamPlayer` in scripts/scenes; only bus volumes in Settings | `find assets -name '*.ogg'` → none |
| Builds | **Missing**: no `export_presets.cfg`, so no Windows/Linux build has been made or tested | repository root |
| Validation | **Green**: 121 scripts, 314/314 tests, leak check clean (Lead fresh archive of `f432bca`, 2026-11-01) | `tools/validate.ps1` |

**Known bugs / blockers:**
- RISK-020: PZ-002 is solvable without Freeze. Confirmed by TLF-049; the fix is specified in Step 1.
- ISSUE-038: the chapter is too short (< 5 min). Step 1 targets ≥ 15 min.
- ISSUE-039: Trace has no content yet.
- ISSUE-041: the HUD hint shows through the chapter-complete overlay.
- ISSUE-011: physical controller spot-check (human).
- ISSUE-042: process.

## 2. Story beats of directive §2 / Story Bible Ch1

| # | Beat | Status | Evidence / gap |
|---|---|---|---|
| 1 | Explore an abandoned underground station | EXISTS | 10 rooms |
| 2 | Movement and interaction introduced | EXISTS | Beat 01, interaction prompt |
| 3 | First temporal recording | PARTIAL | Beat 06 `trace_bench`; Step 1 adds Trace memories from the start |
| 4 | Rewind, Freeze, Temporal Echo introduced | EXISTS | PZ-001…004 |
| 5 | Message from Mira | EXISTS | `ch01.waiting_lounge.audio_mira_01` |
| 6 | Evidence that someone used temporal systems before him | EXISTS, maybe too strong | Turnstile trace, Level-0 transit pass; Beat 09 says "I sealed this station" as a fact (audit C10, decision D1) |
| 7 | Mysterious figure briefly seen at the end of a corridor | **MISSING** | The Operator is voice-only today (audit C8, decision D3) |
| 8 | Signature puzzle *The Forgotten Sequence* | EXISTS (as PZ-004) | Player-facing title differs (audit C15) |
| 9 | Exit reveals the frozen city; voice: "You are late. Again." | **PARTIAL** | Exit + "the rain isn't falling" line exist, but there is no cinematic, and the voice says other lines (`OP_B10_01/02`, `chapter01.gd:254-275`; audit C9, C11) |
| — | No Operator identity confirmation | EXISTS (in-game) | No Ch1 line confirms it; the docs (GDD, MASTER_PROMPT) still state it as canon (audit C1) |

## 3. Gap matrix (features)

| ID | Feature | Status | Evidence |
|---|---|---|---|
| F01 | Memory Reconstruction | MISSING | The journal's fact/theory split is a foundation only |
| F02 | Temporal Echo 2.0 | MISSING | Echo 1.0 EXISTS: `scripts/echo/` (1 echo, 1200 ticks, deterministic, persistent occupancy) |
| F03 | Reality Shift / impossible architecture | PARTIAL | Doorway reassignment EXISTS (`scripts/spatial/`, PZ-005); rotation, gravity and folding MISSING |
| F04 | Operator's invisible influence | PARTIAL | Voice through devices (B03/B05/B07/B10), one shared phrase; no visual motif or sighting |
| F05 | Environmental storytelling layers | PARTIAL | 23:59 clocks, evacuation notice, tech log, threshold plaque, transit pass, recorder; Step 1 adds 7 readables + 13 commuters (specified) |
| F06 | Branching Truth | MISSING | — |
| F07 | Persistent world changes | PARTIAL (foundation) | `NarrativeState` flags + save v3; only one chapter exists |
| F08 | Elias's journal | **EXISTS** | Journal screen with categories and fragments. Directive P1-1 is already done |
| F09 | Pocket-watch evolution | EXISTS (Ch1) | `AbilityUnlocks` (TLF-050); wheel TLF-052 |
| F10 | Dynamic sound and silence | MISSING | No audio at all |
| F11 | Adaptive hints | PARTIAL | 3-tier hints on request EXIST; adaptive offering MISSING |
| F12 | Residual Memories / NG+ | MISSING | — |
| X01 | Unreliable Save (fiction only) | MISSING | Must stay that way until approved; real saves are never altered |

**NOT INSPECTED:**
- performance on representative low-end hardware
- Linux (no build exists)
- the physical controller (human, ISSUE-011)

## 4. Conflict report

Story conflicts C1-C17 are in `docs/reviews/2026-11-05_STORY_BIBLE_V2_AUDIT.md`. The directive's §2 beats match Story Bible v2, so they add no new story conflicts; decisions D1-D6 there are still open. New conflicts from the directive and the reference images:

| # | Conflict | Detail | Proposal |
|---|---|---|---|
| K1 | Directive P1-1 (journal) and P1-3 (tiered hints) | Both already exist (F08, F11) | No new task; only verify the PZ-004 hints after its title change |
| K2 | **Map reference vs. built layout** (`ref/chapter1_map.png`) | The reference shows 10 different locations: Station Office, Power Room, Baggage Storage (secret), Central Clock Chamber, and an Exit Platform with a sealed gate. Its puzzle flow is power → train signal → **"sync the station clock and unfreeze time"** → sealed gate. The built chapter has 10 rooms whose collision is frozen (ADR-019) and exits by the street stairs into the frozen city | (a) **"Unfreeze time"** contradicts canon: the city stays at 23:59 until the endings, and Ch1 must end on the frozen city. Not adoptable as written. (b) Rebuilding the room graph breaks the directive's no-churn rule. **Proposal:** use the map as a structure and mood reference. Map names onto existing rooms (Awakening Platform = `arrival_platform`, Main Concourse / Ticket Hall = `concourse_west`, Waiting Room = `waiting_lounge`, Maintenance Corridor = `maintenance_bay`, Signal Control Room = `signal_control`, Central Clock Chamber = `station_atrium`). The ideas without a home (Station Office, Power Room, Baggage Storage as a secret room) are candidates for the two new rooms the owner already approved for Step 2 (R11/R12). Keep the street-stairs exit |
| K3 | Two environment palettes (`chapter1.1_map.png` cool blue-teal + red LEDs; `chapter1.2_map.png` warm brown-amber; `chapter1_map.png` dark with amber lamps) | The current chapter uses `TLF-CH01-32` | **Sol** picks one direction for Ch1. Good story props from the references fit canon and the research-facility link: the "DESTINATION: NOWHERE - 23:59" board, "A1 → Research" / "R&D Access" door, Sector A pillars, a "CLOSED TRACK" notice |
| K4 | **Elias reference** (`elias_ref.png`) vs. the finished Elias v2 | Reference: white lab coat, red scarf, goggles, ID badge, hourglass on the belt, bandaged cheek, chibi proportions, Run/Hurt/Knockdown. Built: brown trench coat, 32×48 px, 4-head proportion, 80 frames, integrated in all rooms (`ch01_char_elias_base_sheet.png`, ART_BIBLE §2) | Adopting it **replaces a finished asset** (Elias v3), which needs your approval. Run is not in the game, and Hurt/Knockdown don't fit a game without damage (GDD §17); leave them out. A lab coat + ID badge tells the player from the first frame that Elias is a scientist, which is a mild spoiler of his ELYSIUM link. The red scarf is a strong silhouette at 32×48 and helps Ending 3 (K6) |
| K5 | **Mira reference** (`mira_ref.png`) | The visual design (lavender, research partner, Fade/Disperse) fits. But its background text conflicts with Story Bible §3.2: "Tolong... teruslah mengingatku" (keep remembering me) is the opposite of Mira's canon ("don't lose yourself trying to remember me", "choose to live"); "a fragment begging for help" frames her as someone to be saved; "as if she knows the whole timeline" is the Operator's trait | Adopt the look; the Story Bible overrides the reference text. Mira is not on screen in Ch1 (voice + Trace silhouette), so this matters from Ch2 on |
| K6 | **Operator reference** (`operator_ref.png`) | A hood and a cracked white mask hide the face (OK, rule 2). But: (a) **Attack (Anomaly)** animations mean combat, which is out of scope (GDD §17); (b) the hourglass lantern replaces the canon pocket watch, while the Story Bible requires "a pocket watch of similar design", "hand gestures like Elias" and "the same temporal effect as Elias's abilities"; (c) Ending 3 shows a figure **"wearing the same clothes as Elias, the same pocket watch, seen from behind"**, which must match the Operator's composition. A robe/mask silhouette that shares nothing with Elias weakens that clue | Keep the hood/mask (mystery). Have Sol add elements that link to Elias: the same pocket watch, the same hand gesture, the same scarf colour under the robe, the same temporal VFX. Drop Attack; keep "Restrict/Block" as a non-combat barrier gesture. The background text ("knows how the journey ends, tries to stop him to prevent the mistake repeating") fits canon, as design intent only, never as in-game exposition |
| K7 | Hourglass motif in all three character references | Canon motifs (Story Bible §8): pocket watch, the 23:59 clock, suspended rain. The pocket watch is the only time tool | Sol decides: the hourglass as the ELYSIUM project emblem (OK) vs. a second personal device (not OK, it competes with the watch) |
| K8 | Reference rendering vs. the technical pipeline | The references are high-colour painted art with glow and soft gradients. The pipeline is 640×360, 32-colour palette, binary alpha, 32×48 characters, reproducible generators (ADR-003/019, `ART_PIPELINE.md`: AI images are references only) | Use the references for costume, silhouette, colour mood and props, translated into the existing constraints. **No resolution or pipeline change** (that would be architecture churn) |
| K9 | Infinite Library palette (directive §5: warm wood, gold, sunlight, not purple) | The Mira/Operator in-game panels show purple, library-like rooms | Record in ART_BIBLE as a Ch3 rule when Ch3 is planned; don't use those panels as Ch3 environment references |
| K10 | Smoke tests on Windows/Linux (directive P0) | There is no export preset | P0 task (plan P0-4) |
| K11 | Step 1 expansion vs. "no scope expansion without approval" | Step 1 was approved by the owner on 2026-11-01 (ADR-020 amendment) before this directive | It continues as the P0 path to a full-length Ch1, unless you say otherwise |
| K12 | `ref/` sits at the repository root, untracked | Agents in other worktrees (Sol, Argon) can't see untracked files in the Lead's checkout | Commit to `design/art/reference/ch01/` (about 14 MB), marked "concept reference, not shippable" (`ART_PIPELINE.md`), after your OK |
