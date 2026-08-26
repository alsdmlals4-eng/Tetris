## 전술 스킬의 짧은 버프와 디버프 스택을 보관한다.
class_name ProductionStatusState
extends RefCounted

var _stacks: Dictionary = {}

func apply_status(status_id: String, stacks: int = 1) -> bool:
	if status_id == "" or stacks <= 0:
		return false
	_stacks[status_id] = int(_stacks.get(status_id, 0)) + stacks
	return true

func has_status(status_id: String) -> bool:
	return int(_stacks.get(status_id, 0)) > 0

func status_stacks(status_id: String) -> int:
	return int(_stacks.get(status_id, 0))
