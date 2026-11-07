# TLF-070 Handoff Report: Memory Lines Auto-Advance & Interact Advance

**Task:** TLF-070 — Watch-pickup Memory lines auto-advance + interact key advance + AbilityWheel unblocking  
**Owner:** Flash  
**Worktree:** `tlf-implementation-qa`  
**Branch:** `adityadaffa522/tlf-070-mem-watch-advance`  
**Base Commit:** `f0685ed` (Merge of TLF-059 + TLF-065 on `main`)  
**Status:** COMPLETE / VALIDATION GREEN (454 passed, 0 failed, 0 leaks)  

---

## 1. Executive Summary

This task resolves the issue where the pocket watch pickup Memory lines (`MEM_WATCH_1`, `MEM_WATCH_2`, `EL_B01_04`) on the Arrival Platform never cleared by themselves, only `confirm` (`Enter`, `Space`, mouse click) advanced them (not `interact` / `E`), and while active, the ability wheel was blocked from opening.

Additionally, per Lead review of TLF-059, the 3 handoff screenshots for Beat 10 (`doc_beat10_cinematic_start.png`, `doc_beat10_cinematic_mid.png`, `doc_beat10_cinematic_end.png`) were replaced with real distinct frames captured directly from the game viewport at pan offsets $x = 0, -320, -640$.

Key Deliverables:
1. **Auto-Advance Configuration (`arrival_platform.tscn`):**
   - Configured `auto_advance_delay = 4.0` on `pocket_watch_pickup` (matching the cadence of all other non-blocking monologue/memory lines such as `ch01_b01_start`).
2. **Interact Key Advancement (`dialogue_box.gd`):**
   - Enabled the `interact` action (`E`) to advance non-blocking dialogue when the player does not have a usable world target (`not _player_has_usable_target()`).
   - Disambiguation ensures that if the player faces a usable interactable object with `can_interact(actor, &"use") == &""`, the interact key triggers the object in the world without consuming the dialogue (preserving ADR-021 / TLF-038 behavior and passing `test_non_blocking_dialogue_does_not_consume_interact`).
3. **Dialogue Trigger Target Release (`dialogue_trigger.gd`):**
   - When a one-shot dialogue trigger has fired (`heard` or `flag_id` is set), `_can_use()` returns `&"unsupported"`. This prevents the player from maintaining an active `use` target on the spent pickup trigger after taking the watch, allowing immediate interact taps to advance the lines.
4. **AbilityWheel Modal Unblocking:**
   - While watch dialogue is active, `AbilityWheel._is_modal_open()` returns `true`, correctly suppressing wheel opening.
   - Once all lines advance or clear, `AbilityWheel` opens cleanly on real input.
5. **Real-Input Test Coverage (`tests/chapters/ch01/test_ch01_narrative_beats.gd`):**
   - Added `test_beat01_watch_pickup_real_input_interact_advance_and_unblock_wheel()` verifying the entire lifecycle: real walking to pickup, interact tap pickup, line 0 displayed, ability wheel blocked, interact tap advancing lines 0 -> 1 -> 2 -> finish, and ability wheel opening freely after clearance.
   - Updated `test_beat01_platform_awakening_and_watch_pickup()` asserting `auto_advance_delay == 4.0`.
6. **No Narrative Text Changes:**
   - Adhered strictly to ADR-022 D5: zero narrative keys added, deleted, or altered.

---

## 2. TLF-059 Screenshot Replacements

Per Lead direction, captured real D3D12/Forward+ frames of `res://scenes/ui/cinematics/ch01_outro.tscn` at exact integer pan coordinates:
- `docs/handoffs/TLF-059/doc_beat10_cinematic_start.png`: pan $x = 0$
- `docs/handoffs/TLF-059/doc_beat10_cinematic_mid.png`: pan $x = -320$
- `docs/handoffs/TLF-059/doc_beat10_cinematic_end.png`: pan $x = -640$ (clearly displaying Mira tower)

Pixel difference verification across frames:
- Pan 0 vs Pan -320: 63.36% pixel difference
- Pan -320 vs Pan -640: 58.22% pixel difference
- Pan 0 vs Pan -640: 54.37% pixel difference

---

## 3. Implementation Details

### 3.1 `scenes/chapters/ch01/rooms/arrival_platform.tscn`
```diff
@@ -130,6 +130,7 @@ collision_mask = 2
 script = ExtResource("6_trigger")
 sequence_id = &"ch01_b01_watch"
 lines = [["SPK_MEMORY", "MEM_WATCH_1"], ["SPK_MEMORY", "MEM_WATCH_2"], ["SPK_ELIAS", "EL_B01_04"]]
+auto_advance_delay = 4.0
 flag_id = &"ch01.flag.pocket_watch_acquired"
 object_id = &"global.pocket_watch"
```

### 3.2 `scripts/ui/dialogue_box.gd`
```gdscript
		elif event.is_action_pressed(&"interact") and not _player_has_usable_target():
			advance_line()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
...
func _player_has_usable_target() -> bool:
	if not is_inside_tree() or get_tree() == null:
		return false
	var player = get_tree().get_first_node_in_group(&"player")
	if player != null and "current_target" in player and player.current_target != null:
		var target = player.current_target
		if target is Interactable:
			var actor: StringName = player.actor_id if "actor_id" in player else &"player"
			if target.can_interact(actor, &"use") == &"":
				return true
	return false
```

### 3.3 `scripts/ui/dialogue_trigger.gd`
```gdscript
func _can_use(_actor_id: StringName, interaction_id: StringName, _payload: Dictionary) -> StringName:
	if interaction_id != &"use":
		return &"unsupported"
	if one_shot and _is_already_triggered():
		return &"unsupported"
	return &""


func _is_already_triggered() -> bool:
	var sess := get_session()
	if sess == null:
		sess = _find_session_in_tree()
	if sess != null and sess.narrative_state != null:
		if sequence_id != &"" and sess.narrative_state.get_flag(StringName("heard." + String(sequence_id)), false):
			return true
		if flag_id != &"" and sess.narrative_state.get_flag(flag_id, false):
			return true
	return false
```

---

## 4. Test Suite & Validation Results

Executed `tools/validate.ps1` from a clean scratch copy with `config/name="The Last Frame Val070"` (no BOM) against `D:\Godot\Godot_v4.7.2-stable_win64_console.exe`:

```
=== Validating The Last Frame Project ===
Using Godot executable: D:\Godot\Godot_v4.7.2-stable_win64_console.exe
Project root: C:\temp\tlf_val_070

[1/3] Running headless import check...
Import check passed with zero errors.

[2/3] Checking that every GDScript parses...
Script check: 160 scripts, 0 failed.
Leak check: clean (script check)

[3/3] Running headless automated test suite...
...
---------------------------
TESTS: 454 passed, 0 failed
Leak check: clean (test suite)

=== All validation checks passed successfully! ===
```
