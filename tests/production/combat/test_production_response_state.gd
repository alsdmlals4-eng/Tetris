## 행동에 묶인 방어 반응 상태의 체크포인트 복구를 검증한다.
extends GutTest

const RESPONSE_PATH := "res://src/production/combat/production_response_state.gd"

func test_action_response_snapshot_restores_only_the_same_action_state() -> void:
	var response = load(RESPONSE_PATH).new()
	var action_id := "gatebreaker:light_smash:1"
	assert_true(response.has_method("snapshot_action_state"))
	assert_true(response.has_method("restore_action_state"))
	if not response.has_method("snapshot_action_state"):
		return
	assert_true(response.configure_direct_mitigation(action_id, 20))
	var before: Dictionary = response.snapshot_action_state()
	assert_true(response.configure_counter(action_id, 0.5))
	assert_true(response.restore_action_state(before))
	assert_eq(response.modifiers_for_action(action_id).get("counter_ratio", -1.0), 0.0)
	assert_false(response.restore_action_state({}))
	assert_eq(response.modifiers_for_action(action_id).get("direct_mitigation", -1), 20)
