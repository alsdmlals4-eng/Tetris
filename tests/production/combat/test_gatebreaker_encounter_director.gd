## Gatebreaker encounter director의 authored 순서와 phase 전이를 검증한다.
extends GutTest

const DIRECTOR_PATH := "res://src/production/combat/gatebreaker_encounter_director.gd"
const ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"

func _catalog():
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ACTION_DATA_PATH)))

func _director():
    assert_true(ResourceLoader.exists(DIRECTOR_PATH), "GatebreakerEncounterDirector script must exist")
    assert_true(FileAccess.file_exists(SEQUENCE_DATA_PATH), "Gatebreaker sequence seed must exist")
    if not ResourceLoader.exists(DIRECTOR_PATH) or not FileAccess.file_exists(SEQUENCE_DATA_PATH):
        return null
    return load(DIRECTOR_PATH).from_dictionary(
        JSON.parse_string(FileAccess.get_file_as_string(SEQUENCE_DATA_PATH)),
        _catalog()
    )

func test_bootstrap_uses_first_run_light_smash_then_first_slam_without_player_state_input() -> void:
    var director = _director()
    if director == null:
        return

    var pair: Dictionary = director.bootstrap()

    assert_eq(director.balance_status, "TUNING_SEED_NOT_FINAL")
    assert_eq(pair["current"]["template_key"], "light_smash")
    assert_eq(pair["next"]["template_key"], "gatebreaker_slam")
    assert_eq(pair["current"]["id"], "gatebreaker:light_smash:1")
    assert_eq(pair["next"]["id"], "gatebreaker:gatebreaker_slam:2")
    assert_eq(director.current_phase, 1)

func test_phase_thresholds_are_monotonic_and_do_not_rewind_after_repair_healing() -> void:
    var director = _director()
    if director == null:
        return
    director.bootstrap()

    assert_eq(director.phase_for_hp_ratio(0.71), 1)
    assert_eq(director.phase_for_hp_ratio(0.70), 2)
    assert_eq(director.phase_for_hp_ratio(0.31), 2)
    assert_eq(director.phase_for_hp_ratio(0.30), 3)

    var phase3: Dictionary = director.schedule_next_after_resolve(0.29)
    assert_eq(director.current_phase, 3)
    assert_eq(phase3["template_key"], "siege_charge")

    var after_heal: Dictionary = director.schedule_next_after_resolve(0.36)
    assert_eq(director.current_phase, 3, "encounter phase may not rewind after entering a later HP phase")
    assert_eq(after_heal["template_key"], "light_smash")

func test_phase_two_starts_with_authored_siphon_and_preserves_base_ladder_order() -> void:
    var director = _director()
    if director == null:
        return
    director.bootstrap()

    var p2_1: Dictionary = director.schedule_next_after_resolve(0.69)
    var p2_2: Dictionary = director.schedule_next_after_resolve(0.60)
    var p2_3: Dictionary = director.schedule_next_after_resolve(0.55)
    var p2_4: Dictionary = director.schedule_next_after_resolve(0.51)

    assert_eq([
        p2_1["template_key"],
        p2_2["template_key"],
        p2_3["template_key"],
        p2_4["template_key"],
    ], ["rift_siphon", "gatebreaker_slam", "chain_fracture", "light_smash"])

func test_phase_two_repair_is_single_use_near_half_hp_and_resume_does_not_skip_ladder_position() -> void:
    var director = _director()
    if director == null:
        return
    director.bootstrap()

    var siphon: Dictionary = director.schedule_next_after_resolve(0.69)
    var repair: Dictionary = director.schedule_next_after_resolve(0.49)
    var resumed: Dictionary = director.schedule_next_after_resolve(0.48)
    assert_eq(siphon["template_key"], "rift_siphon")
    assert_eq(repair["template_key"], "rift_repair")
    assert_eq(resumed["template_key"], "gatebreaker_slam")
    assert_true(director.repair_used)

    director.schedule_next_after_resolve(0.47)
    director.schedule_next_after_resolve(0.46)
    var next_cycle: Dictionary = director.schedule_next_after_resolve(0.45)
    assert_eq(next_cycle["template_key"], "rift_siphon", "Repair must not recur in the same encounter")

func test_phase_three_first_new_authored_action_is_siege_then_uses_no_repair_cycle() -> void:
    var director = _director()
    if director == null:
        return
    director.bootstrap()

    var siege: Dictionary = director.schedule_next_after_resolve(0.29)
    var light: Dictionary = director.schedule_next_after_resolve(0.28)
    var siphon: Dictionary = director.schedule_next_after_resolve(0.27)
    var heavy: Dictionary = director.schedule_next_after_resolve(0.26)
    var fracture: Dictionary = director.schedule_next_after_resolve(0.25)

    assert_eq([
        siege["template_key"],
        light["template_key"],
        siphon["template_key"],
        heavy["template_key"],
        fracture["template_key"],
    ], ["siege_charge", "light_smash", "rift_siphon", "gatebreaker_slam", "chain_fracture"])
    assert_false(director.repair_used)

func test_scheduled_actions_are_catalog_valid_for_the_phase_that_created_them() -> void:
    var director = _director()
    if director == null:
        return
    var catalog = _catalog()
    director.bootstrap()

    var p2: Dictionary = director.schedule_next_after_resolve(0.69)
    assert_true(catalog.is_allowed_in_phase(p2["template_key"], 2))

    var p3: Dictionary = director.schedule_next_after_resolve(0.29)
    assert_true(catalog.is_allowed_in_phase(p3["template_key"], 3))
    assert_ne(p3["template_key"], "rift_repair")

func test_invalid_or_out_of_canon_sequence_data_refuses_director_construction() -> void:
    assert_null(load(DIRECTOR_PATH).from_dictionary({
        "balance_status": "TUNING_SEED_NOT_FINAL",
        "phase_2_at_or_below": 0.70,
        "phase_3_at_or_below": 0.30,
        "phase_1_cycle": ["light_smash"],
        "phase_2_cycle": ["hidden_reactive_counter"],
        "phase_2_repair": {"key": "rift_repair", "trigger_at_or_below": 0.50, "max_uses": 1, "requires_base_actions_scheduled": 1},
        "phase_3_entry": "siege_charge",
        "phase_3_cycle": ["light_smash"]
    }, _catalog()))
