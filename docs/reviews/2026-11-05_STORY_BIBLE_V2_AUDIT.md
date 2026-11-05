# Audit: existing story material vs. Story Bible v2.0 ("Revised Operator Mystery")

**Date:** 2026-11-05 · **Auditor:** Agent 1 (Lead, Opus 5.5) · **Source:** `docs/STORY_BIBLE_AND_NARRATIVE_MASTER_PROMPT.md` (user, v2.0) · **Main:** `0ab5bf5`
**Scope (bible §14 steps 1-3):** read the existing story material, find conflicts, list the changes. Nothing has been changed yet; canon changes wait for the user's decisions (§5).

## 1. Sources read
- `docs/GDD.md` (§1, §4, §5, §8, §9, §12)
- `docs/PRD.md` (§2, FR-009/016/020, §8, §9)
- `docs/MASTER_PROMPT.md` §3
- `README.md`
- `agent_prompts/AGENT_2_GEMINI_4_ARGON_DESIGN.md`
- `docs/tasks/TLF-003.md`, `docs/TLF-001_AUDIT_REPORT.md`
- `design/ch01/CH01_BEAT_SHEET.md` (beats 01-10, §6 canon answers, §7 Step 1)
- `design/ch01/CH01_EXPANSION.md` (§4b NPCs, §6 seeds, §7 Q-6/Q-7)
- `design/ch01/COMMUTERS_STEP1.md`
- `narrative/ch01/CH01_TEXT.md`: all dialogue, documents, journal, fragment and memory text, i.e. the generated `localization/ch01_text.csv`
- `scripts/chapters/ch01/chapter01.gd`: beat wiring and the Beat 10 outro

There are no cutscene scripts, chapter scripts beyond Ch1, ending sequences or audio logs other than Mira's recorder yet. Ch1 is the only built content.

## 2. Verdict
- **The Ch1 game content is mostly compatible.** Movement, Trace/Rewind/Freeze/Echo, Mira's message, the frozen city and the "VOICE" speaker label all match. No Ch1 line has the Operator confirm who he is.
- **The design documents conflict.** GDD, MASTER_PROMPT, the Argon prompt, the TLF-003 canon checklist and the beat sheet state as **canon that "the Operator is a future Elias"**, and the GDD says the game **reveals** it. Bible v2.0 forbids confirming it (§3.3, §7.2).
- **Ch1 has three real story gaps:**
  - there is no Operator sighting (bible Ch1 event 7, the anchor for Ending 3)
  - the Beat 10 hook line is wrong ("You are late. Again." is required, and Ending 3 reuses it)
  - Beat 10 is not a cinematic in the build (dialogue only)
- **Beat 09 may reveal too much too early** (see C10).

## 3. Conflicts and gaps

| # | Where | Today | Bible v2.0 | Severity | Proposed change |
|---|---|---|---|---|---|
| C1 | GDD §1, §4 (Operator row); MASTER_PROMPT §3; `AGENT_2_GEMINI_4_ARGON_DESIGN.md`; `CH01_BEAT_SHEET.md` §3 last row; `TLF-003.md`, TLF-001 audit (canon checklist) | "The Operator ... is a future Elias", "ultimately revealed as a future version of Elias" | Never revealed or confirmed. Three interpretations (future Elias / construct of Elias's memory / someone else trapped). Ending 3 gives the strongest visual/audio hint, never a verbal one | **High** | New canon ADR (ADR-022) replaces the old canon. Rewrite these lines; historical task files get a "superseded by ADR-022" note instead of a rewrite |
| C2 | GDD §1 | "the catastrophe was caused by a future version of himself in an attempt to prevent the death of Mira" | The disaster comes from Elias's own refusal to lose Mira (revealed in Ch4). Mira is a consciousness reconstruction (revealed in Ch5) | **High** | Rewrite the high concept without "future version" and "death" |
| C3 | GDD §4 + §5 (Ch4 "introduce Elias-0"); MASTER_PROMPT; Argon prompt | Character **Elias-0**, "the original Elias" | Not in the bible (main cast: Elias, Mira, Operator, Archivist). A character called "the original Elias" would also answer the identity question | Medium | **D4**: drop Elias-0 as a character. "Level-0 clearance" in Ch1 stays as a clearance name |
| C4 | GDD §4 | Archivist = "a construct formed from memories of people erased by timeline changes" | Keeper of memory recordings, knows *possible* events but not which happened, may hide truths to protect Elias | Low | Replace with the bible text |
| C5 | GDD §12; MASTER_PROMPT §3 | **A New Beginning:** "Elias loses his memories". **The Paradox:** "merge timelines; Elias loses a singular identity". **Secret:** "discover the reconstruction process" | **A New Beginning:** stops ELYSIUM, keeps the memory and accepts the loss, Mira's farewell, 00:00. **Eternal Stillness:** becomes the keeper, a watcher on a screen. **The Paradox:** merges with the core; the Operator composition; "You are late. Again."; 23:59; no narration. **Last Player:** an unlisted room, stop outside procedure, 00:01, "Someone is still watching." | Medium | Rewrite the endings (count unchanged: 3 + 1 secret = PRD's "4 endings including one secret"). Write `ENDING_DESIGN.md` with triggers and save state per bible §10.4 |
| C6 | GDD §5 chapter table | Ch3 = "introduce room rotation, doorway graphs"; Ch4 = "introduce Elias-0" | Ch3 = Infinite Library, the Archivist, **controllable Dual Elias**; Ch4 = Broken Causality puzzles, the tragedy | Medium (later chapters only) | Lead decision: the Library keeps spatial-graph puzzles as its environment, and Dual Elias becomes Ch3's new mechanic. Ch4's purpose becomes "the experiment, causality puzzles". Ch1 is not affected |
| C7 | GDD §9 / ADR-008 (Echo) | "Echo" = a recorded copy of the player | **Dual Elias:** Elias Present + Elias Past (an extension of Temporal Echo); Ch1 introduces it; it becomes controllable in Ch3. Special rule: Elias Past sometimes acts unbidden (rare, authored, foreshadowed) | Low (Ch1) | Player-facing name stays **Echo**; "Dual Elias / Elias Past" is the design term and the Ch3+ extension. The "unbidden action" must be authored and deterministic (a future ADR, not random). OP_B05_01 ("An echo only does what you already chose to do.") becomes deliberate foreshadowing: keep it |
| C8 | `CH01_BEAT_SHEET.md` §6 Q2; `CH01_TEXT.md` rules | The Operator "communicates exclusively through fixed/old communication devices" and is never seen | A recognisable **silhouette** with a consistent visual language (face never visible, hand gestures like Elias, the same pocket watch, the same temporal effect). Ch1 event 7: **a mysterious figure seen briefly at the end of a corridor**. Ending 3 returns to "the place where the Operator was first seen", with an identical composition | **High** | Amend the rule: voice through devices **plus** rare silhouette sightings. Add a Ch1 sighting (**D3**). Operator silhouette art: Sol directs, Argon makes it |
| C9 | Beat 10: `OP_B10_01/02` (payphone) + beat sheet broadcast screen | "Now you see why I told you to leave the terminal alone." / "Keep moving. She's in the Central District, and the city remembers what you lost." + Mira on a plaza screen "in an observation tower" | Ch1 ending: a voice through a communication device: **"You are late. Again."**, and it is not known who says it. Ending 3 replays this exact line. Mira is not only someone to be saved; her status is revealed gradually | **High** | Replace both lines with "You are late. Again." Remove "She's in the Central District" (it places Mira physically and frames a rescue). Keep or drop the silent broadcast image (**D2**) |
| C10 | Beat 09: `EL_B09_02` "Level-0 clearance. My clearance. I sealed this station.", `DOC_DISPATCH_BODY_1` "USER: ELIAS", `JRN_CH1_SEAL_ELIAS` (fact) | Ch1 states as a **fact** that Elias sealed the station | Ch1 event 6: "a sign that someone used the temporal system before him". Ch4's major revelation: the disaster comes from Elias's own decision. "Don't give the answers too quickly" (§13) | Medium-High | **D1**: keep it, or turn it into a question (recommended: the terminal knows his hand, but the user field is corrupted; Elias asks "Did I do this?"; the journal entry becomes a theory). PRD §8 still needs "one major revelation" in Ch1: the revelation becomes "this station was sealed deliberately, from here, with a clearance my hand opens" |
| C11 | `chapter01.gd:254-275` | Beat 10 = three dialogue lines, then the chapter-complete overlay. No camera pull-back, no frozen-rain shot, no broadcast screen | Ch1 ends with Elias leaving the station and seeing the **whole city frozen**. The bible wants short cutscenes and a reusable shot language (Ending 3 mirrors the Ch1 composition) | Medium | New task: a Beat 10 cinematic (scripted camera, frozen rain, the city plate, the voice line). Its framing rules go into `OPERATOR_MYSTERY_GUIDELINES.md` so Ending 3 can mirror them |
| C12 | Beat 01: `EL_B01_04` + `UNLOCK_TRACE` | Picking up the watch gives a monologue and a toast | "When Elias touches it, he sees flashes of events that were not in the room before" | Low | With Trace-first (Step 1), the first touch plays one short Trace memory (a flash). Small text + TLF-055 wiring |
| C13 | GDD §1/§5 | No year; "a futuristic city" | **2097, Elysium City**; ELYSIUM's five purposes; parts of the city show past, future or mixed states | Low | Add to the GDD / `STORY_BIBLE.md`. Ch1 text is compatible (it names no year) |
| C14 | GDD §8 | Still says "**Echo:** Reveal residual traces" (renamed Trace by ADR-014) and lists **Time Shift** | Ch6 lists Memory Reconstruction and causality puzzles; Time Shift is not mentioned | Low | Fix the stale Echo/Trace line now. Time Shift / Memory Reconstruction is a later-chapter mechanics question (ADR when Ch2+ is planned) |
| C15 | `CH1-PZ-004` "The Synchronized Substation" | — | Ch1 signature puzzle **"The Forgotten Sequence"**: record actions, replay them to run several mechanisms at once, which introduces Echo / Dual Elias | Low | PZ-004 already is that puzzle (an echo pulls breaker A while Elias pulls B). Recommended: rename its player-facing title (`PZ004_TITLE`) to "The Forgotten Sequence"; no logic change |
| C16 | Ownership (`ADR-017` am. 2026-11-05) | Argon owns `design/ch01/**` and `narrative/**` (narrative, puzzle specs) | Bible §11 lists Argon for **visual** work only; Opus does story integration, chapter structure, narrative progression, ending state and story-consistency review; Flash does dialogue/narrative triggers and ending tests | Medium | **D5**: who writes story canon and dialogue text |
| C17 | Bible §12 | — | Six docs: `STORY_BIBLE.md`, `NARRATIVE_DESIGN.md`, `CHARACTER_BIBLE.md`, `CHAPTER_BREAKDOWN.md`, `ENDING_DESIGN.md`, `OPERATOR_MYSTERY_GUIDELINES.md` | — | Create them after the decisions (**D6** language). `STORY_BIBLE.md` is canon; the other five are focused views that link to it, with no copied lore, so they can't drift apart. The GDD/PRD then point to them |

## 4. Already consistent (keep)
- **Operator dialogue in Ch1:** no line says "I am you / your future self / Elias". The speaker label is `SPK_OPERATOR` = "VOICE". He helps (B03) and obstructs (B07: "Leave it alone"). The single shared phrase "Time doesn't stop. It waits." (EL_B01_03 / OP_B03_03) is a clue, not a confirmation. This matches bible §3.3 and §7.2.
- **Mira in Ch1:** the voice recorder ("don't come back for me. Promise me you'll let the clock pass midnight."), the two silhouettes on the bench and the fragment "She was asking me for something, and I said no." These match §3.2: she sees the risk and doesn't want Elias to destroy himself. It does not pre-empt the Ch2 line ("choose to live").
- **Frozen commuters (13, Step 1) and their memories:** none names the Operator or explains ELYSIUM, which matches "some people remain only as recordings or temporal shadows". The Step 2 seeds (controller "Which terminal, the Atrium?", porter "calls before the order") are questions, not answers, so they are allowed. The medic's "the man from the lab" is already marked to be softened or cut (user decision 2026-11-01).
- **Motifs:** 23:59, the pocket watch, the evacuation at 23:54, "chronometric backflow", the threshold index (space is unstable), suspended rain (EL_B10_01).
- **Mechanics taught in Ch1** (Rewind, Freeze, Echo, Trace, one spatial foreshadow) cover bible Ch1 events 1-5.
- **PRD:** 5-8 h, 6 chapters, 4 endings including the secret one, one Ch1 revelation and one cinematic. Only the content of the revelation (C10) and of the endings (C5) changes.

## 5. Decisions for the user
| # | Question | Options | Recommendation |
|---|---|---|---|
| D1 | Beat 09 revelation (C10) | (a) keep "I sealed this station" as a fact · (b) make it a question: the terminal knows his hand, the user name is corrupted, "Did I do this?" | **(b)**: it keeps Ch4's revelation and fits "someone used the system before him" |
| D2 | Beat 10 hook (C9) | the voice line becomes "You are late. Again." (required); Mira's broadcast image: (a) keep, silent · (b) drop | **(a)** silent image + the new line |
| D3 | Where the Operator is first seen (C8) | (a) **Arrival Platform**, the far end of the platform tunnel, right after the watch pickup: a silhouette checks a pocket watch and is gone when Elias walks closer · (b) Upper Vestibule (Beat 08), at the end of the looping corridor | **(a)**: Ending 3 shows the figure "checking the watch exactly like Elias's opening animation" at "the place the Operator was first seen", so the loop closes at the game's first room; replaying Ch1 reveals it (§7.3) |
| D4 | Elias-0 (C3) | drop · keep as hidden lore | **drop** |
| D5 | Who writes story canon and dialogue (C16) | (a) Opus (Lead) writes the canon docs and dialogue (as TLF-024 did); Argon keeps puzzle/level specs + all visuals; Flash wires triggers · (b) Argon writes narrative as before | **(a)**: matches bible §11 |
| D6 | Language of the six new docs (C17) | English (like all repo docs and agent tasks) with this Indonesian file kept as the source directive · Indonesian | **English** |

## 6. Change plan (after the decisions)
1. **Canon (Lead, docs only):** ADR-022 "Story Bible v2.0 canon". It supersedes "Operator = future Elias", Elias-0 and the old ending texts, and adds the Operator mystery rules as a review gate for every narrative delivery. Update GDD §1/§4/§5/§8/§12, MASTER_PROMPT §3, README, the Argon prompt and the beat sheet canon row; add superseded notes in TLF-001/TLF-003. Write the six docs (C17).
2. **Ch1 text (writer per D5), in `CH01_TEXT.md`, then the generator:**
   - OP_B10_01/02 → "You are late. Again."
   - Beat 09 per D1 (EL_B09_02/03, DOC_DISPATCH_BODY_1/2, JRN_CH1_SEAL_ELIAS category)
   - the watch-pickup flash (C12)
   - `PZ004_TITLE` (C15)
   - beat sheet updated to match
3. **Ch1 scenes:**
   - Beat 10 cinematic (C11) and the Operator sighting (D3): new tasks for Flash, after TLF-055, with Opus contracts for camera scripting.
   - Operator silhouette + watch gesture: an art task for Argon, directed by Sol, under the visual restrictions (no face).
   - Mystery check (bible §10.5) in each review.
4. **Not affected:** TLF-054 (puzzle logic), TLF-055 (Step 1 rooms), TLF-056 (real-input tests), TLF-057 (Step 1 art). They continue unchanged. Changing text keys does not touch them, except that `PZ004_TITLE` comes from the puzzle data generator (TLF-054 output), so it goes in after TLF-054.
5. **Chapters 2-6:** plan them from `CHAPTER_BREAKDOWN.md` only after the Ch1 vertical slice (the bible's last line: "the foundation first").
