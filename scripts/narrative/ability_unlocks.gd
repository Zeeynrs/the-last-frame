class_name AbilityUnlocks
extends Node

## Which pocket-watch abilities the player has (ADR-020 am. "progressive abilities", TLF-050).
##
## A session service (GameSession creates it): unlocks are per-run progression saved with the
## game (save v3 "unlocked_abilities"), and several readers need them: PocketWatch (selection and
## activation), the ability wheel (ADR-021, read-only) and unlock triggers in rooms. It is kept
## out of NarrativeState so readers get a small typed API instead of generic flags.
##
## Unlocks only grow during play (unlock()); set_unlocked()/import_state() replace the whole set
## for the chapter start config and for loading a save.

## An ability became available during play (not emitted by set_unlocked()/import_state()).
signal ability_unlocked(ability: StringName)
## The set changed for any reason (unlock, chapter start config, save load). Readers resync.
signal unlocks_changed(unlocked: Array[StringName])

## ADR-015 order (also the ability wheel's slot order, ADR-021).
const KNOWN: Array[StringName] = [&"trace", &"rewind", &"freeze", &"echo", &"fast_forward"]
## The pre-ADR-020 flow and old saves: everything but the Fast-Forward stretch.
const DEFAULT_UNLOCKED: Array[StringName] = [&"trace", &"rewind", &"freeze", &"echo"]

var _unlocked: Array[StringName] = DEFAULT_UNLOCKED.duplicate()


static func is_known(ability: StringName) -> bool:
	return ability in KNOWN


func is_unlocked(ability: StringName) -> bool:
	return ability in _unlocked


## Unlocked abilities in ADR-015 order.
func unlocked() -> Array[StringName]:
	return _unlocked.duplicate()


## Returns true when `ability` was locked and is now unlocked.
func unlock(ability: StringName) -> bool:
	if not is_known(ability):
		push_warning("AbilityUnlocks: unknown ability '%s'." % ability)
		return false
	if is_unlocked(ability):
		return false
	_unlocked = _ordered(_unlocked + [ability])
	unlocks_changed.emit(unlocked())
	ability_unlocked.emit(ability)
	return true


## Replaces the whole set (chapter start config). Unknown names are ignored.
func set_unlocked(abilities: Array) -> void:
	_unlocked = _ordered(abilities)
	unlocks_changed.emit(unlocked())


## Plain data for SaveStore: ability names as Strings, ADR-015 order.
func export_state() -> Array:
	var out: Array = []
	for ability in _unlocked:
		out.append(String(ability))
	return out


func import_state(data: Array) -> void:
	set_unlocked(data)


static func _ordered(abilities: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for ability in KNOWN:
		for value in abilities:
			if StringName(str(value)) == ability:
				out.append(ability)
				break
	return out
