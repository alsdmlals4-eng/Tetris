## Combo C1-C10 data definitions and adaptive current-threat previews must stay deterministic.
extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const SEED_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
	var data = JSON.parse_string(FileAccess.get_file_as_string(SEED_PATH))
	assert_true(data is Dictionary, "the production skill seed must remain valid JSON object data")
	if not (data is Dictionary):
		return null
	return load(CATALOG_PATH).from_dictionary(data)

func test_catalog_has_exactly_one_combo_stage_definition_per_lane() -> void:
	var catalog = _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	assert_true(catalog.has_method("definition_for_lane_stage"), "the catalog must resolve one definition from lane plus current Combo stage")
	if not catalog.has_method("definition_for_lane_stage"):
		return
	assert_eq(catalog.technique_count(), 30)
	for lane in ["ATTACK", "DEFENSE", "SUPPORT"]:
		for stage in range(1, 11):
			var definition: Dictionary = catalog.definition_for_lane_stage(lane, stage)
			assert_eq(String(definition.get("lane", "")), lane)
			assert_eq(int(definition.get("stage", 0)), stage)
			assert_eq(int(definition.get("combo_cost", 0)), stage)
			assert_gte(int(definition.get("mp_cost", 0)), 0)
			assert_ne(String(definition.get("display_name", "")), "")
			assert_true(definition.get("preview_lines", []) is Array)

func test_adaptive_aegis_reveals_exactly_one_legal_current_threat_package() -> void:
	var catalog = _catalog()
	assert_not_null(catalog)
	if catalog == null:
		return
	assert_true(catalog.has_method("definition_for_lane_stage"))
	assert_true(catalog.has_method("resolve_effects"), "adaptive technique previews must resolve at catalog time")
	if not catalog.has_method("definition_for_lane_stage") or not catalog.has_method("resolve_effects"):
		return
	var aegis: Dictionary = catalog.definition_for_lane_stage("DEFENSE", 6)
	var direct: Dictionary = catalog.resolve_effects(aegis, "DIRECT_HP_RATIO")
	var resource: Dictionary = catalog.resolve_effects(aegis, "ENERGY_LOSS")
	assert_true(bool(direct.get("ok", false)))
	assert_true(bool(resource.get("ok", false)))
	assert_ne(direct.get("preview_lines", []), resource.get("preview_lines", []))
	assert_true((direct.get("effects", []) as Array).any(func(effect): return String(effect.get("op", "")) == "MITIGATE_CURRENT_DIRECT"))
	assert_false((direct.get("effects", []) as Array).any(func(effect): return String(effect.get("op", "")) == "PROTECT_RESOURCE_LOSS"))
	assert_true((resource.get("effects", []) as Array).any(func(effect): return String(effect.get("op", "")) == "PROTECT_RESOURCE_LOSS"))
	assert_false(bool(catalog.resolve_effects(aegis, "UNKNOWN_ACTION").get("ok", true)))

func test_catalog_rejects_legacy_tier_and_unimplemented_multiplier_definitions() -> void:
	var legacy_tier := {
		"balance_status": "TUNING_SEED_NOT_FINAL",
		"techniques": [{"id": "legacy", "lane": "ATTACK", "tier": 1, "energy_cost": 10, "stock_cost": 1, "effects": [{"op": "DAMAGE_SINGLE", "magnitude": 10}]}],
	}
	assert_null(load(CATALOG_PATH).from_dictionary(legacy_tier))
	var multiplier := {
		"schema_version": 2,
		"balance_status": "TUNING_SEED_NOT_FINAL",
		"techniques": [{"id": "invalid_multiplier", "lane": "ATTACK", "stage": 1, "combo_cost": 1, "mp_cost": 10, "display_name": "Invalid", "preview_lines": ["Invalid"], "effects": [{"op": "CONDITIONAL_MULTIPLIER", "magnitude": 2}]}],
	}
	assert_null(load(CATALOG_PATH).from_dictionary(multiplier))
