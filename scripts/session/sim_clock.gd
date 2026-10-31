class_name SimClock
extends Node

## Deterministic simulation clock per ADR-004.
## Advances an integer tick counter once per physics process frame while unpaused.

signal tick_advanced(tick: int)

@export var is_paused: bool = false

var tick: int = 0


func _physics_process(_delta: float) -> void:
	if not is_paused:
		tick += 1
		tick_advanced.emit(tick)


## Advance clock by n ticks (used in deterministic tests and simulations).
## Emits tick_advanced once per tick so step(N) and N x step(1) are identical (ADR-004).
func step(n: int = 1) -> void:
	for i in range(maxi(n, 0)):
		tick += 1
		tick_advanced.emit(tick)


## Reset clock to zero or specified tick.
func reset(new_tick: int = 0) -> void:
	tick = new_tick
