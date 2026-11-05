# THE LAST FRAME — SAFE ENHANCEMENT DIRECTIVE

**Document type:** AI Agent Handoff / Non-Destructive Feature Roadmap  
**Version:** 1.0  
**Date:** 2026-11-04  
**Status:** PROPOSAL FOR AUDIT — NOT BLANKET IMPLEMENTATION APPROVAL  
**Current production stage:** Chapter 1 — The Forgotten Station, in progress  
**Primary recipient:** Claude Opus 5.5 High (Lead Architect / Integration Owner)  
**Engine / language:** Godot 4.x / GDScript  
**Visual direction:** 2.5D isometric, premium cinematic HD pixel art

> **CRITICAL — READ FIRST:** This document supplements the existing project. Do **not** restart, recreate, rename, or overwrite the current Godot project, Chapter 1 scenes, scripts, assets, story documentation, or agent changes. **Do not implement all 12 ideas now.** First audit the actual repository and report which features already exist, which are partially implemented, and which are proposed. Obtain owner approval before scope-expanding changes. Protect the working Chapter 1 vertical slice above all else.

## 1. Context and source of truth

The current game is **THE LAST FRAME**, a single-player psychological sci-fi narrative puzzle adventure. Elias wakes in an abandoned station, his memories missing, where clocks show **23:59**. His pocket watch enables temporal manipulation. His search intersects with Mira, ELYSIUM and the enigmatic Operator. The narrative is structured around **six chapters** and multiple endings. The Operator's identity must remain **ambiguous**, including in the third ending.

**Source-of-truth order when documents conflict:**
1. The actual current repository, working implementation, and latest explicit owner instructions for *what exists and what is approved*.
2. Latest approved Story Bible / Narrative Master Prompt for canonical story and mystery rules.
3. Existing GDD / PRD / architectural decisions for gameplay and engineering constraints.
4. This document as a **candidate enhancement plan**, not a replacement for any of the above.

If a conflict is found, **document it and ask for a decision** rather than silently changing an established design. Confirm file paths and class names from the repository; any paths below are suggestions only.

## 2. Chapter 1 canon to preserve

**Chapter:** The Forgotten Station.  
**Narrative purpose:** Establish mystery and teach first temporal mechanics.

Expected story beats from the existing Story Bible:
1. Elias explores an abandoned underground station.
2. Movement and interaction are introduced.
3. He encounters his first temporal recording.
4. Basic **Rewind, Freeze, and Temporal Echo** are introduced.
5. He discovers a message from **Mira**.
6. Evidence suggests that someone else used temporal systems before him.
7. A mysterious figure is briefly seen at the end of a corridor.
8. Signature puzzle: **The Forgotten Sequence**, combining recorded Elias actions with simultaneous mechanisms.
9. Chapter exit reveals an entire city frozen in time; a voice says: **"You are late. Again."**

Preserve these beats unless the owner explicitly revises them. Do not reveal that Elias is The Operator or make that interpretation canonical.

## 3. What to do NOW (Chapter 1 only)

### P0 — Stabilize and finish the playable vertical slice

**Required before optional features:**
- Inspect actual game boot, chapter entry, player movement and isometric navigation.
- Verify interactable object feedback, controls, collision, camera, and scene transitions.
- Verify pocket-watch mechanics already implemented: Rewind, Freeze, and Temporal Echo; do not create redundant systems.
- Verify **The Forgotten Sequence** has a reproducible solution, a restart/reset path, and clear success/failure states.
- Verify story trigger order: first recording, Mira message, temporal-system evidence, silhouette, frozen-city reveal, end-of-chapter line.
- Verify checkpoint/save/load behavior *if already in current scope*; ensure puzzle state does not desynchronize.
- Audit readability of sprite scale, navigation depth, walkable spaces, interaction cues, UI and audio.
- Run smoke tests on available Windows/Linux targets where possible; report untested targets explicitly.

**P0 acceptance gate:** A new player can begin Chapter 1, learn the controls, learn the intended mechanics, solve The Forgotten Sequence, and reach the ending without a softlock or a spoiler of The Operator's identity.

### P1 — Low-risk enhancements that support Chapter 1

Implement **only after P0 is stable**, and only when existing architecture allows incremental additions:

1. **Optional journal foundation (minimal):** Log already discovered clues (Mira's message, time anomaly, first temporal recording). Do not build a full deduction graph now. UI can initially be a simple read-only entry list.
2. **Environmental storytelling pass:** Add a small number of purposeful details: 23:59 clocks, staff note, recording artifact, evidence of prior device use. Tie each detail to later revelations; avoid filler collectibles.
3. **Tiered hint hooks for The Forgotten Sequence:** Three levels: observational hint -> mechanism hint -> explicit action sequence. Do not trigger automatically or change puzzle logic unless explicitly approved. Respect accessibility settings if present.
4. **Lightweight Operator foreshadowing:** Use an understated visual/audio motif or clue; preserve ambiguity. No identity reveal, face confirmation, or explicit exposition.
5. **Audio affordance pass:** Temporal operations receive distinguishable sound feedback; avoid large new dynamic audio architecture for Chapter 1.

**P1 implementation strategy:** Feature flags or opt-in scene additions, small reviewable diffs, reused existing systems, and immediate regression tests. Each change needs a short description of player benefit and rollback steps.

### P2 — Design only, defer implementation

- Temporal Echo 2.0: advanced recording, replay and controlled deviations.
- Full Memory Reconstruction and contradiction / evidence graph.
- Branching Truth, multi-reality events, unreliable narration systems.
- Reality Shift and impossible architecture.
- Persistent world changes across chapters.
- Pocket-watch ability upgrades beyond current Chapter 1 spec.
- Dynamic music/silence system beyond basic audio feedback.
- Residual Memories / New Game Plus.
- **Unreliable Save** as a *fictional effect only*; never corrupt real player save files.

These can receive short design notes, dependencies and estimates, but **must not be implemented as new Chapter 1 scope without explicit authorization**.

## 4. Feature backlog: twelve proposed improvements

| ID | Feature | Intended value | Earliest sensible phase | Constraint |
|---|---|---|---|---|
| F01 | Memory Reconstruction | Build narrative investigation puzzles from conflicting memory fragments | Chapter 2 | Distinguish discovered facts from hypotheses |
| F02 | Temporal Echo 2.0 | Deepen existing signature time puzzles | Chapter 1 polish / Chapter 4 depth | Preserve determinism, reset path and explainability |
| F03 | Reality Shift & Impossible Architecture | Make space itself a puzzle | Chapter 3 or 5 | Do not introduce ambiguous traversal / softlocks |
| F04 | Operator's Invisible Influence | Build mystery without explicit exposition | Chapter 1 light foreshadowing onward | Never confirm the Operator's identity |
| F05 | Environmental Storytelling Layers | Reward attention and revisit locations | Chapter 1 light pass onward | Every clue must respect narrative canon |
| F06 | Branching Truth | Allow competing accounts of one event | Chapter 3 | Avoid pretending one unverifiable memory is absolute truth |
| F07 | Persistent World Changes | Meaningful cross-chapter consequences | After state architecture audit | Use scoped flags, not global timeline simulation |
| F08 | Elias's Journal | Track clues, locations and player theories | Minimal Chapter 1 foundation | Do not auto-solve mysteries for the player |
| F09 | Pocket Watch Evolution | Structure ability progression | Existing Chapter 1 basics, later chapters | No duplicate time-controller architecture |
| F10 | Dynamic Sound & Silence | Communicate temporal reality changes | Chapter 1 audio polish, later depth | Audio must provide feedback without jumpscare dependence |
| F11 | Adaptive Hint System | Prevent puzzle frustration | Small Chapter 1 prototype | Optional and staged; no automatic spoilers |
| F12 | Residual Memories NG+ | Reward replay and reinterpretation | Post-full-game | Keep canon ambiguity and save integrity |

**Experimental proposal X01 — The Unreliable Save:** Only simulate narrative mismatch after reloading using reversible flags and visual changes. The underlying save must remain accurate, stable, and recoverable. Deferred until reliable save/load architecture and owner approval. Never alter system save files deceptively.

## 5. Per-chapter mechanical identity (planning, not implementation instruction)

| Chapter | Narrative role | Distinctive gameplay direction |
|---|---|---|
| 1 — The Forgotten Station | Teach time, mystery setup | Rewind, Freeze, introductory Temporal Echo, The Forgotten Sequence |
| 2 — The City That Remembers | Memory, loss, distrust of experience | Memory Reconstruction, evidence and layered environmental storytelling |
| 3 — The Infinite Library | Truth, identity, manipulated memories | Branching Truth and spatial reading puzzles |
| 4 — Paradox Laboratory | Causality and consequences | Causal loops, advanced Dual Elias / Echo cooperation |
| 5 — Beyond Reality | Destabilized rules | Controlled Reality Shift and combined mechanics |
| 6 — The Last Frame | Payoff and interpretation | Final integrated puzzle, narrative consequences and established endings |

**Art direction note:** The Infinite Library should use warm **wood-brown bookshelves, golden yellow and bright sunlit tones**, not a predominantly purple palette. Keep each chapter visually distinct while maintaining overall pixel-art cohesion.

## 6. Engineering principles for AI agent

- **Audit before edits.** Map existing scene tree, autoloads, input actions, save format, player controller, time manipulation systems, puzzle trigger code, journal/dialogue systems and test tools.
- **Non-destructive changes:** Extend existing modules; do not replace whole modules just because alternatives seem cleaner.
- **Determinism:** Echo playback and puzzle state must reset predictably. Test replay and seek behavior where applicable.
- **Separation of concerns:** Temporal mechanics, puzzle rules, story triggers, journal flags and presentation should remain decoupled through existing patterns/signals.
- **Data-driven where practical:** Clues, hint tiers and story flags should use established project data conventions, not scattered hard-coded scene references.
- **State safety:** Save/load upgrades need versioning or backward-compatibility assessment. Test reloading during and after the signature puzzle.
- **Visual fidelity:** Avoid placeholder assets in approved polished environments unless tagged with explicit ownership and replacement criteria. Do not generate purple-tinted Infinite Library designs by default.
- **Accessibility:** Distinguishable cues for time states; avoid relying on audio or color alone. Hints must be optional.
- **Performance:** Monitor temporal clone count, recording buffers, effects and pathfinding on representative hardware.
- **Branch and review discipline:** Before an invasive change, create a branch/backup using the project's existing workflow. Never discard uncommitted human or agent work.

## 7. Multi-agent ownership and conflict prevention

| Agent | Responsibility in this directive | Boundaries |
|---|---|---|
| **Claude Opus 5.5 High** | Technical lead, repo audit, integration plan, architecture decisions, review/merge | Must protect existing implementation; authorize coding scopes |
| **Gemini 3.8 Flash High** | Small feature tasks, UI hooks, smoke/regression tests, documentation | Work on explicitly assigned files/branches only |
| **Gemini 4 Argon** | Asset and sprite studies, environmental visual details, lighting/temporal effect concepts | No unapproved replacement of finalized assets |
| **GPT-6.1 Sol** | Art direction and review; Argon fallback if unavailable | Ensure palette and story motifs remain consistent |

**Do not assign Claude Sonnet 5.5** under the archived project workflow. If currently available model names differ, the owner must approve substitutions. Do not assume an agent has access to another agent's unsaved files.

## 8. Required first response from the lead agent

Before writing feature code, the lead agent should produce the following deliverables **based on actual files it can inspect**:

1. **Project State Audit** — current Chapter 1 completion, working scenes, current ability implementations, known bugs/blockers; cite exact repository paths.
2. **Gap Matrix** — mark each feature/status as `EXISTS`, `PARTIAL`, `MISSING`, or `NOT INSPECTED`; provide evidence paths.
3. **Chapter 1 Safe Plan** — prioritized P0 fixes and optional P1 scope, each with owner, dependencies, risk, estimated effort and test criteria.
4. **Deferred Backlog** — assign F01–F12 and X01 to later phases without coding them.
5. **Conflict Report** — identify any conflicts among this file, existing Story Bible, GDD, PRD, and current repository; make no silent canonical edits.
6. **Approval Request** — ask the owner to approve specific P1 tasks before implementing them.

Suggested output names **only if they do not conflict with the repository's conventions**: `docs/CHAPTER1_AUDIT.md`, `docs/CHAPTER1_SAFE_PLAN.md`, `docs/FUTURE_FEATURE_BACKLOG.md`.

## 9. Definition of done — Chapter 1

- [ ] Chapter 1 loads and finishes as designed.
- [ ] Elias's movement, camera, interactables and collisions work.
- [ ] Rewind, Freeze and Temporal Echo are taught clearly as per established design.
- [ ] The Forgotten Sequence is solvable, resets properly and cannot softlock progression.
- [ ] Mira's message, evidence of previous time-system use and the figure's brief appearance are preserved.
- [ ] Exit scene conveys frozen city and "You are late. Again."
- [ ] No explicit Operator identity confirmation or premature ending spoilers.
- [ ] Existing save/load behavior has not regressed.
- [ ] All changed code/scenes have focused validation and documented known limitations.
- [ ] P1 additions were owner-approved, scoped and easy to revert.

## 10. Copy-paste instruction to the AI agent

> Read `THE_LAST_FRAME_CHAPTER_1_SAFE_ENHANCEMENT_DIRECTIVE.md` as a proposal and safeguard document, not permission to rebuild the project. We are **currently developing Chapter 1**. First inspect the existing Godot repository and all currently approved Story Bible/GDD/PRD documents. Preserve every working feature, asset and existing narrative decision. Give me: (1) exact Chapter 1 audit, (2) gap matrix, (3) safe P0/P1 implementation plan, (4) deferred roadmap for later chapters, and (5) conflicts/questions requiring my decision. **Do not start implementing new enhancements until I approve the scoped plan.** Never reveal The Operator's identity explicitly. Focus on finishing Chapter 1 as a polished, stable vertical slice.

---

**Owner decision rule:** Core Chapter 1 completion takes precedence over feature expansion. The best next improvement is the one that improves the current playable build without introducing architecture churn, narrative contradictions or regression risk.
