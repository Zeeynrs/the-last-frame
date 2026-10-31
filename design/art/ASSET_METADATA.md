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

**Task:** TLF-039 · **Author:** design-art agent (Claude Code, Sonnet 5.5, standing in for Argon, RISK-019) · **Palette:** `TLF-CH01-32`, `0` off-palette, `0` semi-transparent pixels · **Authoring:** every pixel is placed by a deterministic script using palette indices only, which writes layered `.pxo` files; every `.pxo` passes `Pixelorama.exe --headless --quit -- --size` and `--export --spritesheet`, and each committed PNG is the byte-identical re-export (raw logs in `design/art/TLF-039_VERIFICATION.txt`). **No AI-generated or third-party images.** Elias v2 replaces the batch-1 sheet in place (section 2.1). Rows 27-38 are Tier 2 hero set-pieces (TLF-039); rows 39-52 are TLF-042 (route board, security gate, bridge, transit car, dispatch terminal, pocket watch, lever badges, PA horn), which completes every ROOM_GRAPH §7.3 piece.

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
| **36** | `ch01.prop.surge_capacitor_frozen` | Prop (Large Hero Mechanism) | `ch01_prop_surge_capacitor_frozen.pxo` | `assets/props/ch01/ch01_prop_surge_capacitor_frozen.png` | `64 × 64 px` | `1f` (`static`) | `(32, 56)` | `YSort_Actors` (`z_index = 10`) | `8 / 32` | **`exported`** |
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

### `ch01.prop.surge_capacitor_frozen`
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

Rows 12-52 and the mockups/placement sheet are produced by `tools/art/gen/` (see its `README.md`). `python tools/art/gen/verify_regen.py` regenerates every generated `.pxo` (byte for byte), PNG (pixel for pixel; byte for byte against a fresh Pixelorama re-export with `--pixelorama`), mockup and the placement sheet, and compares with the committed files. Batch-1 files (rows 1-11, drawn by Argon in Pixelorama, plus the `.pxo` of the palette and target sheet) have no generator and are reported as *not covered*. Generated `.pxo` files carry the author `TLF design-art agent (Claude Code, Sonnet 5.5)`.
