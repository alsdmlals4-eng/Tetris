extends GutTest

const TURN_BUDGET_PATH := "res://src/production/turn/turn_budget.gd"

func _make_budget():
    assert_true(ResourceLoader.exists(TURN_BUDGET_PATH), "production TurnBudget script must exist")
    if not ResourceLoader.exists(TURN_BUDGET_PATH):
        return null
    return load(TURN_BUDGET_PATH).new()

func test_snapshot_clamps_effective_budget() -> void:
    var budget = _make_budget()
    if budget == null:
        return
    budget.snapshot(90.0, 20.0, 30.0, 100.0)
    assert_eq(budget.effective_budget_seconds, 100.0)
    assert_eq(budget.remaining_seconds, 100.0)
    assert_eq(budget.active_used_seconds, 0.0)
    assert_false(budget.frozen)

func test_consume_uses_one_shared_clock() -> void:
    var budget = _make_budget()
    if budget == null:
        return
    budget.snapshot(90.0, 0.0, 30.0, 120.0)
    budget.consume(12.0)
    budget.consume(8.0)
    assert_eq(budget.remaining_seconds, 70.0)
    assert_eq(budget.active_used_seconds, 20.0)

func test_non_positive_delta_never_changes_budget() -> void:
    var budget = _make_budget()
    if budget == null:
        return
    budget.snapshot(90.0, 0.0, 30.0, 120.0)
    budget.consume(0.0)
    budget.consume(-10.0)
    assert_eq(budget.remaining_seconds, 90.0)
    assert_eq(budget.active_used_seconds, 0.0)

func test_consume_clamps_at_zero_and_marks_expired() -> void:
    var budget = _make_budget()
    if budget == null:
        return
    budget.snapshot(10.0, 0.0, 1.0, 20.0)
    budget.consume(25.0)
    assert_eq(budget.remaining_seconds, 0.0)
    assert_eq(budget.active_used_seconds, 10.0)
    assert_true(budget.is_expired())

func test_freeze_prevents_consumption() -> void:
    var budget = _make_budget()
    if budget == null:
        return
    budget.snapshot(90.0, 0.0, 30.0, 120.0)
    budget.freeze()
    budget.consume(15.0)
    assert_eq(budget.remaining_seconds, 90.0)
    assert_eq(budget.active_used_seconds, 0.0)
