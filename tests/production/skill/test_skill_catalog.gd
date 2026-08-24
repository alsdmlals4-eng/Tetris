extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const DATA_PATH := "res://data/production/vanguard_skill_seed.json"

const EXPECTED_LANES := ["ATTACK", "DEFENSE", "SUPPORT"]
const ALLOWED_EFFECT_OPS := [
    "DAMAGE_SINGLE",
    "DAMAGE_AOE",
    "MITIGATE_CURRENT_DIRECT",
    "COUNTER_FROM_PREVENTED_DAMAGE",
    "HEAL_SELF",
    "APPLY_SELF_BUFF",
    "APPLY_ENEMY_DEBUFF",
    "PROTECT_RESOURCE_LOSS",
    "MODIFY_NEXT_TURN_BUDGET",
    "CONDITIONAL_MULTIPLIER",
    "LETHAL_SAFETY",
    "TARGET_PATTERN",
]

func _load_catalog():
    assert_true(ResourceLoader.exists(CATALOG_PATH), "ProductionSkillCatalog script must exist")
    assert_true(FileAccess.file_exists(DATA_PATH), "vanguard skill seed data must exist")
    if not ResourceLoader.exists(CATALOG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    assert_typeof(parsed, TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return null
    return load(CATALOG_PATH).from_dictionary(parsed)

func test_catalog_declares_non_final_tuning_seed_and_exact_eighteen_cells() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return

    assert_eq(catalog.balance_status, "TUNING_SEED_NOT_FINAL")
    assert_eq(catalog.technique_count(), 18)
    assert_eq(catalog.all_ids().size(), 18, "technique ids must be unique")

func test_each_lane_has_exactly_one_cell_for_tiers_one_through_six() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return

    for lane in EXPECTED_LANES:
        var lane_defs: Array = catalog.for_lane(lane)
        assert_eq(lane_defs.size(), 6, "%s must expose six cells" % lane)
        var tiers: Array[int] = []
        for definition in lane_defs:
            tiers.append(int(definition["tier"]))
        tiers.sort()
        assert_eq(tiers, [1, 2, 3, 4, 5, 6])

func test_stock_cost_equals_tier_and_energy_cost_is_explicit_non_negative_seed() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return

    for definition in catalog.all_definitions():
        var tier: int = int(definition["tier"])
        assert_eq(int(definition["stock_cost"]), tier, "%s must spend exactly Tier N Stock" % definition["id"])
        assert_true(definition.has("energy_cost"))
        assert_true(int(definition["energy_cost"]) >= 0)

func test_every_effect_uses_bounded_approved_primitive_vocabulary() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return

    for definition in catalog.all_definitions():
        var effects: Array = definition.get("effects", [])
        assert_true(effects.size() > 0, "%s must compose at least one effect primitive" % definition["id"])
        for effect in effects:
            assert_true(ALLOWED_EFFECT_OPS.has(String(effect.get("op", ""))), "%s has unknown effect op" % definition["id"])

func test_current_and_future_control_cells_encode_target_scope_explicitly() -> void:
    var catalog = _load_catalog()
    if catalog == null:
        return

    var atk_t5: Dictionary = catalog.get_by_id("atk_t5_suppressive_break")
    var def_t5: Dictionary = catalog.get_by_id("def_t5_rift_ward")
    var sup_t5: Dictionary = catalog.get_by_id("sup_t5_rift_seal")

    assert_eq(atk_t5.get("control_scope", ""), "VISIBLE_NEXT_FORECAST_DIRECT")
    assert_eq(def_t5.get("control_scope", ""), "CURRENT_TELEGRAPH_RESOURCE_LOSS")
    assert_eq(sup_t5.get("control_scope", ""), "VISIBLE_NEXT_FORECAST_RIFT_UTILITY")
