## Briefing은 전투 규칙을 확인한 다음에만 동일 전투 씬으로 Deploy한다.
class_name ProductionBattleBriefing
extends Control

const FLOW_SCRIPT := preload("res://src/production/session/production_first_session_flow.gd")

var _flow = FLOW_SCRIPT.new()

@onready var _acknowledge_button: Button = $Margin/Panel/Content/AcknowledgeRules
@onready var _deploy_button: Button = $Margin/Panel/Content/Deploy
@onready var _acknowledgement: Label = $Margin/Panel/Content/Acknowledgement

func _ready() -> void:
	_acknowledge_button.pressed.connect(_acknowledge_rules)
	_deploy_button.pressed.connect(_deploy)
	_refresh_deploy_state()

func _acknowledge_rules() -> void:
	_flow.acknowledge_rules()
	_acknowledgement.text = "RULES CONFIRMED · DEPLOY WHEN READY"
	_refresh_deploy_state()

func _deploy() -> void:
	var result: Dictionary = _flow.deploy()
	if bool(result.get("accepted", false)):
		get_tree().change_scene_to_file(String(result.get("scene_path", "")))

func _refresh_deploy_state() -> void:
	_deploy_button.disabled = not _flow.can_deploy()
