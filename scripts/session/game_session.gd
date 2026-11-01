class_name GameSession
extends Node

## Container node for session-scoped services per ADR-011.
## Belongs to group 'game_session' so gameplay nodes can discover services cleanly.

@export var sim_clock: SimClock
@export var id_registry: IdRegistry
@export var interaction_service: InteractionService
@export var echo_service: EchoService
@export var puzzle_service: PuzzleService
@export var narrative_state: NarrativeState
@export var spatial_service: SpatialService
@export var hint_service: HintService
## Present in chapter scenes (ChapterRoot); null in standalone test rooms.
@export var room_router: RoomRouter
## Abilities a New Game starts with (TLF-050, ADR-020 am.), e.g. [&"trace"]. Empty = the old flow
## (AbilityUnlocks.DEFAULT_UNLOCKED); a loaded save replaces it either way.
@export var starting_abilities: Array[StringName] = []
## Playtest telemetry (TLF-048): created for chapter scenes when `tlf/playtest_log` is on, else null.
var playtest_log: PlaytestLog
## Pocket-watch unlocks (TLF-050). Always present; created here when the scene has none.
var ability_unlocks: AbilityUnlocks


func _enter_tree() -> void:
	add_to_group(&"game_session")


func _ready() -> void:
	if sim_clock == null:
		sim_clock = get_node_or_null("SimClock") as SimClock
	if id_registry == null:
		id_registry = get_node_or_null("IdRegistry") as IdRegistry
	if interaction_service == null:
		interaction_service = get_node_or_null("InteractionService") as InteractionService
	if echo_service == null:
		echo_service = get_node_or_null("EchoService") as EchoService
	if puzzle_service == null:
		puzzle_service = get_node_or_null("PuzzleService") as PuzzleService
	if narrative_state == null:
		narrative_state = get_node_or_null("NarrativeState") as NarrativeState
	if spatial_service == null:
		spatial_service = get_node_or_null("SpatialService") as SpatialService
	if hint_service == null:
		hint_service = get_node_or_null("HintService") as HintService
	if room_router == null:
		room_router = get_node_or_null("RoomRouter") as RoomRouter
	if ability_unlocks == null:
		ability_unlocks = get_node_or_null("AbilityUnlocks") as AbilityUnlocks
	if ability_unlocks == null:
		ability_unlocks = AbilityUnlocks.new()
		ability_unlocks.name = "AbilityUnlocks"
		add_child(ability_unlocks)
	if not starting_abilities.is_empty():
		ability_unlocks.set_unlocked(starting_abilities)
	# Before the chapter's _ready enters (or restores) the first room, so the log sees it.
	if playtest_log == null and room_router != null and PlaytestLog.is_enabled():
		playtest_log = PlaytestLog.new()
		playtest_log.name = "PlaytestLog"
		add_child(playtest_log)
