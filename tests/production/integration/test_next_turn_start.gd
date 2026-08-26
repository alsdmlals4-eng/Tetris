extends GutTest

const TIME_DATA_PATH := "res://data/production/turn_time_config.json"

func _config() -> TurnTimeConfig:
    return TurnTimeConfig.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(TIME_DATA_PATH)))

func _telegraph_turn_with_old_budget(remaining: float = 7.0) -> TurnController:
    var old_budget := TurnBudget.new()
    old_budget.snapshot(90.0, 0.0, 30.0, 120.0)
    old_budget.consume(90.0 - remaining)
    old_budget.freeze()
    return TurnController.new(old_budget)

func test_start_player_turn_snapshots_fresh_normal_budget_and_never_banks_old_remaining_time() -> void:
    var turn := _telegraph_turn_with_old_budget(17.0)
    var effects := TimeEffectState.new()

    var result: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)

    assert_true(result["started"])
    assert_eq(turn.phase, TurnPhase.LINE)
    assert_eq(turn.turn_budget.effective_budget_seconds, 90.0)
    assert_eq(turn.turn_budget.remaining_seconds, 90.0)
    assert_eq(turn.turn_budget.active_used_seconds, 0.0)
    assert_eq(result["tempo_reference_seconds"], 90.0)
    assert_eq(result["flat_modifier_seconds"], 0.0)

func test_haste_is_snapshotted_once_into_next_turn_then_expires_without_changing_tempo_reference() -> void:
    var turn := _telegraph_turn_with_old_budget()
    var effects := TimeEffectState.new()
    effects.apply_effect("sup_t3_haste", "haste_default", 5.0, false, 1)

    var result: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)

    assert_true(result["started"])
    assert_eq(turn.turn_budget.effective_budget_seconds, 95.0)
    assert_eq(turn.turn_budget.remaining_seconds, 95.0)
    assert_eq(result["flat_modifier_seconds"], 5.0)
    assert_eq(result["tempo_reference_seconds"], 90.0)
    assert_eq(effects.get_total_flat_seconds_for_next_turn(), 0.0, "one-turn Haste is consumed only after its snapshot is captured")

func test_expired_haste_does_not_reapply_on_following_turn() -> void:
    var turn := _telegraph_turn_with_old_budget()
    var effects := TimeEffectState.new()
    effects.apply_effect("sup_t3_haste", "haste_default", 5.0, false, 1)
    assert_true(turn.start_player_turn(_config(), "NORMAL", effects)["started"])

    turn.phase = TurnPhase.ENEMY_TELEGRAPH
    turn.turn_budget.freeze()
    var second: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)

    assert_true(second["started"])
    assert_eq(turn.turn_budget.effective_budget_seconds, 90.0)
    assert_eq(second["flat_modifier_seconds"], 0.0)

func test_permanent_time_effect_survives_turn_boundary_while_one_turn_effect_expires() -> void:
    var turn := _telegraph_turn_with_old_budget()
    var effects := TimeEffectState.new()
    effects.apply_effect("boots", "equipment_boots", 3.0, false, -1)
    effects.apply_effect("haste", "haste_default", 5.0, false, 1)

    var first: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)

    assert_true(first["started"])
    assert_eq(turn.turn_budget.effective_budget_seconds, 98.0)
    assert_eq(effects.get_total_flat_seconds_for_next_turn(), 3.0)

    turn.phase = TurnPhase.ENEMY_TELEGRAPH
    turn.turn_budget.freeze()
    var second: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)
    assert_true(second["started"])
    assert_eq(turn.turn_budget.effective_budget_seconds, 93.0)
    assert_eq(effects.get_total_flat_seconds_for_next_turn(), 3.0)

func test_difficulty_profile_is_applied_to_effective_budget_without_changing_tempo_reference() -> void:
    for profile in ["EASY", "NORMAL", "HARD"]:
        var turn := _telegraph_turn_with_old_budget()
        var result: Dictionary = turn.start_player_turn(_config(), profile, TimeEffectState.new())
        assert_true(result["started"])
        assert_eq(result["tempo_reference_seconds"], 90.0)

    var easy_turn := _telegraph_turn_with_old_budget()
    easy_turn.start_player_turn(_config(), "EASY", TimeEffectState.new())
    assert_eq(easy_turn.turn_budget.effective_budget_seconds, 105.0)
    var hard_turn := _telegraph_turn_with_old_budget()
    hard_turn.start_player_turn(_config(), "HARD", TimeEffectState.new())
    assert_eq(hard_turn.turn_budget.effective_budget_seconds, 75.0)

func test_invalid_profile_or_wrong_phase_fails_closed_without_replacing_budget_or_consuming_effects() -> void:
    var turn := _telegraph_turn_with_old_budget(11.0)
    var old_budget := turn.turn_budget
    var effects := TimeEffectState.new()
    effects.apply_effect("haste", "haste_default", 5.0, false, 1)

    var invalid_profile: Dictionary = turn.start_player_turn(_config(), "UNKNOWN", effects)

    assert_false(invalid_profile["started"])
    assert_eq(invalid_profile["reason"], "UNKNOWN_DIFFICULTY_PROFILE")
    assert_same(turn.turn_budget, old_budget)
    assert_eq(turn.turn_budget.remaining_seconds, 11.0)
    assert_eq(effects.get_total_flat_seconds_for_next_turn(), 5.0)

    turn.phase = TurnPhase.ENEMY_RESOLVE
    var wrong_phase: Dictionary = turn.start_player_turn(_config(), "NORMAL", effects)
    assert_false(wrong_phase["started"])
    assert_eq(wrong_phase["reason"], "WRONG_PHASE")
    assert_same(turn.turn_budget, old_budget)
    assert_eq(effects.get_total_flat_seconds_for_next_turn(), 5.0)

func test_missing_config_fails_closed_without_mutation() -> void:
    var turn := _telegraph_turn_with_old_budget(9.0)
    var old_budget := turn.turn_budget
    var effects := TimeEffectState.new()

    var result: Dictionary = turn.start_player_turn(null, "NORMAL", effects)

    assert_false(result["started"])
    assert_eq(result["reason"], "MISSING_TIME_CONFIG")
    assert_same(turn.turn_budget, old_budget)
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)
