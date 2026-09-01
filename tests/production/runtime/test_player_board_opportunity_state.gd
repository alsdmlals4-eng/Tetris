## 플레이어 보드 기회 보관소가 LINE 시간만 독립적으로 보류하는지 검증한다.
extends GutTest

const OPPORTUNITY_PATH := "res://src/production/runtime/player_board_opportunity_state.gd"

func _new_opportunity():
	assert_true(ResourceLoader.exists(OPPORTUNITY_PATH), "PlayerBoardOpportunityState must exist")
	if not ResourceLoader.exists(OPPORTUNITY_PATH):
		return null
	var opportunity = load(OPPORTUNITY_PATH).new()
	for method_name in ["grant", "consume_line_delta", "remaining_seconds", "snapshot_state", "restore_state"]:
		assert_true(opportunity.has_method(method_name), "%s is required by the local LINE-time contract" % method_name)
	if not opportunity.has_method("grant") or not opportunity.has_method("consume_line_delta"):
		return null
	return opportunity

func test_opportunity_caps_at_twelve_and_partial_expiry_forwards_only_unheld_line_delta() -> void:
	var opportunity = _new_opportunity()
	if opportunity == null:
		return

	opportunity.grant(11.0)
	var capped: Dictionary = opportunity.grant(5.0)
	assert_almost_eq(float(capped.get("remaining_seconds", -1.0)), 12.0, 0.001)
	var short_window = _new_opportunity()
	if short_window == null:
		return
	short_window.grant(0.25)
	var budget: Dictionary = short_window.consume_line_delta(1.0)
	assert_almost_eq(float(budget.get("consumed_seconds", -1.0)), 0.25, 0.001)
	assert_almost_eq(float(budget.get("line_delta", -1.0)), 0.75, 0.001)
	assert_almost_eq(float(budget.get("remaining_seconds", -1.0)), 0.0, 0.001)

func test_opportunity_snapshot_restore_rejects_malformed_or_out_of_cap_state_without_mutation() -> void:
	var opportunity = _new_opportunity()
	if opportunity == null:
		return

	opportunity.grant(3.0)
	var snapshot: Dictionary = opportunity.snapshot_state()
	opportunity.grant(2.0)
	assert_true(opportunity.restore_state(snapshot))
	assert_almost_eq(float(opportunity.remaining_seconds()), 3.0, 0.001)
	assert_false(opportunity.restore_state({}))
	assert_almost_eq(float(opportunity.remaining_seconds()), 3.0, 0.001)
	assert_false(opportunity.restore_state({"remaining_seconds": 12.1}))
	assert_almost_eq(float(opportunity.remaining_seconds()), 3.0, 0.001)
