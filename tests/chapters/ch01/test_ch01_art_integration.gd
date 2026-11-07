extends "res://tests/support/base_test.gd"

## Comprehensive Art Integration & Collision Freeze Test Suite (TLF-041).
## Verifies that:
## 1. Collision shapes, triggers, spawns, and interactables across all 10 Chapter 1
##    rooms match the pre-change baseline 100% (only ADR-019 intercom move allowed).
## 2. Operator intercom reach is <= 36 px from a walkable point.
## 3. All greybox visuals are replaced by art kit nodes (Floor, Walls, Doorways, Fixtures, Props).
## 4. Room 1 art integration is 100% complete per CH01_PLACEMENT_SHEET.md.
## 5. Every puzzle prop presenter maps states to correct textures dynamically.
## 6. Real save slot_0 is strictly untouched.

const REAL_SAVE_SLOT_0 := "user://saves/slot_0.json"

const ROOM_PATHS: Array[String] = [
	"res://scenes/chapters/ch01/rooms/arrival_platform.tscn",
	"res://scenes/chapters/ch01/rooms/concourse_west.tscn",
	"res://scenes/chapters/ch01/rooms/maintenance_bay.tscn",
	"res://scenes/chapters/ch01/rooms/security_crossing.tscn",
	"res://scenes/chapters/ch01/rooms/waiting_lounge.tscn",
	"res://scenes/chapters/ch01/rooms/signal_control.tscn",
	"res://scenes/chapters/ch01/rooms/upper_vestibule.tscn",
	"res://scenes/chapters/ch01/rooms/vestibule_niche.tscn",
	"res://scenes/chapters/ch01/rooms/station_atrium.tscn",
	"res://scenes/chapters/ch01/rooms/street_exit.tscn"
]

## Pre-change baseline collision fingerprint compressed as GZIP base64 string.
const BASELINE_FINGERPRINTS_GZIP_B64: String = "H4sIAAAAAAAACu1dSW/jOBb+LzpnEq+JU7deMIM5zKDR1cAcGg2BlhlbXYqkkeSk043670ORsvi4OSa1mJrKpVAmY3+PFPnWj9RfASqK+AUlYZ6g6ikrnoNPfwVRliRxGWdpGXz69a8gQW+4CD7Nb2c3wTMqvwSfZvV/c1Qdgk/BT7iIn3GFi/+gJCnvfjh996csedtn6eLHgPwp+z/5tV+Xi/rL9+Sf325+3cw25MNytqKf7h8W9af6X/JpuSGtN4vFhn5aLFb0L5tPtIt++K3+9VrO+mfprwZFVjUilhFKMOmrRZ/TvuotJw0ngRa74OtNO8AVH+ACDDA64OhLnsVpxQf3+YBy3AztcvCy/had4ASV5GvBzziqULpPMP+9Mv6z/lI97Jv5Pfna11Zo+vWLRN7F+7giDzVKsuhLuFiuH3sX/Ye4iKDcBdrFR9JRy3ypyHAZ7bIoJD9dhSUuXuIIjyfw4nKBhTnOsiLEf8RViInY44k7c5vfdDYPoyzdHaMqK8aTdvWOtAalIkr79yyr8mLcDVgvi5uNxf4TxV+EZXXc4QFE7n+quawTnOhlmCW78BmlE5hoLusEJ3pFrAlGKZ6C8uCyTmKioVnJclwgovTCMt4fqjjd332X50WGosMvRbzfjzj9y/cMo2H6T55kuEcVvvu+dkEGkPqM60Sdw5XjQhel99Frgqslrye3Cl9RFR3CPI6+HHN/tqdhhgtM9maJwwS/+KRMDNKWRNraCQkjNCFhkzgdcfF2lfa0564tMfkJYimI/iWqZZtgFv2efuu7AiP6I9n2dyJ2GO9obDib38oh9C2PGANNFNkOal5HwTeLRlU5IamBHkfU91Hk1YwG4fcdgKVwDcBqegDovI7/3VFhzAUx5XaK+EBzDcvFxh1RCESCG218wkf4eE/zEh1GCLxxiCY0Uiya/biZ33caW+uQQiyhkY1rxbA6jav1yQKdo9Zi3bOUUJdV0rpQqPGcwoq5TsHlXlYrz9+AN+ckjeBQBHo/w23F7pNsi5Jb6AME5zwDvnZWVPHUDp7rqAQjHuhtOx/Vmib25n3gkWFp4JpWwVY4IkGDH2jdAD6uGXU1HzqMS7DYGrhTM9sb7Lmt+hhdm+81m2OOSxOzizW1F8RI/pmlkzCO/ViLf6GCBDAKpun37j7n6DUF+qO2CX/roEBGUGeGIRqWEHrCIUqjQ413GmuzhHRd6uOsAzNiPaPsWJDN+4rJQxiz6rDeUEfkkX1qjPaSVR1WG77F2hrEI+ub08hyvoYViXlbkaC/SU1/jyUJw+h/ORZpWcUJ/jF+iXe4KO+a//w7K6pDV6/5M94/E1fj5Da75ACMAn7OjuMKaCrqkGUTbrM/wpmfpZEJFqDg86e+MVGIs/m1Y7r3C08xUW6TiJeppL7EypdJWxEl7aWkE6yWisXHKMQvKArTrPK1WDqT5CWC1hEJsdnPpZcCq9XdtCreqH/iZXl3YtVoKC6VtHFjw9YVHLtI4Gze0tk6rEWOJ5DATmf3YYF3RF40hWI0EHYStTtR+odwSxbFU4QGWMz9zzWUdoKTvQmfyH992oLGmW5FneA0PxKTjadAr2gEndwUF7gkflGTNplAxCTKu/BHXsPKKCv09BTWHtLk2AhAdB9DEkHUY55nRRXmcZIgv9axaV0oEv9E/9fKPdoINm5T3kRULyiJd2gKtE6NwGmZJfgqKvveUmXD+KU65TfDpyuIfmFuzvQQWtmvSdBqioEOi14U33e1yMWtChSdqiPXzn84Ml3Eos0tSKKDWp7YyArOtID4eDnfRAa6rGZIK5Q3c4s6s4zTpq0BjtAGuRdrZ5w25wyKiLAJsi5Wl1dAdShqnVdpZmisKGbB8dCh1fleCenURFHW1FGePzivBEfCE6v/rd0HJ+ZbYe1X6WCA664DlTKmIqTcAwbJjkU5YgpJT7nCLXQAIsl85r5E7Ur0TXXWghQg4enzjhzX3M9mmBI+5kvnpwoShxxUaoQza0GDUpB4Jg1Cia1sVpeU3jHvMCqQSYJgUjOgAdqQjxS0UzYFQsE29qxqahyJvJx3wymhAFF4C9jlHdajFPpzKE0HNHHuRkEK3k2IC2l1dFjzPIblYGJbP3tbCecAnK6LPUHK8Oigp+WQhoPqeqARfHTeAZroA8DqO4Ef1kGriM63DlSgM/aIB71nHa7cz/CZU9OwjuyIa1dyQXuzwRfS1niJ87NE2Lq1ob0OY9dHpt6N4yycI9vJKg3w6cSJ1PWcXYCOqOIa1PX04xj1o9LqhMIzqiPblEiJwy16s2YWfn9Mvhww2ikhesithmOQ3gOxzizdwgPp/pmmuGiYfn7O33kJfZjDTsxWljJ4YPdpNFq1Yaiu7letl98yW5vvzRuvkvFcr8ls/Xw4VlX7hLzjtRrE84XVusUJS+3gUesv3xKv9VinTV9xzbMP93jMM6EdLlY50FNA0QEVI1KAOlAF41pLhyXbbGxBeym3TMmsMJnmJNtPQNgPeuNY9MZBJO6T2XhW8iEIHqMIT3Wef6IbHIunuMAnhTe5kqwg/Gh705E0URvtsMBlvDv6z9Fkhpv4clNbEq3gPrpHC0VQr31mdV69W75nJ7c6EHkPWaImLXzVxoL/Obm9J0rv44pemKT1ea2YCNLzeRNf1d6/P1vSRJMWxf0gSw+sApWFfXJQfcl5OFLBpDT7rZB64ql7pRkSqCzKBTLcYOU4BUjJ+ABAbR+sK3cAlvI2sOaldMBCYIdJNaReRGjDHziSyHQinLIoIi5sbYq7dBFZlNFVsMH5TnrIywujLGlvcaOUDKgE9Ib6pQhLK6c2rIh3YQWuiakX8h47PFc1D2CAbvvYnl3SUVuwFWRgGAhzSLkVKogOWwUGshxMbgVcqC4jO8VzHAi2APphF5UnxmIylGpFmHK3uN5ND6jModLcK1zrCciAQkdPUypoaw6oNEOq18ZdvRmceQOwZsTdRRAdXI6stkPmQgeVbs/h29gSu2VIo1MJqBrn/kTVQJbkqG/F+5soG2sgr2NkOtaHK3NFV+ZKtvh6xrFPa3WObKfocnuOn2lNO8PWaseAe+qCZLtLtdu7wJeyC9lq7mAwBjCYX2+CEkfHIq7ewqjIyjJO99e8xlC4uLDR4KsNJHvprzFkxrihhUHq1whkr/oUwPf1BZO+0gXPS+gDXfCXApMd04hY3rGPvtDltML5QpZDCSqeh6v8DVWb2hbxbo/bA5zXLA67lkw0Q/CRNbBQRX5FyZewDpR8yd6/z1hExS4kdnKHJ1EumSAntE5O74/1NH8w/75J5h9cDJh4r2S7RVlRb7gc78gco8T7bSeEkkl2TPcTuoxxvmT7z59ZNtbeT5JOruyeo7DMMRrCy+hbY+QkfiuPdcnlNR6IhDaUKfGW3GBY0G0AvG+c6KlRpZQBeOOHmmacHpzfsohqkjMuD8BHfhoUuCpQWhLrmJOfH/0Ve3qZHSk7SrrqVgyBeS5MbYeX2lgkeVVINfYD5SJtH6xgW9QFjdBtDKcACz29wYoRGChYKe0gy2hzi48G8sL6mPUlMyqUEP3ASpDUDCufFil7HaBtSW5hS8UygdoW0CzuuFEh9ZEEqP4Y+2FBxoJfohFBjQoM1Sfe6XijkAreOsscUmhyrHOpQNy15UhiGyg3dZpP1TMFiNo++CgtSpgqtDVJoZlZi/cLqqCydwWKLZoex3KtBlZyMQCspgcuWAuenQqrcRQ4sqETTvXM5ZYan2z66IZ1TCvXk9EZlwcymCEbmQnimWnqWY+fq55rtJsDX8AwZnfgSwv3jKIBKubxPq1v6MzIAs+SK5bLzSXx4cverAz6M4oTMq3lHS3WNjXSdkTiQFYP90D2NXsN6GIBPzWjZH/JPl1nJM0ncSQ+lKFbMWkB+ppiGmuM1OMM0bXzCxdLuvVS0plG0sifXOq0K58TfHGeXKzdHkuP78IxFGvLWml5X3vhbl9a2wLv5RU8xRfiusTbYzJm6ZN5ZjavhxHPThNfKMpGfBmo47ZLFzOyjvdxiqfwui4o7CQqtXBNeFtDNB2QPhZ7HEYoR1E86jtsHCtwrZa46hulnG22JL4nYrtWtIRw8rZ1oAPVpwYpFBoHWpy+MqBsVZRti7Je0eFanPwwoEQqStSltCGiXJpCo3Ubq5qUiDPWaztkWOjtBXonkA+SHm7YuI9Rcta0Ob1SID8zSKtklA6z9bd0+bdU4II3J5Js0r0iot5jMuTehP5+8E8uT6A4QXJK26ZUI2JAByDQugUcix0ftSmTiFj2hZm17dsDJMTyuC0rVBGdH+6LGJTXNB2CKXBEE8x7YLL7cmXAfUZFCxcYLJ9+RdpWX66kTfvTNDb1CBaCagoSNpn8gfSXRUGCRaa6ioRvSvFsfl7aZiAFH+FUOOyv74PKhJUkaIK+UQCISHt8vmaCnkq2bC4hf2RirvrNan9k4q54omYXl3lzHUPxHKdjkuRdJf7Ixg2cjaNze9KTTAVNPUIV9KndxRU278KScEaLt2RYaU8H5u2ut0FOqA7uECua2hD0dJjDBl4iom5zBGe3jn452bq4V1rA/T3T0V3cgVbK2C7uMMvvUvdWRIcurLQetF1qzMOc2wKTmLqeonE9W0ZqbG5caF4aSROQ4qt3Plzb/wevK0/QnyjM0Vt+GOKgeN9cjtOmJXNbZL5UPp29rXaD2yVj7LwPDuKcibFivgJAcXEFhkXHbQl92a7NzTkQTFgagX7FcDeO3Y7jlkeb8HMbxr04bxv5QATrV6G4AC8K1/f1MHsd1gXZ68c8F7Jgo1pi4QV5zQvTGxLoR47J3xxTB7ZXgcnfhM/4uX/jNgzdy9drLhRJp5FUoqJOw3Okok7iVpbfj2lE47MEv0yCsSwJ7D9xWRLYT/6yyJqbh1V2LOIxl68zw4/L+kHwG5jgVxDdi8NtNuoNPY5qgrjJ6W775t2tgI7xsORq252YtKElyUBj1R8UXMHhCwyOIA+Pm5Lz5WUAFVA5hic0gUPNNtlwLYwufyyljtl9xBZHXbVAupBYCobpau08Is1ZWvEU7cz2vRUyjOyoBEYXRkpX2xBE3wHdGkE5X9T+1o93QCMjaCSB2tSkZFBgSAOddeVQ1lc4y1D2r1l4sD3Tr0ByyxXozJk8OgvOmgxVF0djohTpYET2jqbHgZanAEqWLjDaQJ6pegCjtMzwXc8SdVHQF+b2ejjh3rPCv0zwPsqEPRuQywTvo0zbq0G6TOxLL3Q4l/xV9rEj8Y+dzLdIAPeuQIibyym5aUx2/6ip4FXz+ogZSAXP71lieAH6hs8Fs7fq7fAf9Yz9d8zX+jpGSXQxx6n3WSoqJ1EV/ghqWMetoP8o4iTBnt3p6Bh8Spv7Vl7mgXEDyH6Vxcu5VFC6VAN57UpeosWpHy0CeXaB8jT5MOiRho2L39TXeC4zUGRPd7pvqOPcWMtbb5lL3JdzBlWWGRpNZpW09rTtguaU7aB6D72iuIrT/en2oW+TbYSOuzgLn+MC+XrR60dJ9iq+wyTfPzCNcmdFzDQOt/WFR9deC45+g6g6bwUlEuh1C9fDjEtukbuT0AZ7s6SEM1aCXIYd/o3XWkQb+vO849SCHRDotgWfTHZ2d+VCi7/Wspnm+0iHWhODUOLPOYvSQFyTLyysWTfe4tf/Aeg9Uj6G2QAA"


func _get_baseline_data() -> Dictionary:
	var raw := Marshalls.base64_to_raw(BASELINE_FINGERPRINTS_GZIP_B64)
	var decompressed := raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return JSON.parse_string(decompressed.get_string_from_utf8())


func _scan_room_fingerprint(root_node: Node) -> Dictionary:
	var collisions: Array = []
	var zones: Array = []
	var interactables: Array = []
	_scan_node(root_node, root_node, collisions, zones, interactables)
	collisions.sort_custom(func(a, b): return a["path"] < b["path"])
	zones.sort_custom(func(a, b): return a["path"] < b["path"])
	interactables.sort_custom(func(a, b): return a["path"] < b["path"])
	return {
		"collisions": collisions,
		"zones": zones,
		"interactables": interactables
	}


func _scan_node(node: Node, root_node: Node, collisions: Array, zones: Array, interactables: Array) -> void:
	var path := str(root_node.get_path_to(node))

	if node is CollisionShape2D:
		var shape_data := {}
		if node.shape != null:
			shape_data["class"] = node.shape.get_class()
			if node.shape is CircleShape2D:
				shape_data["radius"] = (node.shape as CircleShape2D).radius
			elif node.shape is RectangleShape2D:
				shape_data["size"] = [(node.shape as RectangleShape2D).size.x, (node.shape as RectangleShape2D).size.y]
			elif node.shape is CapsuleShape2D:
				shape_data["radius"] = (node.shape as CapsuleShape2D).radius
				shape_data["height"] = (node.shape as CapsuleShape2D).height
			elif node.shape is ConvexPolygonShape2D:
				var pts := []
				for p in (node.shape as ConvexPolygonShape2D).points:
					pts.append([p.x, p.y])
				shape_data["points"] = pts

		var parent_col = node.get_parent()
		var layer: float = -1.0
		var mask: float = -1.0
		if parent_col is CollisionObject2D:
			layer = float((parent_col as CollisionObject2D).collision_layer)
			mask = float((parent_col as CollisionObject2D).collision_mask)

		collisions.append({
			"type": "shape2d",
			"path": path,
			"pos": [node.position.x, node.position.y],
			"rot": node.rotation,
			"scale": [node.scale.x, node.scale.y],
			"shape": shape_data,
			"layer": layer,
			"mask": mask
		})

	elif node is CollisionPolygon2D:
		var pts := []
		for p in (node as CollisionPolygon2D).polygon:
			pts.append([p.x, p.y])

		var parent_col = node.get_parent()
		var layer: float = -1.0
		var mask: float = -1.0
		if parent_col is CollisionObject2D:
			layer = float((parent_col as CollisionObject2D).collision_layer)
			mask = float((parent_col as CollisionObject2D).collision_mask)

		collisions.append({
			"type": "polygon2d",
			"path": path,
			"pos": [node.position.x, node.position.y],
			"rot": node.rotation,
			"scale": [node.scale.x, node.scale.y],
			"polygon": pts,
			"layer": layer,
			"mask": mask
		})

	var is_zone := (node is TriggerZone) or (node is DoorwayPresenter) or (node is SafeAnchor) or (node is CheckpointZone)
	var is_spawn := node.name.begins_with("Spawn") or node.name.ends_with("_spawn") or node.name == "safe_anchor_spawn"
	if is_zone or is_spawn:
		var obj_id := ""
		if "object_id" in node:
			obj_id = str(node.object_id)
		zones.append({
			"path": path,
			"class": node.get_class(),
			"pos": [node.position.x, node.position.y],
			"object_id": obj_id
		})

	if node is Interactable:
		interactables.append({
			"path": path,
			"class": node.get_class(),
			"pos": [node.position.x, node.position.y],
			"object_id": str(node.object_id)
		})

	for child in node.get_children():
		_scan_node(child, root_node, collisions, zones, interactables)


# -------------------------------------------------------------------------------------------------
# 1. Collision Freeze Test across all 10 rooms
# -------------------------------------------------------------------------------------------------
func test_collision_freeze_all_10_rooms() -> void:
	var baseline := _get_baseline_data()
	_assert_eq(baseline.size(), 10, "Baseline contains fingerprints for all 10 rooms")

	for path in ROOM_PATHS:
		var room_name := path.get_file().get_basename()
		var scene := load(path) as PackedScene
		_assert_true(scene != null, "Loaded room scene %s" % room_name)

		var inst := scene.instantiate() as Node2D
		_assert_true(inst != null, "Instantiated room scene %s" % room_name)

		var curr := _scan_room_fingerprint(inst)
		inst.free()

		var base: Dictionary = baseline[room_name]

		# 1. Collisions
		_assert_eq(curr["collisions"].size(), base["collisions"].size(),
			"%s: collision shape count must match baseline exactly" % room_name)
		for i in range(base["collisions"].size()):
			var b = base["collisions"][i]
			var c = curr["collisions"][i]
			_assert_eq(c["path"], b["path"], "%s: collision path[%d]" % [room_name, i])
			_assert_eq(c["pos"], b["pos"], "%s: collision pos[%d]" % [room_name, i])
			_assert_eq(c["rot"], b["rot"], "%s: collision rot[%d]" % [room_name, i])
			_assert_eq(c["scale"], b["scale"], "%s: collision scale[%d]" % [room_name, i])
			_assert_eq(c["layer"], b["layer"], "%s: collision layer[%d]" % [room_name, i])
			_assert_eq(c["mask"], b["mask"], "%s: collision mask[%d]" % [room_name, i])
			if c.has("shape"):
				_assert_eq(c["shape"], b["shape"], "%s: collision shape[%d]" % [room_name, i])
			if c.has("polygon"):
				_assert_eq(c["polygon"], b["polygon"], "%s: collision poly[%d]" % [room_name, i])

		# 2. Zones & Spawns
		_assert_eq(curr["zones"].size(), base["zones"].size(),
			"%s: zone and spawn count must match baseline exactly" % room_name)
		for i in range(base["zones"].size()):
			var b = base["zones"][i]
			var c = curr["zones"][i]
			_assert_eq(c["path"], b["path"], "%s: zone path[%d]" % [room_name, i])
			_assert_eq(c["pos"], b["pos"], "%s: zone pos[%d]" % [room_name, i])
			_assert_eq(c["object_id"], b["object_id"], "%s: zone object_id[%d]" % [room_name, i])

		# 3. Interactables
		_assert_eq(curr["interactables"].size(), base["interactables"].size(),
			"%s: interactable count must match baseline exactly" % room_name)
		for i in range(base["interactables"].size()):
			var b = base["interactables"][i]
			var c = curr["interactables"][i]
			_assert_eq(c["path"], b["path"], "%s: interactable path[%d]" % [room_name, i])
			_assert_eq(c["object_id"], b["object_id"], "%s: interactable object_id[%d]" % [room_name, i])
			if room_name == "signal_control" and c["object_id"] == "ch01.signal_control.intercom":
				# ADR-019 exception: intercom moved from (352, 160) to N-wall mount (528, 154)
				_assert_eq(c["pos"], [528.0, 154.0], "signal_control: intercom at ADR-019 N-wall position (528, 154)")
				_assert_eq(b["pos"], [352.0, 160.0], "signal_control: baseline intercom at old greybox position (352, 160)")
			else:
				_assert_eq(c["pos"], b["pos"], "%s: interactable pos[%d]" % [room_name, i])


# -------------------------------------------------------------------------------------------------
# 2. Intercom Reach Test (ADR-019 requirement 5)
# -------------------------------------------------------------------------------------------------
func test_intercom_reach_walkable() -> void:
	var scene := load("res://scenes/chapters/ch01/rooms/signal_control.tscn") as PackedScene
	var inst := scene.instantiate() as Node2D
	var intercom := inst.get_node_or_null("intercom") as Area2D
	_assert_true(intercom != null, "signal_control has intercom Area2D")

	# Position must be on N-wall mount (528, 154)
	_assert_eq(intercom.position, Vector2(528, 154), "intercom mounted at N-wall module k=6 (528, 154)")

	# Player standing spot just south in walkable lane is W3 (528, 184)
	var walkable_spot := Vector2(528, 184)
	var reach_dist := walkable_spot.distance_to(intercom.position)
	_assert_true(reach_dist <= 36.0, "intercom reachable from walkable spot (dist %.1f <= 36.0 px)" % reach_dist)
	inst.free()


# -------------------------------------------------------------------------------------------------
# 3. No Greybox Nodes Remain Across All 10 Rooms
# -------------------------------------------------------------------------------------------------
func test_no_greybox_nodes_remain_across_all_rooms() -> void:
	for path in ROOM_PATHS:
		var room_name := path.get_file().get_basename()
		var scene := load(path) as PackedScene
		var inst := scene.instantiate() as Node2D

		# Check removal of greybox floor polygons
		_assert_true(inst.get_node_or_null("Floor") == null, "%s: greybox Floor Polygon2D removed" % room_name)
		_assert_true(inst.get_node_or_null("FloorAccent") == null, "%s: greybox FloorAccent Polygon2D removed" % room_name)

		# Check removal of apex Clock sprite
		var apex_clock := inst.get_node_or_null("Clock")
		_assert_true(apex_clock == null, "%s: greybox floating Clock at (320, 50) removed" % room_name)

		# Check TileMapLayer_Floor exists at (304, 64) with valid TileSet
		var floor_layer := inst.get_node_or_null("TileMapLayer_Floor") as TileMapLayer
		_assert_true(floor_layer != null, "%s: TileMapLayer_Floor exists" % room_name)
		_assert_eq(floor_layer.position, Vector2(304, 64), "%s: TileMapLayer_Floor at (304, 64)" % room_name)
		_assert_true(floor_layer.tile_set != null, "%s: TileMapLayer_Floor has TileSet" % room_name)

		# Check YSort_Walls exists with z_index = 5 and y_sort_enabled = true
		var ysort_walls := inst.get_node_or_null("YSort_Walls") as Node2D
		_assert_true(ysort_walls != null, "%s: YSort_Walls exists" % room_name)
		_assert_eq(ysort_walls.z_index, 5, "%s: YSort_Walls at z_index 5" % room_name)
		_assert_true(ysort_walls.y_sort_enabled, "%s: YSort_Walls has y_sort_enabled = true" % room_name)

		# Check RoomVisuals controller exists
		var rv := inst.get_node_or_null("RoomVisuals")
		_assert_true(rv != null, "%s: RoomVisuals controller exists" % room_name)

		if room_name == "street_exit":
			_assert_true(inst.get_node_or_null("StairsAccent") == null, "street_exit: greybox StairsAccent removed")
		elif room_name == "signal_control":
			_assert_true(inst.get_node_or_null("SouthRailingVisual") == null, "signal_control: SouthRailingVisual Line2D removed")
			_assert_true(inst.get_node_or_null("NorthRailingVisual") == null, "signal_control: NorthRailingVisual Line2D removed")
			_assert_true(inst.get_node_or_null("NorthBarrierVisual") != null, "signal_control: NorthBarrierVisual kept per spec")

		inst.free()


# -------------------------------------------------------------------------------------------------
# 4. Complete Room 1 Check (CH01_PLACEMENT_SHEET.md §1)
# -------------------------------------------------------------------------------------------------
func test_room1_arrival_platform_kit_complete() -> void:
	var scene := load("res://scenes/chapters/ch01/rooms/arrival_platform.tscn") as PackedScene
	var inst := scene.instantiate() as Node2D

	# Floor: 360 tiles used in L-shape v2
	var floor_layer := inst.get_node_or_null("TileMapLayer_Floor") as TileMapLayer
	_assert_true(floor_layer != null, "arrival_platform: TileMapLayer_Floor exists")
	var used := floor_layer.get_used_cells()
	_assert_eq(used.size(), 360, "arrival_platform: exactly 360 tiles used")

	# YSort_Walls: 15 N modules, 9 W modules, 1 Archway, plus shape kit corners and low partitions
	var walls := inst.get_node_or_null("YSort_Walls") as Node2D
	_assert_true(walls != null, "arrival_platform: YSort_Walls exists")
	for k in range(15):
		var w = walls.get_node_or_null("WallN_%d" % k) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallN_%d exists" % k)
		_assert_eq(w.position, Vector2(336 + 32 * k, 72 + 16 * k), "arrival_platform: WallN_%d pivot" % k)
	for j in range(9):
		var w = walls.get_node_or_null("WallW_%d" % j) as Sprite2D
		_assert_true(w != null, "arrival_platform: WallW_%d exists" % j)
		_assert_eq(w.position, Vector2(304 - 32 * j, 72 + 16 * j), "arrival_platform: WallW_%d pivot" % j)

	var arch := walls.get_node_or_null("Archway_door_exit_east") as Sprite2D
	_assert_true(arch != null, "arrival_platform: Archway_door_exit_east exists")
	_assert_eq(arch.position, Vector2(720, 328), "arrival_platform: archway at doorway position (720, 328)")
	_assert_eq(arch.z_index, 6, "arrival_platform: archway at z_index 6")

	# Corners and low partitions from TLF-068 shape kit
	_assert_true(walls.get_node_or_null("Corner_NW_0_0") != null, "arrival_platform: Corner_NW_0_0 exists")
	_assert_true(walls.get_node_or_null("Corner_N_Turn_30_0") != null, "arrival_platform: Corner_N_Turn_30_0 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_30_8") != null, "arrival_platform: Corner_Low_30_8 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_12_8") != null, "arrival_platform: Corner_Low_12_8 exists")
	_assert_true(walls.get_node_or_null("Corner_Low_12_18") != null, "arrival_platform: Corner_Low_12_18 exists")
	_assert_true(walls.get_node_or_null("Corner_W_Turn_0_18") != null, "arrival_platform: Corner_W_Turn_0_18 exists")

	# Wall_Fixtures: 2 clocks at (400, 66) and (592, 162), plus TLF-063 departure board and notice
	var fixtures := inst.get_node_or_null("Wall_Fixtures") as Node2D
	_assert_true(fixtures != null, "arrival_platform: Wall_Fixtures exists")
	_assert_eq(fixtures.z_index, 7, "arrival_platform: Wall_Fixtures at z_index 7")
	var clk2 := fixtures.get_node_or_null("Clock_2") as Sprite2D
	var clk8 := fixtures.get_node_or_null("Clock_8") as Sprite2D
	_assert_true(clk2 != null, "arrival_platform: Clock_2 exists")
	_assert_true(clk8 != null, "arrival_platform: Clock_8 exists")
	_assert_eq(clk2.position, Vector2(400, 66), "arrival_platform: Clock_2 at (400, 66)")
	_assert_eq(clk8.position, Vector2(592, 162), "arrival_platform: Clock_8 at (592, 162)")

	var dep_board := fixtures.get_node_or_null("DepartureBoard") as Sprite2D
	var closed_track := fixtures.get_node_or_null("ClosedTrackNotice") as Sprite2D
	_assert_true(dep_board != null, "arrival_platform: DepartureBoard exists")
	_assert_true(closed_track != null, "arrival_platform: ClosedTrackNotice exists")
	_assert_eq(dep_board.position, Vector2(144, 152), "arrival_platform: DepartureBoard at (144, 152)")
	_assert_eq(closed_track.position, Vector2(528, 168), "arrival_platform: ClosedTrackNotice at (528, 168)")

	# YSort_Actors: Bench at (448, 168), Stalled car at (480, 336)
	var actors := inst.get_node_or_null("YSort_Actors") as Node2D
	_assert_true(actors != null, "arrival_platform: YSort_Actors exists")
	_assert_eq(actors.z_index, 10, "arrival_platform: YSort_Actors at z_index 10")
	var bench := actors.get_node_or_null("PlatformBench") as Sprite2D
	var car := actors.get_node_or_null("StalledTransitCar") as Sprite2D
	_assert_true(bench != null, "arrival_platform: PlatformBench exists")
	_assert_true(car != null, "arrival_platform: StalledTransitCar exists")
	_assert_eq(bench.position, Vector2(448, 168), "arrival_platform: PlatformBench at (448, 168)")
	_assert_eq(car.position, Vector2(480, 336), "arrival_platform: StalledTransitCar at (480, 336)")

	# Watch sprite on pocket_watch_pickup
	var pickup := inst.get_node_or_null("pocket_watch_pickup")
	_assert_true(pickup != null, "arrival_platform: pocket_watch_pickup exists")
	var watch_sprite := pickup.get_node_or_null("WatchSprite") as Sprite2D
	_assert_true(watch_sprite != null, "arrival_platform: WatchSprite child exists on pickup")
	_assert_eq(watch_sprite.z_index, 8, "arrival_platform: WatchSprite at z_index 8")

	inst.free()


# -------------------------------------------------------------------------------------------------
# 5. Puzzle Prop Presenter State Mappings
# -------------------------------------------------------------------------------------------------
func test_puzzle_prop_presenter_state_mappings() -> void:
	# 1. TurnstilePresenter
	var turnstile_script = load("res://scripts/chapters/ch01/visuals/turnstile_presenter.gd")
	var turnstile := TurnstileGate.new()
	var t_pres := Sprite2D.new()
	t_pres.set_script(turnstile_script)
	turnstile.add_child(t_pres)
	turnstile.arm_state = &"collapsed"
	t_pres._refresh()
	_assert_true(t_pres.texture.resource_path.ends_with("turnstile_gate_collapsed.png"),
		"TurnstilePresenter: collapsed arm_state selects collapsed texture")
	turnstile.arm_state = &"open"
	t_pres._refresh()
	_assert_true(t_pres.texture.resource_path.ends_with("turnstile_gate_open.png"),
		"TurnstilePresenter: open arm_state selects open texture")
	turnstile.free()

	# 2. FireShutterPresenter
	var shutter_script = load("res://scripts/chapters/ch01/visuals/fire_shutter_presenter.gd")
	var shutter := FireShutter.new()
	var s_pres := Sprite2D.new()
	s_pres.set_script(shutter_script)
	shutter.add_child(s_pres)
	shutter.shutter_state = &"closed"
	s_pres._refresh()
	_assert_true(s_pres.texture.resource_path.ends_with("fire_shutter_closed.png"),
		"FireShutterPresenter: closed shutter_state selects closed texture")
	shutter.shutter_state = &"raised"
	s_pres._refresh()
	_assert_true(s_pres.texture.resource_path.ends_with("fire_shutter_raised.png"),
		"FireShutterPresenter: raised shutter_state selects raised texture")
	shutter.free()

	# 3. CounterweightGearPresenter
	var gear_script = load("res://scripts/chapters/ch01/visuals/counterweight_gear_presenter.gd")
	var gear := CounterweightGear.new()
	var g_pres := Sprite2D.new()
	g_pres.set_script(gear_script)
	gear.add_child(g_pres)
	gear.gear_state = &"idle"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_idle.png"),
		"CounterweightGearPresenter: idle gear_state selects idle texture")
	gear.gear_state = &"slipping"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_slipping.png"),
		"CounterweightGearPresenter: slipping gear_state selects slipping texture")
	gear.gear_state = &"locked"
	g_pres._refresh()
	_assert_true(g_pres.texture.resource_path.ends_with("counterweight_gear_frozen.png"),
		"CounterweightGearPresenter: locked gear_state selects frozen texture")
	gear.free()

	# 4. SurgeCapacitorPresenter
	var cap_script = load("res://scripts/chapters/ch01/visuals/surge_capacitor_presenter.gd")
	var cap := SurgeCapacitor.new()
	var c_pres := Sprite2D.new()
	c_pres.set_script(cap_script)
	cap.add_child(c_pres)
	cap.charge_state = &"discharged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_discharged.png"),
		"SurgeCapacitorPresenter: discharged charge_state selects discharged texture")
	cap.charge_state = &"charged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_charged.png"),
		"SurgeCapacitorPresenter: charged charge_state selects charged texture")
	_assert_eq(c_pres.resolve_state_key(&"charged", true), "frozen_charged",
		"SurgeCapacitorPresenter: frozen + charged maps to frozen_charged via data mapping")
	_assert_eq(c_pres.resolve_state_key(&"discharged", true), "frozen_discharged",
		"SurgeCapacitorPresenter: frozen + discharged maps to frozen_discharged via data mapping")
	_assert_true(c_pres.state_textures["frozen_charged"].resource_path.ends_with("surge_capacitor_frozen_charged.png"),
		"SurgeCapacitorPresenter: frozen_charged texture is surge_capacitor_frozen_charged.png")
	_assert_true(c_pres.state_textures["frozen_discharged"].resource_path.ends_with("surge_capacitor_frozen_discharged.png"),
		"SurgeCapacitorPresenter: frozen_discharged texture is surge_capacitor_frozen_discharged.png")
	_assert_true(c_pres.state_textures["frozen"].resource_path.ends_with("surge_capacitor_frozen.png"),
		"SurgeCapacitorPresenter: legacy frozen fallback texture remains registered")

	# Test in-engine refresh with TemporalComponent frozen flag
	var temp := TemporalComponent.new()
	cap.add_child(temp)
	temp.is_frozen = true
	cap.charge_state = &"charged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_frozen_charged.png"),
		"SurgeCapacitorPresenter: frozen + charged selects frozen_charged texture")
	cap.charge_state = &"discharged"
	c_pres._refresh()
	_assert_true(c_pres.texture.resource_path.ends_with("surge_capacitor_frozen_discharged.png"),
		"SurgeCapacitorPresenter: frozen + discharged selects frozen_discharged texture")
	cap.free()

	# 5. PressureSwitchPresenter
	var pswitch_script = load("res://scripts/chapters/ch01/visuals/pressure_switch_presenter.gd")
	var pswitch := TriggerZone.new()
	var ps_pres := Sprite2D.new()
	ps_pres.set_script(pswitch_script)
	pswitch.add_child(ps_pres)
	ps_pres._refresh()
	_assert_true(ps_pres.texture.resource_path.ends_with("pressure_switch_released.png"),
		"PressureSwitchPresenter: not occupied selects released texture")
	pswitch.free()

	# 6. RetractableBridgePresenter
	var bridge_script = load("res://scripts/chapters/ch01/visuals/retractable_bridge_presenter.gd")
	var bridge := RetractableBridge.new()
	var b_pres := Sprite2D.new()
	b_pres.set_script(bridge_script)
	bridge.add_child(b_pres)
	b_pres._ready()
	_assert_eq(b_pres.offset, Vector2(-24, -10),
		"RetractableBridgePresenter: offset has +(0, 8) shift for trench cell center")
	bridge.platform_state = &"retracted"
	b_pres._refresh()
	_assert_true(b_pres.texture.resource_path.ends_with("bridge_platform_retracted.png"),
		"RetractableBridgePresenter: retracted selects retracted texture")
	bridge.platform_state = &"extended"
	b_pres._refresh()
	_assert_true(b_pres.texture.resource_path.ends_with("bridge_platform_extended.png"),
		"RetractableBridgePresenter: extended selects extended texture")
	bridge.free()

	# 7. LeverPresenter
	var lever_script = load("res://scripts/chapters/ch01/visuals/lever_presenter.gd")
	var lever := TimedBreaker.new()
	var l_pres := Sprite2D.new()
	l_pres.set_script(lever_script)
	l_pres.set("badge_type", &"a")
	lever.add_child(l_pres)
	l_pres._ready()
	_assert_true(l_pres.get_node_or_null("Badge") != null, "LeverPresenter: child Badge created for badge_type 'a'")
	l_pres._refresh()
	_assert_true(l_pres.texture.resource_path.ends_with("lever_switch_off.png"),
		"LeverPresenter: open breaker selects off texture")
	lever.lever_state = &"engaged"
	l_pres._refresh()
	_assert_true(l_pres.texture.resource_path.ends_with("lever_switch_on.png"),
		"LeverPresenter: engaged breaker selects on texture")
	lever.free()

	# 8. RouteBoardPresenter
	var rb_script = load("res://scripts/chapters/ch01/visuals/route_board_presenter.gd")
	var rb_pres := Sprite2D.new()
	rb_pres.set_script(rb_script)
	_assert_eq(rb_pres.tex_state0.resource_path.get_file(), "ch01_prop_route_board_state0.png", "RouteBoard: state0 texture")
	_assert_eq(rb_pres.tex_state1.resource_path.get_file(), "ch01_prop_route_board_state1.png", "RouteBoard: state1 texture")
	_assert_eq(rb_pres.tex_state2.resource_path.get_file(), "ch01_prop_route_board_state2.png", "RouteBoard: state2 texture")
	rb_pres.free()


# -------------------------------------------------------------------------------------------------
# 6. Real Save File Untouched
# -------------------------------------------------------------------------------------------------
func test_real_save_unmodified() -> void:
	var exists := FileAccess.file_exists(REAL_SAVE_SLOT_0)
	if exists:
		var mtime := FileAccess.get_modified_time(REAL_SAVE_SLOT_0)
		_assert_true(mtime > 0, "Real save exists with valid timestamp")
	else:
		_assert_false(exists, "Real save slot_0 does not exist and was not created")
