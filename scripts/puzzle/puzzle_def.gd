class_name PuzzleDef
extends Resource

## Data definition of one puzzle (ADR-013). Text is referenced by translation keys only.

@export var puzzle_id: StringName = &""
## Room the puzzle lives in (ADR-005 room id), used to find the active puzzle for hints.
@export var room_id: StringName = &""
@export var title_key: String = ""
## Escalating hint ladder (FR-010): [nudge, rule reminder, next action].
@export var hint_keys: PackedStringArray = PackedStringArray()


func is_valid() -> bool:
	return not String(puzzle_id).is_empty() and not String(room_id).is_empty() and hint_keys.size() == 3
