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
| OP_B05_01 | operator | Operator (PA) | 05 | ch01.security_crossing | Don't stare at it too long. An echo only does what you already chose to do. | from beat sheet |
| EL_B05_01 | monologue | Elias | 05 | | That was me. A minute ago. And it's still standing there. | first echo playback |
| EL_B06_01 | monologue | Elias | 06 | ch01.waiting_lounge.trace_bench | Two people on this bench. One of them sits the way I do. | Trace on the bench |
| EL_B06_02 | monologue | Elias | 06 | ch01.waiting_lounge.audio_mira_01 | Mira. I know that voice. Why do I know that voice? | after the audio log |
| OP_B07_01 | operator | Operator (intercom) | 07 | ch01.signal_control | Power's back. Good. Now go straight to the street exit. | after PZ-004 |
| OP_B07_02 | operator | Operator (intercom) | 07 | ch01.signal_control | There's a dispatch terminal in the Atrium. Leave it alone. It won't help you. | suspicion seed |
| EL_B08_01 | monologue | Elias | 08 | ch01.upper_vestibule | I walked north. I came out of the west arch. The building is lying to me. | first loop |
| EL_B09_01 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | It knows my hand. | terminal unlocks |
| EL_B09_02 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | Level-0 clearance. My clearance. I sealed this station. | THE revelation |
| EL_B09_03 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | Why would I do that? | |
| EL_B09_04 | monologue | Elias | 09 | ch01.station_atrium.dispatch_terminal | The same minute, over and over. Probably a clock fault. Probably. | ambiguous seed only |
| EL_B10_01 | monologue | Elias | 10 | ch01.street_exit | The rain isn't falling. It's hanging in the air, waiting. | cinematic |
| OP_B10_01 | operator | Operator (payphone) | 10 | ch01.street_exit.plaza_payphone | Now you see why I told you to leave the terminal alone. | from beat sheet |
| OP_B10_02 | operator | Operator (payphone) | 10 | ch01.street_exit.plaza_payphone | Keep moving. She's in the Central District, and the city remembers what you lost. | chapter hook |
| JRN_CH1_TURNSTILE_TRACE | journal | | 02 | ch01.concourse_west.turnstile_trace_anchor | Someone else passed through the West Turnstile seconds before the station froze at 23:59. | observation (spec) |
| JRN_CH1_EVAC_2354 | journal | | 03 | ch01.concourse_west.doc_evac_notice | An evacuation was ordered at 23:54. Five minutes later, every clock stopped. | fact |
| JRN_CH1_OPERATOR | journal | | 03 | ch01.concourse_west.call_box_09 | A voice on the call box knows the station, the lock, and the watch. It won't say who it is. | observation |
| JRN_CH1_BACKFLOW | journal | | 04 | ch01.maintenance_bay.doc_tech_log | Days before the lock, technicians logged "chronometric backflow". The directors told them to ignore it. | observation |
| JRN_CH1_TWO_SILHOUETTES | journal | | 06 | ch01.waiting_lounge.trace_bench | Two traces on the lounge bench: a woman, and a man who stands like me. | observation |
| JRN_CH1_MIRA_PLEA | journal | | 06 | ch01.waiting_lounge.audio_mira_01 | Mira asked me not to come back for her if the stabilization failed. | fact |
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

## Documents
| document_id | kind | title_key | body_keys | flag_id | fragment_id | journal_key | category |
|---|---|---|---|---|---|---|---|
| ch01.concourse_west.doc_evac_notice | DOCUMENT | DOC_EVAC_NOTICE_TITLE | DOC_EVAC_NOTICE_BODY_1 | ch01.flag.evac_notice_read | | JRN_CH1_EVAC_2354 | fact |
| ch01.maintenance_bay.doc_tech_log | DOCUMENT | DOC_TECH_LOG_TITLE | DOC_TECH_LOG_BODY_1 | | | JRN_CH1_BACKFLOW | observation |
| ch01.waiting_lounge.audio_mira_01 | AUDIO_LOG | DOC_MIRA_01_TITLE | DOC_MIRA_01_BODY_1 | ch01.flag.mira_trace_seen | ch01.fragment.mira_departure | JRN_CH1_MIRA_PLEA | fact |
| ch01.vestibule_niche.doc_index_plaque | PLAQUE | DOC_INDEX_PLAQUE_TITLE | DOC_INDEX_PLAQUE_BODY_1 | | | JRN_CH1_THRESHOLDS | theory |
| ch01.station_atrium.dispatch_terminal | TERMINAL | DOC_DISPATCH_TITLE | DOC_DISPATCH_BODY_1 | ch01.flag.ledger_2359_revealed | | JRN_CH1_SEAL_ELIAS | fact |

## Deltas
- Spec feedback text shortened to fit 80 characters and made ASCII: `PZ002_FB_GEAR_LOCKED`, `PZ002_FB_GEAR_NO_REWIND`, `PZ002_FB_SHUTTER_NO_FREEZE`, `PZ005_FB_ATRIUM_LOCKED`. Every em dash became a full stop.
- `DocumentDef` has a single `body_key`, so the generator uses each document's first page. Multi-page bodies (`DOC_DISPATCH_BODY_2`) are shown by the document UI by key convention (`_BODY_2`, `_BODY_3` …). Adding a `page_keys` field to `DocumentDef` is a small follow-up if the UI needs it.
- The Beat 09 terminal also yields `JRN_CH1_REPEATS` (theory). The UI/scene adds it when page 2 is viewed, since a DocumentDef only carries one journal entry.

## Open canon questions (for Argon's review when available)
1. Is "Time doesn't stop. It waits." the right shared Elias/Operator phrase, or should it be subtler still?
2. Should the transit pass's "Clearance: LEVEL-0" stay? It foreshadows Beat 09 without stating it.
