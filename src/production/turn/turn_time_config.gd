class_name TurnTimeConfig
extends RefCounted

var min_budget_seconds: float = 0.0
var max_budget_seconds: float = 0.0
var tempo_reference_seconds: float = 0.0
var potency_per_saved_ratio: float = 0.0
var potency_bonus_cap_ratio: float = 0.0
var _difficulty_profiles: Dictionary = {}

static func from_dictionary(data: Dictionary) -> TurnTimeConfig:
    var config := TurnTimeConfig.new()
    var shared: Dictionary = data.get("shared_turn_budget", {})
    var reward: Dictionary = data.get("tempo_reward", {})

    config.min_budget_seconds = float(shared.get("min_budget_seconds", 0.0))
    config.max_budget_seconds = float(shared.get("max_budget_seconds", 0.0))
    config.tempo_reference_seconds = float(shared.get("tempo_reference_seconds", 0.0))
    config.potency_per_saved_ratio = float(reward.get("potency_per_saved_ratio", 0.0))
    config.potency_bonus_cap_ratio = float(reward.get("potency_bonus_cap_ratio", 0.0))
    config._difficulty_profiles = data.get("difficulty_profiles", {}).duplicate(true)
    return config

func has_difficulty_profile(profile_id: String) -> bool:
    return _difficulty_profiles.has(profile_id)

func get_base_budget_seconds(profile_id: String) -> float:
    if not has_difficulty_profile(profile_id):
        return 0.0
    var profile: Dictionary = _difficulty_profiles[profile_id]
    return float(profile.get("base_budget_seconds", 0.0))

func create_budget(profile_id: String, effects: TimeEffectState):
    if not has_difficulty_profile(profile_id):
        return null

    var budget := TurnBudget.new()
    var flat_modifier_seconds := 0.0
    if effects != null:
        flat_modifier_seconds = effects.get_total_flat_seconds_for_next_turn()
    budget.snapshot(
        get_base_budget_seconds(profile_id),
        flat_modifier_seconds,
        min_budget_seconds,
        max_budget_seconds
    )
    return budget
