# THE LAST FRAME — Product Requirements Document

**Version:** 1.0  
**Status:** Baseline requirements  
**Target:** Windows and Linux PC, single-player

## 1. Product vision

Deliver an atmospheric, premium-feeling isometric 2.5D puzzle adventure in which players manipulate time, spatial relationships and recorded versions of their own actions to solve interconnected mysteries.

## 2. Product goals

1. Deliver a complete, polished Chapter 1 vertical slice.
2. Prove that temporal, echo and spatial systems can work together reliably.
3. Establish a scalable content pipeline for six chapters.
4. Maintain a coherent HD cinematic pixel-art identity.
5. Support keyboard/mouse and controller.
6. Deliver four narrative endings in the full game.

## 3. Non-goals

- Multiplayer or online services.
- Combat-focused gameplay.
- Open-world exploration.
- Procedural generation of main story puzzles.
- User-generated content.
- Complex inventory crafting or survival mechanics.
- Mobile/console release in the initial scope.

## 4. Target platform and technical baseline

- Engine: Godot 4.x stable release selected at project start.
- Language: GDScript, typed where practical.
- Platforms: Windows and Linux desktop.
- Baseline resolution: 1920×1080 output, with configurable window and scaling.
- Performance target: stable 60 FPS on a reasonable mid-range desktop; establish a documented reference machine during development.
- Input: keyboard/mouse and controller.
- Rendering: 2D-focused isometric presentation with layered lighting and effects. Choose renderer according to tested compatibility, not assumption.
- Version control: Git.
- Automated checks: headless import/test where feasible, unit tests for core logic, integration tests for system interactions.

## 5. User stories

### Exploration
- As a player, I can move through isometric rooms and understand where I can walk.
- As a player, I can inspect important objects and receive contextual interaction feedback.
- As a player, I can revisit areas and understand what changed between timelines.

### Time manipulation
- As a player, I can rewind supported objects to a previous valid state.
- As a player, I can accelerate supported processes.
- As a player, I can freeze supported objects.
- As a player, I can reveal echoes of past events.
- As a player, I can shift between supported timeline layers.

### Temporal echoes
- As a player, I can record a sequence of interactions.
- As a player, I can replay the sequence deterministically.
- As a player, I can reset or replace a recording without losing permanent progress.
- As a player, I can understand when an echo cannot interact with an object.

### Spatial puzzles
- As a player, I can rotate supported rooms.
- As a player, I can change defined doorway connections.
- As a player, I can reorient supported gravity.
- As a player, I can use spatial folds and timeline overlaps in later chapters.

### Narrative and progression
- As a player, I can read documents and review discovered memories.
- As a player, I can save and load progress.
- As a player, I can access hints when stuck.
- As a player, I can reach endings based on comprehensible discoveries and choices.

## 6. Functional requirements

Priority definitions: **P0** required for vertical slice; **P1** required for full game; **P2** optional polish.

| ID | Requirement | Priority |
|---|---|---|
| FR-001 | Isometric player movement with collision and interaction | P0 |
| FR-002 | Contextual interaction framework with stable object IDs | P0 |
| FR-003 | Room/chapter loading and transitions | P0 |
| FR-004 | Temporal object state model and rewind | P0 |
| FR-005 | Freeze and fast-forward for supported objects | P0 |
| FR-006 | Echo recording and deterministic playback | P0 |
| FR-007 | Puzzle state and reset framework | P0 |
| FR-008 | Save/load with versioned data | P0 |
| FR-009 | Dialogue, documents and memory fragment presentation | P0 |
| FR-010 | Tutorial and hint system | P0 |
| FR-011 | Timeline shifting | P1 |
| FR-012 | Spatial graph and room rotation | P0 for vertical slice prototype; P1 for complete implementation |
| FR-013 | Doorway reassignment and spatial folding | P1 |
| FR-014 | Gravity reorientation | P1 |
| FR-015 | Journal and clue tracking | P0 |
| FR-016 | Four endings and ending state tracking | P1 |
| FR-017 | Controller support and remapping | P0 |
| FR-018 | Accessibility settings | P0 |
| FR-019 | Audio mixing and ability feedback | P0 |
| FR-020 | Optional lore and memory fragments | P1 |

## 7. Non-functional requirements

- **Reliability:** No known critical progression blockers in a release candidate.
- **Determinism:** Echo playback and puzzle state transitions must be reproducible.
- **Maintainability:** Systems should be modular, documented and testable.
- **Performance:** Target stable 60 FPS; profile before optimizing.
- **Usability:** Puzzle-critical feedback must be readable and not color-only.
- **Persistence:** Save files must be versioned and resilient to missing optional fields.
- **Recoverability:** Puzzles must have reset/recovery paths; temporal energy must not cause permanent soft-locks.
- **Localization readiness:** UI and dialogue should use translatable text keys rather than hard-coded strings where practical.

## 8. Vertical slice scope — Chapter 1

The first complete milestone is a polished 30–45 minute experience in The Forgotten Station.

> **Scope decision SD-1 (`docs/ADR_LOG.md`):** Ch1 mechanics = Rewind, Freeze, Echo (1 at a time), Trace reveal, and one doorway-reassignment spatial foreshadow. Fast-Forward is a stretch goal for the slice. Time Shift, room rotation, gravity, folding and temporal energy are out of the slice. Controller remapping and accessibility settings ship at foundation fidelity.

Must include:
- One cohesive station environment with interconnected rooms.
- Isometric player movement, camera and interactions.
- Tutorialized pocket-watch introduction.
- At least one working rewind/freeze/fast-forward interaction, selected according to the implemented content.
- A first temporal echo puzzle.
- A small spatial puzzle introduction.
- Approximately 5 polished puzzles as minimum exit criteria; 8–12 is a stretch target.
- At least one meaningful NPC encounter or recorded character presence.
- One major narrative revelation.
- One cinematic sequence.
- Journal/document/memory presentation.
- Save/load.
- Audio, lighting, VFX and UI pass.
- A complete start-to-finish playable path with no critical blockers.

## 9. Full-game content targets

These are planning targets and may be adjusted after vertical-slice playtesting:
- 6 chapters.
- 30–40 main puzzles.
- 10–15 optional puzzles or puzzle variations.
- 4–6 major set-piece puzzles.
- 15–25 memory fragments.
- 4 endings, including one secret ending.
- Approximately 5–8 hours of main playtime.

## 10. Acceptance criteria

### Player and interaction
- Player movement is responsive and collision is reliable.
- Interactables are discoverable and have clear feedback.
- Interaction works consistently with keyboard/mouse and controller.

### Temporal system
- Supported objects expose explicit temporal state.
- Rewind restores only defined state fields.
- Freeze and fast-forward respect object capability declarations.
- Invalid operations provide feedback and do not corrupt state.
- Temporal energy cannot permanently block required progression.

### Echo system
- Recording captures timestamped supported events.
- Playback is deterministic across tested frame rates.
- Missing targets fail gracefully.
- Resetting an echo does not corrupt permanent puzzle progress.
- Tests cover start, stop, replay, reset and invalid target cases.

### Spatial system
- Logical graph state is the source of truth.
- Visual connections, collision, navigation and interaction anchors remain synchronized.
- Invalid graph configurations are rejected or safely resolved.
- Player cannot be trapped by a transformation without a recovery rule.

### Save/load
- Save data uses stable IDs and a schema version.
- No live Node references are serialized.
- Missing optional fields use safe defaults.
- A save can be loaded after a normal scene restart.
- Save/load is tested at key progression points.

### Puzzle quality
- Puzzle objective is communicated.
- Rules are discoverable.
- The solution is logically inferable.
- Feedback explains success and failure.
- Reset/hints prevent dead ends.
- At least one external playtest is performed before a puzzle is marked final.

## 11. UX requirements

- Avoid clutter; keep the pocket watch interface readable.
- Make current timeline and active ability obvious.
- Echo playback must communicate its timeline and target interactions.
- Hints should escalate from subtle nudge to explicit next action.
- The journal should distinguish observations, confirmed facts and unresolved theories where useful.
- Include pause, settings, save feedback and accessibility options.

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Temporal state becomes too complex | Explicit state schemas, stable IDs, unit tests |
| Echo playback desynchronizes | Timestamped event model, deterministic simulation tests |
| Spatial transformations break collision/navigation | Logical graph as source of truth; integration tests |
| Puzzle difficulty becomes unfair | Playtesting, hint ladder, clear feedback |
| Scope grows beyond solo production capacity | Vertical-slice gate; defer non-core features |
| AI agents produce conflicting code | Worktree/file ownership rules and lead review |
| Pixel art lacks consistency | Style guide, pixel-density rules, asset inventory |
| Save data breaks after changes | Versioned schema and migration tests |

## 13. Release gates

- **Gate A — Foundation:** Project imports, player moves, room loads, tests run.
- **Gate B — Core mechanics:** Temporal objects, echo prototype and spatial prototype pass tests.
- **Gate C — Vertical slice:** Chapter 1 playable start to finish and externally playtested.
- **Gate D — Content complete:** Six chapters and endings implemented.
- **Gate E — Beta:** Regression, performance, accessibility and save migration checks.
- **Gate F — Release candidate:** No known critical blockers; documentation and packaging complete.
