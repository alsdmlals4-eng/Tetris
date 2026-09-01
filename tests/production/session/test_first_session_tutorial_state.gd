## 첫 실전 연습이 실제 이벤트만 관찰하고 첫 CONFIRM 뒤 자유 전투로 넘기는지 검증한다.
extends GutTest

const TUTORIAL_PATH := "res://src/production/session/first_session_tutorial_state.gd"

func test_tutorial_tracks_real_rewards_preview_and_confirm_without_owning_simulation() -> void:
	assert_true(ResourceLoader.exists(TUTORIAL_PATH), "FirstSessionTutorialState must exist for the safe real encounter handoff")
	if not ResourceLoader.exists(TUTORIAL_PATH):
		return
	var tutorial = load(TUTORIAL_PATH).new()
	assert_true(tutorial.should_use_safe_opening())
	var opening_events: Array = tutorial.begin()
	assert_eq(String(opening_events[0].get("kind", "")), "TUTORIAL_SAFE_OPENING_STARTED")
	assert_eq(tutorial.current_step(), "READ_THREAT", "The opening should first point at the live telegraph")
	assert_true(tutorial.is_nonterminal_guard_active())
	var observed: Array = tutorial.observe([
		{"kind": "production_line_resolved"},
		{"kind": "production_chain_resolved"},
		{"kind": "TECHNIQUE_PREVIEWED"},
		{"kind": "TECHNIQUE_USED"},
	])
	assert_true(observed.any(func(event): return String(event.get("step", "")) == "READ_THREAT"), "The first real board reward should close the threat-reading prompt")
	assert_true(observed.any(func(event): return String(event.get("kind", "")) == "TUTORIAL_FREE_PLAY_STARTED"))
	assert_true(tutorial.is_free_play())
	assert_false(tutorial.is_nonterminal_guard_active())
