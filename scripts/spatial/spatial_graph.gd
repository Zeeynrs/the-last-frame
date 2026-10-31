class_name SpatialGraph
extends RefCounted

## Logical room/doorway graph per ADR-009 (+ clarification). Pure data, no scene nodes.
##
## - Rooms declare doorways (room-local door ids). A doorway is addressed as (room_id, door_id).
## - Every declared doorway must be paired exactly once. A doorway may pair with itself
##   (a dead-end loop). An edge flagged traversable = false (e.g. a grille) is a valid pairing
##   but is ignored for reachability.
## - apply(pairs) is transactional: every doorway named in `pairs` is detached from its current
##   partner, then re-paired as listed. The result is validated on a copy; on failure nothing
##   changes and `changed` is not emitted.
## - Validation order: unknown doorway / duplicate mention / dangling doorway -> invalid_graph;
##   then each critical room pair must stay mutually reachable -> critical_path_unreachable.

signal changed(affected_rooms: Array[StringName])

var _rooms: Dictionary = {}      # room_id -> {"orientation": int, "doorways": Array[StringName]}
var _partners: Dictionary = {}   # "room|door" -> {"room": room_id, "door": door_id, "traversable": bool}
var _critical_pairs: Array = []  # [[room_a, room_b], ...]


static func key(room_id: StringName, door_id: StringName) -> String:
	return "%s|%s" % [room_id, door_id]


func add_room(room_id: StringName, doorways: Array, orientation: int = 0) -> void:
	var doors: Array[StringName] = []
	for d in doorways:
		doors.append(StringName(d))
	_rooms[room_id] = {"orientation": orientation, "doorways": doors}


func has_doorway(room_id: StringName, door_id: StringName) -> bool:
	return _rooms.has(room_id) and door_id in _rooms[room_id]["doorways"]


func get_room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in _rooms.keys():
		ids.append(id)
	ids.sort_custom(func(a, b): return String(a) < String(b))
	return ids


## Rooms that must remain mutually reachable after any transform (e.g. the chapter entry anchor).
func add_critical_pair(room_a: StringName, room_b: StringName) -> void:
	_critical_pairs.append([room_a, room_b])


## Builds the initial pairing (validated). Each pair: [room_a, door_a, room_b, door_b, traversable?].
func set_initial_pairs(pairs: Array) -> Dictionary:
	var candidate := {}
	for pair in pairs:
		var problem := _write_pair(candidate, pair)
		if problem != &"":
			return {"ok": false, "reason": problem}
	var check := _validate(candidate)
	if check["ok"]:
		_partners = candidate
	return check


## Destination of walking through (room_id, door_id): {"room_id", "door_id", "traversable"} or {}.
func get_destination(room_id: StringName, door_id: StringName) -> Dictionary:
	var partner = _partners.get(key(room_id, door_id))
	if partner == null:
		return {}
	return {"room_id": partner["room"], "door_id": partner["door"], "traversable": partner["traversable"]}


## Dry run of apply(): same validation, no side effects. Returns {ok, reason}.
func validate_transform(pairs: Array) -> Dictionary:
	var built := _build_candidate(pairs)
	return {"ok": built["ok"], "reason": built["reason"]}


## Transactional re-pairing. Returns {ok, reason}; emits `changed(affected_rooms)` on success.
func apply(pairs: Array) -> Dictionary:
	var built := _build_candidate(pairs)
	if not built["ok"]:
		return {"ok": false, "reason": built["reason"]}
	var candidate: Dictionary = built["candidate"]
	var affected := _affected_rooms(_partners, candidate)
	_partners = candidate
	changed.emit(affected)
	return {"ok": true, "reason": &""}


func _build_candidate(pairs: Array) -> Dictionary:
	var candidate := _partners.duplicate(true)
	var mentioned := {}
	for pair in pairs:
		if not (pair is Array) or pair.size() < 4:
			return {"ok": false, "reason": &"invalid_graph", "candidate": {}}
		for side in [[pair[0], pair[1]], [pair[2], pair[3]]]:
			var k := key(StringName(side[0]), StringName(side[1]))
			if mentioned.has(k) and not (pair[0] == pair[2] and pair[1] == pair[3]):
				return {"ok": false, "reason": &"invalid_graph", "candidate": {}}  # same doorway re-paired twice
			mentioned[k] = true
	# Detach every mentioned doorway from its current partner (both directions).
	for k in mentioned.keys():
		var partner = candidate.get(k)
		if partner != null:
			candidate.erase(key(partner["room"], partner["door"]))
		candidate.erase(k)
	for pair in pairs:
		var problem := _write_pair(candidate, pair)
		if problem != &"":
			return {"ok": false, "reason": problem, "candidate": {}}
	var check := _validate(candidate)
	return {"ok": check["ok"], "reason": check["reason"], "candidate": candidate}


func is_reachable(from_room: StringName, to_room: StringName) -> bool:
	return _reachable_from(_partners, from_room).has(to_room)


## Rooms that cannot be reached from `from_room` through traversable edges.
func get_unreachable_rooms(from_room: StringName) -> Array[StringName]:
	var seen := _reachable_from(_partners, from_room)
	var out: Array[StringName] = []
	for room in get_room_ids():
		if not seen.has(room):
			out.append(room)
	return out


## Canonical sorted pair list, e.g. for saves (ADR-010) and test comparisons.
func export_pairs() -> Array:
	var out: Array = []
	for k in _partners.keys():
		var parts := String(k).split("|")
		var partner: Dictionary = _partners[k]
		var a := [parts[0], parts[1]]
		var b := [String(partner["room"]), String(partner["door"])]
		if "%s|%s" % a <= "%s|%s" % b:
			out.append([a[0], a[1], b[0], b[1], partner["traversable"]])
	out.sort_custom(func(x, y): return "%s|%s" % [x[0], x[1]] < "%s|%s" % [y[0], y[1]])
	return out


## Replaces the whole pairing from saved data (validated; nothing changes on failure).
func import_pairs(pairs: Array) -> Dictionary:
	var candidate := {}
	for pair in pairs:
		var problem := _write_pair(candidate, pair)
		if problem != &"":
			return {"ok": false, "reason": problem}
	var check := _validate(candidate)
	if check["ok"]:
		var affected := _affected_rooms(_partners, candidate)
		_partners = candidate
		if not affected.is_empty():
			changed.emit(affected)
	return check


# --- internals ------------------------------------------------------------------------

func _write_pair(target: Dictionary, pair: Array) -> StringName:
	var room_a := StringName(pair[0])
	var door_a := StringName(pair[1])
	var room_b := StringName(pair[2])
	var door_b := StringName(pair[3])
	var traversable: bool = pair[4] if pair.size() > 4 else true
	if not has_doorway(room_a, door_a) or not has_doorway(room_b, door_b):
		return &"invalid_graph"
	var ka := key(room_a, door_a)
	var kb := key(room_b, door_b)
	if target.has(ka) or target.has(kb):
		return &"invalid_graph"
	target[ka] = {"room": room_b, "door": door_b, "traversable": traversable}
	target[kb] = {"room": room_a, "door": door_a, "traversable": traversable}
	return &""


func _validate(candidate: Dictionary) -> Dictionary:
	for room in _rooms.keys():
		for door in _rooms[room]["doorways"]:
			if not candidate.has(key(room, door)):
				return {"ok": false, "reason": &"invalid_graph"}  # dangling doorway
	for pair in _critical_pairs:
		if not _reachable_from(candidate, pair[0]).has(pair[1]):
			return {"ok": false, "reason": &"critical_path_unreachable"}
	return {"ok": true, "reason": &""}


func _reachable_from(partners: Dictionary, start: StringName) -> Dictionary:
	var seen := {start: true}
	var queue: Array[StringName] = [start]
	while not queue.is_empty():
		var room: StringName = queue.pop_front()
		if not _rooms.has(room):
			continue
		for door in _rooms[room]["doorways"]:
			var partner = partners.get(key(room, door))
			if partner == null or not partner["traversable"]:
				continue
			var next: StringName = partner["room"]
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


func _affected_rooms(before: Dictionary, after: Dictionary) -> Array[StringName]:
	var rooms := {}
	for k in before.keys():
		if not after.has(k) or after[k] != before[k]:
			rooms[StringName(String(k).split("|")[0])] = true
	for k in after.keys():
		if not before.has(k):
			rooms[StringName(String(k).split("|")[0])] = true
	var out: Array[StringName] = []
	for r in rooms.keys():
		out.append(r)
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out
