## 적 행동에 결속된 방어 반응 checkpoint가 비정상 복원을 거부하는지 검증한다.
extends GutTest

const RESPONSE_STATE_PATH := "res://src/production/combat/production_response_state.gd"

func test_response_checkpoint_restores_exact_action_state_and_rejects_out_of_range_ratios() -> void:
	var script = load(RESPONSE_STATE_PATH)
	assert_not_null(script)
	if script == null:
		return
	var response = script.new()
	assert_true(response.configure_direct_mitigation("gatebreaker_slam", 18))
	var snapshot: Dictionary = response.snapshot_action_state()
	assert_true(response.configure_counter("gatebreaker_slam", 0.4))
	assert_true(response.restore_action_state(snapshot))
	assert_eq(response.modifiers_for_action("gatebreaker_slam"), {"direct_mitigation": 18, "counter_ratio": 0.0, "resource_ward_ratio": 0.0, "lethal_hp_floor": 0, "lethal_charges": 0})
	var before_invalid: Dictionary = response.snapshot_action_state()
	var invalid := before_invalid.duplicate(true)
	invalid["counter_ratio"] = 1.2
	assert_false(response.restore_action_state(invalid))
	assert_eq(response.snapshot_action_state(), before_invalid)
