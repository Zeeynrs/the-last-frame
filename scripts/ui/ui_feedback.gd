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
	&"no_active_puzzle": "UI_FB_NO_ACTIVE_PUZZLE",
	&"already_solved": "UI_FB_ALREADY_SOLVED",
	&"unknown_puzzle": "UI_FB_UNKNOWN_PUZZLE",
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
	"UI_FB_NO_ACTIVE_PUZZLE": "No active puzzle in this area.",
	"UI_FB_ALREADY_SOLVED": "This puzzle is already solved.",
	"UI_FB_UNKNOWN_PUZZLE": "No puzzle records found.",
	"PROMPT_USE": "Use",
	"PROMPT_INTERACT": "Interact",
	"PROMPT_WATCH": "Watch",
	"UI_PROMPT_HINT": "Hint",
	"ABILITY_TRACE": "Trace",
	"ABILITY_REWIND": "Rewind",
	"ABILITY_FREEZE": "Freeze",
	"ABILITY_ECHO": "Echo",
	"ABILITY_FAST_FORWARD": "Fast-Forward",
	"UI_DOC_CLOSE": "Close",
	"UI_DOC_NEXT": "Next",
	"UI_DOC_PREV": "Prev",
	"UI_DOC_PAGE": "Page %d of %d",
	"UI_JOURNAL_TITLE": "INVESTIGATION JOURNAL",
	"UI_JOURNAL_TAB_LOG": "Journal",
	"UI_JOURNAL_TAB_FRAGMENTS": "Memory Fragments",
	"UI_JOURNAL_CAT_OBSERVATION": "Observations",
	"UI_JOURNAL_CAT_FACT": "Confirmed Facts",
	"UI_JOURNAL_CAT_THEORY": "Unresolved Theories",
	"UI_JOURNAL_EMPTY": "No journal entries recorded.",
	"UI_FRAGMENTS_EMPTY": "No memory fragments recovered.",
	"UI_JOURNAL_CLOSE": "Close",
	"UI_DIALOGUE_ADVANCE": "Continue",
	"UI_CHAPTER_COMPLETE": "CHAPTER 1 COMPLETE",
	"UI_CHAPTER_01_TITLE": "THE FORGOTTEN STATION",
	"UI_FB_USE_UNSUPPORTED": "Nothing happens.",
	"UI_HINT_MOVE": "Move: %s",
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
## Accepts optional context (&"watch" or &"use") to disambiguate unsupported feedback.
static func get_feedback_text(reason: StringName, context: StringName = &"watch") -> String:
	init_translations()
	if reason == &"":
		return ""
	if context == &"use" and reason == &"unsupported":
		return String(TranslationServer.translate(&"UI_FB_USE_UNSUPPORTED"))
	var key = REASON_TO_KEY.get(reason, "")
	if key != "":
		return String(TranslationServer.translate(StringName(key)))
	return String(TranslationServer.translate(StringName("UI_FB_" + String(reason).to_upper())))
