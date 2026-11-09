# Pilot side-view scene: Beat 06 Mira departure memory (TLF-076, ADR-025 V6)

Author: Lead, 2026-11-10. Status: READY once TLF-074 is merged. Art: TLF-075 (merged). New text: none.

## 1. What it is
A short **Trace memory** in flat side view. Elias traces the lounge bench, the world remembers a frozen moment: the same platform edge at 23:59, Mira standing still, a voice recorder cup on the floor. He walks left/right, looks at two things, traces Mira once, rewinds one small object once, then walks out the right end and is back in the Waiting Lounge. It proves: the view change, walking, camera, Trace, Rewind, save/load. It is not a puzzle and adds no story.

## 2. Entry and exit (main flow untouched)
* The first Trace on `ch01.waiting_lounge.trace_bench` behaves exactly as today (EL_B06_01, journal entry JRN_CH1_TWO_SILHOUETTES). The playthrough tests must not change.
* **Entry:** a second Trace on the bench, after that journal entry exists, loads the memory scene (the builder may use an Interactable state, not a new object id in the main graph). Exact mechanism: Opus/Flash, smallest change; if it needs a new object in the lounge, it stays inside the lounge scene and is not part of the room graph.
* **Exit:** walking into the exit marker at the right end returns to the lounge at the bench stand spot, same camera, same ability state. Save inside the memory scene stores the memory room id plus the return target (TLF-074 save/load rule V7).

## 3. Scene (960 x 540 canvas, floor line y = 394, letterbox bars about 90 px)
Width **1440 px** (one and a half screens) so the horizontal-only camera is exercised. Background layers from TLF-075 (`ch01_env_side_bg_far_wall_arches_idle`, `..._near_wall_pillars_idle`, `ch01_env_side_platform_floor_strip_idle`) repeat to cover 1440; their wrap seams were approved by Sol.

| Object | x (px) | Asset | Role |
|---|---|---|---|
| Elias start | 120 (facing e) | side sheet | spawn and checkpoint-free |
| platform pillar | 300 | `ch01_prop_side_platform_pillar_idle` | scenery, blocks nothing |
| station bench | 520 | `ch01_prop_side_station_bench_idle` | **look** target 1: existing key EL_B06_01 |
| voice recorder cup | 600 | `ch01_prop_side_voice_recorder_cup_idle` | **Rewind** target: it was knocked from the bench edge; Rewind returns it to the bench top at x 540. No text. |
| Mira (frozen, silhouette placeholder) | 780 | `ch01_prop_side_mira_memory_silhouette_idle` | **Trace** target once: existing keys JRN_CH1_TWO_SILHOUETTES (journal) and the fragment `ch01.fragment.mira_departure` text FRAG_MIRA_DEPARTURE_* if not already owned |
| luggage trolley | 1000 | `ch01_prop_side_luggage_trolley_idle` | scenery |
| clock 23:59 | 1180 | `ch01_prop_side_clock_2359_idle` | **look** target 2: existing key of the lounge clock (`digital_clock_2359`) |
| exit marker | 1380 | (invisible, 24 px wide) | returns to the lounge |

Interaction reach is 1-D: Elias within 24 px of the object on the floor line. Mira is a placeholder silhouette, not a final sprite (Sol's TLF-075 and ART_BIBLE C.5 limits). The Trace on Mira must not add her movement, dialogue or a present-day encounter.

## 4. Abilities in the scene
* **Trace** on Mira: once, works as in the lounge, then stays used for the visit.
* **Rewind** on the voice recorder cup: the cup returns to the bench top, short feedback with an existing key.
* **Freeze** and **Echo** are available but have no target; using them must not crash or soft-lock (Echo records 1-D positions on the floor line, TLF-074 rule). Refused uses show an existing reason key.

## 5. Camera
Horizontal-only follow, whole pixels, clamp to 0..1440. Elias is on screen centre-left while walking; the camera never shows outside the 1440 scene.

## 6. Tests (Flash writes, Opus reviews)
Real-input run: enter from the lounge, walk to each object, look x2, Trace once, Rewind once, exit and arrive at the lounge bench; save inside the scene and load it; each object reachable from both sides; Elias cannot leave 0..1440; mode switch iso -> side -> iso leaves no leaked nodes or signals; existing playthrough tests unchanged. Windowed screenshots at 960 x 540: start, bench, Mira, clock, exit.

## 7. Landing criteria
Full validate 0 failed, 0 SCRIPT ERROR; Opus approves reach, camera, save/load; Sol approves the composition against ART_BIBLE D.7 (shoot in the room's view mode) and the Mira placeholder; the owner plays it.
