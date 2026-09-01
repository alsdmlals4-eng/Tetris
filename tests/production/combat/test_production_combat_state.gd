## ProductionCombatState의 MP·Combo 원자적 자원 계약을 검증한다.
extends GutTest

const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"

func _make_state():
	assert_true(ResourceLoader.exists(COMBAT_STATE_PATH), "ProductionCombatState script must exist")
	if not ResourceLoader.exists(COMBAT_STATE_PATH):
		return null
	return load(COMBAT_STATE_PATH).new(100)

func test_chain_wave_caps_combo_and_mp_after_awarding_combo_first() -> void:
	var state = _make_state()
	if state == null:
		return
	state.energy = 58
	state.stock = 9

	var line_lengths: Array[int] = [5, 5]
	var event: Dictionary = state.apply_chain_wave(line_lengths)

	assert_eq(event["combo_before"], 9)
	assert_eq(event["combo_after"], 10)
	assert_eq(event["mp_requested"], 17)
	assert_eq(event["mp_applied"], 2)
	assert_eq(event["mp_lost_at_cap"], 15)
	assert_eq(state.energy, 60)
	assert_eq(state.stock, 10)

func test_crossing_maximal_lines_award_twelve_mp_at_combo_four() -> void:
	var state = _make_state()
	if state == null:
		return
	state.energy = 0
	state.stock = 4

	var line_lengths: Array[int] = [5, 5]
	var event: Dictionary = state.apply_chain_wave(line_lengths)

	assert_eq(event["combo_after"], 5)
	assert_eq(event["mp_requested"], 12)
	assert_eq(state.energy, 12)
	assert_eq(state.stock, 5)

func test_shortage_fallback_converts_only_surplus_combo_then_spends_opening_combo_once() -> void:
	var state = _make_state()
	if state == null:
		return
	state.energy = 13
	state.stock = 5

	var result: Dictionary = state.try_commit_combo_skill(18, 5, 4)

	assert_true(result["committed"])
	assert_eq(result["resolved_stage"], 4)
	assert_eq(result["converted_combo"], 1)
	assert_eq(result["mp_spent"], 18)
	assert_eq(result["combo_spent"], 5)
	assert_eq(state.energy, 0)
	assert_eq(state.stock, 0)

func test_invalid_combo_transaction_leaves_mp_and_combo_unchanged() -> void:
	var state = _make_state()
	if state == null:
		return
	state.energy = 12
	state.stock = 3

	var result: Dictionary = state.try_commit_combo_skill(14, 2, 2)

	assert_false(result["committed"])
	assert_eq(result["reason"], "INVALID_COMBO_TRANSACTION")
	assert_eq(state.energy, 12)
	assert_eq(state.stock, 3)

func test_fixed_mp_spend_never_allows_negative_energy() -> void:
	var state = _make_state()
	if state == null:
		return
	state.energy = 1

	assert_true(state.try_spend_mp(1))
	assert_eq(state.energy, 0)
	assert_false(state.try_spend_mp(1))
	assert_eq(state.energy, 0)

func test_reset_combo_returns_previous_value_and_clears_state() -> void:
	var state = _make_state()
	if state == null:
		return
	state.stock = 4

	assert_eq(state.reset_combo(), 4)
	assert_eq(state.stock, 0)

func test_checked_state_and_resource_snapshots_restore_only_valid_same_capacity_values() -> void:
	var state = _make_state()
	if state == null:
		return
	assert_true(state.has_method("snapshot_state"))
	assert_true(state.has_method("restore_state"))
	assert_true(state.has_method("resource_snapshot"))
	assert_true(state.has_method("restore_resource_snapshot"))
	if not state.has_method("snapshot_state"):
		return
	state.hp = 55
	state.energy = 20
	state.stock = 4
	var state_snapshot: Dictionary = state.snapshot_state()
	var resource_snapshot: Dictionary = state.resource_snapshot()
	state.hp = 10
	state.energy = 1
	state.stock = 0
	assert_true(state.restore_state(state_snapshot))
	assert_eq(state.hp, 55)
	assert_eq(state.energy, 20)
	assert_eq(state.stock, 4)
	state.energy = 2
	state.stock = 1
	assert_true(state.restore_resource_snapshot(resource_snapshot))
	assert_eq(state.energy, 20)
	assert_eq(state.stock, 4)
	assert_false(state.restore_state({"max_hp": 101, "hp": 55, "energy": 20, "stock": 4}))
	assert_eq(state.max_hp, 100)
	assert_eq(state.hp, 55)
