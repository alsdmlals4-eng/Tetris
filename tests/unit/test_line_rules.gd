extends GutTest

func _rules():
    var script := load("res://src/rules/line_rules.gd")
    assert_not_null(script)
    return script

func test_line_energy_mapping() -> void:
    var rules = _rules()
    if rules == null:
        return
    assert_eq(rules.energy_for_clear(1), 10)
    assert_eq(rules.energy_for_clear(2), 22)
    assert_eq(rules.energy_for_clear(3), 36)
    assert_eq(rules.energy_for_clear(4), 52)
    assert_eq(rules.energy_for_clear(0), 0)
    assert_eq(rules.energy_for_clear(5), 0)

func test_reference_line_score_is_separate_from_energy() -> void:
    var rules = _rules()
    if rules == null:
        return
    assert_eq(rules.score_for_clear(1), 100)
    assert_eq(rules.score_for_clear(2), 300)
    assert_eq(rules.score_for_clear(3), 500)
    assert_eq(rules.score_for_clear(4), 800)
    assert_eq(rules.score_for_clear(4, 2), 1600)

func test_line_event_shape_contains_resource_and_score() -> void:
    var rules = _rules()
    if rules == null:
        return
    var event: Dictionary = rules.make_event(2)
    assert_eq(event.kind, &"line_clear")
    assert_eq(event.lines, 2)
    assert_eq(event.energy, 22)
    assert_eq(event.score, 300)
