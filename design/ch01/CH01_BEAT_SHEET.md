# Chapter 1 Narrative Beat Sheet — "The Forgotten Station"

**Task:** TLF-003  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Location:** Elysium-09 Underground Transit Station  
**Target Duration:** 30–45 minutes (**Estimated Total: 38 minutes**)  
**Mechanic Scope (SD-1):** `Rewind`, `Freeze`, `Echo` (record/replay, max 1 active, 20 s / 1200 ticks), `Trace` (reveal residual traces, accepted per ADR-014), and one `Doorway Reassignment` spatial foreshadow puzzle (ADR-009).  
**Excluded Mechanics (SD-1 Out):** `Time Shift`, room rotation, gravity reorientation, spatial folding, dimensional overlap, multiple simultaneous echoes, temporal energy constraints. `Fast-Forward` is not required by any beat below.

---

## 1. Beat Overview & Pacing Summary

| Beat | Title | Location (`ADR-005` Room Prefix) | Role / Special Tags | Puzzle Slot | Mechanics Taught / Tested | Est. Min |
|---|---|---|---|---|---|---|
| **01** | Awakening on the Sub-Line | Arrival Platform (`ch01.arrival_platform`) | Opening / Movement & Inspect | — | Isometric movement, contextual interaction, Journal init | 3 min |
| **02** | The Fractured Turnstile | West Turnstile Gate (`ch01.concourse_west`) | **Pocket-Watch Tutorial** | `CH1-PZ-001` | **Taught:** Pocket watch UI, `Trace`, `Rewind` | 4 min |
| **03** | Call Box 09 | West Concourse (`ch01.concourse_west`) | **NPC Presence #1** (The Operator) | — | Dialogue, document inspection, Journal clue logging | 4 min |
| **04** | The Runaway Shutter | Maintenance Bay (`ch01.maintenance_bay`) | Temporal Combination | `CH1-PZ-002` | **Taught:** `Freeze` · **Tested:** `Rewind` + `Freeze` | 5 min |
| **05** | The Delayed Platform | Security Crossing (`ch01.security_crossing`) | **First Echo Puzzle** | `CH1-PZ-003` | **Taught:** `Echo` (record, replay, hold occupancy, reset) | 6 min |
| **06** | Ghosts in the Waiting Lounge | Waiting Lounge (`ch01.waiting_lounge`) | **Recorded Character Presence #2** (Mira) | — | **Tested:** `Trace` (narrative memory fragment & audio log) | 3 min |
| **07** | The Synchronized Substation | Signal Control (`ch01.signal_control`) | Multi-System Temporal Synthesis | `CH1-PZ-004` | **Tested:** `Echo` + `Rewind` + `Freeze` coordination | 5 min |
| **08** | The Displaced Corridor | Upper Vestibule (`ch01.upper_vestibule`) | **Spatial Foreshadow Beat** | `CH1-PZ-005` | **Taught/Tested:** `Doorway Reassignment` (`SpatialGraph`) + `Trace` | 5 min |
| **09** | Ledger 23:59 | Station Atrium (`ch01.station_atrium`) | **Major Revelation** (Exactly One) | — | **Tested:** `Trace` on dispatch terminal + evidence synthesis | 2 min |
| **10** | Ascent to the Frozen City | Street Exit (`ch01.street_exit`) | **Cinematic Beat** & **Ch2 Exit Hook** | — | Scripted sequence / transition to Chapter 2 | 1 min |
| **Total** | **10 Ordered Beats** | **8 Interconnected Station Rooms** | **All PRD §8 / TLF-003 Milestones Covered** | **5 Puzzle Slots** | **All SD-1 "In" Mechanics Covered** | **38 min** |

---

## 2. Ordered Beat Breakdown

### Beat 01 — Awakening on the Sub-Line
- **Location:** Arrival Platform (`ch01.arrival_platform`) — a dimly lit subterranean Mag-Transit platform. Dust motes hang motionless in shafts of emergency amber light; digital departure boards flicker endlessly on `23:59`.
- **Player objective:** Stand up, orient within the isometric space, inspect the stalled transit car and platform bench, and recover the damaged pocket watch lying beside Elias (`global.pocket_watch`).
- **Mechanic taught or tested:** **Taught:** Isometric 8-directional movement (`WASD` / Left Stick), contextual interaction prompt (`E` / South Button), and opening the Journal (`J` / Menu Button). Demonstrates `InteractionService` feedback on locked or unpowered fixtures before the watch is acquired.
- **Narrative information revealed:** Elias wakes alone on the floor of Station **Elysium-09** with no memory of his arrival or identity beyond his own name etched inside his coat collar. Every station clock is frozen at `23:59`. The transit car doors are sealed from the outside, and a heavy brass pocket watch with a cracked crystal is warm to the touch on the tiles beside him.
- **Emotional tone:** Disorientation, eerie stillness, quiet isolation.
- **Estimated minutes:** 3 min

---

### Beat 02 — The Fractured Turnstile *(Pocket-Watch Tutorial)*
- **Location:** West Turnstile Gate (`ch01.concourse_west` entry threshold, connecting `ch01.arrival_platform` to `ch01.concourse_west`).
- **Puzzle Slot:** **`CH1-PZ-001`** — *One-line intent:* Use `Trace` to reveal how the security turnstile jammed and apply `Rewind` to restore the collapsed barrier arm to its pre-arrival open state (`ADR-007` `initial_history`).
- **Player objective:** Equip the pocket watch, inspect the residual temporal signature on the crushed turnstile barrier, and rewind the mechanism to enter the West Concourse.
- **Mechanic taught or tested:** **Taught (Pocket-Watch Tutorial):** Activating the pocket watch (`Q` / Shoulder Button), cycling abilities (`ability_next` / `ability_prev`), using `Trace` to reveal residual past events around an object, and using `Rewind` (`TemporalComponent` with `REWIND` capability and authored `initial_history`) to step an object back through its discrete state history (`collapsed` → `open`). Also demonstrates explicit `"unsupported"` feedback when targeting non-temporal static pillars.
- **Narrative information revealed:** The pocket watch does not rewind the entire world; it interfaces with localized temporal fractures left in the wake of a station-wide event. A faint `Trace` silhouette at the turnstile shows someone rushing through the gate moments before the ceiling conduit fell and crushed it.
- **Emotional tone:** Wonder tinged with unease; first sense of agency over the frozen environment.
- **Estimated minutes:** 4 min

---

### Beat 03 — Call Box 09 *(NPC Presence #1: The Operator)*
- **Location:** West Concourse (`ch01.concourse_west`) — a ticket hall flanked by shuttered kiosks, scattered luggage, and a ringing emergency wall telephone (`ch01.concourse_west.call_box_09`).
- **Player objective:** Answer the ringing station call box to speak with The Operator, then inspect the nearby Station Evacuation Notice (`ch01.concourse_west.doc_evac_notice`) to unlock the route toward the Maintenance Bay.
- **Mechanic taught or tested:** **Taught:** Narrative dialogue interaction, readable document inspection, and automatic Journal entry updates (distinguishing *Observations* from *Confirmed Facts*).
- **Narrative information revealed:** **The Operator** speaks through the static-heavy receiver—calm, weary, and unsettlingly familiar with how the pocket watch works (sharing a single subtle turn of phrase with Elias's earlier internal monologue). He warns Elias that Elysium-09 is caught in a localized containment lock and instructs him to restore auxiliary power via the Signal Control substation to unseal the street exit. A readable transit bulletin mentions the **ELYSIUM** civic stabilization project and an emergency evacuation ordered at `23:54`—five minutes before the clocks stopped.
- **Emotional tone:** Tense curiosity, cautious reliance on an unseen guide who knows more than he admits.
- **Estimated minutes:** 4 min

---

### Beat 04 — The Runaway Shutter
- **Location:** Maintenance Bay (`ch01.maintenance_bay`) — an industrial service corridor humming with pressurized steam pipes and a heavy counterweighted fire shutter blocking the path to the security crossing.
- **Puzzle Slot:** **`CH1-PZ-002`** — *One-line intent:* `Rewind` a dropped fire shutter to its raised pre-arrival position, then `Freeze` its stripped counterweight gear so the shutter cannot immediately slide shut again while Elias walks underneath (non-lethal, safely resettable).
- **Player objective:** Cross the Maintenance Bay by stabilizing the broken fire shutter and bypassing the ruptured steam vent.
- **Mechanic taught or tested:** **Taught:** `Freeze` (`TemporalComponent` with `FREEZE` capability, halting state updates and rejecting state-changing interactions with `&"frozen"`). **Tested:** Sequencing `Rewind` followed by `Freeze` under a clear, non-lethal, non-punishing timing window with safe reset.
- **Narrative information revealed:** A maintenance technician's clipboard (`ch01.maintenance_bay.doc_tech_log`) notes strange "chronometric backflow" in the station's power grid days before the incident, ordered to be ignored by ELYSIUM project directors.
- **Emotional tone:** Methodical tension, tactile mechanical satisfaction.
- **Estimated minutes:** 5 min

---

### Beat 05 — The Delayed Platform *(First Echo Puzzle)*
- **Location:** Security Crossing (`ch01.security_crossing`) — a split-level transit trench bridged by a retractable walkway and a security gate tied to a distant floor pressure switch.
- **Puzzle Slot:** **`CH1-PZ-003`** — *One-line intent:* Record an `Echo` of Elias stepping onto the weight-sensitive pressure switch, then replay the `Echo` so the ghost holds the switch down while Elias crosses the open security gate and platform (matches `docs/PUZZLE_DESIGN.md` §3, *The Delayed Platform*).
- **Player objective:** Coordinate with a recorded temporal `Echo` of Elias's own actions to hold the floor switch active and cross the security gate to the Waiting Lounge.
- **Mechanic taught or tested:** **Taught (First Echo Puzzle):** `Echo` recording start/stop, deterministic event playback (max 1 active echo, max 1200 ticks / 20 s shown in UI), persistent final-position trigger occupancy (`ADR-008`), and manual echo reset/delete without losing room progress. Also demonstrates that echoes cannot pick up progression items (`&"echo_forbidden"`, `ADR-006`).
- **Narrative information revealed:** Seeing a translucent, phase-shifted copy of himself stand on the switch triggers a fleeting headache in Elias—and a comment from The Operator over the wall PA speaker: *"Don't stare at it too long. An echo only does what you already chose to do."*
- **Emotional tone:** Uncanny self-confrontation; the "aha" thrill of cooperating with one's own past action.
- **Estimated minutes:** 6 min

---

### Beat 06 — Ghosts in the Waiting Lounge *(Recorded Character Presence #2: Mira)*
- **Location:** Waiting Lounge (`ch01.waiting_lounge`) — a quiet passenger seating area overlooking a dark rail tunnel, with an overturned coffee cup, a personal audio recorder on a bench, and a shimmering temporal distortion near the platform window.
- **Player objective:** Use `Trace` on the temporal distortion and play the damaged voice recorder (`ch01.waiting_lounge.audio_mira_01`) to uncover why Elias came to Elysium-09.
- **Mechanic taught or tested:** **Tested:** Using `Trace` for environmental investigation and collecting a **Memory Fragment** (`ch01.fragment.mira_departure`) into the Journal.
- **Narrative information revealed:** Activating `Trace` reveals two residual silhouettes seated on the bench prior to the catastrophe: **Mira** and a frantic man whose posture matches Elias. The voice recording captures Mira's voice pleading in fear of what the experiment might cost him: *"Elias, if the stabilization fails, don't come back for me. Promise me you'll let the clock pass midnight."* This establishes **Mira** as the emotional core of the disaster and frames her perspective as one personal viewpoint within the wider mystery.
- **Emotional tone:** Melancholy, intimacy, emotional grounding amid sci-fi mystery.
- **Estimated minutes:** 3 min

---

### Beat 07 — The Synchronized Substation
- **Location:** Signal Control (`ch01.signal_control`) — the station's elevated electrical control room housing two interlocked breaker consoles, a surge capacitor, and the power feed for the Upper Vestibule.
- **Puzzle Slot:** **`CH1-PZ-004`** — *One-line intent:* First stabilize the decaying surge capacitor using `Rewind` and `Freeze`, then record an `Echo` pulling Primary Breaker A so Elias can pull Secondary Breaker B in synchronization (two-step structure to keep complexity fair).
- **Player objective:** Restore main power to the Upper Vestibule and Station Atrium by stabilizing the capacitor and synchronizing both substation breakers.
- **Mechanic taught or tested:** **Tested:** Multi-system synthesis combining `Rewind` + `Freeze` (Step 1: lock the capacitor charge) with `Echo` (Step 2: dual breaker timing) in a single room, supported by an escalating hint ladder.
- **Narrative information revealed:** Once power surges back, the Signal Control monitors boot up: they show that Elysium-09 is not cut off by rubble—it is enclosed in an artificial temporal boundary anchored to the Station Atrium above. The Operator comes through the control console's wired intercom, sounding urgent, telling Elias to head straight to the street exit and **not** to waste time inspecting the Atrium dispatch logs.
- **Emotional tone:** Rising mastery, growing suspicion toward The Operator's evasiveness.
- **Estimated minutes:** 5 min

---

### Beat 08 — The Displaced Corridor *(Spatial Foreshadow Beat)*
- **Location:** Upper Vestibule (`ch01.upper_vestibule`) — a three-doorway transit hub where geometry has frayed under temporal stress; walking through the North Archway inexplicably returns Elias to the West Archway until the junction graph is re-aligned.
- **Puzzle Slot:** **`CH1-PZ-005`** — *One-line intent:* Use `Trace` to observe doorway destination glyphs and operate two route-junction levers to reassign doorway graph edges (`SpatialGraph` doorway reassignment only, `ADR-009`) so the North Archway connects to the Station Atrium.
- **Player objective:** Break the looping corridor by reassigning the vestibule's doorway connections and enter the Station Atrium.
- **Mechanic taught or tested:** **Taught/Tested (Spatial Foreshadow):** **Doorway Reassignment** (`ADR-009` `SpatialGraph` edge remapping—no room rotation, no gravity, no folding). Teaches the player that doorways in fractured zones are logical graph connections indicated by diegetic route markers, foreshadowing Chapter 3 (*The Infinite Library*).
- **Narrative information revealed:** Space itself is destabilizing near the surface exit. A wall plaque and an inspection note explain that the ELYSIUM field links spatial thresholds via index nodes; when time froze at `23:59`, adjacent corridors decoupled from physical adjacency.
- **Emotional tone:** Surreal awe, cerebral intrigue ("space itself is a puzzle").
- **Estimated minutes:** 5 min

---

### Beat 09 — Ledger 23:59 *(Major Revelation)*
- **Location:** Station Atrium (`ch01.station_atrium`) — the grand vaulted concourse beneath a monumental suspended station clock frozen at `23:59`. At its center stands the Central Dispatch Recorder (`ch01.station_atrium.dispatch_terminal`) guarding the blast doors to the street stairs.
- **Player objective:** Inspect the Central Dispatch Recorder and apply `Trace` to its biometric seal to unlock the street-level blast doors.
- **Mechanic taught or tested:** **Tested:** Narrative synthesis using `Trace` + contextual interaction to trigger a permanent story state flag (`NarrativeState`).
- **Narrative information revealed (EXACTLY ONE MAJOR REVELATION):** When Elias places his hand on the Central Dispatch Recorder and activates `Trace`, the terminal unlocks immediately—recognizing his palm print:
  - **The Revelation (Self-Implication):** The emergency temporal containment protocol that sealed and froze Elysium-09 at `23:59` was manually executed from this terminal using **Elias's own Level-0 ELYSIUM clearance**. Elias is not an innocent passenger caught in an accident—he is the one who locked the station in stasis.
  - **Ambiguous Seed:** In a secondary corner pane of the screen, an unnumbered diagnostic log scrolls through a column of identical `23:59:00 — USER: ELIAS` access timestamps—with no counter, no "exit" label, and no explanation of whether it is a clock fault or something deeper.
- **Emotional tone:** Chilling realization, vertigo, dramatic shift from *"What happened here?"* to *"Why did I seal this station?"*
- **Estimated minutes:** 2 min

---

### Beat 10 — Ascent to the Frozen City *(Cinematic Beat & Exit Hook into Chapter 2)*
- **Location:** Street Exit Stairwell & Overlook (`ch01.street_exit`) — wide stone steps ascending from the subterranean station into the open night air of the city.
- **Player objective:** Walk up the opened station stairs into the surface plaza (hands-off scripted camera transition once Elias crosses the threshold trigger `ch01.street_exit.trigger_outro`).
- **Mechanic taught or tested:** None (scripted **Cinematic Beat** and chapter transition via `SceneRouter` + checkpoint save via `SaveService`).
- **Narrative information revealed & Exit Hook into Chapter 2:**
  - **Cinematic Beat:** As the heavy blast doors part and Elias ascends into the night, the isometric camera pulls back to reveal the skyline beyond Elysium-09. Thousands of raindrops hang motionless like glass beads in mid-air. Vehicles sit halted mid-turn on slick neon streets; towering holographic clocks across the plaza pulse on `23:59`.
  - **Exit Hook into Chapter 2 (*The City That Remembers*):** Across the frozen plaza, a colossal civic broadcast screen flickers between frames—showing **Mira** standing inside an observation tower, looking directly toward the station exit. Beside the station awning, a weathered street payphone (`ch01.street_exit.plaza_payphone`) rings once and clicks onto its external speaker: *"Now you see why I told you to leave the terminal alone. Keep moving—she's in the Central District, and the city remembers what you lost."* The pocket watch chimes once as the screen cuts to black.
- **Emotional tone:** Haunting grandeur, resolve, propulsion into the wider mystery.
- **Estimated minutes:** 1 min

---

## 3. Requirement & Acceptance Criteria Traceability

| Requirement (`TLF-003.md`) | Beat / Section Reference | Verification |
|---|---|---|
| **8–14 ordered beats** | Beats 01–10 (§1, §2) | **10 beats** in strict playable sequence. |
| **Total estimate 30–45 min** | §1 Table & §2 per-beat estimates | `3+4+4+5+6+3+5+5+2+1` = **38 minutes**. |
| **≥ 5 puzzle slots (`CH1-PZ-00N` + one-line intent)** | Beats 02, 04, 05, 07, 08 | **5 slots:** `CH1-PZ-001` through `CH1-PZ-005`, each with one-line intent. |
| **Pocket-watch tutorial** | Beat 02 (`CH1-PZ-001`) | Teaches watch equip, ability selection, `Trace`, and `Rewind`. |
| **First Echo puzzle** | Beat 05 (`CH1-PZ-003`) | *The Delayed Platform* (pressure switch + gate + 1 echo replay). |
| **Spatial foreshadow beat** | Beat 08 (`CH1-PZ-005`) | *The Displaced Corridor* (`SpatialGraph` doorway reassignment only). |
| **≥ 1 NPC or recorded character presence** | Beat 03 & Beat 06 | **The Operator** (live call box dialogue, Beat 03) + **Mira** (recorded audio log & `Trace` silhouette, Beat 06). |
| **Exactly one major revelation** | Beat 09 (*Ledger 23:59*) | Elias's own Level-0 clearance executed the `23:59` station containment seal (with an unnumbered scrolling column of `23:59` entries left as an ambiguous seed). |
| **One cinematic beat** | Beat 10 (*Ascent to the Frozen City*) | Scripted camera reveal of the frozen city at `23:59` with suspended rain. |
| **Exit hook into Chapter 2** | Beat 10 | Mira's image on the plaza broadcast screen + Operator's call via street payphone speaker leading into *The City That Remembers*. |
| **Canon unchanged** | All beats + §6 | Preserves Elias, Mira, Operator (= future Elias, speaking only via old communication devices), Archivist, Elias-0, 23:59, loop, 4 endings. |

---

## 4. Naming Proposal (ADR-014 — Accepted as `Trace`)

Per **ADR-014**, `GDD.md` §8 and §9 previously used **"Echo"** for two different systems:
1. The **record/replay system** where the player coordinates with a recorded copy of their own actions (kept as **Echo**).
2. The **pocket-watch reveal ability** that exposes residual past events, silhouettes, and temporal clues in the environment (accepted name **Trace**; code identifier `trace`).

Below are the **3 candidate player-facing names** evaluated for the reveal-residual-traces ability:

### Option 1: **Trace** *(Recommended & Accepted)*
- **Player-facing verb / noun:** *"Trace"* / *"Temporal Trace"*
- **Rationale:**
  - **Clarity & immediacy:** Functions naturally as both a verb (*"Trace the jammed turnstile"*) and a noun (*"A residual trace lingers by the bench"*).
  - **Zero code/doc churn:** Matches `GDD.md` §5, `PRD.md` §8, `ADR-014`, and code identifier `trace`.
  - **Thematic fit:** Evokes forensic investigation, photographic light trails (fitting *The Last Frame*), and faint imprints left behind in spacetime without sounding redundant alongside *Echo*.

### Option 2: **Imprint**
- **Player-facing verb / noun:** *"Read Imprint"* / *"Temporal Imprint"*
- **Rationale:**
  - **Photographic & memory resonance:** Fits the game's title (*The Last Frame*) and the ELYSIUM theme of preserving human consciousness like an exposure burned onto film.
  - **Distinct silhouette from Echo:** Whereas an *Echo* is kinetic and active (replaying actions), an *Imprint* immediately communicates something static or scarred into a location by intense emotion or temporal trauma.
  - **Trade-off:** Slightly less direct as a single-word action verb on a compact 640×360 HUD ability wheel than *Trace*.

### Option 3: **Afterimage**
- **Player-facing verb / noun:** *"Reveal Afterimage"* / *"Afterimage"*
- **Rationale:**
  - **Strong visual metaphor:** Directly connects to the "Last Frame" cinema/photography motif and accurately describes what the player sees on screen (translucent ghostly silhouettes of Mira, earlier Elias, or past object states).
  - **Clear sensory distinction:** *Echo* is acoustic/action-oriented (repeating your steps), whereas *Afterimage* is purely visual/observational (seeing what was once there).
  - **Trade-off:** Longer label (10 characters) for small pixel-art UI badges at 640×360 internal resolution, and implies purely visual clues even when the ability also surfaces residual audio logs.

> **Decision (ADR-014):** **Option 1 (`Trace`)** is accepted as the canonical player-facing and technical name; narrative prose and journal descriptions may use *"afterimage"* and *"imprint"* as diegetic synonyms.

---

## 5. Mechanics Outside SD-1 I Wanted

**None required.** Every beat and puzzle slot in this Chapter 1 beat sheet works cleanly within the **SD-1 "In"** mechanic set (`Rewind`, `Freeze`, single `Echo`, `Trace`, and single-room `Doorway Reassignment`).

- **Note on `Fast-Forward` (SD-1 Stretch):** I considered using `Fast-Forward` in Beat 04 or Beat 07 (e.g., accelerating a corroded battery charge or decaying a rusted lock), but excluded it from the baseline beats so Chapter 1's teaching curve stays tightly focused on `Rewind` → `Freeze` → `Echo` → `Doorway Reassignment`. If `Fast-Forward` is implemented as a stretch goal, it can optionally be added as an alternative valid solution in `CH1-PZ-002` or `CH1-PZ-004` without altering any beat structure.

---

## 6. Open Canon Questions (Resolved by Lead Review)

1. **Loop Counter Visibility (Beat 09) — Resolved:** No fixed number, no "exit" label, and no memory-wipe statement in Chapter 1. Beat 09's single revelation is Elias's self-implication (his clearance froze the station); the secondary pane shows only an unspecified scrolling list of `23:59:00` timestamps under user `ELIAS` as an ambiguous seed.
2. **The Operator's Voice Modulation in Ch1 (Beat 03 / Beat 07) — Resolved:** Subtle shared phrasing is allowed (at most one or two echoed phrases between Elias and The Operator across Chapter 1, with nothing explicit). The Operator communicates exclusively through fixed/old communication devices (wall call boxes, intercoms, street payphone).
3. **Foreshadowing The Archivist (Optional Lore) — Resolved:** Deferred to Chapters 2–3 so Chapter 1 remains tightly focused.
