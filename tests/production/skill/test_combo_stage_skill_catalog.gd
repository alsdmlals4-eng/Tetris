## C1–C10 전술 스킬 카탈로그의 단계·적응형 효과 계약을 검증한다.
extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
    assert_true(FileAccess.file_exists(SKILL_DATA_PATH), "C1–C10 Skill seed must exist")
    var raw: String = FileAccess.get_file_as_string(SKILL_DATA_PATH) if FileAccess.file_exists(SKILL_DATA_PATH) else ""
    var data = JSON.parse_string(raw)
    assert_true(data is Dictionary, "C1–C10 Skill seed must parse as a dictionary")
    var script = load(CATALOG_PATH)
    assert_not_null(script, "ProductionSkillCatalog must exist")
    if script == null or not data is Dictionary:
        return null
    return script.from_dictionary(data)

func _has_effect(effects: Array, operation: String) -> bool:
    for raw_effect in effects:
        if raw_effect is Dictionary and String(raw_effect.get("op", "")) == operation:
            return true
    return false

func test_catalog_has_exactly_one_definition_for_each_lane_and_combo_stage() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_eq(catalog.technique_count(), 30)
    for lane in ["ATTACK", "DEFENSE", "SUPPORT"]:
        for stage in range(1, 11):
            var definition: Dictionary = catalog.definition_for_lane_stage(lane, stage)
            assert_false(definition.is_empty(), "%s C%d must be authored" % [lane, stage])
            assert_eq(String(definition.get("lane", "")), lane)
            assert_eq(int(definition.get("stage", 0)), stage)
            assert_eq(int(definition.get("combo_cost", -1)), stage)
            assert_gte(int(definition.get("mp_cost", -1)), 0)
            assert_false(String(definition.get("display_name", "")).is_empty())
            assert_true(definition.get("preview_lines", null) is Array)
            assert_false(definition.has("tier"))
            assert_false(definition.has("stock_cost"))
            assert_false(definition.has("energy_cost"))

func test_adaptive_aegis_preview_has_exactly_one_legal_current_action_package() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    var definition: Dictionary = catalog.definition_for_lane_stage("DEFENSE", 6)
    var direct: Dictionary = catalog.resolve_effects(definition, "DIRECT_HP_RATIO")
    var energy_loss: Dictionary = catalog.resolve_effects(definition, "ENERGY_LOSS")
    var stock_loss: Dictionary = catalog.resolve_effects(definition, "STOCK_LOSS")

    assert_true(bool(direct.get("ok", false)))
    assert_true(bool(energy_loss.get("ok", false)))
    assert_true(bool(stock_loss.get("ok", false)))
    assert_true(_has_effect(direct.get("effects", []), "MITIGATE_CURRENT_DIRECT"))
    assert_false(_has_effect(direct.get("effects", []), "PROTECT_RESOURCE_LOSS"))
    assert_true(_has_effect(energy_loss.get("effects", []), "PROTECT_RESOURCE_LOSS"))
    assert_false(_has_effect(energy_loss.get("effects", []), "MITIGATE_CURRENT_DIRECT"))
    assert_ne(direct.get("preview_lines", []), energy_loss.get("preview_lines", []))
    assert_ne(energy_loss.get("preview_lines", []), stock_loss.get("preview_lines", []))
    assert_string_contains(str(energy_loss.get("preview_lines", [])), "MP")
    assert_string_contains(str(stock_loss.get("preview_lines", [])), "Combo")

func test_c10_aegis_uses_only_the_current_action_package_without_unrelated_safety() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    var definition: Dictionary = catalog.definition_for_lane_stage("DEFENSE", 10)
    var direct: Dictionary = catalog.resolve_effects(definition, "DIRECT_HP_RATIO")
    var energy_loss: Dictionary = catalog.resolve_effects(definition, "ENERGY_LOSS")

    assert_true(bool(direct.get("ok", false)))
    assert_true(_has_effect(direct.get("effects", []), "MITIGATE_CURRENT_DIRECT"))
    assert_true(_has_effect(direct.get("effects", []), "COUNTER_FROM_PREVENTED_DAMAGE"))
    assert_false(_has_effect(direct.get("effects", []), "LETHAL_SAFETY"))
    assert_true(bool(energy_loss.get("ok", false)))
    assert_true(_has_effect(energy_loss.get("effects", []), "PROTECT_RESOURCE_LOSS"))
    assert_false(_has_effect(energy_loss.get("effects", []), "LETHAL_SAFETY"))

func test_catalog_rejects_legacy_tier_and_unimplemented_multiplier_schema() -> void:
    var script = load(CATALOG_PATH)
    assert_not_null(script)
    if script == null:
        return

    assert_null(script.from_dictionary({
        "balance_status": "TUNING_SEED_NOT_FINAL",
        "source_contract": "TETRIS-SKILL-039 / TETRIS-BALANCE-040 / TETRIS-SKILL-042",
        "techniques": [
            {"id": "legacy", "lane": "ATTACK", "tier": 1, "energy_cost": 10, "stock_cost": 1, "effects": [{"op": "CONDITIONAL_MULTIPLIER", "magnitude": 2}]},
        ],
    }))
