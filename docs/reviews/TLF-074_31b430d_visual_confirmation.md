# TLF-074 — APPROVE VISUAL

Sol, 2026-11-10. Reviewed **`31b430d45e36d07251e02896f0cc252d66f802e1`**, `agent/opus-core-tlf074`. Approval is for the side-view SpriteFrames integration and cadence requested by Lead, not the future TLF-076 scene composition or a full gameplay review.

- **Tags / frame order: PASS.** Loaded the real `scenes/player/elias_side_sprite_frames.tres` in Godot. E: `idle_e` cells 0–1, `walk_e` 2–7, `interact_e` 8–10. W: 11–12, 13–18, 19–21 respectively. All 22 atlas regions are 32×48 with duration 1. Idle/walk loop; neutral reach is one-shot. The native strip shows the two breathing poses, six ordered stride poses and reach → inspect → return without a watch-check.
- **Mirrors: PASS.** The PNG is byte-identical to approved TLF-075 `76e63bf`; all 11 W cells are pixel-exact horizontal E mirrors. W uses these baked cells, without an additional flip.
- **Foot pivot: PASS.** The actual Player scene's centred 32×48 sprite at `(0,-20)`, offset `(0,0)`, gives texture top-left `(-16,-44)` relative to the actor: nominal foot pivot `(16,44)`. Both rows stay registered to the drawn foot baseline.
- **Idle cadence: keep 2 fps.** This is the approved runtime choice: 0.5 s per pose, one complete two-pose cycle per second. A 10 fps two-frame idle would repeat five cycles per second and read as a twitch rather than quiet breathing. The one-pixel head/coat change with planted boots suits the slower cadence. Walk at 10 fps (0.6 s cycle) and neutral reach at 10 fps (0.3 s, non-looping) are visually acceptable.

The §13 inventory's `22f @ 10 FPS` describes the sheet globally and should not force every runtime tag to 10 fps. The PXO also has older preview annotations `8fps_loop` for idle and `12fps_oneshot` for interact. This review explicitly approves **runtime idle 2 / walk 10 / interact 10 fps, both directions**. During integration, add those runtime rates to the metadata note to remove ambiguity; no sprite redraw or regeneration is requested by this confirmation.

Fresh renamed archive, separate custom user directory; import and Windows D3D12 Forward+ 960×540 strip capture exit 0, without engine/script errors. Runtime checks cover all six tags, counts, atlas regions, durations, loop flags and pivot calculation. Real save/settings inventory, hashes, sizes and mtimes unchanged (139 files). No product edits; no merge.

Evidence: [native loaded-resource strip](TLF-074/31b430d/side_frames_native.png), [capture log and independent checks](TLF-074/31b430d/evidence.txt).
