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
| **2** | `ch01.char.elias.base_sheet` | Character | `ch01_char_elias_base_sheet.pxo` | `assets/characters/ch01/ch01_char_elias_base_sheet.png` | `2560 × 48 px`<br>(`80 × 32×48`) | `80f` (`16` tags: `8 FPS` idle, `10 FPS` walk) | `(16, 44)` per `32×48` frame | `YSort_Actors` (`z_index = 10`) | `11 / 32` | **`exported`** |
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
- **Palette ID & Color Constraints:** `TLF-CH01-32` (`11` colors used: indices `00, 01, 02, 16, 17, 18, 19, 20, 21, 25, 26`; `0` off-palette colors; `0` semi-transparent pixels)
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
  - East doorway frame (`ch01_env_archway_frame_e_idle.png`) at `ch01.arrival_platform:door_exit_east` (`(13, 5)` / `(448, 160)`)
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
