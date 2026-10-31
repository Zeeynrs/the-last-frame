# Architecture Decision Log

Format per `ARCHITECTURE.md` §11. Status values: **Proposed**, **Accepted**, **Accepted (provisional)** (numbers may be tuned without a new ADR), **Superseded by ADR-xxx**.
Decisions accepted by Agent 1 (Lead) under human delegation on 2026-10-31. Any change requires a new or amended entry here plus updates to affected docs.

---

## SD-1 — Chapter 1 vertical-slice mechanic scope
- **Date / status:** 2026-10-31 · Accepted (provisional, revisit after TLF-003 review)
- **Context:** PRD §8 needs "at least one" of rewind/freeze/fast-forward, but FR-004/005 make all three P0. PRD wants a spatial puzzle in Ch1, while GDD §5 has Ch3 introduce spatial mechanics. The P0 list is large for one slice.
- **Options:** (a) everything P0 in Ch1; (b) minimal temporal-only slice; (c) core temporal + echo + one spatial foreshadow.
- **Decision:** (c).
  - **In:** Rewind, Freeze, Echo record/replay (1 echo at a time), Trace reveal (narrative clues), one spatial foreshadow puzzle using doorway reassignment (ADR-009).
  - **Stretch:** Fast-Forward in one puzzle.
  - **Out (P1):** Time Shift, room rotation, gravity, folding, overlap, multiple simultaneous echoes, temporal energy.
  - **Foundation-only in the slice:** controller remapping UI, accessibility menu (text size, subtitles, reduced effects, volume sliders) at minimal fidelity.
- **Consequences:** Ch1 has no temporal-energy soft-lock risk. FR-005 fast-forward drops to stretch for the slice. GDD §5 and PRD §8 annotated.
- **Affected:** PRD §6/§8, GDD §5, TLF-003/004/005/008.

## ADR-001 — Repository layout and ownership
- **Date / status:** 2026-10-31 · Accepted (implemented in commit `4297a5a`)
- **Context:** The planning pack was nested two folders deep inside `res://`. Prompts expect `docs/` at root.
- **Decision:** Repo root = Godot project.
  | Path | Owner |
  |---|---|
  | `docs/`, `README.md`, `agent_prompts/`, `orca_templates/` | Opus |
  | `design/`, `narrative/`, `assets/source/` (`.pxo`) | Argon |
  | `assets/{characters,environments,props,animations,vfx,ui}/` (exports) | Argon writes, Flash imports |
  | `scenes/`, `scripts/`, `tests/`, `data/`, `localization/`, `project.godot`, `*.import` | Flash |
  | `tools/` (shell helpers) | Flash writes, Opus approves |
  | `addons/` | Flash, only after an ADR + human approval |
- **Consequences:** README's `scripts/windows/` becomes `tools/`. Shared contracts are changed only through this log.

## ADR-002 — Git and worktree workflow
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - `main` is always importable. Nobody commits directly to `main` except Opus for docs/integration.
  - Task branches: `tlf-<id>-<slug>` (e.g. `tlf-006-project-skeleton`), one per task, cut from the latest `main`.
  - Orca worktrees: `tlf-lead`, `tlf-design-art`, `tlf-implementation-qa`.
  - Opus integrates with `git merge --no-ff` after diff review and test evidence. No force-push, no history rewrite on shared branches.
  - Milestone tags: `m0-base`, `m1-…`, `gate-a`, etc.
  - Commit messages: Conventional Commits prefixes (`feat:`, `fix:`, `docs:`, `chore:`, `test:`).
- **Consequences:** Agents push task branches only. Merges are serialized through Opus.

## ADR-003 — Rendering, resolution and pixel density
- **Date / status:** 2026-10-31 · Accepted (provisional numbers; final after TLF-010 target sheet)
- **Context:** `project.godot` used `canvas_items`/`expand` stretch with no nearest filter. That blurs and shimmers pixel art and contradicts the integer-scaling requirement.
- **Options:** Renderer Forward+ vs Compatibility. Internal resolution 640×360 vs 960×540 vs 480×270.
- **Decision:**
  - Renderer: keep **Forward+** (D3D12 on Windows, Vulkan on Linux) for 2D glow, HDR 2D and GPU particles. Compatibility is the documented fallback, re-tested at the performance gate.
  - Internal canvas **640×360**, `display/window/stretch/mode="viewport"`, `stretch/scale_mode="integer"`, `aspect="keep"`. Window 1920×1080 (×3).
  - `rendering/textures/canvas_textures/default_texture_filter = Nearest`; `rendering/2d/snap/snap_2d_transforms_to_pixel = true`.
  - Isometric 2:1 dimetric, tile footprint **32×16 px**. Character height ≈ **48 px**. Y-sorted `TileMapLayer`s.
  - Physics: 2D uses the default Godot Physics 2D. The existing Jolt 3D setting is unused and left untouched.
- **Consequences:** The UI is authored at 640×360 (a high-res UI layer can be added later via a separate CanvasLayer if text legibility requires it). Argon must use these metrics in TLF-010.
- **Affected:** `project.godot`, ART_PIPELINE, TLF-006, TLF-010.

## ADR-004 — Simulation clock and determinism
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - `physics/common/physics_ticks_per_second = 60`. A `SimClock` node (session-scoped, ADR-011) increments `tick: int` once per `_physics_process` while unpaused.
  - All temporal, echo and puzzle timestamps are integer ticks. Gameplay logic must not read `Time.get_ticks_*`, `delta` accumulation or frame counts.
  - Puzzle logic runs in physics ticks only. Rendering interpolates.
  - No unseeded randomness in puzzle logic; cosmetic randomness is allowed.
- **Consequences:** Echo playback is identical at 30/60/144 render FPS. Tests can step the clock manually.

## ADR-005 — Stable ID scheme
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - IDs are `StringName`s matching `^(ch\d\d|global)\.[a-z0-9_]+(\.[a-z0-9_]+)*$`, for example `ch01.platform.gate_01` or `global.pocket_watch`.
  - Declared on nodes as `@export var object_id: StringName`. Never derived from node path or name.
  - A session `IdRegistry` registers IDs on `_ready` and errors on empty, malformed or duplicate IDs.
  - Actor IDs: `player`, `echo.0` … `echo.N`.
- **Consequences:** Saves, echoes and puzzle definitions reference IDs only, so renaming nodes doesn't break saves.

## ADR-006 — Interaction contract
- **Date / status:** 2026-10-31 · Accepted
- **Decision:** Every state-changing interaction goes through one session service:
  ```gdscript
  InteractionService.request(actor_id: StringName, target_id: StringName,
      interaction_id: StringName, payload: Dictionary = {}) -> InteractionResult  # {ok: bool, reason: StringName}
  InteractionService.trigger_enter(actor_id, trigger_id) / trigger_exit(actor_id, trigger_id)
  signal interaction_applied(tick: int, actor_id, target_id, interaction_id, payload)
  ```
  - Targets implement `can_interact(actor_id, interaction_id, payload) -> StringName` (`&""` = allowed, otherwise a reason such as `&"frozen"`) and `interact(actor_id, interaction_id, payload) -> void`.
  - Interactions flagged `progression = true` (pickups, story flags) reject echo actors with `&"echo_forbidden"`.
- **Consequences:** The player and echoes share validation. The echo recorder just listens to `interaction_applied` and trigger events. The UI shows `reason` as feedback.

## ADR-007 — Temporal objects and rewind history
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - A `TemporalComponent` child node gives its parent: `object_id`, `capabilities` (flags `REWIND | FREEZE | FAST_FORWARD`), `schema_version`, `state_fields: PackedStringArray`, plus parent callbacks `capture_state() -> Dictionary` and `apply_state(d: Dictionary)`.
  - History is a ring buffer (default 32) of `{tick, state}`. Entries are appended only when declared state changes, never per frame.
  - **Rewind** restores the previous history entry, one step per activation. **Freeze** sets `is_frozen` (state-changing interactions return `&"frozen"`, process updates halt). **Fast-Forward** calls `advance(ticks)` on the parent.
  - Permanent progression (puzzle solved, story flags) lives in `PuzzleService`/`NarrativeState`, never in `state_fields`, so it can't be rewound.
  - An unsupported ability returns `&"unsupported"` with feedback, and state is unchanged.
- **Consequences:** Objects opt in explicitly. No whole-scene snapshots.

## ADR-008 — Echo recording model
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - **Logic track:** an ordered array of `[rel_tick, kind, target_id, interaction_id, payload]`, where `kind ∈ {interact, trigger_enter, trigger_exit}`. These are captured from ADR-006 signals during recording.
  - **Presentation track:** player position sampled every 6 ticks (10 Hz). The ghost interpolates it for visuals only, so logic never depends on ghost physics.
  - Playback runs once from the activation tick. The ghost then **remains at its final position and keeps its trigger occupancy** until the echo is reset or replaced. This is what lets an echo hold a pressure switch.
  - Ch1: max 1 echo, max recording length 1200 ticks (20 s). Both limits are shown in the UI.
  - Missing, disabled or invalid target: the event is skipped, `echo_event_failed(tick, target_id, reason)` is emitted, and the UI flashes feedback. Playback continues.
  - Reset/delete clears the echo and its occupancy (trigger_exit is dispatched). Permanent progress is never touched.
- **Consequences:** Resolves contradiction C5. Tests required: start, stop, replay, reset, invalid target, determinism across render FPS.

## ADR-009 — Spatial graph
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - `SpatialGraph` is a `RefCounted` holding pure data: `RoomNode{id, orientation, doorways}` and `DoorwayEdge{from_room, from_door, to_room, to_door}`.
  - `apply(transform) -> Result`: validate (no duplicate or dangling edges, critical path reachable) → commit → emit `changed`. On failure, nothing changes.
  - Presenters (door visuals, collision, navigation, interaction anchors, camera) rebuild from the graph on `changed`. A player in an affected room is moved to a safe anchor.
  - **Ch1 supports doorway reassignment only.** Room rotation arrives with Ch3 under a follow-up ADR.
- **Consequences:** Keeps the Ch1 spatial cost small while exercising the real architecture.

## ADR-010 — Save format
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - JSON at `user://saves/slot_<n>.json`, written to `*.tmp` then renamed (atomic).
  - Top level: `{save_version:1, chapter, checkpoint_id, puzzles:{id:state}, narrative_flags:{}, fragments:[], temporal:{id:state}, settings_ref}`.
  - Only IDs and primitives. Missing fields get defaults. Migrations live in `SaveService.MIGRATIONS[from_version]`.
  - A corrupt or unknown file is reported to the UI and never crashes the game.
  - Settings are stored separately in `user://settings.cfg` (ConfigFile).

## ADR-011 — Global vs session services
- **Date / status:** 2026-10-31 · Accepted (supersedes the autoload list in ARCHITECTURE §2)
- **Decision:**
  - Autoloads (only these 4): `Settings`, `SaveService`, `SceneRouter`, `AudioService`.
  - Everything else is a child of a `GameSession` node at the root of gameplay scenes: `SimClock`, `IdRegistry`, `InteractionService`, `TemporalService`, `EchoService`, `PuzzleService`, `SpatialGraph` holder, `NarrativeState`.
  - Gameplay nodes find the session with `get_tree().get_first_node_in_group(&"game_session")`.
- **Consequences:** Tests instantiate a fresh `GameSession` per case. No hidden global gameplay state.

## ADR-012 — Test framework and tool policy
- **Date / status:** 2026-10-31 · Accepted
- **Context:** GUT/GdUnit4 compatibility with Godot 4.7.2 is unverified, and installing addons needs approval.
- **Decision:**
  - Start with a **zero-dependency runner**: `tests/run_tests.gd` (`extends SceneTree`). It discovers `res://tests/**/test_*.gd`, runs methods prefixed `test_`, prints results and quits with exit code = number of failures.
  - Commands:
    - Import check: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --import`
    - Tests: `Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tests/run_tests.gd`
  - Adopting GdUnit4/GUT later needs a new ADR plus human approval for the install.
  - **MCP tool policy:** the Lead uses Godot MCP read-only. Only the agent assigned as Godot owner for a task may use write tools (`create_scene`, `add_node`, `save_scene`, `update_project_uids`). Godot CLI is preferred for validation. Godot AI Workbench is not adopted for now (not installed).

## ADR-013 — Data-driven content format
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - Typed custom `Resource` scripts saved as `.tres` under `data/` for content definitions: `PuzzleDef`, `RoomDef`, `InteractableCaps`, `ChapterDef`, `MemoryFragmentDef`.
  - Player-facing text uses translation keys via `tr()` with CSV tables in `localization/`.
  - Argon specs (Markdown) are the design source. Flash transcribes them into `.tres`.

## ADR-014 — Ability naming
- **Date / status:** 2026-10-31 · Proposed (awaiting Argon's TLF-003 naming proposal)
- **Context:** "Echo" names two different mechanics (GDD §8 vs §9).
- **Working decision:** "**Echo**" = record/replay of the player's own actions. The reveal-residual-traces ability uses the working name "**Trace**" until accepted. Code uses `echo` and `trace` identifiers accordingly.
