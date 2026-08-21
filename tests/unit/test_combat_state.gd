extends GutTest

func _new_state():
    var script := load("res://src/core/combat_state.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func test_chain_stock_is_non_additive_and_capped() -> void:
    var state = _new_state()
    if state == null:
        return
    state.set_chain_stock_from_completed_chain(2)
    state.set_chain_stock_from_completed_chain(2)
    assert_eq(state.chain_stock, 2)
    state.set_chain_stock_from_completed_chain(9)
    assert_eq(state.chain_stock, 5)

func test_tier_three_spend_consumes_exactly_three_stock() -> void:
    var state = _new_state()
    if state == null:
        return
    state.energy = 40
    state.chain_stock = 5
    assert_true(state.spend_skill(3, 40))
    assert_eq(state.energy, 0)
    assert_eq(state.chain_stock, 2)

func test_emergency_energy_recovery_stops_at_fifteen() -> void:
    var state = _new_state()
    if state == null:
        return
    state.tick(30.0)
    assert_eq(state.energy, 15)
    state.tick(30.0)
    assert_eq(state.energy, 15)

func test_energy_above_emergency_floor_cannot_bank_partial_recovery_time() -> void:
    var state = _new_state()
    if state == null:
        return
    state.energy = 14
    state.tick(0.9)
    assert_eq(state.energy, 14)
    state.gain_energy(10)
    assert_eq(state.energy, 24)
    state.chain_stock = 1
    assert_true(state.spend_skill(1, 15))
    assert_eq(state.energy, 9)
    state.tick(0.1)
    assert_eq(state.energy, 9)
    state.tick(0.9)
    assert_eq(state.energy, 10)

func test_shield_absorbs_damage_before_hp() -> void:
    var state = _new_state()
    if state == null:
        return
    state.shield = 30
    state.apply_incoming_damage(40)
    assert_eq(state.shield, 0)
    assert_eq(state.player_hp, 190)

func test_invalid_skill_spend_does_not_mutate_resources() -> void:
    var state = _new_state()
    if state == null:
        return
    state.energy = 85
    state.chain_stock = 5
    assert_false(state.spend_skill(0, 15))
    assert_eq(state.energy, 85)
    assert_eq(state.chain_stock, 5)
    assert_false(state.spend_skill(5, -1))
    assert_eq(state.energy, 85)
    assert_eq(state.chain_stock, 5)
