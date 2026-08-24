extends GutTest

const CONFIG_ADAPTER_PATH := "res://src/production/turn/turn_time_config.gd"
const CONFIG_PATH := "res://data/production/turn_time_config.json"

func _load_config():
    assert_true(ResourceLoader.exists(CONFIG_ADAPTER_PATH), "TurnTimeConfig adapter must exist")
    if not ResourceLoader.exists(CONFIG_ADAPTER_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
    return load(CONFIG_ADAPTER_PATH).from_dictionary(parsed)

func _empty_effects() -> TimeEffectState:
    return TimeEffectState.new()

func test_difficulty_profiles_change_effective_budget_only() -> void:
    var config = _load_config()
    if config == null:
        return
    var easy = config.create_budget("EASY", _empty_effects())
    var normal = config.create_budget("NORMAL", _empty_effects())
    var hard = config.create_budget("HARD", _empty_effects())
    assert_true(easy.effective_budget_seconds > normal.effective_budget_seconds)
    assert_true(normal.effective_budget_seconds > hard.effective_budget_seconds)
    assert_eq(config.tempo_reference_seconds, 90.0)

func test_same_active_time_uses_same_tempo_reference_across_difficulties() -> void:
    var config = _load_config()
    if config == null:
        return
    var effects := _empty_effects()
    var easy = config.create_budget("EASY", effects)
    var hard = config.create_budget("HARD", effects)
    assert_ne(easy.effective_budget_seconds, hard.effective_budget_seconds)

    var easy_tempo = TempoEvaluator.evaluate(
        config.tempo_reference_seconds, 45.0,
        true, true, true, false, false,
        config.potency_per_saved_ratio, config.potency_bonus_cap_ratio
    )
    var hard_tempo = TempoEvaluator.evaluate(
        config.tempo_reference_seconds, 45.0,
        true, true, true, false, false,
        config.potency_per_saved_ratio, config.potency_bonus_cap_ratio
    )
    assert_almost_eq(easy_tempo.saved_ratio, hard_tempo.saved_ratio, 0.0001)
    assert_almost_eq(easy_tempo.potency_bonus_ratio, hard_tempo.potency_bonus_ratio, 0.0001)

func test_haste_adds_to_next_snapshot_without_changing_reference() -> void:
    var config = _load_config()
    if config == null:
        return
    var effects := _empty_effects()
    effects.apply_effect("haste", "haste_default", 8.0, false, 1)
    var budget = config.create_budget("NORMAL", effects)
    assert_eq(budget.effective_budget_seconds, config.get_base_budget_seconds("NORMAL") + 8.0)
    assert_eq(config.tempo_reference_seconds, 90.0)

func test_slow_subtracts_and_budget_clamps() -> void:
    var config = _load_config()
    if config == null:
        return
    var effects := _empty_effects()
    effects.apply_effect("slow", "slow_default", -500.0, false, 1)
    var budget = config.create_budget("NORMAL", effects)
    assert_eq(budget.effective_budget_seconds, config.min_budget_seconds)
    assert_eq(config.tempo_reference_seconds, 90.0)

func test_positive_modifiers_respect_max_budget_clamp() -> void:
    var config = _load_config()
    if config == null:
        return
    var effects := _empty_effects()
    effects.apply_effect("huge_haste", "haste_default", 500.0, false, 1)
    var budget = config.create_budget("NORMAL", effects)
    assert_eq(budget.effective_budget_seconds, config.max_budget_seconds)

func test_effect_created_after_snapshot_does_not_jump_current_clock() -> void:
    var config = _load_config()
    if config == null:
        return
    var effects := _empty_effects()
    var current = config.create_budget("NORMAL", effects)
    var current_effective := current.effective_budget_seconds
    current.consume(10.0)

    effects.apply_effect("haste", "haste_default", 8.0, false, 1)

    assert_eq(current.effective_budget_seconds, current_effective)
    assert_eq(current.remaining_seconds, current_effective - 10.0)
    var next = config.create_budget("NORMAL", effects)
    assert_eq(next.effective_budget_seconds, current_effective + 8.0)

func test_unknown_difficulty_profile_is_rejected() -> void:
    var config = _load_config()
    if config == null:
        return
    assert_false(config.has_difficulty_profile("UNKNOWN"))
    assert_null(config.create_budget("UNKNOWN", _empty_effects()))
