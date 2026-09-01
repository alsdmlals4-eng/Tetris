## 플레이어 LINE 보드의 gravity·lock 진행만 보류하는 제한 시간 보관소다.
class_name PlayerBoardOpportunityState
extends RefCounted

const MAX_SECONDS: float = 12.0

var _remaining_seconds: float = 0.0

func grant(seconds: float) -> Dictionary:
	if seconds <= 0.0:
		return {"granted": false, "reason": "INVALID_DURATION", "remaining_seconds": _remaining_seconds}
	var before := _remaining_seconds
	_remaining_seconds = minf(MAX_SECONDS, _remaining_seconds + seconds)
	return {
		"granted": _remaining_seconds > before,
		"granted_seconds": _remaining_seconds - before,
		"remaining_seconds": _remaining_seconds,
	}

func consume_line_delta(delta: float) -> Dictionary:
	var requested := maxf(delta, 0.0)
	var consumed := minf(requested, _remaining_seconds)
	_remaining_seconds = maxf(0.0, _remaining_seconds - consumed)
	return {
		"line_delta": requested - consumed,
		"consumed_seconds": consumed,
		"remaining_seconds": _remaining_seconds,
	}

func remaining_seconds() -> float:
	return _remaining_seconds

func snapshot_state() -> Dictionary:
	return {"remaining_seconds": _remaining_seconds}

func restore_state(snapshot: Dictionary) -> bool:
	if not snapshot.has("remaining_seconds"):
		return false
	var raw_remaining = snapshot.get("remaining_seconds")
	if not (raw_remaining is int or raw_remaining is float):
		return false
	var restored := float(raw_remaining)
	if restored != restored or restored < 0.0 or restored > MAX_SECONDS:
		return false
	_remaining_seconds = restored
	return true
