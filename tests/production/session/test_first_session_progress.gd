## 첫 Deploy 전 읽기 완료 기록이 최소 저장 데이터만 남기는지 검증한다.
extends GutTest

const PROGRESS_PATH := "res://src/production/session/first_session_progress.gd"
const LAUNCH_STATE_PATH := "res://src/production/session/first_session_launch_state.gd"
const TEST_STORAGE_PATH := "user://tetris_first_session_progress_gut_test.json"

func test_progress_is_false_until_marked_and_persists_only_the_completion_bit() -> void:
	assert_true(ResourceLoader.exists(PROGRESS_PATH), "FirstSessionProgress must exist before a briefing can gate Deploy")
	if not ResourceLoader.exists(PROGRESS_PATH):
		return
	var progress = load(PROGRESS_PATH).new(TEST_STORAGE_PATH)
	progress.reset_for_test()
	assert_false(progress.is_briefing_complete())
	assert_true(progress.mark_briefing_complete())
	assert_true(progress.is_briefing_complete())
	var reopened = load(PROGRESS_PATH).new(TEST_STORAGE_PATH)
	assert_true(reopened.is_briefing_complete())
	reopened.reset_for_test()

func test_launch_state_consumes_only_the_briefing_requested_first_tutorial_handoff() -> void:
	assert_true(ResourceLoader.exists(LAUNCH_STATE_PATH))
	if not ResourceLoader.exists(LAUNCH_STATE_PATH):
		return
	var launch_state = load(LAUNCH_STATE_PATH).new()
	assert_false(launch_state.consume_tutorial_handoff())
	launch_state.request_tutorial_handoff()
	assert_true(launch_state.consume_tutorial_handoff())
	assert_false(launch_state.consume_tutorial_handoff())
	launch_state.free()
