extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"
const DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
    return load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _resolver():
    return load(RESOLVER_PATH).new(ProductionEffectExecutor.new())

func _definition() -> Dictionary:
    return _catalog().get_by_id("atk_t6_execution_edge")

func test_execution_edge_without_pre_resolution_condition_uses_base_damage_only() -> void:
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()

    var result: Dictionary = _resolver().resolve(_definition(), {
        "enemy": enemy,
        "status_state": status,
    })

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 72)
    assert_eq(result["effect_results"][0]["amount"], 28)
    assert_false(result.get("conditional_multiplier_applied", false))

func test_execution_edge_low_hp_condition_uses_pre_resolution_hp_snapshot() -> void:
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()
    enemy.apply_damage(80)

    var result: Dictionary = _resolver().resolve(_definition(), {
        "enemy": enemy,
        "status_state": status,
    })

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 0)
    assert_eq(result["effect_results"][0]["amount"], 20, "applied damage clamps to remaining HP")
    assert_true(result["conditional_multiplier_applied"])
    assert_eq(result["conditional_multiplier"], 1.8)
    assert_eq(result["prepared_damage_magnitude"], 50, "28 × 1.8 uses deterministic nearest-integer damage preparation")

func test_execution_edge_does_not_retroactively_qualify_after_base_hit_crosses_hp_threshold() -> void:
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()
    enemy.apply_damage(60)

    var result: Dictionary = _resolver().resolve(_definition(), {
        "enemy": enemy,
        "status_state": status,
    })

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 12)
    assert_false(result.get("conditional_multiplier_applied", false))

func test_execution_edge_breach_condition_is_snapshotted_then_consumed_after_successful_attack() -> void:
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()
    assert_true(status.apply_status("BREACH", "enemy"))

    var result: Dictionary = _resolver().resolve(_definition(), {
        "enemy": enemy,
        "status_state": status,
    })

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 50)
    assert_true(result["conditional_multiplier_applied"])
    assert_false(status.has_status("BREACH", "enemy"), "qualifying ATK consumes BREACH only after successful resolution")

func test_execution_edge_preflight_failure_does_not_consume_breach_or_mutate_enemy() -> void:
    var enemy := ProductionCombatState.new(100)
    var status := ProductionStatusState.new()
    assert_true(status.apply_status("BREACH", "enemy"))
    var invalid := _definition().duplicate(true)
    invalid["effects"].append({"op": "INVENTED_RUNTIME_MAGIC"})

    var result: Dictionary = _resolver().resolve(invalid, {
        "enemy": enemy,
        "status_state": status,
    })

    assert_false(result["resolved"])
    assert_eq(enemy.hp, 100)
    assert_true(status.has_status("BREACH", "enemy"))
