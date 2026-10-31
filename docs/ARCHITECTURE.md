# Technical Architecture — THE LAST FRAME

## 1. Architectural principles

- Prefer small, composable systems over a monolithic game manager.
- Use explicit data contracts and stable IDs.
- Keep puzzle logic independent from visual presentation.
- Make temporal and spatial simulation deterministic and testable.
- Use data-driven definitions for rooms, puzzles, dialogue and object capabilities.
- Do not serialize live scene-tree references.
- The logical world state is authoritative; rendering is a presentation of that state.

> **Accepted decisions:** see `docs/ADR_LOG.md`. Where this document and an accepted ADR differ, the ADR wins.

## 2. Suggested autoloads

> Superseded by ADR-011: autoloads are limited to `Settings`, `SaveService`, `SceneRouter`, `AudioService`; gameplay services live under a session-scoped `GameSession` node. The list below is kept for history.

Keep autoloads limited to truly global services:
- `GameManager`: global game state and high-level flow.
- `SceneManager`: scene transitions and loading.
- `SaveManager`: versioned save/load and migration.
- `AudioManager`: global audio buses and transitions.
- `SettingsManager`: settings and input preferences.
- `NarrativeManager`: chapter-level narrative flags and dialogue state.

Temporal and spatial systems may be autoload services only if they genuinely require global lifetime. Otherwise attach them to a world/session root.

## 3. Major systems

### PlayerController
Owns movement intent, animation state, interaction targeting and player-facing input. It must not contain puzzle-specific rules.

### InteractionSystem
Uses interfaces/base classes or groups with stable interaction IDs. Provides prompts and dispatches validated interaction requests.

### TemporalManager
Coordinates temporal operations and temporal object registration. It does not blindly snapshot the entire scene tree.

### TemporalObject
Each supported object defines:
- Stable ID.
- Supported abilities.
- Explicit serializable temporal state.
- Validation rules.
- Restore/apply methods.
- Optional temporal energy cost metadata.

### TemporalEcho
Records supported events with timestamps and stable target IDs. Playback dispatches deterministic events through the same validated interaction contract.

### TimelineManager
Tracks active timeline layer and resolves object visibility/interactivity for Past, Present and Fractured states.

### SpatialGraph
Represents rooms as nodes and doorways/connections as graph edges. Transformations update graph data first; presentation systems then update visuals, collision, navigation and anchors.

### PuzzleManager
Loads puzzle definitions, tracks puzzle state, validates completion and exposes reset/hint functionality. Puzzle content should be data-driven.

### Chapter/Room Manager
Owns room loading, transitions, checkpoint state and chapter progression.

### Narrative System
Handles dialogue, documents, memory fragments, narrative flags and ending prerequisites.

### SaveManager
Serializes stable IDs and plain data structures into a versioned schema. No live Node references or raw scene objects.

### UI/Audio/VFX
Presentation systems subscribe to events and display state. They must not become authoritative gameplay logic.

## 4. Temporal state model

Use explicit per-object state dictionaries or typed Resources. Example conceptual schema:

```gdscript
{
    "object_id": "station_gate_01",
    "schema_version": 1,
    "state": {
        "is_open": false,
        "motor_phase": 0.25,
        "is_frozen": false
    }
}
```

Do not serialize every property on every Node. Define which fields are rewindable and which are permanent. Separate:
- Reversible puzzle state.
- Persistent progression state.
- Presentation-only state.
- Derived state that can be recalculated.

Rewind must restore only fields declared by the object. Permanent progression flags should not accidentally roll back.

## 5. Echo event model

Prefer events such as:
- `interact(target_id, interaction_id, relative_time)`
- `enter_trigger(trigger_id, relative_time)`
- `activate_switch(target_id, value, relative_time)`

Use a monotonic recording clock and normalized event times. Playback should resolve stable IDs at runtime, validate target state and dispatch through the standard interaction API. Define deterministic behavior for events that cannot be applied.

Avoid recording raw per-frame transforms unless a specific set-piece requires it and its cost/behavior is explicitly bounded.

## 6. Spatial graph model

Conceptual structures:
- `RoomNode`: room ID, timeline, orientation, gravity direction, doorway anchors.
- `DoorwayEdge`: source room/door, destination room/door, connection state.
- `SpatialTransform`: operation type and validated parameters.

A room rotation updates logical orientation. A connection change updates graph edges. Systems derive:
- Rendered room orientation.
- Collision arrangement.
- Navigation connectivity.
- Interaction anchor transforms.
- Camera framing.
- Player relocation or safe landing.

Use validation to prevent duplicate/invalid connections and inaccessible states unless intentionally designed.

## 7. Data-driven content

Use Godot Resources or structured data for:
- Puzzle definitions.
- Room metadata.
- Chapter progression.
- Character definitions.
- Dialogue.
- Interactable capabilities.
- Timeline variants.
- Memory fragments.

Avoid hard-coding every puzzle into a single script. Scripts implement reusable rules; data defines instances and parameters.

## 8. Save format

- Include `save_version`.
- Store stable IDs and primitive/serializable values.
- Store chapter, checkpoint, puzzle flags, narrative flags, collected fragments and settings as appropriate.
- Never store live Node references.
- Add migration functions when schema changes.
- Missing optional fields must have defaults.
- Validate data before applying it to the active world.

## 9. Testing strategy

- Unit tests: temporal state, event ordering, graph validation, puzzle condition evaluation, save serialization.
- Integration tests: echo activates switch; timeline shift changes object availability; spatial transform updates navigation/collision.
- Gameplay tests: complete Chapter 1 from fresh save; save/load at checkpoints; reset failed puzzle.
- Regression tests: rerun after changes to shared systems.

## 10. Performance and rendering

Profile before optimizing. Use atlases and reusable tilesets where practical. Avoid excessive unique lights and expensive full-screen effects. Use layered 2D lighting and shader effects carefully. Maintain a target internal resolution/pixel density and validate integer scaling. Keep visual effects optional/reducible for accessibility.

## 11. Architecture decision record

Recorded in `docs/ADR_LOG.md`.

Any major architecture change must be recorded with:
- Decision ID and date.
- Context/problem.
- Options considered.
- Chosen option and rationale.
- Consequences/trade-offs.
- Systems and documents affected.
