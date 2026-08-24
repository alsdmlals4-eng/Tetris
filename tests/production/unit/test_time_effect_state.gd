extends GutTest

const STATE_PATH := "res://src/production/status/time_effect_state.gd"
const BUDGET_PATH := "res://src/production/turn/turn_budget.gd"

func _make_state():
    assert_true(ResourceLoader.exists(STATE_PATH), "TimeEffectState script must exist")
    if not ResourceLoader.exists(STATE_PATH):
        return null
    return load(STATE_PATH).new()

func _make_budget():
    return load(BUDGET_PATH).new()

func test_default_haste_refreshes_same_non_stackable_group() -> void:
    var state = _make_state()
    if state == null:
        return
    state.apply_effect("haste", "haste_default", 8.0, false, 1)
    state.apply_effect("haste", "haste_default", 8.0, false, 1)
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 8.0)

func test_distinct_groups_combine() -> void:
    var state = _make_state()
    if state == null:
        return
    state.apply_effect("boots", "equipment_boots", 3.0, false, -1)
    state.apply_effect("slow", "slow_default", -5.0, false, 1)
    assert_eq(state.get_total_flat_seconds_for_next_turn(), -2.0)

func test_reapplying_non_stackable_group_replaces_magnitude_and_duration() -> void:
    var state = _make_state()
    if state == null:
        return
    state.apply_effect("haste_small", "haste_default", 4.0, false, 1)
    state.apply_effect("haste_large", "haste_default", 9.0, false, 2)
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 9.0)
    state.advance_turn_boundary()
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 9.0)
    state.advance_turn_boundary()
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 0.0)

func test_new_effect_never_mutates_an_already_snapshotted_current_budget() -> void:
    var state = _make_state()
    if state == null:
        return
    var current_budget = _make_budget()
    current_budget.snapshot(90.0, 0.0, 30.0, 120.0)
    current_budget.consume(10.0)

    state.apply_effect("haste", "haste_default", 8.0, false, 1)

    assert_eq(current_budget.effective_budget_seconds, 90.0)
    assert_eq(current_budget.remaining_seconds, 80.0)

func test_effect_is_applied_by_next_snapshot_then_expires_at_boundary() -> void:
    var state = _make_state()
    if state == null:
        return
    state.apply_effect("haste", "haste_default", 8.0, false, 1)

    var next_budget = _make_budget()
    next_budget.snapshot(
        90.0,
        state.get_total_flat_seconds_for_next_turn(),
        30.0,
        120.0
    )
    assert_eq(next_budget.effective_budget_seconds, 98.0)

    state.advance_turn_boundary()
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 0.0)

func test_permanent_effect_survives_turn_boundaries() -> void:
    var state = _make_state()
    if state == null:
        return
    state.apply_effect("boots", "equipment_boots", 3.0, false, -1)
    state.advance_turn_boundary()
    state.advance_turn_boundary()
    assert_eq(state.get_total_flat_seconds_for_next_turn(), 3.0)
