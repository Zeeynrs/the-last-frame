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
  - Optional `journal` (array of `{key, category}`) and `hints` (`{puzzle_id: level}`) sections (TLF-022).
  - `SaveService` is implemented in `scripts/save/save_service.gd` (a Node). Its **autoload registration** in `project.godot` belongs to Flash (single owner) in TLF-018.

## ADR-011 — Global vs session services
- **Date / status:** 2026-10-31 · Accepted (supersedes the autoload list in ARCHITECTURE §2)
- **Decision:**
  - Autoloads (only these 4): `Settings`, `SaveService`, `SceneRouter`, `AudioService`.
  - Everything else is a child of a `GameSession` node at the root of gameplay scenes: `SimClock`, `IdRegistry`, `InteractionService`, `TemporalService`, `EchoService`, `PuzzleService`, `SpatialGraph` holder, `NarrativeState`.
  - Gameplay nodes find the session with `get_tree().get_first_node_in_group(&"game_session")`.
- **Consequences:** Tests instantiate a fresh `GameSession` per case. No hidden global gameplay state.
- **Implementation note 2026-10-31 (TLF-027):** Godot 4.7.2 refuses a `class_name` equal to an autoload name ("Class … hides an autoload singleton"). Therefore the **class is `SaveStore`** (`scripts/save/save_service.gd`) and the **autoload is `SaveService`**. `RoomRouter` adopts `/root/SaveService` when registered and owns a `SaveStore` only as a fallback. Tests inject their own `SaveStore` so they never touch the real save root. Rule for future autoloads: the autoload name must not equal any `class_name`.
- **Amendment 2026-10-31 (ISSUE-026, TLF-036):** Headless runs never touch the player's real data. When `DisplayServer.get_name() == "headless"` (test runner, `validate.ps1`, ad-hoc `-s` probes), `SaveStore.DEFAULT_ROOT` resolves to `user://headless/saves` and `Settings.DEFAULT_SETTINGS_PATH` to `user://headless/settings.cfg`. The only override is the env var `TLF_ALLOW_REAL_USER_DATA=1`. An explicitly assigned `save_root`/`settings_path` still wins (existing tests keep their own roots). Reason: ad-hoc headless probes wrote `user://saves/slot_0.json` despite the ISSUE-016/022 test rule; a convention isn't enough, so the guard sits in the code. The shipped game never runs headless, so player behaviour is unchanged.
- **Amendment 2026-10-31 (TLF-037):** `SceneRouter` is implemented as the 4th autoload for menu ↔ chapter changes: `start_chapter(scene_path, restore_slot := -1)`, plus `return_to_title()`. Pending restore state lives in `SceneRouter`, never in a gameplay global. `run/main_scene` stays `Boot.tscn`, which routes to the title screen.

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
- **Amendment 2026-10-31 (TLF-022):**
  - `PuzzleDef` (`puzzle_id`, `room_id`, `title_key`, 3 `hint_keys`) and `DocumentDef` (`document_id`, kind, title/body keys, optional flag/fragment/journal entry + category) are implemented.
  - Ch1 PuzzleDefs (`data/puzzles/ch01/*.tres`) and `localization/ch01_puzzles.csv` are **generated from the merged specs by a script**: text is copied verbatim, never retyped. Re-run it when a spec changes, and don't hand-edit the generated files.
  - Key scheme: `PZ00N_TITLE`, `PZ00N_HINT_{1..3}`; journal entries `JRN_…`; documents `DOC_…`.
- **Amendment 2026-10-31 (TLF-024 duplicate resolution, user-approved via tlf-lead):**
  - `main`'s `narrative/ch01/CH01_TEXT.md` is the baseline. The second TLF-024 (`eecb822`, design worktree) is **not merged**; its improvements are ported into main's file **keeping main's key names**, and its `narrative/ch01/ch01_text.csv` is dropped (the CSV is generated by `tools/content/gen_ch01_text.py`).
  - **Speaker labels:** new prefix `SPK_*`. For all of Ch1, `SPK_OPERATOR = "VOICE"` (identity hidden).
  - **Multi-page documents:** `DOC_*_BODY_1..N`. A `page_keys` field on `DocumentDef` is a possible Opus follow-up once the document UI is built.
  - The clock line stays `EL_CLOCK_2359`. `UI_FB_*` is reserved for `InteractionResult` reasons; object-specific feedback uses `PZ00N_FB_*`.
  - Proposed object IDs `ch01.security_crossing.pa_speaker`, `ch01.signal_control.intercom` and journal key `JRN_CH1_OPERATOR_WARNING` are **pending Lead approval** in the review of the port commit.
  - **Player-facing text is ASCII-only** while the UI font (TLF Pixel Mono) covers ASCII 32-126 (tested for `ch01_text.csv` and `ch01_puzzles.csv`).
  - Generators live in `tools/content/` (`gen_ch01_puzzle_data.py`, `gen_ch01_text.py`). Their markdown inputs are the source of truth: re-run them, don't edit generated files.
  - CSV translations are imported by Godot into `*.translation` files. ~~Derived and git-ignored~~ **Corrected 2026-10-31: the generated `*.translation` files are committed.** They're registered in `project.godot`, and on a fresh clone Godot loads them *before* the import creates them, which produced startup `ERROR`s and failed validation (reproduced by the Lead on a `git archive`). Staleness against the CSV is caught by the round-trip tests (`test_hint_service`, `test_ch01_text`). Registering them in `project.godot` (internationalization/locale/translations) is Flash's job (single owner).

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
- **Implementation notes 2026-10-31 (TLF-023):**
  - Puzzle objects extend `PuzzleObject` (`puzzle_id`, `safe_anchor_id`). It registers as a member and latches on solve, on a reset after solving, and in `_ready` when the puzzle is already SOLVED (restored saves).
  - Collision for passages is a child **`Blocker`** (StaticBody2D) whose shapes are toggled by `set_passage_blocked()`.
  - Safety moves go through `SpatialService.request_relocation()`, which the room router executes.
  - Timed windows that echoes can trigger use **absolute ticks**, so an echo's pull (inside a tick signal) and a player's pull last exactly the same number of ticks.

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
- **Amendment 2026-11-05 (user directive: team update + Argon fallback protocol):**
  - **Team:**
    - **Claude Opus 5.5:** Lead Architect and Senior Programmer. The Lead session does review, integration on `main`, docs and delegation; the Opus implementation agent does core systems in `wt-opus-core`. Final technical and integration authority.
    - **Gemini 3.8 Flash High:** feature implementation (gameplay features, puzzles in scenes, UI), bug fixing, testing and regression testing, performance, technical docs. Follows the Opus contracts.
    - **GPT-6.1 Sol:** **Art Director**, with visual direction authority: style, palette, light, composition, character/environment direction, cinematic identity. Owns `design/art/ART_BIBLE.md` and the visual review of every art delivery. It is also the **full Argon fallback** (below).
    - **Gemini 4 Argon:** **primary creative asset specialist**, available again (RISK-019 resolved). Original scope: narrative, puzzle and level specs (`design/ch01/**`, `narrative/**`), `.pxo` sources (`assets/source/**`), runtime exports, the art generators (`tools/art/gen/**`), `design/art/ASSET_METADATA.md`, placement sheet and mockups. It follows Sol's visual direction.
    - **Claude Sonnet 5.5:** **excluded**. It gets no tasks, no fallback role and no workflows. Its merged work (TLF-039/042/044/045/047/053) stays. Branch `adityadaffa522/tlf-art-batch2` is history.
  - **Single writer:** at any time exactly one **active asset specialist** (Argon, or Sol in fallback) writes `assets/source/**`, art exports, `tools/art/gen/**` and `design/ch01/**` (`narrative/**` moved to the Lead by ADR-022 D5). The task file names it. Sol edits those paths only while it is the active specialist.
  - **Fallback protocol (Argon unavailable: usage limit, quota, access or other problems):**
    1. Stop assigning to Argon at once.
    2. Sol takes over every unfinished Argon task. Its base is Argon's last **pushed** commit (unpushed work counts as lost, not as done). The task file's owner line and the board change to Sol.
    3. Don't redo what Argon finished.
    4. Never use Sonnet, and don't wait for Argon.
  - **Argon available again:** Argon is the primary specialist again for **new** tasks and for unfinished tasks that Sol hasn't started. Sol finishes what it has started and stays Art Director. Sol's assets are kept and are not reproduced.
  - **Authority split:** Sol decides visual questions (style, palette, readability as art). Opus decides technical ones (formats, scale/camera conventions per ADR-003/019, import, collision, IDs, tests, merges). Where they meet (e.g. a clue's readability vs. collision), Opus decides after hearing Sol. Creative-direction changes still go to the user.

## ADR-018 — Room routing inside a chapter (world memory)
- **Date / status:** 2026-10-31 · Accepted (implemented in TLF-021, `5fda100`)
- **Context:** Ch1 is 10 room scenes (TLF-005). `GameSession` services and the player must persist across rooms. Puzzle state in a room you've left must not reset when you come back. Doorway traversal is triggered from inside a node of the room that is about to be freed.
- **Options:** (a) one big scene with every room; (b) the `SceneRouter` autoload swaps whole scenes, including the session; (c) a `ChapterRoot` with a persistent session and player, plus a session-scoped `RoomRouter` that swaps only the room.
- **Decision:** (c).
  - `ChapterRoot.tscn` holds GameSession, RoomContainer, Player and RoomRouter, wired by node paths. The `SceneRouter` autoload (ADR-011) stays reserved for chapter/menu-level changes.
  - Traversals and relocations are **queued** and run by `process_pending()` each physics frame, never inside the presenter callback.
  - A same-room destination repositions the player without a reload. Placement uses the destination presenter's `Spawn` child, or a `SafeAnchor`.
  - After every placement there's a 12-tick arrival grace during which doorway traversal is ignored.
  - **World memory:** unloading a room caches each temporal object's `export_history()` by `object_id`, and it's restored on return. Autosaves merge the cache. `restore_from_save` parks the state of rooms that aren't loaded in the cache.
  - An object's room is derived from its ADR-005 ID (`chNN.<room>.<object>`).
  - The echo is reset on every room change.
  - `CheckpointZone` (player-only) triggers the autosave to slot 0. The router owns a `SaveService` until the autoload is registered (TLF-018).
- **Consequences:** Room scenes must follow the ID scheme and give each doorway a `Spawn` marker placed **off** the presenter's shape. Non-temporal room state that must persist belongs in PuzzleService/NarrativeState or a TemporalComponent.

## ADR-019 — Chapter 1 art integration rules (art batch 2)
- **Date / status:** 2026-10-31 · Accepted (Lead decisions on TLF-039 open questions, `design/art/CH01_PLACEMENT_SHEET.md` §13)
- **Context:** Art batch 2 (TLF-039, merged `34d95be`) delivers the kit, puzzle props and a per-room placement sheet. The placement sheet raised layout and sorting questions that touch gameplay scenes.
- **Decision:**
  - **Sorting:** wall-mounted fixtures stay in `Wall_Fixtures` (`z_index = 7`). **Free-standing** objects (junction levers, mid-room breakers, consoles, benches, puzzle props on the floor) go into `YSort_Actors` (`z_index = 10`, Y-sorted by pivot), so Elias draws behind them when he is behind them (OQ-2). The art agent adds a bible appendix.
  - **Collision and gameplay positions are frozen:** art integration changes visuals only. Every `CollisionShape2D`/`CollisionPolygon2D`, `TriggerZone`, doorway, spawn and puzzle-object position stays byte-identical, with two exceptions:
    - `ch01.signal_control.intercom` moves to its N-wall mount (OQ-4), under the condition that the TLF-033 layout tests and the RISK-018 negative test stay green and the intercom stays reachable (≤ 36 px from a walkable point).
    - The greybox `Clock` sprites (rooms 1, 2, 5, 6, 7, 9) move onto wall modules per placement sheet §0.6 (OQ-9). They are visuals; the `digital_clock_2359` interactables keep their positions unless the sheet names a new one, in which case the reach rule above applies.
  - **Railings:** rooms 1 and 5 ship without near-edge rails (they would hide the amber platform lip); railings only on interior trench edges (rooms 4, 6) and the niche grille (room 8) (OQ-7). Collision is unaffected.
  - **Puzzle visuals bind read-only:** sprite state comes from a presenter in `scripts/chapters/ch01/visuals/` that reads the object's public state (`capture_state()`, `is_frozen()`, `passage_changed`) every frame. No visual code in `scripts/puzzle/**`.
  - **Echo recorder pedestal (OQ-8):** not built. The implemented PZ-003 starts the echo from the pocket watch; the ROOM_GRAPH §5.3 entry is set dressing only and is deferred.
  - **Palette:** Elias may use palette index 03 (trouser highlight); it is in TLF-CH01-32, the bible appendix records it.
  - **Reproducibility:** art produced by scripts must be regenerable: generator scripts are committed under `tools/art/gen/` and a check reproduces the committed `.pxo`/PNG byte for byte.
- **Consequences:** Integration tasks guard collision geometry with a before/after hash test. ISSUE-012 (Elias walk) closes only after an in-motion check in Godot, not from stills.
- **Amendment 2026-11-01 (TLF-042 findings):**
  - **Surge capacitor:** "frozen" is a flag over `charge_state`, and the stabilised state (`bus_powered and is_frozen()`, `is_stabilized()`) is the PZ-004 success readout, so it must be visible. The single `_frozen` sprite is split into `_frozen_charged` and `_frozen_discharged` (TLF-044). Until then the presenter maps both to `_frozen`.
  - **Dispatch terminal:** `_active` is shown once `ch01.flag.ledger_2359_revealed` is set (the DocumentDef flag set on reading), `_idle` before.
  - **Counterweight gear:** file suffix `_frozen` maps to code `gear_state = locked`; no rename (the code is authoritative, the mapping lives in the placement sheet).
  - **Stalled transit car:** pivot at the footprint centre (64,52) instead of `(W/2, H-8)`, accepted for this large background piece (bible appendix).


## ADR-020 — Chapter 1 length: deepen the two-ability combo core, measure it
- **Date / status:** 2026-11-01 · Accepted (Lead, after user playtest #2)
- **Context:** Playtest #2 (F5, `36f54de`): no bugs; the user called combining two abilities "a perfect mechanic", but the chapter "feels very short". The beat sheet targets 30–45 min (estimate 38) with 5 puzzles; scripted perfect runs clear rooms 1–4 in ~9 s and 5–10 in ~16 s of game time. There is no measured first-time playtime yet.
- **Options:** (a) pad with walking/backtracking or text; (b) harder variants of the 5 existing puzzles; (c) more two-ability combo puzzles on the main path plus optional combo side puzzles with lore rewards, calibrated by measured playtime; (d) a new mechanic.
- **Decision:** (c), with (b) only where a second stage adds a *new* combo.
  - **Target:** measured first-time playtime 30–45 min. Main path ≥ 25 min, optional content ≥ 8 min on top. Sizing is recalibrated from TLF-048 telemetry and the user's reported time.
  - **Main path:** +3 combo puzzles (`CH1-PZ-006..008`), each needing two abilities in a combination the chapter has not used yet, e.g. Echo+Freeze, Trace+Rewind (Trace reveals which past state to restore), Echo or Rewind + doorway reassignment. Fast-Forward (SD-1 stretch) may appear in **at most one** puzzle, introduced late.
  - **Optional:** 3 side puzzles (`CH1-SP-01..03`), ≤ 4 min each, combo-based, each rewarding one Memory Fragment (the journal has 1 today) plus a readable. Never required for completion.
  - **Existing puzzles:** at most 2 second stages, only if they introduce a new combo. PZ-001..005 solutions and their tests stay valid.
  - **Placement:** reuse the 10 rooms where footprints allow; at most 2 new rooms (ROOM_GRAPH + generator). ADR-019 frozen collision applies to existing puzzle geometry; new content gets its own fingerprint entries. ADR-015 reach rules (36 px interact, 96 px watch) and the RISK-018 lesson (prove "needs ability X" with a real-input negative test) apply to every new puzzle.
  - **Not allowed:** new core mechanics beyond SD-1 (+ the FF stretch), difficulty through timing precision beyond the existing assist window, padding (forced backtracking, fetch quests).
  - **Content:** +4–6 readables and journal theories tied to the new puzzles and fragments (ASCII, CH01_TEXT.md → generator).
  - **Process:** concept doc first (TLF-047 phase 1, Lead and user approve), then full specs with given/when/then tests (phase 2), then implementation: Opus impl (puzzle logic + spec tests + real-input negative tests), Flash (rooms/scenes/wiring), design-art (props).
- **Consequences:** The vertical slice grows by ~6 puzzles; the beat sheet and ROOM_GRAPH get revised. Telemetry (TLF-048) becomes the yardstick for "long enough" instead of estimates.
- **Amendment 2026-11-01 (user direction after playtest #2):** the expansion is also a story and world expansion.
  - **Progressive abilities:** the pocket watch starts with **one** ability. The others unlock at story moments, one at a time; each new ability gets a short solo puzzle before it is combined. This creates the teach → combine curve that carries the chapter length. Build on the existing `PocketWatch.unlocked_abilities`; unlocks persist in the save. PZ-001..005 stay solvable with the abilities unlocked by the time the player reaches them (their specs may be re-sequenced, their solutions not weakened).
  - **NPCs in the world:** the station is populated by **commuters frozen at 23:59**, people who did not make the 23:54 evacuation. They are environmental storytelling: Trace reveals a short memory per person, some link to side puzzles and fragments. The design may propose 1–2 **interactive** NPCs (e.g. someone only partly caught by the freeze), consistent with the lore (evacuation 23:54, lock 23:59, the Operator stays a voice) and without pre-empting the Beat 09 revelation, which remains the only one.
  - **World building / environment:** each room gets a "story of the room" (what happened here at 23:54–23:59) expressed through dressing, signage, readables and frozen NPCs; art follows the design.
  - **Story:** the 10 core beats stay; new sub-beats are added around the new abilities, NPCs and puzzles. The user approves the concept before specs are written.
- **Amendment 2026-11-01 (measured length):** the user reports playtest #2 took **under 5 minutes** for the whole chapter (estimate 38 min, about 8× off). So each existing puzzle took well under a minute; the 3–6 min per-puzzle estimates in the beat sheet are not credible. Consequences:
  - **More puzzles alone cannot close the gap** (at the current depth it would take ~40). Depth per puzzle is the main lever: multi-step puzzles (≥ 3 dependent steps), information the player has to discover first (Trace clues, readables, NPC memories, sometimes from another room), more interacting objects including plausible wrong options, and small hubs where 2–3 sub-goals can be done in any order (no forced backtracking).
  - **Iteration target:** the next playtest must measure ≥ 15 min first-time (TLF-048 telemetry). 30–45 min remains the vertical-slice goal for the iteration after that, recalibrated from the telemetry.
  - **Per-puzzle bar:** every main-path combo puzzle is designed for ≥ 3 min first-time (stated per concept and checked against telemetry); solo ability puzzles ≥ 1.5 min.
  - The existing PZ-001..005 are the first candidates for deepening (second stages / more steps), still only with combos and without padding; this replaces the "at most 2 second stages" limit.
- **Amendment 2026-11-01 (TLF-047 phase 1 approved, `e038e45`):** `design/ch01/CH01_EXPANSION.md` is the approved concept. Decisions:
  - **User:** start ability **Trace**; unlock order Trace → Rewind → Freeze → Echo with a solo puzzle each. Frozen commuters are desaturated grey "statues" with a shimmer, 13 in Step 1 (23 total later). Beat 09 seeds: keep the controller's "Which terminal, the Atrium?", soften or cut the medic's "the man from the lab". The porter's "calls before the order" stays as a question. **2 new rooms in two steps:** Step 1 adds none; R11 Cable Gallery and R12 follow in Step 2. Step 1 gets its own playtest with TLF-048 telemetry before the rest is built.
  - **Lead:** Q-1 confirmed by code: nothing listens to `Interactable.traced`, so Trace shows nothing today. `TraceMemory` is the first thing built. Q-4: 1 stage + depth-only deepenings OK. Q-8: brute-force policy accepted (6 s lock-out, silent reset, never per-step feedback). Q-9: 3 hint keys per new or changed puzzle are mandatory, and every Trace memory adds a journal observation. Q-10: unlocked abilities are saved (save schema bump + migration: old saves unlock all four), and the HUD shows locked slots greyed. Q-11: PZ-002 gets a real-input negative test now; the fix is the additive route of §4 in Step 1.
  - **Step 1 scope** (target ≥ 15 min measured): `TraceMemory`, progressive unlocks, 13 commuters, solo puzzles SO-01/SO-02, PZ-006 "Last Ticket" (Trace+Rewind), deepened PZ-001..004, PZ-005 stage, sub-beats, readables and hints for these. Step 1b (R11 + PZ-007) and Step 2 are decided after the Step 1 playtest.
- **Amendment 2026-11-01 (TLF-047 phase 2 merged, `15ecf28`; Lead decisions on the open points):**
  - **PZ-002 fix (RISK-020 confirmed by TLF-049 `a28fe63`: solved 26 ticks after the Rewind without Freeze, assist off and on):** accepted as specified in `CH1-PZ-002.md` R1: a second `inner_shutter` on the same gear that can only be rewound while the gear is frozen (`requires_gear_frozen`, reason `&"unanchored"`). Completion moves to `exit_trigger_east_02` (12,4); the old zone stays, inert. A state rule, not a timing change, so the assist window can't weaken it. TLF-049's test stays on its branch until the fix is in the rooms and must then pass unchanged (plus TEST-PZ002-R03).
  - **SO-02:** one hatch (`hatch_01`, plate-linked + FREEZE), as specified. **Courier N-05** stands at tile (1,6) px (240,120) in the entry strip, so Rewind unlocks before the turnstile has to be rewound.
  - **Puzzle data generator:** `gen_ch01_puzzle_data.py` gets the patch in `design/ch01/expansion/gen_ch01_puzzle_data.patch` (key prefix `SO001`/`SO002`/`PZ006`). It is applied together with the tests that count defs/documents, in the Opus Step 1 logic task (TLF-054), not by design.
  - **TLF-050 deviation accepted:** an empty `GameSession.starting_abilities` means all four (old flow, tests); Chapter 1 sets `[trace]` when the Step 1 rooms are wired (TLF-055). `ABILITY_UNLOCKS.md` §4 `default_save() = []` is superseded by this.

## ADR-021 — Ability wheel (radial selection with locked slots)
- **Date / status:** 2026-11-01 · Accepted (user request with a sketch; Lead details)
- **Context:** With progressive unlocks (ADR-020 am.), cycling with `ability_next/prev` hides what exists and what is still locked. The user sketched a radial wheel around the watch face, opened with a key such as Z, with locked abilities shown as locked.
- **Decision:**
  - **New input action `ability_wheel`:** keyboard **Z**, controller **LT (axis 4)**. Hold to open, aim, release to select (radial standard). An accessibility setting `wheel_toggle_mode`: press to open, `confirm`/press again to select, `cancel` to close without change.
  - **Aim:** keyboard WASD/arrows (8 directions), mouse direction from the wheel centre, controller left **or** right stick (axes 2/3 are free). A dead zone keeps the current selection; release in the dead zone = no change.
  - **6 segments** around the pocket-watch face (as in the sketch), fixed positions in ADR-015 order: Trace, Rewind, Freeze, Echo, Fast-Forward, and one **unknown** slot (silhouette "?", always locked in Ch1, a tease for later chapters). Positions never shift when abilities unlock (muscle memory).
  - **Locked segments:** greyed with a lock glyph, not selectable; hovering shows "Locked" (text key), and releasing on them changes nothing and gives the `ability_locked` feedback. Unlocked: icon + name, the current selection highlighted. A newly unlocked ability pulses once (static with `reduced_effects`).
  - **Time:** the SimClock **pauses** while the wheel is open (like the document viewer), so choosing never costs puzzle time and needs no reflexes; the player is input-blocked through `Player.set_input_blocked`.
  - **No-colour readability:** every ability has a distinct icon shape (ART_BIBLE VFX language), the lock is a shape, not just grey.
  - `ability_next/prev` (D-pad, mouse wheel, 1/2) stay as quick cycling and skip locked abilities.
  - Unlock state comes from TLF-050 (`AbilityUnlocks`); the wheel only reads it.
- **Consequences:** A new UI scene (Flash), wheel art (design-art), one new input action (binding-conflict tests), one setting. Built after TLF-050.

## ADR-022 — Story canon v2.0 ("Revised Operator Mystery") and Chapter 1 safe plan
- **Date / status:** 2026-11-05 · Accepted (the owner approved every Lead recommendation in `docs/reviews/2026-11-05_STORY_BIBLE_V2_AUDIT.md` and `docs/CHAPTER1_SAFE_PLAN.md`)
- **Context:** The owner issued Story Bible v2.0 (`docs/STORY_BIBLE_AND_NARRATIVE_MASTER_PROMPT.md`) and a Chapter 1 safe enhancement directive (`docs/THE_LAST_FRAME_CHAPTER_1_SAFE_ENHANCEMENT_DIRECTIVE.md`) with concept references (`design/art/reference/ch01/`). The old canon said the Operator *is* a future Elias and that the game reveals it.
- **Decision:**
  - **Canon:** `docs/STORY_BIBLE.md` and its five companion documents (`CHARACTER_BIBLE`, `CHAPTER_BREAKDOWN`, `ENDING_DESIGN`, `OPERATOR_MYSTERY_GUIDELINES`, `NARRATIVE_DESIGN`). They are in English; the owner's Indonesian directive stays the source (D6).
  - **The Operator's identity is never confirmed.** Three interpretations stay open; Ending 3 is the strongest visual/audio hint. The Operator checklist (`OPERATOR_MYSTERY_GUIDELINES.md` §6) gates every narrative merge.
  - **Superseded:** "Operator = future Elias"; **Elias-0** (D4, dropped; "Level-0" survives only as a clearance level); the old ending texts (A New Beginning keeps his memory, 00:00; The Paradox = the loop sequence); "a future Elias caused the catastrophe to prevent Mira's death"; the old Archivist description.
  - **D1** Beat 09: the terminal knows Elias's hand, the user field is corrupted, and "Did I do this?" stays a question. Ch4 gives the answer.
  - **D2** Beat 10: the unidentified voice line "You are late." / "Again." (OP_B10_01/02); Mira's broadcast image is kept, silent; no location line.
  - **D3** The Operator is first seen at the far end of the **Arrival Platform**, after the watch pickup, checking a pocket watch, gone when approached. Ending 3 reuses this composition exactly.
  - **D5** Narrative canon and dialogue text belong to the **Lead (Opus)**: `docs/` story documents and `narrative/**`. This amends ADR-017 (2026-11-05). Argon keeps puzzle/level specs (`design/ch01/**`) and all visual assets; Flash wires dialogue and narrative triggers.
  - **A2** The map reference is a structure/mood reference. The built rooms and the street exit stay. Station Office / Power Room / Baggage Storage are candidates for the two Step 2 rooms. "Unfreeze time" is **not** canon.
  - **A3** Elias v3 (lab coat, red scarf, goggles) waits for Sol's direction note (TLF-061) and then the owner's decision.
    - **A3 resolved (2026-11-05, owner accepted the Lead's recommendation, which follows Sol's TLF-061 §C.1):** **Elias v2 is retained for Chapter 1.** v3 is deferred; replacing v2 would redraw all 80 frames (5 directions x (4 idle + 6 walk) plus mirrors) and shows the lab coat (an early ELYSIUM spoiler). No red scarf is added to Elias in Ch1. The Operator is built on separate Robe / Hood_Mask / Scarf / Hand_Watch layers (TLF-062) so the scarf can be kept or removed without redrawing; whether the scarf is in the shipped Ch1 export is decided at the TLF-062 merge on Sol's visual review, since Elias v2 has no scarf for it to echo. No Elias watch-check clip is made for Ch1. Reopen with the owner when Ch2 or later needs the scarf link. **Scarf decision recorded at the TLF-062 merge (2026-11-06):** the scarf is HIDDEN in the shipped Ch1 export (Sol APPROVE VISUAL on `0370e0c`); the `.pxo` keeps the populated, removable Scarf layer, so showing it later needs no redraw.
  - **A4** The Operator's look: hood + mask, Elias's pocket watch (no hourglass), Elias's gesture and scarf colour, the same temporal VFX, **no attack animations**.
  - **A1/A5:**
    - Step 1 continues.
    - P1 approved: environmental props from the references (TLF-063), the Operator motif + basic audio (TLF-064), and the character direction note (TLF-061).
    - **Audio source** (no owner preference given, the Lead's choice): SFX generated by a reproducible script, like the art generators. CC0 packs are allowed with a licence record in `ASSET_INVENTORY.md`.
  - **CH1-PZ-004** is titled *The Forgotten Sequence* (the Story Bible's Ch1 signature puzzle); its logic is unchanged.
- **Consequences:**
  - Old task files (TLF-001 audit, TLF-003) keep their historical text; `STORY_BIBLE.md` §5 lists what is superseded.
  - New tasks TLF-058 (sighting), TLF-059 (Beat 10 cinematic), TLF-060 (export + smoke test), TLF-061 (Sol, character direction), TLF-062 (Argon, Operator silhouette + city plate), TLF-063 (environmental props), TLF-064 (audio). TLF-056 gains save/load tests around The Forgotten Sequence.

## ADR-023 — Chapter 1 large rooms, free-form room shapes, follow camera (amends ADR-003)

- **Date / status:** 2026-11-07, accepted by the owner. Spec: `docs/superpowers/specs/2026-11-07-ch1-large-rooms-design.md`. Plan: `docs/superpowers/plans/2026-11-07-ch1-large-rooms.md`.
- **Context:** Every Chapter 1 room is a W×H rectangle between 6×6 and 16×14 tiles inside one fixed 640×360 screen (ADR-003). Rooms read as boxes and Elias (32×48) is large against them. Owner playtest feedback also reports object sprites facing the wrong way and drawing through Elias.
- **Decision (approach A, phased, Chapter 1 first):**
  - The internal canvas stays 640×360, integer-scaled. A `Camera2D` follows Elias with whole-pixel positions, clamped to the room's bounds. A room that fits one screen keeps a fixed camera.
  - Room shapes are data (`RoomShape`, a floor outline in tile coordinates) and may be L, T, dog-leg, cross or notched. Floor tiles, perimeter collision, wall segments and camera bounds are generated from it.
  - Rule R2: no tall wall stands in front of walkable floor on the south/east side; those faces are low elements (about 20 px at most), so Elias is never hidden. No cut-away system.
  - The ADR-003 "continuous opposite-side transition" convention is dropped. Doors may be on any straight edge and are paired explicitly (ADR-009). Room ids, door ids, checkpoint ids and safe-anchor ids do not change.
  - Main rooms grow roughly 1.6–2× per side (floor about 640–830 px wide); the final numbers are tuned on the pilot room (Arrival Platform). The vestibule niche stays small.
  - Puzzle specs stay authoritative: apertures at least 1.5 tiles (TLF-055 §G), reachable stand spots, no skippable puzzle. A re-laid-out room lands only with its real-input segment and negative tests green.
  - Dev saves made before the pilot may become invalid (ids stay, pixel positions change). The game is unreleased, accepted.
- **Consequences:** tasks TLF-065 (camera + RoomShape), TLF-066 (Sol audit of facing and overlap), TLF-067 (sort/pivot/facing fixes), TLF-068 (corner and low-partition art kit), TLF-069 (pilot room), then one task per remaining room. TLF-059, TLF-060 and TLF-064 are unaffected. The Step 1 playtest gate moves to after the pilot or after all rooms, decided after the pilot.

- **ADR-023 addendum (2026-11-07, from the TLF-065 review):** concave corners must follow rule R2b. An L is cut only on the south or east side, where the faces are low. A cut on the north or west side is allowed only if the floor hidden behind its inner corner (the room builder lists it as `hidden_floor_cells()` and exits 1) is made unwalkable. Rooms built from a shape get a generated perimeter polygon instead of the hand-tuned one, so every re-laid-out room rechecks stand spots and door triggers near its edges (landing criterion of TLF-069 and the room tasks).

- **ADR-023 addendum 2 (2026-11-07, from the TLF-071 review):** the room builder's `--door` option (leave the N/W wall module under an archway to the archway) is not used for the pilot (Arrival Platform has its only door on the E face). Sol reviews the first rebuilt room that has an N/W door before the option is relied on; an archway straddling two modules is reported by the builder, not cut. The builder's Python tests (`python -m unittest discover -s tools/content -p "test_*.py"`) run as a separate step from `tools/validate.ps1`; the Lead runs them at every merge that touches `tools/content/`.

- **ADR-023 addendum 3 (2026-11-07, owner decision after a visual reference):** the internal canvas becomes **960 x 540** (integer x2 to 1080p), replacing 640 x 360 (ADR-003). Sprites, art and the 2:1 dimetric camera angle are unchanged. Character height goes from 13% to about 9% of the screen. Consequences accepted by the owner: UI text appears about one third smaller on a 1080p screen (x2 instead of x3; a separate UI scale may follow); the nine rooms not yet rebuilt sit centred with dark margins until they are rebuilt larger (the camera centres a room smaller than the screen); the Beat 10 cinematic is letterboxed with a 0 to -320 pan on the 1280 px plate; the pilot room (30 x 18, about 768 x 368 px) fits one screen at 960 x 540, so scrolling appears with larger rooms. Order of work: TLF-069 (pilot) is built and merged at 640 x 360 first; TLF-072 (Opus) then changes the viewport and updates every test and baseline. Elevation levels and stairs (the reference's multi-level architecture) are a separate future project, ADR-024, after the pilot.

## ADR-025 — Multi-perspective rooms: a view mode per room (iso, side, topdown)

- **Date / status:** 2026-11-09, accepted by the owner. Spec: `docs/superpowers/specs/2026-11-09-multi-perspective-rooms-design.md`. ADR-024 stays reserved for elevation levels and stairs.
- **Context:** the owner wants the game to stop being isometric only, so that some stages or buildings can use another camera (oblique top-down, flat side view) and offer more puzzle variety. Reference images: an oblique top-down forest and a side-view crime-scene room with a portrait dialogue box.
- **Decision (approach A, a view mode per room, added step by step):**
  - A room declares `metadata/view_mode` (`iso` default, `side`, `topdown` later) next to `metadata/room_shape`; `RoomRouter` publishes `view_mode_changed(mode)`; `Player`, `RoomCamera`, `DepthSort` and the HUD read it.
  - Puzzles, the four abilities, dialogue, journal, save/load, Echo, Rewind and audio are shared by all modes. Chapter 1's isometric rooms, art and tests are unchanged.
  - `side`: left/right movement only, facing `e`/`w`, a separate `SpriteFrames` for Elias (profile idle, walk, interact; 32 x 48 cell, palette TLF-CH01-32), a 960 x 540 composition with letterbox bars, no `RoomShape`, camera fixed or horizontal-only.
  - The first pilot is the Beat 06 Mira departure shown as a **Trace memory scene in side view** (existing text keys and memory fragment `ch01.fragment.mira_departure`, no new text). Side-view puzzles are designed after the owner approves the pilot; `topdown` is decided after that.
- **Consequences:** tasks TLF-074 (view_mode plumbing and side movement/camera, Opus, after TLF-072), TLF-075 (side-view Elias sprites and background kit, Argon, Sol reviews, can start now), TLF-076 (pilot scene: Lead layout, Flash build, Opus and Sol review). The 960 x 540 canvas (ADR-023 addendum 3) is the composition size for side-view scenes.

- **ADR-023 addendum 4 (2026-11-10, TLF-072 delivered):** the logical canvas is now **960 x 540** (integer x2 at 1080p); this supersedes the 640 x 360 canvas stated in ADR-003 (the tile math of ADR-003 is unchanged). Rooms without `metadata/room_shape` keep a 640 x 360 fallback frame centred in the view with a dark margin (`#0A0D14`, palette index 00); the pilot fits one screen. Windows smaller than 1920 x 1080 render at x1 with black borders (still integer), which Sol judged too small to read comfortably: a UI/text-scale option is a separate follow-up task, not part of this decision. The Beat 10 cinematic is letterboxed (plate 1280 x 360 at y 90, pan 0 to -320) and now plays by itself to the end (an old stall after "You are late." was fixed).

## ADR-026 — Chapter 1 lighting: palette-indexed ramp shift (option C)

- **Date / status:** 2026-11-10, accepted by the Lead on the owner's instruction ("start lighting from now on", 2026-11-10). This authorization supersedes the "no lighting system" lines of ART_BIBLE Appendix D (D.2/D.10); the palette, readability and narrative rules of the art bible still apply. Inputs: Opus `docs/reviews/TLF-082_lighting_options.md` (`43e645f`, spike on `arrival_platform` and the side memory scene) and Sol `docs/reviews/TLF-082_art_direction.md` (`0326cbf`).
- **Context:** Chapter 1 reads evenly lit; Appendix D wants dark, cold, selectively lit rooms. The game uses one fixed 32-colour palette (TLF-CH01-32) and runs in iso and side view (ADR-025).
- **Options rejected:** (A) `CanvasModulate` + `PointLight2D`: 26 % of the frame leaves the palette, and quantizing back drifts material hues. (B) Authored overlay sprites: stipple breaks readable text, actors drawn above the overlay are never darkened, and every layout change needs new art.
- **Decision (option C):**
  - One `LightingPass` (a `CanvasLayer` at layer 1 with a full-screen palette shader) above the world and under every UI layer; the HUD moves from layer 1 to layer 2, so the HUD, target marker and wheel are never lit.
  - Each pixel's palette index moves `k = max(0, A - max lift)` steps down its own material ramp (lights never brighten above the authored art, overlapping lights do not add). 0 off-palette pixels by construction.
  - Per room: `metadata/lighting` (`RoomLighting`: `ambient_steps` A 0-3, `exempt_from`, `dither`, the Elias zone) plus at most 8 `RoomLight` marker nodes (radius x/y, inner/outer lift). A room without the metadata is unlit and looks exactly as today; lighting is added room by room from room 2 (PATTERN rule 11).
  - Defaults (Sol): `exempt_from = 25` (indices 25-31 never shift: clock core, watch, tactile accents, temporal VFX, UI cyan); `dither = false`; no bloom, halo, tint, additive flare or flicker. Index 24 is not globally exempt: the departure-board LED glyphs are protected by a local information region (or a lift-2 light confined to the board face), never by raising the threshold.
  - Per-area values (A; focal L inner/outer): arrival 2 (clock 2/1, one helper 1/0); concourse and hubs 2 (one focal 2/1 + one helper 1/0); waiting lounge 1; maintenance 3 (one cue 2/1, Elias's whole body in lift 2, fall back to A 2 if the stress test fails); security and signal 2; atrium 2 (clock 2/1); street exit 1; side memory 1. At most one dominant focal light per screenshot; the technical limit of 8 is not an artistic budget.
  - Pools stay on their receivers: no spill onto caps, cornices or the wall behind a floor pool. Where an ellipse crosses architecture, an authored receiver mask (data read by the pass, not an overlay) is part of that room's acceptance.
  - Settings: `lighting_enabled` (on by default; off hides the pass and restores today's look). `reduced_effects` keeps the static lighting and freezes any future animated light.
- **Gates:** headless tests (metadata ranges, at most 8 lights inside the room bounds, HUD layer above the pass, the setting hides the pass, the ramp table maps every index inside its ramp or to 00/01, router switches lighting iso→side→iso without leaks). Per lit room, a D.7 proof pack: windowed native shots at the spawn and focal points with lighting on and off, 0 off-palette pixels outside the HUD, greyscale readability of Elias and in-range targets, Sol visual approval. Before the first merge, the pass is measured on the owner's machine with the toggle as A/B; above 1 ms per frame the 32-entry loop is replaced by a 32³ index LUT.
- **Consequences:** TLF-083 (Opus): the pass, `RoomLighting`/`RoomLight`, router hook, setting, tests, and the first lit room `ch01.concourse_west` (after TLF-080 lands), Sol visual review. Further rooms get lighting as part of their rebuild task.

## ADR-027 — Chapter 1 shadows and depth: a shade map in the ADR-026 pass

- **Date / status:** 2026-11-11, accepted by the Lead; the floor-fill mood chosen by the owner ("fill, keep the focal"). Input: Opus `docs/reviews/TLF-084_shadow_options.md` (`2bc6983`, spike on lit Concourse West). Sol was offline; Sol reviews the first room proof when back (Fable 5.2 stand-in until then).
- **Context:** the owner wants lighting and shadows in every room for atmosphere and depth (2026-11-11). ADR-026 lights rooms but casts no shadows; bodies float and the open floor collapses to index 00 at A 2.
- **Decision (option C, with C′ as the fallback):**
  - A world-space shade map (one texel per world pixel, values 0..2) baked when a room is entered, plus one dynamic contact ellipse under Elias. The pass rule becomes `k = clamp(A − lift + shade, 0, 3)`.
  - Shapes come from the room automatically: AO strips from `RoomShape.wall_segments()` and divider/partition segments (0.5 / 0.3 tile wide, strength 1); contact ellipses from footprint colliders and actor-layer sprites (core 2, rim 1); cast quads from grounded sprites at least 28 px tall (strength 1).
  - Cast direction is the ART_BIBLE key, 315° (shadows fall screen down-right) in every room, so floor shadows agree with the shading painted into the sprites; a per-room override only on Sol's request.
  - Receivers: floor indices 00-05 only. Information regions and indices ≥ `exempt_from` never take shade. Elias's contact ellipse sits low enough that his body is not darkened (readability first).
  - **Floor fill (owner choice):** every lit room gets a fill (lift 1/1 on floor indices 00-05) so shadows and the floor read, **except around the focal and helper pools**, which keep their full contrast against the darker floor.
  - **Fill rule as built (TLF-084 Part 2, Lead 2026-11-11 after the Fable stand-in review `docs/reviews/TLF-084/TLF-084_8f7cb2d_FABLE_VISUAL.md`):** `fill_mode` ADD: room pools add the fill on floor receivers, so every pool stays one step brighter than the filled floor and no dark ring forms. CLEAR (fill removed within `fill_clear` radii of each pool) stays available per room but is not used: at A 2 it shrinks the focal to its core and turns the helper into a dark hole. The focal leads by size and its body light. **Round 2 (TLF-084 r2, Fable P2-1/P2-3/P3):** the rule is `k = clamp(max(A − lift, 0) + shade, 0, 3)` (the lift is capped at A before the shade is added, so shadows read inside pools). Receivers are floor indices 00-05 on the room's floor mask, baked with the shade map (iso floor polygon; side platform strip y 378..449); the fill is at most A − 1, so A ≤ 1 rooms get no fill. A blocker that opens or closes in the room rebakes the map.
  - `lighting_enabled` off still gives today's unlit frame, byte-identical; `reduced_effects` keeps static shadows.
- **Gates:** bake time measured at room entry on the owner's machine; above budget → bake offline in the room builder (C′: a file per room plus a staleness test). Tests fail when stubbed (receiver mask, info regions untouched, exempt indices, shade + lift order, setting off, map rebuilt on room change, no leaks). D.7 proof pack per lit room: lit / lit + shadows / unlit, greyscale, 0 off-palette pixels.
- **Consequences:** TLF-084 Part 2 (Opus) implements it and applies it to Concourse West first; every rebuilt room (TLF-085..092) gets lighting and shadows as part of its acceptance (PATTERN rule 11).
