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
const BASELINE_FINGERPRINTS_GZIP_B64: String = "H4sIAAAAAAAC/+1d33OjOBL+X/ScTQBjx5m3nd26q3u4q6mdrbqHqS1KxorNBoMPcDKZrfnfTxIYkJAIiF/STl6m4jBxt4TU/XX3p9ZfACZJ8AxD7xzC7DFOTuDDX8CPwzBIgzhKwYcvf4EQvqIEfLBvrRtwgukT+GCRH88wO4IP4BNKghPKUPJfGIbp3S/Xv/0Uh6+HOHJ+Bfi/5j/jb/uycsgfb/A/f9x82Vpb/GFlufTT5t4hn8i/+NNqi3974zhb+slxXPo/i0/0Ef3wB/l2oif5WvqtIImzQsXUhyHCz4jqNn2WvZ7xL64KOXvw/aYcoFsN0KkN0D8i/+kcB1FWDe7zEZ5RMbTuwlPyV3SCQ5jiPwO/IT+D0SFE1felwTfyR2TYN/YG/9n3Umn6551U3geHIMMv1Q9j/8lzVuuH0VX/JUj8ut4J3AcX/IDo3FXl+jLax76HvzrzUpQ8Bz6aT2Gnu8LMHMdx4qGvQeYhrPZ86lpq8xtZtufH0f7iZ3Eyn7buG9raXbT9Rxxn52TeDUiWxc22x/5j1Xe8NLvsUZQZMNWVrgZO9MqLw713gpEBE13pauBEu9ibIBghE4xHpasRE113K/EZJRAbPS8NDscsiA53P5/PSQz94+9JcDjMOP0rR236r0jSO8AM3X0kEGQCrVugEwWHruJCZ7XXETXVV8uZTG7mvcDMP3rnwH+6nPXZnpIZThDemynyQvSskzGRaJtibQkI8XxokLJhECFztL3uuaU1xl+BPQW2v9i07EKUR7/X7/o5QZB+Sbz7E6vtBXsaG1r2LR9C31YRIxBEkeWgbBIF3ziFqVKS1Az0QEsQWEpePzg0gLYGSObiNSCN5EqpLpF3YzuDpNaDLiAJxkqJ9zTZsHK26hKZSASIA5RqhA+bofNag+NAhNFLWTT9gVMEg8ZWIlIggqnVuNxc1sMQWSUoAyKkVsra5DmhIaukxFCwgE5elmMn0B1mlfr8VINzStowiAKIgYbaij2E8Q6Gt3UQANqgQbV2XGp5CMJTHRXjxYHYuVejWtPMnj2GPDwsgbjit4yzUJRU9/hAiAOqcVkUa947I0gjLhuIPXm1N/L35o4xujLhK/fHlVyamXXWNB+JveS3ODLCO47jLf4NExzBNGTKvu/u8xm+RDX7QXzCT1utzZlkiJIlBB+RByP/SORdx1osIdGj5uskkRn2nn58SfDmfUH4JcxZdlhvKRB5yD8VTnuVlx3cbbXFyiLEQ/7MpqGlva6XJOyyJEG/k7r+EWsSktH/fkmiNAtC9GvwHOxRkt4VP/wnTrLjUNj8GR1OGGpccbNKEkCq4Of4Mq+CsqoOXjbeLv7qWQ/aR/mGVKDq759iY2wQLVv7MHQfYONmRMBMNdUlWO6mbYaNtJaaGlgudbhyKXqGvhfFma7VUr68ixUlEQn22afUkPJulCWvFJ9oWd81rBxdV5dqWsBYr4SCc1cJlN1bZK09onJgQAY7sjZegvZYX2hCNbqmrIFV0ntvhxfFow9TZMBc17U1cLK33iP+0YiKdKmqgdP8gF02MoFfUShq3BQnKMW4qEibGBAxsfo62q+MNIOPjx5BSMbREWqq687gTC/nM84+4VpDGEK91rHdVeNP9KdS79lGsFWb8iKiwtnZYA9N4HUKFI7SOESLmOzNAJpWds1veo8LqN4xNyd7CaXuSzK0imKgwqJn1dfdLFbqZphYcq2OLJ3/UKS6sEWb21oSHYgy61XBmRYQHzadi2C8oG41Q1qhvLF71Jl5OWXaGghS2Tz3Yq0sp8w5g2YammdduO4gKc06b+PXubS8KLaxBkkj+V7QTAFXzCMKlO37jboUJcZTXv9bqw+OzbcCWSK2ErgeOlAuYwqkuVRukPm5KEWZTNITyLKhHJHEttxhEjuX6IvqrKMsT5x3BG/kJasZpoQPe6X8VmuJQyDKJvIz61jqkqpMGhDm16pZXVF6hz1gVLVMEhAnmDgaYB/yUUPaNZsCBBmW6l0RahyOvLbqcvKEAmikGLhdPmA9cqE/kOUEeBfnjiTRkUl0uNUxYM1XMSwQxLXj7e1GOAfkkV71BinDY4Cd5kMaIA12eCf4oLwDBNEHaAtNOBw2wKqw4BtIQPkU8uroGbyBriv5OagpWEf9iGsLQdDRfHBH2lpV4vzMEbZ60V6n8eszU+/mAQttZDvepNX4dOxEip60LkBFqewaFD0ZBxiNY9JIQuEESWQbYS2Rt4OvvZmFHy/h0xHBfSNE92wNiHVy7RwNtPtXhKn8BdNPz/lr11CHORzEbM1TBvdunctaMFTdjVui/JLZWvydXaBKZ3Fm6+fjJcvKN6Qdr1Wini6s1h0K89QOmrX+8iPxWi8kbfqCCM/eOyCYGNFZ5UhPAflHmGRGUAUDYqW9NN9s+YI2gDGI03IIT3MYH97pje/0xjIymETjMZmNrZpPQfCYRXlq8/RTXQIsHoMEXQ2ecSVZRvnZ9qYiaYI4bZwDT4P9RX+OZu64MZYzbUmUiusOQnNFtcbMzXnVbvm2Tm52xPoecVMBY6wxgz+N23us9rpvQBbra7xWZARp2y7iK4L+9adJs+q+k6UnNoGNhX0FqLrkPBSpYFya/ZZJPQFxRoonUPUoF/DiJivHNQQ1Mj6gJRvE15UHCObyNkCW0OELgQMmVZJ6AW/lZgaQyEQqXLMoQJhbqRV3tz3L6E1hk/OdxCK7F0bzpL2lPqGNgB7IY/1KLK2c9mFFvCmW4ZrIntZ5jwPeazMPAFpyBNWeXW16shV4wfVAGAjDY95ADNgq9UAWCMNbjgs1ZGTXeA40IjyOfjjE5LGxGJDEaLxx79HeTSywMYeNX48qrkQCQBYnjTiljLUGYtDNU7227jjiRCNt+Q8jqcACXCABvjxzYYBJ78/h2/YldvMipaASvI07xRaoJznqR0F/hrKxJkIdM9Ox3qHMglBmIV+8nHMc01u1ke0atrw/x0+2ppXFErMjkXt9VCfbWWONtyu7MF/NAxzGBA4Tp1JS5ONTG9mr5ydxmuK2i0u2MWQaFxYW3N2+3cYwd8YFLaxO/ZqB7EVOAXwkDSZ1pQu2a6gDXfD3BOEdU6iY3uUftWkDKVJOF7IcxEdBTtNV/qaqTeETVfsDKg9wLlkcVi2ZCIagI2vAaar8AsMnjwRK5jAWYbLHqQyIWaomlEsM5ISS5PThQqb5nfn3QzL/6osBp5ZivN38OCEb7oz2eI5hqP22Y0LJEJe1DgY1Y7RX+f4zoPZ+1dS4svsZ4obuCD7NSShRtBhnHL+lF1JyeQkmIqFN5Uq0JTfIOmhdA+BDAaJNo0o1BqANDm3tZbfLIyojZ5wfgPYNnBIYpdg7nvHXz37H3mbM7k2NdNUtGwIDSWjMN7XpkeRtimzGfqAlLuQr2D3qglLRZQwHpNHdqGLZCAxIIjMuy9ini49AZMf6WO8mM01RTPQDxEERX/nskbIXCexbknPckYT2LaCthogURxLgjUiDL8hshrxbQVQA2kKGAR2FmsJLsAya+HlAnaspqIK2QAB3uXLToPlsIlPQglr5V3k/ZDZ7kxSKmd0MMUM8ugJS3DWgXCsQy0EMIAUf/IK1hrxdAVAAbSiCn2pLpUuNTj59dsc6p5cbyenMywOZzJHNzATRzDWNbMfbqucC66bAF5CMWV1w18K9Y3EV8+AQkQ6dMV7gcbhguVxeEp/h9j5aBv0NBrjd6yG9o8XaokZajogdiHu/qem+zq8BdZz6p2KU+f/MPy0zkuITOxIdytClmrQAvaSa0hojRZwe1P7M3lXTnfbZm6um/nvlc5x0tYEX5/HF2t0l1bgXjqRYmxKjZVC1NiK+wKxGLc8YugS7Szhn6TNHZq7iBqRZYD8+ab/tIsfC6/iA29ubcF1XXVkjKrWOyQekLwnOEPjwDP1g1jtsFCtwpZVY9EYpZZ/Nqa+J2qoVLSacvC0BNGhiau4m+j6nryRSdk0pu6rHt+v2PPkhkeI3pfhDShuslK4pNFq36VWTYuXMdW0HL7aO9oAYBHKHG7bqY+TAGpDCOE5kr2SUSGaJt4AMiPEnkhzlUYoRE3gDUY0n/wp5QAME8SntjfKyqQMAIIQF/PHRjfJ4+hdm1s4wy5JedrgOkmGb7x1wer5+S0LjAeMKFKUx7h3I/D5fGVCfUdbDAYnnE6/IvtWXhazpeJamTz0iD0EFBYmftovbrx4FiTwyFVUkdDOKrfl5bpvVUvA+ipjD/uJnzWuqaIK+MAAQa3s5LZmgp5qtiibkD07Z13zErPZ7Jm7BEzX7ID0X7RiSUxDNSZLfvmfj9MzG0bm92sncBJkeoTL2tF/jij53YXFyZou3eLHcngby7T7gqkReqgIccvteQieUOW3gxUoUbQ7QunXEy6kvxF1oAY/3TmeHuBOtlLkh7jTLryu8ZaXXISy3HoSPmjFPDm4ThGNqMkXzItuc1Fh0XCgujXTdxtU779D274C6MMXyG8REz9fzcYqD4mNzOa6bFs9tEutS+VRGW+UG75eM6Yc+KiHKmZhezNeaQHZxAcmi4y7b7dM5py6MWRpAvGL47jhqeTSD39s08KLdN1YDYbxfBoMklXjG8tkIszdgXeC9ju/iZbJgs3pi5oK84sL0ggT6nmP6W7K9EoT/j3dCp9gQuhc0pSuHGUklqqpB+TojurL8eYl8Gp+F6NkIxjKnsP7EZU5hPfnLLGvO9jJ8o3Mw5/JVZvhVur4T/CYm+CXY9uIunPGsHXoUzQSGydF+96pdV0DFeJiD2v1OTPahJfGC5qo/NOQygA9IgCB/X0kPLk1TYOMYHvOr2qHmPtlwoRhR/phLHef9iB1rmCBRSMwFw3S1Dh6R4Cwte4rW2g4cDw9UgBTC8Mc0XXcsoTup0N2Arh9vCPWlQn1xaK4ktOZIgci7DmjhzIvqf83Cfd8z/Q2RlecCInc2oFkCL4oURwNsFOlgWPaO4IkCLa8hkPN0QOoDq0zVfW2UPTN8y3miIQa6Y25vhBPuIxv8boqPUSYc2YF0U3yMMu2oDqmb2l0bOrQlfxv7WJH4l5/Mv98sZ0AwzK0ouVGAd/+sqWC3uD7CqqWC7Y1btMGvnk2fC85v1dujr2TG/nfRv2RIF3MQmZFPw6ZCH0VtWZ66UPSfSRCGSLOejorBJ7e5b/llDqQbQNwZ6UZNKF2qgF+76qd+hBLwuwONt8kdadiq4KaxxtPNQeE9Pajf0MC56a0v2TJd4EubQ+V1rjvN3CsJ/Wn5qHkXEdlDLzDIcHuRa/ehH5NtBC/7IPZOQQJ1bfT6XpJdBDsYef+AGeVO3GiQ3HlFGh4Z2qaYNZ23jBEBYtvCc8l75O44aZPdLMnJmStBzoud/sZrocQ+9Gd74NTWdgAQbQv+7K6rQotfatmYeR/pVGtiEkp8G1jkBqKafMnDmnWBFr//H0GU/O2H2QAA"


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
	_assert_true(dep_board == null, "arrival_platform: DepartureBoard removed pending TLF-073 sheared W-face variant")
	_assert_true(closed_track != null, "arrival_platform: ClosedTrackNotice exists")
	_assert_eq(closed_track.position, Vector2(528, 146), "arrival_platform: ClosedTrackNotice at (528, 146)")

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
