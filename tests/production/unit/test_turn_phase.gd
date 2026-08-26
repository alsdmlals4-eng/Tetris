extends GutTest

const TURN_PHASE_PATH := "res://src/production/turn/turn_phase.gd"

func _load_turn_phase_script():
    assert_true(ResourceLoader.exists(TURN_PHASE_PATH), "production TurnPhase script must exist")
    if not ResourceLoader.exists(TURN_PHASE_PATH):
        return null
    return load(TURN_PHASE_PATH)

func test_production_turn_phase_vocabulary_is_ordered() -> void:
    var turn_phase = _load_turn_phase_script()
    if turn_phase == null:
        return
    assert_eq(turn_phase.ENEMY_TELEGRAPH, 0)
    assert_eq(turn_phase.LINE, 1)
    assert_eq(turn_phase.LINE_SETTLE, 2)
    assert_eq(turn_phase.CHAIN, 3)
    assert_eq(turn_phase.CHAIN_SETTLE, 4)
    assert_eq(turn_phase.ACTION, 5)
    assert_eq(turn_phase.PLAYER_RESOLVE, 6)
    assert_eq(turn_phase.ENEMY_RESOLVE, 7)
