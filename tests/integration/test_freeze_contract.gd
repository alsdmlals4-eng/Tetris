extends GutTest

func _session():
    var script := load("res://src/core/poc_session.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func test_lock_and_inactive_mode_freeze_sources_but_not_combat_clock() -> void:
    var session = _session()
    if session == null:
        return

    assert_true(session.run_active())
    session.tick(1.0)
    assert_eq(session.line_source.advance_count, 1)
    assert_eq(session.chain_source.advance_count, 0)
    assert_almost_eq(session.combat.combat_time, 1.0, 0.001)

    assert_true(session.lock_active())
    session.tick(1.0)
    assert_eq(session.line_source.advance_count, 1)
    assert_almost_eq(session.combat.combat_time, 2.0, 0.001)

    assert_true(session.switch_mode(&"chain"))
    session.tick(1.0)
    assert_eq(session.line_source.advance_count, 1)
    assert_eq(session.chain_source.advance_count, 0)
    assert_almost_eq(session.combat.combat_time, 3.0, 0.001)

    assert_true(session.run_active())
    session.tick(1.0)
    assert_eq(session.chain_source.advance_count, 1)
    assert_almost_eq(session.combat.combat_time, 4.0, 0.001)

func test_enemy_action_fires_while_puzzle_is_locked() -> void:
    var session = _session()
    if session == null:
        return
    assert_true(session.lock_active())
    session.tick(12.0)
    assert_eq(session.line_source.advance_count, 0)
    assert_eq(session.combat.player_hp, 160)
    assert_eq(session.telemetry.events[-1].name, &"enemy_action")

func test_switch_destination_stays_locked_until_explicit_run() -> void:
    var session = _session()
    if session == null:
        return
    assert_true(session.switch_mode(&"chain"))
    session.tick(1.0)
    assert_eq(session.chain_source.advance_count, 0)
    assert_true(session.run_active())
    session.tick(1.0)
    assert_eq(session.chain_source.advance_count, 1)
