# THE LAST FRAME — Game Design Document

**Version:** 1.1 (story sections aligned with Story Bible v2.0, ADR-022)  
**Status:** Production baseline  
**Engine:** Godot 4.x  
**Genre:** Isometric 2.5D psychological mystery / sci-fi puzzle adventure

## 1. High concept

In 2097, Elias wakes in an abandoned transit station called Elysium-09 with no memory of how he arrived. A damaged pocket watch allows him to manipulate time and perceive the traces of events that no longer exist. Beyond the station lies Elysium City, frozen at 23:59 by the ELYSIUM experiment. As Elias explores impossible spaces and reconstructs fragmented memories, he discovers that the catastrophe is tied to his own refusal to lose Mira, and that a figure called the Operator knows his journey too well. Who the Operator is, the game never answers. Story canon: `STORY_BIBLE.md` (ADR-022).

**Core hook:** The player does not simply manipulate time to solve puzzles; they use the recorded consequences of their own actions, alternate timelines and rearranged spaces to challenge what they believe happened.

## 2. Design pillars

1. **Time is a playable system.** Rewind, accelerate, freeze, reveal echoes and shift timelines must produce understandable, consistent consequences.
2. **Space is a puzzle.** Rooms, doorways, gravity and connections can change according to clear rules.
3. **The player's actions become part of the solution.** Temporal echoes let the player coordinate with a recorded version of themselves.
4. **Mystery through discovery.** The story is delivered through places, objects, dialogue, documents, recordings and carefully paced revelations.
5. **Fair complexity.** Puzzles can be mind-bending, but every solution must be logically inferable and testable.

## 3. Player experience and audience

The intended player enjoys atmospheric exploration, environmental storytelling, systems-driven puzzles and science-fiction mysteries. The experience should feel contemplative, eerie and emotionally grounded rather than action-heavy.

## 4. Narrative premise

ELYSIUM records past events, stores human consciousness and memory, and reconstructs events from temporal data; under some conditions it creates causal links between states of time. Its last experiment froze the city at 23:59. Elias believes he is investigating the disaster, but he is also tied to its cause. The Operator, who speaks through old devices and is glimpsed only as a silhouette, sometimes helps and sometimes blocks him; his identity is never confirmed (`OPERATOR_MYSTERY_GUIDELINES.md`). Mira is a consciousness reconstruction stored in ELYSIUM, revealed gradually. The player discovers that memories, identities and even the apparent order of events cannot be trusted. Full canon: `STORY_BIBLE.md`, `CHARACTER_BIBLE.md`.

### Main characters

- **Elias:** The playable protagonist. Amnesiac at the beginning; his identity and responsibility are central mysteries.
- **Mira:** Elias's research partner and the person he could not let go; a reason for the experiment, with her own will. Revealed in Ch5 as a consciousness reconstruction.
- **The Operator:** A voice on old devices and a hooded silhouette who helps and hinders Elias and knows things that haven't happened yet. **Never identified** (three interpretations stay open).
- **The Archivist:** Keeper of ELYSIUM's memory recordings; knows possible events, not which one happened; may hide truths.

### Narrative delivery

Use environmental storytelling, optional memory fragments, readable documents, audio logs, character encounters, short cinematic sequences and contradictions between timelines. Avoid long exposition dumps. Optional lore should deepen the mystery without being required to understand basic puzzle logic.

## 5. World and chapter structure

The city is frozen at 23:59. The recurring clock motif should appear in UI, environmental props, sound design and chapter transitions.

| Chapter | Name | Main location | Design purpose |
|---|---|---|---|
| 1 | The Forgotten Station | Abandoned underground station | Teach movement, interaction, first time powers and basic echo logic |
| 2 | The City That Remembers | Futuristic abandoned city | Introduce Mira, memory contradictions and broader timeline use |
| 3 | The Infinite Library | Impossible library (warm wood, gold, sunlight) | The Archivist; controllable Dual Elias; spatial-graph reading puzzles |
| 4 | Paradox Laboratory | ELYSIUM research facility | Reveal the experiment and the tragedy; causality puzzles; deeper Dual Elias |
| 5 | Beyond Reality | Fractured dimension | Combine overlapping timelines, spatial folding and repeated journeys |
| 6 | The Last Frame | Temporal core | Final synthesis puzzle, confrontation and ending choice |

Chapter 1 foreshadows spatial manipulation with a single doorway-reassignment puzzle; Chapter 3 remains the full introduction of room rotation and doorway graphs (SD-1, `ADR_LOG.md`).

Naming: the ability that reveals residual traces is called **Trace** to avoid collision with the recorded **Echo** system (ADR-014).

Target full-game duration: approximately 5–8 hours. Treat this as a pacing target, not a promise until playtesting.

## 6. Core gameplay loop

1. Enter a room or environment and observe its state.
2. Identify temporal, spatial and narrative clues.
3. Form a hypothesis about the room's rules.
4. Experiment with time abilities, timeline shifts and recorded echoes.
5. Reconfigure the environment or coordinate multiple states.
6. Execute the solution.
7. Receive clear confirmation through animation, sound, environment change or narrative feedback.
8. Explore the newly accessible area and uncover story information.

## 7. Player controls and interaction

Provide keyboard/mouse and controller support. Suggested defaults:
- Move: WASD / left stick
- Interact: E / controller south face button
- Pocket watch: Q / controller shoulder button
- Ability selection: mouse wheel or number keys / D-pad
- Confirm: left mouse / controller south face button
- Cancel: Escape / controller east face button
- Journal: J / controller menu button

All controls must be remappable. Do not hard-code controls into puzzle logic.

## 8. Pocket watch — temporal abilities

The pocket watch is the central tool. Its abilities must have clear visual language, audio feedback and explicit target rules.

- **Rewind:** Restore selected supported environmental objects to a prior recorded state.
- **Fast Forward:** Accelerate supported processes such as plant growth, machinery cycles or aging.
- **Freeze:** Stop a supported object's temporal progression.
- **Trace:** Reveal residual traces of past events, actions or entities (named Trace by ADR-014; **Echo** is the record/replay system in §9).
- **Time Shift:** Move between supported timeline layers: Past, Present and Fractured.

Not every object must support every ability. Each interactable declares supported abilities and state data. Do not imply that the player can rewind the entire world if only selected objects are supported.

### Temporal energy

Temporal energy may constrain powerful actions, but it must never create grinding or permanent soft-locks. Provide recovery through natural exploration, puzzle checkpoints or predictable environmental sources. A player who experiments should not be punished into an unwinnable state.

## 9. Temporal echo system

The player can record a sequence of actions and replay it as an echo. Echoes can hold switches, activate mechanisms, block sensors or repeat a timed interaction while the player performs another task.

Implementation/design requirements:
- Prefer timestamped, event-based deterministic recording over raw frame-by-frame input recording.
- Record stable interaction identifiers and normalized event times.
- Echo playback must be deterministic at different frame rates.
- Define what happens if a referenced object is absent, disabled or in another timeline.
- Provide clear recording start/stop, playback, reset and delete affordances.
- Limit simultaneous echoes according to puzzle design; do not introduce arbitrary limits without communicating them.
- Echoes must not duplicate irreversible progression or grant unintended inventory rewards.

## 10. Spatial manipulation

Spatial puzzles use a logical spatial graph rather than arbitrary rotation of rendered scenes.

Supported concepts:
- **Room rotation:** Rotate room orientation in 90-degree increments.
- **Doorway connection:** Reassign which doorways connect to each other.
- **Gravity reorientation:** Change the direction of gravity in supported rooms or objects.
- **Spatial folding:** Make distant or separate locations connect through a defined fold.
- **Dimensional overlap:** Overlay compatible versions of a room from different timelines.

The logical room graph is authoritative. Rendering, collision, navigation, player position, interaction anchors and camera presentation must all derive from the same graph state. Never rotate only the visual scene while leaving collisions or navigation unchanged.

## 11. Puzzle design

Puzzle complexity should come from combining a small number of learnable rules, not from hidden arbitrary rules.

Puzzle framework:
1. Observation
2. Discovery
3. Hypothesis
4. Experimentation
5. Execution
6. Confirmation

Every major puzzle should include:
- A clear objective.
- Visible or discoverable rules.
- A safe way to experiment.
- Feedback for invalid actions.
- A hint path with escalating specificity.
- A deterministic solution unless explicitly designed otherwise.
- A recovery/reset path that avoids soft-locks.

### Puzzle categories

- Temporal sequence puzzles.
- Echo coordination puzzles.
- Timeline-state puzzles.
- Room rotation and doorway graph puzzles.
- Gravity and traversal puzzles.
- Spatial folding puzzles.
- Multi-system set pieces combining time, echoes and space.

See `PUZZLE_DESIGN.md` for templates and examples.

## 12. Endings

The final chapter supports four outcomes:

1. **A New Beginning:** Stop ELYSIUM; Elias keeps his memory of Mira and lets her go; the clock reaches 00:00.
2. **Eternal Stillness:** Keep ELYSIUM running; Elias becomes its keeper; 23:59 forever.
3. **The Paradox:** Merge with the core; a loop that strongly suggests, but never confirms, that Elias becomes the Operator.
4. **The Last Player (secret):** Find an unrecorded room and stop the system outside procedure; the clock reaches 00:01; "Someone is still watching."

Details, triggers and state: `ENDING_DESIGN.md`.

Endings should be earned through understandable narrative choices and/or optional discoveries. The secret ending must not require obscure pixel hunting.

## 13. Art direction

**Premium HD Cinematic Pixel Art** in an isometric 2.5D presentation.

Visual goals:
- High-detail pixel environments with deliberate pixel density.
- Strong composition, readable silhouettes and controlled color palettes.
- Layered backgrounds and atmospheric depth.
- Dynamic lighting, shadows, fog, rain, particles and temporal distortions.
- Restrained neon and sci-fi elements; avoid visual noise.
- Character sprites and animations that remain readable at gameplay scale.
- Pixel-aligned effects and consistent nearest-neighbor treatment where appropriate.

Broad reference points: Octopath Traveler for lighting and layered presentation; Eastward for environmental detail; The Last Night for selective neon atmosphere; Cocoon for spatial puzzle clarity; Outer Wilds, The Witness and Return of the Obra Dinn for discovery and inference. These are inspiration only—do not copy proprietary characters, art, levels or assets.

### Asset pipeline

- Establish a target internal resolution and pixel density before producing final assets.
- Build modular isometric tilesets and reusable environment kits.
- Create directional character sprites and animation sets.
- Use nearest-neighbor filtering or controlled pixel-art scaling.
- Test every asset at actual gameplay resolution.
- Blender may be used for blockout, perspective/layout reference, lighting or animation reference, but must not replace the intended pixel-art production style with finished 3D visuals.
- AI-generated images are concept references unless rebuilt into consistent, modular, game-ready assets.

## 14. Audio direction

Use a restrained cinematic soundscape: distant machinery, electrical hum, rain, clock ticks, spatially displaced ambience and sparse melodic motifs. Each temporal ability needs distinct but coherent audio feedback. Echoes may use filtered or phase-shifted versions of original sounds. Ensure puzzle-critical audio cues have visual equivalents.

## 15. UI and feedback

The UI should be diegetic where useful but never obscure interaction. Required screens:
- Main menu and settings.
- Pause menu.
- Pocket watch ability selector and energy indicator.
- Interaction prompt.
- Echo recording/playback controls.
- Journal with clues, documents and memory fragments.
- Hint interface.
- Save/load feedback.
- Ending summary.

Use clear icons, labels and consistent color language. Do not rely on color alone to communicate puzzle states.

## 16. Accessibility and comfort

- Remappable keyboard and controller controls.
- Adjustable text size and subtitle settings.
- Separate music, ambience and effects volume.
- Color-independent puzzle indicators.
- Optional hint system.
- Reduced screen shake, flashes and intense temporal effects.
- Adjustable input sensitivity where relevant.
- Pause during single-player gameplay, including most puzzle sequences.

## 17. Scope boundaries

Do not add multiplayer, combat, open-world systems, procedural narrative, survival crafting or large RPG progression to the initial game. Do not expand scope without updating the PRD, architecture and milestone plan.

## 18. Success criteria

The game succeeds when players:
- Understand the core rules through play rather than external explanation.
- Feel clever for solving puzzles and can explain why a solution works.
- Care about the mystery and its characters.
- Can recover from experimentation without restarting large sections.
- Experience a stable, polished and coherent Chapter 1 vertical slice.
