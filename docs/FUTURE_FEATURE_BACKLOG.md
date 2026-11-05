# Future Feature Backlog (Safe Enhancement Directive, deliverable 4)

**Date:** 2026-11-05 · **Lead:** Agent 1
**Status:** design notes only. Nothing here is Chapter 1 scope. Every item needs an ADR and your approval before it is built. The Story Bible (`docs/STORY_BIBLE_AND_NARRATIVE_MASTER_PROMPT.md`) wins over this file.

## 1. Features

| ID | Feature | Earliest phase | Depends on | Size | Notes / constraints |
|---|---|---|---|---|---|
| F01 | Memory Reconstruction | Ch2 (*The Apartment That Remembers*); also part of the Ch6 finale | Journal (exists), F07 | L | Keep discovered **facts** apart from player **hypotheses**; the journal's fact/theory split is the base |
| F02 | Temporal Echo 2.0 / controllable Dual Elias | Ch3 (introduction, Story Bible), Ch4 depth | Echo 1.0 (exists) | L | Deterministic, resettable, explainable. Story Bible §6: "Elias Past" sometimes does something unbidden: **authored and scripted**, rare, foreshadowed, never random (the existing line "An echo only does what you already chose to do" is its setup) |
| F03 | Reality Shift / impossible architecture | Ch3 (spatial reading), Ch5 (controlled shifts) | SpatialGraph (exists) | L | Graph-authoritative (ADR-009); no ambiguous traversal or softlocks |
| F04 | Operator's invisible influence | Ch1 light (plan P0-3, P1-4), then every chapter | `OPERATOR_MYSTERY_GUIDELINES.md` (to write) | S per chapter | Never confirm his identity; a mystery check on every delivery |
| F05 | Environmental storytelling layers | Every chapter; Ch1 light pass (P1-2) | — | S-M per room | Each clue respects canon; no filler collectibles |
| F06 | Branching Truth | Ch3 | F01 | L | Competing accounts of one event; never present one unverifiable memory as absolute truth |
| F07 | Persistent world changes | After a state-architecture review, before Ch2 | Save v3 (exists) | M | Scoped narrative flags per chapter, not a global timeline simulation; save migration per change |
| F08 | Elias's journal (deeper: locations, player theories) | Ch2 | Journal (exists) | M | Never solves the mystery for the player |
| F09 | Pocket-watch evolution | Ch2+ (Fast-Forward, later abilities) | `AbilityUnlocks` + wheel (exist) | S per ability | No second time-controller architecture |
| F10 | Dynamic sound and silence | After the Ch1 audio pass (P1-5) | Basic audio | M | Feedback, never jump-scares; every audio cue also visible |
| F11 | Adaptive hints | Small prototype after the playtest #3 telemetry | HintService + telemetry (exist) | S-M | Optional, staged, offered not forced; no automatic spoilers |
| F12 | Residual Memories / New Game+ | After the full game | All endings | M | Keeps the ambiguity; never touches existing saves |
| X01 | Unreliable Save (fiction only) | After stable save/load across chapters | F07 | M | Only a narrative mismatch shown through reversible flags and visuals. **The real save file must never be altered or made inaccurate** |

## 2. Chapter mechanical identity (planning, reconciled with the Story Bible)

| Chapter | Story Bible signature | Directive direction | Reconciled plan |
|---|---|---|---|
| 1 The Forgotten Station | The Forgotten Sequence | Rewind, Freeze, introductory Echo | As built + Step 1 |
| 2 The City That Remembers | The Apartment That Remembers | Memory Reconstruction, layered storytelling | F01 + F05; Mira's past |
| 3 The Infinite Library | Two Sides of Time (controllable Dual Elias), the Archivist | Branching Truth, spatial reading | F02 introduction + F06 + doorway/room graph; **art: warm wood, gold and sunlight, not purple** |
| 4 Paradox Laboratory | The Broken Causality | Causal loops, advanced Dual Elias | F02 depth + causality puzzles |
| 5 Beyond Reality | The Unreliable Reality | Controlled Reality Shift | F03 + combined mechanics |
| 6 The Last Frame | Final convergence, 3 endings + the secret ending | Integrated finale | All mechanics; endings per `ENDING_DESIGN.md` (to write) |

The directive and the Story Bible agree: Dual Elias is introduced in Ch3 and deepened in Ch4. One open technical question for later: the GDD's "Time Shift" (Past/Present/Fractured layers) does not appear in the Story Bible or the directive. Decide when Ch2 is planned.
