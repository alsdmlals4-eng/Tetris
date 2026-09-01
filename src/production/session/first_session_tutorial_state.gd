## 첫 실전의 실제 이벤트만 관찰하고 첫 CONFIRM 뒤 자유 전투로 넘긴다.
class_name FirstSessionTutorialState
extends RefCounted

const STEPS: Array[String] = ["READ_THREAT", "LINE_REWARD", "CHAIN_REWARD", "SKILL_PREVIEW", "SKILL_CONFIRM", "FREE_PLAY"]

var _started := false
var _free_play := false
var _completed: Dictionary = {}

func should_use_safe_opening() -> bool:
	return not _started

func begin() -> Array[Dictionary]:
	if _started:
		return []
	_started = true
	return [{"kind": "TUTORIAL_SAFE_OPENING_STARTED", "step": current_step()}]

func observe(events: Array) -> Array[Dictionary]:
	var observed: Array[Dictionary] = []
	for event_variant in events:
		if not (event_variant is Dictionary):
			continue
		match String(Dictionary(event_variant).get("kind", "")):
			"production_line_resolved":
				_append_completion(observed, "READ_THREAT")
				_append_completion(observed, "LINE_REWARD")
			"production_chain_resolved":
				_append_completion(observed, "CHAIN_REWARD")
			"TECHNIQUE_PREVIEWED":
				_append_completion(observed, "SKILL_PREVIEW")
			"TECHNIQUE_USED":
				_append_completion(observed, "SKILL_CONFIRM")
				if not _free_play:
					_free_play = true
					_completed["FREE_PLAY"] = true
					observed.append({"kind": "TUTORIAL_FREE_PLAY_STARTED", "step": "FREE_PLAY"})
	return observed

func is_nonterminal_guard_active() -> bool:
	return _started and not _free_play

func is_free_play() -> bool:
	return _free_play

func current_step() -> String:
	for step in STEPS:
		if not bool(_completed.get(step, false)):
			return step
	return "FREE_PLAY"

func _append_completion(observed: Array[Dictionary], step: String) -> void:
	if bool(_completed.get(step, false)):
		return
	_completed[step] = true
	observed.append({"kind": "TUTORIAL_STEP_COMPLETED", "step": step})
