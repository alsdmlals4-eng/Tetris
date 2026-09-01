## 첫 전투의 실시간 압박을 유지한 채, 실제 행동으로 핵심 규칙을 안내한다.
class_name ProductionGuidedPracticeState
extends RefCounted

var _started := false
var _saw_line_reward := false
var _saw_chain_reward := false
var _saw_skill_preview := false
var _saw_skill_confirm := false

func opening_eta_seconds() -> float:
	return 28.0

func begin() -> Dictionary:
	if _started:
		return {"started": false, "reason": "ALREADY_STARTED", "prompt": prompt()}
	_started = true
	return {"started": true, "phase": phase(), "prompt": prompt()}

func observe_combat_events(events: Array) -> Dictionary:
	var before := phase()
	for event in events:
		if not event is Dictionary:
			continue
		match String(event.get("kind", "")):
			"production_line_resolved":
				_saw_line_reward = true
			"production_chain_resolved":
				_saw_chain_reward = true
	return _progress_result(before)

func record_skill_preview(result: Dictionary) -> Dictionary:
	var before := phase()
	if bool(result.get("selected", false)) and bool(result.get("ready", false)):
		_saw_skill_preview = true
	return _progress_result(before)

func record_skill_confirmation(result: Dictionary) -> Dictionary:
	var before := phase()
	if bool(result.get("committed", false)):
		_saw_skill_confirm = true
	return _progress_result(before)

func opening_guard_active() -> bool:
	return _started and not _saw_skill_confirm

func is_active() -> bool:
	return _started and not completed()

func completed() -> bool:
	return _saw_line_reward and _saw_chain_reward and _saw_skill_preview and _saw_skill_confirm

func phase() -> String:
	if not _started:
		return "NOT_STARTED"
	if not _saw_line_reward:
		return "LINE_REWARD"
	if not _saw_chain_reward:
		return "CHAIN_REWARD"
	if not _saw_skill_preview:
		return "SKILL_PREVIEW"
	if not _saw_skill_confirm:
		return "SKILL_CONFIRM"
	return "FREE_COMBAT"

func prompt() -> String:
	match phase():
		"LINE_REWARD":
			return "GUIDED 1/4 · READ CURRENT THREAT / ETA, THEN CLEAR LINE FOR MP"
		"CHAIN_REWARD":
			return "GUIDED 2/4 · SWITCH TO CHAIN · MAKE A STRAIGHT 3+ MATCH FOR COMBO"
		"SKILL_PREVIEW":
			return "GUIDED 3/4 · OPEN SKILL · INSPECT ONE ATK / DEF / SUP PREVIEW"
		"SKILL_CONFIRM":
			return "GUIDED 4/4 · CONFIRM THE PREVIEWED TECHNIQUE TO RESUME FULL PRESSURE"
		"FREE_COMBAT":
			return "GUIDED PRACTICE COMPLETE · THE GATEBREAKER FIGHT CONTINUES"
	return "GUIDED PRACTICE · BATTLE STARTING"

func snapshot() -> Dictionary:
	return {
		"started": _started,
		"active": is_active(),
		"completed": completed(),
		"opening_guard_active": opening_guard_active(),
		"opening_eta_seconds": opening_eta_seconds(),
		"phase": phase(),
		"prompt": prompt(),
		"line_reward_seen": _saw_line_reward,
		"chain_reward_seen": _saw_chain_reward,
		"skill_preview_seen": _saw_skill_preview,
		"skill_confirm_seen": _saw_skill_confirm,
	}

func _progress_result(before_phase: String) -> Dictionary:
	var current_phase := phase()
	return {
		"advanced": before_phase != current_phase,
		"phase": current_phase,
		"prompt": prompt(),
		"completed": completed(),
	}
