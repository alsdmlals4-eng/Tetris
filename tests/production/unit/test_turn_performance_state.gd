extends GutTest

const STATE_PATH := "res://src/production/combat/production_turn_performance_state.gd"

func _state():
    assert_true(ResourceLoader.exists(STATE_PATH), "ProductionTurnPerformanceState script must exist")
    if not ResourceLoader.exists(STATE_PATH):
        return null
    return load(STATE_PATH).new()

func test_normalized_line_and_chain_events_create_exact_tempo_qualification() -> void:
    var state = _state()
    if state == null:
        return

    assert_false(state.line_qualified)
    assert_false(state.chain_qualified)
    assert_true(state.record_event({"kind": &"production_line_resolved", "energy_delta": 10}))
    assert_true(state.record_event({"kind": &"production_chain_resolved", "stock_applied": 2}))
    assert_true(state.line_qualified)
    assert_true(state.chain_qualified)
    assert_false(state.board_break_occurred)

func test_board_break_is_a_separate_disqualifier_and_does_not_fake_line_qualification() -> void:
    var state = _state()
    if state == null:
        return

    assert_true(state.record_event({"kind": &"production_line_board_break", "reason": "SPAWN_BLOCKED"}))
    assert_true(state.board_break_occurred)
    assert_false(state.line_qualified)

func test_timeout_and_pass_are_explicit_independent_gates() -> void:
    var state = _state()
    if state == null:
        return

    state.mark_timeout()
    state.mark_action("PASS")

    assert_true(state.timeout_occurred)
    assert_false(state.action_non_pass)

func test_legal_non_pass_action_marks_only_action_gate() -> void:
    var state = _state()
    if state == null:
        return

    state.mark_action("atk_t1_quick_cut")

    assert_true(state.action_non_pass)
    assert_false(state.line_qualified)
    assert_false(state.chain_qualified)

func test_unknown_events_fail_closed_without_changing_qualification() -> void:
    var state = _state()
    if state == null:
        return

    assert_false(state.record_event({"kind": &"historical_line_clear"}))
    assert_false(state.record_event({}))
    assert_false(state.line_qualified)
    assert_false(state.chain_qualified)
    assert_false(state.board_break_occurred)

func test_reset_clears_only_turn_local_eligibility_facts() -> void:
    var state = _state()
    if state == null:
        return
    state.record_event({"kind": &"production_line_resolved"})
    state.record_event({"kind": &"production_chain_resolved"})
    state.record_event({"kind": &"production_line_board_break"})
    state.mark_timeout()
    state.mark_action("atk_t1_quick_cut")

    state.reset_for_next_turn()

    assert_false(state.line_qualified)
    assert_false(state.chain_qualified)
    assert_false(state.action_non_pass)
    assert_false(state.timeout_occurred)
    assert_false(state.board_break_occurred)
