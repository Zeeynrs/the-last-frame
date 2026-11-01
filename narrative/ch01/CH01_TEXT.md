# Chapter 1 Text — "The Forgotten Station"

**Task:** TLF-024 (re-assigned from Argon to Opus on 2026-10-31: Argon hit its usage limit) · **Status:** first pass, open for Argon's narrative review when available
**Source of truth:** this file. `tools/content/gen_ch01_text.py` turns the two tables below into `localization/ch01_text.csv` and `data/documents/ch01/*.tres`. Don't hand-edit the generated files.

## Rules applied
- **ASCII only** (TLF Pixel Mono covers ASCII 32-126): no em dashes, curly quotes or ellipsis characters.
- Length: `OP_`/`EL_` lines ≤ 120 chars; `PZ00N_FB_` ≤ 80; document pages ≤ 6 lines × 48 chars (`<br>` = line break; one key per page).
- Canon (Lead review, TLF-003): exactly **one** revelation (Beat 09, self-implication); the loop is only an **ambiguous seed** (an unnumbered column of identical timestamps, no "exit", no count, no memory wipe); the Operator speaks only through **old devices** (call box, PA, wired intercom, payphone); **one** subtle phrase is shared by Elias and the Operator ("Time doesn't stop. It waits." in EL_B01_03 and OP_B03_03); no Archivist foreshadowing.
- Puzzle feedback text is from the specs, made ASCII and shortened where it exceeded 80 chars (listed under Deltas).

## Text table
| key | kind | speaker | beat | object_id | text | notes |
|---|---|---|---|---|---|---|
| EL_B01_01 | monologue | Elias | 01 | | Where... is this? | waking |
| EL_B01_02 | monologue | Elias | 01 | | Every clock says 23:59. None of them are moving. | first look at the boards |
| EL_B01_03 | monologue | Elias | 01 | | Time doesn't stop. It waits. Where did I hear that? | shared phrase (see OP_B03_03) |
| EL_B01_04 | monologue | Elias | 01 | global.pocket_watch | A pocket watch. Cracked glass. Still warm, like someone just put it down. | watch pickup |
| EL_CLOCK_2359 | monologue | Elias | any | ch01.*.digital_clock_2359 | 23:59. The seconds digit flickers, but it never turns over. | clock inspect, reusable |
| OP_B03_01 | operator | Operator (call box) | 03 | ch01.concourse_west.call_box_09 | Easy. Don't hang up. You're in Elysium-09, under the old transit line. | |
| OP_B03_02 | operator | Operator (call box) | 03 | ch01.concourse_west.call_box_09 | The station is under a containment lock. Every door you've seen was sealed at 23:59. | |
| OP_B03_03 | operator | Operator (call box) | 03 | ch01.concourse_west.call_box_09 | That watch still remembers how things were. Use it. Time doesn't stop. It waits. | shared phrase |
| EL_B03_01 | dialogue | Elias | 03 | ch01.concourse_west.call_box_09 | Who is this? How do you know about the watch? | |
| OP_B03_04 | operator | Operator (call box) | 03 | ch01.concourse_west.call_box_09 | Later. Restore auxiliary power at Signal Control. The street exit opens from there. | |
| OP_B03_05 | operator | Operator (call box) | 03 | ch01.concourse_west.call_box_09 | This line won't hold much longer. Keep moving. | call ends |
| OP_B05_01 | operator | Operator (PA) | 05 | ch01.security_crossing.pa_speaker | Don't stare at it too long. An echo only does what you already chose to do. | from beat sheet (proposed object ID) |
| EL_B05_01 | monologue | Elias | 05 | | That was me. A minute ago. And it's still standing there. | first echo playback |
| EL_B06_01 | monologue | Elias | 06 | ch01.waiting_lounge.trace_bench | Two people on this bench. One of them sits the way I do. | Trace on the bench |
| EL_B06_02 | monologue | Elias | 06 | ch01.waiting_lounge.audio_mira_01 | Mira. I know that voice. Why do I know that voice? | after the audio log |
| OP_B07_01 | operator | Operator (intercom) | 07 | ch01.signal_control.intercom | Power's back. Good. Now go straight to the street exit. | after PZ-004 (proposed object ID) |
| OP_B07_02 | operator | Operator (intercom) | 07 | ch01.signal_control.intercom | There's a dispatch terminal in the Atrium. Leave it alone. It won't help you. | suspicion seed (proposed object ID) |
| EL_B08_01 | monologue | Elias | 08 | ch01.upper_vestibule | I walked north. I came out of the west arch. The building is lying to me. | first loop |
| EL_B09_01 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | It knows my hand. | terminal unlocks |
| EL_B09_02 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | Level-0 clearance. My clearance. I sealed this station. | THE revelation |
| EL_B09_03 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | Why would I do that? | |
| EL_B09_04 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | The same minute, over and over. Probably a clock fault. Probably. | ambiguous seed only |
| EL_B10_01 | monologue | Elias | 10 | ch01.street_exit | The rain isn't falling. It's hanging in the air, waiting. | cinematic |
| OP_B10_01 | operator | Operator (payphone) | 10 | ch01.street_exit.plaza_payphone | Now you see why I told you to leave the terminal alone. | from beat sheet |
| OP_B10_02 | operator | Operator (payphone) | 10 | ch01.street_exit.plaza_payphone | Keep moving. She's in the Central District, and the city remembers what you lost. | chapter hook |
| SPK_ELIAS | speaker | System | any | | Elias | UI speaker label |
| SPK_MIRA | speaker | System | any | | Mira | UI speaker label |
| SPK_OPERATOR | speaker | System | any | | VOICE | UI speaker label (canon hides true identity) |
| JRN_CH1_TURNSTILE_TRACE | journal | | 02 | ch01.concourse_west.turnstile_trace_anchor | Someone else passed through the West Turnstile seconds before the station froze at 23:59. | observation (spec) |
| JRN_CH1_EVAC_2354 | journal | | 03 | ch01.concourse_west.doc_evac_notice | An evacuation was ordered at 23:54. Five minutes later, every clock stopped. | fact |
| JRN_CH1_OPERATOR | journal | | 03 | ch01.concourse_west.call_box_09 | A voice on the call box knows the station, the lock, and the watch. It won't say who it is. | observation |
| JRN_CH1_BACKFLOW | journal | | 04 | ch01.maintenance_bay.doc_tech_log | Days before the lock, technicians logged "chronometric backflow". The directors told them to ignore it. | observation |
| JRN_CH1_TWO_SILHOUETTES | journal | | 06 | ch01.waiting_lounge.trace_bench | Two traces on the lounge bench: a woman, and a man who stands like me. | observation |
| JRN_CH1_MIRA_PLEA | journal | | 06 | ch01.waiting_lounge.audio_mira_01 | Mira asked me not to come back for her if the stabilization failed. | fact |
| JRN_CH1_OPERATOR_WARNING | journal | | 07 | ch01.signal_control.intercom | The voice on the intercom warned me away from the Atrium dispatch logs. What is it hiding? | theory, suspicion seed |
| JRN_CH1_THRESHOLDS | journal | | 08 | ch01.vestibule_niche.doc_index_plaque | The ELYSIUM field indexes doorways. When time froze, some stopped leading where they should. | theory |
| JRN_CH1_SEAL_ELIAS | journal | | 09 | ch01.station_atrium.dispatch_terminal | The containment lock was executed from the Atrium terminal with my Level-0 clearance. | fact |
| JRN_CH1_REPEATS | journal | | 09 | ch01.station_atrium.dispatch_terminal | The terminal log repeats one line: 23:59:00, USER: ELIAS. A fault? | theory, ambiguous seed |
| FRAG_MIRA_DEPARTURE_TITLE | fragment | | 06 | ch01.fragment.mira_departure | Memory: The Lounge Bench | |
| FRAG_MIRA_DEPARTURE_BODY | fragment | | 06 | ch01.fragment.mira_departure | Her hand on my sleeve. The departure board flickering. She was asking me for something, and I said no. | |
| PZ001_FB_GATE_JAMMED | feedback | | 02 | ch01.concourse_west.turnstile_gate | The turnstile rotor is crushed shut. Force won't move it. | |
| PZ001_FB_GATE_REWIND_ONLY | feedback | | 02 | ch01.concourse_west.turnstile_gate | Only Rewind can restore this fractured mechanism. | |
| PZ001_FB_PILLAR_UNSUPPORTED | feedback | | 02 | ch01.concourse_west.support_pillar_01 | Solid station concrete. No temporal fracture here. | |
| PZ002_FB_GEAR_LOCKED | feedback | | 04 | ch01.maintenance_bay.fire_shutter | The gear is frozen solid. Unfreeze it before rewinding the shutter. | shortened |
| PZ002_FB_GEAR_NO_REWIND | feedback | | 04 | ch01.maintenance_bay.counterweight_gear | The stripped gear has no memory to rewind. Try the shutter. | shortened |
| PZ002_FB_SHUTTER_HEAVY | feedback | | 04 | ch01.maintenance_bay.fire_shutter | Too heavy to lift by hand. | |
| PZ002_FB_SHUTTER_NO_FREEZE | feedback | | 04 | ch01.maintenance_bay.fire_shutter | The shutter is too heavy to freeze. Target the counterweight gear. | shortened |
| PZ003_FB_GATE_SWITCH_LOCKED | feedback | | 05 | ch01.security_crossing.security_gate_01 | Locked by the floor pressure switch on the south deck. | |
| PZ003_FB_SHIELDED_GATE | feedback | | 05 | ch01.security_crossing.security_gate_01 | Chrono-shielded security gate. It can't be frozen or rewound. | |
| PZ003_FB_SHIELDED_SWITCH | feedback | | 05 | ch01.security_crossing.pressure_switch_01 | Chrono-shielded plate. It only responds to weight. | |
| PZ004_FB_BREAKER_ENGAGED | feedback | | 07 | ch01.signal_control.breaker_a | Breaker is already engaged. | |
| PZ004_FB_BREAKER_SHIELDED | feedback | | 07 | ch01.signal_control.breaker_a | Insulated high-voltage switch. The watch can't affect it. | |
| PZ004_FB_BUS_UNPOWERED | feedback | | 07 | ch01.signal_control.breaker_a | The power bus is dead. Stabilize the central capacitor first. | |
| PZ004_FB_DOOR_UNPOWERED | feedback | | 07 | ch01.signal_control.vestibule_door | Bulkhead sealed. Engage both breakers at once to restore power. | |
| PZ005_FB_ATRIUM_LOCKED | feedback | | 08 | ch01.upper_vestibule.junction_lever_a | The north arch is routed to the Atrium. The West Loop can't re-engage. | shortened |
| PZ005_FB_LOOP_CONFLICT | feedback | | 08 | ch01.upper_vestibule.junction_lever_b | Route conflict on the north arch. Uncouple the West Loop first. | |
| PZ005_FB_SPATIAL_ANCHORED | feedback | | 08 | ch01.upper_vestibule.junction_lever_a | Spatial relays sit outside local time. Switch them by hand. | |
| DOC_EVAC_NOTICE_TITLE | document | | 03 | ch01.concourse_west.doc_evac_notice | TRANSIT BULLETIN 23:54 | |
| DOC_EVAC_NOTICE_BODY_1 | document | | 03 | ch01.concourse_west.doc_evac_notice | ELYSIUM CIVIC STABILIZATION PROJECT<br>Emergency evacuation of Elysium-09.<br>All passengers proceed to street level.<br>Do not use platform lifts.<br>Staff: secure the lower concourse.<br>This is not a drill. | |
| DOC_TECH_LOG_TITLE | document | | 04 | ch01.maintenance_bay.doc_tech_log | MAINTENANCE CLIPBOARD | |
| DOC_TECH_LOG_BODY_1 | document | | 04 | ch01.maintenance_bay.doc_tech_log | Day 3: grid shows chronometric backflow.<br>Counters run, then un-run. Logged it.<br>Day 4: worse. Shutter gear slipping.<br>Day 5: directors say ignore the readings.<br>"Within ELYSIUM tolerances."<br>Whose tolerances? | |
| DOC_MIRA_01_TITLE | audio | Mira | 06 | ch01.waiting_lounge.audio_mira_01 | VOICE RECORDER - DAMAGED | |
| DOC_MIRA_01_BODY_1 | audio | Mira | 06 | ch01.waiting_lounge.audio_mira_01 | [static]<br>Elias, if the stabilization fails,<br>don't come back for me.<br>Promise me you'll let the clock pass midnight.<br>Promise me.<br>[static] | from beat sheet |
| DOC_INDEX_PLAQUE_TITLE | plaque | | 08 | ch01.vestibule_niche.doc_index_plaque | ELYSIUM THRESHOLD INDEX | |
| DOC_INDEX_PLAQUE_BODY_1 | plaque | | 08 | ch01.vestibule_niche.doc_index_plaque | Every threshold in this station is indexed.<br>An archway leads where its index points.<br>Should the field be interrupted,<br>indices may decouple from their walls.<br>Do not pass an unmarked arch.<br>- ELYSIUM Facilities | |
| DOC_TRANSIT_PASS_TITLE | document | | 05 | ch01.security_crossing.transit_pass_pickup | STAFF TRANSIT PASS | progression pickup |
| DOC_TRANSIT_PASS_BODY_1 | document | | 05 | ch01.security_crossing.transit_pass_pickup | ELYSIUM SITE ACCESS<br>Holder: [name scratched out]<br>Clearance: LEVEL-0<br>Valid until: 23:59<br><br>The photo has been torn away. | |
| DOC_DISPATCH_TITLE | terminal | | 09 | ch01.station_atrium.dispatch_terminal | CENTRAL DISPATCH RECORDER | the revelation |
| DOC_DISPATCH_BODY_1 | terminal | | 09 | ch01.station_atrium.dispatch_terminal | BIOMETRIC MATCH - ACCESS GRANTED<br>EVENT: CONTAINMENT PROTOCOL<br>STATUS: EXECUTED 23:59:00<br>AUTHORIZATION: LEVEL-0<br>USER: ELIAS<br>LOCATION: THIS TERMINAL | |
| DOC_DISPATCH_BODY_2 | terminal | | 09 | ch01.station_atrium.dispatch_terminal | DIAGNOSTIC LOG<br>23:59:00 - USER: ELIAS<br>23:59:00 - USER: ELIAS<br>23:59:00 - USER: ELIAS<br>23:59:00 - USER: ELIAS<br>23:59:00 - USER: ELIAS | unnumbered, no "exit" |
| SPK_MEM_N01 | speaker | System | any |  | Ines, conductor | frozen commuter speaker label |
| MEM_N01_1 | memory | Ines, conductor | 01b | ch01.arrival_platform.n01_conductor | [23:57] Doors closing! Hollow Quay, rear car only. | Trace memory line 1 (time stamp first) |
| MEM_N01_2 | memory | Ines, conductor | 01b | ch01.arrival_platform.n01_conductor | They keep changing it. Go by the last announcement. | Trace memory line 2 |
| JRN_MEM_N01 | journal |  | 01b | ch01.arrival_platform.n01_conductor | Ines, conductor, 23:57: the last service is Hollow Quay, rear car. Go by the last announcement. | observation (added on first Trace) |
| SPK_MEM_N02 | speaker | System | any |  | Tomas, student | frozen commuter speaker label |
| MEM_N02_1 | memory | Tomas, student | 01b | ch01.arrival_platform.n02_student | [23:41] Mum says Central, platform 1, front car. | Trace memory line 1 (time stamp first) |
| MEM_N02_2 | memory | Tomas, student | 01b | ch01.arrival_platform.n02_student | She can't know about the cancellations, can she? | Trace memory line 2 |
| JRN_MEM_N02 | journal |  | 01b | ch01.arrival_platform.n02_student | Tomas, a student, 23:41: Central line, platform 1, front car, his mother's advice. | observation (added on first Trace) |
| SPK_MEM_N03 | speaker | System | any |  | Mr. Adeyemi, old man | frozen commuter speaker label |
| MEM_N03_1 | memory | Mr. Adeyemi, old man | 01b | ch01.arrival_platform.n03_old_man | [23:30] Harbour line, platform 2, middle car. | Trace memory line 1 (time stamp first) |
| MEM_N03_2 | memory | Mr. Adeyemi, old man | 01b | ch01.arrival_platform.n03_old_man | Forty years. Same bench, same train. | Trace memory line 2 |
| JRN_MEM_N03 | journal |  | 01b | ch01.arrival_platform.n03_old_man | Mr. Adeyemi, 23:30: Harbour line, platform 2, middle car. The oldest word on the platform. | observation (added on first Trace) |
| SPK_MEM_N04 | speaker | System | any |  | Night cleaner | frozen commuter speaker label |
| MEM_N04_1 | memory | Night cleaner | 01b | ch01.arrival_platform.n04_cleaner | [23:58] They moved the last service to platform 3. | Trace memory line 1 (time stamp first) |
| MEM_N04_2 | memory | Night cleaner | 01b | ch01.arrival_platform.n04_cleaner | Hauled my trolley over. One minute and I'm clocked out. | Trace memory line 2 |
| JRN_MEM_N04 | journal |  | 01b | ch01.arrival_platform.n04_cleaner | The night cleaner, 23:58: the last service was moved to platform 3. | observation (added on first Trace) |
| SPK_MEM_N05 | speaker | System | any |  | Dev, courier | frozen commuter speaker label |
| MEM_N05_1 | memory | Dev, courier | 02a | ch01.concourse_west.n05_courier | [23:59] Not stopping for a gate. The conduit's coming down! | Trace memory line 1 (time stamp first) |
| MEM_N05_2 | memory | Dev, courier | 02a | ch01.concourse_west.n05_courier | Go, go, GO! | Trace memory line 2 |
| JRN_MEM_N05 | journal |  | 02a | ch01.concourse_west.n05_courier | A courier cleared the turnstile at 23:59 as the ceiling conduit fell. The watch ticked backwards. | observation (added on first Trace) |
| SPK_MEM_N06 | speaker | System | any |  | Woman in a red coat | frozen commuter speaker label |
| MEM_N06_1 | memory | Woman in a red coat | 03b | ch01.concourse_west.n06_red_coat | [23:41] Harbour line, platform 1. | Trace memory line 1 (time stamp first) |
| MEM_N06_2 | memory | Woman in a red coat | 03b | ch01.concourse_west.n06_red_coat | I'll make the 23:50 if this thing prints. | Trace memory line 2 |
| JRN_MEM_N06 | journal |  | 03b | ch01.concourse_west.n06_red_coat | Woman in a red coat, 23:41: ticket for the Harbour line, platform 1. | observation (added on first Trace) |
| SPK_MEM_N07 | speaker | System | any |  | Man with a briefcase | frozen commuter speaker label |
| MEM_N07_1 | memory | Man with a briefcase | 03b | ch01.concourse_west.n07_briefcase | [23:49] Central line, platform 2. | Trace memory line 1 (time stamp first) |
| MEM_N07_2 | memory | Man with a briefcase | 03b | ch01.concourse_west.n07_briefcase | Third notice today that says it's not a drill. | Trace memory line 2 |
| JRN_MEM_N07 | journal |  | 03b | ch01.concourse_west.n07_briefcase | Man with a briefcase, 23:49: ticket for the Central line, platform 2. | observation (added on first Trace) |
| SPK_MEM_N08 | speaker | System | any |  | Father with a child | frozen commuter speaker label |
| MEM_N08_1 | memory | Father with a child | 03b | ch01.concourse_west.n08_father | [23:53] Orchard Gate, platform 3. | Trace memory line 1 (time stamp first) |
| MEM_N08_2 | memory | Father with a child | 03b | ch01.concourse_west.n08_father | Just let her sleep. Just let her sleep. | Trace memory line 2 |
| JRN_MEM_N08 | journal |  | 03b | ch01.concourse_west.n08_father | A father with a sleeping child, 23:53: ticket for Orchard Gate, platform 3. | observation (added on first Trace) |
| SPK_MEM_N09 | speaker | System | any |  | Teenager | frozen commuter speaker label |
| MEM_N09_1 | memory | Teenager | 03b | ch01.concourse_west.n09_teen | [23:55] Orchard Gate, platform 1. | Trace memory line 1 (time stamp first) |
| MEM_N09_2 | memory | Teenager | 03b | ch01.concourse_west.n09_teen | Bought it right when they said evacuate. Whatever. | Trace memory line 2 |
| JRN_MEM_N09 | journal |  | 03b | ch01.concourse_west.n09_teen | A teenager, 23:55: ticket for Orchard Gate, platform 1, bought as the evacuation was announced. | observation (added on first Trace) |
| SPK_MEM_N11 | speaker | System | any |  | Hollis, hatch tech | frozen commuter speaker label |
| MEM_N11_1 | memory | Hollis, hatch tech | 04a | ch01.maintenance_bay.n11_hatch_tech | [23:58] Hold it. Hold it open! I'll fetch the wrench. | Trace memory line 1 (time stamp first) |
| MEM_N11_2 | memory | Hollis, hatch tech | 04a | ch01.maintenance_bay.n11_hatch_tech | Hold it... | Trace memory line 2 |
| JRN_MEM_N11 | journal |  | 04a | ch01.maintenance_bay.n11_hatch_tech | Hollis, a hatch tech, 23:58: held a service hatch open by hand. The watch stopped for a moment. | observation (added on first Trace) |
| SPK_MEM_N13 | speaker | System | any |  | Corva, security guard | frozen commuter speaker label |
| MEM_N13_1 | memory | Corva, security guard | 05a | ch01.security_crossing.n13_guard | [23:57] The gate follows the south plate. | Trace memory line 1 (time stamp first) |
| MEM_N13_2 | memory | Corva, security guard | 05a | ch01.security_crossing.n13_guard | The north one's the alarm. Trust me on that. | Trace memory line 2 |
| JRN_MEM_N13 | journal |  | 05a | ch01.security_crossing.n13_guard | Corva, security guard, 23:57: the south plate works the gate. The north plate is only an alarm. | observation (added on first Trace) |
| SPK_MEM_N20 | speaker | System | any |  | Lis, signal engineer | frozen commuter speaker label |
| MEM_N20_1 | memory | Lis, signal engineer | 07a | ch01.signal_control.n20_engineer | [23:56] Bus 2 is hot. Don't touch breaker C. | Trace memory line 1 (time stamp first) |
| MEM_N20_2 | memory | Lis, signal engineer | 07a | ch01.signal_control.n20_engineer | C is the lamp ring. It'll brown out the whole bank. | Trace memory line 2 |
| JRN_MEM_N20 | journal |  | 07a | ch01.signal_control.n20_engineer | Lis, signal engineer, 23:56: never engage breaker C while the bus is powered. | observation (added on first Trace) |
| SPK_MEM_N21 | speaker | System | any |  | Ayo, tourist | frozen commuter speaker label |
| MEM_N21_1 | memory | Ayo, tourist | 08a | ch01.upper_vestibule.n21_tourist | [23:55] North, then west, then north again. | Trace memory line 1 (time stamp first) |
| MEM_N21_2 | memory | Ayo, tourist | 08a | ch01.upper_vestibule.n21_tourist | I keep coming out of the same door. | Trace memory line 2 |
| JRN_MEM_N21 | journal |  | 08a | ch01.upper_vestibule.n21_tourist | Ayo, a tourist, 23:55: walking north brought them out of the west arch again and again. | observation (added on first Trace) |
| SPK_MEMORY | speaker | System | any |  | Memory | generic Trace speaker label |
| MEM_ANCHOR_TURNSTILE_1 | memory | Memory | 02a | ch01.concourse_west.turnstile_trace_anchor | [23:59] A figure vaults the gate. Behind him a conduit tears loose. | scene memory, line 1 |
| MEM_ANCHOR_TURNSTILE_2 | memory | Memory | 02a | ch01.concourse_west.turnstile_trace_anchor | It lands across the turnstile arm. | scene memory, line 2 |
| EL_UNLOCK_REWIND | monologue | Elias | 02a | ch01.concourse_west.n05_courier | It went back. One step. | Rewind unlock |
| EL_UNLOCK_FREEZE | monologue | Elias | 04a | ch01.maintenance_bay.n11_hatch_tech | It can hold things still. | Freeze unlock |
| EL_UNLOCK_ECHO | monologue | Elias | 05a | ch01.security_crossing.echo_recorder_pedestal | A second hand. It follows the first. | Echo unlock |
| UNLOCK_TRACE | toast |  | 01 | global.pocket_watch | Trace unlocked. Hold the watch up to anything that remembers. | HUD toast, 60 chars |
| UNLOCK_REWIND | toast |  | 02a |  | Rewind unlocked. | HUD toast |
| UNLOCK_FREEZE | toast |  | 04a |  | Freeze unlocked. | HUD toast |
| UNLOCK_ECHO | toast |  | 05a |  | Echo unlocked. | HUD toast |
| SO001_FB_WRONG_CODE | feedback |  | 01b | ch01.arrival_platform.release_lever | The panel buzzes and resets. | identical for every wrong code (no partial feedback) |
| SO001_FB_LOCKED_OUT | feedback |  | 01b | ch01.arrival_platform.release_lever | The panel is still resetting. | during the lock-out |
| SO001_FB_GATE_SEALED | feedback |  | 01b | ch01.arrival_platform.platform_gate | Sealed. The release panel is on the north wall. | use on the gate |
| SO001_LINE_0 | label |  | 01b | ch01.arrival_platform.selector_line | CENTRAL | selector LINE position 0 |
| SO001_LINE_1 | label |  | 01b | ch01.arrival_platform.selector_line | HOLLOW QUAY | selector LINE position 1 (answer) |
| SO001_LINE_2 | label |  | 01b | ch01.arrival_platform.selector_line | HARBOUR | selector LINE position 2 |
| SO001_PLAT_0 | label |  | 01b | ch01.arrival_platform.selector_platform | PLAT 1 | selector PLATFORM position 0 |
| SO001_PLAT_1 | label |  | 01b | ch01.arrival_platform.selector_platform | PLAT 2 | selector PLATFORM position 1 |
| SO001_PLAT_2 | label |  | 01b | ch01.arrival_platform.selector_platform | PLAT 3 | selector PLATFORM position 2 (answer) |
| SO001_CAR_0 | label |  | 01b | ch01.arrival_platform.selector_car | MIDDLE CAR | selector CAR position 0 |
| SO001_CAR_1 | label |  | 01b | ch01.arrival_platform.selector_car | REAR CAR | selector CAR position 1 (answer) |
| SO001_CAR_2 | label |  | 01b | ch01.arrival_platform.selector_car | FRONT CAR | selector CAR position 2 |
| JRN_SO001_SOLVED | journal |  | 01b | ch01.arrival_platform.release_lever | The platform gate answers to the last announcement, not the first. | fact |
| DOC_LAST_SERVICE_TITLE | document |  | 01b | ch01.arrival_platform.doc_last_service | PLATFORM ANNOUNCEMENT LOG |  |
| DOC_LAST_SERVICE_BODY_1 | document |  | 01b | ch01.arrival_platform.doc_last_service | LAST SERVICE: ANNOUNCEMENTS<br>23:30  service announced<br>23:41  service changed<br>23:57  service changed<br>23:58  platform changed<br>Follow the latest announcement. | times only, no values (insurance for the rule) |
| JRN_DOC_LAST_SERVICE | journal |  | 01b | ch01.arrival_platform.doc_last_service | The platform log: the service was changed three times, the platform once. The latest one counts. | observation |
| SO002_FB_HATCH_WEIGHT | feedback |  | 04b | ch01.maintenance_bay.hatch_01 | The hatch only opens under weight. | use on a closed hatch |
| SO002_FB_BELL | feedback |  | 04b | ch01.maintenance_bay.bell_plate_01 | A bell rings. Nothing else happens. | decoy plate |
| SO002_FB_HATCH_HELD | feedback |  | 04b | ch01.maintenance_bay.hatch_01 | The hatch is held open. | use on a frozen open hatch |
| JRN_SO002_SOLVED | journal |  | 04b | ch01.maintenance_bay.hatch_01 | The watch can hold a mechanism in the state it is in, even after I step away. | fact |
| DOC_HATCH_CHART_TITLE | document |  | 04b | ch01.maintenance_bay.doc_hatch_chart | HATCH 4 SERVICE CHART |  |
| DOC_HATCH_CHART_BODY_1 | document |  | 04b | ch01.maintenance_bay.doc_hatch_chart | Plate A (brass, marked A): opens Hatch 4<br>Plate B (green, marked B): service bell<br>The hatch opens under weight.<br>Do not leave it unattended.<br>- Maintenance |  |
| JRN_DOC_HATCH_CHART | journal |  | 04b | ch01.maintenance_bay.doc_hatch_chart | Plate A works the hatch. Plate B only rings a bell. | observation |
| OP_B03_06 | operator | Operator (call box) | 03a | ch01.concourse_west.call_box_09 | The staff door opens for one ticket only. Ask the queue what they bought, and when. | new nudge, plays before OP_B03_05 |
| DOC_TICKET_TERMS_TITLE | document |  | 03b | ch01.concourse_west.doc_ticket_terms | STAFF DOOR NOTICE |  |
| DOC_TICKET_TERMS_BODY_1 | document |  | 03b | ch01.concourse_west.doc_ticket_terms | After the evacuation order,<br>only ORCHARD GATE tickets<br>are honoured at the staff door.<br>The door reads one ticket at a time.<br>- Station Office |  |
| JRN_DOC_TICKET_TERMS | journal |  | 03b | ch01.concourse_west.doc_ticket_terms | The staff door honours Orchard Gate tickets bought after the evacuation order. | fact |
| PZ006_LINE_0 | label |  | 03b | ch01.concourse_west.dial_line | DOCKSIDE | LINE dial entry 0 |
| PZ006_LINE_1 | label |  | 03b | ch01.concourse_west.dial_line | HARBOUR | LINE dial entry 1 |
| PZ006_LINE_2 | label |  | 03b | ch01.concourse_west.dial_line | ORCHARD GATE | LINE dial entry 2 (target) |
| PZ006_LINE_3 | label |  | 03b | ch01.concourse_west.dial_line | CENTRAL | LINE dial entry 3 |
| PZ006_LINE_4 | label |  | 03b | ch01.concourse_west.dial_line | HOLLOW QUAY | LINE dial entry 4 |
| PZ006_LINE_5 | label |  | 03b | ch01.concourse_west.dial_line | HILL ROAD | LINE dial entry 5 (tick-0) |
| PZ006_PLAT_0 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 6 | PLATFORM dial entry 0 |
| PZ006_PLAT_1 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 4 | PLATFORM dial entry 1 |
| PZ006_PLAT_2 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 2 | PLATFORM dial entry 2 |
| PZ006_PLAT_3 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 1 | PLATFORM dial entry 3 (target) |
| PZ006_PLAT_4 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 3 | PLATFORM dial entry 4 |
| PZ006_PLAT_5 | label |  | 03b | ch01.concourse_west.dial_platform | PLAT 5 | PLATFORM dial entry 5 (tick-0) |
| PZ006_TIME_0 | label |  | 03b | ch01.concourse_west.dial_time | 23:38 | TIME dial entry 0 |
| PZ006_TIME_1 | label |  | 03b | ch01.concourse_west.dial_time | 23:55 | TIME dial entry 1 (target) |
| PZ006_TIME_2 | label |  | 03b | ch01.concourse_west.dial_time | 23:49 | TIME dial entry 2 |
| PZ006_TIME_3 | label |  | 03b | ch01.concourse_west.dial_time | 23:41 | TIME dial entry 3 |
| PZ006_TIME_4 | label |  | 03b | ch01.concourse_west.dial_time | 23:53 | TIME dial entry 4 |
| PZ006_TIME_5 | label |  | 03b | ch01.concourse_west.dial_time | 23:57 | TIME dial entry 5 (tick-0) |
| PZ006_FB_DIAL_JAMMED | feedback |  | 03b | ch01.concourse_west.dial_line | The dial only turns back with the watch. | use on a dial |
| PZ006_FB_NO_SUCH_TICKET | feedback |  | 03b | ch01.concourse_west.ticket_validator | No such ticket. | identical for every wrong combination |
| PZ006_FB_DOOR_WAITING | feedback |  | 03b | ch01.concourse_west.staff_door | The staff door is waiting for a valid ticket. | use on the staff door |
| PZ006_OK | feedback |  | 03b | ch01.concourse_west.ticket_validator | Ticket accepted. The staff door unlocks. | success |
| JRN_PZ006_SOLVED | journal |  | 03b | ch01.concourse_west.ticket_validator | The ticket machines remember tickets out of order. Time here runs backwards in places. | theory |
| PZ001_FB_PINNED | feedback |  | 02b | ch01.concourse_west.turnstile_gate | A fallen conduit pins the turnstile. Lift it first. | Rewind on a pinned gate |
| PZ002_FB_UNANCHORED | feedback |  | 04c | ch01.maintenance_bay.inner_shutter | The inner shutter needs the gear locked to hold. | Rewind on the inner shutter while the gear is free |
| DOC_INNER_SHUTTER_TITLE | document |  | 04c | ch01.maintenance_bay.doc_inner_shutter_plate | INNER SHUTTER |  |
| DOC_INNER_SHUTTER_BODY_1 | document |  | 04c | ch01.maintenance_bay.doc_inner_shutter_plate | Anchored to the main counterweight gear.<br>Gear locked: shutter holds.<br>Gear free: shutter will not lift. |  |
| JRN_DOC_INNER_SHUTTER | journal |  | 04c | ch01.maintenance_bay.doc_inner_shutter_plate | The inner shutter hangs on the same gear. It only lifts while the gear is locked. | observation |
| PZ003_FB_NO_PASS | feedback |  | 05b | ch01.security_crossing.card_reader_01 | A staff pass is needed to open this barrier. | reader without the pass |
| PZ003_FB_ALARM | feedback |  | 05b | ch01.security_crossing.alarm_plate_01 | The alarm rings. Nothing else happens. | decoy plate |
| PZ003_FB_BARRIER | feedback |  | 05b | ch01.security_crossing.staff_barrier_01 | Staff only. The reader is beside the barrier. | use on the barrier |
| DOC_GUARD_LOG_TITLE | document |  | 05b | ch01.security_crossing.doc_guard_log | SECURITY LOG |  |
| DOC_GUARD_LOG_BODY_1 | document |  | 05b | ch01.security_crossing.doc_guard_log | 23:52 Trench sealed: staff only.<br>23:55 Gate runs off the SOUTH plate.<br>NORTH plate: alarm. Do not stand on it.<br>Staff pass at the desk, reader at the barrier. |  |
| JRN_DOC_GUARD_LOG | journal |  | 05b | ch01.security_crossing.doc_guard_log | Only the south plate works the gate. The staff pass is needed at the east barrier. | observation |
| PZ004_FB_BROWNOUT | feedback |  | 07b | ch01.signal_control.breaker_c | Breaker C browned out the capacitor. Stabilize it again. | C pulled while charged |
| PZ004_FB_C_DEAD | feedback |  | 07b | ch01.signal_control.breaker_c | The lamp ring has no power to draw yet. | C pulled while the bus is dead |
| DOC_BUS_CHART_TITLE | document |  | 07b | ch01.signal_control.doc_bus_chart | BUS 2 CHART |  |
| DOC_BUS_CHART_BODY_1 | document |  | 07b | ch01.signal_control.doc_bus_chart | A, B: vestibule door feed<br>C: lamp ring. Do NOT engage<br>while the bus is powered.<br>Engage A and B together. |  |
| JRN_DOC_BUS_CHART | journal |  | 07b | ch01.signal_control.doc_bus_chart | Breakers A and B feed the vestibule door. Breaker C is the lamp ring and must stay off. | observation |
| PZ005_FB_UNPOWERED_RELAY | feedback |  | 08b | ch01.upper_vestibule.junction_lever_a | The relay is dead. Something must hold the standby plate. | lever without plate power |
| PZ005_FB_DEAD_RELAY | feedback |  | 08b | ch01.upper_vestibule.junction_lever_c | This auxiliary relay was never wired. | decoy lever |
| DOC_RELAY_MEMO_TITLE | document |  | 08b | ch01.upper_vestibule.doc_relay_memo | RELAY BOX MEMO |  |
| DOC_RELAY_MEMO_BODY_1 | document |  | 08b | ch01.upper_vestibule.doc_relay_memo | Junction relays draw standby power<br>from the floor plate in the SW corner.<br>Keep it held while switching. |  |
| JRN_DOC_RELAY_MEMO | journal |  | 08b | ch01.upper_vestibule.doc_relay_memo | The junction relays need the floor plate held while they are switched. | observation |
| MEM_HATCH_RESIDUE_1 | memory | Memory | 04b | ch01.maintenance_bay.hatch_residue | [23:58] A man's whole weight on the brass plate. | scene memory on the brass plate, line 1 |
| MEM_HATCH_RESIDUE_2 | memory | Memory | 04b | ch01.maintenance_bay.hatch_residue | The hatch breathes open. It closes the moment he lets go. | scene memory, line 2 |
| JRN_MEM_HATCH | journal |  | 04b | ch01.maintenance_bay.hatch_residue | The brass plate opens the hatch while someone stands on it. It shuts the moment they step off. | observation |
| MEM_GEAR_RESIDUE_1 | memory | Memory | 04c | ch01.maintenance_bay.gear_residue | [23:56] The gear housing shudders. A second linkage runs east. | scene memory on the counterweight gear, line 1 |
| MEM_GEAR_RESIDUE_2 | memory | Memory | 04c | ch01.maintenance_bay.gear_residue | It ends at the inner shutter. Both hang on this one gear. | scene memory, line 2 |
| JRN_MEM_GEAR | journal |  | 04c | ch01.maintenance_bay.gear_residue | The counterweight gear also carries the inner shutter, east of the first one. | observation |

## Documents
| document_id | kind | title_key | body_keys | flag_id | fragment_id | journal_key | category |
|---|---|---|---|---|---|---|---|
| ch01.concourse_west.doc_evac_notice | DOCUMENT | DOC_EVAC_NOTICE_TITLE | DOC_EVAC_NOTICE_BODY_1 | ch01.flag.evac_notice_read | | JRN_CH1_EVAC_2354 | fact |
| ch01.maintenance_bay.doc_tech_log | DOCUMENT | DOC_TECH_LOG_TITLE | DOC_TECH_LOG_BODY_1 | | | JRN_CH1_BACKFLOW | observation |
| ch01.waiting_lounge.audio_mira_01 | AUDIO_LOG | DOC_MIRA_01_TITLE | DOC_MIRA_01_BODY_1 | ch01.flag.mira_trace_seen | ch01.fragment.mira_departure | JRN_CH1_MIRA_PLEA | fact |
| ch01.vestibule_niche.doc_index_plaque | PLAQUE | DOC_INDEX_PLAQUE_TITLE | DOC_INDEX_PLAQUE_BODY_1 | | | JRN_CH1_THRESHOLDS | theory |
| ch01.station_atrium.dispatch_terminal | TERMINAL | DOC_DISPATCH_TITLE | DOC_DISPATCH_BODY_1 | ch01.flag.ledger_2359_revealed | | JRN_CH1_SEAL_ELIAS | fact |

## Documents (Step 1, pending implementation)
Not read by `gen_ch01_text.py` (the generator parses only the `## Documents` table above). These seven readables belong to the TLF-047 Step 1 specs; their `DocumentDef` resources are generated when the implementation task moves the rows into the table above (it also updates the document-count assertion in `tests/narrative/test_ch01_text.gd`, which expects exactly 5).

| document_id | kind | title_key | body_keys | flag_id | fragment_id | journal_key | category |
|---|---|---|---|---|---|---|---|
| ch01.arrival_platform.doc_last_service | DOCUMENT | DOC_LAST_SERVICE_TITLE | DOC_LAST_SERVICE_BODY_1 | ch01.flag.last_service_read |  | JRN_DOC_LAST_SERVICE | observation |
| ch01.maintenance_bay.doc_hatch_chart | DOCUMENT | DOC_HATCH_CHART_TITLE | DOC_HATCH_CHART_BODY_1 | ch01.flag.hatch_chart_read |  | JRN_DOC_HATCH_CHART | observation |
| ch01.concourse_west.doc_ticket_terms | PLAQUE | DOC_TICKET_TERMS_TITLE | DOC_TICKET_TERMS_BODY_1 | ch01.flag.ticket_terms_read |  | JRN_DOC_TICKET_TERMS | fact |
| ch01.maintenance_bay.doc_inner_shutter_plate | PLAQUE | DOC_INNER_SHUTTER_TITLE | DOC_INNER_SHUTTER_BODY_1 | ch01.flag.inner_shutter_plate_read |  | JRN_DOC_INNER_SHUTTER | observation |
| ch01.security_crossing.doc_guard_log | DOCUMENT | DOC_GUARD_LOG_TITLE | DOC_GUARD_LOG_BODY_1 | ch01.flag.guard_log_read |  | JRN_DOC_GUARD_LOG | observation |
| ch01.signal_control.doc_bus_chart | PLAQUE | DOC_BUS_CHART_TITLE | DOC_BUS_CHART_BODY_1 | ch01.flag.bus_chart_read |  | JRN_DOC_BUS_CHART | observation |
| ch01.upper_vestibule.doc_relay_memo | DOCUMENT | DOC_RELAY_MEMO_TITLE | DOC_RELAY_MEMO_BODY_1 | ch01.flag.relay_memo_read |  | JRN_DOC_RELAY_MEMO | observation |

## Deltas
- Spec feedback text shortened to fit 80 characters and made ASCII: `PZ002_FB_GEAR_LOCKED`, `PZ002_FB_GEAR_NO_REWIND`, `PZ002_FB_SHUTTER_NO_FREEZE`, `PZ005_FB_ATRIUM_LOCKED`. Every em dash became a full stop.
- `DocumentDef` has a single `body_key`, so the generator uses each document's first page. Multi-page bodies (`DOC_DISPATCH_BODY_2`) are shown by the document UI by key convention (`_BODY_2`, `_BODY_3` …). Adding a `page_keys` field to `DocumentDef` is a small follow-up if the UI needs it.
- The Beat 09 terminal also yields `JRN_CH1_REPEATS` (theory). The UI/scene adds it when page 2 is viewed, since a DocumentDef only carries one journal entry.

- **TLF-047 phase 2 (Step 1):** rows from `MEM_`, `SPK_MEM_`, `JRN_MEM_`, `UNLOCK_`, `EL_UNLOCK_`, `SO00N_`, `PZ006_`, `DOC_*` (7 new readables), `OP_B03_06` and the `PZ00N_FB_` additions are new. `UNLOCK_*`, `SO00N_*` labels and `PZ006_*` dial labels are display strings for the HUD/props. `MEM_*` lines start with a `[hh:mm]` time stamp (the memory UI shows them as is).
- Hint keys for `CH1-SO-01`, `CH1-SO-02` and `CH1-PZ-006` (and the revised hints of PZ-001..005) come from `gen_ch01_puzzle_data.py` once it is extended (`design/ch01/expansion/gen_ch01_puzzle_data.patch`; the generator hard-codes `range(1, 6)`). The generated `data/puzzles/ch01/*.tres` and `localization/ch01_puzzles.csv` are **deferred to the implementation task**: `tests/puzzle/test_hint_service.gd:84` expects exactly 5 PuzzleDefs, and the hint button would otherwise show hints for objects that do not exist yet.

## Open canon questions (for Argon's review when available)
1. Is "Time doesn't stop. It waits." the right shared Elias/Operator phrase, or should it be subtler still?
2. Should the transit pass's "Clearance: LEVEL-0" stay? It foreshadows Beat 09 without stating it.
