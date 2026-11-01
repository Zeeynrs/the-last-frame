class_name ChapterCompleteOverlay
extends CanvasLayer

## Chapter Complete Overlay (TLF-051).
## Displays "CHAPTER 1 COMPLETE" (HeaderLarge, 24 px),
## "THE FORGOTTEN STATION" (HeaderMedium, 16 px),
## and playtest summary (theme default 8 px inside a theme-styled PanelContainer)
## on the 4 px grid with >= 12 px safe margins, leaving clear space at the bottom
## for the SceneRouter hint (y=320..340).

var _summary_lines: PackedStringArray = PackedStringArray()
var _has_summary: bool = false
var _setup_called: bool = false


func _ready() -> void:
	_update_localized_text()
	if _setup_called:
		_apply_summary()


func _update_localized_text() -> void:
	var title_lbl := get_node_or_null("VBox/Title") as Label
	if title_lbl != null:
		title_lbl.text = tr("UI_CHAPTER_COMPLETE")

	var ch_lbl := get_node_or_null("VBox/ChapterName") as Label
	if ch_lbl != null:
		ch_lbl.text = tr("UI_CHAPTER_01_TITLE")

	var compat_lbl := get_node_or_null("TitleLabel") as Label
	if compat_lbl != null:
		compat_lbl.text = "%s\n%s" % [tr("UI_CHAPTER_COMPLETE"), tr("UI_CHAPTER_01_TITLE")]


func setup(summary_lines: PackedStringArray = PackedStringArray()) -> void:
	_setup_called = true
	_summary_lines = summary_lines
	_has_summary = not summary_lines.is_empty()
	_update_localized_text()
	_apply_summary()


func _apply_summary() -> void:
	var panel := get_node_or_null("VBox/SummaryPanel") as PanelContainer
	var summary_lbl := get_node_or_null("VBox/SummaryPanel/SummaryMargin/SummaryScroll/PlaytestSummary") as Label
	var vbox := get_node_or_null("VBox") as VBoxContainer

	if not _has_summary:
		if panel != null:
			if panel.get_parent() != null:
				panel.get_parent().remove_child(panel)
			panel.queue_free()
		if vbox != null:
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		if summary_lbl != null:
			summary_lbl.text = "\n".join(_summary_lines)
		if vbox != null:
			vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
