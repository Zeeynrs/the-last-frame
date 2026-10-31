# Art Pipeline — Premium HD Cinematic Pixel Art

## Visual direction

Isometric 2.5D premium cinematic pixel art. Dense but readable environments; restrained palette shifts by chapter; controlled bloom/glow; layered parallax; fog, rain, particles and temporal distortion. Pixel art must remain pixel-aligned and use consistent density. Do not switch to low-poly 3D.

## Source of truth

- Editable art source: `.pxo` (Pixelorama) owned by Argon.
- Runtime deliverables: PNG, spritesheets, JSON/tag metadata as appropriate.
- Runtime implementation/import: Flash.
- Art direction and integration approval: Opus.
- Blender: blockout, isometric camera/layout reference, lighting/animation reference only; not final rendered 3D game assets.
- AI-generated images: concept references only unless manually rebuilt and checked for consistency/licensing.

## Asset workflow

1. Argon creates an asset brief: purpose, dimensions, pivot, palette, animation tags, collision/interaction requirements.
2. Argon creates `.pxo` (Pixelorama) source and exports runtime files.
3. Argon records source/export filenames, dimensions, frame rate, tags, palette and license/source.
4. Flash imports exported files, configures filtering/compression, pivots, sorting, collision and scene references.
5. Flash tests in the actual isometric scene; reports alignment/readability issues.
6. Argon revises source; Flash reimports. No other agent edits the source file concurrently.
7. Opus approves visual consistency and marks inventory status.

## Naming convention

`<chapter>_<category>_<asset>_<variant>_<state>.<ext>`

Examples: `ch01_env_platform_north_idle.pxo`, `ch01_prop_terminal_damaged.png`, `ch01_fx_temporal_rift_loop.png`.

## Required metadata

- Asset ID and filename
- Category and chapter/room
- Pixel dimensions and intended in-game scale
- Pivot/origin and sorting layer
- Animation frame count, FPS and tags
- Palette ID and color constraints
- Collision/interaction footprint if any
- Source file and export paths
- License/source attribution
- QA state: concept / source-created / exported / imported / tested / approved

## Visual QA

- Silhouette readable at gameplay zoom.
- Pixel density consistent with adjacent assets.
- No accidental subpixel blur or inconsistent outlines.
- Character feet/pivots align with isometric floor plane.
- Shadows and light direction match scene.
- Effects do not obscure clues or interaction prompts.
- Sprite sheet dimensions and frame order verified in Godot.
