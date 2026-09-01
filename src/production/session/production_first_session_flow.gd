## 첫 Frontier Gate 진입에서 규칙 확인과 Deploy 경계를 소유한다.
class_name ProductionFirstSessionFlow
extends RefCounted

const TITLE_SCENE_PATH := "res://scenes/production/title.tscn"
const BRIEFING_SCENE_PATH := "res://scenes/production/battle_briefing.tscn"
const BATTLE_SCENE_PATH := "res://scenes/production/battle.tscn"

var _rules_acknowledged := false

func start_briefing() -> String:
	return BRIEFING_SCENE_PATH

func acknowledge_rules() -> void:
	_rules_acknowledged = true

func can_deploy() -> bool:
	return _rules_acknowledged

func deploy() -> Dictionary:
	if not can_deploy():
		return {"accepted": false, "reason": "RULES_NOT_ACKNOWLEDGED"}
	return {"accepted": true, "scene_path": BATTLE_SCENE_PATH}
