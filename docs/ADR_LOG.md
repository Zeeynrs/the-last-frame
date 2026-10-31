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
- **Amendment 2026-10-31 (Orca naming):** Orca creates per-role workspace branches `adityadaffa522/tlf-lead`, `…/tlf-design-art`, `…/tlf-implementation-qa` (worktrees under the user's Orca workspace folder). These are accepted as the task branches. Rules:
  - One task at a time per role worktree.
  - The commit subject starts with the task ID (e.g. `feat(TLF-006): …`).
  - After Opus merges, the role starts its next task with `git switch -c tlf-<id>-<slug> origin/main` (or Orca creates a fresh workspace). Never reset a worktree that has unmerged work.
- **Amendment 2026-10-31 (incident):** Agents created branches and wrote files in the Lead's primary checkout, and a Lead commit landed on an agent branch. Rule: the primary checkout `D:\TheLastFrame\the-last-frame` is Lead-only. Agents stay inside their Orca worktree and its existing branch, and never create or switch branches. Duplicate remote branches `tlf-003-ch01-beat-sheet` and `tlf-006-project-skeleton` (same commits as the Orca branches) are removed only after integration.

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
- **Clarification 2026-10-31 (TLF-004 review):**
  - `trigger_enter`/`trigger_exit` return nothing and carry no reasons. Each trigger's handler decides per actor what happens; completion triggers simply ignore `echo.*` actors.
  - Pocket-watch abilities are requests with `interaction_id` `&"trace"`, `&"rewind"`, `&"freeze"`, `&"fast_forward"` (see ADR-015). An unsupported capability returns `&"unsupported"`.

## ADR-007 — Temporal objects and rewind history
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - A `TemporalComponent` child node gives its parent: `object_id`, `capabilities` (flags `REWIND | FREEZE | FAST_FORWARD`), `schema_version`, `state_fields: PackedStringArray`, plus parent callbacks `capture_state() -> Dictionary` and `apply_state(d: Dictionary)`.
  - History is a ring buffer (default 32) of `{tick, state}`. Entries are appended only when declared state changes, never per frame.
  - **Rewind** restores the previous history entry, one step per activation. **Freeze** sets `is_frozen` (state-changing interactions return `&"frozen"`, process updates halt). **Fast-Forward** calls `advance(ticks)` on the parent.
  - Permanent progression (puzzle solved, story flags) lives in `PuzzleService`/`NarrativeState`, never in `state_fields`, so it can't be rewound.
  - An unsupported ability returns `&"unsupported"` with feedback, and state is unchanged.
- **Consequences:** Objects opt in explicitly. No whole-scene snapshots.
- **Amendment 2026-10-31 (authored pre-history):** Many Ch1 puzzles rewind objects to states from before the player arrived (TLF-003 Beats 02, 04, 07). `TemporalComponent` therefore exposes `@export var initial_history: Array[Dictionary]` (oldest first, each a full `state_fields` dict). On `_ready` these entries seed the ring buffer with negative ticks (`-N … -1`), ahead of the current state at tick 0. Rewind walks through them like any other entry. An object with an empty buffer returns `&"no_history"`. Save data stores the buffer cursor so a reload doesn't restore a consumed pre-history.
- **Amendment 2 2026-10-31 (history commit semantics, freeze toggle):**
  - History is a list of full snapshots plus a `cursor` (index of the snapshot the object currently embodies). At start-up: `initial_history` entries, then the tick-0 state, with `cursor` on the last entry.
  - **Commit:** the parent calls `commit_history()` only on a **discrete transition** (e.g. `closed → raised`). Per-tick counters (`hold_ticks`, `decay_ticks`, `engage_ticks`) are captured inside snapshots, but changing them never commits by itself. A commit drops every entry after `cursor`, appends the new snapshot and moves `cursor` to it. The ring capacity (32) evicts the oldest entry.
  - **Rewind:** if `cursor == 0` → `&"no_history"`; else `cursor -= 1` and apply that snapshot, counters included (so a rewound shutter comes back with `hold_ticks = 180`).
  - **Freeze is a toggle** owned by the component (`is_frozen`, never part of `state_fields` or snapshots). Freeze on an unfrozen object freezes it; Freeze on a frozen object unfreezes it. While frozen, the parent's tick logic is skipped and state-changing requests (`use`, `rewind`) return `&"frozen"`. Cross-object rules (e.g. a frozen gear blocking the shutter) are the parent's `can_interact` logic.
  - Worked check: PZ-001 `[open(-1), collapsed(0)]` → rewind → open → rewind → `no_history` ✓. PZ-002 `[raised180, closed]` → rewind → raised (no commits while counting) → commit closed (drops nothing after cursor, appends) → rewind → raised180 ✓ (TEST-PZ002-05).

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
- **Amendment 2026-10-31 (TLF-004 review):**
  - The logic track records only `interact` events whose `interaction_id` is **not** a pocket-watch ability, plus `trigger_enter`/`trigger_exit`. Echoes never replay `trace`/`rewind`/`freeze`/`fast_forward` (an echo has no pocket watch).
  - When recording starts, every trigger the player already occupies is seeded as a `trigger_enter` at `rel_tick 0`.
  - The ghost spawns at the player's position at recording start. A room transition or reaching 1200 ticks stops the recording automatically.
  - Playback dispatches as actor `&"echo.0"` through `InteractionService`. Failures emit `echo_event_failed(tick, target_id, reason)`.
- **Implementation notes 2026-10-31 (TLF-016):**
  - `rel_tick 0` events dispatch at the moment `start_playback()` is called; later events dispatch on their tick.
  - After the last event and the recorded length, the state becomes `HOLDING` (final occupancy kept). Restarting playback first releases the echo's occupancy.
  - Occupancy uses one code path: physical bodies and the echo both go through `InteractionService.trigger_enter/exit`, which calls the trigger's `on_trigger_enter/exit`.
  - `TriggerZone.accepts_echoes = false` implements the ADR-016 rule that completion triggers are player-only.

## ADR-009 — Spatial graph
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - `SpatialGraph` is a `RefCounted` holding pure data: `RoomNode{id, orientation, doorways}` and `DoorwayEdge{from_room, from_door, to_room, to_door}`.
  - `apply(transform) -> Result`: validate (no duplicate or dangling edges, critical path reachable) → commit → emit `changed`. On failure, nothing changes.
  - Presenters (door visuals, collision, navigation, interaction anchors, camera) rebuild from the graph on `changed`. A player in an affected room is moved to a safe anchor.
  - **Ch1 supports doorway reassignment only.** Room rotation arrives with Ch3 under a follow-up ADR.
  - **Clarification 2026-10-31:** Doorway IDs are room-local keys. A doorway is referenced as `(room_id, door_id)`, written `room_id:door_id` in docs, and is not registered in IdRegistry (doorway presenter nodes are). Every declared doorway must be paired exactly once. An edge may be flagged `traversable = false` (e.g. a grille); it's valid for pairing but ignored for reachability.
  - **Implementation notes 2026-10-31 (TLF-020):**
    - A transform is a list of new pairings. Every doorway it names is first detached from its current partner, so any partner left unpaired fails validation. This rejects PZ-005 I-1 and I-2 with no special cases.
    - A doorway may pair with itself (a dead-end loop).
    - Validation order: unknown, duplicate or dangling doorway → `invalid_graph`; then the registered critical room pairs → `critical_path_unreachable`.
    - **Relocation rule:** after a committed change, actors whose current room can't be reached from the session's anchor room (via traversable edges) get `relocate_requested(actor, anchor)`. Actors in rooms that are still reachable are not moved.
    - `DoorwayPresenter` only reports `traversed/blocked` from the graph; loading and positioning rooms is the room router's job (next task). Echoes never traverse doorways.
    - Saves carry `spatial = {pairs, actor_rooms}` (optional section); invalid imports leave the graph untouched.
- **Consequences:** Keeps the Ch1 spatial cost small while exercising the real architecture.

## ADR-010 — Save format
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - JSON at `user://saves/slot_<n>.json`, written to `*.tmp` then renamed (atomic).
  - Top level: `{save_version:1, chapter, checkpoint_id, puzzles:{id:state}, narrative_flags:{}, fragments:[], temporal:{id:state}, settings_ref}`.
  - Only IDs and primitives. Missing fields get defaults. Migrations live in `SaveService.MIGRATIONS[from_version]`.
  - A corrupt or unknown file is reported to the UI and never crashes the game.
  - Settings are stored separately in `user://settings.cfg` (ConfigFile).
- **Amendment 2026-10-31 (TLF-019 implementation):**
  - Encoding: `JSON.stringify(JSON.from_native(data))` / `JSON.to_native(JSON.parse_string(text))`. Verified on 4.7.2 that StringName/int/nested values round-trip exactly and that Objects encode as `null`, so live Nodes can't be serialized.
  - `temporal[object_id]` is `TemporalComponent.export_history()`: `{schema_version, cursor, entries[], is_frozen}`. A cursor alone is insufficient after runtime commits.
  - Writes go to `.tmp`, are verified by re-reading, then renamed. Reads return `{ok, reason, data}` with `reason ∈ {no_save, corrupt, unsupported_version, invalid}`. Migrations are `migrations[from_version] -> Callable`, and a gap in the chain is refused. Defaults are filled for missing fields; structure is validated before any write or apply. Unknown temporal IDs are skipped and reported, never fatal.
  - Optional `spatial` section (TLF-020): `SpatialService.export_state()`.
  - `SaveService` is implemented in `scripts/save/save_service.gd` (a Node). Its **autoload registration** in `project.godot` belongs to Flash (single owner) in TLF-018.

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
  - **Amendment 2026-10-31 (TLF-008):** the runner executes tests on the **first `_process` frame**, not in `_init()`. Measured: during `_init`/`_initialize` the root isn't inside the tree, so nodes added by tests never got `_ready()`. The runner injects `scene_tree`. New tests extend `res://tests/support/base_test.gd` (shared asserts plus a `make_session()` fixture).
  - **MCP tool policy:** the Lead uses Godot MCP read-only. Only the agent assigned as Godot owner for a task may use write tools (`create_scene`, `add_node`, `save_scene`, `update_project_uids`). Godot CLI is preferred for validation. Godot AI Workbench is not adopted for now (not installed).
- **Amendment 2026-10-31 (MCP server chosen):** The project's Godot MCP is **`@coding-solo/godot-mcp`**, pinned to **0.1.1** (`npx -y @coding-solo/godot-mcp@0.1.1`, Claude Code user scope). Godot AI Workbench is **not adopted**. Upgrades need a version bump recorded here.
  - Verified read-only: `get_godot_version`, `get_project_info`, `list_projects`, `get_uid` (see ISSUE-002).
  - Tool tiers:
    | Tier | Tools | Who |
    |---|---|---|
    | Read | `get_godot_version`, `get_project_info`, `list_projects`, `get_uid`, `get_debug_output` | anyone |
    | Run | `run_project`, `stop_project`, `launch_editor` | Godot owner; Lead for QA review |
    | Write | `create_scene`, `add_node`, `load_sprite`, `save_scene`, `export_mesh_library`, `update_project_uids` | assigned Godot owner only |
  - Gemini CLI (Flash) has **no** Godot MCP configured. That's deliberate: TLF-006 uses the Godot CLI. Add the same pinned entry to Gemini's `mcpServers` only when a task needs scene tooling.
  - The project-local `pixel-art` MCP (`pxcli-mcp`, exporting to `./assets/sprites`) is **not part of the pipeline**. It conflicts with ADR-001 folders and Argon's art ownership, so it must not be used.

## ADR-013 — Data-driven content format
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - Typed custom `Resource` scripts saved as `.tres` under `data/` for content definitions: `PuzzleDef`, `RoomDef`, `InteractableCaps`, `ChapterDef`, `MemoryFragmentDef`.
  - Player-facing text uses translation keys via `tr()` with CSV tables in `localization/`.
  - Argon specs (Markdown) are the design source. Flash transcribes them into `.tres`.

## ADR-014 — Ability naming
- **Date / status:** 2026-10-31 · **Accepted**: "Trace" (Argon's TLF-003 recommendation; "afterimage" and "imprint" allowed as prose synonyms only)
- **Context:** "Echo" names two different mechanics (GDD §8 vs §9).
- **Working decision:** "**Echo**" = record/replay of the player's own actions. The reveal-residual-traces ability uses the working name "**Trace**" until accepted. Code uses `echo` and `trace` identifiers accordingly.

## ADR-015 — Pocket-watch UX, ability targeting and Echo controls
- **Date / status:** 2026-10-31 · Accepted (tuning values provisional until playtest)
- **Context:** The TLF-004 specs need watch abilities to pick between adjacent objects (PZ-002 shutter/gear, PZ-001 gate/pillar), and Echo needs record/stop/play/reset affordances. Neither was defined, and the input map had no reset action.
- **Options:** (a) aim with a cursor or right stick; (b) cycle targets with an extra button; (c) automatic nearest target with a capability preference.
- **Decision:** (c), plus one new action.
  - `ability_next`/`ability_prev` cycle the unlocked abilities in the order Trace → Rewind → Freeze → Echo (→ Fast-Forward if unlocked). `watch` activates the selected ability.
  - **Targeting (Trace/Rewind/Freeze/Fast-Forward):** candidates are Interactables within the watch radius (default 96 px, larger than the 36 px interact radius). If any candidate supports the selected ability, pick the nearest of those; otherwise pick the nearest overall (so `unsupported` feedback stays teachable). Ties use the TLF-007 rule (smallest `object_id`). The current watch target is always highlighted, with an ability icon over it, whenever an ability other than Echo is selected.
  - **Echo** (no target) is a state machine driven by `watch`:
    - `IDLE → RECORDING → READY → PLAYING`
    - pressing `watch` while PLAYING or holding restarts playback
    - new action **`echo_reset`** (R key, joypad Y / button 3) clears the echo from any state (ADR-008 reset semantics)
    - to record again, reset first
    - the HUD shows the state, elapsed and max ticks, and an icon for each state
  - Abilities resolve instantly. There's no slow-motion or time scaling.
- **Consequences:** Flash adds `echo_reset` to the input map and to the binding-conflict tests in TLF-008. The PZ-002 timing becomes reasonable without an aiming skill. Level layouts must keep supported targets within 96 px of where the player naturally stands.

## ADR-016 — Puzzle completion and reset policy
- **Date / status:** 2026-10-31 · Accepted
- **Decision:**
  - Each puzzle has one `PuzzleService` state: `UNSOLVED | SOLVED`. `SOLVED` is permanent progression, saved under ADR-010 and never rewound.
  - Completion triggers accept only `&"player"`.
  - A reset anchor resets only its own puzzle's dynamic objects plus the active echo.
  - **After `SOLVED`, nothing may re-block the solved passage:** reset anchors, unfreezing, and echo resets all leave the route open. Optional objects may still reset.
  - Any reset or spatial change that would overlap the player with newly enabled collision first moves the player to the puzzle's declared safe anchor.

## ADR-017 — Team allocation and Opus implementation workflow
- **Date / status:** 2026-10-31 · Accepted (from the user's continuous-development master prompt)
- **Context:** The user's updated master prompt makes Opus an active core-systems programmer (~50%), with Flash on features/QA (~35%) and Argon on high-value creative batches (~15%). It also asks for continuous development without per-task approval, plus four status documents.
- **Decision:**
  - **Opus implements** the core systems: temporal (TemporalComponent/TemporalService), Echo, PuzzleService, SaveService, SpatialGraph, TimelineManager, and the session contracts.
  - **Flash** owns player feel, UI/HUD/menus, settings, input, camera, audio/VFX integration, scene setup and regression tests. Flash is the single owner of `project.godot`.
  - **Argon** owns design batches and `.pxo` sources.
  - TLF-008 is split: the temporal core goes to Opus; the pocket-watch controller and HUD become TLF-018 (Flash).
  - Opus works in its own worktree `D:\TheLastFrame\wt-opus-core` on branch `agent/opus-core`. Orca role branches stay as they are; the master prompt's suggested names are advisory, and existing branches are kept for compatibility. Opus's own work is self-verified (validate plus runtime probe) before merging to `main` with `--no-ff`.
  - Status docs: `PROJECT_STATUS.md`, `DEVELOPMENT_ROADMAP.md`, `TECHNICAL_DEBT.md`, `AGENT_HANDOFF.md`.
  - Unchanged: destructive or irreversible actions, external credentials and creative-direction changes still go to the user.
- **Consequences:** Shared contract files get exactly one owner per task (named in the task file). Opus may edit `scripts/interaction/interactable.gd` and `scripts/session/*` during TLF-008/016; Flash must not touch them until merged.

