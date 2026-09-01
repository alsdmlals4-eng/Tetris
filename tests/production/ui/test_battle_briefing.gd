## 첫 방문의 전체 규칙 읽기와 이후 즉시 Deploy를 검증한다.
extends GutTest

const BRIEFING_SCENE_PATH := "res://scenes/production/battle_briefing.tscn"
const PROGRESS_PATH := "res://src/production/session/first_session_progress.gd"
const TEST_STORAGE_PATH := "user://tetris_battle_briefing_gut_test.json"

func _briefing():
	var scene = load(BRIEFING_SCENE_PATH)
	assert_not_null(scene)
	if scene == null:
		return null
	var briefing = scene.instantiate()
	add_child_autofree(briefing)
	return briefing

func test_first_visit_requires_full_rules_review_but_later_visit_can_deploy_immediately() -> void:
	assert_true(ResourceLoader.exists(BRIEFING_SCENE_PATH), "BattleBriefing must become the explicit first-session entry")
	assert_true(ResourceLoader.exists(PROGRESS_PATH), "BattleBriefing requires the minimal completion record")
	if not ResourceLoader.exists(BRIEFING_SCENE_PATH) or not ResourceLoader.exists(PROGRESS_PATH):
		return
	var progress = load(PROGRESS_PATH).new(TEST_STORAGE_PATH)
	progress.reset_for_test()
	var briefing = _briefing()
	if briefing == null:
		return
	briefing.set_progress_for_test(progress)
	briefing.configure()
	assert_true(briefing.deploy_button.disabled)
	briefing.rules_scroll.scroll_vertical = briefing.rules_scroll.get_v_scroll_bar().max_value
	briefing._on_rules_scrolled()
	assert_false(briefing.deploy_button.disabled)
	briefing._on_deploy_pressed()
	assert_true(progress.is_briefing_complete())
	var revisit = _briefing()
	if revisit == null:
		return
	revisit.set_progress_for_test(progress)
	revisit.configure()
	assert_false(revisit.deploy_button.disabled)
	progress.reset_for_test()

func test_reference_mode_never_marks_first_session_progress() -> void:
	if not ResourceLoader.exists(BRIEFING_SCENE_PATH) or not ResourceLoader.exists(PROGRESS_PATH):
		return
	var progress = load(PROGRESS_PATH).new(TEST_STORAGE_PATH)
	progress.reset_for_test()
	var briefing = _briefing()
	if briefing == null:
		return
	briefing.set_progress_for_test(progress)
	briefing.configure(true)
	assert_false(briefing.deploy_button.disabled)
	briefing._on_deploy_pressed()
	assert_false(progress.is_briefing_complete())
