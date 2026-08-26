## Gatebreaker authored 행동 catalog 유효성을 검증한다.
extends GutTest

const DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const CATALOG_PATH := "res://src/production/combat/gatebreaker_action_catalog.gd"

func _catalog():
    assert_true(ResourceLoader.exists(CATALOG_PATH), "GatebreakerActionCatalog script must exist")
    assert_true(FileAccess.file_exists(DATA_PATH), "Gatebreaker authored action seed must exist")
    if not ResourceLoader.exists(CATALOG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    assert_true(parsed is Dictionary)
    if not parsed is Dictionary:
        return null
    return load(CATALOG_PATH).from_dictionary(parsed)

func test_catalog_contains_exact_six_current_gatebreaker_action_templates() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_eq(catalog.keys(), [
        "light_smash",
        "gatebreaker_slam",
        "rift_siphon",
        "chain_fracture",
        "rift_repair",
        "siege_charge",
    ])

func test_seed_values_match_current_human_encounter_canon() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_eq(catalog.get_by_key("light_smash")["kind"], "DIRECT_HP_RATIO")
    assert_almost_eq(float(catalog.get_by_key("light_smash")["hp_ratio"]), 0.12, 0.001)
    assert_almost_eq(float(catalog.get_by_key("gatebreaker_slam")["hp_ratio"]), 0.35, 0.001)
    assert_eq(int(catalog.get_by_key("rift_siphon")["amount"]), 20)
    assert_eq(int(catalog.get_by_key("chain_fracture")["amount"]), 2)
    assert_almost_eq(float(catalog.get_by_key("rift_repair")["hp_ratio"]), 0.08, 0.001)
    assert_almost_eq(float(catalog.get_by_key("siege_charge")["hp_ratio"]), 0.55, 0.001)

func test_phase_permissions_follow_current_gatebreaker_phase_contract() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_true(catalog.is_allowed_in_phase("light_smash", 1))
    assert_true(catalog.is_allowed_in_phase("gatebreaker_slam", 1))
    assert_false(catalog.is_allowed_in_phase("rift_siphon", 1))
    assert_false(catalog.is_allowed_in_phase("chain_fracture", 1))
    assert_false(catalog.is_allowed_in_phase("rift_repair", 1))
    assert_false(catalog.is_allowed_in_phase("siege_charge", 1))

    for key in ["light_smash", "gatebreaker_slam", "rift_siphon", "chain_fracture", "rift_repair"]:
        assert_true(catalog.is_allowed_in_phase(key, 2), "%s should be available in Phase 2" % key)
    assert_false(catalog.is_allowed_in_phase("siege_charge", 2))

    for key in ["light_smash", "gatebreaker_slam", "rift_siphon", "chain_fracture", "siege_charge"]:
        assert_true(catalog.is_allowed_in_phase(key, 3), "%s should be available in Phase 3" % key)
    assert_false(catalog.is_allowed_in_phase("rift_repair", 3), "Rift Repair is removed in Phase 3")

func test_tags_expose_only_authored_direct_or_rift_utility_scope() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_true(catalog.get_by_key("light_smash")["tags"].has("DIRECT_HIT"))
    assert_true(catalog.get_by_key("gatebreaker_slam")["tags"].has("DIRECT_HIT"))
    assert_true(catalog.get_by_key("siege_charge")["tags"].has("DIRECT_HIT"))
    assert_true(catalog.get_by_key("rift_siphon")["tags"].has("RIFT_UTILITY"))
    assert_true(catalog.get_by_key("chain_fracture")["tags"].has("RIFT_UTILITY"))
    assert_true(catalog.get_by_key("rift_repair")["tags"].has("RIFT_UTILITY"))

func test_instantiated_actions_receive_stable_exact_ids_without_mutating_templates() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    var first: Dictionary = catalog.instantiate_action("gatebreaker_slam", 4)
    var repeated: Dictionary = catalog.instantiate_action("gatebreaker_slam", 4)
    var next: Dictionary = catalog.instantiate_action("gatebreaker_slam", 5)

    assert_ne(first["id"], "")
    assert_eq(first["id"], repeated["id"])
    assert_ne(first["id"], next["id"])
    assert_eq(first["template_key"], "gatebreaker_slam")
    assert_false(catalog.get_by_key("gatebreaker_slam").has("id"), "authored template must remain immutable when an encounter action instance is created")

func test_invalid_template_or_phase_fails_closed() -> void:
    var catalog = _catalog()
    if catalog == null:
        return

    assert_true(catalog.get_by_key("hidden_reactive_counter").is_empty())
    assert_false(catalog.is_allowed_in_phase("light_smash", 0))
    assert_false(catalog.is_allowed_in_phase("light_smash", 4))
    assert_true(catalog.instantiate_action("hidden_reactive_counter", 1).is_empty())
