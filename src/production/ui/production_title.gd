## 타이틀은 첫 전투 전에 규칙이 있는 Briefing으로만 진입시킨다.
class_name ProductionTitle
extends Control

const FLOW_SCRIPT := preload("res://src/production/session/production_first_session_flow.gd")

@onready var _field_note: Label = $Margin/Panel/Content/FieldNote

func _ready() -> void:
	$Margin/Panel/Content/BeginBriefing.pressed.connect(_open_briefing)
	$Margin/Panel/Content/FieldManual.pressed.connect(_toggle_field_note)

func _open_briefing() -> void:
	var flow = FLOW_SCRIPT.new()
	get_tree().change_scene_to_file(flow.start_briefing())

func _toggle_field_note() -> void:
	_field_note.visible = not _field_note.visible
