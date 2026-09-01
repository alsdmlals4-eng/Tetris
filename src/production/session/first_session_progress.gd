## 첫 Deploy 전 규칙 읽기 완료 여부만 저장하는 최소 로컬 진행 기록이다.
class_name FirstSessionProgress
extends RefCounted

const DEFAULT_STORAGE_PATH := "user://first_session_progress.json"

var _storage_path: String

func _init(storage_path: String = DEFAULT_STORAGE_PATH) -> void:
	_storage_path = storage_path

func is_briefing_complete() -> bool:
	if not FileAccess.file_exists(_storage_path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(_storage_path))
	return parsed is Dictionary and bool(Dictionary(parsed).get("briefing_complete", false))

func mark_briefing_complete() -> bool:
	var file := FileAccess.open(_storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"briefing_complete": true}))
	file.close()
	return true

func reset_for_test() -> void:
	if FileAccess.file_exists(_storage_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_storage_path))
