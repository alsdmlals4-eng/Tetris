## R2 LINE resources, automatic casts, timing, and save transactions stay deterministic.
extends GutTest

const COMBAT_PATH := "res://src/replanned_r2/r2_combat.gd"
const SESSION_PATH := "res://docs/design/r2-complete-session.json"

func _state(mode: String = "STANDARD"):
    var script = load(COMBAT_PATH)
    assert_not_null(script, "R2 combat owner must exist")
    return script.new(mode) if script != null else null

func _cells(prefix: String, kinds: Array) -> Array:
    var cells: Array = []
    for index in range(kinds.size()):
        cells.append({"id": "%s-%d" % [prefix, index], "kind": String(kinds[index])})
    return cells

func test_default_and_relaxed_modes_consume_the_approved_encounter() -> void:
    var approved = JSON.parse_string(FileAccess.get_file_as_string(SESSION_PATH))
    assert_true(approved is Dictionary)
    var standard = _state()
    var relaxed = _state("RELAXED")
    if standard == null or relaxed == null or not approved is Dictionary:
        return
    var encounter: Dictionary = approved["encounter"]
    assert_eq(standard.hp, int(encounter["player_hp"]))
    assert_eq(standard.boss_hp, int(encounter["boss_hp"]))
    assert_eq(standard.current_action()["id"], "probe")
    assert_eq(standard.current_action()["damage"], 12)
    assert_eq(standard.next_action()["id"], "slam")
    assert_eq(standard.eta_us, 10000000)
    assert_eq(relaxed.eta_us, 12500000)
    assert_eq(standard.action_id(), "rift_breaker_r2_intro:0")
    assert_ne(String(standard.snapshot()["rule_pack_hash"]), "")

func test_line_a4_d2_h2_t2_pays_unique_cells_once() -> void:
    var state = _state()
    if state == null:
        return
    state.hp = 80
    var kinds := ["A", "A", "A", "A", "D", "D", "H", "H", "T", "T"]
    var result: Dictionary = state.apply_line("line-1", _cells("line-1", kinds))
    assert_true(result["success"])
    assert_eq(result["effect"], "LINE_RESOURCES_APPLIED")
    assert_eq(result["counts"], {"A": 4, "D": 2, "H": 2, "T": 2})
    assert_eq(state.attack_bank, 4)
    assert_eq(state.armor, 2)
    assert_eq(state.hp, 82)
    assert_eq(state.eta_us, 10500000)
    assert_eq(state.extension_us, 500000)

func test_duplicate_line_event_and_cell_ids_never_pay_twice() -> void:
    var state = _state()
    if state == null:
        return
    var duplicated_cells := [
        {"id": "cell-a", "kind": "A"},
        {"id": "cell-a", "kind": "A"},
        {"id": "cell-d", "kind": "D"},
    ]
    var first: Dictionary = state.apply_line("line-duplicate", duplicated_cells)
    assert_true(first["success"])
    assert_eq(first["counts"], {"A": 1, "D": 1, "H": 0, "T": 0})
    var before: Dictionary = state.snapshot()
    var duplicate_event: Dictionary = state.apply_line("line-duplicate", [{"id": "cell-new", "kind": "A"}])
    assert_false(duplicate_event["success"])
    assert_eq(duplicate_event["reason"], "DUPLICATE_EVENT")
    assert_eq(state.snapshot(), before)
    var repeated_cell: Dictionary = state.apply_line("line-new", [{"id": "cell-a", "kind": "A"}])
    assert_false(repeated_cell["success"])
    assert_eq(repeated_cell["reason"], "NO_NEW_CELLS")
    assert_eq(state.attack_bank, 1)
    assert_eq(state.armor, 1)

func test_invalid_line_payload_is_atomic() -> void:
    var state = _state()
    if state == null:
        return
    var before: Dictionary = state.snapshot()
    var invalid_kind: Dictionary = state.apply_line("bad-kind", [
        {"id": "valid-first", "kind": "A"},
        {"id": "invalid-second", "kind": "attack"},
    ])
    assert_false(invalid_kind["success"])
    assert_eq(invalid_kind["reason"], "INVALID_CELL_KIND")
    assert_eq(state.snapshot(), before)
    var invalid_cell: Dictionary = state.apply_line("bad-cell", [{"id": "missing-kind"}])
    assert_false(invalid_cell["success"])
    assert_eq(invalid_cell["reason"], "INVALID_CELL")
    assert_eq(state.snapshot(), before)

func test_attack_bank_is_consumed_by_only_the_first_successful_atk_wave() -> void:
    var state = _state()
    if state == null:
        return
    state.attack_bank = 7
    var first: Dictionary = state.cast("atk-1", "ATK", 1)
    var second: Dictionary = state.cast("atk-2", "ATK", 2)
    var third: Dictionary = state.cast("atk-3", "ATK", 3)
    assert_eq(first["damage_applied"], 11)
    assert_eq(first["bank_consumed"], 7)
    assert_eq(second["damage_applied"], 6)
    assert_eq(second["bank_consumed"], 0)
    assert_eq(third["damage_applied"], 8)
    assert_eq(state.boss_hp, 215)
    assert_eq(state.attack_bank, 0)

func test_def_uses_max_ward_then_armor_before_hp() -> void:
    var state = _state()
    if state == null:
        return
    state.tick(10000000)
    state.hp = 100
    state.armor = 10
    state.cast("def-1", "DEF", 1)
    state.cast("def-2", "DEF", 2)
    state.cast("def-3", "DEF", 3)
    assert_eq(state.current_action()["id"], "slam")
    assert_eq(state.ward, 7)
    assert_eq(state.ward_target, "rift_breaker_r2_intro:1")
    var events: Array = state.tick(14000000)
    assert_eq(state.hp, 82)
    assert_eq(state.ward, 0)
    assert_eq(state.armor, 0)
    assert_eq(events[0]["damage_to_hp"], 18)

func test_sup_healing_caps_at_max_hp() -> void:
    var state = _state()
    if state == null:
        return
    state.hp = 98
    var result: Dictionary = state.cast("sup-cap", "SUP", 6)
    assert_true(result["success"])
    assert_eq(result["healing_applied"], 2)
    assert_eq(state.hp, 100)

func test_time_extension_caps_current_action_at_three_seconds() -> void:
    var state = _state()
    if state == null:
        return
    var first: Dictionary = state.apply_line("time-first", _cells("time-first", ["T", "T", "T", "T", "T", "T", "T", "T", "T", "T"]))
    assert_eq(first["time_applied_us"], 2500000)
    var eta_before: int = state.eta_us
    var second: Dictionary = state.apply_line("time-cap", _cells("time-cap", ["T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T", "T"]))
    assert_eq(second["time_requested_us"], 5000000)
    assert_eq(second["time_applied_us"], 500000)
    assert_eq(state.extension_us, 3000000)
    assert_eq(state.eta_us, eta_before + 500000)

func test_def_cast_on_committed_or_rest_action_has_no_ward_target() -> void:
    var committed = _state()
    var rest = _state()
    if committed == null or rest == null:
        return
    committed.tick(9999000)
    var committed_result: Dictionary = committed.cast("def-committed", "DEF", 3)
    assert_true(committed_result["success"])
    assert_eq(committed_result["effect"], "DEF_NO_TARGET")
    assert_eq(committed_result["reason"], "ACTION_COMMITTED")
    assert_eq(committed.ward, 0)
    rest.tick(10000000)
    rest.tick(14000000)
    rest.tick(10000000)
    var rest_result: Dictionary = rest.cast("def-rest", "DEF", 3)
    assert_eq(rest.current_action()["id"], "rest")
    assert_true(rest_result["success"])
    assert_eq(rest_result["effect"], "DEF_NO_TARGET")
    assert_eq(rest_result["reason"], "NO_DAMAGE_ACTION")
    assert_eq(rest.ward, 0)

func test_duplicate_cast_id_has_no_effect() -> void:
    var state = _state()
    if state == null:
        return
    var first: Dictionary = state.cast("same-cast", "ATK", 1)
    var after_first: Dictionary = state.snapshot()
    var duplicate: Dictionary = state.cast("same-cast", "ATK", 6)
    assert_true(first["success"])
    assert_false(duplicate["success"])
    assert_eq(duplicate["reason"], "DUPLICATE_EVENT")
    assert_eq(state.snapshot(), after_first)

func test_lethal_atk_stops_later_sup_in_the_same_tick() -> void:
    var state = _state()
    if state == null:
        return
    state.boss_hp = 4
    state.hp = 50
    var events: Array = state.tick(0, [], [
        {"id": "lethal-atk", "category": "ATK", "wave": 1},
        {"id": "too-late-sup", "category": "SUP", "wave": 6},
    ])
    assert_eq(state.boss_hp, 0)
    assert_eq(state.hp, 50)
    assert_eq(state.outcome, "VICTORY")
    assert_eq(events.size(), 1)
    assert_eq(events[0]["effect"], "ATK_DAMAGE")

func test_old_action_time_cannot_retarget_the_next_action_at_tick_end() -> void:
    var state = _state()
    if state == null:
        return
    var events: Array = state.tick(10000000, [{
        "id": "late-time",
        "cells": [{"id": "late-time-cell", "kind": "T"}],
    }])
    assert_eq(events[0]["effect"], "ENEMY_ACTION_RESOLVED")
    assert_eq(events[1]["effect"], "LINE_RESOURCES_APPLIED")
    assert_eq(events[1]["time_applied_us"], 0)
    assert_eq(events[1]["time_reason"], "ACTION_FINISHED")
    assert_eq(events[2]["effect"], "ACTION_SCHEDULED")
    assert_eq(state.current_action()["id"], "slam")
    assert_eq(state.eta_us, 14000000)
    assert_eq(state.extension_us, 0)

func test_pause_preserves_the_exact_snapshot() -> void:
    var state = _state()
    if state == null:
        return
    state.paused = true
    var before: Dictionary = state.snapshot()
    var events: Array = state.tick(10000000, [{
        "id": "paused-line",
        "cells": [{"id": "paused-cell", "kind": "A"}],
    }], [{"id": "paused-cast", "category": "ATK", "wave": 1}])
    assert_eq(events, [])
    assert_eq(state.snapshot(), before)

func test_invalid_restore_rejects_all_partial_mutation() -> void:
    var state = _state()
    if state == null:
        return
    state.apply_line("save-line", [{"id": "save-cell", "kind": "A"}])
    state.cast("save-cast", "SUP", 1)
    var before: Dictionary = state.snapshot()
    var missing_key: Dictionary = before.duplicate(true)
    missing_key.erase("boss_hp")
    assert_false(state.restore(missing_key))
    assert_eq(state.snapshot(), before)
    var wrong_hash: Dictionary = before.duplicate(true)
    wrong_hash["rule_pack_hash"] = "foreign"
    assert_false(state.restore(wrong_hash))
    assert_eq(state.snapshot(), before)
    var bad_ward: Dictionary = before.duplicate(true)
    bad_ward["ward"] = 3
    bad_ward["ward_target"] = "other-action"
    assert_false(state.restore(bad_ward))
    assert_eq(state.snapshot(), before)
func test_snapshot_restores_after_real_json_roundtrip_and_rejects_fractional_numbers() -> void:
    var state = _state("RELAXED")
    if state == null:
        return
    state.apply_line("roundtrip-line", [{"id": "roundtrip-cell", "kind": "D"}])
    state.tick(250000)
    var expected: Dictionary = state.snapshot()
    var encoded: String = JSON.stringify(expected)
    var decoded = JSON.parse_string(encoded)
    assert_true(decoded is Dictionary)
    assert_true(state.restore(decoded))
    assert_eq(state.snapshot(), expected)
    var before: Dictionary = state.snapshot()
    var fractional: Dictionary = decoded.duplicate(true)
    fractional["eta_us"] = 12500000.5
    assert_false(state.restore(fractional))
    assert_eq(state.snapshot(), before)
func test_topout_damage_bypasses_defenses_deduplicates_and_can_defeat() -> void:
    var state = _state()
    var lethal = _state()
    if state == null or lethal == null:
        return
    state.hp = 30
    state.armor = 10
    state.cast("topout-ward", "DEF", 3)
    var first: Dictionary = state.apply_topout("topout-1")
    assert_true(first["success"])
    assert_eq(first["effect"], "LINE_TOPOUT_DAMAGE")
    assert_eq(first["damage_applied"], 25)
    assert_true(first["reset_required"])
    assert_eq(state.hp, 5)
    assert_eq(state.armor, 10)
    assert_eq(state.ward, 7)
    var after_first: Dictionary = state.snapshot()
    var duplicate: Dictionary = state.apply_topout("topout-1")
    assert_false(duplicate["success"])
    assert_eq(duplicate["reason"], "DUPLICATE_EVENT")
    assert_eq(state.snapshot(), after_first)
    lethal.hp = 20
    var defeat: Dictionary = lethal.apply_topout("topout-lethal")
    assert_eq(defeat["damage_applied"], 20)
    assert_eq(lethal.hp, 0)
    assert_eq(lethal.outcome, "DEFEAT")
func test_restore_rejects_eta_beyond_authored_duration_without_mutation() -> void:
    var state = _state()
    if state == null:
        return
    var before: Dictionary = state.snapshot()
    var impossible_eta: Dictionary = before.duplicate(true)
    impossible_eta["eta_us"] = 10000001
    assert_false(state.restore(impossible_eta))
    assert_eq(state.snapshot(), before)
func test_due_lethal_boss_action_prevents_same_tick_line_heal_and_sup_revive() -> void:
    var state = _state()
    if state == null:
        return
    state.hp = 12
    var events: Array = state.tick(10000000, [{
        "id": "too-late-line-heal",
        "cells": [{"id": "too-late-heart", "kind": "H"}],
    }], [{"id": "too-late-sup", "category": "SUP", "wave": 6}])
    assert_eq(events.size(), 1)
    assert_eq(events[0]["effect"], "ENEMY_ACTION_RESOLVED")
    assert_eq(events[0]["damage_to_hp"], 12)
    assert_eq(state.hp, 0)
    assert_eq(state.outcome, "DEFEAT")
    assert_eq(state.snapshot()["processed_line_event_ids"], [])
    assert_eq(state.snapshot()["processed_cast_event_ids"], [])

func test_pause_blocks_direct_transactions_without_consuming_event_ids() -> void:
    var state = _state()
    if state == null:
        return
    state.paused = true
    var before: Dictionary = state.snapshot()
    var line_result: Dictionary = state.apply_line("paused-direct-line", [{"id": "paused-direct-cell", "kind": "A"}])
    var cast_result: Dictionary = state.cast("paused-direct-cast", "ATK", 1)
    var topout_result: Dictionary = state.apply_topout("paused-direct-topout")
    assert_false(line_result["success"])
    assert_eq(line_result["reason"], "PAUSED")
    assert_false(cast_result["success"])
    assert_eq(cast_result["reason"], "PAUSED")
    assert_false(topout_result["success"])
    assert_eq(topout_result["reason"], "PAUSED")
    assert_eq(state.snapshot(), before)
    state.paused = false
    assert_true(state.apply_line("paused-direct-line", [{"id": "paused-direct-cell", "kind": "A"}])["success"])
    assert_true(state.cast("paused-direct-cast", "ATK", 1)["success"])
    assert_true(state.apply_topout("paused-direct-topout")["success"])

func test_restore_accepts_valid_committed_ward_and_rejects_unauthored_ward_atomically() -> void:
    var invalid = _state()
    var committed = _state()
    if invalid == null or committed == null:
        return
    invalid.cast("invalid-ward-seed", "DEF", 6)
    var before_invalid: Dictionary = invalid.snapshot()
    var unauthored: Dictionary = before_invalid.duplicate(true)
    unauthored["ward"] = 99
    assert_false(invalid.restore(unauthored))
    assert_eq(invalid.snapshot(), before_invalid)
    committed.cast("committed-ward-seed", "DEF", 6)
    committed.tick(9999000)
    var committed_snapshot: Dictionary = committed.snapshot()
    assert_eq(committed_snapshot["ward"], 17)
    assert_eq(committed_snapshot["ward_target"], "rift_breaker_r2_intro:0")
    assert_eq(committed_snapshot["eta_us"], 1000)
    committed.hp = 99
    assert_true(committed.restore(committed_snapshot))
    assert_eq(committed.snapshot(), committed_snapshot)
