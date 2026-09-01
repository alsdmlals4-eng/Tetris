## 플레이어 LINE 보드 기회시간이 적 ETA와 분리된 저장·소비 경계를 지키는지 검증한다.
extends GutTest

const STATE_PATH := "res://src/production/runtime/player_board_opportunity_state.gd"

func _new_state():
	assert_true(ResourceLoader.exists(STATE_PATH), "PlayerBoardOpportunityState must own the LINE-only reserve")
	if not ResourceLoader.exists(STATE_PATH):
		return null
	return load(STATE_PATH).new()

func test_grant_caps_reserve_at_twelve_seconds_without_global_time_control() -> void:
	var opportunity = _new_state()
	if opportunity == null:
		return

	var first: Dictionary = opportunity.grant(11.0)
	var capped: Dictionary = opportunity.grant(5.0)

	assert_true(bool(first.get("granted", false)))
	assert_true(bool(capped.get("granted", false)))
	assert_almost_eq(float(capped.get("remaining_seconds", -1.0)), 12.0, 0.001)
	assert_almost_eq(opportunity.remaining_seconds(), 12.0, 0.001)

func test_partial_expiry_forwards_only_the_unheld_line_delta() -> void:
	var opportunity = _new_state()
	if opportunity == null:
		return

	opportunity.grant(0.25)
	var budget: Dictionary = opportunity.consume_line_delta(1.0)

	assert_almost_eq(float(budget.get("consumed_seconds", -1.0)), 0.25, 0.001)
	assert_almost_eq(float(budget.get("line_delta", -1.0)), 0.75, 0.001)
	assert_almost_eq(float(budget.get("remaining_seconds", -1.0)), 0.0, 0.001)

func test_restore_rejects_invalid_or_out_of_cap_state_without_mutation() -> void:
	var opportunity = _new_state()
	if opportunity == null:
		return

	opportunity.grant(3.0)
	var saved: Dictionary = opportunity.snapshot_state()
	opportunity.grant(2.0)

	assert_true(opportunity.restore_state(saved))
	assert_almost_eq(opportunity.remaining_seconds(), 3.0, 0.001)
	assert_false(opportunity.restore_state({}))
	assert_almost_eq(opportunity.remaining_seconds(), 3.0, 0.001)
	assert_false(opportunity.restore_state({"remaining_seconds": 12.1}))
	assert_almost_eq(opportunity.remaining_seconds(), 3.0, 0.001)

func test_grant_rejects_non_finite_seconds_without_corrupting_the_reserve() -> void:
	var opportunity = _new_state()
	if opportunity == null:
		return

	opportunity.grant(3.0)
	var infinite_result: Dictionary = opportunity.grant(INF)
	var nan_result: Dictionary = opportunity.grant(NAN)

	assert_false(bool(infinite_result.get("granted", true)))
	assert_false(bool(nan_result.get("granted", true)))
	assert_almost_eq(opportunity.remaining_seconds(), 3.0, 0.001)
