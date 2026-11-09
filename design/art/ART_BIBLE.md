# THE LAST FRAME — Production Art Bible ("Premium HD Cinematic Pixel Art")

**Task:** TLF-010  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Architecture Baseline:** `docs/ADR_LOG.md` (ADR-003, ADR-004, ADR-008, ADR-014, ADR-015; canvas superseded by ADR-023 addendum 3), `docs/ART_PIPELINE.md`, `design/ch01/ROOM_GRAPH.md`

---

> **Art Direction Enhancement — 2026-11-10 (proposed review, not automatically approved)**  
> This revision preserves the existing technical/art production contract in Sections 1–8 and Appendices A–C, and adds Appendix D: a production-focused visual quality framework. It does **not** authorize new assets, code modifications, scene restructuring, replacement of Elias v2, new palette entries, or a new lighting system. Opus/Lead approves any implementation; Argon authors assets (Sol is the fallback, ADR-017 amendment); Sol reviews visual proofs. Canvas and camera follow ADR-023 addenda 3-4 (`960 × 540`) and ADR-025 (a view mode per room). **Current production priority: finish Chapter 1.**

---

## 1. Resolution, Projection, Pixel Density & Grid Metrics (`ADR-003`)

### 1.1 Viewport & Scaling Standard
| Parameter | Exact Value | Notes / Engine Binding |
|---|---|---|
| **Internal Authoring Canvas** | **`960 × 540 px`** (`16:9`, ADR-023 addendum 3) | `display/window/size/viewport_width = 960`, `viewport_height = 540` |
| **Default Window Output** | **`1920 × 1080 px`** (`×2` integer scale) | `stretch/mode = "viewport"`, `stretch/scale_mode = "integer"`, `aspect = "keep"` |
| **Supported Integer Multipliers** | `×1` (`960×540`), `×2` (`1920×1080`), `×3` (`2880×1620`), `×4` (`3840×2160`) | Zero fractional scaling; unused window area is letterboxed. A `1280×720` window uses `×1`, with `160 px` side borders and `90 px` top/bottom borders. |
| **Texture Filtering & Pixel Snap** | **`Nearest`** + **`2D Transform Snap = true`** | `default_texture_filter = Nearest`, `snap_2d_transforms_to_pixel = true` |
| **Renderer** | **Forward+** (`Compatibility` fallback) | Supports 2D HDR glow, bloom, and GPU particle overlays without blurring base sprites |

Sprites retain their native dimensions: a `32 × 48 px` character frame is about **9% of the 540 px screen height**. At 1080p, art and UI scale `×2`; UI glyphs appear one third smaller than under the former `×3` output. A separate UI scale remains a follow-up decision (ADR-023 addendum 3).

### 1.2 Isometric Projection & Pixel Density
- **Projection:** **2:1 Dimetric Isometric** (`±2 px` horizontal step per `±1 px` vertical step along floor diamond edges; floor axis angle = $\arctan(0.5) \approx 26.565^\circ$).
- **Logical Grid Unit (`1 × 1` Tile):** **`32 × 16 px`** diamond (`1.0 m × 1.0 m` world floor footprint).
  - Top vertex: `(16, 0)` · Right vertex: `(31, 7..8)` · Bottom vertex: `(16, 15)` · Left vertex: `(0, 7..8)` · Geometric center pivot: **`(16, 8)`**.
- **Room Screen Mapping (`ROOM_GRAPH.md` §1):**
  $$\text{px\_x}(x, y) = 320 + (x - y) \times 16, \qquad \text{px\_y}(x, y) = 64 + (x + y) \times 8$$
- **Vertical Pixel Density:** **`24 px = 1.0 m` vertical height** (`1 px ≈ 4.17 cm` vertical; `48 px = 2.0 m` vertical wall/frame height).

### 1.3 Character, Tile, Wall & Prop Size Table Against the `32 × 16` Grid

| Asset Class | Grid Footprint (`W × H` Tiles) | Canvas Size (`W × H px`) | Active Silhouette (`W × H px`) | Pivot / Origin `(px_x, px_y)` | Godot `z_index` / Sorting Layer | Examples |
|---|---|---|---|---|---|---|
| **Playable / NPC Humanoid (`Elias`, `Mira`, `Echo`)** | `1 × 1` (`0.45 m` radius) | **`32 × 48 px`** | **`14 × 42 px`** (`y = 3..44` standing; `1.75 m` @ `24 px/m`) | **`(16, 44)`** *(boot sole center; `offset = (-16, -44)`)* | `z_index = 10` (`YSort_Actors`, `y_sort_enabled = true`) | `ch01_char_elias_base_sheet.png` |
| **Base Floor Tile (`1 × 1` flush)** | `1 × 1` | **`32 × 16 px`** | `32 × 16 px` (`256 px` diamond area) | **`(16, 8)`** *(tile diamond center)* | `z_index = 0` (`TileMapLayer_Floor`) | `ch01_env_tile_terrazzo_dark_idle.png`, `ch01_env_tile_terrazzo_cracked_idle.png`, `ch01_env_tile_tactile_amber_idle.png` |
| **Boundary Wall Module (`N` or `W`)** | `1 × 1` boundary edge | **`32 × 64 px`** | `32 × 64 px` (`48 px` vertical wall = `2.0 m` + `16 px` iso slope; clears Elias by `+6 px`) | **`(16, 56)`** *(center of `32×16` base diamond at `y = 48..63`)* | `z_index = 5` (`TileMapLayer_Walls` / `YSort_Walls`) | `ch01_env_wall_subterranean_n_idle.png`, `ch01_env_wall_subterranean_w_idle.png` |
| **Doorway Archway Frame (`N/S/E/W`)** | `1 × 1` boundary tile | **`32 × 64 px`** | `32 × 64 px` outer · **`20 × 42 px` clear portal opening** (`6 px` steel jambs, `11 px` lintel + transom glyph) | **`(16, 56)`** *(threshold floor center)* | `z_index = 6` (`YSort_Walls`) | `ch01_env_archway_frame_e_idle.png` |
| **Low Trench / Mezzanine Railing** | `1 × 1` edge | **`32 × 48 px`** | `32 × 38 px` (`22 px` vertical iron rail ≈ `0.92 m` waist height + `16 px` iso slope) | **`(16, 40)`** | `z_index = 8` (`YSort_Props`) | `wall_railing_iron` |
| **Micro / Floor Pickup Prop** | `0.5 × 0.5` | **`16 × 16 px`** | `10 × 8 px` to `12 × 12 px` | **`(8, 12)`** | `z_index = 8` (`YSort_Props`) | `global.pocket_watch` pickup, `prop_document_clipboard` |
| **Small Wall / Suspended Fixture** | `1 × 1` wall-mounted | **`32 × 24 px`** | `30 × 21 px` | **`(16, 20)`** *(bottom casing mount)* | `z_index = 7` (`Wall_Fixtures`) | `ch01_prop_digital_clock_2359_idle.png` (`32 × 24 px`), `prop_call_box_phone` (`24 × 36 px`), `prop_lever_switch` (`24 × 32 px`) |
| **Medium Floor Prop / Console** | `1 × 1` to `1.5 × 1` | **`32 × 36 px`** to **`48 × 32 px`** | `28 × 32 px` to `44 × 28 px` | **`(W/2, H - 6)`** | `z_index = 10` (`YSort_Actors`) | `prop_reset_console` (`32 × 36 px`), `prop_turnstile_gate` (`32 × 40 px`), `prop_station_bench` (`48 × 32 px`) |
| **Large Hero Mechanism / Set-Piece** | `2 × 1` to `4 × 2` | **`64 × 64 px`** to **`128 × 80 px`** | `60 × 58 px` to `124 × 74 px` | **`(W/2, H - 8)`** | `z_index = 10` (`YSort_Actors`) | `prop_fire_shutter` (`64 × 64 px`), `prop_surge_capacitor` (`64 × 64 px`), `prop_dispatch_terminal` (`64 × 64 px`), `prop_transit_car_stalled` (`128 × 80 px`) |

---

## 2. Character Proportions, Direction Count & Mirroring Rule (`Elias`)

### 2.1 Elias 4-Head Vertical Proportion (`32 × 48 px` Frame)
- **Top Headroom (`y = 0..2`, `3 px`):** Reserved for walk-cycle vertical bob (`±1 px`) and overhead status badges.
- **Head & Hair (`y = 3..12`, `10 px`):** Tousled espresso-brown hair (`#231B18` / `#3B2D26`) and key-lit face (`#E0B494` lit cheek, `#B88A6C` shadow cheek, `1 px` `#0A0D14` eyes).
- **Upper Torso, Coat Lapels & Arms (`y = 13..30`, `18 px`):** Weathered umber trench coat (`#7D614F` NW shoulder highlight, `#594438` mid-body, `#3B2D26` shadow fold) over a dark slate collar (`#1F2838`), with a `3 px` glinting brass pocket-watch chain (`#EB8A28` / `#FFD166`) at the waist (`y = 26..27`).
- **Coat Hem, Trousers & Boots (`y = 31..44`, `14 px`):** Coat tails (`y = 31..36`) over dark boots (`#231B18` / `#3B2D26`) planting at **`(16, 44)`**.
- **Bottom Margin (`y = 45..47`, `3 px`):** Front toe step clearance and `14 × 6 px` isometric floor shadow ellipse (`#141A26` / `#0A0D14`).

### 2.2 Direction Count (`8 Directions`) & Mirroring Specification
- **Chosen Direction Count:** **`8 directions`** (`S`, `SE`, `E`, `NE`, `N`, `NW`, `W`, `SW`).
- **Unique Authored Directions (`5`):** **`S`**, **`SE`**, **`E`**, **`NE`**, **`N`**.
- **Horizontally Mirrored Directions (`3`):**
  - **`SW` (`(-2, +1).normalized()`)** $\Longleftarrow$ Horizontal mirror (`flip_h`, $x' = 31 - x$) of **`SE` (`(+2, +1).normalized()`)**
  - **`W` (`(-1, 0)`)** $\Longleftarrow$ Horizontal mirror (`flip_h`, $x' = 31 - x$) of **`E` (`(+1, 0)`)**
  - **`NW` (`(-2, -1).normalized()`)** $\Longleftarrow$ Horizontal mirror (`flip_h`, $x' = 31 - x$) of **`NE` (`(+2, -1).normalized()`)**

| Direction Tag Suffix | Velocity Vector in `Player.compute_movement_vector` (`scripts/player/player.gd`) | Screen Angle | Authored vs. Mirrored | Idle Frames (`1`-based in `.pxo`) | Walk Frames (`1`-based in `.pxo`) |
|---|---|---|---|---|---|
| **`s`** | `(0.0, +1.0)` | `+90.0°` (Down) | **Unique Authored #1** | `1..4` (`idle_s`) | `5..10` (`walk_s`) |
| **`se`** | `(+0.8944, +0.4472)` (`+x` tile axis) | `+26.6°` (Down-Right) | **Unique Authored #2** | `11..14` (`idle_se`) | `15..20` (`walk_se`) |
| **`e`** | `(+1.0, 0.0)` | `0.0°` (Right) | **Unique Authored #3** | `21..24` (`idle_e`) | `25..30` (`walk_e`) |
| **`ne`** | `(+0.8944, -0.4472)` (`-y` tile axis) | `-26.6°` (Up-Right) | **Unique Authored #4** | `31..34` (`idle_ne`) | `35..40` (`walk_ne`) |
| **`n`** | `(0.0, -1.0)` | `-90.0°` (Up) | **Unique Authored #5** | `41..44` (`idle_n`) | `45..50` (`walk_n`) |
| **`nw`** | `(-0.8944, -0.4472)` (`-x` tile axis) | `-153.4°` (Up-Left) | **Mirrored from `ne`** (`flip_h`) | `51..54` (`idle_nw`) | `55..60` (`walk_nw`) |
| **`w`** | `(-1.0, 0.0)` | `180.0°` (Left) | **Mirrored from `e`** (`flip_h`) | `61..64` (`idle_w`) | `65..70` (`walk_w`) |
| **`sw`** | `(-0.8944, +0.4472)` (`+y` tile axis) | `+153.4°` (Down-Left) | **Mirrored from `se`** (`flip_h`) | `71..74` (`idle_sw`) | `75..80` (`walk_sw`) |

### 2.3 Justification Against 8-Direction Movement
1. **Zero Angular Foot-Sliding:** `Player.compute_movement_vector` (`scripts/player/player.gd`) maps `WASD`/stick input to 8 discrete vectors: 4 along the `2:1` isometric room axes (`SE`, `SW`, `NE`, `NW`) and 4 along the screen cardinal axes (`N`, `S`, `E`, `W`). A 4-direction sprite set creates a `26.6°` to `63.4°` angular mismatch whenever the player traverses a room horizontally (`E/W`) or vertically (`N/S`), making feet appear to skate sideways. Providing all 8 directions guarantees `0.0°` discrepancy between movement vector and stride orientation.
2. **Bilateral Projection Symmetry (`37.5%` Scope Reduction):** In a `2:1` dimetric projection, the camera view plane is bilaterally symmetric across the vertical screen centerline (`x = 16`). Consequently, `SW`, `W`, and `NW` are exact geometric reflections of `SE`, `E`, and `NE`. Authoring `5` canonical directions and mirroring `3` saves `37.5%` of character frame production (`50` unique frames instead of `80`) while preserving full 8-way responsiveness.
3. **Baked Spritesheet Convenience:** All `80` frames (`50` unique + `30` mirrored) are exported in `ch01_char_elias_base_sheet.png` (`2560 × 48 px`), allowing Flash's `AnimatedSprite2D` controller to look up `idle_<dir>` and `walk_<dir>` uniformly without conditional `flip_h` branching.
4. **Documented Horizontal Mirror (`flip_h`) Compromises:**
   - **Screen-Space Key-Light Flip on Mirrored Directions (`SW`, `W`, `NW`):** Because top-left key-light shading (`#7D614F` lit coat shoulder, `#E0B494` lit cheek) and the `1 px` floor-shadow offset are baked into the authored `SE`, `E`, and `NE` frames, horizontally flipping (`x' = 31 - x`) those frames to produce `SW`, `W`, and `NW` flips the baked highlight to the screen-right side of Elias on those three directions.
   - **Asymmetric Costume Details Swap Sides:** Subtle asymmetric costume accents—specifically the `3 px` brass pocket-watch chain glint at the waist (`y = 26..27`) and coat lapel overlap—swap between Elias's left and right side when mirrored. At the `32 × 48 px` sprite scale (`14 × 42 px` active silhouette), this standard 2D isometric pixel-art compromise (`ADR-014`) is visually unobtrusive and saves `30` hand-drawn frames.

---

## 3. Chapter 1 Master Palette (`TLF-CH01-32`) & Material Ramps

All Chapter 1 sprites, tiles, props, UI elements, and target compositions are strictly constrained to the **32-color `TLF-CH01-32` palette** (`assets/source/ch01/ch01_palette_elysium09.gpl` / `.pxo` / `.png`) plus binary transparent background (`#00000000`).

### 3.1 Complete 32-Color Ramp Specification

| Index | Hex | RGB `(R, G, B)` | Swatch Name | Material Ramp & Primary Usage |
|---|---|---|---|---|
| **`00`** | `#0A0D14` | `(10, 13, 20)` | *Abyssal Void* | **Ramp 1 (Void & Terrazzo Slate):** Universal `1 px` interior dark outline, unlit tunnel void, UI panel fill |
| **`01`** | `#141A26` | `(20, 26, 38)` | *Sub-Line Shadow* | **Ramp 1:** Cast shadows, floor mortar seams, recessed window interiors |
| **`02`** | `#1F2838` | `(31, 40, 56)` | *Terrazzo Dark Base* | **Ramp 1:** Primary dark terrazzo platform floor slab |
| **`03`** | `#2D394F` | `(45, 57, 79)` | *Terrazzo Mid* | **Ramp 1:** Terrazzo mineral flecks, NE floor bevel, weathered concrete mid |
| **`04`** | `#3F4F6B` | `(63, 79, 107)` | *Terrazzo Highlight* | **Ramp 1:** NW key-lit floor tile bevel, fracture crack lip highlight |
| **`05`** | `#586C8F` | `(88, 108, 143)` | *Specular Stone* | **Ramp 1:** Wet stone step rim glint, polished terrazzo specular peak |
| **`06`** | `#19232E` | `(25, 35, 46)` | *Wall Mortar Shadow* | **Ramp 2 (Subterranean Ceramic Wall):** NE wall grout lines, deep cornice shadow |
| **`07`** | `#263545` | `(38, 53, 69)` | *Ceramic Tile Dark* | **Ramp 2:** Shaded NE wall ceramic face (`Step -1`), NW wall mortar grout |
| **`08`** | `#364B5E` | `(54, 75, 94)` | *Ceramic Tile Mid* | **Ramp 2:** Key-lit NW wall ceramic face (`Step 0`), NE tile top glaze |
| **`09`** | `#4B667D` | `(75, 102, 125)` | *Ceramic Tile Light* | **Ramp 2:** Upper wall cornice plane, NW ceramic bevel highlight |
| **`10`** | `#6888A3` | `(104, 136, 163)` | *Glazed Ceramic Specular* | **Ramp 2:** NW wall top cornice edge (`Step +1`), glazed tile corner glint |
| **`11`** | `#1B1E24` | `(27, 30, 36)` | *Cast Iron Dark* | **Ramp 3 (Brushed Steel & Cast Iron):** Skirting boards, heavy iron railings, shadow bevels |
| **`12`** | `#2E333D` | `(46, 51, 61)` | *Gunmetal Shadow* | **Ramp 3:** Shaded machinery casings, transit car body, curb steel |
| **`13`** | `#464E5C` | `(70, 78, 92)` | *Brushed Steel Mid* | **Ramp 3:** Archway pillars, `23:59` clock casing, UI inactive frame border |
| **`14`** | `#677385` | `(103, 115, 133)` | *Steel Bevel Light* | **Ramp 3:** NW machined steel edge highlight, bench seat plane |
| **`15`** | `#94A2B8` | `(148, 162, 184)` | *Chrome Specular* | **Ramp 3:** `1 px` top lintel & clock housing specular ridge |
| **`16`** | `#231B18` | `(35, 27, 24)` | *Espresso Hair / Boot Dark* | **Ramp 4 (Elias Character):** Elias hair base, boots, deep coat crease |
| **`17`** | `#3B2D26` | `(59, 45, 38)` | *Umber Coat Shadow* | **Ramp 4:** Elias coat shadow side (`SE`/`E`), hair crown mid-tone |
| **`18`** | `#594438` | `(89, 68, 56)` | *Weathered Brown Coat Mid* | **Ramp 4:** Elias trench coat primary body |
| **`19`** | `#7D614F` | `(125, 97, 79)` | *Coat Shoulder Light* | **Ramp 4:** Elias NW key-lit shoulder, lapel, and left sleeve |
| **`20`** | `#B88A6C` | `(184, 138, 108)` | *Skin Shadow / Warm Tan* | **Ramp 4:** Elias shaded cheek, right hand, leather watch strap |
| **`21`** | `#E0B494` | `(224, 180, 148)` | *Skin Key Light* | **Ramp 4:** Elias lit face plane and left hand |
| **`22`** | `#4A1C14` | `(74, 28, 20)` | *Dark Crimson Backlight* | **Ramp 5 (Ch1 Warning Amber & `23:59` Glow):** Unlit `23:59` LED matrix bed, blister stud shadow |
| **`23`** | `#8C2D19` | `(140, 45, 25)` | *Deep Hazard Amber-Red* | **Ramp 5:** `23:59` digit outer glow halo, recessed hazard strip |
| **`24`** | `#CC4E1E` | `(204, 78, 30)` | *Emergency Sodium Orange* | **Ramp 5:** Wall dado emergency stripe, lower LED segment tone |
| **`25`** | `#EB8A28` | `(235, 138, 40)` | *Tactile Safety Amber* | **Ramp 5:** Tactile platform studs, brass pocket watch casing, `23:59` digit mid |
| **`26`** | `#FFD166` | `(255, 209, 102)` | *Incandescent Gold Peak* | **Ramp 5:** `23:59` digit hot core, pocket-watch chain glint, frozen dust motes |
| **`27`** | `#16425B` | `(22, 66, 91)` | *Temporal Deep Teal* | **Ramp 6 (Temporal VFX & UI):** `Freeze` deep aura shadow, temporal UI backdrop |
| **`28`** | `#287A9E` | `(40, 122, 158)` | *Chrono Cyan Mid* | **Ramp 6:** `Echo` ghost body mid-tone, `Rewind` trail secondary |
| **`29`** | `#4CE0D2` | `(76, 224, 210)` | *Aether Cyan-Mint* | **Ramp 6:** `Rewind` primary arc, active transom glyph `[◁]`, UI focus border |
| **`30`** | `#9E7BFF` | `(158, 123, 255)` | *Residual Trace Violet* | **Ramp 6:** `Trace` memory distortion ripple & past silhouette columns |
| **`31`** | `#EDF4FA` | `(237, 244, 250)` | *Frost / UI Crisp White* | **Ramp 6:** `Freeze` crystalline lock peak, primary HUD & dialogue text |

---

## 4. Station Light Direction & Planar Value Hierarchy

- **2D Screen-Space Key Light (`Screen Top-Left`, Screen Azimuth `315°`, Elevation `60°`):**
  - In 2D viewport coordinates, the primary directional key light originates from **Screen Top-Left (`-px_x, -px_y`)** at **`60°` elevation** above the floor plane and projects cast shadows **Screen Down-Right (`+2 px` X, `+1 px` Y)** along the `+x` (`SE`) isometric floor axis.
  - Every standalone prop, floor tile bevel, and uniquely authored character direction (`S`, `SE`, `E`, `NE`, `N`) receives its brightest highlight on its top and screen-left surfaces. *(Note: per §2.3 #4, Elias's horizontally mirrored `SW`, `W`, and `NW` frames invert this baked screen-left highlight to the screen-right shoulder as an accepted `flip_h` compromise.)*
- **Room-Axis Wall Convention vs. Physical Backface Lighting:**
  - In `ROOM_GRAPH.md` §1 (`px_x = 320 + (x - y) * 16`, `px_y = 64 + (x + y) * 8`), the visible top-left room boundary is the **West (`W`, `x = 0`) wall** whose interior face points **screen down-right (`+x`, `SE`)**, and the visible top-right room boundary is the **North (`N`, `y = 0`) wall** whose interior face points **screen down-left (`+y`, `SW`)**.
  - Rather than placing the `W` (`x = 0`) interior wall in physical backface shadow from an exterior top-left point light, Chapter 1 uses an **interior overhead planar value convention** (representing suspended station strip-luminaires inside the room volume biased toward the west ceiling): the screen-left `W` (`x = 0`) interior wall face is rendered at **Mid-Light (`Step 0`)** and the screen-right `N` (`y = 0`) interior wall face is rendered at **Mid-Dark (`Step -1`)**, guaranteeing a crisp `1`-step value contrast at the `(0, 0)` north-west room corner.
- **Mandatory Planar Value Separation (Minimum `1` Ramp Step Between Adjacent Isometric Planes):**
  1. **Horizontal Top Planes (Cornice Caps, Bench Seats, Console Tops, Character Head/Shoulders):** **Brightest (`Step +1`)** — e.g., `#6888A3` / `#4B667D` on wall cornices, `#94A2B8` / `#677385` on steel, `#7D614F` on Elias's key-lit coat shoulder.
  2. **West (`W`, `x = 0`, Screen-Left) Interior Wall Faces (facing South-East `+x`):** **Mid-Light (`Step 0`)** — e.g., `#364B5E` ceramic body with `#4B667D` / `#6888A3` top tile glaze (`ch01_env_wall_subterranean_w_idle.png`).
  3. **Horizontal Floor Slabs (`z_index = 0`):** **Controlled Dark-Mid (`#1F2838` / `#2D394F`)** — intentionally kept `2` value steps darker than character skin/coat highlights (`#E0B494` / `#7D614F`) and tactile amber (`#EB8A28`) so actors and puzzle cues pop with high contrast against the floor.
  4. **North (`N`, `y = 0`, Screen-Right) Interior Wall Faces (facing South-West `+y`):** **Mid-Dark (`Step -1`)** — e.g., `#263545` ceramic body with `#19232E` grout (`ch01_env_wall_subterranean_n_idle.png`).
  5. **Cast Shadows & Trenches:** **Darkest (`Step -2`, `#141A26` / `#0A0D14`)** — projected **`+2 px` X, `+1 px` Y** (screen down-right along the `SE` `+x` isometric axis) from every grounded actor and prop.

---

## 5. Outline, Anti-Aliasing (AA) & Dithering Rules

### 5.1 Outline Rule
- **Characters & Interactive/Standalone Props (`Elias`, `prop_digital_clock_2359`, levers, consoles, gates):**
  - Mandatory **`1 px` interior outline** using `#0A0D14` (*Abyssal Void*) on outer silhouettes, never exceeding `1 px` thickness and never using pure `#000000`.
- **Modular Floor Tiles & Wall Modules (`tile_*`, `wall_*`):**
  - **`0 px` outer silhouette outline** along shared tile seams so adjacent modules tile without visible grid cages.
  - Internal structural transitions use **`1 px` bevel highlights** (`#3F4F6B` on floors, `#6888A3` / `#94A2B8` on walls/steel) on NW-facing lips and **`1 px` dark mortar seams** (`#141A26` / `#0A0D14`) on SE-facing drops.

### 5.2 Anti-Aliasing (AA) Rule
- **External / Alpha-Edge AA:** **STRICTLY NONE (`0` semi-transparent pixels allowed).**
  - Every pixel in every exported PNG must have **binary alpha `A ∈ {0, 255}`**. Semi-transparent pixels (`1 ≤ A ≤ 254`) are prohibited to prevent dark/light halo artifacts under `Nearest` filtering and Y-sorted overlap.
- **Selective Internal AA:**
  - Allowed **only inside opaque regions** (`A = 255`) using existing `TLF-CH01-32` ramp colors (`max 1–2 px` intermediate buffer pixels on `23:59` LED digit glow halos `#8C2D19` or long diagonal rails).

### 5.3 Dithering Rule
- **Characters & Props (`≤ 64 × 64 px`):** **NONE (`0%` dithering).** Shading uses solid, readable pixel clusters (`≥ 2 px` width/height wherever geometry permits) so animations never shimmer.
- **Environment Tiles & Target Compositions:** **Restrained stipple / `2×2` Bayer dither (`≤ 4 px` transition band)** allowed only between adjacent ramp steps (`Step N` to `Step N+1`) on weathered terrazzo/concrete or suspended dust motes.

---

## 6. Animation Frame Rates (FPS) Per Category

All gameplay state runs on the deterministic `60 Hz` `SimClock` (`ADR-004`). Visual animations use exact integer/half-integer tick divisors:

| Animation Type | Target FPS | `SimClock` Ticks / Frame | Standard Frame Count | Cycle Duration | Loop Policy |
|---|---|---|---|---|---|
| **Character Idle (`idle_s` … `idle_sw`)** | **`8 FPS`** | `7.5 ticks` (`0.125 s`) | **`4 frames`** | `0.50 s` | Loop |
| **Character Walk (`walk_s` … `walk_sw`)** | **`10 FPS`** | `6.0 ticks` (`0.100 s`) | **`6 frames`** (`3f` per step) | `0.60 s` (`72 px` travel @ `120 px/s`) | Loop |
| **Pocket-Watch Cast / Interact** | **`12 FPS`** | `5.0 ticks` (`0.083 s`) | **`4 frames`** | `0.33 s` | One-shot |
| **Ambient Fixture Loops (`23:59` clock, conduits)** | **`6 FPS`** | `10.0 ticks` (`0.167 s`) | **`2–4 frames`** | `0.33–0.67 s` | Loop |
| **Mechanical Puzzle Transitions (Turnstile, Shutter, Gear)** | **`12 FPS`** | `5.0 ticks` (`0.083 s`) | **`4–6 frames`** | `0.33–0.50 s` | One-shot / Loop |
| **Temporal Ability VFX (`Rewind`, `Freeze`, `Trace`, `Echo`)** | **`15 FPS`** | `4.0 ticks` (`0.067 s`) | **`6–8 frames`** | `0.40–0.53 s` | One-shot / Loop |

---

## 7. Temporal VFX Color & Color-Independent Shape/Motion Language

Per `GDD.md` §15–16 and `ADR-014`/`ADR-015`, no temporal state may rely on color alone. Every ability combines a **dedicated palette pair**, a **distinct geometric icon/border shape**, and a **unique motion/line-pattern signature**:

| Ability / System | Palette Colors (`TLF-CH01-32`) | Non-Color Geometric Shape / Silhouette Cue | Non-Color Animation / Pattern Cue |
|---|---|---|---|
| **`Rewind`** (`&"rewind"`) | • Primary: `#4CE0D2` (`29` *Aether Cyan-Mint*)<br>• Secondary: `#287A9E` (`28` *Chrono Cyan Mid*) | **Counter-clockwise double-chevron ring (`«` / `↺`)** with inward-pointing triangular arrowheads around the target's bounding box. | **Upward reverse-scrolling horizontal scanlines** (`1 px` dashed bands rising at `-1 px/frame` @ `15 FPS`) + reverse frame stepping. |
| **`Freeze`** (`&"freeze"`) | • Primary: `#EDF4FA` (`31` *Frost White*)<br>• Secondary: `#16425B` (`27` *Temporal Deep Teal*) | **Rigid 6-point hexagonal crystal glyph (`❖`) + `2 px` solid `90°` corner L-brackets** clamping all four corners of the frozen object. | **Absolute `0 FPS` static hold:** zero internal motion, solid double-pixel perimeter lock (`no scanline scrolling`). |
| **`Trace`** (`&"trace"`) | • Primary: `#9E7BFF` (`30` *Residual Trace Violet*)<br>• Secondary: `#FFD166` (`26` *Incandescent Gold Peak*) | **Concentric diamond reticle (`◈`)** expanding outward from the anchor point (`turnstile_trace_anchor`, `route_board`, Mira's bench). | **Vertical column interlacing:** past silhouettes are rendered only on **even `X` columns** (`x % 2 == 0`) with a `±1 px` vertical wave at `8 FPS`. |
| **`Echo`** (`&"echo.0"`) | • Primary: `#287A9E` (`28` *Chrono Cyan Mid*)<br>• Outline: `#4CE0D2` (`29` *Aether Cyan-Mint*)<br>• Peak: `#EDF4FA` (`31` *Frost White*) | **Hollow-core silhouette (`1 px` bright outer rim over `#141A26` interior) + overhead tape transport badge** (`●` `RECORDING`, `▶` `PLAYING`, `❚❚` `HOLDING`). | **Horizontal row interlacing:** rendered on **even `Y` scanlines** (`y % 2 == 0`) + persistent `3`-dot isometric footprint trail on the floor. |

---

## 8. UI Scale & Pixel Font Specification (`960 × 540`)

### 8.1 UI Grid & HUD Scale at `960 × 540`
- **Authoring Canvas:** `960 × 540 px` (`1:1` pixel match with the gameplay viewport; scales `×2` to `1920 × 1080`, ADR-023 addendum 3).
- **Screen Safe Margin:** **`12 px`** inset from all four viewport edges (`active HUD box = (12, 12) to (948, 528)`).
- **Panel Construction:** Snap all panel positions and dimensions to a **`4 px` grid**; `1 px` outer border (`#464E5C` idle, `#4CE0D2` focused/active, `#EB8A28` warning), `#0A0D14` solid interior fill (`100%` opaque `A = 255`), and `4 px` internal text padding.
- **HUD Element Dimensions (`ADR-015`):**
  - **Top-Left Location / Status Bar:** `212 × 16 px` at `(12, 12)`.
  - **Top-Right Pocket-Watch & `23:59` Indicator:** `80 × 16 px` at `(868, 12)`; ability icon slots = `16 × 16 px` each (`Trace`, `Rewind`, `Freeze`, `Echo`).
  - **Bottom-Center Contextual Interaction Prompt (`[E] ...`):** `192 × 16 px`, top-left `(384, 510)`.
  - **World-Space Watch Target Highlight (`≤ 96 px` radius per `ADR-015`):** `12 × 12 px` floating ability badge centered `6 px` above the targeted `Interactable`'s top bound.

### 8.2 Pixel Font Specification
- **Font File:** `assets/ui/fonts/tlf_pixel_mono.ttf` (**TLF Pixel Mono Regular**).
- **License:** **CC0 1.0 Universal (Public Domain Dedication)** — committed at `assets/ui/fonts/LICENSE.txt` (original production font authored by Argon for *The Last Frame*).
- **Glyph Metrics:**
  - Native glyph matrix: **`5 × 7 px`** inside a **`6 × 8 px` monospace character cell** (`5 px` glyph width + `1 px` right tracking; `7 px` cap/ascender height + `1 px` descender/row gap; `unitsPerEm = 512` where `1 px = 64 font units`).
  - Allowed integer point/pixel sizes at `960 × 540` (`subpixel_positioning = disabled`, `antialiased = false`, `hinting = none`):
    - **`8 px` (`1×` native):** HUD badges, interaction prompts (`[E]`), subtitle/dialogue body (`96` characters max per `576 px` line; recommended `≤ 64` chars/line for comfort), Journal body text.
    - **`16 px` (`2×` integer multiple):** Room title cards, Journal section headers, Pause/Settings menu headings.
    - **`24 px` (`3×` integer multiple):** Chapter title cards (`CHAPTER 1 — THE FORGOTTEN STATION`) and ending summary headers.
  - **Accessibility Text Size Multiplier (`SD-1` / `GDD.md` §16):** `Small/Default (100%) = 8 px`, `Large (200%) = 16 px` (maintaining strict integer pixel alignment on the `960 × 540` canvas; `16 px` / `32 px` physical text cells respectively at 1080p `×2`).


---

## Appendix A — Additions from TLF-039 / TLF-042 (ADR-019)

Added by the design-art agent (Claude Code, Sonnet 5.5). Nothing above is changed; this appendix only adds rules that production exposed.

### A.1 Sorting rule for props (OQ-2, ADR-019)
§1.3 puts small fixtures (`prop_call_box_phone`, `prop_lever_switch`) in `Wall_Fixtures` (`z_index = 7`). A fixture that is **mounted on a drawn wall** stays at `z_index = 7`. Anything that **stands free on the floor** (junction levers, mid-room breakers, reset consoles, benches, hero mechanisms, security gate, route board, dispatch terminal, transit car) goes into `YSort_Actors` (`z_index = 10`, Y-sorted by pivot), so Elias draws behind it when he stands north of it. Floor-level surfaces Elias walks over (`prop_bridge_platform`, `prop_pressure_switch`) stay in `YSort_Props` (`z_index = 8`), below Elias. The placement sheet lists the effective layer per object.

### A.2 Elias palette index 03
Elias v2 uses palette index `03` (`#2D394F`, *Terrazzo Mid*) as the trouser highlight (trousers are `02`/`03`, boots `16`/`17`). It belongs to `TLF-CH01-32`, so the 32-colour rule is unchanged; Elias now uses 12 of 32 colours.

### A.3 Pivots of the sizes that §1.3 does not list

**Owner decision, 2026-11-09 (TLF-078): the frontal wall-fixture allowance is withdrawn.** Every wall-mounted fixture, including its text and state variants, must pass three tests at native scale: **(1) follows the wall's 2:1 slope**, by pixel shear or correctly facing isometric art; **(2) sits flush on the actual wall face**, using a documented pivot/anchor; **(3) stays inside the wall silhouette**, with no opaque housing, text or mount shadow above the top or across the foot. Raising a frontal sprite or changing its z does not satisfy these tests.

| Asset class | Canvas | Pivot rule | Used by |
|---|---|---|---|
| Wall-mounted fixture (face-specific) | sized for the projected face | document the actual wall mount, pivot and offset; shear may change all three (TLF-073 examples) | clocks, selectors, phones, speakers, panels, signs/notices |
| Free-standing small prop | `W × H` | `(W/2, H - 4)` | `prop_lever_switch` 24×32 → `(12,28)` |
| Floor plate | `W × H` | footprint centre | `prop_pressure_switch` 32×20 → `(16,12)` |
| Large hero mechanism / set-piece | any | **projected footprint centre at floor level** (the point the Y-sort and node position refer to) | gear/capacitor/shutter/terminal 64×64 → `(32,56)`, `prop_transit_car_stalled` 128×80 → `(64,52)`, `prop_bridge_platform` 48×32 → `(24,18)` |
| Overlay | `W × H` | glyph centre | `prop_lever_badge_{a,b}` 5×7 → `(2,3)` |

The `(W/2, H - 8)` rule of §1.3 only fits footprints up to about two tiles: a footprint of length `L` tiles along one axis needs `L * 8` px below the centre inside the canvas (2:1 projection), so `prop_transit_car_stalled` (5 tiles long) cannot keep its centre 8 px above the bottom edge in `128 × 80`. For such pieces the pivot is the footprint centre and the canvas is sized around it.

### A.4 Axis-run pieces and `flip_h`
`wall_railing_iron`, `prop_station_bench`, `tile_cable_conduit_*`, `prop_fire_shutter`, `prop_bridge_platform` are authored along the down-right (`+x`) axis; `prop_security_gate` spans the down-left (`y`) axis. The other axis is a `flip_h` of the sprite (baked light flips with it, the same accepted compromise as §2.3 #4).

Wall fixtures follow **N = down-right (`+x`)**, **W = down-left (`+y`)**; text rows follow that plane too. Use a face-specific variant and its documented mount. A flip alone is not approval: the facing, top-left light and all three A.3 tests must still pass.

### A.5 Reproducibility
Every generated asset can be rebuilt byte for byte: `python tools/art/gen/verify_regen.py` (see `tools/art/gen/README.md`). Files authored before TLF-039 (batch 1) have no generator and are reported as *not covered*.

---

## Appendix B — TLF-057 Step 1 visual direction (Sol, 2026-11-05)

Scope: wishlist sections A and B in `design/ch01/expansion/ART_WISHLIST_STEP1.md`. This applies the approved grey-statue direction; it changes neither the chapter palette nor puzzle data. Argon remains the sole asset author. Sol reviews the exact pushed delivery before Lead integration; this brief is **direction, not delivery approval**. Technical dimensions, camera, collision, import and IDs remain Opus's authority.

### B.1 Frozen commuters: people interrupted

Preserve recognisable clothes, everyday gestures and weight. These are people arrested in time: no sculpted plinths, stone cracks, ice crust or luminous ghost interiors. Use broad, quiet planes with top-left highlights and compact down-right shadows. Avoid bright eye pixels and warm skin planes that make the figures read as living NPCs.

| Function | Existing palette indices / colours |
|---|---|
| Five-step grey body ramp, dark to light | `11 #1B1E24`, `12 #2E333D`, `13 #464E5C`, `14 #677385`, `15 #94A2B8` |
| Interior silhouette outline | `00 #0A0D14`, 1 px, separate from the five body values |
| Ground contact/shadow | `01 #141A26` / `00 #0A0D14` |
| Optional single subdued accent per assembled commuter | Existing dark colours only: e.g. `23 #8C2D19` for N-06's red coat, `18 #594438` for a courier bag. Keep the accent local; overlays must not add competing accent colours. |

Reserve the brightest grey for small upper-left folds and edges. Do not fill the whole coat with it. Elias retains the warmer face and coat hierarchy. The statue must remain identifiable beside him at native scale and nearest-neighbour ×3, in greyscale, with Trace effects hidden. Use posture, compact tonal masses and stillness as well as desaturation.

Keep the three builds (slim, broad, child/small), each standing and mid-action, plus the four specific poses. The small build has shorter limbs and a distinct head/body ratio; do not shrink an adult sprite uniformly. Keep the approximate 16×40 visual envelope, the specified `(8,36)` foot pivot and 12×8 collision contract. A lifted foot does not move the ground anchor. If an extended pose or overlay needs padding, agree canvas/offset metadata with Opus; never crop a hand, bag, trolley or crank to force a fit.

| Commuter | Required silhouette read |
|---|---|
| N-05 courier (Rewind unlock) | Forward weight, one foot visibly clear of the floor, separated legs and a swinging bag: a run-up/mid-vault gesture rather than a generic standing lean. |
| N-11 hatch technician (Freeze unlock) | Planted feet, torso leaning away from the crank, both hands engaged; retain negative space between arms and torso so the effort reads at ×3. |
| N-04 cleaner | Trolley half-turned, wheels/handle readable separately from the body. |
| N-03 old man | Seated weight on the existing bench, bent knees and paper bag on knee. Export the person/overlay without duplicating the bench. |

The approximately fourteen overlays remain modular: suitcase, paper bag, whistle, trolley, phone, red coat, briefcase, sleeping child, headphones, hatch crank, gate lever, breaker handle, map and courier bag. Keep phone/map/paper silhouettes distinct; the sleeping child needs a head/shoulder contour. Supply an assembly mapping for all thirteen commuters in `design/ch01/COMMUTERS_STEP1.md`; do not alter their narrative timestamps or encode which memories are correct using extra brightness.

### B.2 Trace shimmer and read state

The body never animates. Use the specified 24×12 foot ellipse with four frames of restrained stepped highlights, plus a 6×6 clock-hand timestamp glyph above the head. Trace violet (`30`) with sparse gold (`26`) belongs on the effect, not as a full-body fill. Keep the ring low so it cannot hide feet or floor clues. This commuter cue supplements §7's Trace language; it does not borrow Echo's cyan hollow body or Freeze's crystal corners.

The read variant is a static 1 px silhouette outline with the same pose, dimensions and anchor. Show it on both lit floor and dark wall backgrounds without thickening it. Visibility follows the wishlist: Trace selected, within 96 px; read state follows the first Trace flag. In `reduced_effects`, use the static outline and no shimmer animation. These are visual states for Flash to wire, not new scene/script work in this art delivery.

### B.3 Station hardware and state language

Reuse the worn steel family (ramp 11–15), restrained ceramic backing and existing shutter/console/lever forms. Flat upper-left bevels, darker right planes, readable working parts and one focal glyph take priority over texture. Amber is a small hardware/status accent. Keep temporal colours for temporal meaning. State must survive greyscale and a still frame; a lamp colour or a shake alone is insufficient.

| Family / wishlist row | Direction and non-colour state cue |
|---|---|
| SO-01 selector panel | Three visibly separate controls. LINE uses circle/diamond/triangle; PLATFORM uses 1/2/3 pips; CAR uses front/middle/rear window-position silhouettes. Preserve space between glyphs; do not bake the solution into a special highlight. |
| Release lever + lamp | Idle handle at rest; buzzing has X; accepted has `>>>` and changed handle detent. The six-second timing belongs to implementation. |
| Platform gate, staff door, inner shutter, staff barrier | Shared shutter housing, distinct plate marks. Closed has a continuous blocking slab; open visibly retracts it and leaves a clear portal. Recolouring the slab is insufficient. |
| Fallen / mounted conduit | Fallen has a sag/break and grounded end; mounted is straight and visibly seated in brackets. Keep the same material/segment identity. |
| Split-flap dials ×3 | Shared frame with LINE/PLATFORM/TIME identity marks; retain the font-rendered six label states as text. Jammed frame has a visibly misaligned flap/seam, not only shake. Do not invent label content. |
| Ticket validator / card reader | Idle slot and quiet display; rejection X; acceptance `>>>`. Reader and validator differ in casing size/slot silhouette, not contradictory status symbols. |
| Ticket-terms notice | Paper/plaque silhouette with restrained line blocks. Actual clue/terms text comes from the content spec; no invented readable clue text. |
| Service hatch | Four separate states: closed, open, frozen open, frozen closed. The frozen pair retain the correct aperture geometry and add the specified brass `[o]` lock ring; a lock badge must never cover whether the hatch is open. |
| Bulkhead wall | Same planar hierarchy as existing N/W walls, stronger structural seam; shared edges tile cleanly without a heavy outline cage. Confirm the requested axis run with Opus rather than changing projection. |
| Plates A / B | A and B letters persist in both states. Pressed lowers the centre/rim profile. Brass/green remain material cues within the existing palette, never the only distinction. |
| Bell icon | Idle bell contour; ringing adds visible strike marks within its 8×8 frame. |
| Echo pedestal | Idle quiet face; used adds a persistent paired-hand/second-hand mark. Do not fill the whole console with cyan. |
| Alarm plate | Idle unstruck bell; ringing bell + strike marks and small red lamp. Retain a floor-level profile. |
| Breaker C | Persistent C and lamp-ring identity. Engaged changes lever detent; browned-out shows broken ring/dark segments as well as reduced lamp value. |
| Standby plate | Empty hollow centre; held has a paired footprint/echo mark and depressed centre. |
| Dead relay lever C | Visible disconnected lug/lead in idle and never-wired shake frame. Keep it distinct from an ordinary powered lever; no accepted status. |

Follow the wishlist's suggested canvases and existing family pivots; document any agreed exception in asset metadata. Keep overlays and glyphs within their export bounds, use binary alpha, no antialiasing, no fractional scaling and no new palette colours. Detailed grime must not compete with a glyph, working slot or lever arm.

### B.4 Required visual-review handoff

Argon supplies the exact pushed branch/SHA, proof paths, inventory and a state matrix covering every A/B row, plus:

- Room composition with statues and Elias at native 960×540 and nearest ×2 (1080p); matching greyscale, plus an assembly sheet covering all thirteen commuters and four specific poses.
- Prop-family contact sheets showing every state side by side in colour and greyscale, with a legend outside runtime sprite bounds. Judge silhouettes and symbols at native size as well as ×3.
- All four shimmer frames, clock glyph, static read outline and reduced-effects view. Include an effects-hidden statue/Elias comparison.
- Raw `check_assets.py` and `verify_regen.py` output; Pixelorama source-to-PNG pixel-equality evidence for **every** new `.pxo`, with the exact source count; complete asset metadata and open issues.

Sol records **APPROVE** or **CHANGES REQUIRED**, tied to the reviewed SHA and concrete filenames/states, in the TLF-057 handoff after inspecting those proofs. Missing proofs or an unfinished delivery leave review **PENDING**. Lead retains technical acceptance and merge authority, including the repository's fresh-archive validation rule. No approval transfers to a later unreviewed SHA.
---

## Cast and Ch1 direction (TLF-061)

**Sol, 2026-11-05. Direction only.** Based on `origin/main` at `690f370`, updated to Lead's merged `efed5ab` before this edit. Canon: `docs/STORY_BIBLE.md`, `CHARACTER_BIBLE.md`, `OPERATOR_MYSTERY_GUIDELINES.md`, ADR-022. All six images in `design/art/reference/ch01/` were inspected. Their composition, clothing masses and station materials inform this section; their printed biographies, dialogue, combat poses, room graphs and hourglass devices do not become canon. No reference pixels are shippable.

### C.1 Decisions, authority and production boundary

- **Binding direction for TLF-062/063:** Operator silhouette, pocket-watch motif, non-combat gesture specification, Mira's silent broadcast look, unchanged Ch1 palette and the four-purpose prop list below. Lead merges this note before those tasks proceed.
- **Owner decision still required:** Elias v3, including whether to reveal a lab coat, introduce a red scarf, goggles or badge. This note proposes it; it does not replace Elias v2 or authorise a player-art rebuild.
- Keep 960×540 (ADR-023 addendum 3), nearest integer scaling (×2 at 1080p), 32×48 character frames, foot pivot (16,44), 2:1 placement, top-left light, binary alpha, 1 px silhouette outlines and the existing reproducibility gates. Assets belong to Argon; runtime/camera/timing contracts and integration approval belong to Opus/Flash.
- **Recommended approach:** retain the finished v2 for the present slice and build the Operator on separate robe/mask/watch/scarf layers. If the owner later chooses v3, use the restrained candidate below. A wholesale recreation of the reference sheet would add unsupported combat states and premature research symbolism; it is outside scope.

### C.2 Elias v3 proposal — not approved for production

Translate the reference into the same grounded adult proportions as v2, not its oversized anime head or ornate equipment. Preserve untidy dark hair, readable exposed face, split coat hem, two separate boots and the brass pocket watch. At 32×48, the hierarchy is face → scarf/shoulders → coat split → watch; tiny equipment must not compete with it.

| Reference feature | Proposed treatment at 32×48 | Existing palette |
|---|---|---|
| Lab coat | Two broad light lapel/hem masses, dark centre and sleeve underside; no white flood-fill. Retain the v2 mid-thigh split hem, visible legs and 14×42 standing-body target; a full ankle-length coat would converge with the Operator. | shadow 12/13, body 14, upper-left edge 15; 31 only for an isolated specular pixel, never the coat body |
| Red scarf | 2 px neck band and a short 3–5 px side tail; no huge fluttering banner. Identical material colours on Elias and the Operator if selected. | shadow 22 `#4A1C14`, mid 23 `#8C2D19`; no hot orange/red lamp colours |
| Goggles | Optional two dark lens pixels and a short brass bridge at collar level; omit if the neck/watch becomes busy. No face-covering goggles. | 11/12 lenses, 25 bridge |
| ID badge | Prefer **omit in Ch1**. If the owner insists, use a 2×3 unlettered tab without portrait, name, logo or clearance number. | 13/15; no readable ELYSIUM text |
| Hair, face, trousers, boots | Keep the current head/skin and lower-body ramps and proportions. No new portrait or facial scar clue. | hair/boots 16–18, skin 20/21, trousers 02/03 |
| Pocket watch | Same round brass case, crown and short chain as the existing watch; no hourglass at the belt. | 25/26, recessed face 13/15, dark hand 00 |

**Spoiler flag:** a lab coat, especially with goggles or an ID, suggests Elias's research/ELYSIUM link before the chapter has earned it. It may make the uncertain Beat 09 association feel like confirmation. Recommendation: keep the brown v2 coat for Ch1, reserve an unmistakable lab coat for a later authorised memory/reveal. The owner may choose the reference-led lab-coat v3 despite that cost; do not quietly settle this in asset production.

**Replacement cost, planning estimate rather than a quote:** v2 already ships 80 frames = 5 authored directions × (4 idle + 6 walk) = 50 authored poses, plus 30 mirrored frames. A costume/proportion replacement affects **all 80**, not a single portrait: rebuild and review 50 authored poses, regenerate 30 mirrors, preserve 16 tags and the 2560×48 sheet, pivot and movement cadence; check the three mirrored directions' scarf/goggle/chain compromises. Re-run palette/alpha/size/mirror and regen checks, Pixelorama equality, and in-room colour/greyscale animation proofs. Budget approximately 2–4 focused artist-days for the 50-pose redraw/generator work plus 1–2 for export, review, revisions and integration (3–6 total; Argon estimates after the owner selects the costume). A scarf-only addition still touches the 50 authored/80 delivered frames, though it is cheaper than repainting the coat. Retaining v2 has zero replacement-frame cost. Neither option includes Run, Hurt, Knockdown, attacks, new movement directions or combat.

### C.3 Operator — TLF-062 sighting contract

Take the reference's peaked hood, closed mask and long robe. Remove the hanging hourglass, elaborate gold filigree, floating weapons, clawed attack hand and purple floor sigils. The robe has a single broad lower mass, a hood higher/wider than Elias's hair, and almost no exposed leg gap. It must read as an observant person rather than a boss.

- **Material:** robe 00/01/02/03, restrained 04 on top-left folds; mask 12/13/14 with a tiny 15 rim in later authorised views. No skin, eyes, mouth, facial anatomy, transparent mask, cracked-mask reveal or recognisable Elias hair/scar. The Ch1 back view shows no mask front at all; retain a closed mask beneath the hood in the source design.
- **The watch is Elias's pocket watch:** same round case/crown/chain motif and 25/26 brass, not a similar-but-different hourglass or glowing crystal. A 3×3 round/square-stepped case with a dark centre and a 1 px crown is enough; keep it beside the hand, not an oversized chest medallion. Only pose/occlusion changes its apparent view.
- **Scarf link:** proposed v3 red uses exactly 22/23 on both characters, a short under-robe neck/side fold, never the robe's main colour. **Current-build gap:** v2 has a dark slate collar (02), no scarf. TLF-061 cannot truthfully certify a shared scarf against unchanged v2. Argon should keep the scarf on its own named layer and supply the red candidate without repainting Elias. The owner must decide whether to approve a matching Elias scarf (with or without full v3), or explicitly defer that visible clue while retaining v2. Until then, the shared-scarf shipping check is pending, not passed; the independent Operator source work can proceed after this direction is merged.
- **Gesture link:** right hand retrieves the watch, elbow closes toward the ribs, wrist lifts to lower chest, head tips slightly to check, wrist lowers. Calm, weary, deliberate. No pointing at Elias, casting attack, beckoning threat or face turn. Never mirror this gesture automatically: it would swap the watch hand.
- **Current animation gap:** `elias_build.py` and the player currently expose idle/walk only; there is no dedicated Elias watch-check clip to copy. The shared four-key-pose/timing reference below is a proposed common gesture contract for future Elias use and the Operator, not a claim that a player clip exists. If Opus has an approved clip elsewhere, match that exact cadence before export. Adding a player clip is a separate authorised task; do not extend the 80-frame v2 sheet in TLF-062.

| TLF-062 item | Authoring specification |
|---|---|
| View | One back three-quarter view facing away along the approved platform composition, nominal `ne`; enough side sleeve/hand visibility to see the watch, zero face rotation. Flash/Lead confirm facing at the chosen tile before export. |
| Canvas / anchor | 32×48 per frame; foot pivot (16,44), foot sole fixed y=44; robe/hood approximately 22–24×43 within x=4..29, y=2..44. No runtime scale-down to simulate distance; no collider. |
| Frame count / file | **4 unique frames**, horizontal 128×48 sheet; source layers `Robe`, `Hood_Mask`, `Scarf`, `Hand_Watch`, `Contact_Shadow`. Suggested stem `ch01_char_operator_sighting_ne_sheet`, tag `check_watch_ne` frames 1–4. |
| F1 — rest | Hand/watch low at hip, body still; 2 ticks at 8 FPS = 0.25 s. This is the reusable static rest pose. |
| F2 — lift | Elbow bends inward, wrist rising, short chain follows; 2 ticks = 0.25 s. |
| F3 — check | Watch at lower-chest side, head inclines by at most 1 px, watch remains outside robe contour; 8 ticks = 1.00 s. This is the static `reduced_effects` pose. |
| F4 — lower | Wrist descends without a face turn; 2 ticks = 0.25 s. One cycle totals 1.75 s; hold F1 a further 1 s between cycles if the sighting lasts. Frame durations belong in metadata and the Flash handoff, not four equal-duration playback assumptions. |
| Temporal VFX | Reuse §7's existing ability pairs **and shapes/motion**: Trace violet/gold diamond/column signature; Rewind cyan chevrons/reverse motion; Freeze white/teal rigid corners; Echo cyan hollow/scanline signature. No Operator-only purple magic system. For this Ch1 shot use a restrained existing Trace signature on a separate effect layer/export, never inside the body silhouette or over the watch. No palette additions. |
| Reduced effects / disappearance | Hold F3; suppress moving VFX. TLF-058 owns the 0.5 s approach fade and static cut for reduced effects; no extra disappearance/combat frames are requested. Binary sprite alpha remains 0/255; any runtime fade is Flash's presentation. |
| Proof / repeat composition | Native and ×3 colour + greyscale against the actual dark platform, effects on/off; inspect F3 watch contour and scarf swatch separately. Lead approves the platform tile, screen framing, facing, watch-hand position and shot timing and records them for exact Ending 3 reuse. This note does not invent new coordinates or a second scene. |

Do not infer identity from the matching objects. The future-Elias, memory/consciousness entity, and other-person-in-ELYSIUM readings all remain possible. A later front/side character sheet, walk set, interaction/barrier pose or other chapter animation is outside this four-frame sighting request. No attack poses at any stage.

### C.4 Mira — look only; Ch1 is a silent image

Keep shoulder-length lavender hair with a small asymmetric flower at one temple, open shoulders/short fitted jacket, narrow waist and a short flared lower garment. This separates her silhouette from Elias's split rectangular coat and the Operator's continuous robe. Use 13/15 for desaturated hair base/light, a **small** 30 lavender accent, 20/21 skin, 11/12 garment shadow and 14/15 lapel; flower is a 3×3 stepped petal mark in 30/31 with a 25 centre. No new lavender ramp; avoid colouring the entire figure bright temporal violet.

The Ch1 Beat 10 screen uses a **single static, silent broadcast portrait**; frame the face, flower and shoulder line in a 32×48 source composition, then place it on its own layer in the TLF-062 city plate. No walking Mira in the platform, new encounter, new dialogue, subtitles copied from the concept sheet, rescue plea, biography card or explicit reconstruction label. Her look must not explain her Ch5 status. Existing authored Trace/story content stays with the Lead; this note authorises none of the sheet's Talk/Guide/Research/Fade animations. At a smaller in-plate display, simplify to hair contour + flower + face; validate at its actual native screen size, not just an enlarged portrait.

### C.5 Native 32×48 greyscale silhouette study

This is a **document-only schematic**, not finished sprite art or a new source/export. Each column is exactly 32 cells wide and 48 high. Left: Elias v3 candidate (same split-hem/leg-gap principle as v2); centre: Operator back/side watch check; right: Mira look study (not an in-world Ch1 appearance).

`.` = background, `#` = one solid body value; `s` = scarf marker, `w` = shared watch marker. For the strict silhouette test, replace **all** `#sw` cells with the same grey. Distinctness must survive removing accents and effects. For a second greyscale-link pass, use #=96, s=144, w=224, background=24: Elias/Operator have the same scarf and watch marker values and watch-case geometry, Mira neither. The scarf study represents the **candidate** shared red design; it does not resolve the missing v2 scarf.

```text
ELIAS (candidate)                 | OPERATOR                         | MIRA (look only)
................................ | ................................ | ................................
................................ | ................................ | ................................
................................ | ...............###.............. | ................................
.............########........... | ...............###.............. | ................................
...........##########........... | ..............#####............. | ............#########...........
............###########......... | .............#######............ | ............#########...........
............##########.......... | .............#######............ | ...........###########..........
............##########.......... | ............#########........... | ...........###########..........
............##########.......... | ...........###########.......... | ........###############.........
............##########.......... | ..........#############......... | .......################.........
............##########.......... | ..........#############......... | ........###############.........
............##########.......... | ..........#############......... | ..........#############.........
............##########.......... | ..........#############......... | ..........###.......###.........
.........###ssssssssss##........ | .........###############........ | ..........#############.........
.........###ssssssssss##........ | .........########sssss##........ | ..........#############.........
.........##########sssss........ | .........########sssss##........ | ..........#############.........
.........###############........ | .........###############........ | ..........#############.........
.........###############........ | .........###############........ | ..........#############.........
.........###############........ | .........###############........ | ..........#############.........
..........###############....... | .........###############........ | ..........#############.........
..........##############www..... | ........##################www... | ..........#############.........
..........##############w.w..... | ........##################w.w... | .............#######............
..........##############www..... | ........##################www... | .............#######............
..........#############......... | ........###################..... | .............#######............
..........#############......... | ........#################....... | .............#######............
..........#############......... | ........#################....... | .............#######............
..........#############......... | ........#################....... | ............#########...........
..........#############......... | .......###################...... | ............#########...........
..........#############......... | .......###################...... | ............#########...........
..........#############......... | .......###################...... | ...........###########..........
..........#############......... | .......###################...... | ...........###########..........
..........#############......... | .......###################...... | ...........###########..........
..........#############......... | .......###################...... | ..........#############.........
..........#############......... | .......###################...... | ..........#############.........
.........######..#######........ | ......#####################..... | ..........#############.........
.........######..#######........ | ......#####################..... | .........###############........
.........######..#######........ | ......#####################..... | .........###############........
............###...###........... | ......#####################..... | ............###...###...........
............###...###........... | ......#####################..... | ............###...###...........
............###...###........... | ......#####################..... | ............###...###...........
............###...###........... | ......#####################..... | ............###...###...........
............###...###........... | .....#######################.... | ............###...###...........
............###...###........... | .....#######################.... | ............###...###...........
............###...###........... | ......#####################..... | ............###...###...........
...........#####..#####......... | ...........####....####......... | ...........#####..#####.........
................................ | ................................ | ................................
................................ | ................................ | ................................
................................ | ................................ | ................................
```

**Read criteria:** Elias has an uncovered irregular hair crown, squared coat shoulders, split hem and separated legs; Operator has a higher peaked hood, taper-to-broad robe hem with no long leg gap, and a watch-hand projection; Mira has the side flower/hair notch, inward waist and short flared hem with exposed lower legs. Watch/scarf are recognition clues across the first two, not the means of telling those silhouettes apart. Check native 1× and nearest ×3 on floor 02 and wall 08; no effect, labels, coloured edges or facial detail may be needed to tell the three apart. A production pass must retain these silhouette differences and prove them in Argon's own delivery. This schematic is not approval of a replacement Elias.

#### C.5.1 Detailed character concept study — Elias / Operator / Mira (visual reference; not production approval)

This subsection **adds** a more readable illustrated comparison and a production translation specification. The 32×48 schematic above stays the native-size reference, and the C.8 verification still refers to it. The illustration below is **concept-only**. It conveys visual richness, clothing layers, facial character, and different silhouettes, **not approved final character design, not a new sprite asset, and not permission to change Chapter 1 canon**.

Reference sheet (linked, not embedded; concept only): [`reference/ch01/character_comparison_detailed_CONCEPT_ONLY.png`](reference/ch01/character_comparison_detailed_CONCEPT_ONLY.png)

> **Important canon and pipeline boundary:** The illustration is aspirational, with noncanonical details. **Do not copy** the Elias lab coat/red scarf/goggles/ID as shipped v2 without owner approval; the current v2 brown coat and no-scarf state remain unchanged. **Do not ship** the artwork's visible hourglasses, ornate white/gold Operator robe, exposed or identifiable face/mask, combat imagery, invented devices, purple magic, or extra Mira-in-world appearances. Elias/Operator's only personal timepiece is the **same pocket-watch motif**. Mira remains a **silent, static broadcast image** in Ch1. The illustration's extra costume/equipment icons are not an asset manifest. **Also excluded:** a pocket watch or any other timepiece on Mira (C.7: the watch belongs only to Elias and the Operator); the sheet's chibi head-to-body proportions (keep the grounded adult proportions of the 32×48 frames); the armillary sphere, scroll, books, glowing vial, bandage, ribbon props and the clock/rune halos behind the busts.

#### C.5.2 Art-quality goals distilled from the detailed reference

| Quality dimension | Required interpretation for actual 32×48 sprites | Avoid |
|---|---|---|
| Silhouette | Distinct head, shoulder, torso, hem and foot contours at **native 1×** | Detail readable only when zoomed in |
| Forms | 2–4 deliberate colour clusters per large material plane; strong separation between outerwear and trousers | Speckled noise, excessive 1px decorations |
| Character identity | Silhouette and posture first, then face/watch/flower accessories | Reliance on palette hue or VFX alone |
| Costume richness | Imply seams and layered garments with broad value bands and selective highlight pixels | Shrinking portrait-level embroidery into noisy sprites |
| Facial expression | Minimal readable pixel clusters in 32×48; detailed portraits only in **separate approved portrait assets** | Assuming illustration-scale eyes and facial marks fit runtime sprite |
| Presentation | One neutral turnaround, grayscale, 1× and nearest-neighbour ×2 (1080p, ADR-023 addendum 3), plus placed scene view | Passing a beautiful splash image as pixel-perfect runtime QA |
| Mystery | Operator's face and identity remain unknowable | Literal future-Elias reveal, face features, readable identity tags |

#### C.5.3 Three-character design intent and physical read

**ELIAS — current v2 (shipping baseline)**
- Uncovered irregular dark hair crown; exposed recognizable human face, compact shoulders and grounded adult proportions.
- Current **weathered umber/brown coat** with clear split hem, two separate legs and boots; pocket-watch case and short chain are the small distinctive accent.
- At native scale, prioritize **hair silhouette → face → coat split → boots → watch**. Light face pixels must not create a halo that looks like temporal magic.
- **Optional v3 exploration only:** short dark-crimson scarf and restrained light research-coat visual language, as described in C.2. That proposal is *not* approved; do not repaint 80-frame sheet or add ID/goggles by default.
- Noncombat idle/walk remain the approved animation baseline. Do not import run/hurt/knockdown states merely because the reference displays them.

**THE OPERATOR — mysterious observer**
- Higher peaked hood, wider upper silhouette and broad uninterrupted lower robe mass; legs mostly hidden; **no leg-gap similarity** with Elias.
- Ch1 approved sighting remains **back three-quarter**, hood up, mask closed/concealed; no human facial anatomy or identity clue beyond **circumstantial watch/gesture**.
- Robe uses **near-black slate** family 00–04, tiny restrained metallic mask edges 12–15 only when visible; no cream-white main robe, elaborate gilding, magical gold rings, or personal hourglass.
- The watch checking gesture is slow and weary, not threatening. Keep a clear readable watch-hand protrusion without changing hand side through automatic mirroring.
- A proposed scarf-link may exist as a **separate concept layer**. Current Elias v2 does **not** include a matching scarf; never claim parity is resolved.

**MIRA — look study only / Ch1 broadcast**
- Shoulder-length lavender-tinted hair with a small asymmetric flower; visible hair notch and open face.
- More tapered waist and short, softly flared lower garment, unlike Elias's divided coat or Operator's continuous robe.
- Preserve figure's lightness through shape and local value, **not** big purple surfaces or full-screen lavender lighting.
- In Chapter 1, only a **silent, static broadcast portrait** is authorized. This full-body turnaround is an external concept reference, not permission to place Mira in a walkable scene.
- At small broadcast size, prioritize **hair outline + flower + cheek/eye/shoulder arrangement**. Do not introduce revealing dialogue, biography cards, or unapproved abilities.

#### C.5.4 Detailed study panels required before any production redesign

For each character, the art team must supply an **original** working sheet separate from this illustrative reference:

1. **Hero concept:** one readable full-body 3/4 study and one controlled bust portrait. Concept images may be richer than runtime sprites; mark the status clearly.
2. **Turnaround:** front, back and both 3/4 angles, with consistent cloth panels, silhouette and the same watch/flower placement where applicable.
3. **Silhouette test:** identical solid grey fill for all three at 32×48, plus native 1×, nearest ×2 on both floor `02` and wall `08` backgrounds.
4. **Value study:** grayscale rendering with 3–5 principal value bands, proving separation of head, torso, hands, hem and feet with all VFX disabled.
5. **Material callouts:** only approved palette indices from `TLF-CH01-32`; each callout points to a *large* garment mass, not a decorative micro-pixel.
6. **Scene proof:** Elias and relevant Operator sighting placed in the approved Chapter 1 room, in that room's view mode (ADR-025); Mira only on the approved Beat 10 broadcast display. Include effects-on/effects-off and reduced-effects views.
7. **Technical handoff:** approved frame bounds, pivot `(16,44)`, eight-direction rules for Elias (plus the TLF-075 side-view `e`/`w` set where a room uses `side`), source/export paths, palette/alpha validation and regeneration evidence. Operator and Mira follow their existing narrower shot/portrait contracts, not Elias's full walk sheet.

#### C.5.5 Character differentiation checklist

| Test | Elias | Operator | Mira |
|---|---|---|---|
| Head | Uncovered, messy hair | Peaked hood hides head | Shoulder-length side-flower hair |
| Torso | Rectangular practical coat, human face | Layered but monolithic dark robe | Narrowed waist / soft shoulder line |
| Hem | Two coat tails, **visible leg separation** | Broad continuous robe mass | Short flared garment, exposed lower legs |
| Unique cue | Small brass pocket watch | Matching watch shape used as uncertain clue | Tiny flower and asymmetrical hair shape |
| Ch1 status | Existing v2 playable character | Restricted observation shot | Static broadcast only |
| Unapproved elements | New lab coat, scarf, ID/goggles | White/gold robe, face reveal, hourglass | Playable/walkable appearance, unapproved story text |

**Approval gate:** Owner decides whether Elias v3 is desired and resolves the missing v2 scarf explicitly. Until then **keep v2** and keep the shared-scarf clue **PENDING**. Sol reviews exact source/assets and grayscale proof, Argon (fallback Sol) authors approved changes, and Opus/Flash retain technical integration/merge authority. This illustrated panel is a *visual direction reference*, not proof that native 32×48 runtime art has passed review.

### C.6 Chapter 1 mood and TLF-063 props

**Keep TLF-CH01-32 unchanged: 32 colours, zero new RGB entries.** Choose the cool blue-teal architecture of `chapter1.1_map.png` as the mood emphasis within the existing palette: floor 00–05, ceramic 06–10 and steel 11–15. Borrow the warm pools, worn brass and quiet transit signage of `chapter1.2_map.png` locally using 22–26; do not globally warm/repaint the finished room tiles. Dark floor and grey commuters stay subordinate to Elias's face, watch and puzzle glyphs. Sparse amber station practicals are different from the cyan of active technology. Large purple environments, ubiquitous bloom, lush vines, new stairs/rooms and the overview's “unfreeze time” objective are not adopted. The approved room graph, 23:54 evacuation, 23:59 clocks and street exit stay.

Use the **four existing TLF-063 items only**. Proposed canvases below are art briefs; Opus/Flash confirm placement, pivot, text handling and overlap before production. They are decorative, never new selectable controls, doors or colliders.

| TLF-063 prop | Story reason / reference | Production direction |
|---|---|---|
| Departure board `DESTINATION: NOWHERE - 23:59` | Cool platform reference: service continuing to announce a destination that no longer exists. | 160×32 wall board, two lines `DESTINATION:` / `NOWHERE - 23:59`, native 5×7 pixel font at 8 px; steel 11–15, recessed 00, restrained 24/25 digits. One static state; no flickering clock or new route solution. |
| Wall sign `A1 -> RESEARCH` + sealed `R&D ACCESS` panel/door dressing | Both platform references: transit fed an ELYSIUM research route; establishes place without naming Elias's role. | Sign 96×16, native font; door dressing 32×64 matching the existing appropriate archway axis, a visible sealed seam and small `R&D ACCESS` plaque (two lines if needed). Mounted over existing non-traversable dressing only; do not create a new traversable door. No glowing access prompt. |
| Sector A pillar marks | Warm reference: civic wayfinding tying spaces together. | Reuse existing pillar; small 16×16 `A`/sector mark decal in steel/quiet amber. Put it away from lever A/B labels and plate glyphs so it cannot be mistaken for a puzzle answer. No new pillar geometry. |
| `CLOSED TRACK` notice | Cool reference: a closure preceding the abandoned service. | 80×16 plaque (or two native-font lines on 48×24 if placement needs it), one dark diagonal closure stroke, no extra dates, commands, collectibles or invented readable lore. Clearly separate it from the playable exit signage. |

No new bench, train, luggage, ivy or floor set: those roles already have assets, and filler would increase clutter/cost without advancing this story. Longer sign copy uses Lead-approved text keys if needed; source text remains under the Lead's ownership. Readability/palette/alpha/regen and greyscale proofs remain mandatory for Argon's TLF-063 delivery.

### C.7 Hourglass and Chapter 3 boundary

The **pocket watch is the only personal time device** for Elias and the Operator. An hourglass may appear solely as a small, static **ELYSIUM project emblem** on institutional signage/documents if the Lead approves that placement, or be omitted. It never hangs from a character, replaces the watch, powers a puzzle, or appears as a personal HUD icon. Default for TLF-062/063: omit it; the watch motif already carries the clue.

**Chapter 3, Infinite Library:** warm wood, gold/brass and sunlight. Broad timber/book masses and warm light establish its identity. Purple is not its architectural palette, fog wash, dominant light or inherited Operator ambience. A local existing ability VFX may keep its functional colour/shape without turning the library purple. This records a later-chapter rule, not permission to build a Ch3 palette or assets now.

### C.8 Handoff and Operator §6 gate

| Mandatory question from OPERATOR_MYSTERY_GUIDELINES §6 | Answer for this direction |
|---|---|
| Is his identity revealed directly? | **No.** No name, identity assertion or confirming face is specified. |
| Does any character confirm it? | **No.** This direction adds no dialogue or character testimony. |
| Is a line too explicit? | **No.** No new line is written; reference-sheet text is excluded. |
| Does any visual show his face or a feature that removes the mystery? | **No.** Back-facing hood/closed mask; watch, scarf and gesture remain circumstantial links. The Elias lab-coat spoiler is separately flagged for owner decision. |
| Does Ending 3 still leave room for interpretation? | **Yes.** Repeated composition/gesture is a clue; all three readings remain possible, with no visual identity confirmation. |

**Open decisions / limits:** owner chooses v2 retention vs v3 and the shared scarf treatment; Lead/Flash confirm the common watch-check cadence because v2 has no such clip, and approve the repeatable shot composition. These gaps must be disclosed in TLF-062's handoff; do not mark scarf/gesture parity against the current v2 as already tested. They do not require creating a new face, replacing the watch or postponing independent robe/watch/prop source work. Technical import/collision/sorting approval remains with Opus; the previously noted dead-relay layer reconciliation remains in TLF-055 integration, outside this document-only task.

**Verification performed:** parsed the study directly from this document with Python, asserted 48 rows × three 32-cell columns, allowed only `. # s w`, checked pairwise-distinct collapsed foreground masks and matching hollow 3×3 watch markers. Rendered only a temporary QA view outside the repository and visually inspected native 1× and nearest ×3 on floor 02 and wall 08, both as solid silhouettes and with greyscale markers. The hair/split coat, peaked continuous robe and flower/waist/flared hem are distinguishable without colour. This is a schematic acceptance test; Argon's finished asset proofs still need their own visual review.

Raw mask-check output (exit 0):

```text
Elias: 32x48 cells; foreground=488
Operator: 32x48 cells; foreground=689
Mira: 32x48 cells; foreground=425
silhouette pair 1/2: distinct; IoU=0.658
silhouette pair 1/3: distinct; IoU=0.763
silhouette pair 2/3: distinct; IoU=0.565
Watch: matching 3x3 case with hollow centre in both; scarf markers present in both candidate studies
```

IoU is the occupied-cell intersection/union, recorded for reproducibility rather than used as a substitute for visual judgement. `git diff --check` passed (exit 0); `git diff --name-only` returned only `design/art/ART_BIBLE.md`. No production asset files, sources, exports, generators, scenes, scripts or task files were created/edited. No Godot or gameplay validation was run for this direction-only edit. Final handoff reports the branch and pushed SHA with the open decisions above; Lead integrates.

---

## Appendix D — Visual Quality Upgrade for Chapter 1 (2026-11-10; PROPOSED)

**Status:** Visual-direction proposal for owner/Lead review; not an implementation task.  
**Primary purpose:** Make *The Forgotten Station* feel like a premium, restrained, authored HD pixel-art location rather than a uniformly illuminated asset showcase.  
**Scope:** Polish existing Chapter 1 spaces and assets within the approved room graph, animation contracts, `TLF-CH01-32` palette, the `960 × 540` canvas (ADR-023 addenda 3-4) and each room's view mode (ADR-025: 2:1 isometric by default, `side` for the Trace memory pilot).  
**Invariants:** Sections 1–8, Appendices A–C, ADRs, approved assets, puzzle beats, timestamps and spoiler boundaries remain authoritative wherever this appendix is less specific or conflicts. Ask the Lead to resolve a conflict; never silently override a contract.

### D.1 Six visual pillars (decision filter)

1. **Loneliness before spectacle.** Most of the station is quiet, empty and unlit. Preserve negative space and the feeling of a place interrupted mid-routine; avoid a magical ruin or a glowing cyberpunk hub.
2. **Shape before texture.** Floor heights, door openings, switches, platform edges and character silhouettes must read at **native 960×540**, before grime, outlines or post-processing are considered.
3. **Light carries meaning.** Each brighter area needs a story, navigation, or gameplay reason. A lit control panel is information; decorative light strings are noise.
4. **Physical materials, restrained age.** Concrete, ceramic, iron, old glass, paper and worn brass must each read through plane, wear and local material patterns, not random noisy pixels.
5. **Time disruption is rare and specific.** Temporal VFX use the existing ability shape/colour vocabulary; they must never turn the station into an all-purple magic scene.
6. **Consistency beats isolated beautiful assets.** A modest sprite that fits scale, palette, lighting, and camera is better than a visually impressive sprite that breaks the scene.

### D.2 Chapter 1 darkness and practical-light policy

**User visual direction:** Earlier isometric map concept had *too many lights and was too bright*. Prefer darker, colder, less evenly lit rooms. This is a composition requirement, not permission to make clues invisible.

| Area type | Mood target | Lighting role | Avoid |
|---|---|---|---|
| Awakening platform (`ch01.arrival_platform`) | Deep blue-grey darkness, isolated human scale | Small readable silhouette zone around Elias; optional subdued status indicator | Repeating bright lamps down the whole platform |
| Concourse and hub (`ch01.concourse_west`, `ch01.upper_vestibule`, `ch01.vestibule_niche`) | Dark open space, selective silhouettes of architecture | Broad low-value ambient separation to reveal exits/steps | Golden floodlighting every bench and floor tile |
| Maintenance bay (`ch01.maintenance_bay`) | Claustrophobic and nearly unlit | One purposeful cue at the next traversal decision | Evenly spaced glowing sconces |
| Security and signal rooms (`ch01.security_crossing`, `ch01.signal_control`) | Functional industrial darkness | Console status and mechanical form are focal points | Multiple competing neon displays |
| Waiting lounge (`ch01.waiting_lounge`) | Abandoned everyday space | Gentle pooled or reflected illumination only when needed | Cozy, inhabited-room warmth |
| Atrium clock and street exit (`ch01.station_atrium`, `ch01.street_exit`) | Distinct but still restrained | Controlled clock-face or single focused source | Giant bloom washing out surrounding details |

**Suggested authoring targets, not validated engine numeric thresholds:**
- Treat most of the frame as low-to-mid values and reserve the brightest palette entries for small, actionable accents and carefully chosen focal points.
- Keep **one dominant focal light motivation per screenshot** where feasible; do not automatically add a lamp to every prop/architectural column.
- Favor non-emissive surfaces and existing palette ramps. A powered-off fixture should look off, not merely less saturated.
- The absence of light is safe only when ledges, doorways, collision-relevant boundaries, and interactive affordances remain distinguishable at native resolution.
- Preserve existing screen-top-left planar highlight conventions (§4) as stylized authored shading; these **do not imply** every physical lamp must be on. Light scarcity is a level composition principle, not a replacement for §4.
- If runtime illumination changes are proposed, Lead/Flash must evaluate rendering, performance, gameplay accessibility, and asset implications **before** implementation. This appendix does not request 2D light nodes, shaders, bloom, or new post-processing.

### D.3 Pixel-art craftsmanship: clusters, edges, and perceived detail

- **Silhouette pass first:** examine solid black/grey masks before colour. Elias, a frozen commuter, operator silhouette, and foreground props must remain separate when reduced to shape.
- **Cluster hierarchy:** large contiguous colour masses define materials; mid-sized clusters define structure; individual 1-pixel highlights are reserved for deliberate visual priorities (watch rim, control glyph, edge specular). Avoid scattered decorative single pixels across entire surfaces.
- **Directional materials:** iron beams use continuous edges and joint logic; ceramic tiles use readable planes and occasional cracks; worn terrazzo has subtle local variation, not high-frequency uniform noise. Weathering accumulates near seams, traffic areas, leaks, and corners.
- **Controlled edge quality:** preserve binary alpha, nearest-neighbour scaling, existing 1px silhouette outline rules, no external AA, and restricted dithering per §5. Do not introduce blur to make low-resolution images look smoother.
- **Material value separation:** steel, ceramic and floor should not collapse into one identical grey when displayed in greyscale. Prefer the established material ramps; avoid solving separation by adding a new colour.
- **Depth staging:** foreground silhouettes and props can obscure noncritical decoration, but must not cover navigable routes or critical clues. Validate y-sorting and foot pivots against actual player movement.
- **No fake resolution:** do not use high-resolution painted textures or soft photo overlays that are inconsistent with the 32×16 tile language. Concept art is direction only, not sprite source.

### D.4 Environmental storytelling density (Chapter 1)

Use **small, readable evidence clusters** rather than scattering props everywhere. Every added visual detail should pass at least one purpose check: **place history**, **navigation**, **puzzle communication**, or **emotional atmosphere**.

Examples of *visual treatments* for **already-approved** objects and spaces (not new interactables):
- An abandoned bench: uneven wear at hand-contact zones and dust on unused sections, while maintaining the original silhouette.
- A ticket counter: mostly dark glazing and restrained faded signage rather than a brightly illuminated storefront.
- Station control equipment: clear active/inactive mechanical states; the working element should be the visual focus.
- A commuter frozen in time: everyday human pose and muted material masses, avoiding stone statue cracks, ice shells or a bright ghost interior (Appendix B).
- Signage: only Lead-approved wording/placement, not invented lore, new route clues or premature ELYSIUM revelations (Appendix C). Wall-mounted signs also pass the three wall-fixture tests in A.3 (TLF-078).

**Density gate:** if a detail makes the main interaction or character harder to see at native size, remove/simplify it even when attractive enlarged. Do not populate rooms with extra benches, vines, luggage, lamps, or posters just to appear more detailed.

### D.5 Narrative art guardrails: Elias, Mira, Operator

| Subject | Keep | Improve without spoiler | Do not change without approval |
|---|---|---|---|
| **Elias** | Existing approved v2, brown coat, hair, face, pocket watch, 32×48, established directional sheet, TLF-075 side-view set | Cleaner coat cluster readability, readable foot separation and watch glint in the actual room composition | Lab coat/scarf/goggles/badge v3; new combat or story-revealing equipment |
| **Operator** | Enclosed hood and mask, watch motif, calm observational gesture, back-facing Ch1 sighting | Strong hood-to-robe silhouette, deliberate hand/watch negative space, subdued grey value hierarchy | Face reveal, explicit Elias features, hourglass, dramatic attack gestures, purple aura |
| **Mira** | Ch1 silent broadcast image only; modest lavender accent and small flower | Readable head/flower/shoulder shapes at in-world display size | Physical Ch1 appearance, invented dialogue, walking encounters, bright purple body fill |
| **Frozen commuters** | Ordinary poses, grey body ramps, modular overlays, per-character anchors | Distinct ages/builds/gestures with one clear silhouette story each | Ice, stone pedestals, animated bodies, extra colour clues identifying correct memories |

All proposed character polishing goes through the existing acceptance and approval workflow. The unresolved shared-scarf and watch-gesture parity issues in Appendix C remain **open**, not automatically resolved here.

### D.6 Puzzle readability is part of art quality

An attractive screenshot fails production if it obscures important gameplay state. For every puzzle-facing sprite, prove all of the following:

1. **Recognizable object identity:** players can distinguish panel vs lever vs gate before activation.
2. **Distinct state shapes:** idle / active / jammed / accepted / open / closed use silhouette, detent, aperture, glyph or geometry changes as applicable; colour is supplementary.
3. **Persistence:** after the animation, the new state remains recognizable in a still frame.
4. **Spatial clarity:** doors, walkable edges, floor plates and raised props remain clear in unlit and lit compositions.
5. **Correct meaning:** cyan/teal/violet/white and symbol vocabulary follow §7, not decorative use.
6. **No accidental answer:** prop highlights, signs, floor markings or commuters do not silently expose puzzle solutions or contradict canonical clue text.

**Important:** Do not add unsolicited tutorial arrows, floating UI markers, map numbers or puzzle labels to shippable environment art. Planning-map annotations stay outside production sprites.

### D.7 Composition, camera and polish review (contact-sheet protocol)

For each high-impact room or asset family under review, Argon (fallback Sol) provides a compact proof set using *actual current in-project* backgrounds, not invented mock rooms. Shoot each proof in the room's view mode (ADR-025) at the real ADR-023 follow-camera framing; a room without `metadata/room_shape` is shown in its 640 × 360 fallback frame inside the 960 × 540 view (ADR-023 addendum 4):

| Proof | Required observation |
|---|---|
| A. Native 960×540 | Elias and critical paths discernible without zoom; dark-but-readable |
| B. Nearest ×2 output (1080p) | Crisp pixel clusters; no fractional scaling artifacts |
| C. Greyscale | Actor, props and actionable cues separate by value and/or shape |
| D. Effects hidden | Environment and characters still readable without magical VFX |
| E. Puzzle states side by side | Open/closed, on/off, held/released etc. visibly distinct |
| F. Reduced effects | Important information survives shimmer/flicker removal |
| G. Dark-area stress test | No inaccessible-looking doorway, invisible ledge or lost interaction cue |
| H. Existing baseline vs proposed | Visual improvement visible without introducing a new mismatch or spoiler |

Review at **native scale first**. Enlarged presentation alone is not evidence. If a reference or mockup is not the actual asset exported from the approved generator/source, label it clearly as **concept only**.

### D.8 Quality scorecard (acceptance rubric; suggested)

For each new/reworked visual delivery, reviewers score **0 = fails, 1 = needs work, 2 = good**:

| Dimension | 0 — Fails | 1 — Needs work | 2 — Good |
|---|---|---|---|
| Native readability | Unclear silhouette/route | Reads after inspection | Reads instantly |
| Composition | No focal hierarchy | Several competing focal points | Clear focus/negative space |
| Lighting restraint | Uniform bright/decorative glow | Some unnecessary illumination | Sparse motivated light |
| Material definition | Noisy/indistinguishable | Uneven but recognizable | Clean material/ramp hierarchy |
| Pixel craft | Blur/fringe/random 1px noise | Isolated craft defects | Clean clusters, crisp edges |
| Canon consistency | Contradicts approved design | Unclear/open decision | Matches approved beat/design |
| Game-state clarity | Colour-only/ambiguous | Partially separated | Shape+state independently readable |
| Pipeline correctness | Breaks export/scale/pivot | Minor metadata gap | Validated by existing checks |

**Suggested review rule:** all eight dimensions should score **2** before final art approval; any safety/canon/pipeline failure is a blocking issue regardless of total. This rubric guides subjective review; the technical validation commands already in the Bible remain mandatory and authoritative. Do not treat this rubric as proof that asset tests have run.

### D.9 Implementation priority while Chapter 1 is in development

| Priority | Action | Ownership | Scope guard |
|---|---|---|---|
| **P0 — now (read-only first)** | Audit 2–3 representative current scenes: awakening platform, concourse, one puzzle room. Identify excessive lamps, low silhouette contrast, and visual clutter. | Sol visual review; Opus approves access/plan | Findings/report only; do not block Chapter 1 delivery or modify scene files |
| **P1 — upon approval** | Small targeted corrections to light placement, cluster readability, material accents, and existing state sprites. | Argon (fallback Sol) produces; Sol reviews; Opus/Flash integrates | Only approved art files / existing rooms; avoid changes to room graph, puzzle logic, collisions |
| **P2 — later** | Comprehensive room polish and broader presentation consistency pass after Chapter 1 vertical slice plays end-to-end. | Lead schedules | No wholesale reskin before gameplay completion |
| **Deferred** | Elias v3, new shader systems, remade environment tilesets, new chapter palettes or New Game Plus visuals | Owner decision required | Not authorized by this appendix |

### D.10 Agent handoff contract (copy into task brief)

> Review Appendix D together with the complete existing ART_BIBLE, the current branch/commit, approved ADRs, Chapter 1 room graph and story documents. This is a **visual quality proposal**, not a command to rework production art. Begin with a read-only audit of the actual current assets/scenes. Report up to ten concrete, ranked issues with screenshots or source filenames, their effect on native-size legibility/mood, and the smallest safe fix. Protect the approved 32-colour palette, the 960×540 canvas (ADR-023 addenda 3-4), the 2:1 grid of isometric rooms, the ADR-025 view-mode rules, pivots, alpha rules, sprite sheets, asset generator contracts and story reveal restrictions. Chapter 1 must become darker and less uniformly illuminated **without hiding gameplay information**. No new lighting tech, objects, room geometry, canon, or unapproved changes. Argon (fallback Sol) authors any approved asset edits; Sol inspects the exact pushed SHA; Opus retains implementation and merge approval. Do not start modifying project files until the Lead/owner approves the identified changes.

**Deliverable format (audit stage):** `visual_issue_id | scene/asset path | current behavior | proposed minimal change | visual reference/proof | risk | dependency | priority | approval status`.

### D.11 Unresolved decisions / explicit non-goals

- **Elias v2 vs v3:** owner approval still missing; **default unchanged v2**.
- **Scarf link:** character-to-Operator scarf parity is an unresolved proposed clue, not a fact shipped in current Ch1.
- **Older ×3 review views:** B.1 (statue and N-11 notes), the B.4 handoff list, the C.3 proof row and the C.5 read criteria still ask for nearest ×3; under ADR-023 addendum 3 the 1080p review view is nearest ×2. Sol aligns those lines in the next ART_BIBLE pass. The C.8 verification record stays as run.
- **Watch-check cadence:** verify existing authorised animation contract before claiming a shared gesture.
- **Runtime light budget:** no fixed count of lamps is imposed here; evaluate actual compositions and approved locations. If art-only correction is insufficient, Lead decides whether engine work is justified.
- **This document cannot prove the current art looks better:** screenshots and actual post-change deliverables must be reviewed. The appended criteria give a practical way to make that judgment without destabilizing the game.
