class_name SaveStore
extends Node

## Versioned save/load per ADR-010 (+ TLF-019 amendment).
##
## - JSON text, type-tagged with JSON.from_native/to_native so StringName/int survive the round trip
##   and Objects can never be serialized (they encode as null).
## - Atomic writes: <slot>.json.tmp is written and verified, then renamed over the slot file.
## - Reads never crash: missing, corrupt, newer-version and malformed files return a reason.
## - Older versions are upgraded through `migrations` (from_version -> Callable(Dictionary) -> Dictionary).
## - Missing optional fields get defaults; data is validated before anything touches the world.
## Registered as the SaveService autoload (ADR-011); the class is SaveStore so the name does not hide it.

const SAVE_VERSION: int = 1
const DEFAULT_ROOT: String = "user://saves"

## Override in tests; never point at a real user directory from a test.
var save_root: String = DEFAULT_ROOT
## Target version for migrations (tests may raise it together with `migrations`).
var current_version: int = SAVE_VERSION
## from_version (int) -> Callable taking and returning the save Dictionary at from_version + 1.
var migrations: Dictionary = {}


static func default_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"chapter": "ch01",
		"checkpoint_id": "",
		"puzzles": {},
		"narrative_flags": {},
		"fragments": [],
		"temporal": {},
		"spatial": {},
		"journal": [],
		"hints": {},
		"settings_ref": "user://settings.cfg",
	}


# --- Capture / apply ------------------------------------------------------------

## Builds plain save data from a live session. Only IDs and primitives (ADR-010).
func capture(session: GameSession, chapter: String, checkpoint_id: String) -> Dictionary:
	var data := default_save()
	data["save_version"] = current_version
	data["chapter"] = chapter
	data["checkpoint_id"] = checkpoint_id
	if session.puzzle_service != null:
		data["puzzles"] = session.puzzle_service.export_state()
	if session.narrative_state != null:
		data["narrative_flags"] = session.narrative_state.export_flags()
		data["fragments"] = session.narrative_state.export_fragments()
		data["journal"] = session.narrative_state.export_journal()
	if session.hint_service != null:
		data["hints"] = session.hint_service.export_state()
	var temporal := {}
	for id in session.id_registry.get_ids():
		var node = session.id_registry.resolve(id)
		if node is Interactable:
			var component: TemporalComponent = node.get_temporal()
			if component != null:
				temporal[String(id)] = component.export_history()
	data["temporal"] = temporal
	if session.spatial_service != null:
		data["spatial"] = session.spatial_service.export_state()
	return data


## Applies validated save data to a live session.
## Returns {ok, reason, skipped: Array[String]}; unknown temporal IDs are skipped, never fatal.
func apply(session: GameSession, data: Dictionary) -> Dictionary:
	var check := validate(data)
	if not check["ok"]:
		return {"ok": false, "reason": check["reason"], "skipped": []}
	if session.puzzle_service != null:
		session.puzzle_service.import_state(data["puzzles"])
	if session.narrative_state != null:
		session.narrative_state.import_state(data["narrative_flags"], data["fragments"])
		session.narrative_state.import_journal(data["journal"])
	if session.hint_service != null:
		session.hint_service.import_state(data["hints"])
	if session.spatial_service != null and not data["spatial"].is_empty():
		var spatial_result := session.spatial_service.import_state(data["spatial"])
		if not spatial_result["ok"]:
			return {"ok": false, "reason": spatial_result["reason"], "skipped": []}
	var skipped: Array[String] = []
	for key in data["temporal"].keys():
		var node = session.id_registry.resolve(StringName(key))
		var component: TemporalComponent = node.get_temporal() if node is Interactable else null
		if component == null or not component.import_history(data["temporal"][key]):
			skipped.append(String(key))
	return {"ok": true, "reason": &"", "skipped": skipped}


# --- Disk ---------------------------------------------------------------------------

func slot_path(slot: int) -> String:
	return save_root.path_join("slot_%d.json" % slot)


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Atomic write. Returns OK or an Error code.
func write_slot(slot: int, data: Dictionary) -> Error:
	var check := validate(data)
	if not check["ok"]:
		push_error("SaveService: refusing to write invalid save (%s)." % check["reason"])
		return ERR_INVALID_DATA
	var dir_error := DirAccess.make_dir_recursive_absolute(save_root)
	if dir_error != OK and not DirAccess.dir_exists_absolute(save_root):
		return dir_error
	var text := JSON.stringify(JSON.from_native(data), "\t")
	var final_path := slot_path(slot)
	var tmp_path := final_path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	# Verify the temp file before it replaces the real one.
	if FileAccess.get_file_as_string(tmp_path) != text:
		DirAccess.remove_absolute(tmp_path)
		return ERR_FILE_CORRUPT
	if FileAccess.file_exists(final_path):
		DirAccess.remove_absolute(final_path)
	return DirAccess.rename_absolute(tmp_path, final_path)


## Returns {ok, reason, data}. reason: no_save | corrupt | unsupported_version | invalid | ""
func read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": &"no_save", "data": {}}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {"ok": false, "reason": &"corrupt", "data": {}}
	var native = JSON.to_native(parsed)
	if not (native is Dictionary):
		return {"ok": false, "reason": &"corrupt", "data": {}}
	return upgrade(native)


# --- Versioning and validation ----------------------------------------------------

## Fills defaults and runs migrations up to current_version. Returns {ok, reason, data}.
func upgrade(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	var version := int(data.get("save_version", -1))
	if version < 0:
		return {"ok": false, "reason": &"invalid", "data": {}}
	if version > current_version:
		return {"ok": false, "reason": &"unsupported_version", "data": {}}
	while version < current_version:
		if not migrations.has(version):
			return {"ok": false, "reason": &"unsupported_version", "data": {}}
		data = migrations[version].call(data)
		version += 1
		data["save_version"] = version
	for key in default_save().keys():
		if not data.has(key):
			data[key] = default_save()[key]
	var check := validate(data)
	if not check["ok"]:
		return {"ok": false, "reason": check["reason"], "data": {}}
	return {"ok": true, "reason": &"", "data": data}


## Structural validation (types of every section). Returns {ok, reason}.
func validate(data: Dictionary) -> Dictionary:
	var expected := {
		"save_version": TYPE_INT, "chapter": TYPE_STRING, "checkpoint_id": TYPE_STRING,
		"puzzles": TYPE_DICTIONARY, "narrative_flags": TYPE_DICTIONARY,
		"fragments": TYPE_ARRAY, "temporal": TYPE_DICTIONARY, "spatial": TYPE_DICTIONARY,
		"journal": TYPE_ARRAY, "hints": TYPE_DICTIONARY, "settings_ref": TYPE_STRING,
	}
	for key in expected.keys():
		if not data.has(key) or typeof(data[key]) != expected[key]:
			return {"ok": false, "reason": &"invalid"}
	for entry in data["temporal"].values():
		if not (entry is Dictionary) or not (entry.get("entries") is Array):
			return {"ok": false, "reason": &"invalid"}
	return {"ok": true, "reason": &""}
