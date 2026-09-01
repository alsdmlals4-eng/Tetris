## 실제 전투 시작 전 전체 규칙을 한 번 읽게 하는 짧은 Frontier Gate 브리핑이다.
class_name BattleBriefing
extends Control

const BRIEFING_DATA_PATH := "res://data/production/first_session_briefing_seed.json"
const BATTLE_SCENE_PATH := "res://scenes/production/battle.tscn"
const PROGRESS_SCRIPT = preload("res://src/production/session/first_session_progress.gd")

signal deployed
signal dismissed

@onready var deploy_button: Button = $BriefingFrame/BriefingLayout/DeployButton
@onready var rules_scroll: ScrollContainer = $BriefingFrame/BriefingLayout/RulesScroll
@onready var _title_label: Label = $BriefingFrame/BriefingLayout/Title
@onready var _threat_label: Label = $BriefingFrame/BriefingLayout/Threat
@onready var _rules_text: RichTextLabel = $BriefingFrame/BriefingLayout/RulesScroll/RulesText
@onready var _gate_label: Label = $BriefingFrame/BriefingLayout/GateStatus

var _progress = PROGRESS_SCRIPT.new()
var _reference_mode := false
var _transition_enabled := true

func _ready() -> void:
	deploy_button.pressed.connect(_on_deploy_pressed)
	rules_scroll.get_v_scroll_bar().value_changed.connect(func(_value: float): _on_rules_scrolled())
	_load_seed_copy()
	_apply_configuration()
	call_deferred("_on_rules_scrolled")

func configure(reference_mode: bool = false) -> void:
	_reference_mode = reference_mode
	if is_inside_tree():
		_apply_configuration()

func set_progress_for_test(progress) -> void:
	_progress = progress
	_transition_enabled = false
	if is_inside_tree():
		_apply_configuration()

func _on_rules_scrolled() -> void:
	if _reference_mode or _progress.is_briefing_complete():
		deploy_button.disabled = false
		_gate_label.text = "REFERENCE READY" if _reference_mode else "RULES REVIEW COMPLETE"
		return
	var bar := rules_scroll.get_v_scroll_bar()
	var reached_end := bar.max_value <= 0.0 or bar.value + bar.page >= bar.max_value - 1.0
	deploy_button.disabled = not reached_end
	_gate_label.text = "RULES REVIEW COMPLETE · DEPLOY READY" if reached_end else "FIRST DEPLOY · READ TO THE END TO UNLOCK"

func _on_deploy_pressed() -> void:
	if deploy_button.disabled:
		return
	if _reference_mode:
		dismissed.emit()
		return
	var first_deploy: bool = not _progress.is_briefing_complete()
	if not _progress.mark_briefing_complete():
		_gate_label.text = "LOCAL PROGRESS WRITE FAILED · DEPLOY BLOCKED"
		return
	if first_deploy:
		var launch_state = get_tree().root.get_node_or_null("FirstSessionLaunch")
		if launch_state != null and launch_state.has_method("request_tutorial_handoff"):
			launch_state.request_tutorial_handoff()
	deployed.emit()
	if _transition_enabled:
		call_deferred("_change_to_battle")

func _change_to_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func _apply_configuration() -> void:
	if not is_node_ready():
		return
	deploy_button.text = "CLOSE REFERENCE" if _reference_mode else "DEPLOY · START LIVE ETA"
	_on_rules_scrolled()

func _load_seed_copy() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(BRIEFING_DATA_PATH))
	if not (parsed is Dictionary):
		_title_label.text = "FRONTIER GATE · BRIEFING UNAVAILABLE"
		_threat_label.text = "Rules data could not be read."
		_rules_text.text = ""
		return
	var seed: Dictionary = parsed
	_title_label.text = String(seed.get("title", "FRONTIER GATE · BATTLE BRIEFING"))
	_threat_label.text = String(seed.get("threat", "Gatebreaker threat detected."))
	var sections: Array = seed.get("rule_sections", [])
	var lines: Array[String] = []
	for section_variant in sections:
		if not (section_variant is Dictionary):
			continue
		var section: Dictionary = section_variant
		lines.append("[b]%s[/b]" % String(section.get("heading", "RULE")))
		lines.append(String(section.get("body", "")))
		lines.append("")
	_rules_text.text = "\n".join(lines)
