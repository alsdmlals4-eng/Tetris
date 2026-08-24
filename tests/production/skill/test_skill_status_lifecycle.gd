extends GutTest

func test_breach_consumes_only_on_qualifying_attack_trigger() -> void:
    var state := ProductionStatusState.new()
    assert_true(state.apply_status("BREACH", "enemy"))

    assert_false(state.consume_unbound_for_trigger("BREACH", "enemy", "PLAYER_SUPPORT_ACTION"))
    assert_true(state.has_status("BREACH", "enemy"))
    assert_true(state.consume_unbound_for_trigger("BREACH", "enemy", "QUALIFYING_PLAYER_ATTACK"))
    assert_false(state.has_status("BREACH", "enemy"))

func test_fortify_and_rally_have_distinct_bounded_consumption_triggers() -> void:
    var state := ProductionStatusState.new()
    assert_true(state.apply_status("FORTIFY", "player"))
    assert_true(state.apply_status("RALLY", "player"))

    assert_false(state.consume_unbound_for_trigger("FORTIFY", "player", "LEGAL_PLAYER_ACTION"))
    assert_true(state.consume_unbound_for_trigger("RALLY", "player", "LEGAL_PLAYER_ACTION"))
    assert_true(state.has_status("FORTIFY", "player"))
    assert_false(state.has_status("RALLY", "player"))

    assert_true(state.consume_unbound_for_trigger("FORTIFY", "player", "QUALIFYING_DIRECT_HIT"))
    assert_false(state.has_status("FORTIFY", "player"))

func test_battle_trance_consumes_only_at_next_eligible_preparation_window() -> void:
    var state := ProductionStatusState.new()
    assert_true(state.apply_status("BATTLE_TRANCE", "player"))

    assert_false(state.consume_unbound_for_trigger("BATTLE_TRANCE", "player", "LEGAL_PLAYER_ACTION"))
    assert_true(state.has_status("BATTLE_TRANCE", "player"))
    assert_true(state.consume_unbound_for_trigger("BATTLE_TRANCE", "player", "ELIGIBLE_LINE_CHAIN_PREPARATION"))
    assert_false(state.has_status("BATTLE_TRANCE", "player"))

func test_bound_forecast_statuses_cannot_be_consumed_through_unbound_trigger_api() -> void:
    var state := ProductionStatusState.new()
    assert_true(state.apply_bound_status("WEAKEN", "enemy", "enemy_action_42", "VISIBLE_NEXT_FORECAST_ACTION_ID"))
    assert_true(state.apply_bound_status("RIFT_SEAL", "enemy", "enemy_action_43", "VISIBLE_NEXT_FORECAST_ACTION_ID"))
    assert_true(state.apply_bound_status("RIFT_WARD", "player", "enemy_action_44", "CURRENT_TELEGRAPH_ACTION_ID"))

    assert_false(state.consume_unbound_for_trigger("WEAKEN", "enemy", "QUALIFYING_PLAYER_ATTACK"))
    assert_false(state.consume_unbound_for_trigger("RIFT_SEAL", "enemy", "ELIGIBLE_LINE_CHAIN_PREPARATION"))
    assert_false(state.consume_unbound_for_trigger("RIFT_WARD", "player", "QUALIFYING_DIRECT_HIT"))

    assert_true(state.matches_bound_action("WEAKEN", "enemy", "enemy_action_42"))
    assert_true(state.matches_bound_action("RIFT_SEAL", "enemy", "enemy_action_43"))
    assert_true(state.matches_bound_action("RIFT_WARD", "player", "enemy_action_44"))

func test_unknown_status_or_trigger_fails_closed_without_erasing_status() -> void:
    var state := ProductionStatusState.new()
    assert_true(state.apply_status("BREACH", "enemy"))

    assert_false(state.consume_unbound_for_trigger("POISON", "enemy", "QUALIFYING_PLAYER_ATTACK"))
    assert_false(state.consume_unbound_for_trigger("BREACH", "enemy", "INVENTED_TRIGGER"))
    assert_true(state.has_status("BREACH", "enemy"))
