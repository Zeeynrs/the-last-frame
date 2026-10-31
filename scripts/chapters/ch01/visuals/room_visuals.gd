class_name RoomVisuals
extends Node2D

## Visual controller for Chapter 1 rooms.
## Ensures player is set to z_index = 10 to participate in YSort_Actors sorting per ADR-019.


func _ready() -> void:
	_ensure_player_layer()


func _process(_delta: float) -> void:
	_ensure_player_layer()


func _ensure_player_layer() -> void:
	if not is_inside_tree():
		return
	var player := get_tree().root.find_child("Player", true, false) as Node2D
	if player != null and player.z_index != 10:
		player.z_index = 10
