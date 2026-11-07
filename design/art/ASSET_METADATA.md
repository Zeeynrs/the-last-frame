# THE LAST FRAME — Chapter 1 Asset Metadata Registry (`TLF-010`)

**Task:** TLF-010  
**Owner:** Agent 2 (Argon — Narrative, Puzzle, Level Design & Art)  
**Pipeline Standard:** `docs/ART_PIPELINE.md`, `design/art/ART_BIBLE.md`, `docs/ADR_LOG.md` (ADR-001, ADR-003, ADR-005)  
**Master Palette ID:** `TLF-CH01-32` (`assets/source/ch01/ch01_palette_elysium09.gpl` · 32 colors · `0` off-palette exceptions · `0` semi-transparent AA pixels)

---

## 1. Summary Inventory Table (`TLF-010` Batch 1)

| # | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **1** | `ch01.palette.elysium09` | Palette | `ch01_palette_elysium09.pxo`<br>+ `ch01_palette_elysium09.gpl` | `assets/source/ch01/ch01_palette_elysium09.png` | `256 × 64 px` | `1f` (`1 FPS`) | `(0, 0)` | Reference Swatch | `32 / 32` | **`exported`** |
| **2** | `ch01.char.elias.base_sheet` | Character | `ch01_char_elias_base_sheet.pxo` | `assets/characters/ch01/ch01_char_elias_base_sheet.png` | `2560 × 48 px`<br>(`80 × 32×48`) | `80f` (`16` tags: `8 FPS` idle, `10 FPS` walk) | `(16, 44)` per `32×48` frame | `YSort_Actors` (`z_index = 10`) | `12 / 32` | **`exported`** (v2, TLF-039) |
| **3** | `ch01.env.tile.terrazzo_dark` | Environment (Floor Tile) | `ch01_env_tile_terrazzo_dark_idle.pxo` | `assets/environments/ch01/ch01_env_tile_terrazzo_dark_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `4 / 32` | **`exported`** |
| **4** | `ch01.env.tile.terrazzo_cracked` | Environment (Floor Tile) | `ch01_env_tile_terrazzo_cracked_idle.pxo` | `assets/environments/ch01/ch01_env_tile_terrazzo_cracked_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `6 / 32` | **`exported`** |
| **5** | `ch01.env.tile.tactile_amber` | Environment (Floor Tile) | `ch01_env_tile_tactile_amber_idle.pxo` | `assets/environments/ch01/ch01_env_tile_tactile_amber_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `7 / 32` | **`exported`** |
| **6** | `ch01.env.wall.subterranean_n` | Environment (Wall Module) | `ch01_env_wall_subterranean_n_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_n_idle.png` | `32 × 64 px` | `1f` (`static`) | `(16, 56)` | `YSort_Walls` (`z_index = 5`) | `8 / 32` | **`exported`** |
| **7** | `ch01.env.wall.subterranean_w` | Environment (Wall Module) | `ch01_env_wall_subterranean_w_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_w_idle.png` | `32 × 64 px` | `1f` (`static`) | `(16, 56)` | `YSort_Walls` (`z_index = 5`) | `8 / 32` | **`exported`** |
| **8** | `ch01.env.archway.frame_e` | Environment (Doorway Frame) | `ch01_env_archway_frame_e_idle.pxo` | `assets/environments/ch01/ch01_env_archway_frame_e_idle.png` | `32 × 64 px` | `1f` (`static`) | `(16, 56)` | `YSort_Walls` (`z_index = 6`) | `11 / 32` | **`exported`** |
| **9** | `ch01.prop.digital_clock_2359` | Prop (Wall Fixture) | `ch01_prop_digital_clock_2359_idle.pxo` | `assets/props/ch01/ch01_prop_digital_clock_2359_idle.png` | `32 × 24 px` | `1f` (`6 FPS` base) | `(16, 20)` | `Wall_Fixtures` (`z_index = 7`) | `11 / 32` | **`exported`** |
| **10** | `ch01.env.arrival_platform.target_sheet` | Target Composition | `ch01_env_arrival_platform_target_sheet.pxo` | `assets/environments/ch01/ch01_env_arrival_platform_target_sheet.png` | `640 × 360 px` | `1f` (`static` target) | `(0, 0)` | Full Viewport (`640×360`) | `30 / 32` | **`exported`** |
| **11** | `global.ui.font.tlf_pixel_mono` | UI Pixel Font | Built via deterministic TrueType packager | `assets/ui/fonts/tlf_pixel_mono.ttf`<br>+ `assets/ui/fonts/LICENSE.txt` | `5 × 7 px` glyph in `6 × 8 px` cell (`upm=512`) | `95` ASCII glyphs (`32..126`) | Baseline `(0, 7)` | `CanvasLayer_UI` | Tinted via UI theme (`#EDF4FA` / `#FFD166`) | **`exported`** |

---

## 2. Detailed `ART_PIPELINE.md` Asset Records

### 2.1 `ch01.char.elias.base_sheet` — Elias 8-Direction Idle & Walk Spritesheet
- **Asset ID:** `ch01.char.elias.base_sheet`
- **Filename:** `ch01_char_elias_base_sheet.pxo` / `ch01_char_elias_base_sheet.png`
- **Category & Chapter/Room:** Character (`actor_id = &"player"`) · Chapter 1 (all 10 rooms, `ch01.arrival_platform` … `ch01.street_exit`)
- **Pixel Dimensions & In-Game Scale:**
  - Single Frame: **`32 × 48 px`** (active standing silhouette `14 × 42 px` at `y = 3..44`)
  - Exported Horizontal Strip: **`2560 × 48 px`** (`hframes = 80`, `vframes = 1`)
  - In-Game Scale: `1.0×` on `640 × 360` internal viewport (`3.0×` integer stretch at `1920 × 1080`)
- **Pivot / Origin & Sorting Layer:**
  - Frame-local foot pivot: **`(16, 44)`** (`Sprite2D.offset = Vector2(-16, -44)` when `centered = false`, or `Vector2(0, -20)` when `centered = true`)
  - Sorting Layer: `YSort_Actors` (`z_index = 10`, `y_sort_enabled = true`)
- **Animation Frame Count, FPS & Tags (`80` Frames Total, `16` Tags in `.pxo`):**
  - Pixelorama layers (`3`): `Cast_Shadow`, `Boots_And_Coat`, `Head_Arms_And_Watch_Chain`
  - **Idle Animations (`4 frames` each @ `8 FPS`, loop = `true`):**
    - `idle_s`: frames `1..4` (`0`-based `0..3`, `x = 0..127`) — Unique authored
    - `idle_se`: frames `11..14` (`0`-based `10..13`, `x = 320..447`) — Unique authored
    - `idle_e`: frames `21..24` (`0`-based `20..23`, `x = 640..767`) — Unique authored
    - `idle_ne`: frames `31..34` (`0`-based `30..33`, `x = 960..1087`) — Unique authored
    - `idle_n`: frames `41..44` (`0`-based `40..43`, `x = 1280..1407`) — Unique authored
    - `idle_nw`: frames `51..54` (`0`-based `50..53`, `x = 1600..1727`) — Mirrored from `idle_ne` (`flip_h`)
    - `idle_w`: frames `61..64` (`0`-based `60..63`, `x = 1920..2047`) — Mirrored from `idle_e` (`flip_h`)
    - `idle_sw`: frames `71..74` (`0`-based `70..73`, `x = 2240..2367`) — Mirrored from `idle_se` (`flip_h`)
  - **Walk Animations (`6 frames` each @ `10 FPS`, loop = `true`):**
    - `walk_s`: frames `5..10` (`0`-based `4..9`, `x = 128..319`) — Unique authored
    - `walk_se`: frames `15..20` (`0`-based `14..19`, `x = 448..639`) — Unique authored
    - `walk_e`: frames `25..30` (`0`-based `24..29`, `x = 768..959`) — Unique authored
    - `walk_ne`: frames `35..40` (`0`-based `34..39`, `x = 1088..1279`) — Unique authored
    - `walk_n`: frames `45..50` (`0`-based `44..49`, `x = 1408..1599`) — Unique authored
    - `walk_nw`: frames `55..60` (`0`-based `54..59`, `x = 1728..1919`) — Mirrored from `walk_ne` (`flip_h`)
    - `walk_w`: frames `65..70` (`0`-based `64..69`, `x = 2048..2239`) — Mirrored from `walk_e` (`flip_h`)
    - `walk_sw`: frames `75..80` (`0`-based `74..79`, `x = 2368..2559`) — Mirrored from `walk_se` (`flip_h`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`12` colors used: indices `00, 01, 02, 03, 16, 17, 18, 19, 20, 21, 25, 26`; `0` off-palette colors; `0` semi-transparent pixels). v2 adds `03` (trouser highlight); trousers are slate `02`/`03`, boots `16`/`17`.
- **v2 changes (TLF-039, ISSUE-012):** layout unchanged (`2560×48`, same 80-frame order, same 16 tags, pivot `(16,44)`). Walk cycles are rebuilt on a 3-frame-per-step rig: *contact* (legs spread, arms counter-swung, body `bob = +1 px`), *recoil/down* (`bob = +1`, swing foot lifting), *passing* (`bob = 0`, swing foot raised 3 px and forward, planted leg vertical). The coat flares at the hem and kicks on contact frames, hands are visible (2×3 px skin), each authored direction has a new 10×11 head (hair highlight, ear/nose profile), and trousers/boots are separated. Idle: 4-frame breath bob (`0,0,+1,+1`) plus hem sway. Mirrors (`nw`, `w`, `sw`) are exact `flip_h` copies (`tools/art/check_assets.py`: pixel diff 0).
- **Collision / Interaction Footprint:**
  - Physics body (`CharacterBody2D` in `scenes/player/Player.tscn`): `CircleShape2D` radius `8 px` (`16 × 8 px` isometric foot contact ellipse centered at pivot `(16, 44)`)
  - Physical `InteractionDetector` (`Area2D`): `CircleShape2D` radius `36 px` (`ADR-015`)
  - Pocket-Watch Target Radius: `96 px` (`ADR-015`)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_char_elias_base_sheet.pxo`
  - Export: `assets/characters/ch01/ch01_char_elias_base_sheet.png`
- **License / Attribution:** Original production art authored by Agent 2 (Argon) in Pixelorama 1.2.3 `.pxo` format (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.2 `ch01.env.tile.terrazzo_dark` — Dark Terrazzo Platform Floor Tile
- **Asset ID:** `ch01.env.tile.terrazzo_dark` (`tile_platform_terrazzo_dark` in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_tile_terrazzo_dark_idle.pxo` / `ch01_env_tile_terrazzo_dark_idle.png`
- **Category & Chapter/Room:** Environment Floor Tile · Chapter 1 (Rooms 1, 2, 5, 7, 8, 9)
- **Pixel Dimensions & In-Game Scale:** **`32 × 16 px`** (`1.0×` scale; `2:1` dimetric diamond)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 8)`** (top vertex at `(16, 0)`) · `TileMapLayer_Floor` (`z_index = 0`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `2` layers (`Terrazzo_Slab`, `Bevel_And_Flecks`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`4` colors used: indices `01, 02, 03, 04`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Walkable floor tile (`navigation_layer_0 = true`, no blocking collision)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_tile_terrazzo_dark_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_tile_terrazzo_dark_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.3 `ch01.env.tile.terrazzo_cracked` — Cracked Terrazzo Platform Floor Tile
- **Asset ID:** `ch01.env.tile.terrazzo_cracked` (`tile_platform_terrazzo_cracked` in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_tile_terrazzo_cracked_idle.pxo` / `ch01_env_tile_terrazzo_cracked_idle.png`
- **Category & Chapter/Room:** Environment Floor Tile · Chapter 1 (Rooms 1, 2, 5, 7, 8, 9)
- **Pixel Dimensions & In-Game Scale:** **`32 × 16 px`** (`1.0×` scale; `2:1` dimetric diamond)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 8)`** · `TileMapLayer_Floor` (`z_index = 0`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `2` layers (`Terrazzo_Slab`, `Fracture_Cracks`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`6` colors used: indices `00, 01, 02, 03, 04, 05`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Walkable floor tile (`navigation_layer_0 = true`, no blocking collision)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_tile_terrazzo_cracked_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_tile_terrazzo_cracked_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.4 `ch01.env.tile.tactile_amber` — Tactile Safety Amber Curb Floor Tile
- **Asset ID:** `ch01.env.tile.tactile_amber` (`tile_tactile_warning_amber` in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_tile_tactile_amber_idle.pxo` / `ch01_env_tile_tactile_amber_idle.png`
- **Category & Chapter/Room:** Environment Floor Tile · Chapter 1 (Platform & trench edges in Rooms 1, 4, 5)
- **Pixel Dimensions & In-Game Scale:** **`32 × 16 px`** (`1.0×` scale; `2:1` dimetric diamond)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 8)`** · `TileMapLayer_Floor` (`z_index = 0`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `2` layers (`Curb_Steel_Base`, `Amber_Tactile_Studs`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`7` colors used: indices `00, 12, 14, 22, 23, 25, 26`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Walkable edge warning tile adjacent to impassable platform/trench boundary collider
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_tile_tactile_amber_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_tile_tactile_amber_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.5 `ch01.env.wall.subterranean_n` — Subterranean Ceramic Wall Module (North-East `N`, `y = 0`)
- **Asset ID:** `ch01.env.wall.subterranean_n` (`wall_tiled_subterranean_n` in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_wall_subterranean_n_idle.pxo` / `ch01_env_wall_subterranean_n_idle.png`
- **Category & Chapter/Room:** Environment Wall Module · Chapter 1 (All 10 rooms, North-East `y = 0` boundary)
- **Pixel Dimensions & In-Game Scale:** **`32 × 64 px`** (`48 px` vertical wall height + `16 px` isometric run; `1.0×` scale)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 56)`** · `YSort_Walls` (`z_index = 5`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `3` layers (`Wall_Cornice_Backing`, `Ceramic_Tile_Course`, `Dado_And_Skirting`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`8` colors used: indices `00, 06, 07, 08, 09, 11, 12, 24`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Static boundary wall (`StaticBody2D` polygon along the `32 × 16 px` base edge `(0, 48) → (31, 63)`)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_wall_subterranean_n_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_wall_subterranean_n_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.6 `ch01.env.wall.subterranean_w` — Subterranean Ceramic Wall Module (North-West `W`, `x = 0`)
- **Asset ID:** `ch01.env.wall.subterranean_w` (`wall_tiled_subterranean_w` in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_wall_subterranean_w_idle.pxo` / `ch01_env_wall_subterranean_w_idle.png`
- **Category & Chapter/Room:** Environment Wall Module · Chapter 1 (All 10 rooms, North-West `x = 0` boundary)
- **Pixel Dimensions & In-Game Scale:** **`32 × 64 px`** (`48 px` vertical wall height + `16 px` isometric run; `1.0×` scale)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 56)`** · `YSort_Walls` (`z_index = 5`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `3` layers (`Wall_Cornice_Backing`, `Ceramic_Tile_Course`, `Dado_And_Skirting`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`8` colors used: indices `00, 07, 08, 09, 10, 12, 13, 25`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Static boundary wall (`StaticBody2D` polygon along the `32 × 16 px` base edge `(0, 63) → (31, 48)`)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_wall_subterranean_w_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_wall_subterranean_w_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.7 `ch01.env.archway.frame_e` — Modular Transit Doorway Archway Frame (`E/W` Boundary)
- **Asset ID:** `ch01.env.archway.frame_e` (`wall_archway_frame_w` / `E↔W` boundary doorway in `ROOM_GRAPH.md` §7.1)
- **Filename:** `ch01_env_archway_frame_e_idle.pxo` / `ch01_env_archway_frame_e_idle.png`
- **Category & Chapter/Room:** Environment Doorway Frame · Chapter 1 (`ch01.arrival_platform:door_exit_east` @ `(13, 5)` and all `E↔W` doorways `E1`–`E4`)
- **Pixel Dimensions & In-Game Scale:** **`32 × 64 px`** (`20 × 42 px` clear portal opening inside `6 px` steel pillars and `11 px` transom lintel; `1.0×` scale)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 56)`** (threshold floor center) · `YSort_Walls` (`z_index = 6`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`static`), `3` layers (`Portal_Depth_Threshold`, `Steel_Arch_Jambs`, `Transom_Glyph_Badge`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`11` colors used: indices `00, 01, 02, 11, 12, 13, 14, 15, 25, 26, 29`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:**
  - `DoorwayPresenter` (`scripts/spatial/doorway_presenter.gd`) trigger `Area2D` (`16 × 12 px` diamond on threshold `(6..25, 48..63)`)
  - Flanking `6 px` steel jambs block non-portal boundary edges
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_archway_frame_e_idle.pxo`
  - Export: `assets/environments/ch01/ch01_env_archway_frame_e_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.8 `ch01.prop.digital_clock_2359` — Station Digital Clock Frozen at `23:59`
- **Asset ID:** `ch01.prop.digital_clock_2359` (`prop_digital_clock_2359` in `ROOM_GRAPH.md` §7.2)
- **Filename:** `ch01_prop_digital_clock_2359_idle.pxo` / `ch01_prop_digital_clock_2359_idle.png`
- **Category & Chapter/Room:** Prop (Wall/Suspended Fixture) · Chapter 1 (Reused in Rooms 1, 2, 5, 7, 9, 10)
- **Pixel Dimensions & In-Game Scale:** **`32 × 24 px`** (`1.0×` scale; `2.0×` integer scale optional for the monumental Atrium clock in Room 9)
- **Pivot / Origin & Sorting Layer:** Pivot **`(16, 20)`** (bottom housing center) · `Wall_Fixtures` (`z_index = 7`)
- **Animation Frame Count, FPS & Tags:** `1` frame (`6 FPS` base timeline), `3` layers (`Steel_Casing_And_Mount`, `Crimson_Matrix_Screen`, `Digits_2359_Glow`)
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`11` colors used: indices `00, 11, 12, 13, 14, 15, 22, 23, 24, 25, 26`; `0` off-palette; `0` semi-transparent pixels)
- **Collision / Interaction Footprint:** Mounted overhead on wall (`y_offset = -38 px` above wall base); optional inspect `Interactable` (`36 px` radius) on platform/concourse floor below
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_prop_digital_clock_2359_idle.pxo`
  - Export: `assets/props/ch01/ch01_prop_digital_clock_2359_idle.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.9 `ch01.env.arrival_platform.target_sheet` — `ch01.arrival_platform` `640 × 360` Target Sheet
- **Asset ID:** `ch01.env.arrival_platform.target_sheet`
- **Filename:** `ch01_env_arrival_platform_target_sheet.pxo` / `ch01_env_arrival_platform_target_sheet.png`
- **Category & Chapter/Room:** Target Composition · Chapter 1, Room 1 (`ch01.arrival_platform`, `14 × 10` tiles = `384 × 192 px` floor diamond anchored at top apex `(320, 64)`)
- **Pixel Dimensions & In-Game Scale:** **`640 × 360 px`** (`1:1` true internal viewport scale per `ADR-003`)
- **Pivot / Origin & Sorting Layer:** Top-left `(0, 0)` · Full scene reference composition (`6` layers in `.pxo`: `Subterranean_Void_And_Track_Bed`, `Floor_Tiles_14x10_Kit`, `Walls_And_Doorway_Kit`, `Station_Props_And_Clock_2359`, `Elias_At_Spawn_7_5`, `Atmosphere_And_HUD_Overlay`)
- **Composition Contents Verified at True Scale:**
  - `14 × 10` floor grid assembled from `ch01_env_tile_terrazzo_dark_idle.png`, `ch01_env_tile_terrazzo_cracked_idle.png`, and `ch01_env_tile_tactile_amber_idle.png`
  - North-East (`7 × ch01_env_wall_subterranean_n_idle.png`) and North-West (`5 × ch01_env_wall_subterranean_w_idle.png`) walls meeting at `(320, 64)`
  - East doorway frame (`ch01_env_archway_frame_e_idle.png`) at `ch01.arrival_platform:door_exit_east` (`(13, 5)` / `(448, 208)`)
  - Two wall-mounted `ch01_prop_digital_clock_2359_idle.png` fixtures displaying `23:59`
  - Isometric stalled Mag-Transit car along the South-West trench (`y = 9`), platform bench at `(4, 2)`, and damaged pocket watch pickup (`global.pocket_watch`) at `(8, 5)`
  - Elias (`idle_se` frame 1 from `ch01_char_elias_base_sheet.png`) placed at `ch01.arrival_platform.safe_anchor_spawn` (`(7, 5)` / foot pivot `(352, 168)`)
  - Diegetic HUD location header, `TIME 23:59` indicator, and `[E] POCKET WATCH ( DAMAGED )` prompt rendered at `8 px` using `assets/ui/fonts/tlf_pixel_mono.ttf`
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`30` colors used; `0` off-palette; `0` semi-transparent pixels)
- **Source & Export Paths:**
  - Source: `assets/source/ch01/ch01_env_arrival_platform_target_sheet.pxo`
  - Export: `assets/environments/ch01/ch01_env_arrival_platform_target_sheet.png`
- **License / Attribution:** Original production art by Agent 2 (Argon) (`CC0-1.0` / project-owned).
- **QA State:** **`exported`**

---

### 2.10 `global.ui.font.tlf_pixel_mono` — UI Pixel Font (`TLF Pixel Mono Regular`)
- **Asset ID:** `global.ui.font.tlf_pixel_mono`
- **Filename:** `tlf_pixel_mono.ttf` + `LICENSE.txt`
- **Category & Chapter/Room:** UI Font · Global (All chapters, HUD, Journal, Menus, Subtitles)
- **Pixel Dimensions & In-Game Scale:** `5 × 7 px` glyph bitmap contours inside a `6 × 8 px` monospace cell (`unitsPerEm = 512`, `1 px = 64 units`); rendered at `8 px` (`1×`), `16 px` (`2×`), and `24 px` (`3×`) on the `640 × 360` viewport
- **Source & Export Paths:**
  - Font: `assets/ui/fonts/tlf_pixel_mono.ttf`
  - License: `assets/ui/fonts/LICENSE.txt`
- **License / Attribution:** **CC0 1.0 Universal (Public Domain Dedication)** — original pixel font authored by Agent 2 (Argon) for *The Last Frame*.
- **QA State:** **`exported`**

---

## 3. Batch 2 Summary Inventory Table (`TLF-039`)

**Task:** TLF-039 · **Author:** design-art agent (Claude Code, Sonnet 5.5, standing in for Argon, RISK-019) · **Palette:** `TLF-CH01-32`, `0` off-palette, `0` semi-transparent pixels · **Authoring:** every pixel is placed by a deterministic script using palette indices only, which writes layered `.pxo` files; every `.pxo` passes `Pixelorama.exe --headless --quit -- --size` and `--export --spritesheet`, and each committed PNG is the byte-identical re-export (raw logs in `design/art/TLF-039_VERIFICATION.txt`). **No AI-generated or third-party images.** Elias v2 replaces the batch-1 sheet in place (section 2.1). Rows 27-38 are Tier 2 hero set-pieces (TLF-039); rows 39-52 are TLF-042, rows 53-54 are TLF-044 (frozen capacitor split) (route board, security gate, bridge, transit car, dispatch terminal, pocket watch, lever badges, PA horn), which completes every ROOM_GRAPH §7.3 piece.

| # | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **12** | `ch01.env.tile.industrial_grating` | Environment (Floor Tile) | `ch01_env_tile_industrial_grating_idle.pxo` | `assets/environments/ch01/ch01_env_tile_industrial_grating_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `5 / 32` | **`exported`** |
| **13** | `ch01.env.tile.concrete_service` | Environment (Floor Tile) | `ch01_env_tile_concrete_service_idle.pxo` | `assets/environments/ch01/ch01_env_tile_concrete_service_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `3 / 32` | **`exported`** |
| **14** | `ch01.env.tile.cable_conduit_off` | Environment (Floor Tile) | `ch01_env_tile_cable_conduit_off_idle.pxo` | `assets/environments/ch01/ch01_env_tile_cable_conduit_off_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `8 / 32` | **`exported`** |
| **15** | `ch01.env.tile.cable_conduit_on` | Environment (Floor Tile) | `ch01_env_tile_cable_conduit_on_idle.pxo` | `assets/environments/ch01/ch01_env_tile_cable_conduit_on_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `8 / 32` | **`exported`** |
| **16** | `ch01.env.tile.stone_step_wet` | Environment (Floor Tile) | `ch01_env_tile_stone_step_wet_idle.pxo` | `assets/environments/ch01/ch01_env_tile_stone_step_wet_idle.png` | `32 × 16 px` | `1f` (`static`) | `(16, 8)` | `TileMapLayer_Floor` (`z_index = 0`) | `5 / 32` | **`exported`** |
| **17** | `ch01.env.wall.corner_pillar` | Environment (Wall Module) | `ch01_env_wall_corner_pillar_idle.pxo` | `assets/environments/ch01/ch01_env_wall_corner_pillar_idle.png` | `32 × 64 px` | `1f` (`static`) | `(16, 56)` | `YSort_Walls` (`z_index = 5`) | `11 / 32` | **`exported`** |
| **18** | `ch01.env.archway.frame_n` | Environment (Doorway Frame) | `ch01_env_archway_frame_n_idle.pxo` | `assets/environments/ch01/ch01_env_archway_frame_n_idle.png` | `32 × 64 px` | `1f` (`static`) | `(16, 56)` | `YSort_Walls` (`z_index = 6`) | `11 / 32` | **`exported`** |
| **19** | `ch01.env.wall.railing_iron` | Environment (Railing) | `ch01_env_wall_railing_iron_idle.pxo` | `assets/environments/ch01/ch01_env_wall_railing_iron_idle.png` | `32 × 48 px` | `1f` (`static`) | `(16, 40)` | `YSort_Props` (`z_index = 8`) | `7 / 32` | **`exported`** |
| **20** | `ch01.prop.station_bench` | Prop (Medium Floor Prop) | `ch01_prop_station_bench_idle.pxo` | `assets/props/ch01/ch01_prop_station_bench_idle.png` | `48 × 32 px` | `1f` (`static`) | `(24, 26)` | `YSort_Actors` (`z_index = 10`) | `6 / 32` | **`exported`** |
| **21** | `ch01.prop.call_box_phone` | Prop (Wall Fixture) | `ch01_prop_call_box_phone_idle.pxo` | `assets/props/ch01/ch01_prop_call_box_phone_idle.png` | `24 × 36 px` | `1f` (`static`) | `(12, 32)` | `Wall_Fixtures` (`z_index = 7`) | `7 / 32` | **`exported`** |
| **22** | `ch01.prop.call_box_phone.ringing` | Prop (Wall Fixture) | `ch01_prop_call_box_phone_ringing.pxo` | `assets/props/ch01/ch01_prop_call_box_phone_ringing.png` | `24 × 36 px` | `1f` (`static`) | `(12, 32)` | `Wall_Fixtures` (`z_index = 7`) | `8 / 32` | **`exported`** |
| **23** | `ch01.prop.reset_console` | Prop (Medium Floor Prop) | `ch01_prop_reset_console_idle.pxo` | `assets/props/ch01/ch01_prop_reset_console_idle.png` | `32 × 36 px` | `1f` (`static`) | `(16, 30)` | `YSort_Actors` (`z_index = 10`) | `10 / 32` | **`exported`** |
| **24** | `ch01.prop.lever_switch.off` | Prop (Fixture) | `ch01_prop_lever_switch_off.pxo` | `assets/props/ch01/ch01_prop_lever_switch_off.png` | `24 × 32 px` | `1f` (`static`) | `(12, 28)` | `Wall_Fixtures` (`z_index = 7`), see OQ-2 | `8 / 32` | **`exported`** |
| **25** | `ch01.prop.lever_switch.on` | Prop (Fixture) | `ch01_prop_lever_switch_on.pxo` | `assets/props/ch01/ch01_prop_lever_switch_on.png` | `24 × 32 px` | `1f` (`static`) | `(12, 28)` | `Wall_Fixtures` (`z_index = 7`), see OQ-2 | `9 / 32` | **`exported`** |
| **26** | `ch01.prop.document_clipboard` | Prop (Floor Pickup) | `ch01_prop_document_clipboard_idle.pxo` | `assets/props/ch01/ch01_prop_document_clipboard_idle.png` | `16 × 16 px` | `1f` (`static`) | `(8, 12)` | `YSort_Props` (`z_index = 8`) | `8 / 32` | **`exported`** |
| **27** | `ch01.prop.turnstile_gate_collapsed` | Prop (Medium Floor Prop) | `ch01_prop_turnstile_gate_collapsed.pxo` | `assets/props/ch01/ch01_prop_turnstile_gate_collapsed.png` | `32 × 40 px` | `1f` (`static`) | `(16, 34)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **28** | `ch01.prop.turnstile_gate_open` | Prop (Medium Floor Prop) | `ch01_prop_turnstile_gate_open.pxo` | `assets/props/ch01/ch01_prop_turnstile_gate_open.png` | `32 × 40 px` | `1f` (`static`) | `(16, 34)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **29** | `ch01.prop.fire_shutter_closed` | Prop (Large Hero Mechanism) | `ch01_prop_fire_shutter_closed.pxo` | `assets/props/ch01/ch01_prop_fire_shutter_closed.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **30** | `ch01.prop.fire_shutter_raised` | Prop (Large Hero Mechanism) | `ch01_prop_fire_shutter_raised.pxo` | `assets/props/ch01/ch01_prop_fire_shutter_raised.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `7 / 32` | **`exported`** |
| **31** | `ch01.prop.counterweight_gear_idle` | Prop (Large Hero Mechanism) | `ch01_prop_counterweight_gear_idle.pxo` | `assets/props/ch01/ch01_prop_counterweight_gear_idle.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `6 / 32` | **`exported`** |
| **32** | `ch01.prop.counterweight_gear_slipping` | Prop (Large Hero Mechanism) | `ch01_prop_counterweight_gear_slipping.pxo` | `assets/props/ch01/ch01_prop_counterweight_gear_slipping.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `9 / 32` | **`exported`** |
| **33** | `ch01.prop.counterweight_gear_frozen` | Prop (Large Hero Mechanism) | `ch01_prop_counterweight_gear_frozen.pxo` | `assets/props/ch01/ch01_prop_counterweight_gear_frozen.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **34** | `ch01.prop.surge_capacitor_discharged` | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_discharged.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_discharged.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `7 / 32` | **`exported`** |
| **35** | `ch01.prop.surge_capacitor_charged` | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_charged.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_charged.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `9 / 32` | **`exported`** |
| **36** | `ch01.prop.surge_capacitor_frozen` **(deprecated, TLF-044)** | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_frozen.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_frozen.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **37** | `ch01.prop.pressure_switch_released` | Prop (Floor Plate) | `ch01_prop_pressure_switch_released.pxo` | `assets/props/ch01/ch01_prop_pressure_switch_released.png` | `32 × 20 px` | `1f` (`static`) | `(16, 12)` | `YSort_Props` (`z_index = 8`) | `5 / 32` | **`exported`** |
| **38** | `ch01.prop.pressure_switch_pressed` | Prop (Floor Plate) | `ch01_prop_pressure_switch_pressed.pxo` | `assets/props/ch01/ch01_prop_pressure_switch_pressed.png` | `32 × 20 px` | `1f` (`static`) | `(16, 12)` | `YSort_Props` (`z_index = 8`) | `7 / 32` | **`exported`** |
| **39** | `ch01.prop.route_board.state0` | Prop (Free-standing Sign) | `ch01_prop_route_board_state0.pxo` | `assets/props/ch01/ch01_prop_route_board_state0.png` | `48 × 56 px` | `1f` (`static`) | `(24, 50)` | `YSort_Actors` (`z_index = 10`) | `6 / 32` | **`exported`** |
| **40** | `ch01.prop.route_board.state1` | Prop (Free-standing Sign) | `ch01_prop_route_board_state1.pxo` | `assets/props/ch01/ch01_prop_route_board_state1.png` | `48 × 56 px` | `1f` (`static`) | `(24, 50)` | `YSort_Actors` (`z_index = 10`) | `6 / 32` | **`exported`** |
| **41** | `ch01.prop.route_board.state2` | Prop (Free-standing Sign) | `ch01_prop_route_board_state2.pxo` | `assets/props/ch01/ch01_prop_route_board_state2.png` | `48 × 56 px` | `1f` (`static`) | `(24, 50)` | `YSort_Actors` (`z_index = 10`) | `6 / 32` | **`exported`** |
| **42** | `ch01.prop.security_gate.closed` | Prop (Large Hero Mechanism) | `ch01_prop_security_gate_closed.pxo` | `assets/props/ch01/ch01_prop_security_gate_closed.png` | `40 × 52 px` | `1f` (`static`) | `(20, 42)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
| **43** | `ch01.prop.security_gate.open` | Prop (Large Hero Mechanism) | `ch01_prop_security_gate_open.pxo` | `assets/props/ch01/ch01_prop_security_gate_open.png` | `40 × 52 px` | `1f` (`static`) | `(20, 42)` | `YSort_Actors` (`z_index = 10`) | `9 / 32` | **`exported`** |
| **44** | `ch01.prop.bridge_platform.retracted` | Prop (Floor Deck) | `ch01_prop_bridge_platform_retracted.pxo` | `assets/props/ch01/ch01_prop_bridge_platform_retracted.png` | `48 × 32 px` | `1f` (`static`) | `(24, 18)` | `YSort_Props` (`z_index = 8`) | `6 / 32` | **`exported`** |
| **45** | `ch01.prop.bridge_platform.extended` | Prop (Floor Deck) | `ch01_prop_bridge_platform_extended.pxo` | `assets/props/ch01/ch01_prop_bridge_platform_extended.png` | `48 × 32 px` | `1f` (`static`) | `(24, 18)` | `YSort_Props` (`z_index = 8`) | `6 / 32` | **`exported`** |
| **46** | `ch01.prop.transit_car_stalled` | Prop (Large Set-piece) | `ch01_prop_transit_car_stalled_idle.pxo` | `assets/props/ch01/ch01_prop_transit_car_stalled_idle.png` | `128 × 80 px` | `1f` (`static`) | `(64, 52)` | `YSort_Actors` (`z_index = 10`) | `11 / 32` | **`exported`** |
| **47** | `ch01.prop.dispatch_terminal.idle` | Prop (Large Hero Mechanism) | `ch01_prop_dispatch_terminal_idle.pxo` | `assets/props/ch01/ch01_prop_dispatch_terminal_idle.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `7 / 32` | **`exported`** |
| **48** | `ch01.prop.dispatch_terminal.active` | Prop (Large Hero Mechanism) | `ch01_prop_dispatch_terminal_active.pxo` | `assets/props/ch01/ch01_prop_dispatch_terminal_active.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `10 / 32` | **`exported`** |
| **49** | `ch01.prop.pocket_watch` | Prop (Floor Pickup) | `ch01_prop_pocket_watch_idle.pxo` | `assets/props/ch01/ch01_prop_pocket_watch_idle.png` | `16 × 16 px` | `1f` (`static`) | `(8, 12)` | `YSort_Props` (`z_index = 8`) | `4 / 32` | **`exported`** |
| **50** | `ch01.prop.lever_badge_a` | Prop (Overlay) | `ch01_prop_lever_badge_a_idle.pxo` | `assets/props/ch01/ch01_prop_lever_badge_a_idle.png` | `5 × 7 px` | `1f` (`static`) | `(2, 3)` | child of the lever, same `z_index` | `2 / 32` | **`exported`** |
| **51** | `ch01.prop.lever_badge_b` | Prop (Overlay) | `ch01_prop_lever_badge_b_idle.pxo` | `assets/props/ch01/ch01_prop_lever_badge_b_idle.png` | `5 × 7 px` | `1f` (`static`) | `(2, 3)` | child of the lever, same `z_index` | `2 / 32` | **`exported`** |
| **52** | `ch01.prop.pa_speaker` | Prop (Wall Fixture) | `ch01_prop_pa_speaker_idle.pxo` | `assets/props/ch01/ch01_prop_pa_speaker_idle.png` | `16 × 16 px` | `1f` (`static`) | `(8, 12)` | `Wall_Fixtures` (`z_index = 7`) | `6 / 32` | **`exported`** |
| **53** | `ch01.prop.surge_capacitor.frozen_charged` | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_frozen_charged.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_frozen_charged.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `9 / 32` | **`exported`** |
| **54** | `ch01.prop.surge_capacitor.frozen_discharged` | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_frozen_discharged.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_frozen_discharged.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `9 / 32` | **`exported`** |

---

## 4. Batch 2 Detailed `ART_PIPELINE.md` Records

Common to all entries: **License / Attribution:** original production art by the TLF-039 design-art agent (Claude Code, Sonnet 5.5), `CC0-1.0` / project-owned; source format `.pxo` (Pixelorama 1.2.3); **QA state `exported`** (not yet imported or tested in Godot). Outline rule per bible §5.1: floor tiles and wall modules have no outer outline; props and the railing carry a 1 px `#0A0D14` outline. Collision/interaction: floor tiles walkable; walls/pillar/railing static blockers (shape set by Flash); props per `CH01_PLACEMENT_SHEET.md`.

### `ch01.env.tile.industrial_grating`
- **Filename:** `ch01_env_tile_industrial_grating_idle.pxo` / `ch01_env_tile_industrial_grating_idle.png` · **Category / use:** Environment (Floor Tile) · Rooms 3, 4, 6
- **Pixel dimensions:** `32 × 16 px` (`1.0×`) · **Pivot / sorting:** `(16, 8)` · `TileMapLayer_Floor` (`z_index = 0`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,01,11,13,14`
- **Source / export:** `assets/source/ch01/ch01_env_tile_industrial_grating_idle.pxo` → `assets/environments/ch01/ch01_env_tile_industrial_grating_idle.png`

### `ch01.env.tile.concrete_service`
- **Filename:** `ch01_env_tile_concrete_service_idle.pxo` / `ch01_env_tile_concrete_service_idle.png` · **Category / use:** Environment (Floor Tile) · Rooms 3, 4, 6
- **Pixel dimensions:** `32 × 16 px` (`1.0×`) · **Pivot / sorting:** `(16, 8)` · `TileMapLayer_Floor` (`z_index = 0`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `11,12,13`
- **Source / export:** `assets/source/ch01/ch01_env_tile_concrete_service_idle.pxo` → `assets/environments/ch01/ch01_env_tile_concrete_service_idle.png`

### `ch01.env.tile.cable_conduit_off`
- **Filename:** `ch01_env_tile_cable_conduit_off_idle.pxo` / `ch01_env_tile_cable_conduit_off_idle.png` · **Category / use:** Environment (Floor Tile) · Rooms 3, 4, 6, 7; `[>>>]` runs down-right (+x axis); `flip_h` for the +y axis
- **Pixel dimensions:** `32 × 16 px` (`1.0×`) · **Pivot / sorting:** `(16, 8)` · `TileMapLayer_Floor` (`z_index = 0`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `01,02,03,04,11,12,13,14`
- **Source / export:** `assets/source/ch01/ch01_env_tile_cable_conduit_off_idle.pxo` → `assets/environments/ch01/ch01_env_tile_cable_conduit_off_idle.png`

### `ch01.env.tile.cable_conduit_on`
- **Filename:** `ch01_env_tile_cable_conduit_on_idle.pxo` / `ch01_env_tile_cable_conduit_on_idle.png` · **Category / use:** Environment (Floor Tile) · Rooms 3, 4, 6, 7; powered state of `cable_conduit_off` (chevrons lit amber)
- **Pixel dimensions:** `32 × 16 px` (`1.0×`) · **Pivot / sorting:** `(16, 8)` · `TileMapLayer_Floor` (`z_index = 0`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `01,02,03,04,11,14,25,26`
- **Source / export:** `assets/source/ch01/ch01_env_tile_cable_conduit_on_idle.pxo` → `assets/environments/ch01/ch01_env_tile_cable_conduit_on_idle.png`

### `ch01.env.tile.stone_step_wet`
- **Filename:** `ch01_env_tile_stone_step_wet_idle.pxo` / `ch01_env_tile_stone_step_wet_idle.png` · **Category / use:** Environment (Floor Tile) · Rooms 9, 10
- **Pixel dimensions:** `32 × 16 px` (`1.0×`) · **Pivot / sorting:** `(16, 8)` · `TileMapLayer_Floor` (`z_index = 0`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `01,02,03,04,05`
- **Source / export:** `assets/source/ch01/ch01_env_tile_stone_step_wet_idle.pxo` → `assets/environments/ch01/ch01_env_tile_stone_step_wet_idle.png`

### `ch01.env.wall.corner_pillar`
- **Filename:** `ch01_env_wall_corner_pillar_idle.pxo` / `ch01_env_wall_corner_pillar_idle.png` · **Category / use:** Environment (Wall Module) · All rooms (convex corner post)
- **Pixel dimensions:** `32 × 64 px` (`1.0×`) · **Pivot / sorting:** `(16, 56)` · `YSort_Walls` (`z_index = 5`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,06,07,08,11,12,13,14,15,24,25`
- **Source / export:** `assets/source/ch01/ch01_env_wall_corner_pillar_idle.pxo` → `assets/environments/ch01/ch01_env_wall_corner_pillar_idle.png`

### `ch01.env.archway.frame_n`
- **Filename:** `ch01_env_archway_frame_n_idle.pxo` / `ch01_env_archway_frame_n_idle.png` · **Category / use:** Environment (Doorway Frame) · N and S doorways (down-right slope), see 4.1
- **Pixel dimensions:** `32 × 64 px` (`1.0×`) · **Pivot / sorting:** `(16, 56)` · `YSort_Walls` (`z_index = 6`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,01,02,11,12,13,14,15,25,26,29`
- **Source / export:** `assets/source/ch01/ch01_env_archway_frame_n_idle.pxo` → `assets/environments/ch01/ch01_env_archway_frame_n_idle.png`

### `ch01.env.wall.railing_iron`
- **Filename:** `ch01_env_wall_railing_iron_idle.pxo` / `ch01_env_wall_railing_iron_idle.png` · **Category / use:** Environment (Railing) · Rooms 1, 4, 5, 6, 8; runs down-right (+x axis); `flip_h` for the +y axis
- **Pixel dimensions:** `32 × 48 px` (`1.0×`) · **Pivot / sorting:** `(16, 40)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25`
- **Source / export:** `assets/source/ch01/ch01_env_wall_railing_iron_idle.pxo` → `assets/environments/ch01/ch01_env_wall_railing_iron_idle.png`

### `ch01.prop.station_bench`
- **Filename:** `ch01_prop_station_bench_idle.pxo` / `ch01_prop_station_bench_idle.png` · **Category / use:** Prop (Medium Floor Prop) · Rooms 1, 2, 5, 9; runs down-right; `flip_h` for the +y axis
- **Pixel dimensions:** `48 × 32 px` (`1.0×`) · **Pivot / sorting:** `(24, 26)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15`
- **Source / export:** `assets/source/ch01/ch01_prop_station_bench_idle.pxo` → `assets/props/ch01/ch01_prop_station_bench_idle.png`

### `ch01.prop.call_box_phone`
- **Filename:** `ch01_prop_call_box_phone_idle.pxo` / `ch01_prop_call_box_phone_idle.png` · **Category / use:** Prop (Wall Fixture) · Room 2 (`call_box_09`), Room 6 intercom, Room 10 (`plaza_payphone`)
- **Pixel dimensions:** `24 × 36 px` (`1.0×`) · **Pivot / sorting:** `(12, 32)` · `Wall_Fixtures` (`z_index = 7`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22`
- **Source / export:** `assets/source/ch01/ch01_prop_call_box_phone_idle.pxo` → `assets/props/ch01/ch01_prop_call_box_phone_idle.png`

### `ch01.prop.call_box_phone.ringing`
- **Filename:** `ch01_prop_call_box_phone_ringing.pxo` / `ch01_prop_call_box_phone_ringing.png` · **Category / use:** Prop (Wall Fixture) · Ringing state: lit lamp plus 6 ring marks (shape cue, not colour only)
- **Pixel dimensions:** `24 × 36 px` (`1.0×`) · **Pivot / sorting:** `(12, 32)` · `Wall_Fixtures` (`z_index = 7`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_call_box_phone_ringing.pxo` → `assets/props/ch01/ch01_prop_call_box_phone_ringing.png`

### `ch01.prop.reset_console`
- **Filename:** `ch01_prop_reset_console_idle.pxo` / `ch01_prop_reset_console_idle.png` · **Category / use:** Prop (Medium Floor Prop) · `reset_anchor_01` in Rooms 2, 3, 4, 6, 7
- **Pixel dimensions:** `32 × 36 px` (`1.0×`) · **Pivot / sorting:** `(16, 30)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22,24,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_reset_console_idle.pxo` → `assets/props/ch01/ch01_prop_reset_console_idle.png`

### `ch01.prop.lever_switch.off`
- **Filename:** `ch01_prop_lever_switch_off.pxo` / `ch01_prop_lever_switch_off.png` · **Category / use:** Prop (Fixture) · `breaker_a/b` (Room 6), `junction_lever_a/b` (Room 7); lever tilted back, lamp dark
- **Pixel dimensions:** `24 × 32 px` (`1.0×`) · **Pivot / sorting:** `(12, 28)` · `Wall_Fixtures` (`z_index = 7`), see OQ-2
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22,23`
- **Source / export:** `assets/source/ch01/ch01_prop_lever_switch_off.pxo` → `assets/props/ch01/ch01_prop_lever_switch_off.png`

### `ch01.prop.lever_switch.on`
- **Filename:** `ch01_prop_lever_switch_on.pxo` / `ch01_prop_lever_switch_on.png` · **Category / use:** Prop (Fixture) · Lever tilted forward, lamp lit
- **Pixel dimensions:** `24 × 32 px` (`1.0×`) · **Pivot / sorting:** `(12, 28)` · `Wall_Fixtures` (`z_index = 7`), see OQ-2
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,24,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_lever_switch_on.pxo` → `assets/props/ch01/ch01_prop_lever_switch_on.png`

### `ch01.prop.document_clipboard`
- **Filename:** `ch01_prop_document_clipboard_idle.pxo` / `ch01_prop_document_clipboard_idle.png` · **Category / use:** Prop (Floor Pickup) · `doc_evac_notice`, `doc_tech_log`, `transit_pass_pickup`, `audio_mira_01`, `doc_index_plaque`
- **Pixel dimensions:** `16 × 16 px` (`1.0×`) · **Pivot / sorting:** `(8, 12)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25,31`
- **Source / export:** `assets/source/ch01/ch01_prop_document_clipboard_idle.pxo` → `assets/props/ch01/ch01_prop_document_clipboard_idle.png`

### `ch01.prop.turnstile_gate_collapsed`
- **Filename:** `ch01_prop_turnstile_gate_collapsed.pxo` / `ch01_prop_turnstile_gate_collapsed.png` · **Category / use:** Prop (Medium Floor Prop) · Room 2 `turnstile_gate`, arm snapped, lamp dead (Tier 2)
- **Pixel dimensions:** `32 × 40 px` (`1.0×`) · **Pivot / sorting:** `(16, 34)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22,24`
- **Source / export:** `assets/source/ch01/ch01_prop_turnstile_gate_collapsed.pxo` → `assets/props/ch01/ch01_prop_turnstile_gate_collapsed.png`

### `ch01.prop.turnstile_gate_open`
- **Filename:** `ch01_prop_turnstile_gate_open.pxo` / `ch01_prop_turnstile_gate_open.png` · **Category / use:** Prop (Medium Floor Prop) · arm folded up, lamp lit (Tier 2)
- **Pixel dimensions:** `32 × 40 px` (`1.0×`) · **Pivot / sorting:** `(16, 34)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_turnstile_gate_open.pxo` → `assets/props/ch01/ch01_prop_turnstile_gate_open.png`

### `ch01.prop.fire_shutter_closed`
- **Filename:** `ch01_prop_fire_shutter_closed.pxo` / `ch01_prop_fire_shutter_closed.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 3 `fire_shutter`; spans 2 tiles on the +x axis; slats down (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,24,25`
- **Source / export:** `assets/source/ch01/ch01_prop_fire_shutter_closed.pxo` → `assets/props/ch01/ch01_prop_fire_shutter_closed.png`

### `ch01.prop.fire_shutter_raised`
- **Filename:** `ch01_prop_fire_shutter_raised.pxo` / `ch01_prop_fire_shutter_raised.png` · **Category / use:** Prop (Large Hero Mechanism) · slats rolled into the housing, opening clear (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,24`
- **Source / export:** `assets/source/ch01/ch01_prop_fire_shutter_raised.pxo` → `assets/props/ch01/ch01_prop_fire_shutter_raised.png`

### `ch01.prop.counterweight_gear_idle`
- **Filename:** `ch01_prop_counterweight_gear_idle.pxo` / `ch01_prop_counterweight_gear_idle.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 3 `counterweight_gear` (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15`
- **Source / export:** `assets/source/ch01/ch01_prop_counterweight_gear_idle.pxo` → `assets/props/ch01/ch01_prop_counterweight_gear_idle.png`

### `ch01.prop.counterweight_gear_slipping`
- **Filename:** `ch01_prop_counterweight_gear_slipping.pxo` / `ch01_prop_counterweight_gear_slipping.png` · **Category / use:** Prop (Large Hero Mechanism) · weight lowered 6 px, sparks + slip marks (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,24,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_counterweight_gear_slipping.pxo` → `assets/props/ch01/ch01_prop_counterweight_gear_slipping.png`

### `ch01.prop.counterweight_gear_frozen`
- **Filename:** `ch01_prop_counterweight_gear_frozen.pxo` / `ch01_prop_counterweight_gear_frozen.png` · **Category / use:** Prop (Large Hero Mechanism) · Freeze language: 2 px corner L-brackets + teal dashes, no motion (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,27,31`
- **Source / export:** `assets/source/ch01/ch01_prop_counterweight_gear_frozen.pxo` → `assets/props/ch01/ch01_prop_counterweight_gear_frozen.png`

### `ch01.prop.surge_capacitor_discharged`
- **Filename:** `ch01_prop_surge_capacitor_discharged.pxo` / `ch01_prop_surge_capacitor_discharged.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 6 `surge_capacitor` (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22`
- **Source / export:** `assets/source/ch01/ch01_prop_surge_capacitor_discharged.pxo` → `assets/props/ch01/ch01_prop_surge_capacitor_discharged.png`

### `ch01.prop.surge_capacitor_charged`
- **Filename:** `ch01_prop_surge_capacitor_charged.pxo` / `ch01_prop_surge_capacitor_charged.png` · **Category / use:** Prop (Large Hero Mechanism) · lit bands + jagged arc between terminals (shape cue) (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25,26,31`
- **Source / export:** `assets/source/ch01/ch01_prop_surge_capacitor_charged.pxo` → `assets/props/ch01/ch01_prop_surge_capacitor_charged.png`

### `ch01.prop.surge_capacitor_frozen` **(deprecated, TLF-044)**
- **Deprecated:** replaced by `surge_capacitor_frozen_charged` / `_frozen_discharged` (rows 53-54). The file is kept unchanged until TLF-041 has switched over; do not use it for new work.
- **Filename:** `ch01_prop_surge_capacitor_frozen.pxo` / `ch01_prop_surge_capacitor_frozen.png` · **Category / use:** Prop (Large Hero Mechanism) · Freeze language (Tier 2)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,27,31`
- **Source / export:** `assets/source/ch01/ch01_prop_surge_capacitor_frozen.pxo` → `assets/props/ch01/ch01_prop_surge_capacitor_frozen.png`

### `ch01.prop.pressure_switch_released`
- **Filename:** `ch01_prop_pressure_switch_released.pxo` / `ch01_prop_pressure_switch_released.png` · **Category / use:** Prop (Floor Plate) · Room 4 `pressure_switch_01`; raised plate, dead lamp (Tier 2)
- **Pixel dimensions:** `32 × 20 px` (`1.0×`) · **Pivot / sorting:** `(16, 12)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,12,13,14,22`
- **Source / export:** `assets/source/ch01/ch01_prop_pressure_switch_released.pxo` → `assets/props/ch01/ch01_prop_pressure_switch_released.png`

### `ch01.prop.pressure_switch_pressed`
- **Filename:** `ch01_prop_pressure_switch_pressed.pxo` / `ch01_prop_pressure_switch_pressed.png` · **Category / use:** Prop (Floor Plate) · flush plate, lit amber ring (Tier 2)
- **Pixel dimensions:** `32 × 20 px` (`1.0×`) · **Pivot / sorting:** `(16, 12)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,24,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_pressure_switch_pressed.pxo` → `assets/props/ch01/ch01_prop_pressure_switch_pressed.png`

### `ch01.prop.route_board.state0`
- **Filename:** `ch01_prop_route_board_state0.pxo` / `ch01_prop_route_board_state0.png` · **Category / use:** Prop (Free-standing Sign) · Room 7 `route_board`; derived state 0 = lever A `loop` + lever B `niche`; 1 lit pip, links N-W and E-S (TLF-042)
- **Pixel dimensions:** `48 × 56 px` (`1.0×`) · **Pivot / sorting:** `(24, 50)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,12,13,15,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_route_board_state0.pxo` → `assets/props/ch01/ch01_prop_route_board_state0.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.route_board.state1`
- **Filename:** `ch01_prop_route_board_state1.pxo` / `ch01_prop_route_board_state1.png` · **Category / use:** Prop (Free-standing Sign) · state 1 = A `uncoupled` + B `niche`; 2 lit pips, cross pattern (TLF-042)
- **Pixel dimensions:** `48 × 56 px` (`1.0×`) · **Pivot / sorting:** `(24, 50)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,12,13,15,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_route_board_state1.pxo` → `assets/props/ch01/ch01_prop_route_board_state1.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.route_board.state2`
- **Filename:** `ch01_prop_route_board_state2.pxo` / `ch01_prop_route_board_state2.png` · **Category / use:** Prop (Free-standing Sign) · state 2 = A `uncoupled` + B `atrium` (solved); 3 lit pips, single N-S line (TLF-042)
- **Pixel dimensions:** `48 × 56 px` (`1.0×`) · **Pivot / sorting:** `(24, 50)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,12,13,15,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_route_board_state2.pxo` → `assets/props/ch01/ch01_prop_route_board_state2.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.security_gate.closed`
- **Filename:** `ch01_prop_security_gate_closed.pxo` / `ch01_prop_security_gate_closed.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 4 `security_gate_01`, `gate_state = &"closed"`; barrier spans the lane along the y axis (TLF-042)
- **Pixel dimensions:** `40 × 52 px` (`1.0×`) · **Pivot / sorting:** `(20, 42)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22,24`
- **Source / export:** `assets/source/ch01/ch01_prop_security_gate_closed.pxo` → `assets/props/ch01/ch01_prop_security_gate_closed.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.security_gate.open`
- **Filename:** `ch01_prop_security_gate_open.pxo` / `ch01_prop_security_gate_open.png` · **Category / use:** Prop (Large Hero Mechanism) · `gate_state = &"open"`; bars retracted to stubs, lamp lit (TLF-042)
- **Pixel dimensions:** `40 × 52 px` (`1.0×`) · **Pivot / sorting:** `(20, 42)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,24,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_security_gate_open.pxo` → `assets/props/ch01/ch01_prop_security_gate_open.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.bridge_platform.retracted`
- **Filename:** `ch01_prop_bridge_platform_retracted.pxo` / `ch01_prop_bridge_platform_retracted.png` · **Category / use:** Prop (Floor Deck) · Room 4 `bridge_platform_01`, `platform_state = &"retracted"`; only the two hazard-striped lip stubs (TLF-042)
- **Pixel dimensions:** `48 × 32 px` (`1.0×`) · **Pivot / sorting:** `(24, 18)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,22,24`
- **Source / export:** `assets/source/ch01/ch01_prop_bridge_platform_retracted.pxo` → `assets/props/ch01/ch01_prop_bridge_platform_retracted.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.bridge_platform.extended`
- **Filename:** `ch01_prop_bridge_platform_extended.pxo` / `ch01_prop_bridge_platform_extended.png` · **Category / use:** Prop (Floor Deck) · `platform_state = &"extended"`; deck 2 tiles long, guide lights, hazard ends (TLF-042)
- **Pixel dimensions:** `48 × 32 px` (`1.0×`) · **Pivot / sorting:** `(24, 18)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,12,13,14,24,25`
- **Source / export:** `assets/source/ch01/ch01_prop_bridge_platform_extended.pxo` → `assets/props/ch01/ch01_prop_bridge_platform_extended.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.transit_car_stalled`
- **Filename:** `ch01_prop_transit_car_stalled_idle.pxo` / `ch01_prop_transit_car_stalled_idle.png` · **Category / use:** Prop (Large Set-piece) · Room 1 stalled Mag-Transit car (static, 5 tiles long along +x, dead headlights); pivot is the footprint centre because a 5-tile footprint cannot keep (W/2, H-8) in 128×80 (bible appendix A.3) (TLF-042)
- **Pixel dimensions:** `128 × 80 px` (`1.0×`) · **Pivot / sorting:** `(64, 52)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,01,11,12,13,15,22,23,24,27,28`
- **Source / export:** `assets/source/ch01/ch01_prop_transit_car_stalled_idle.pxo` → `assets/props/ch01/ch01_prop_transit_car_stalled_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.dispatch_terminal.idle`
- **Filename:** `ch01_prop_dispatch_terminal_idle.pxo` / `ch01_prop_dispatch_terminal_idle.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 9 `dispatch_terminal`; dark screen, unlit seal pad (TLF-042)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,22`
- **Source / export:** `assets/source/ch01/ch01_prop_dispatch_terminal_idle.pxo` → `assets/props/ch01/ch01_prop_dispatch_terminal_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.dispatch_terminal.active`
- **Filename:** `ch01_prop_dispatch_terminal_active.pxo` / `ch01_prop_dispatch_terminal_active.png` · **Category / use:** Prop (Large Hero Mechanism) · lit amber text rows, teal concentric-diamond seal pad (shape cue); no code state, keyed to flag `ch01.flag.ledger_2359_revealed` (TLF-042)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15,25,26,29,31`
- **Source / export:** `assets/source/ch01/ch01_prop_dispatch_terminal_active.pxo` → `assets/props/ch01/ch01_prop_dispatch_terminal_active.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.pocket_watch`
- **Filename:** `ch01_prop_pocket_watch_idle.pxo` / `ch01_prop_pocket_watch_idle.png` · **Category / use:** Prop (Floor Pickup) · `global.pocket_watch` at `(368, 168)` in Room 1; damaged brass watch with cracked glass and loose chain (TLF-042)
- **Pixel dimensions:** `16 × 16 px` (`1.0×`) · **Pivot / sorting:** `(8, 12)` · `YSort_Props` (`z_index = 8`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,22,25,26`
- **Source / export:** `assets/source/ch01/ch01_prop_pocket_watch_idle.pxo` → `assets/props/ch01/ch01_prop_pocket_watch_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.lever_badge_a`
- **Filename:** `ch01_prop_lever_badge_a_idle.pxo` / `ch01_prop_lever_badge_a_idle.png` · **Category / use:** Prop (Overlay) · gold `A` on a dark plate; child offset `(3, -8)` from the lever pivot (`breaker_a`, `junction_lever_a`) (TLF-042)
- **Pixel dimensions:** `5 × 7 px` (`1.0×`) · **Pivot / sorting:** `(2, 3)` · child of the lever, same `z_index`
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `11,26`
- **Source / export:** `assets/source/ch01/ch01_prop_lever_badge_a_idle.pxo` → `assets/props/ch01/ch01_prop_lever_badge_a_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.lever_badge_b`
- **Filename:** `ch01_prop_lever_badge_b_idle.pxo` / `ch01_prop_lever_badge_b_idle.png` · **Category / use:** Prop (Overlay) · gold `B` on a dark plate (`breaker_b`, `junction_lever_b`) (TLF-042)
- **Pixel dimensions:** `5 × 7 px` (`1.0×`) · **Pivot / sorting:** `(2, 3)` · child of the lever, same `z_index`
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `11,26`
- **Source / export:** `assets/source/ch01/ch01_prop_lever_badge_b_idle.pxo` → `assets/props/ch01/ch01_prop_lever_badge_b_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.pa_speaker`
- **Filename:** `ch01_prop_pa_speaker_idle.pxo` / `ch01_prop_pa_speaker_idle.png` · **Category / use:** Prop (Wall Fixture) · optional wall horn for `security_crossing.pa_speaker` (node at `(320, 60)`) (TLF-042)
- **Pixel dimensions:** `16 × 16 px` (`1.0×`) · **Pivot / sorting:** `(8, 12)` · `Wall_Fixtures` (`z_index = 7`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,11,12,13,14,15`
- **Source / export:** `assets/source/ch01/ch01_prop_pa_speaker_idle.pxo` → `assets/props/ch01/ch01_prop_pa_speaker_idle.png` · generator `tools/art/gen/t3.py`

### `ch01.prop.surge_capacitor.frozen_charged`
- **Filename:** `ch01_prop_surge_capacitor_frozen_charged.pxo` / `ch01_prop_surge_capacitor_frozen_charged.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 6 `surge_capacitor` · `is_frozen()` and `charge_state = &"charged"` (`is_stabilized()` when `bus_powered`): frost fill in all three cells, solid crystal hexagon, rigid bridge bar between the terminals, corner L-brackets (no-colour cue: fill height + solid glyph) (TLF-044)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,01,11,12,13,14,15,27,31`
- **Source / export:** `assets/source/ch01/ch01_prop_surge_capacitor_frozen_charged.pxo` → `assets/props/ch01/ch01_prop_surge_capacitor_frozen_charged.png` · generator `tools/art/gen/t2.py` (`capacitor('frozen_charged'|'frozen_discharged')`)

### `ch01.prop.surge_capacitor.frozen_discharged`
- **Filename:** `ch01_prop_surge_capacitor_frozen_discharged.pxo` / `ch01_prop_surge_capacitor_frozen_discharged.png` · **Category / use:** Prop (Large Hero Mechanism) · Room 6 `surge_capacitor` · `is_frozen()` and `charge_state = &"discharged"`: empty dark tubes (2 px sliver), hollow hexagon outline, no bridge, corner L-brackets (no-colour cue: hollow vs solid) (TLF-044)
- **Pixel dimensions:** `64 × 64 px` (`1.0×`) · **Pivot / sorting:** `(32, 56)` · `YSort_Actors` (`z_index = 10`)
- **Frames / FPS / tags:** `1` frame, static, no tags · **Palette:** `TLF-CH01-32`, indices `00,01,11,12,13,14,15,27,31`
- **Source / export:** `assets/source/ch01/ch01_prop_surge_capacitor_frozen_discharged.pxo` → `assets/props/ch01/ch01_prop_surge_capacitor_frozen_discharged.png` · generator `tools/art/gen/t2.py` (`capacitor('frozen_charged'|'frozen_discharged')`)

### 4.1 Archway reconciliation (`archway_frame_e` vs `ROOM_GRAPH.md` §7.1)
`ROOM_GRAPH` §7.1 names `wall_archway_frame_n` and `wall_archway_frame_w`; batch 1 shipped one file named `archway_frame_e`. Geometry decides the mapping, not the compass letter: E and W boundary edges both run *down-left* on screen, N and S edges both run *down-right* (`px_x = 320 + (x-y)*16`). So:

| File | §7.1 name | Slope | Use for |
|---|---|---|---|
| `ch01_env_archway_frame_e_idle.png` (batch 1, unchanged, not renamed) | `wall_archway_frame_w` | down-left | W **and** E doorways (E1-E4: `door_entry_west`, `door_exit_east`, `door_west`, `door_east`, `door_in`) |
| `ch01_env_archway_frame_n_idle.png` (new) | `wall_archway_frame_n` | down-right | N **and** S doorways (E5-E7: `door_exit_north`, `door_entry_south`, `door_south`, `door_north`, `door_out`) |

`archway_frame_n` is the batch-1 frame flipped horizontally with the jamb light/dark edge colours swapped back so the NW-lit convention holds (bible §4). No file was renamed.

### 4.2 `flip_h` rule for axis-run assets
`wall_railing_iron`, `prop_station_bench` and `tile_cable_conduit_*` are authored along the down-right (+x) axis. For the down-left (+y) axis set `flip_h = true`; the baked top-left light then falls on the screen-right side, the same compromise the bible accepts for Elias (§2.3 #4).

### 4.3 Room mockups (`concept`, `640 × 360 px`; kit + puzzle props, not runtime assets)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M1 | `ch01.arrival_platform` (validation against the approved target sheet) | `design/art/mockups/ch01_arrival_platform_mockup.png` | `640 × 360 px` | **`concept`** |
| M2 | `ch01.concourse_west` | `design/art/mockups/ch01_concourse_west_mockup.png` | `640 × 360 px` | **`concept`** |
| M3 | `ch01.signal_control` | `design/art/mockups/ch01_signal_control_mockup.png` | `640 × 360 px` | **`concept`** |
| M4 | `ch01.security_crossing` | `design/art/mockups/ch01_security_crossing_mockup.png` | `640 × 360 px` | **`concept`** |

Composited by script from the committed PNGs at the positions in `CH01_PLACEMENT_SHEET.md` (palette `TLF-CH01-32` only, background `#0A0D14`, Elias `idle_se` frame 2 at the safe anchor; Tier 2 pieces shown in their default state). No `.pxo` (derived images).

---

## 5. Reproducibility (ADR-019)

Rows 12-54 and the mockups/placement sheet are produced by `tools/art/gen/` (see its `README.md`). `python tools/art/gen/verify_regen.py` regenerates every generated `.pxo` (byte for byte), PNG (pixel for pixel; byte for byte against a fresh Pixelorama re-export with `--pixelorama`), mockup and the placement sheet, and compares with the committed files. Batch-1 files (rows 1-11, drawn by Argon in Pixelorama, plus the `.pxo` of the palette and target sheet) have no generator and are reported as *not covered*. Generated `.pxo` files carry the author `TLF design-art agent (Claude Code, Sonnet 5.5)`.

---

## 6. Ability wheel (TLF-053, ADR-021)

Generator `tools/art/gen/ui_wheel.py` (registered in `registry.py`; `verify_regen.py` covers the 39 `.pxo`/PNG pairs, the three mockups and the greyscale proof). Palette `TLF-CH01-32` only, binary alpha. `.pxo` sources live in `assets/source/ch01/` (as for every generated asset); the runtime PNGs live in the new folder `assets/ui/ability_wheel/`. Raw Pixelorama `--size` / `--export` log for the 39 files: `design/art/TLF-053_VERIFICATION.txt` (all re-exports byte-identical).

### 6.1 Size and layout (for TLF-052)

* **Wheel canvas `160 × 160 px`**, centre `(80, 80)`, centred on the screen: top-left at `(240, 100)` of the `640 × 360` view. Safe margin: the wheel is 100 px from the nearest edge (12 px safe margin = `(12,12)-(628,348)`, §8.1). A 4 px-grid size (160 = 40 × 4).
* **Why 160:** at ×3 (`1920 × 1080`) it is 480 px, about 44 % of the height. A segment ring 38 px thick leaves room for the `16 × 16` icon (48 px at ×3) **and** a one-line `8 px` label below it (24 px at ×3, the project's minimum text size). A smaller wheel (128) would force the label out of the segment; a larger one (192) would cover about half of the room art for no gain.
* **Six segments, fixed positions** (ADR-021), clockwise from the top, each centred on the angle `-90 + 60 i` degrees: `0` Trace (top), `1` Rewind (upper right), `2` Freeze (lower right), `3` Echo (bottom), `4` Fast-Forward (lower left), `5` unknown "?" (upper left). Ring radii `42 … 80 px`, each segment 56 degrees wide (4 degree gaps).
* **Assembly:** place each PNG with its **top-left at `wheel_top_left + offset`**; the `offset` column below is relative to the `160 × 160` canvas. Z order from the bottom: segment backgrounds, `face`, `pointer`, icons (centre at radius 62 px along the segment angle, shifted 5 px up so the label fits under it), labels (font `tlf_pixel_mono` 8 px). Locked segments use `seg_locked` + `icon_*_locked` (the `ch01_ui_lock_glyph.png` can be used as a larger overlay, e.g. for a tooltip).
* **Pointer:** `pointer_0 … pointer_5` (a bead on the bezel ring at each segment direction) plus `pointer_rest` (a ring over the dial hub: dead zone, no change). **Six snapped positions rather than a rotated needle:** the segments are 60 degrees apart, so a needle would have to be rendered at 30 and 60 degree angles, which pixel art cannot rotate cleanly; the bead is the *same* shape in every direction (only its position changes), so it is pixel-clean everywhere. The 8-direction keyboard aim and the stick/mouse angle are mapped to the nearest segment by the UI (TLF-052), and the bead snaps to it. If a free-aim needle is wanted later, the generator can emit 8 or 12 directions (one function, `pointer()`).
* **States, readable without colour:** `normal` = dark plate, thin steel border; `selected` = **double** border (cyan + white, 2 px) and a teal fill; `locked` = **dashed** border, diagonal hatch, dimmed icon with a **padlock** (a shape). Greyscale proof: `design/art/mockups/ch01_ability_wheel_greyscale_proof.png` (luminance only, the three mockup states plus all icons and locked icons).
* **Icons (also the HUD slots, §8.1 `16 × 16`):** Trace = concentric diamond reticle, Rewind = counter-clockwise ring with `<<`, Freeze = hexagonal crystal with corner brackets, Echo = figure with its offset echo, Fast-Forward = two solid right-pointing triangles, unknown = "?" disc. They follow the bible §7 shape language; each is distinguishable in greyscale and by silhouette alone.
* **Light** from the top left (lit bezel/plate edges on the top left, shaded on the bottom right).

### 6.2 Files (`row` continues the §3 numbering)

| Row | Asset | Category / use | Source | Export | Size | Frames | Pivot | Offset in the `160 × 160` wheel canvas (top-left) | Use | QA state |
|---|---|---|---|---|---|---|---|---|---|---|
| **55** | `ch01.ui.wheel_face` | UI (ability wheel) | `ch01_ui_wheel_face.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_face.png` | `52 × 56 px` | `1f` (`static`) | `(26, 30)` (dial centre) | `(54, 50)` | watch face, centred on the wheel centre; pivot = dial centre (26,30) | **`exported`** |
| **56** | `ch01.ui.wheel_pointer_rest` | UI (ability wheel) | `ch01_ui_wheel_pointer_rest.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_rest.png` | `10 × 10 px` | `1f` (`static`) | `(5, 5)` | `(75, 75)` | no direction (dead zone): ring over the dial hub | **`exported`** |
| **57** | `ch01.ui.wheel_pointer_0` | UI (ability wheel) | `ch01_ui_wheel_pointer_0.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_0.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(70, 36)` | bead pointer at segment 0 (trace) | **`exported`** |
| **58** | `ch01.ui.wheel_pointer_1` | UI (ability wheel) | `ch01_ui_wheel_pointer_1.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_1.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(100, 54)` | bead pointer at segment 1 (rewind) | **`exported`** |
| **59** | `ch01.ui.wheel_pointer_2` | UI (ability wheel) | `ch01_ui_wheel_pointer_2.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_2.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(100, 88)` | bead pointer at segment 2 (freeze) | **`exported`** |
| **60** | `ch01.ui.wheel_pointer_3` | UI (ability wheel) | `ch01_ui_wheel_pointer_3.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_3.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(70, 104)` | bead pointer at segment 3 (echo) | **`exported`** |
| **61** | `ch01.ui.wheel_pointer_4` | UI (ability wheel) | `ch01_ui_wheel_pointer_4.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_4.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(41, 88)` | bead pointer at segment 4 (fast_forward) | **`exported`** |
| **62** | `ch01.ui.wheel_pointer_5` | UI (ability wheel) | `ch01_ui_wheel_pointer_5.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_pointer_5.png` | `18 × 18 px` | `1f` (`static`) | `(9, 9)` | `(41, 54)` | bead pointer at segment 5 (unknown) | **`exported`** |
| **63** | `ch01.ui.wheel_seg0_normal` | UI (ability wheel) | `ch01_ui_wheel_seg0_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg0_normal.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 0)` | segment 0 (trace) background, normal | **`exported`** |
| **64** | `ch01.ui.wheel_seg0_selected` | UI (ability wheel) | `ch01_ui_wheel_seg0_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg0_selected.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 0)` | segment 0 (trace) background, selected | **`exported`** |
| **65** | `ch01.ui.wheel_seg0_locked` | UI (ability wheel) | `ch01_ui_wheel_seg0_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg0_locked.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 0)` | segment 0 (trace) background, locked | **`exported`** |
| **66** | `ch01.ui.wheel_seg1_normal` | UI (ability wheel) | `ch01_ui_wheel_seg1_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg1_normal.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 12)` | segment 1 (rewind) background, normal | **`exported`** |
| **67** | `ch01.ui.wheel_seg1_selected` | UI (ability wheel) | `ch01_ui_wheel_seg1_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg1_selected.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 12)` | segment 1 (rewind) background, selected | **`exported`** |
| **68** | `ch01.ui.wheel_seg1_locked` | UI (ability wheel) | `ch01_ui_wheel_seg1_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg1_locked.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 12)` | segment 1 (rewind) background, locked | **`exported`** |
| **69** | `ch01.ui.wheel_seg2_normal` | UI (ability wheel) | `ch01_ui_wheel_seg2_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg2_normal.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 81)` | segment 2 (freeze) background, normal | **`exported`** |
| **70** | `ch01.ui.wheel_seg2_selected` | UI (ability wheel) | `ch01_ui_wheel_seg2_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg2_selected.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 81)` | segment 2 (freeze) background, selected | **`exported`** |
| **71** | `ch01.ui.wheel_seg2_locked` | UI (ability wheel) | `ch01_ui_wheel_seg2_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg2_locked.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(102, 81)` | segment 2 (freeze) background, locked | **`exported`** |
| **72** | `ch01.ui.wheel_seg3_normal` | UI (ability wheel) | `ch01_ui_wheel_seg3_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg3_normal.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 117)` | segment 3 (echo) background, normal | **`exported`** |
| **73** | `ch01.ui.wheel_seg3_selected` | UI (ability wheel) | `ch01_ui_wheel_seg3_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg3_selected.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 117)` | segment 3 (echo) background, selected | **`exported`** |
| **74** | `ch01.ui.wheel_seg3_locked` | UI (ability wheel) | `ch01_ui_wheel_seg3_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg3_locked.png` | `74 × 43 px` | `1f` (`static`) | `(37, 21)` | `(43, 117)` | segment 3 (echo) background, locked | **`exported`** |
| **75** | `ch01.ui.wheel_seg4_normal` | UI (ability wheel) | `ch01_ui_wheel_seg4_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg4_normal.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 81)` | segment 4 (fast_forward) background, normal | **`exported`** |
| **76** | `ch01.ui.wheel_seg4_selected` | UI (ability wheel) | `ch01_ui_wheel_seg4_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg4_selected.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 81)` | segment 4 (fast_forward) background, selected | **`exported`** |
| **77** | `ch01.ui.wheel_seg4_locked` | UI (ability wheel) | `ch01_ui_wheel_seg4_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg4_locked.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 81)` | segment 4 (fast_forward) background, locked | **`exported`** |
| **78** | `ch01.ui.wheel_seg5_normal` | UI (ability wheel) | `ch01_ui_wheel_seg5_normal.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg5_normal.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 12)` | segment 5 (unknown) background, normal | **`exported`** |
| **79** | `ch01.ui.wheel_seg5_selected` | UI (ability wheel) | `ch01_ui_wheel_seg5_selected.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg5_selected.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 12)` | segment 5 (unknown) background, selected | **`exported`** |
| **80** | `ch01.ui.wheel_seg5_locked` | UI (ability wheel) | `ch01_ui_wheel_seg5_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_wheel_seg5_locked.png` | `58 × 67 px` | `1f` (`static`) | `(29, 33)` | `(0, 12)` | segment 5 (unknown) background, locked | **`exported`** |
| **81** | `ch01.ui.icon_trace` | UI (ability wheel) | `ch01_ui_icon_trace.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_trace.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | trace icon 16x16 (wheel and HUD slot) | **`exported`** |
| **82** | `ch01.ui.icon_rewind` | UI (ability wheel) | `ch01_ui_icon_rewind.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_rewind.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | rewind icon 16x16 (wheel and HUD slot) | **`exported`** |
| **83** | `ch01.ui.icon_freeze` | UI (ability wheel) | `ch01_ui_icon_freeze.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_freeze.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | freeze icon 16x16 (wheel and HUD slot) | **`exported`** |
| **84** | `ch01.ui.icon_echo` | UI (ability wheel) | `ch01_ui_icon_echo.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_echo.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | echo icon 16x16 (wheel and HUD slot) | **`exported`** |
| **85** | `ch01.ui.icon_fast_forward` | UI (ability wheel) | `ch01_ui_icon_fast_forward.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_fast_forward.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | fast_forward icon 16x16 (wheel and HUD slot) | **`exported`** |
| **86** | `ch01.ui.icon_trace_locked` | UI (ability wheel) | `ch01_ui_icon_trace_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_trace_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | trace icon, locked variant (dim silhouette + lock) | **`exported`** |
| **87** | `ch01.ui.icon_rewind_locked` | UI (ability wheel) | `ch01_ui_icon_rewind_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_rewind_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | rewind icon, locked variant (dim silhouette + lock) | **`exported`** |
| **88** | `ch01.ui.icon_freeze_locked` | UI (ability wheel) | `ch01_ui_icon_freeze_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_freeze_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | freeze icon, locked variant (dim silhouette + lock) | **`exported`** |
| **89** | `ch01.ui.icon_echo_locked` | UI (ability wheel) | `ch01_ui_icon_echo_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_echo_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | echo icon, locked variant (dim silhouette + lock) | **`exported`** |
| **90** | `ch01.ui.icon_fast_forward_locked` | UI (ability wheel) | `ch01_ui_icon_fast_forward_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_fast_forward_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | fast_forward icon, locked variant (dim silhouette + lock) | **`exported`** |
| **91** | `ch01.ui.icon_unknown_locked` | UI (ability wheel) | `ch01_ui_icon_unknown_locked.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_unknown_locked.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | unknown icon, locked variant (dim silhouette + lock) | **`exported`** |
| **92** | `ch01.ui.icon_unknown` | UI (ability wheel) | `ch01_ui_icon_unknown.pxo` | `assets/ui/ability_wheel/ch01_ui_icon_unknown.png` | `16 × 16 px` | `1f` (`static`) | `(8, 8)` | (icon: placed by the slot) | unknown slot "?" silhouette | **`exported`** |
| **93** | `ch01.ui.lock_glyph` | UI (ability wheel) | `ch01_ui_lock_glyph.pxo` | `assets/ui/ability_wheel/ch01_ui_lock_glyph.png` | `14 × 16 px` | `1f` (`static`) | `(7, 8)` | (icon: placed by the slot) | lock glyph overlay for locked segments | **`exported`** |

Icons carry no offset: the HUD slot (or the wheel script) places a `16 × 16` icon centred on its slot / segment label anchor. `pointer_rest` and `face` are placed with the offsets above.

### 6.3 Mockups (`concept`, `640 × 360 px`; assembled by script from the PNGs above)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M5 | wheel, only Trace unlocked (Trace selected) | `design/art/mockups/ch01_ability_wheel_a_trace_only_mockup.png` | `640 × 360 px` | **`concept`** |
| M6 | wheel, all four abilities unlocked (Trace selected) | `design/art/mockups/ch01_ability_wheel_b_all_four_mockup.png` | `640 × 360 px` | **`concept`** |
| M7 | wheel, all four unlocked, Rewind selected | `design/art/mockups/ch01_ability_wheel_c_rewind_selected_mockup.png` | `640 × 360 px` | **`concept`** |

The greyscale proof `design/art/mockups/ch01_ability_wheel_greyscale_proof.png` (`1040 × 496 px`, luminance only, so it is **not** palette-checked) is generated by the same script and compared by `verify_regen.py`.

---

## 7. Step 1 Art — Statues, Shimmer & New Props (`TLF-057`)

**Task:** TLF-057 · **Author:** Agent 2 (`Gemini 4 Argon`, Creative Asset Specialist, ADR-017 amended 2026-11-05) · **Art Director / Reviewer:** `GPT-6.1 Sol` · **Palette:** `TLF-CH01-32`, `0` off-palette, `0` semi-transparent pixels · **Generators:** `tools/art/gen/step1_statues.py` (76 Section A assets), `tools/art/gen/step1_props.py` (57 Section B assets), and `tools/art/gen/step1_mockups.py` (5 room/contact-sheet mockups & greyscale proofs), registered in `tools/art/gen/registry.py`, `gen_all.py`, and `verify_regen.py`.

### 7.1 Visual Direction Summary (per Sol, 2026-11-05)
- **Frozen Commuters (Statues):** Arrested human gestures at `23:59`, not carved monuments. Rendered in the 5 existing steel/slate greys `#1B1E24` (`11`), `#2E333D` (`12`), `#464E5C` (`13`), `#677385` (`14`), `#94A2B8` (`15`), with a dedicated `1 px` `#0A0D14` (`00`) outer silhouette outline and `#141A26` (`01`) compact down-right floor shadow. Broad quiet grey planes with top-left key light (`315°`); no skin tones (`20`/`21`), no white eyes (`31`), no icy crust, no glow fill, and no stone cracks. One subdued accent per commuter confined to coat/bag/overlay (`#8C2D19` idx `23` red coat, `#594438` idx `18` leather bag, etc.). All 6 base bodies (`3 builds × 2 poses`), 4 specific poses (`N-03` seated on existing bench without second bench, `N-04` mid-turn cleaner with separate half-turned trolley, `N-05` courier mid-vault with lifted foot and air gap, `N-11` hatch tech leaning back on crank with visible arm gap), 14 prop overlays (`_idle` and `_read`), and all 13 pre-assembled commuter sprites (`_idle` and `_read`) fit inside `16 × 40 px` with foot pivot `(8, 36)` and `12 × 8 px` collider footprint.
- **Runtime Combined Idle/Read Outline Contract (`R2`):** Both (a) the 26 registered pre-assembled commuter sprites (`ch01_char_statue_commuter_<slug>_{idle,read}`) and (b) modular alpha-compositing of base pose (`ch01_char_statue_<pose>_{idle,read}`) + prop overlays (`ch01_prop_statue_ov_<ov>_{idle,read}`) reproduce the exact `1 px` outer silhouette outline around the combined person + held prop with **`0 / 0` pixel differences** across all 13 commuters.
- **Trace VFX & Static Read State:** `24 × 12 px` isometric foot ellipse (`4` stepped highlight frames @ `8 FPS`, `96 × 12 px` horizontal strip) in `#9E7BFF` (`30`) + sparse `#FFD166` (`26`), plus a `6 × 6 px` overhead clock-hand timestamp glyph (`00`/`30`/`26`). The `"read"` state (and `reduced_effects` mode) swaps the combined statue + held-prop `1 px` outer silhouette outline to static `#9E7BFF` (`30`) with sparse `#FFD166` (`26`) at the NW crown and hides the animated foot ring.
- **Step 1 Puzzle & Station Props (Section B, `R1` & `R3`):** One worn steel station hardware family (`11..15` + `00` `1 px` outline) where mechanical geometry and glyphs carry every state in greyscale: SO-01 selectors (`LINE` circle/diamond/triangle, `PLATFORM` 1/2/3 bars, `CAR` middle/rear/front train car silhouettes), release lever (`idle` rest, `buzzing` `X` + jiggle ticks, `accepted` `>>>` + shifted handle), split-flap dials (separate header glyphs, clean label window, `jammed` tilted flap + seam gap), ticket validator & card reader (`X` reject/denied, `>>>` accepted), `2:1` down-left isometric `32 × 64 px` doorways (`platform_gate`, `staff_door`, `service_hatch`, `inner_shutter`, `staff_barrier`) and `wall_bulkhead_module` aligned 1:1 with `ch01_env_archway_frame_e_idle` (pivot `(16, 56)`, slope `(31 - x) // 2`) with distinct header plate marks and clear open portals when open/raised, service hatch `frozen_open` and `frozen_closed` retaining their open/closed aperture state plus a brass `[o]` lock ring and Freeze corner brackets, `conduit` (`fallen` sag/break vs `mounted` straight/bracketed), `2:1` isometric floor-diamond plates (`floor_plate_a`, `floor_plate_b`, `alarm_plate`, `standby_plate` at `32 × 16 px`, pivot `(16, 8)`, raised proud tread when empty/idle vs depressed tread inside a recessed `2:1` collar trench when pressed/ringing/held), `bell_icon` (bell glyph + radiating strike marks when ringing), `echo_pedestal` (`used` adds persistent second clock-hand + paired twin mark), `breaker_c` (lamp ring + lever detent; `browned_out` broken/split lamp ring + fault detent), `dead_relay_c` (`24 × 36 px`, pivot `(12, 32)`, visibly disconnected cable lug with air gap in both `idle` and `shake`), and `ticket_terms_notice` (plaque + paper silhouette without invented clue text).
- **Bible Named Layer Reconciliation (`R3`):** All Section A and B assets use the `ART_BIBLE.md` §5.2 named layers: `YSort_Walls (z_index = 5)` for `ch01_env_wall_bulkhead_module_idle`, `Wall_Fixtures (z_index = 7)` for wall-mounted selectors/dials/validators/card readers/notices/breakers/relays/mounted conduit, `YSort_Props (z_index = 8)` for floor-diamond plates (`floor_plate_a/b`, `alarm_plate`, `standby_plate`), `conduit_fallen`, and the ground `shimmer_ring`, and `YSort_Actors (z_index = 10)` for statues, freestanding pedestals/consoles, and Y-sorted `32 × 64` doorway gates/doors/hatches/shutters/barriers.

### 7.2 Step 1 Commuter Assembly Matrix (`COMMUTERS_STEP1.md` — all 13 commuters)

| Commuter ID | Room | Tile / Pixel Pos | Registered Assembled Sprite (`_idle` & `_read`) | Modular Base Pose (`_idle` & `_read`) | Modular Prop Overlays (`_idle` & `_read`) | Trace Timestamp | Role / Clue |
|---|---|---|---|---|---|---|---|
| **`N-01`** (`n01_conductor`) | `R1` | `(10, 8)` / `(352, 208)` | `ch01_char_statue_commuter_n01_conductor_{idle,read}` | `ch01_char_statue_body_a_pose2_{idle,read}` | `ch01_prop_statue_ov_whistle_{idle,read}` | `23:57` | SO-01 LINE+CAR |
| **`N-02`** (`n02_student`) | `R1` | `(5, 8)` / `(272, 168)` | `ch01_char_statue_commuter_n02_student_{idle,read}` | `ch01_char_statue_body_a_pose1_{idle,read}` | `ch01_prop_statue_ov_phone_{idle,read}` | `23:41` | SO-01 decoy |
| **`N-03`** (`n03_old_man`) | `R1` | `(4, 2)` / `(352, 112)` | `ch01_char_statue_commuter_n03_old_man_{idle,read}` | `ch01_char_statue_n03_old_man_seated_{idle,read}` | `ch01_prop_statue_ov_paper_bag_{idle,read}` | `23:30` | SO-01 seated on bench |
| **`N-04`** (`n04_cleaner`) | `R1` | `(12, 7)` / `(400, 216)` | `ch01_char_statue_commuter_n04_cleaner_{idle,read}` | `ch01_char_statue_n04_cleaner_{idle,read}` | `ch01_prop_statue_ov_trolley_{idle,read}` | `23:58` | SO-01 PLATFORM |
| **`N-05`** (`n05_courier`) | `R2` | `(1, 6)` / `(240, 120)` | `ch01_char_statue_commuter_n05_courier_{idle,read}` | `ch01_char_statue_n05_courier_vault_{idle,read}` | `ch01_prop_statue_ov_courier_bag_{idle,read}` | `23:59` | PZ-001 Rewind unlock |
| **`N-06`** (`n06_red_coat`) | `R2` | `(13, 6)` / `(432, 216)` | `ch01_char_statue_commuter_n06_red_coat_{idle,read}` | `ch01_char_statue_body_a_pose1_{idle,read}` | `ch01_prop_statue_ov_red_coat_{idle,read}` | `23:41` | PZ-006 decoy |
| **`N-07`** (`n07_briefcase`) | `R2` | `(13, 8)` / `(400, 232)` | `ch01_char_statue_commuter_n07_briefcase_{idle,read}` | `ch01_char_statue_body_b_pose1_{idle,read}` | `ch01_prop_statue_ov_briefcase_{idle,read}` | `23:49` | PZ-006 decoy |
| **`N-08`** (`n08_father`) | `R2` | `(13, 10)` / `(368, 248)` | `ch01_char_statue_commuter_n08_father_{idle,read}` | `ch01_char_statue_body_b_pose1_{idle,read}` | `ch01_prop_statue_ov_sleeping_child_{idle,read}` | `23:53` | PZ-006 decoy 23:53 |
| **`N-09`** (`n09_teen`) | `R2` | `(11, 9)` / `(352, 224)` | `ch01_char_statue_commuter_n09_teen_{idle,read}` | `ch01_char_statue_body_c_pose2_{idle,read}` | `ch01_prop_statue_ov_headphones_{idle,read}` | `23:55` | PZ-006 target ticket |
| **`N-11`** (`n11_hatch_tech`) | `R3` | `(2, 3)` / `(304, 104)` | `ch01_char_statue_commuter_n11_hatch_tech_{idle,read}` | `ch01_char_statue_n11_tech_crank_{idle,read}` | `ch01_prop_statue_ov_hatch_crank_{idle,read}` | `23:58` | SO-02 Freeze unlock |
| **`N-13`** (`n13_guard`) | `R4` | `(4, 3)` / `(336, 120)` | `ch01_char_statue_commuter_n13_guard_{idle,read}` | `ch01_char_statue_body_b_pose2_{idle,read}` | `ch01_prop_statue_ov_gate_lever_{idle,read}` | `23:57` | PZ-003 south plate clue |
| **`N-20`** (`n20_engineer`) | `R6` | `(6, 7)` / `(304, 168)` | `ch01_char_statue_commuter_n20_engineer_{idle,read}` | `ch01_char_statue_body_b_pose2_{idle,read}` | `ch01_prop_statue_ov_breaker_handle_{idle,read}` | `23:56` | PZ-004 breaker C warning |
| **`N-21`** (`n21_tourist`) | `R7` | `(5, 4)` / `(336, 136)` | `ch01_char_statue_commuter_n21_tourist_{idle,read}` | `ch01_char_statue_body_c_pose1_{idle,read}` | `ch01_prop_statue_ov_map_{idle,read}` + `ch01_prop_statue_ov_suitcase_{idle,read}` | `23:55` | PZ-005 loop clue |

### 7.3 Step 1 Asset Inventory Table (`row` 94–226)

| Row | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **94** | `ch01.char.statue_body_a_pose1_idle` | Characters | `ch01_char_statue_body_a_pose1_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_a_pose1_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **95** | `ch01.char.statue_body_a_pose1_read` | Characters | `ch01_char_statue_body_a_pose1_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_a_pose1_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **96** | `ch01.char.statue_body_a_pose2_idle` | Characters | `ch01_char_statue_body_a_pose2_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_a_pose2_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **97** | `ch01.char.statue_body_a_pose2_read` | Characters | `ch01_char_statue_body_a_pose2_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_a_pose2_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **98** | `ch01.char.statue_body_b_pose1_idle` | Characters | `ch01_char_statue_body_b_pose1_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_b_pose1_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **99** | `ch01.char.statue_body_b_pose1_read` | Characters | `ch01_char_statue_body_b_pose1_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_b_pose1_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **100** | `ch01.char.statue_body_b_pose2_idle` | Characters | `ch01_char_statue_body_b_pose2_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_b_pose2_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **101** | `ch01.char.statue_body_b_pose2_read` | Characters | `ch01_char_statue_body_b_pose2_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_b_pose2_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **102** | `ch01.char.statue_body_c_pose1_idle` | Characters | `ch01_char_statue_body_c_pose1_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_c_pose1_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **103** | `ch01.char.statue_body_c_pose1_read` | Characters | `ch01_char_statue_body_c_pose1_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_c_pose1_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **104** | `ch01.char.statue_body_c_pose2_idle` | Characters | `ch01_char_statue_body_c_pose2_idle.pxo` | `assets/characters/ch01/ch01_char_statue_body_c_pose2_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **105** | `ch01.char.statue_body_c_pose2_read` | Characters | `ch01_char_statue_body_c_pose2_read.pxo` | `assets/characters/ch01/ch01_char_statue_body_c_pose2_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **106** | `ch01.char.statue_n03_old_man_seated_idle` | Characters | `ch01_char_statue_n03_old_man_seated_idle.pxo` | `assets/characters/ch01/ch01_char_statue_n03_old_man_seated_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **107** | `ch01.char.statue_n03_old_man_seated_read` | Characters | `ch01_char_statue_n03_old_man_seated_read.pxo` | `assets/characters/ch01/ch01_char_statue_n03_old_man_seated_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **108** | `ch01.char.statue_n04_cleaner_idle` | Characters | `ch01_char_statue_n04_cleaner_idle.pxo` | `assets/characters/ch01/ch01_char_statue_n04_cleaner_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **109** | `ch01.char.statue_n04_cleaner_read` | Characters | `ch01_char_statue_n04_cleaner_read.pxo` | `assets/characters/ch01/ch01_char_statue_n04_cleaner_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **110** | `ch01.char.statue_n05_courier_vault_idle` | Characters | `ch01_char_statue_n05_courier_vault_idle.pxo` | `assets/characters/ch01/ch01_char_statue_n05_courier_vault_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **111** | `ch01.char.statue_n05_courier_vault_read` | Characters | `ch01_char_statue_n05_courier_vault_read.pxo` | `assets/characters/ch01/ch01_char_statue_n05_courier_vault_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **112** | `ch01.char.statue_n11_tech_crank_idle` | Characters | `ch01_char_statue_n11_tech_crank_idle.pxo` | `assets/characters/ch01/ch01_char_statue_n11_tech_crank_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **113** | `ch01.char.statue_n11_tech_crank_read` | Characters | `ch01_char_statue_n11_tech_crank_read.pxo` | `assets/characters/ch01/ch01_char_statue_n11_tech_crank_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **114** | `ch01.prop.statue_ov_suitcase_idle` | Props | `ch01_prop_statue_ov_suitcase_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_suitcase_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **115** | `ch01.prop.statue_ov_suitcase_read` | Props | `ch01_prop_statue_ov_suitcase_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_suitcase_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **116** | `ch01.prop.statue_ov_paper_bag_idle` | Props | `ch01_prop_statue_ov_paper_bag_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_paper_bag_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **117** | `ch01.prop.statue_ov_paper_bag_read` | Props | `ch01_prop_statue_ov_paper_bag_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_paper_bag_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **118** | `ch01.prop.statue_ov_whistle_idle` | Props | `ch01_prop_statue_ov_whistle_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_whistle_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **119** | `ch01.prop.statue_ov_whistle_read` | Props | `ch01_prop_statue_ov_whistle_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_whistle_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **120** | `ch01.prop.statue_ov_trolley_idle` | Props | `ch01_prop_statue_ov_trolley_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_trolley_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **121** | `ch01.prop.statue_ov_trolley_read` | Props | `ch01_prop_statue_ov_trolley_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_trolley_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **122** | `ch01.prop.statue_ov_phone_idle` | Props | `ch01_prop_statue_ov_phone_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_phone_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **123** | `ch01.prop.statue_ov_phone_read` | Props | `ch01_prop_statue_ov_phone_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_phone_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **124** | `ch01.prop.statue_ov_red_coat_idle` | Props | `ch01_prop_statue_ov_red_coat_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_red_coat_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `5 / 32` | **`exported`** |
| **125** | `ch01.prop.statue_ov_red_coat_read` | Props | `ch01_prop_statue_ov_red_coat_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_red_coat_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `5 / 32` | **`exported`** |
| **126** | `ch01.prop.statue_ov_briefcase_idle` | Props | `ch01_prop_statue_ov_briefcase_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_briefcase_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `5 / 32` | **`exported`** |
| **127** | `ch01.prop.statue_ov_briefcase_read` | Props | `ch01_prop_statue_ov_briefcase_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_briefcase_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `5 / 32` | **`exported`** |
| **128** | `ch01.prop.statue_ov_sleeping_child_idle` | Props | `ch01_prop_statue_ov_sleeping_child_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_sleeping_child_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **129** | `ch01.prop.statue_ov_sleeping_child_read` | Props | `ch01_prop_statue_ov_sleeping_child_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_sleeping_child_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `7 / 32` | **`exported`** |
| **130** | `ch01.prop.statue_ov_headphones_idle` | Props | `ch01_prop_statue_ov_headphones_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_headphones_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `3 / 32` | **`exported`** |
| **131** | `ch01.prop.statue_ov_headphones_read` | Props | `ch01_prop_statue_ov_headphones_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_headphones_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **132** | `ch01.prop.statue_ov_hatch_crank_idle` | Props | `ch01_prop_statue_ov_hatch_crank_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_hatch_crank_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **133** | `ch01.prop.statue_ov_hatch_crank_read` | Props | `ch01_prop_statue_ov_hatch_crank_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_hatch_crank_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **134** | `ch01.prop.statue_ov_gate_lever_idle` | Props | `ch01_prop_statue_ov_gate_lever_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_gate_lever_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **135** | `ch01.prop.statue_ov_gate_lever_read` | Props | `ch01_prop_statue_ov_gate_lever_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_gate_lever_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **136** | `ch01.prop.statue_ov_breaker_handle_idle` | Props | `ch01_prop_statue_ov_breaker_handle_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_breaker_handle_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **137** | `ch01.prop.statue_ov_breaker_handle_read` | Props | `ch01_prop_statue_ov_breaker_handle_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_breaker_handle_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **138** | `ch01.prop.statue_ov_map_idle` | Props | `ch01_prop_statue_ov_map_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_map_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **139** | `ch01.prop.statue_ov_map_read` | Props | `ch01_prop_statue_ov_map_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_map_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `6 / 32` | **`exported`** |
| **140** | `ch01.prop.statue_ov_courier_bag_idle` | Props | `ch01_prop_statue_ov_courier_bag_idle.pxo` | `assets/props/ch01/ch01_prop_statue_ov_courier_bag_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **141** | `ch01.prop.statue_ov_courier_bag_read` | Props | `ch01_prop_statue_ov_courier_bag_read.pxo` | `assets/props/ch01/ch01_prop_statue_ov_courier_bag_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `child of statue in YSort_Actors (z_index = 10)` | `4 / 32` | **`exported`** |
| **142** | `ch01.char.statue_commuter_n01_conductor_idle` | Characters | `ch01_char_statue_commuter_n01_conductor_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n01_conductor_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **143** | `ch01.char.statue_commuter_n01_conductor_read` | Characters | `ch01_char_statue_commuter_n01_conductor_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n01_conductor_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **144** | `ch01.char.statue_commuter_n02_student_idle` | Characters | `ch01_char_statue_commuter_n02_student_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n02_student_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **145** | `ch01.char.statue_commuter_n02_student_read` | Characters | `ch01_char_statue_commuter_n02_student_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n02_student_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **146** | `ch01.char.statue_commuter_n03_old_man_idle` | Characters | `ch01_char_statue_commuter_n03_old_man_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n03_old_man_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **147** | `ch01.char.statue_commuter_n03_old_man_read` | Characters | `ch01_char_statue_commuter_n03_old_man_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n03_old_man_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **148** | `ch01.char.statue_commuter_n04_cleaner_idle` | Characters | `ch01_char_statue_commuter_n04_cleaner_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n04_cleaner_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **149** | `ch01.char.statue_commuter_n04_cleaner_read` | Characters | `ch01_char_statue_commuter_n04_cleaner_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n04_cleaner_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **150** | `ch01.char.statue_commuter_n05_courier_idle` | Characters | `ch01_char_statue_commuter_n05_courier_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n05_courier_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **151** | `ch01.char.statue_commuter_n05_courier_read` | Characters | `ch01_char_statue_commuter_n05_courier_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n05_courier_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **152** | `ch01.char.statue_commuter_n06_red_coat_idle` | Characters | `ch01_char_statue_commuter_n06_red_coat_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n06_red_coat_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **153** | `ch01.char.statue_commuter_n06_red_coat_read` | Characters | `ch01_char_statue_commuter_n06_red_coat_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n06_red_coat_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **154** | `ch01.char.statue_commuter_n07_briefcase_idle` | Characters | `ch01_char_statue_commuter_n07_briefcase_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n07_briefcase_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **155** | `ch01.char.statue_commuter_n07_briefcase_read` | Characters | `ch01_char_statue_commuter_n07_briefcase_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n07_briefcase_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **156** | `ch01.char.statue_commuter_n08_father_idle` | Characters | `ch01_char_statue_commuter_n08_father_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n08_father_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **157** | `ch01.char.statue_commuter_n08_father_read` | Characters | `ch01_char_statue_commuter_n08_father_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n08_father_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **158** | `ch01.char.statue_commuter_n09_teen_idle` | Characters | `ch01_char_statue_commuter_n09_teen_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n09_teen_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **159** | `ch01.char.statue_commuter_n09_teen_read` | Characters | `ch01_char_statue_commuter_n09_teen_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n09_teen_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **160** | `ch01.char.statue_commuter_n11_hatch_tech_idle` | Characters | `ch01_char_statue_commuter_n11_hatch_tech_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n11_hatch_tech_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **161** | `ch01.char.statue_commuter_n11_hatch_tech_read` | Characters | `ch01_char_statue_commuter_n11_hatch_tech_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n11_hatch_tech_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **162** | `ch01.char.statue_commuter_n13_guard_idle` | Characters | `ch01_char_statue_commuter_n13_guard_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n13_guard_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **163** | `ch01.char.statue_commuter_n13_guard_read` | Characters | `ch01_char_statue_commuter_n13_guard_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n13_guard_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **164** | `ch01.char.statue_commuter_n20_engineer_idle` | Characters | `ch01_char_statue_commuter_n20_engineer_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n20_engineer_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **165** | `ch01.char.statue_commuter_n20_engineer_read` | Characters | `ch01_char_statue_commuter_n20_engineer_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n20_engineer_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **166** | `ch01.char.statue_commuter_n21_tourist_idle` | Characters | `ch01_char_statue_commuter_n21_tourist_idle.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n21_tourist_idle.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **167** | `ch01.char.statue_commuter_n21_tourist_read` | Characters | `ch01_char_statue_commuter_n21_tourist_read.pxo` | `assets/characters/ch01/ch01_char_statue_commuter_n21_tourist_read.png` | `16 × 40 px` | 1f (`static`) | `(8, 36)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **168** | `ch01.prop.trace_shimmer_ring_loop` | Props | `ch01_prop_trace_shimmer_ring_loop.pxo` | `assets/props/ch01/ch01_prop_trace_shimmer_ring_loop.png` | `96 × 12 px (4× 24×12)` | 4f @ 8 FPS (`loop`) | `(12, 6)` | `YSort_Props (z_index = 8, under statue feet)` | `3 / 32` | **`exported`** |
| **169** | `ch01.prop.trace_timestamp_glyph_idle` | Props | `ch01_prop_trace_timestamp_glyph_idle.pxo` | `assets/props/ch01/ch01_prop_trace_timestamp_glyph_idle.png` | `6 × 6 px` | 1f (`static`) | `(3, 3)` | `child of statue in YSort_Actors (z_index = 10)` | `3 / 32` | **`exported`** |
| **170** | `ch01.prop.selector_line_pos0` | Props | `ch01_prop_selector_line_pos0.pxo` | `assets/props/ch01/ch01_prop_selector_line_pos0.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **171** | `ch01.prop.selector_line_pos1` | Props | `ch01_prop_selector_line_pos1.pxo` | `assets/props/ch01/ch01_prop_selector_line_pos1.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **172** | `ch01.prop.selector_line_pos2` | Props | `ch01_prop_selector_line_pos2.pxo` | `assets/props/ch01/ch01_prop_selector_line_pos2.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **173** | `ch01.prop.selector_platform_pos0` | Props | `ch01_prop_selector_platform_pos0.pxo` | `assets/props/ch01/ch01_prop_selector_platform_pos0.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **174** | `ch01.prop.selector_platform_pos1` | Props | `ch01_prop_selector_platform_pos1.pxo` | `assets/props/ch01/ch01_prop_selector_platform_pos1.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **175** | `ch01.prop.selector_platform_pos2` | Props | `ch01_prop_selector_platform_pos2.pxo` | `assets/props/ch01/ch01_prop_selector_platform_pos2.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **176** | `ch01.prop.selector_car_pos0` | Props | `ch01_prop_selector_car_pos0.pxo` | `assets/props/ch01/ch01_prop_selector_car_pos0.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **177** | `ch01.prop.selector_car_pos1` | Props | `ch01_prop_selector_car_pos1.pxo` | `assets/props/ch01/ch01_prop_selector_car_pos1.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **178** | `ch01.prop.selector_car_pos2` | Props | `ch01_prop_selector_car_pos2.pxo` | `assets/props/ch01/ch01_prop_selector_car_pos2.png` | `32 × 48 px` | 1f (`static`) | `(16, 40)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **179** | `ch01.prop.release_lever_idle` | Props | `ch01_prop_release_lever_idle.pxo` | `assets/props/ch01/ch01_prop_release_lever_idle.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `8 / 32` | **`exported`** |
| **180** | `ch01.prop.release_lever_buzzing` | Props | `ch01_prop_release_lever_buzzing.pxo` | `assets/props/ch01/ch01_prop_release_lever_buzzing.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `11 / 32` | **`exported`** |
| **181** | `ch01.prop.release_lever_accepted` | Props | `ch01_prop_release_lever_accepted.pxo` | `assets/props/ch01/ch01_prop_release_lever_accepted.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `11 / 32` | **`exported`** |
| **182** | `ch01.prop.platform_gate_closed` | Props | `ch01_prop_platform_gate_closed.pxo` | `assets/props/ch01/ch01_prop_platform_gate_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **183** | `ch01.prop.platform_gate_open` | Props | `ch01_prop_platform_gate_open.pxo` | `assets/props/ch01/ch01_prop_platform_gate_open.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **184** | `ch01.prop.conduit_fallen` | Props | `ch01_prop_conduit_fallen.pxo` | `assets/props/ch01/ch01_prop_conduit_fallen.png` | `48 × 32 px` | 1f (`static`) | `(24, 26)` | `YSort_Props (z_index = 8)` | `11 / 32` | **`exported`** |
| **185** | `ch01.prop.conduit_mounted` | Props | `ch01_prop_conduit_mounted.pxo` | `assets/props/ch01/ch01_prop_conduit_mounted.png` | `48 × 32 px` | 1f (`static`) | `(24, 26)` | `Wall_Fixtures (z_index = 7)` | `8 / 32` | **`exported`** |
| **186** | `ch01.prop.flap_dial_line_idle` | Props | `ch01_prop_flap_dial_line_idle.pxo` | `assets/props/ch01/ch01_prop_flap_dial_line_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `11 / 32` | **`exported`** |
| **187** | `ch01.prop.flap_dial_line_jammed` | Props | `ch01_prop_flap_dial_line_jammed.pxo` | `assets/props/ch01/ch01_prop_flap_dial_line_jammed.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `13 / 32` | **`exported`** |
| **188** | `ch01.prop.flap_dial_platform_idle` | Props | `ch01_prop_flap_dial_platform_idle.pxo` | `assets/props/ch01/ch01_prop_flap_dial_platform_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **189** | `ch01.prop.flap_dial_platform_jammed` | Props | `ch01_prop_flap_dial_platform_jammed.pxo` | `assets/props/ch01/ch01_prop_flap_dial_platform_jammed.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `12 / 32` | **`exported`** |
| **190** | `ch01.prop.flap_dial_time_idle` | Props | `ch01_prop_flap_dial_time_idle.pxo` | `assets/props/ch01/ch01_prop_flap_dial_time_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `11 / 32` | **`exported`** |
| **191** | `ch01.prop.flap_dial_time_jammed` | Props | `ch01_prop_flap_dial_time_jammed.pxo` | `assets/props/ch01/ch01_prop_flap_dial_time_jammed.png` | `32 × 32 px` | 1f (`static`) | `(16, 28)` | `Wall_Fixtures (z_index = 7)` | `13 / 32` | **`exported`** |
| **192** | `ch01.prop.ticket_validator_idle` | Props | `ch01_prop_ticket_validator_idle.pxo` | `assets/props/ch01/ch01_prop_ticket_validator_idle.png` | `24 × 36 px` | 1f (`static`) | `(12, 30)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **193** | `ch01.prop.ticket_validator_rejecting` | Props | `ch01_prop_ticket_validator_rejecting.pxo` | `assets/props/ch01/ch01_prop_ticket_validator_rejecting.png` | `24 × 36 px` | 1f (`static`) | `(12, 30)` | `YSort_Actors (z_index = 10)` | `11 / 32` | **`exported`** |
| **194** | `ch01.prop.ticket_validator_accepted` | Props | `ch01_prop_ticket_validator_accepted.pxo` | `assets/props/ch01/ch01_prop_ticket_validator_accepted.png` | `24 × 36 px` | 1f (`static`) | `(12, 30)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **195** | `ch01.prop.staff_door_closed` | Props | `ch01_prop_staff_door_closed.pxo` | `assets/props/ch01/ch01_prop_staff_door_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `13 / 32` | **`exported`** |
| **196** | `ch01.prop.staff_door_open` | Props | `ch01_prop_staff_door_open.pxo` | `assets/props/ch01/ch01_prop_staff_door_open.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **197** | `ch01.prop.ticket_terms_notice_idle` | Props | `ch01_prop_ticket_terms_notice_idle.pxo` | `assets/props/ch01/ch01_prop_ticket_terms_notice_idle.png` | `16 × 20 px` | 1f (`static`) | `(8, 16)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **198** | `ch01.prop.service_hatch_closed` | Props | `ch01_prop_service_hatch_closed.pxo` | `assets/props/ch01/ch01_prop_service_hatch_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **199** | `ch01.prop.service_hatch_open` | Props | `ch01_prop_service_hatch_open.pxo` | `assets/props/ch01/ch01_prop_service_hatch_open.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **200** | `ch01.prop.service_hatch_frozen_open` | Props | `ch01_prop_service_hatch_frozen_open.pxo` | `assets/props/ch01/ch01_prop_service_hatch_frozen_open.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `12 / 32` | **`exported`** |
| **201** | `ch01.prop.service_hatch_frozen_closed` | Props | `ch01_prop_service_hatch_frozen_closed.pxo` | `assets/props/ch01/ch01_prop_service_hatch_frozen_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `14 / 32` | **`exported`** |
| **202** | `ch01.env.wall_bulkhead_module_idle` | Environments | `ch01_env_wall_bulkhead_module_idle.pxo` | `assets/environments/ch01/ch01_env_wall_bulkhead_module_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `10 / 32` | **`exported`** |
| **203** | `ch01.prop.floor_plate_a_empty` | Props | `ch01_prop_floor_plate_a_empty.pxo` | `assets/props/ch01/ch01_prop_floor_plate_a_empty.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `9 / 32` | **`exported`** |
| **204** | `ch01.prop.floor_plate_a_pressed` | Props | `ch01_prop_floor_plate_a_pressed.pxo` | `assets/props/ch01/ch01_prop_floor_plate_a_pressed.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `8 / 32` | **`exported`** |
| **205** | `ch01.prop.floor_plate_b_empty` | Props | `ch01_prop_floor_plate_b_empty.pxo` | `assets/props/ch01/ch01_prop_floor_plate_b_empty.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `9 / 32` | **`exported`** |
| **206** | `ch01.prop.floor_plate_b_pressed` | Props | `ch01_prop_floor_plate_b_pressed.pxo` | `assets/props/ch01/ch01_prop_floor_plate_b_pressed.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `8 / 32` | **`exported`** |
| **207** | `ch01.prop.bell_icon_idle` | Props | `ch01_prop_bell_icon_idle.pxo` | `assets/props/ch01/ch01_prop_bell_icon_idle.png` | `8 × 8 px` | 1f (`static`) | `(4, 4)` | `Wall_Fixtures (z_index = 7)` | `5 / 32` | **`exported`** |
| **208** | `ch01.prop.bell_icon_ringing` | Props | `ch01_prop_bell_icon_ringing.pxo` | `assets/props/ch01/ch01_prop_bell_icon_ringing.png` | `8 × 8 px` | 1f (`static`) | `(4, 4)` | `Wall_Fixtures (z_index = 7)` | `4 / 32` | **`exported`** |
| **209** | `ch01.prop.inner_shutter_closed` | Props | `ch01_prop_inner_shutter_closed.pxo` | `assets/props/ch01/ch01_prop_inner_shutter_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `11 / 32` | **`exported`** |
| **210** | `ch01.prop.inner_shutter_raised` | Props | `ch01_prop_inner_shutter_raised.pxo` | `assets/props/ch01/ch01_prop_inner_shutter_raised.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **211** | `ch01.prop.echo_pedestal_idle` | Props | `ch01_prop_echo_pedestal_idle.pxo` | `assets/props/ch01/ch01_prop_echo_pedestal_idle.png` | `24 × 36 px` | 1f (`static`) | `(12, 30)` | `YSort_Actors (z_index = 10)` | `8 / 32` | **`exported`** |
| **212** | `ch01.prop.echo_pedestal_used` | Props | `ch01_prop_echo_pedestal_used.pxo` | `assets/props/ch01/ch01_prop_echo_pedestal_used.png` | `24 × 36 px` | 1f (`static`) | `(12, 30)` | `YSort_Actors (z_index = 10)` | `11 / 32` | **`exported`** |
| **213** | `ch01.prop.card_reader_idle` | Props | `ch01_prop_card_reader_idle.pxo` | `assets/props/ch01/ch01_prop_card_reader_idle.png` | `16 × 24 px` | 1f (`static`) | `(8, 20)` | `Wall_Fixtures (z_index = 7)` | `8 / 32` | **`exported`** |
| **214** | `ch01.prop.card_reader_denied` | Props | `ch01_prop_card_reader_denied.pxo` | `assets/props/ch01/ch01_prop_card_reader_denied.png` | `16 × 24 px` | 1f (`static`) | `(8, 20)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **215** | `ch01.prop.card_reader_accepted` | Props | `ch01_prop_card_reader_accepted.pxo` | `assets/props/ch01/ch01_prop_card_reader_accepted.png` | `16 × 24 px` | 1f (`static`) | `(8, 20)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **216** | `ch01.prop.staff_barrier_closed` | Props | `ch01_prop_staff_barrier_closed.pxo` | `assets/props/ch01/ch01_prop_staff_barrier_closed.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **217** | `ch01.prop.staff_barrier_open` | Props | `ch01_prop_staff_barrier_open.pxo` | `assets/props/ch01/ch01_prop_staff_barrier_open.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **218** | `ch01.prop.alarm_plate_idle` | Props | `ch01_prop_alarm_plate_idle.pxo` | `assets/props/ch01/ch01_prop_alarm_plate_idle.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `9 / 32` | **`exported`** |
| **219** | `ch01.prop.alarm_plate_ringing` | Props | `ch01_prop_alarm_plate_ringing.pxo` | `assets/props/ch01/ch01_prop_alarm_plate_ringing.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `9 / 32` | **`exported`** |
| **220** | `ch01.prop.breaker_c_idle` | Props | `ch01_prop_breaker_c_idle.pxo` | `assets/props/ch01/ch01_prop_breaker_c_idle.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `7 / 32` | **`exported`** |
| **221** | `ch01.prop.breaker_c_engaged` | Props | `ch01_prop_breaker_c_engaged.pxo` | `assets/props/ch01/ch01_prop_breaker_c_engaged.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `9 / 32` | **`exported`** |
| **222** | `ch01.prop.breaker_c_browned_out` | Props | `ch01_prop_breaker_c_browned_out.pxo` | `assets/props/ch01/ch01_prop_breaker_c_browned_out.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `Wall_Fixtures (z_index = 7)` | `8 / 32` | **`exported`** |
| **223** | `ch01.prop.standby_plate_empty` | Props | `ch01_prop_standby_plate_empty.pxo` | `assets/props/ch01/ch01_prop_standby_plate_empty.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `7 / 32` | **`exported`** |
| **224** | `ch01.prop.standby_plate_held` | Props | `ch01_prop_standby_plate_held.pxo` | `assets/props/ch01/ch01_prop_standby_plate_held.png` | `32 × 16 px` | 1f (`static`) | `(16, 8)` | `YSort_Props (z_index = 8)` | `8 / 32` | **`exported`** |
| **225** | `ch01.prop.dead_relay_c_idle` | Props | `ch01_prop_dead_relay_c_idle.pxo` | `assets/props/ch01/ch01_prop_dead_relay_c_idle.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `YSort_Actors (z_index = 10)` | `9 / 32` | **`exported`** |
| **226** | `ch01.prop.dead_relay_c_shake` | Props | `ch01_prop_dead_relay_c_shake.pxo` | `assets/props/ch01/ch01_prop_dead_relay_c_shake.png` | `24 × 36 px` | 1f (`static`) | `(12, 32)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |

### 7.4 Step 1 Mockups & Greyscale Proofs (`design/art/mockups/`)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M8 | Step 1 Room 1 (`R1`) native mockup with Elias, N-01..N-04, shimmer, read outline, N-wall SO-01 fixtures, floor plates & archway gate | `design/art/mockups/ch01_step1_room_statues_mockup.png` | `640 × 360 px` | **`concept`** |
| M9 | Step 1 Room 1 (`R1`) nearest `×3` (`1920 × 1080`) presentation proof | `design/art/mockups/ch01_step1_room_statues_x3_proof.png` | `1920 × 1080 px` | **`concept`** |

The three luminance-only greyscale proofs (`design/art/mockups/ch01_step1_room_statues_greyscale_proof.png` at `1920 × 1080 px`, `design/art/mockups/ch01_step1_statues_all13_greyscale_proof.png` at `1320 × 1664 px`, and `design/art/mockups/ch01_step1_props_greyscale_proof.png` at `1320 × 1580 px` — luminance `.convert("L")` so they are not palette-table-checked) are generated deterministically from delivered runtime PNGs by `tools/art/gen/step1_mockups.py` and verified by `verify_regen.py`.

---

## 8. Chapter 1 Environmental Storytelling Props (`TLF-063`)

**Task:** TLF-063 · **Author:** Agent 2 (`Gemini 4 Argon`, Creative Asset Specialist, ADR-017) · **Art Director / Reviewer:** `GPT-6.1 Sol` (`ART_BIBLE.md` §C.6–C.7) · **Palette:** `TLF-CH01-32` (`0` new colours, `0` off-palette, `0` semi-transparent pixels) · **Generator:** `tools/art/gen/tlf063_story_props.py` (5 assets + 2 mockup/proof sheets), registered in `tools/art/gen/registry.py`, `gen_all.py`, and `verify_regen.py`.

### 8.1 Story Reason & Visual Direction Summary (`ART_BIBLE.md` §C.6, `docs/NARRATIVE_DESIGN.md` §4)
- **1. Departure Board (`ch01_prop_departure_board_nowhere_idle`, `160 × 32 px`):** Arrival Platform overhead display announcing `DESTINATION:` / `NOWHERE - 23:59` in native `5 × 7` pixel font (`24/25` digits on `00` recessed cavity inside a `11..15` steel housing). Shows transit service continuing to announce a destination that no longer exists after the `23:54` evacuation.
- **2A. Directional Wall Sign (`ch01_prop_sign_a1_research_idle`, `96 × 16 px`):** Corridor wayfinding plaque reading `A1 -> RESEARCH` in native `5 × 7` font (`22/25` left sector badge + `15/25` directional text). Establishes that Station Elysium-09 fed the main ELYSIUM research facility without prematurely naming Elias's role.
- **2B. Sealed `R&D ACCESS` Door Dressing (`ch01_prop_door_rd_access_sealed_idle`, `32 × 64 px`):** Non-traversable `2:1` down-left isometric steel bulkhead door dressing (`_y_iso(x, z) = (31 - x) // 2 + z`, pivot `(16, 56)`) with a bolted/clamped vertical seam, worn `22` caution stripes, and a small non-glowing `R&D ACCESS` padlock plaque. Mounted over existing non-traversable archway/wall dressing with zero glowing access prompt.
- **3. Sector A Pillar Mark Decal (`ch01_prop_pillar_mark_sector_a_idle`, `16 × 16 px`):** Small `16 × 16 px` civic wayfinding stencil decal (`11..15` steel frame, `22/23` crimson transit stripe, `24/25` `A` mark) designed to mount onto existing `ch01_env_wall_corner_pillar_idle` geometry away from puzzle lever `A`/`B` badges and floor plates.
- **4. `CLOSED TRACK` Notice Plaque (`ch01_prop_notice_closed_track_idle`, `80 × 16 px`):** Wall notice reading `CLOSED TRACK` in native `5 × 7` font (`14/15` on `12` slate plaque) crossed by a single bold `00/22/23` diagonal closure slash, recording track closure prior to the `23:59` standstill without invented lore text.

### 8.2 `TLF-063` Asset Inventory Table (`row` 227–231)

| Row | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **227** | `ch01.prop.departure_board_nowhere_idle` | Props | `ch01_prop_departure_board_nowhere_idle.pxo` | `assets/props/ch01/ch01_prop_departure_board_nowhere_idle.png` | `160 × 32 px` | 1f (`static`) | `(80, 28)` | `Wall_Fixtures (z_index = 7)` | `10 / 32` | **`exported`** |
| **228** | `ch01.prop.sign_a1_research_idle` | Props | `ch01_prop_sign_a1_research_idle.pxo` | `assets/props/ch01/ch01_prop_sign_a1_research_idle.png` | `96 × 16 px` | 1f (`static`) | `(48, 14)` | `Wall_Fixtures (z_index = 7)` | `9 / 32` | **`exported`** |
| **229** | `ch01.prop.door_rd_access_sealed_idle` | Props | `ch01_prop_door_rd_access_sealed_idle.pxo` | `assets/props/ch01/ch01_prop_door_rd_access_sealed_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `Wall_Fixtures (z_index = 7)` | `11 / 32` | **`exported`** |
| **230** | `ch01.prop.pillar_mark_sector_a_idle` | Props | `ch01_prop_pillar_mark_sector_a_idle.pxo` | `assets/props/ch01/ch01_prop_pillar_mark_sector_a_idle.png` | `16 × 16 px` | 1f (`static`) | `(8, 14)` | `Wall_Fixtures (z_index = 7)` | `9 / 32` | **`exported`** |
| **231** | `ch01.prop.notice_closed_track_idle` | Props | `ch01_prop_notice_closed_track_idle.pxo` | `assets/props/ch01/ch01_prop_notice_closed_track_idle.png` | `80 × 16 px` | 1f (`static`) | `(40, 14)` | `Wall_Fixtures (z_index = 7)` | `9 / 32` | **`exported`** |

### 8.3 `TLF-063` Mockups & Greyscale Proofs (`design/art/mockups/`)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M10 | Arrival Platform (`R1`) storytelling props room mockup + `2:1` sealed R&D door & Sector A pillar inset | `design/art/mockups/ch01_tlf063_story_props_room_mockup.png` | `640 × 360 px` | **`concept`** |

The colour + luminance-greyscale contact sheet (`design/art/mockups/ch01_tlf063_story_props_greyscale_proof.png` at `1320 × 1040 px` — luminance `.convert("L")` lower half so it is not palette-table-checked) is generated deterministically from delivered runtime PNGs by `tools/art/gen/tlf063_story_props.py` and verified by `verify_regen.py`.

---

## 9. Operator Sighting Sprite & Beat 10 City Plate (`TLF-062`)

**Task:** TLF-062 · **Author:** Agent 2 (`Gemini 4 Argon`, Creative Asset Specialist, ADR-017) · **Art Director / Reviewer:** `GPT-6.1 Sol` (`ART_BIBLE.md` §C.3–C.5, §C.7, §C.8, `ADR-022 A3`, `cb2acbd`) · **Palette:** `TLF-CH01-32` (`0` new colours, `0` off-palette, `0` semi-transparent pixels) · **Generator:** `tools/art/gen/tlf062_operator_city.py` (6 assets + 5 mockup/proof sheets), registered in `tools/art/gen/registry.py`, `gen_all.py`, and `verify_regen.py`.

### 9.1 Visual Direction & Technical Contract Summary (`ART_BIBLE.md` §C.3–C.5)
- **Operator Sighting Sprite (`ch01_char_operator_sighting_ne_sheet`):** `128 × 48 px` horizontal 4-frame sheet (`4 × 32 × 48 px`), foot pivot `(16, 44)`, foot sole fixed at `y = 44`, `YSort_Actors (z_index = 10)`, back-three-quarter `ne` view facing away along the Arrival Platform (`R1`). Authored across 5 named `.pxo` layers (`Contact_Shadow`, `Robe`, `Hood_Mask`, `Scarf`, `Hand_Watch`) with tag `check_watch_ne` (frames `1–4`, base `8 FPS`, frame durations `[2.0, 2.0, 8.0, 2.0]` ticks = **`0.25 s / 0.25 s / 1.00 s / 0.25 s`**, `1.75 s` per cycle; hold `F1` a further `1.00 s` between cycles if sighting persists; **`F3` (`check`, frame 3) is the static `reduced_effects` pose**).
- **Operator Secrecy & Link Rules (`OPERATOR_MYSTERY_GUIDELINES.md` §4 & §6):** Peaked hood and closed mask (`00..04` robe, `12..14` closed mask rim under right hood edge) with **zero visible face, skin (`20/21`), eyes (`31`), mouth, or hair (`16..19`)**, and **no hourglass or combat poses**. Carries Elias's `3 × 3` brass pocket watch (`25/26`, hollow `00` dial centre, `1 px` `26` crown, short `25` chain) outside the robe contour on `F3` (`x = 26..28, y = 20..22`).
- **Disclosed Current-Build Parity Gaps & Ch1 Scarf-Hidden Export (`ART_BIBLE.md` §C.2/C.3, `ADR-022 A3`, Sol `cb2acbd`):** Current Elias `v2` (`ch01_char_elias_base_sheet`) has a dark slate collar (`02`, no red scarf) and idle/walk animations only (no watch-check clip). Per `ADR-022 A3` and Sol's visual review (`cb2acbd`), Elias `v2` is retained untouched for Ch1 and the Operator's red scarf (`22` `#4A1C14` / `23` `#8C2D19`, 12 pixels per frame) is retained on its own separate `Scarf` layer in `ch01_char_operator_sighting_ne_sheet.pxo` over a gap-free `Robe`/`Hood_Mask` backing (`0` underlying gaps), **disabled by default (`visible: false`)** so every shipped Ch1 sprite export, Pixelorama re-export, and production proof is scarf-hidden.
- **Restrained Trace Signature (`ch01_fx_operator_sighting_trace_ring_idle`):** Separate `32 × 48 px` ground effect export (`YSort_Props (z_index = 8)`, pivot `(16, 44)`) using the existing Trace `#9E7BFF` (`30`) + sparse `#FFD166` (`26`) isometric diamond/ellipse strictly outside the body and watch silhouette (`y >= 41`); suppressed in `reduced_effects` mode.
- **Beat 10 Frozen City Plate & Silent Mira Broadcast (`ART_BIBLE.md` §C.4):** `1280 × 360 px` nocturnal `2:1` isometric plate (`ch01_env_beat10_city_plate_idle`, `CanvasLayer (z_index = 20)`) authored across 5 `.pxo` layers (`Sky_And_Distant_Towers`, `Plaza_And_Station_Exit`, `Clocks_2359`, `Mira_Broadcast_Screen`, `Suspended_Rain`), plus standalone layer exports for independent runtime compositing (`ch01_env_beat10_city_backdrop_idle` at `1280 × 360`, `ch01_ui_mira_broadcast_portrait_idle` at `32 × 48`, and `ch01_env_beat10_suspended_rain_idle` at `1280 × 360` — alpha-compositing backdrop + Mira portrait at `(440, 136)` and `(844, 104)` + suspended rain reproduces `ch01_env_beat10_city_plate_idle` with **`0` differing pixels**).

### 9.2 `TLF-062` Asset Inventory Table (`row` 232–237)

| Row | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS / Cadence | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **232** | `ch01.char.operator_sighting_ne_sheet` | Characters | `ch01_char_operator_sighting_ne_sheet.pxo` | `assets/characters/ch01/ch01_char_operator_sighting_ne_sheet.png` | `128 × 48 px (4× 32×48)` | 4f @ 8 FPS (`0.25/0.25/1.00/0.25s`, tag `check_watch_ne`, `F3` static reduced-FX) | `(16, 44)` | `YSort_Actors (z_index = 10)` | `10 / 32` | **`exported`** |
| **233** | `ch01.fx.operator_sighting_trace_ring_idle` | Props | `ch01_fx_operator_sighting_trace_ring_idle.pxo` | `assets/props/ch01/ch01_fx_operator_sighting_trace_ring_idle.png` | `32 × 48 px` | 1f (`static`) | `(16, 44)` | `YSort_Props (z_index = 8)` | `3 / 32` | **`exported`** |
| **234** | `ch01.ui.mira_broadcast_portrait_idle` | Ui | `ch01_ui_mira_broadcast_portrait_idle.pxo` | `assets/ui/ch01/ch01_ui_mira_broadcast_portrait_idle.png` | `32 × 48 px` | 1f (`static`) | `(0, 0)` | `CanvasLayer (z_index = 21)` | `14 / 32` | **`exported`** |
| **235** | `ch01.env.beat10_city_plate_idle` | Environments | `ch01_env_beat10_city_plate_idle.pxo` | `assets/environments/ch01/ch01_env_beat10_city_plate_idle.png` | `1280 × 360 px` | 1f (`static`) | `(0, 0)` | `CanvasLayer (z_index = 20)` | `22 / 32` | **`exported`** |
| **236** | `ch01.env.beat10_city_backdrop_idle` | Environments | `ch01_env_beat10_city_backdrop_idle.pxo` | `assets/environments/ch01/ch01_env_beat10_city_backdrop_idle.png` | `1280 × 360 px` | 1f (`static`) | `(0, 0)` | `CanvasLayer (z_index = 20)` | `15 / 32` | **`exported`** |
| **237** | `ch01.env.beat10_suspended_rain_idle` | Environments | `ch01_env_beat10_suspended_rain_idle.pxo` | `assets/environments/ch01/ch01_env_beat10_suspended_rain_idle.png` | `1280 × 360 px` | 1f (`static`) | `(0, 0)` | `CanvasLayer (z_index = 22)` | `4 / 32` | **`exported`** |

### 9.3 `TLF-062` Mockups & Greyscale Proofs (`design/art/mockups/`)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M11 | Arrival Platform (`R1`) Operator sighting native mockup with `F1..F4` + `reduced_effects` static `F3` inset | `design/art/mockups/ch01_operator_sighting_platform_mockup.png` | `640 × 360 px` | **`concept`** |
| M12 | Beat 10 frozen city plate native `1×` start pan crop (`x = 0..640`, Station Exit -> `2:1` Plaza) | `design/art/mockups/ch01_beat10_city_pan_start_640x360_mockup.png` | `640 × 360 px` | **`concept`** |
| M13 | Beat 10 frozen city plate native `1×` end pan crop (`x = 640..1280`, `2:1` Broadcast Tower & Plaza) | `design/art/mockups/ch01_beat10_city_pan_end_640x360_mockup.png` | `640 × 360 px` | **`concept`** |

The two colour + luminance-greyscale proof sheets (`design/art/mockups/ch01_operator_cast_silhouette_greyscale_proof.png` at `1320 × 1160 px` and `design/art/mockups/ch01_beat10_city_plate_greyscale_proof.png` at `1320 × 1260 px` — luminance `.convert("L")` sections so they are not palette-table-checked) are generated deterministically from delivered runtime PNGs by `tools/art/gen/tlf062_operator_city.py` and verified by `verify_regen.py`.

---

## 10. Shape Art Kit for Non-Rectangular Chapter 1 Rooms (`TLF-068`, `ADR-023` + `R2b`)

**Task:** TLF-068 · **Author:** Agent 2 (`Gemini 4 Argon`, Creative Asset Specialist, ADR-017) · **Art Director / Reviewer:** `GPT-6.1 Sol` (`ADR-023`, `R2`, `R2b`, `R3`) · **Palette:** `TLF-CH01-32` (`0` new colours, `0` off-palette, `0` semi-transparent pixels) · **Generator:** `tools/art/gen/tlf068_shape_kit.py` (12 assets + 2 mockup/proof sheets), registered in `tools/art/gen/registry.py`, `gen_all.py`, and `verify_regen.py`.

### 10.1 Architectural & Geometric Contract (`ADR-023` R2, R2b, R3)
- **1. Tall N/W Corner Pieces (`32 × 64 px`, pivot `(16, 56)`, `offset = Vector2(-16, -56)`, `YSort_Walls (z_index = 5)`):**
  - Anchored directly at the polygon vertex `RoomShape.tile_to_px(v)` where `v = s["from"] == s["to"]`.
  - Covers the 6 tall-wall vertex configurations emitted by `RoomShape.wall_segments()`:
    - `ch01_env_wall_subterranean_corner_nw_outer_idle` (`kind = &"outer_corner"`, `faces = [&"W", &"N"]`): convex room top apex joining a `W` run (`Step 0` Mid-Light, `08` ceramic / `25` amber dado) on the left and an `N` run (`Step -1` Mid-Dark, `07` ceramic / `24` amber dado) on the right with a recessed interior steel corner angle and mitered cornice cap.
    - `ch01_env_wall_subterranean_corner_nw_inner_idle` (`kind = &"inner_corner"`, `faces = [&"N", &"W"]`): concave room vertex protruding toward the camera, joining an `N` run on the left and a `W` run on the right with a chamfered exterior steel/ceramic bullnose quoin (`13..14` top-left highlight, `26` amber corner chevron).
    - `ch01_env_wall_subterranean_corner_n_turn_outer_idle` (`kind = &"outer_corner"`, `faces = [&"N", &"low_E"]`): N-turn East apex where a tall `N` run terminates in a `6 px` `2:1` isometric steel bulkhead return cap (`x = 16..21`) and turns down-left into a `low_E` partition (`16 px` tall) through a corner bollard at `(16, 56)`.
    - `ch01_env_wall_subterranean_corner_n_turn_inner_idle` (`kind = &"inner_corner"`, `faces = [&"low_E", &"N"]`): N-turn NE concave cut (`Rule R2b`) where an incoming `low_E` partition turns at `(16, 56)` into a tall `N` run, stepping up from a `16 px` corner bollard (`x = 16..20`) through a `32 px` steel bulkhead step (`x = 21..25`) to full `48 px` tall `N` wall height (`x = 26..31`) so `x = 31` joins seamlessly with `ch01_env_wall_subterranean_n_idle`.
    - `ch01_env_wall_subterranean_corner_w_turn_outer_idle` (`kind = &"outer_corner"`, `faces = [&"low_S", &"W"]`): W-turn West apex where a tall `W` run terminates in a `6 px` `2:1` isometric steel bulkhead return cap (`x = 10..15`) and turns down-right into a `low_S` partition (`16 px` tall) through a corner bollard at `(16, 56)`.
    - `ch01_env_wall_subterranean_corner_w_turn_inner_idle` (`kind = &"inner_corner"`, `faces = [&"W", &"low_S"]`): W-turn SW concave cut (`Rule R2b`) where an incoming `low_S` partition turns at `(16, 56)` into a tall `W` run, stepping up from a `16 px` corner bollard (`x = 11..18`) through a `32 px` steel bulkhead step (`x = 6..10`) to full `48 px` tall `W` wall height (`x = 0..5`) so `x = 0` joins seamlessly with `ch01_env_wall_subterranean_w_idle`.
- **2. Low Partition Pieces for `low_S` and `low_E` (`Rule R2`: `16 px` vertical height `<= 20 px`, `32 × 32 px` canvas, pivot `(16, 24)`, `offset = Vector2(-16, -24)`, `YSort_Walls (z_index = 5)`):**
  - Because the vertical parapet height is `16 px` (`z_down = 0..16`, `<= 20 px`), Elias (`32 × 48 px`) is never hidden when walking along south/east boundaries or inside concave L/T cuts.
  - Shares the station architectural language: steel coping cap (`08..10`), ceramic parapet course (`07/06` on `low_S`, `08/07` on `low_E`), continuous `24/25` amber safety dado band (`z_down = 4..6`), riveted steel stanchions (`x = 7..8, 23..24`), and dark steel/obsidian floor skirting (`11/12/00` at `z_down = 14..16`).
  - Comprises `ch01_env_wall_partition_low_s_idle` (straight `low_S` 2-tile run), `ch01_env_wall_partition_low_e_idle` (straight `low_E` 2-tile run), `ch01_env_wall_partition_low_corner_inner_idle` (concave `[low_S, low_E]` SE L-cut corner per `Rule R2b`), and `ch01_env_wall_partition_low_corner_outer_idle` (convex `[low_E, low_S]` South apex corner).
- **3. Low End Cap Pieces for Tall N/W Wall Terminations & Odd 1-Tile Ends (`Rule R2b`, `32 × 64 px`, pivot `(16, 56)`, `offset = Vector2(-16, -56)`):**
  - `ch01_env_wall_subterranean_n_endcap_low_idle` and `ch01_env_wall_subterranean_w_endcap_low_idle` terminate a tall `48 px` `N` or `W` wall at a doorway/corridor opening, concave corner, or odd-length 1-tile end (`odd_ends` in `tools/content/build_room_from_shape.py`), stepping from full `48 px` wall height down through a `30 px` riveted steel bulkhead to a `16 px` low partition end-cap bollard.
- **4. Floor-Edge Concave Cut Verification (No Separate Floor-Edge Tile Required):**
  - Tested across all 4 L-shape concave cut orientations (`SE`, `SW`, `NE`, `NW`) with `ch01_tileset.tres` (`ch01_env_tile_terrazzo_dark_idle.png`, `32 × 16 px` diamond): `0` internal transparent gap pixels across all adjacent floor cells (`2 px` seamless shared edge overlap), and every tile already carries a continuous `2 px` `#141A26` (`01`) dark mortar border on `low_S`/`low_E` edges and `#3F4F6B`/`#2D394F` (`04`/`03`) bevel on `N`/`W` edges, which is further covered by the low partition base skirting (`00/11/12`). No extra floor-edge tile asset is required.

### 10.2 `RoomShape.wall_segments()` -> Endpoint-Aware Assembly Recipe & Asset Mapping Table

In `scripts/rooms/room_shape.gd` (and `tools/content/build_room_from_shape.py`), `RoomShape.wall_segments()` returns dictionaries with `face` (`&"N"`, `&"W"`, `&"low_S"`, `&"low_E"`), `from` (`Vector2i`), `to` (`Vector2i`), `kind` (`&"straight"`, `&"inner_corner"`, `&"outer_corner"`), and (for corners) `faces` (`[prev_face, next_face]`). All coordinates use `RoomShape.tile_to_px(t) = Vector2(320 + (t.x - t.y) * 16, 64 + (t.x + t.y) * 8)` with `centered = false` and `offset = -pivot`.

#### Endpoint-Aware Straight-Run Assembly Recipe (`assemble_wall_run()` in `tools/art/gen/tlf068_shape_kit.py`)

Every `32 px`-wide vertex corner sprite centered on `v` (`pivot = (16, 56)` on `32 × 64` tall/turn corners; `pivot = (16, 24)` on `32 × 32` low corners) spans `16 px` (`1` tile) left of `v` (`x = 0..15`) and `16 px` (`1` tile) right of `v` (`x = 16..31`), so it already supplies **`1` tile on its incoming edge (`[to - 1, to]`)** and **`1` tile on its outgoing edge (`[from, from + 1]`)**. Specifically:
- On `ch01_env_wall_subterranean_corner_n_turn_inner_idle` (`faces = [&"low_E", &"N"]` at `v = from`), **both** the incoming `low_E` arm (`[to.y - 1, to.y]`, `16 px` tall) and the outgoing `N` arm (`[from.x, from.x + 1]`, stepping up `16 px -> 32 px -> 48 px`: `x = 16..20` bollard, `x = 21..25` steel step, `x = 26..31` full `48 px` tall `N` profile) project into **`x = 16..31`** (because both `(v.x, v.y - 1)` and `(v.x + 1, v.y)` have `(t.x - t.y) == (v.x - v.y) + 1`). Because `x = 16..25` is intentionally transparent above the stepped profile, placing a full-height `WallN` module at `from.x + 1` (covering `[from.x, from.x + 2]`) would refill `227` opaque pixels above the step.
- Symmetric rule on `ch01_env_wall_subterranean_corner_w_turn_inner_idle` (`faces = [&"W", &"low_S"]` at `v = from`): **both** the incoming `low_S` arm (`[to.x - 1, to.x]`, `16 px` tall) and the outgoing `W` arm (`[from.y, from.y + 1]`, stepping up `16 px -> 32 px -> 48 px`: `x = 11..15` bollard, `x = 6..10` steel step, `x = 0..5` full `48 px` tall `W` profile) project into **`x = 0..15`** (because both `(v.x - 1, v.y)` and `(v.x, v.y + 1)` have `(t.x - t.y) == (v.x - v.y) - 1`); placing `WallW` at `from.y + 1` would likewise refill `227` opaque pixels above the step.

For any straight segment `from -> to` on `face in {&"N", &"W", &"low_S", &"low_E"}` along active axis coordinate `f -> t` (`f = from.x, t = to.x` on `N`/`low_S`; `f = from.y, t = to.y` on `W`/`low_E`, with `f < t` and total tile length `L = t - f`):

1. **Effective straight-module start `s_start` (first straight-module anchor next to each start corner kind):**
   - **After `n_turn_inner` on `N` or `w_turn_inner` on `W` (`start_kind == "inner_turn"`):** `s_start = f + 1` (preserving the `[f, f + 1]` low-to-tall step-up supplied by the corner). The **first** 2-tile straight module is anchored at **`u_0 = s_start + 1 = f + 2`** (`tile_to_px(from.x + 2, from.y)` on `N`; `tile_to_px(from.x, from.y + 2)` on `W`), covering `[f + 1, f + 3]` so its outer column (`x = 0` on `WallN`, `x = 31` on `WallW`) abuts the corner's full-height `48 px` edge (`x = 31` on `n_turn_inner`, `x = 0` on `w_turn_inner`) with `0` gap pixels and `0` refilled pixels above the step.
   - **After all other start corners (`nw_outer`, `nw_inner`, `n_turn_outer`, `w_turn_outer`, `low_corner_inner`, `low_corner_outer`, or open start):** `s_start = f`. The **first** 2-tile straight module is anchored at **`u_0 = s_start + 1 = f + 1`** (`tile_to_px(from.x + 1, from.y)` on `N`/`low_S`; `tile_to_px(from.x, from.y + 1)` on `W`/`low_E`), covering `[f, f + 2]` at matching height underneath the corner sprite (`z_bias = +10`).
2. **Effective straight-module end `s_end` (last straight-module anchor next to each end corner / endcap kind):**
   - **Before any uncornered/open tall `N`/`W` termination (`end_kind == "endcap_low"`, required for both a `Rule R2b` doorway/corridor opening and any uncornered odd/even open end, where `n_endcap_low` / `w_endcap_low` is anchored at `t - 1` covering `[t - 2, t]`):** `s_end = t - 1` (reserving `[t - 1, t]` for the endcap's `30 px -> 16 px` stepped half so no tall module refills it, while its full-height `48 px` inner half supplies `[t - 2, t - 1]`). *(Note: `assemble_wall_run()` also accepts `"open_odd"` as a compatibility alias for `"endcap_low"`.)*
   - **Before any corner piece at `t` (`end_kind == "corner"`: `n_turn_outer`, `w_turn_outer`, `nw_inner`, `nw_outer`, `n_turn_inner`, `w_turn_inner`, `low_corner_inner`, `low_corner_outer`):** `s_end = t`.
3. **Straight 2-tile module count `m` and anchors `u_k` (`k = 0 .. m - 1`):**
   - Compute `rem = max(0, s_end - s_start)` and `m = rem // 2`.
   - Place `m` 2-tile straight modules (`WallN`, `WallW`, `LowS`, or `LowE`, each spanning `[u_k - 1, u_k + 1]`) at axis coordinates:
     $$u_k = s_{\text{start}} + 2k + 1 \quad \text{for } k \in \{0, 1, \dots, m - 1\}$$
     so the **first** straight module is at `u_0 = s_start + 1` and the **last** straight module is at `u_{m-1} = s_start + 2*m - 1` (covering `[s_start, s_start + 2*m]`).
4. **Residual / odd-length end handling (`rem % 2 == 1` vs `rem % 2 == 0`) & `z_bias` layering:**
   - **When `rem` is even (`2*m == rem`, e.g., an uncornered odd `L = 3` run `assemble_wall_run('N', (0,0), (3,0), 'corner', 'endcap_low')` or `assemble_wall_run('W', (0,0), (0,3), 'corner', 'endcap_low')` where `s_start = 0, s_end = 2, rem = 2, m = 1`):** The `m` straight modules cover `[s_start, s_end]` (`WallN(1,0)` / `WallW(0,1)` covering `[0,2]`). When `end_kind == "corner"`, the end corner at `t` (`z_bias = +10`) composites over `[t - 1, t]` at matching height; when `end_kind == "endcap_low"`, `n_endcap_low(2,0)` / `w_endcap_low(0,2)` (`z_bias = +2`) covers `[1, 2]` with its full-height `48 px` inner half and supplies the final uncornered tile `[2, 3]` with its `30 -> 16 px` stepped half (`0` empty columns, `0` refilled step pixels).
   - **When `rem` is odd (`2*m == rem - 1`, e.g., a 3-tile corner-ended run `(0,0)->(3,0)` with `s_start = 0, s_end = 3, rem = 3, m = 1` at `u_0 = 1`; a 4-tile inner-turn run `(0,0)->(4,0)` after `n_turn_inner` with `s_start = 1, s_end = 4, rem = 3, m = 1` at `u_0 = 2`; or a 4-tile open/endcap run `assemble_wall_run('N', (0,0), (4,0), 'corner', 'endcap_low')` with `s_start = 0, s_end = 3, rem = 3, m = 1` at `u_0 = 1`):** The `m` straight modules cover `[s_start, s_end - 1]`, and the remaining 1-tile residual interval **`[s_end - 1, s_end]` is already 100% supplied** by:
     - when `end_kind == "corner"`, the end corner's incoming 1-tile wing `[t - 1, t]` (`x = 0..15` on `n_turn_outer` / `nw_inner` / `w_turn_inner` / `low_corner_outer`; `x = 16..31` on `w_turn_outer` / `n_turn_inner`), which has matching `48 px` tall or `16 px` low profile across that full tile, **or**
     - when `end_kind == "endcap_low"` (`s_end = t - 1`), the full-height `48 px` inner half `[t - 2, t - 1]` of `n_endcap_low` / `w_endcap_low` anchored at `t - 1` (while its outer half `[t - 1, t]` steps down to `16 px`).

| `wall_segments()` `kind` | `face` | `faces` (`[prev, next]`) | Asset Filename (`assets/environments/ch01/`) | Canvas (`W×H`) | Pivot / `offset` | Tile / Vertex Anchor `position` (`RoomShape.tile_to_px(...)`) | Edge Occupancy & Endpoint Rule |
|---|---|---|---|---|---|---|---|
| `&"straight"` | `&"N"` | *(n/a)* | `ch01_env_wall_subterranean_n_idle.png` *(existing)* | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(s_start + 2*k + 1, from.y)` for `k in 0 .. (rem // 2) - 1` (`s_start = from.x + 1` after `n_turn_inner`, else `from.x`; `s_end = to.x - 1` when `end_kind == "endcap_low"`, else `to.x`; `rem = s_end - s_start`) | Each module spans `[u_k - 1, u_k + 1]`; first at `from.x + 2` after `n_turn_inner`, `from.x + 1` after `nw_outer`; odd residual `[s_end - 1, s_end]` supplied by end corner/endcap |
| `&"straight"` | `&"W"` | *(n/a)* | `ch01_env_wall_subterranean_w_idle.png` *(existing)* | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from.x, s_start + 2*k + 1)` for `k in 0 .. (rem // 2) - 1` (`s_start = from.y + 1` after `w_turn_inner`, else `from.y`; `s_end = to.y - 1` when `end_kind == "endcap_low"`, else `to.y`; `rem = s_end - s_start`) | Each module spans `[u_k - 1, u_k + 1]`; first at `from.y + 2` after `w_turn_inner`, `from.y + 1` after `nw_outer`; odd residual `[s_end - 1, s_end]` supplied by end corner/endcap |
| `&"straight"` *(`end_kind == "endcap_low"`)* | `&"N"` | *(n/a)* | `ch01_env_wall_subterranean_n_endcap_low_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(to.x - 1, from.y)` (`z_bias = +2`) | Required for any uncornered/open `N` end (R2b opening or odd/even open end). Spans `[to.x - 2, to.x]`: `x = 0..15` (`[to.x - 2, to.x - 1]`) is `48 px` tall `N` wall; `x = 16..31` (`[to.x - 1, to.x]`) steps `30 px -> 16 px` (`s_end = to.x - 1`) |
| `&"straight"` *(`end_kind == "endcap_low"`)* | `&"W"` | *(n/a)* | `ch01_env_wall_subterranean_w_endcap_low_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from.x, to.y - 1)` (`z_bias = +2`) | Required for any uncornered/open `W` end (R2b opening or odd/even open end). Spans `[to.y - 2, to.y]`: `x = 16..31` (`[to.y - 2, to.y - 1]`) is `48 px` tall `W` wall; `x = 0..15` (`[to.y - 1, to.y]`) steps `30 px -> 16 px` (`s_end = to.y - 1`) |
| `&"straight"` | `&"low_S"` | *(n/a)* | `ch01_env_wall_partition_low_s_idle.png` | `32 × 32 px` | `(16, 24)` / `Vector2(-16, -24)` | `tile_to_px(from.x + 2*k + 1, from.y)` for `k in 0 .. (rem // 2) - 1` (`s_start = from.x`, `s_end = to.x`, `rem = to.x - from.x`) | `Rule R2`: `16 px <= 20 px` tall; odd residual `[to.x - 1, to.x]` supplied by end corner `[to.x - 1, to.x]` wing |
| `&"straight"` | `&"low_E"` | *(n/a)* | `ch01_env_wall_partition_low_e_idle.png` | `32 × 32 px` | `(16, 24)` / `Vector2(-16, -24)` | `tile_to_px(from.x, from.y + 2*k + 1)` for `k in 0 .. (rem // 2) - 1` (`s_start = from.y`, `s_end = to.y`, `rem = to.y - from.y`) | `Rule R2`: `16 px <= 20 px` tall; odd residual `[to.y - 1, to.y]` supplied by end corner `[to.y - 1, to.y]` wing |
| `&"outer_corner"` | `&"N"` | `[&"W", &"N"]` | `ch01_env_wall_subterranean_corner_nw_outer_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `48 px` `[v.y, v.y + 1]` on `W` (`x = 0..15`) and `48 px` `[v.x, v.x + 1]` on `N` (`x = 16..31`); next straight starts at `s_start = f` (`u_0 = f + 1`) |
| `&"inner_corner"` | `&"N"` | `[&"N", &"W"]` | `ch01_env_wall_subterranean_corner_nw_inner_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `48 px` `[v.x - 1, v.x]` on incoming `N` and `48 px` `[v.y, v.y + 1]` on outgoing `W` (`x = 0..15` wings + `x = 15..20` corner pillar) |
| `&"outer_corner"` | `&"N"` | `[&"N", &"low_E"]` | `ch01_env_wall_subterranean_corner_n_turn_outer_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `48 px` `[v.x - 1, v.x]` on incoming `N` (`x = 0..15`) + `6 px` return cap (`x = 16..21`) + `16 px` `[v.y, v.y + 1]` on outgoing `low_E` (`x = 0..15`) |
| `&"inner_corner"` | `&"N"` | `[&"low_E", &"N"]` | `ch01_env_wall_subterranean_corner_n_turn_inner_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `16 px` `[v.y - 1, v.y]` on incoming `low_E` and stepped `16->32->48 px` `[v.x, v.x + 1]` on outgoing `N` (both in `x = 16..31`); sets `s_start = v.x + 1` (first `WallN` at `v.x + 2`) |
| `&"outer_corner"` | `&"W"` | `[&"low_S", &"W"]` | `ch01_env_wall_subterranean_corner_w_turn_outer_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `48 px` `[v.y - 1, v.y]` on `W` (`x = 16..31`) + `6 px` return cap (`x = 10..15`) + `16 px` `[v.x, v.x + 1]` on `low_S` (`x = 16..31`) |
| `&"inner_corner"` | `&"W"` | `[&"W", &"low_S"]` | `ch01_env_wall_subterranean_corner_w_turn_inner_idle.png` | `32 × 64 px` | `(16, 56)` / `Vector2(-16, -56)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `16 px` `[v.x - 1, v.x]` on `low_S` and stepped `16->32->48 px` `[v.y, v.y + 1]` on `W` (both in `x = 0..15`); sets `s_start = v.y + 1` (first `WallW` at `v.y + 2`) |
| `&"inner_corner"` | `&"low_S"` | `[&"low_S", &"low_E"]` | `ch01_env_wall_partition_low_corner_inner_idle.png` | `32 × 32 px` | `(16, 24)` / `Vector2(-16, -24)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `16 px` `[v.x, v.x + 1]` on `low_S` (`x = 16..31`) and `16 px` `[v.y, v.y + 1]` on `low_E` (`x = 0..15`); `s_start = f` (`u_0 = f + 1`) |
| `&"outer_corner"` | `&"low_S"` | `[&"low_E", &"low_S"]` | `ch01_env_wall_partition_low_corner_outer_idle.png` | `32 × 32 px` | `(16, 24)` / `Vector2(-16, -24)` | `tile_to_px(from)` (`from == to == v`, `z_bias = +10`) | Supplies `16 px` `[v.x - 1, v.x]` on `low_S` (`x = 0..15`) and `16 px` `[v.y - 1, v.y]` on `low_E` (`x = 16..31`) |

### 10.3 `TLF-068` Asset Inventory Table (`row` 238–249)

| Row | Asset ID | Category | Source `.pxo` (`assets/source/ch01/`) | Runtime Export (`res://assets/...`) | Canvas Size (`W×H px`) | Frames / FPS | Pivot `(px_x, px_y)` | Sorting / `z_index` | Palette Colors Used | QA State |
|---|---|---|---|---|---|---|---|---|---|---|
| **238** | `ch01.env.wall_subterranean_corner_nw_outer_idle` | Environments | `ch01_env_wall_subterranean_corner_nw_outer_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_nw_outer_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `11 / 32` | **`exported`** |
| **239** | `ch01.env.wall_subterranean_corner_nw_inner_idle` | Environments | `ch01_env_wall_subterranean_corner_nw_inner_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_nw_inner_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `12 / 32` | **`exported`** |
| **240** | `ch01.env.wall_subterranean_corner_n_turn_outer_idle` | Environments | `ch01_env_wall_subterranean_corner_n_turn_outer_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_n_turn_outer_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `12 / 32` | **`exported`** |
| **241** | `ch01.env.wall_subterranean_corner_n_turn_inner_idle` | Environments | `ch01_env_wall_subterranean_corner_n_turn_inner_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_n_turn_inner_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `11 / 32` | **`exported`** |
| **242** | `ch01.env.wall_subterranean_corner_w_turn_outer_idle` | Environments | `ch01_env_wall_subterranean_corner_w_turn_outer_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_w_turn_outer_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `11 / 32` | **`exported`** |
| **243** | `ch01.env.wall_subterranean_corner_w_turn_inner_idle` | Environments | `ch01_env_wall_subterranean_corner_w_turn_inner_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_corner_w_turn_inner_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `11 / 32` | **`exported`** |
| **244** | `ch01.env.wall_partition_low_s_idle` | Environments | `ch01_env_wall_partition_low_s_idle.pxo` | `assets/environments/ch01/ch01_env_wall_partition_low_s_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 24)` | `YSort_Walls (z_index = 5)` | `9 / 32` | **`exported`** |
| **245** | `ch01.env.wall_partition_low_e_idle` | Environments | `ch01_env_wall_partition_low_e_idle.pxo` | `assets/environments/ch01/ch01_env_wall_partition_low_e_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 24)` | `YSort_Walls (z_index = 5)` | `9 / 32` | **`exported`** |
| **246** | `ch01.env.wall_partition_low_corner_inner_idle` | Environments | `ch01_env_wall_partition_low_corner_inner_idle.pxo` | `assets/environments/ch01/ch01_env_wall_partition_low_corner_inner_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 24)` | `YSort_Walls (z_index = 5)` | `11 / 32` | **`exported`** |
| **247** | `ch01.env.wall_partition_low_corner_outer_idle` | Environments | `ch01_env_wall_partition_low_corner_outer_idle.pxo` | `assets/environments/ch01/ch01_env_wall_partition_low_corner_outer_idle.png` | `32 × 32 px` | 1f (`static`) | `(16, 24)` | `YSort_Walls (z_index = 5)` | `12 / 32` | **`exported`** |
| **248** | `ch01.env.wall_subterranean_n_endcap_low_idle` | Environments | `ch01_env_wall_subterranean_n_endcap_low_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_n_endcap_low_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `10 / 32` | **`exported`** |
| **249** | `ch01.env.wall_subterranean_w_endcap_low_idle` | Environments | `ch01_env_wall_subterranean_w_endcap_low_idle.pxo` | `assets/environments/ch01/ch01_env_wall_subterranean_w_endcap_low_idle.png` | `32 × 64 px` | 1f (`static`) | `(16, 56)` | `YSort_Walls (z_index = 5)` | `10 / 32` | **`exported`** |

### 10.4 `TLF-068` Mockups & Greyscale Proofs (`design/art/mockups/`)

| # | Mockup | File | Canvas Size | QA State |
|---|---|---|---|---|
| M14 | L-shaped Subterranean Station room (`12 × 10` with `4 × 4` SE cut, `ADR-023` R2/R2b) built from the 12-piece shape kit + Elias occlusion proof + floor L-cut seam check inset | `design/art/mockups/ch01_tlf068_l_room_shape_kit_mockup.png` | `640 × 360 px` | **`concept`** |
| M15 | Deterministic endpoint-aware §10.2 join proof (`n_turn_inner` + 5-tile odd `N` run, `w_turn_inner` + 3-tile short/odd `W` run, residual odd runs `L = 3` and `L = 4`, and `Rule R2b` low endcap termination at `1×` native + `×2` zoom) | `design/art/mockups/ch01_tlf068_endpoint_join_proof.png` | `640 × 360 px` | **`concept`** |

The colour + luminance-greyscale proof sheet (`design/art/mockups/ch01_tlf068_shape_kit_greyscale_proof.png` at `1320 × 1040 px` — containing both the `640 × 360` L-room mockup in colour + luminance greyscale and all 12 shape kit pieces at `×2` and `1×` native with pivot markers; luminance `.convert("L")` sections are not palette-table-checked) is generated deterministically by `tools/art/gen/tlf068_shape_kit.py` and verified by `verify_regen.py`.
