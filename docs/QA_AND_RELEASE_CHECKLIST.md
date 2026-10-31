# QA & Release Checklist

## Project integrity
- [ ] Opens in the declared Godot 4.x version without parse/import errors.
- [ ] No missing resources, invalid node paths or orphaned critical assets.
- [ ] No debug-only code or test shortcuts in the release path.
- [ ] Project starts at the intended main scene.

## Gameplay
- [ ] Player cannot leave intended playable bounds.
- [ ] Interactions are readable and deterministic.
- [ ] Puzzle state survives scene transitions where intended.
- [ ] Reset/recovery works; no permanent soft-lock from temporal energy depletion.
- [ ] Temporal Echo replays timestamped events deterministically.
- [ ] Spatial graph, rendered geometry, collision, navigation and interaction anchors stay synchronized.
- [ ] Hints are optional, progressive and do not reveal solutions prematurely.

## Save/load
- [ ] Save format is versioned.
- [ ] Stable IDs are used; no live Node references are serialized.
- [ ] Missing/old fields receive safe defaults.
- [ ] Corrupt save fails gracefully and does not crash the game.
- [ ] Save/load tested across a scene transition and puzzle state change.

## Art/audio
- [ ] Pixel density and palette remain consistent.
- [ ] Nearest-neighbor scaling is used where required.
- [ ] Sprite pivots, sorting, collision and interaction anchors align.
- [ ] Pixelorama (.pxo) source and exported files match inventory metadata.
- [ ] Audio levels, subtitle timing and accessibility cues are checked.

## Performance/accessibility
- [ ] Target baseline: 1080p / 60 FPS on agreed minimum PC.
- [ ] No sustained frame spikes from echo replay, particles or room transitions.
- [ ] Remappable controls and controller navigation tested.
- [ ] Text-size option, subtitles and color-independent puzzle cues tested.
- [ ] Reduced screen-effects option tested.

## Release
- [ ] Version/build number recorded.
- [ ] Known issues documented with severity and workaround.
- [ ] Clean build exported and launched on a clean test profile.
- [ ] Save directory and settings behavior verified.
- [ ] Release notes and credits/licensing completed.
