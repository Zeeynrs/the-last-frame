class_name TimedBreaker
extends PuzzleObject

## CH1-PZ-004 breaker: `use` engages it for `engage_ticks_base` ticks, only while the capacitor
## powers the bus. Chrono-shielded (no temporal component). Echoes may pull it.

signal engaged_changed(engaged: bool)

@export var capacitor_id: StringName = &""
@export var engage_ticks_base: int = 180

var lever_state: StringName = &"open"
var engage_ticks: int = 0
## Absolute tick of engagement: release at engaged_at + engage_ticks_base, independent of whether
## the pull came from the player (between ticks) or an echo (inside a tick signal).
var _engaged_at: int = -1


func is_engaged() -> bool:
	return lever_state == &"engaged"


func bus_powered() -> bool:
	var capacitor = resolve(capacitor_id)
	return capacitor != null and capacitor.bus_powered


func _can_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> StringName:
	if not bus_powered():
		return &"unpowered"
	return &"already_open" if is_engaged() else &""


func _on_use(_actor_id: StringName, _interaction_id: StringName, _payload: Dictionary) -> void:
	lever_state = &"engaged"
	engage_ticks = engage_ticks_base
	var clock := _clock()
	_engaged_at = clock.tick if clock != null else 0
	engaged_changed.emit(true)


func _puzzle_tick(tick: int) -> void:
	if not is_engaged():
		return
	engage_ticks = maxi(engage_ticks_base - (tick - _engaged_at), 0)
	if engage_ticks <= 0:
		_release()


func _release() -> void:
	lever_state = &"open"
	engage_ticks = 0
	_engaged_at = -1
	engaged_changed.emit(false)


func _reset_unsolved() -> void:
	if is_engaged():
		_release()
