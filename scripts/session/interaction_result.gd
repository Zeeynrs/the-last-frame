class_name InteractionResult
extends RefCounted

## Result of an interaction request per ADR-006.

var ok: bool = false
var reason: StringName = &""


func _init(p_ok: bool = false, p_reason: StringName = &"") -> void:
	ok = p_ok
	reason = p_reason


static func success() -> InteractionResult:
	return InteractionResult.new(true, &"")


static func failure(p_reason: StringName) -> InteractionResult:
	return InteractionResult.new(false, p_reason)


func _to_string() -> String:
	return "InteractionResult(ok=%s, reason=%s)" % [str(ok), str(reason)]
