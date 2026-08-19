extends GutTest

var PocSessionScript := preload("res://src/core/poc_session.gd")
var SkillDefinitionScript := preload("res://src/skills/skill_definition.gd")
var BoardStateScript := preload("res://src/core/board_state.gd")

func test_automated_forty_five_second_contract() -> void:
    var session = PocSessionScript.new()

    assert_eq(session.modes.active_mode, &"line")
    assert_eq(session.modes.line_state, BoardStateScript.LOCKED)

    assert_true(session.run_active())
    session.tick(2.0)
    assert_true(session.submit_line_clear(2))
    assert_eq(session.combat.energy, 22)
    var saved_line_advance: int = session.line_source.advance_count
    assert_eq(saved_line_advance, 1)

    assert_true(session.lock_active())
    session.tick(2.0)
    assert_eq(session.line_source.advance_count, saved_line_advance)
    assert_almost_eq(session.combat.combat_time, 4.0, 0.001)

    assert_true(session.switch_mode(&"chain"))
    assert_eq(session.modes.chain_state, BoardStateScript.LOCKED)
    session.tick(1.0)
    assert_eq(session.chain_source.advance_count, 0)
    assert_eq(session.line_source.advance_count, saved_line_advance)

    assert_true(session.run_active())
    session.tick(1.0)
    assert_eq(session.chain_source.advance_count, 1)
    assert_true(session.submit_completed_chain(3, 12))
    assert_eq(session.combat.chain_stock, 3)

    var attack_t1 = SkillDefinitionScript.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(session.use_skill(attack_t1))
    assert_eq(session.combat.energy, 7)
    assert_eq(session.combat.chain_stock, 2)
    assert_eq(session.combat.enemy_hp, 275)

    var energy_before_reject: int = session.combat.energy
    var stock_before_reject: int = session.combat.chain_stock
    var enemy_hp_before_reject: int = session.combat.enemy_hp
    var attack_t5 = SkillDefinitionScript.new(&"attack_t5", &"attack", 5, 85, 150)
    assert_false(session.use_skill(attack_t5))
    assert_eq(session.combat.energy, energy_before_reject)
    assert_eq(session.combat.chain_stock, stock_before_reject)
    assert_eq(session.combat.enemy_hp, enemy_hp_before_reject)

    assert_true(session.lock_active())
    var saved_chain_advance: int = session.chain_source.advance_count
    session.tick(6.0)
    assert_almost_eq(session.combat.combat_time, 12.0, 0.001)
    assert_eq(session.chain_source.advance_count, saved_chain_advance)
    assert_eq(session.combat.player_hp, 160)

    assert_true(session.switch_mode(&"line"))
    assert_eq(session.modes.line_state, BoardStateScript.LOCKED)
    assert_eq(session.line_source.advance_count, saved_line_advance)

    session.tick(33.0)
    assert_almost_eq(session.combat.combat_time, 45.0, 0.001)
    assert_eq(session.line_source.advance_count, saved_line_advance)
    assert_eq(session.combat.player_hp, 90)
    assert_eq(session.combat.enemy_hp, 300)

    var names: Array[StringName] = []
    for event in session.telemetry.events:
        names.append(event.name)
    assert_true(names.has(&"line_clear"))
    assert_true(names.has(&"chain_complete"))
    assert_true(names.has(&"skill_use"))
    assert_true(names.has(&"skill_rejected"))
    assert_true(names.has(&"mode_switch"))
    assert_eq(names.count(&"enemy_action"), 3)
