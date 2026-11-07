# Asset Inventory

Track all production assets here. Concept art is not automatically production-ready.

| Asset ID | Name | Chapter/Area | Type | Status | Source/Owner | Notes |
|---|---|---|---|---|---|---|
| ENV-001 | Forgotten Station modular tileset | Chapter 1 | Environment | IN PROGRESS: 3 floor tiles, 2 wall modules, 1 archway exported | Argon (`assets/source/ch01/*.pxo`) | v1 pieces verified (Pixelorama CLI, palette-only, 0 semi-alpha). Remaining kit per `design/ch01/ROOM_GRAPH.md` §7 |
| ENV-002 | Station platform background layers | Chapter 1 | Background | NOT STARTED | TBD | Parallax/layer depth |
| CHAR-001 | Elias directional sprites | Global | Character | exported (v1) | Argon (`ch01_char_elias_base_sheet.pxo`) | 8 directions (5 authored + 3 exact mirrors), idle 4f @ 8 FPS, walk 6f @ 10 FPS, 32×48, pivot (16,44). Polish: stronger walk stride, silhouette detail (ISSUE-012) |
| CHAR-002 | Mira portrait/sprite | Chapters 2–6 | Character | NOT STARTED | TBD | Timeline variants may be needed |
| PROP-001 | Pocket watch | Global | Prop/UI | NOT STARTED | TBD | Central visual motif |
| VFX-001 | Temporal rewind effect | Global | VFX | NOT STARTED | TBD | Pixel-aligned and readable |
| VFX-002 | Echo playback effect | Global | VFX | NOT STARTED | TBD | Distinguish echo from active character |
| UI-001 | Pocket watch interface | Global | UI | NOT STARTED | TBD | Ability selection and energy |
| UI-002 | Journal interface | Global | UI | NOT STARTED | TBD | Clues, documents, memory fragments |
| PAL-001 | Ch1 master palette TLF-CH01-32 | Chapter 1 | Palette | exported | Argon (`ch01_palette_elysium09.gpl/.pxo`) | 32 colours; every Ch1 asset verified against it |
| ENV-T01 | Arrival platform target sheet | Chapter 1 | Target composition | exported | Argon | 640×360 art-direction target, not a runtime asset |
| PROP-002 | Digital clock 23:59 | Chapter 1 | Prop | exported | Argon | 32×24, pivot (16,20) |
| UI-003 | TLF Pixel Mono font | Global | UI font | exported | Argon (CC0, `assets/ui/fonts/LICENSE.txt`) | 5×7 in 6×8 cell; import: no AA/hinting/subpixel |
| AUD-001 | Clock motif and 23:59 tick | Chapter 1 | Audio | exported | Flash (`tools/audio/gen/gen_sfx.py`, CC0 synthesized) | 22050 Hz mono 16-bit WAV, `sfx_clock_tick.wav` |
| AUD-002 | Temporal Ability SFX Suite | Global | Audio | exported | Flash (`tools/audio/gen/gen_sfx.py`, CC0 synthesized) | Trace, Rewind, Freeze, Echo record start/stop, Echo play, Ability locked |
| AUD-003 | Operator Motif & Sighting Sting | Chapter 1 | Audio | exported | Flash (`tools/audio/gen/gen_sfx.py`, CC0 synthesized) | Faint second watch tick for VOICE (`sfx_operator_motif.wav`), sighting vanish sting (`sfx_operator_sighting.wav`) |
| AUD-004 | Street Device Latch Click | Chapter 1 | Audio | exported | Flash (`tools/audio/gen/gen_sfx.py`, CC0 synthesized) | Beat 10 street device click (`sfx_device_click.wav`) |

## Asset acceptance checklist

- Correct visual style and pixel density.
- Readable at actual gameplay resolution.
- Consistent palette and lighting direction.
- Correct pivot/origin and collision metadata where applicable.
- Modular/reusable where appropriate.
- Imported and tested in Godot.
- Source/license recorded.
- File named with stable ID.
- No placeholder mislabeled as final.
