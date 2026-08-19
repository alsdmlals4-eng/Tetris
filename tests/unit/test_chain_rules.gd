extends GutTest

func _rules():
    var script := load("res://src/rules/chain_rules.gd")
    assert_not_null(script)
    return script

func test_chain_stock_value_caps_at_five() -> void:
    var rules = _rules()
    if rules == null:
        return
    assert_eq(rules.stock_value(0), 0)
    assert_eq(rules.stock_value(1), 1)
    assert_eq(rules.stock_value(5), 5)
    assert_eq(rules.stock_value(8), 5)

func test_completed_chain_event_reports_without_mutating_combat() -> void:
    var rules = _rules()
    if rules == null:
        return
    var event: Dictionary = rules.make_completed_event(4, 16)
    assert_eq(event.kind, &"chain_complete")
    assert_eq(event.chain_count, 4)
    assert_eq(event.stock_value, 4)
    assert_eq(event.pieces_cleared, 16)
