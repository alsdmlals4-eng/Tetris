extends GutTest

func _session():
    var script := load("res://src/core/poc_session.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func _skill_definition():
    var script := load("res://src/skills/skill_definition.gd")
    assert_not_null(script)
    return script

func test_line_then_chain_then_skill_uses_both_resources() -> void:
    var session = _session()
    var definition = _skill_definition()
    if session == null or definition == null:
        return

    assert_true(session.run_active())
    assert_true(session.submit_line_clear(2))
    assert_eq(session.combat.energy, 22)

    assert_true(session.switch_mode(&"chain"))
    assert_false(session.submit_completed_chain(1, 4))
    assert_true(session.run_active())
    assert_true(session.submit_completed_chain(1, 4))
    assert_eq(session.combat.chain_stock, 1)

    var attack = definition.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_true(session.use_skill(attack))
    assert_eq(session.combat.energy, 7)
    assert_eq(session.combat.chain_stock, 0)
    assert_eq(session.combat.enemy_hp, 275)

func test_rejected_skill_preserves_resources_and_is_logged() -> void:
    var session = _session()
    var definition = _skill_definition()
    if session == null or definition == null:
        return
    session.combat.energy = 15
    session.combat.chain_stock = 1
    var attack = definition.new(&"attack_t5", &"attack", 5, 85, 150)
    assert_false(session.use_skill(attack))
    assert_eq(session.combat.energy, 15)
    assert_eq(session.combat.chain_stock, 1)
    assert_eq(session.telemetry.events[-1].name, &"skill_rejected")

func test_skill_is_rejected_during_resolution_without_mutation() -> void:
    var session = _session()
    var definition = _skill_definition()
    if session == null or definition == null:
        return
    session.combat.energy = 15
    session.combat.chain_stock = 1
    assert_true(session.run_active())
    assert_true(session.begin_active_resolution())
    var attack = definition.new(&"attack_t1", &"attack", 1, 15, 25)
    assert_false(session.use_skill(attack))
    assert_eq(session.combat.energy, 15)
    assert_eq(session.combat.chain_stock, 1)
    assert_eq(session.combat.enemy_hp, 300)
    assert_eq(session.telemetry.events[-1].name, &"skill_rejected")

func test_queued_switch_logs_queue_then_actual_switch_after_resolution() -> void:
    var session = _session()
    if session == null:
        return
    assert_true(session.run_active())
    assert_true(session.begin_active_resolution())
    assert_true(session.switch_mode(&"chain"))
    assert_eq(session.modes.active_mode, &"line")
    assert_eq(session.telemetry.events[-1].name, &"mode_switch_queued")
    assert_true(session.finish_active_resolution())
    assert_eq(session.modes.active_mode, &"chain")
    assert_eq(session.telemetry.events[-1].name, &"mode_switch")
    assert_eq(session.telemetry.events[-1].payload.target, &"chain")

func test_line_and_chain_events_are_logged_with_combat_time() -> void:
    var session = _session()
    if session == null:
        return
    session.run_active()
    session.tick(2.0)
    assert_true(session.submit_line_clear(1))
    assert_eq(session.telemetry.events[-1].name, &"line_clear")
    assert_almost_eq(session.telemetry.events[-1].time, 2.0, 0.001)
