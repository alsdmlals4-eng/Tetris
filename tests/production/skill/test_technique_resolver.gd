extends GutTest

const RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
    return load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _resolver():
    assert_true(ResourceLoader.exists(RESOLVER_PATH), "ProductionTechniqueResolver script must exist")
    if not ResourceLoader.exists(RESOLVER_PATH):
        return null
    return load(RESOLVER_PATH).new(ProductionEffectExecutor.new())

func test_attack_t3_resolves_ordered_damage_then_breach_status() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()

    var result: Dictionary = resolver.resolve(
        catalog.get_by_id("atk_t3_rift_breach"),
        {"player": player, "enemy": enemy, "status_state": status}
    )

    assert_true(result["resolved"])
    assert_eq(result["effect_results"].size(), 2)
    assert_eq(result["effect_results"][0]["op"], "DAMAGE_SINGLE")
    assert_eq(result["effect_results"][1]["op"], "APPLY_ENEMY_DEBUFF")
    assert_eq(enemy.hp, 82)
    assert_true(status.has_status("BREACH", "enemy"))

func test_defense_t3_builds_exact_current_response_without_resolving_enemy_early() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var response := ProductionResponseState.new()

    var result: Dictionary = resolver.resolve(
        catalog.get_by_id("def_t3_counter_stance"),
        {"response_state": response, "current_telegraph_action_id": "gatebreaker_slam_7"}
    )

    assert_true(result["resolved"])
    var modifiers: Dictionary = response.modifiers_for_action("gatebreaker_slam_7")
    assert_eq(modifiers["direct_mitigation"], 16)
    assert_eq(modifiers["counter_ratio"], 0.5)

func test_haste_uses_seed_owned_next_turn_modifier_contract() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var time_state := TimeEffectState.new()

    var result: Dictionary = resolver.resolve(
        catalog.get_by_id("sup_t3_haste"),
        {"time_effect_state": time_state}
    )

    assert_true(result["resolved"])
    assert_eq(time_state.get_total_flat_seconds_for_next_turn(), 5.0)
    assert_eq(result["effect_results"][0]["stack_group"], "haste_default")
    assert_false(result["effect_results"][0]["tempo_scalable"])

func test_attack_t5_requires_visible_next_direct_forecast_before_any_effect_runs() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()

    var rejected: Dictionary = resolver.resolve(
        catalog.get_by_id("atk_t5_suppressive_break"),
        {"enemy": enemy, "status_state": status, "next_forecast_action_id": "rift_siphon_2", "next_forecast_tags": ["RIFT_UTILITY"]}
    )

    assert_false(rejected["resolved"])
    assert_eq(rejected["reason"], "FORECAST_SCOPE_MISMATCH")
    assert_eq(enemy.hp, 100, "preflight must reject before damage is partially applied")

    var accepted: Dictionary = resolver.resolve(
        catalog.get_by_id("atk_t5_suppressive_break"),
        {"enemy": enemy, "status_state": status, "next_forecast_action_id": "gatebreaker_slam_8", "next_forecast_tags": ["DIRECT_HIT"]}
    )
    assert_true(accepted["resolved"])
    assert_eq(enemy.hp, 76)
    assert_true(status.matches_bound_action("WEAKEN", "enemy", "gatebreaker_slam_8"))

func test_support_t5_requires_visible_next_rift_utility_forecast() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var status := ProductionStatusState.new()

    var rejected: Dictionary = resolver.resolve(
        catalog.get_by_id("sup_t5_rift_seal"),
        {"status_state": status, "next_forecast_action_id": "light_smash_4", "next_forecast_tags": ["DIRECT_HIT"]}
    )
    assert_false(rejected["resolved"])
    assert_eq(rejected["reason"], "FORECAST_SCOPE_MISMATCH")

    var accepted: Dictionary = resolver.resolve(
        catalog.get_by_id("sup_t5_rift_seal"),
        {"status_state": status, "next_forecast_action_id": "rift_repair_1", "next_forecast_tags": ["RIFT_UTILITY", "REPAIR"]}
    )
    assert_true(accepted["resolved"])
    assert_true(status.matches_bound_action("RIFT_SEAL", "enemy", "rift_repair_1"))

func test_tune_required_effect_is_rejected_in_preflight_without_resource_or_target_mutation() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()

    var result: Dictionary = resolver.resolve(
        catalog.get_by_id("sup_t4_mark_weakness"),
        {"enemy": enemy, "status_state": status}
    )

    assert_false(result["resolved"])
    assert_eq(result["reason"], "EFFECT_CONTRACT_UNRESOLVED")
    assert_eq(enemy.hp, 100)

func test_runtime_unimplemented_primitive_is_rejected_before_partial_effect_execution() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var enemy := ProductionCombatState.new(100)

    var result: Dictionary = resolver.resolve(
        catalog.get_by_id("atk_t6_execution_edge"),
        {"enemy": enemy, "status_state": ProductionStatusState.new()}
    )

    assert_false(result["resolved"])
    assert_eq(result["reason"], "EFFECT_OP_NOT_RUNTIME_READY")
    assert_eq(enemy.hp, 100, "conditional multiplier preflight must fail before the preceding base damage executes")

func test_runtime_readiness_is_public_non_mutating_and_matches_resolve_preflight() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()

    var state: Dictionary = resolver.readiness(
        catalog.get_by_id("atk_t3_rift_breach"),
        {"enemy": enemy, "status_state": status}
    )

    assert_true(state["ready"])
    assert_eq(state["reason"], "READY")
    assert_eq(enemy.hp, 100)
    assert_false(status.has_status("BREACH", "enemy"))

func test_runtime_readiness_reports_unresolved_contract_before_resource_commit() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var catalog = _catalog()

    var state: Dictionary = resolver.readiness(
        catalog.get_by_id("sup_t4_mark_weakness"),
        {"enemy": ProductionCombatState.new(100), "status_state": ProductionStatusState.new()}
    )

    assert_false(state["ready"])
    assert_eq(state["reason"], "EFFECT_CONTRACT_UNRESOLVED")
