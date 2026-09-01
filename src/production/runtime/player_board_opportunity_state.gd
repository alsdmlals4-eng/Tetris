## 플레이어 LINE 중력과 락만 보류하는 제한된 보드 기회시간을 소유한다.
class_name PlayerBoardOpportunityState
extends RefCounted

const MAX_STORED_SECONDS: float = 12.0

var _remaining_seconds: float = 0.0

func grant(seconds: float) -> Dictionary:
	if is_nan(seconds) or is_inf(seconds) or seconds <= 0.0:
		return {
			"granted": false,
			"reason": "INVALID_SECONDS",
			"granted_seconds": 0.0,
			"remaining_seconds": _remaining_seconds,
		}
	var before := _remaining_seconds
	_remaining_seconds = minf(MAX_STORED_SECONDS, _remaining_seconds + seconds)
	var granted_seconds := _remaining_seconds - before
	return {
		"granted": granted_seconds > 0.0,
		"granted_seconds": granted_seconds,
		"remaining_seconds": _remaining_seconds,
	}

func consume_line_delta(delta: float) -> Dictionary:
	if delta <= 0.0:
		return {
			"line_delta": 0.0,
			"consumed_seconds": 0.0,
			"remaining_seconds": _remaining_seconds,
		}
	var consumed_seconds := minf(delta, _remaining_seconds)
	_remaining_seconds = maxf(0.0, _remaining_seconds - consumed_seconds)
	return {
		"line_delta": delta - consumed_seconds,
		"consumed_seconds": consumed_seconds,
		"remaining_seconds": _remaining_seconds,
	}

func remaining_seconds() -> float:
	return _remaining_seconds

func snapshot_state() -> Dictionary:
	return {"remaining_seconds": _remaining_seconds}

func restore_state(snapshot: Dictionary) -> bool:
	if snapshot.size() != 1 or not snapshot.has("remaining_seconds"):
		return false
	var raw_remaining = snapshot["remaining_seconds"]
	if not (raw_remaining is int or raw_remaining is float):
		return false
	var restored := float(raw_remaining)
	if is_nan(restored) or is_inf(restored) or restored < 0.0 or restored > MAX_STORED_SECONDS:
		return false
	_remaining_seconds = restored
	return true
