extends GutTest

func _turn_in_action() -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(30.0, 0.0, 0.0, 30.0)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    return turn

func test_player_resolve_completes_only_into_enemy_resolve_and_keeps_committed_action_until_turn_end() -> void:
    var turn := _turn_in_action()
    assert_true(turn.select_player_action("atk_t3_rift_breach"))
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)

    assert_true(turn.complete_player_resolve())

    assert_eq(turn.phase, TurnPhase.ENEMY_RESOLVE)
    assert_not_null(turn.pending_player_action)
    assert_eq(turn.pending_player_action.id, "atk_t3_rift_breach")

func test_enemy_resolve_completes_into_next_enemy_telegraph_and_clears_prior_turn_transients() -> void:
    var turn := _turn_in_action()
    assert_true(turn.select_player_action("PASS"))
    assert_true(turn.complete_player_resolve())
    turn.chain_input_skipped_for_timeout = true

    assert_true(turn.complete_enemy_resolve())

    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)
    assert_null(turn.pending_player_action)
    assert_false(turn.chain_input_skipped_for_timeout)

func test_resolution_completion_calls_fail_closed_in_wrong_phase_without_mutation() -> void:
    var budget := TurnBudget.new()
    budget.snapshot(30.0, 0.0, 0.0, 30.0)
    var turn := TurnController.new(budget)

    assert_false(turn.complete_player_resolve())
    assert_false(turn.complete_enemy_resolve())
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)
    assert_null(turn.pending_player_action)

    turn.enter_line()
    assert_false(turn.complete_player_resolve())
    assert_false(turn.complete_enemy_resolve())
    assert_eq(turn.phase, TurnPhase.LINE)
