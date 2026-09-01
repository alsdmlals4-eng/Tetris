## CHAIN 파동 보상과 Combo·MP 원자 거래를 검증한다.
extends GutTest

const COMBAT_STATE_PATH := "res://src/production/combat/production_combat_state.gd"

func _state():
    var script = load(COMBAT_STATE_PATH)
    assert_not_null(script)
    return script.new(100) if script != null else null

func test_chain_wave_awards_combo_before_mp_formula_and_caps_both_resources() -> void:
    var state = _state()
    if state == null:
        return
    state.energy = 58
    state.stock = 9
    var event: Dictionary = state.apply_chain_wave([5, 5])
    assert_eq(event["combo_before"], 9)
    assert_eq(event["combo_after"], 10)
    assert_eq(event["mp_requested"], 17)
    assert_eq(event["mp_applied"], 2)
    assert_eq(event["mp_lost_at_cap"], 15)
    assert_eq(state.energy, 60)
    assert_eq(state.stock, 10)

func test_chain_wave_counts_crossing_lines_separately_and_unqualified_lengths_do_not_mutate() -> void:
    var state = _state()
    if state == null:
        return
    state.stock = 4
    var event: Dictionary = state.apply_chain_wave([5, 5])
    assert_eq(event["combo_after"], 5)
    assert_eq(event["mp_requested"], 12)
    assert_eq(state.energy, 12)
    var before_energy: int = state.energy
    var before_combo: int = state.stock
    var empty_event: Dictionary = state.apply_chain_wave([1, 2])
    assert_eq(empty_event["mp_requested"], 0)
    assert_eq(state.energy, before_energy)
    assert_eq(state.stock, before_combo)

func test_shortage_fallback_converts_surplus_combo_once_and_rejects_invalid_transactions() -> void:
    var state = _state()
    if state == null:
        return
    state.energy = 8
    state.stock = 5
    var result: Dictionary = state.try_commit_combo_skill(13, 5, 4)
    assert_true(result["committed"])
    assert_eq(result["converted_combo"], 1)
    assert_eq(result["combo_spent"], 5)
    assert_eq(state.energy, 0)
    assert_eq(state.stock, 0)
    state.energy = 4
    state.stock = 3
    var rejected: Dictionary = state.try_commit_combo_skill(20, 3, 2)
    assert_false(rejected["committed"])
    assert_eq(rejected["reason"], "INSUFFICIENT_RESOURCE")
    assert_eq(state.energy, 4)
    assert_eq(state.stock, 3)
