class_name TlfPalette
extends RefCounted

## The Chapter 1 master palette TLF-CH01-32 (ART_BIBLE §3.1,
## `assets/source/ch01/ch01_palette_elysium09.gpl`) and its six material ramps, for the lighting pass
## (ADR-026). A test keeps this table equal to the .gpl file.

const COLORS: Array[Color] = [
	Color8(10, 13, 20), Color8(20, 26, 38), Color8(31, 40, 56), Color8(45, 57, 79),
	Color8(63, 79, 107), Color8(88, 108, 143), Color8(25, 35, 46), Color8(38, 53, 69),
	Color8(54, 75, 94), Color8(75, 102, 125), Color8(104, 136, 163), Color8(27, 30, 36),
	Color8(46, 51, 61), Color8(70, 78, 92), Color8(103, 115, 133), Color8(148, 162, 184),
	Color8(35, 27, 24), Color8(59, 45, 38), Color8(89, 68, 56), Color8(125, 97, 79),
	Color8(184, 138, 108), Color8(224, 180, 148), Color8(74, 28, 20), Color8(140, 45, 25),
	Color8(204, 78, 30), Color8(235, 138, 40), Color8(255, 209, 102), Color8(22, 66, 91),
	Color8(40, 122, 158), Color8(76, 224, 210), Color8(158, 123, 255), Color8(237, 244, 250),
]

## First index of each ramp: 1 void/terrazzo, 2 ceramic wall, 3 steel/iron, 4 Elias,
## 5 amber/23:59 glow, 6 temporal VFX/UI.
const RAMP_STARTS: Array[int] = [0, 6, 11, 16, 22, 27]

const SIZE := 32


## The first index of the ramp `index` belongs to.
static func ramp_start(index: int) -> int:
	var start := 0
	for s in RAMP_STARTS:
		if index >= s:
			start = s
	return start


## Index of the palette colour nearest to `c` (squared RGB distance); exact for palette colours.
static func nearest_index(c: Color) -> int:
	var best := 0
	var best_d := INF
	for i in SIZE:
		var p := COLORS[i]
		var d := (c.r - p.r) * (c.r - p.r) + (c.g - p.g) * (c.g - p.g) + (c.b - p.b) * (c.b - p.b)
		if d < best_d:
			best_d = d
			best = i
	return best
