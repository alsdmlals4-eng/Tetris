extends GutTest

const EVALUATOR_PATH := "res://src/production/combat/tempo_evaluator.gd"
const CONFIG_PATH := "res://data/production/turn_time_config.json"

func _evaluator():
    assert_true(ResourceLoader.exists(EVALUATOR_PATH), "TempoEvaluator script must exist")
    if not ResourceLoader.exists(EVALUATOR_PATH):
        return null
    return load(EVALUATOR_PATH)

func test_same_active_time_has_same_tempo_from_same_reference() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var a = evaluator.evaluate(90.0, 45.0, true, true, true, false, false, 0.20, 0.15)
    var b = evaluator.evaluate(90.0, 45.0, true, true, true, false, false, 0.20, 0.15)
    assert_almost_eq(a.saved_ratio, b.saved_ratio, 0.0001)
    assert_almost_eq(a.potency_bonus_ratio, b.potency_bonus_ratio, 0.0001)

func test_faster_eligible_completion_never_rewards_less() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var slow = evaluator.evaluate(90.0, 70.0, true, true, true, false, false, 0.20, 0.15)
    var fast = evaluator.evaluate(90.0, 40.0, true, true, true, false, false, 0.20, 0.15)
    assert_true(fast.potency_bonus_ratio >= slow.potency_bonus_ratio)

func test_saved_ratio_and_reward_curve_are_capped() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var result = evaluator.evaluate(90.0, 0.0, true, true, true, false, false, 1.0, 0.12)
    assert_almost_eq(result.saved_ratio, 1.0, 0.0001)
    assert_almost_eq(result.potency_bonus_ratio, 0.12, 0.0001)

func test_reward_curve_is_data_driven() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var stronger = evaluator.evaluate(90.0, 45.0, true, true, true, false, false, 0.40, 1.0)
    var lighter = evaluator.evaluate(90.0, 45.0, true, true, true, false, false, 0.10, 1.0)
    assert_almost_eq(stronger.saved_ratio, 0.5, 0.0001)
    assert_almost_eq(stronger.potency_bonus_ratio, 0.20, 0.0001)
    assert_almost_eq(lighter.potency_bonus_ratio, 0.05, 0.0001)

func test_missing_qualification_or_fallback_blocks_tempo() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var cases = [
        [false, true, true, false, false, "LINE_REQUIRED"],
        [true, false, true, false, false, "CHAIN_REQUIRED"],
        [true, true, false, false, false, "NON_PASS_ACTION_REQUIRED"],
        [true, true, true, true, false, "TIMEOUT"],
        [true, true, true, false, true, "BOARD_BREAK"]
    ]
    for item in cases:
        var result = evaluator.evaluate(90.0, 40.0, item[0], item[1], item[2], item[3], item[4], 0.20, 0.15)
        assert_false(result.eligible)
        assert_eq(result.ineligible_reason, item[5])
        assert_almost_eq(result.potency_bonus_ratio, 0.0, 0.0001)

func test_invalid_reference_is_ineligible_and_safe() -> void:
    var evaluator = _evaluator()
    if evaluator == null:
        return
    var result = evaluator.evaluate(0.0, 10.0, true, true, true, false, false, 0.20, 0.15)
    assert_false(result.eligible)
    assert_eq(result.ineligible_reason, "INVALID_REFERENCE")
    assert_almost_eq(result.saved_ratio, 0.0, 0.0001)

func test_turn_time_config_declares_non_final_tempo_curve_seed() -> void:
    assert_true(FileAccess.file_exists(CONFIG_PATH))
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
    assert_eq(parsed["balance_status"], "TUNING_SEED_NOT_FINAL")
    assert_true(parsed.has("tempo_reward"), "tempo reward curve must be data-driven")
    if not parsed.has("tempo_reward"):
        return
    assert_true(parsed["tempo_reward"].has("potency_per_saved_ratio"))
    assert_true(parsed["tempo_reward"].has("potency_bonus_cap_ratio"))
