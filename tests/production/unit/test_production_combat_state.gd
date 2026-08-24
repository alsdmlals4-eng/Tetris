extends GutTest

const STATE_PATH := "res://src/production/combat/production_combat_state.gd"

func _state(max_hp: int = 100):
    assert_true(ResourceLoader.exists(STATE_PATH), "ProductionCombatState script must exist")
    if not ResourceLoader.exists(STATE_PATH):
        return null
    return load(STATE_PATH).new(max_hp)

func test_stock_cap_is_six_and_overflow_is_reported() -> void:
    var state = _state()
    if state == null:
        return

    var first: Dictionary = state.gain_stock(4)
    var second: Dictionary = state.gain_stock(5)

    assert_eq(state.stock, 6)
    assert_eq(state.STOCK_CAP, 6)
    assert_eq(first["applied"], 4)
    assert_eq(first["lost_at_cap"], 0)
    assert_eq(second["applied"], 2)
    assert_eq(second["lost_at_cap"], 3)

func test_energy_has_no_invented_production_cap_and_never_becomes_negative() -> void:
    var state = _state()
    if state == null:
        return

    assert_eq(state.apply_energy_delta(120), 120)
    assert_eq(state.energy, 120, "No production Energy cap is canon yet")
    assert_eq(state.apply_energy_delta(-200), -120)
    assert_eq(state.energy, 0)

func test_skill_cost_spend_is_atomic_and_keeps_resources_non_interchangeable() -> void:
    var state = _state()
    if state == null:
        return
    state.apply_energy_delta(20)
    state.gain_stock(6)

    assert_false(state.try_spend_skill_cost(21, 1), "Stock may not substitute for missing Energy")
    assert_eq(state.energy, 20)
    assert_eq(state.stock, 6)

    assert_false(state.try_spend_skill_cost(1, 7), "Energy may not substitute for Stock and Stock spend cannot exceed cap")
    assert_eq(state.energy, 20)
    assert_eq(state.stock, 6)

    assert_true(state.try_spend_skill_cost(8, 6))
    assert_eq(state.energy, 12)
    assert_eq(state.stock, 0)

func test_tier_cost_uses_exact_tier_stock_grammar() -> void:
    var state = _state()
    if state == null:
        return
    state.apply_energy_delta(50)
    state.gain_stock(6)

    for tier in range(1, 7):
        assert_eq(state.stock_cost_for_tier(tier), tier)
    assert_eq(state.stock_cost_for_tier(0), -1)
    assert_eq(state.stock_cost_for_tier(7), -1)

func test_line_event_commits_energy_only_and_rejects_wrong_or_negative_source_event() -> void:
    var state = _state()
    if state == null:
        return

    var line_event := {
        "kind": &"production_line_resolved",
        "energy_delta": 7,
        "score_delta": 900,
    }
    assert_true(state.apply_line_event(line_event))
    assert_eq(state.energy, 7)
    assert_eq(state.stock, 0, "Line must not create Stock")

    var before: int = state.energy
    assert_false(state.apply_line_event({"kind": &"production_chain_resolved", "energy_delta": 9}))
    assert_false(state.apply_line_event({"kind": &"production_line_resolved", "energy_delta": -1}))
    assert_eq(state.energy, before)

func test_hp_damage_and_heal_do_not_confiscate_puzzle_resources() -> void:
    var state = _state(100)
    if state == null:
        return
    state.apply_energy_delta(13)
    state.gain_stock(5)

    assert_eq(state.apply_damage(35), 35)
    assert_eq(state.hp, 65)
    assert_eq(state.energy, 13)
    assert_eq(state.stock, 5)

    assert_eq(state.heal(80), 35)
    assert_eq(state.hp, 100)
    assert_eq(state.energy, 13)
    assert_eq(state.stock, 5)
    assert_false(state.is_defeated())

    state.apply_damage(1000)
    assert_eq(state.hp, 0)
    assert_true(state.is_defeated())
