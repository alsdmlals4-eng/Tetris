## 같은 실전 전투 안에서 첫 LINE/CHAIN/Skill 확정을 안내하는 최소 상태를 보호한다.
extends GutTest

const GUIDED_PRACTICE_PATH := "res://src/production/session/production_guided_practice_state.gd"

func test_guided_practice_tracks_real_puzzle_and_skill_evidence_in_order() -> void:
	assert_true(ResourceLoader.exists(GUIDED_PRACTICE_PATH), "the first encounter needs a reusable guided-practice owner")
	if not ResourceLoader.exists(GUIDED_PRACTICE_PATH):
		return
	var guided = load(GUIDED_PRACTICE_PATH).new()
	var started: Dictionary = guided.begin()
	assert_true(bool(started.get("started", false)))
	assert_true(guided.has_method("opening_eta_seconds"), "the shared opening timer needs an explicit guided-practice owner")
	assert_almost_eq(float(guided.opening_eta_seconds()), 28.0, 0.001)
	assert_eq(String(guided.snapshot().get("phase", "")), "LINE_REWARD")
	assert_true(guided.opening_guard_active(), "the authored opening protects the player only before the first CONFIRM")
	assert_true(String(guided.snapshot().get("prompt", "")).contains("CURRENT THREAT"))

	guided.observe_combat_events([{"kind": "production_line_resolved"}])
	assert_eq(String(guided.snapshot().get("phase", "")), "CHAIN_REWARD")
	guided.observe_combat_events([{"kind": "production_chain_resolved"}])
	assert_eq(String(guided.snapshot().get("phase", "")), "SKILL_PREVIEW")
	guided.record_skill_preview({"selected": true, "ready": true})
	assert_eq(String(guided.snapshot().get("phase", "")), "SKILL_CONFIRM")
	guided.record_skill_confirmation({"committed": true})
	assert_eq(String(guided.snapshot().get("phase", "")), "FREE_COMBAT")
	assert_false(guided.opening_guard_active())
	assert_true(bool(guided.snapshot().get("completed", false)))
