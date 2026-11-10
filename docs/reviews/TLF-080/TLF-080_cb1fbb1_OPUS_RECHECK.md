# TLF-080 re-check: `cb1fbb1` (delta `db7efcf..cb1fbb1`)

Opus, 2026-11-11. Read-only. `origin/adityadaffa522/tlf-080-concourse-v2` at `cb1fbb1` (code in `b2cd1b8`).

**Method:** renamed scratch copy ("TLF Verify rev080-cb1fbb1"), headless import 0 ERROR. Every Godot call had a hard 120 s cap and no `--eval`. Nothing was merged; the real save was not touched.

**Evidence:** `TLF-080/cb1fbb1/`.

## Verdict: **APPROVE**

## What changed

- **The conduit moves with its state.** `ConduitProp._update_position()` puts `conduit_01` at **(328,184)** when fallen, at the gate contact, and at **(144,160)** when mounted, on the W wall.
- **It runs** in `_ready()`, `apply_state()` (Rewind, reset, load and room cache all go through it) and `_apply_solved_state()`.
- **Presenter positions:** fallen PNG top-left (304,158); mounted (112,102), per `mount_correction.json`.
- **Tests:** the playthrough and audio spots follow the conduit, the suite gains a lifecycle test and module asserts, and the baseline and manifest change for this room only.

## Checks

**1. TEST-AU-08 (probe, real colliders):**

| From | Trace target | Courier | Trace anchor | Conduit |
|---|---|---|---|---|
| (304,184) | `n05_courier` | 17.9 px | 26.8 px | 24.0 px |
| (312,188) | `turnstile_trace_anchor` | — | 17.9 px | 16.5 px |
| spawn (224,144) | courier | — | — | — |

At (312,188) the conduit is nearer than the trace anchor but is not a Trace candidate, so the anchor wins. The suite now asserts both clauses too.

**2. Rewind order (real input):**
- **Gate first:** at the gate spot (298,198) the Rewind target is `turnstile_gate`, refused `pinned`.
- **Conduit:** at the conduit spot (320,168) the target is `conduit_01`; Rewind gives `mounted` at **(144,160)**.
- **Gate again:** back at the gate spot the target is the gate, and Rewind opens it.

**3. Reset drops the conduit back:** `reset_anchor_01` (use) puts it fallen at **(328,184)** and the gate blocked again.

**4. Save and load:**
- **Saved slot:** autosave at `ch01.cp.concourse_west` with the conduit mounted and the gate closed; the slot holds the conduit's temporal entry (cursor 0 = mounted).
- **Continue into a fresh Chapter01:** `restore_from_save` ok; concourse; conduit **mounted at (144,160)**, presenter top-left **(112,102)**.
- **Room re-entry** (temporal cache): mounted at (144,160).
- **Note:** read after physics frames only, the presenter still showed the previous transform. It refreshes in `_process` before each render, so after an idle frame it is correct. That is a probe timing artifact, not a rendered defect.

**5. Tests on `cb1fbb1`** (each its own Godot call, ≤ 120 s):

| File | Result |
|---|---|
| `test_ch01_concourse_west_v2` | 12/0 |
| `test_ch01_real_playthrough` | 1/0 |
| `test_ch01_step1_negatives` | 12/0 |
| `test_step1_r1_deltas` | 39/0 |
| `test_ch01_art_integration` | 6/0 |
| `test_ch01_sort_order` | 3/0 |
| `test_audio_real_input` | 2/0 |
| `test_ch01_playthrough` | 19/0 |
| `test_ch01_unlock_guards` | 4/0 |

All have 0 SCRIPT ERROR and 0 ERROR.

**6. Mutations (`mutations_cb1fbb1.log`).** Baseline 12/0; restored 12/0. The stubbed files are identical afterwards.

| Stub | Result |
|---|---|
| `WallN_7` +1 px | **RED** |
| `WallN_8` +1 px | **RED** |
| `WallN_9` +1 px | **RED** |
| `WallW_1` +1 px | **RED** |
| `POS_FALLEN` +1 px | **RED** |
| `apply_state()` without `_update_position()` | **RED** |

My round-2 P2 (module transforms not asserted) is **closed**.

## P3 (not blocking)

- **Hard-coded positions:** `POS_FALLEN`/`POS_MOUNTED` are constants in the shared `ConduitProp` class. Only `concourse_west` uses it today, but a second conduit anywhere would be moved to these coordinates, and so is every `ConduitProp.new()` in unit rigs (harmless, since they don't check position). Exported per-instance positions set in the scene would be safer.
- **AU-08 margin:** at (312,188) the conduit sits 1.4 px nearer than the trace anchor. That only matters if the conduit is ever made traceable.
