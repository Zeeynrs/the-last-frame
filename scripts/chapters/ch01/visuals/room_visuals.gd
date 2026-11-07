class_name RoomVisuals
extends Node2D

## Visual controller for Chapter 1 rooms.
## Ensures player is set to z_index = 10 to participate in YSort_Actors sorting per ADR-019, and
## applies the upright-body rule (DepthSort) once the room has finished loading.


func _ready() -> void:
	_ensure_player_layer()
	# Deferred: presenters later in the room pick their textures in their own _ready.
	_apply_depth_sort.call_deferred()


func _process(_delta: float) -> void:
	_ensure_player_layer()


func _apply_depth_sort() -> void:
	var room := get_parent()
	if room != null and is_inside_tree():
		DepthSort.apply(room)


func _ensure_player_layer() -> void:
	if not is_inside_tree():
		return
	var player := get_tree().root.find_child("Player", true, false) as Node2D
	if player != null and player.z_index != DepthSort.ACTOR_Z:
		player.z_index = DepthSort.ACTOR_Z
