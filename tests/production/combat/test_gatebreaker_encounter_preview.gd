## Gatebreaker 다음 행동 preview가 상태를 바꾸지 않는지 검증한다.
extends GutTest

const ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"

func _director():
    var catalog := GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ACTION_DATA_PATH)))
    return GatebreakerEncounterDirector.from_dictionary(
        JSON.parse_string(FileAccess.get_file_as_string(SEQUENCE_DATA_PATH)),
        catalog
    )

func test_preview_next_after_resolve_is_repeatable_and_does_not_mutate_director_state() -> void:
    var director = _director()
    director.bootstrap()

    var first: Dictionary = director.preview_next_after_resolve(0.69)
    var second: Dictionary = director.preview_next_after_resolve(0.69)

    assert_eq(first["id"], "gatebreaker:rift_siphon:3")
    assert_eq(second["id"], first["id"])
    assert_eq(director.current_phase, 1)
    assert_false(director.repair_used)

    var committed: Dictionary = director.schedule_next_after_resolve(0.69)
    assert_eq(committed["id"], first["id"])
    assert_eq(director.current_phase, 2)

func test_exact_commit_rejects_preview_id_mismatch_without_advancing_sequence() -> void:
    var director = _director()
    director.bootstrap()
    var preview: Dictionary = director.preview_next_after_resolve(0.69)

    var rejected: Dictionary = director.commit_next_after_resolve(0.69, "gatebreaker:hidden_counter:999")

    assert_true(rejected.is_empty())
    assert_eq(director.current_phase, 1)
    assert_false(director.repair_used)
    assert_eq(director.preview_next_after_resolve(0.69)["id"], preview["id"])

    var committed: Dictionary = director.commit_next_after_resolve(0.69, preview["id"])
    assert_eq(committed["id"], preview["id"])
    assert_eq(director.current_phase, 2)

func test_repair_preview_does_not_consume_single_use_until_exact_commit() -> void:
    var director = _director()
    director.bootstrap()
    director.schedule_next_after_resolve(0.69)

    var repair_preview: Dictionary = director.preview_next_after_resolve(0.49)

    assert_eq(repair_preview["template_key"], "rift_repair")
    assert_false(director.repair_used)
    assert_eq(director.preview_next_after_resolve(0.49)["id"], repair_preview["id"])

    var committed: Dictionary = director.commit_next_after_resolve(0.49, repair_preview["id"])
    assert_eq(committed["template_key"], "rift_repair")
    assert_true(director.repair_used)
