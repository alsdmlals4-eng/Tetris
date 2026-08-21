extends GutTest

var CombatStateScript := preload("res://src/core/combat_state.gd")

func _pattern():
    var script := load("res://src/enemies/enemy_pattern.gd")
    assert_not_null(script)
    if script == null:
        return null
    return script.new()

func test_enemy_schedule_waits_until_twelve_seconds() -> void:
    var pattern = _pattern()
    if pattern == null:
        return
    var state = CombatStateScript.new()
    state.combat_time = 11.9
    var events: Array = pattern.process_due(state)
    assert_eq(events.size(), 0)
    assert_eq(state.player_hp, 200)

func test_enemy_attacks_at_twelve_and_twenty_four_seconds() -> void:
    var pattern = _pattern()
    if pattern == null:
        return
    var state = CombatStateScript.new()
    state.shield = 10
    state.combat_time = 12.0
    var events: Array = pattern.process_due(state)
    assert_eq(events.size(), 1)
    assert_eq(events[0].kind, &"attack")
    assert_eq(state.shield, 0)
    assert_eq(state.player_hp, 170)

    state.combat_time = 24.0
    events = pattern.process_due(state)
    assert_eq(events.size(), 1)
    assert_eq(events[0].magnitude, 70)
    assert_eq(state.player_hp, 100)

func test_enemy_heals_at_thirty_six_seconds_and_clamps() -> void:
    var pattern = _pattern()
    if pattern == null:
        return
    var state = CombatStateScript.new()
    state.enemy_hp = 280
    state.combat_time = 36.0
    var events: Array = pattern.process_due(state)
    assert_eq(events.size(), 3)
    assert_eq(events[2].kind, &"heal")
    assert_eq(events[2].magnitude, 40)
    assert_eq(state.enemy_hp, 300)
