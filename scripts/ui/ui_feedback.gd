class_name UIFeedback
extends RefCounted

## UI Feedback dictionary and translation registration per design/ch01/puzzles/README.md §2.3.

const REASON_TO_KEY: Dictionary = {
	&"missing_target": "UI_FB_MISSING_TARGET",
	&"echo_forbidden": "UI_FB_ECHO_FORBIDDEN",
	&"unsupported": "UI_FB_UNSUPPORTED",
	&"frozen": "UI_FB_FROZEN",
	&"no_history": "UI_FB_NO_HISTORY",
	&"already_open": "UI_FB_ALREADY_OPEN",
	&"unpowered": "UI_FB_UNPOWERED",
	&"invalid_graph": "UI_FB_INVALID_GRAPH",
	&"critical_path_unreachable": "UI_FB_CRITICAL_PATH",
	&"jammed": "UI_FB_JAMMED",
	&"cannot_affect": "UI_FB_CANNOT_AFFECT",
	&"echo_busy": "UI_FB_ECHO_BUSY",
	&"not_recording": "UI_FB_NOT_RECORDING",
	&"no_recording": "UI_FB_NO_RECORDING",
}

const DEFAULT_STRINGS: Dictionary = {
	"UI_FB_MISSING_TARGET": "Target is no longer present.",
	"UI_FB_ECHO_FORBIDDEN": "An echo cannot claim permanent items or records.",
	"UI_FB_UNSUPPORTED": "The pocket watch cannot affect this object.",
	"UI_FB_FROZEN": "Object is locked in time - unfreeze it first.",
	"UI_FB_NO_HISTORY": "No earlier temporal state recorded for this object.",
	"UI_FB_ALREADY_OPEN": "Already open.",
	"UI_FB_UNPOWERED": "No power to this mechanism.",
	"UI_FB_INVALID_GRAPH": "Route conflict - clear the active loop on the paired junction first.",
	"UI_FB_CRITICAL_PATH": "Safety interlock - cannot sever main entry route.",
	"UI_FB_JAMMED": "Mechanism is jammed.",
	"UI_FB_CANNOT_AFFECT": "The pocket watch cannot affect this object.",
	"UI_FB_ECHO_BUSY": "Echo is already busy.",
	"UI_FB_NOT_RECORDING": "Not currently recording an echo.",
	"UI_FB_NO_RECORDING": "No echo recorded to play back.",
	"PROMPT_USE": "Use",
	"PROMPT_INTERACT": "Interact",
	"PROMPT_WATCH": "Watch",
	"ABILITY_TRACE": "Trace",
	"ABILITY_REWIND": "Rewind",
	"ABILITY_FREEZE": "Freeze",
	"ABILITY_ECHO": "Echo",
	"ABILITY_FAST_FORWARD": "Fast-Forward",
}

static var _initialized: bool = false


## Ensures translations are added to TranslationServer for tr() lookups.
static func init_translations() -> void:
	if _initialized:
		return
	_initialized = true

	var tr_res = Translation.new()
	tr_res.locale = "en"
	for k in DEFAULT_STRINGS.keys():
		tr_res.add_message(StringName(k), DEFAULT_STRINGS[k])

	TranslationServer.add_translation(tr_res)
	TranslationServer.set_locale("en")


## Maps an InteractionResult reason code to localized feedback text via TranslationServer.
static func get_feedback_text(reason: StringName) -> String:
	init_translations()
	if reason == &"":
		return ""
	var key = REASON_TO_KEY.get(reason, "")
	if key != "":
		return String(TranslationServer.translate(StringName(key)))
	return String(TranslationServer.translate(StringName("UI_FB_" + String(reason).to_upper())))
