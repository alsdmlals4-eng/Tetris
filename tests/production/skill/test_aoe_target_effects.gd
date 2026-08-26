extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
    return load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _resolver():
    return load(RESOLVER_PATH).new(ProductionEffectExecutor.new())

func test_damage_aoe_uses_single_gatebreaker_fallback_without_changing_aoe_semantics() -> void:
    var enemy := ProductionCombatState.new(100)
    var result := ProductionEffectExecutor.new().execute(
        {"op": "DAMAGE_AOE", "magnitude": 16},
        {"enemy": enemy}
    )

    assert_true(result["applied"])
    assert_eq(result["target_count"], 1)
    assert_eq(result["total_damage"], 16)
    assert_eq(enemy.hp, 84)

func test_damage_aoe_damages_each_explicit_enemy_once() -> void:
    var enemy_a := ProductionCombatState.new(100)
    var enemy_b := ProductionCombatState.new(80)
    var result := ProductionEffectExecutor.new().execute(
        {"op": "DAMAGE_AOE", "magnitude": 16},
        {"enemies": [enemy_a, enemy_b]}
    )

    assert_true(result["applied"])
    assert_eq(result["target_count"], 2)
    assert_eq(result["total_damage"], 32)
    assert_eq(enemy_a.hp, 84)
    assert_eq(enemy_b.hp, 64)

func test_target_pattern_reports_resolved_targets_without_mutating_them() -> void:
    var enemy := ProductionCombatState.new(100)
    var result := ProductionEffectExecutor.new().execute(
        {"op": "TARGET_PATTERN", "pattern": "ALL_ENEMIES", "single_target_fallback": true},
        {"enemy": enemy}
    )

    assert_true(result["applied"])
    assert_eq(result["pattern"], "ALL_ENEMIES")
    assert_eq(result["target_count"], 1)
    assert_eq(enemy.hp, 100)

func test_sweeping_cut_resolves_against_single_gatebreaker_in_first_slice() -> void:
    var enemy := ProductionCombatState.new(100)
    var definition: Dictionary = _catalog().get_by_id("atk_t2_sweeping_cut")

    var result: Dictionary = _resolver().resolve(definition, {"enemy": enemy})

    assert_true(result["resolved"])
    assert_eq(result["effect_results"].size(), 2)
    assert_eq(result["effect_results"][0]["op"], "DAMAGE_AOE")
    assert_eq(result["effect_results"][1]["op"], "TARGET_PATTERN")
    assert_eq(enemy.hp, 84)
