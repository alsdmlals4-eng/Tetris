## 브리핑에서 실제 첫 Deploy로 넘기는 한 번짜리 튜토리얼 의도만 보관한다.
class_name FirstSessionLaunchState
extends Node

var _tutorial_pending := false

func request_tutorial_handoff() -> void:
	_tutorial_pending = true

func consume_tutorial_handoff() -> bool:
	var pending := _tutorial_pending
	_tutorial_pending = false
	return pending
