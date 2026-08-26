extends GutTest

const TELEMETRY_PATH := "res://src/production/telemetry/production_telemetry.gd"

func _telemetry():
    var script = load(TELEMETRY_PATH)
    assert_not_null(script, "ProductionTelemetry script must exist")
    if script == null:
        return null
    return script.new()

func test_turn_started_requires_budget_reference_and_telegraph_identity() -> void:
    var telemetry = _telemetry()
    if telemetry == null:
        return

    assert_false(telemetry.record_event({
        "kind": &"turn_started",
        "turn_index": 1,
    }))
    assert_eq(telemetry.event_count(), 0)

    assert_true(telemetry.record_event({
        "kind": &"turn_started",
        "turn_index": 1,
        "telegraph_action_id": "light_smash#1",
        "profile_id": "NORMAL",
        "base_budget_seconds": 90.0,
        "flat_modifier_seconds": 0.0,
        "effective_budget_seconds": 90.0,
        "tempo_reference_seconds": 90.0,
    }))
    assert_eq(telemetry.event_count(), 1)

func test_phase_completed_keeps_active_time_and_settle_time_separate() -> void:
    var telemetry = _telemetry()
    if telemetry == null:
        return

    assert_true(telemetry.record_event({
        "kind": &"phase_completed",
        "turn_index": 2,
        "phase": "LINE",
        "active_used_seconds": 18.0,
        "settle_seconds": 0.75,
        "ready_used": true,
        "timeout_occurred": false,
        "remaining_budget_seconds": 72.0,
    }))

    var event: Dictionary = telemetry.events_snapshot()[0]
    assert_eq(event["active_used_seconds"], 18.0)
    assert_eq(event["settle_seconds"], 0.75)
    assert_false(event.has("combined_elapsed_seconds"))

func test_tempo_event_requires_all_qualification_gates_and_applied_potency() -> void:
    var telemetry = _telemetry()
    if telemetry == null:
        return

    assert_false(telemetry.record_event({
        "kind": &"tempo_evaluated",
        "turn_index": 3,
        "eligible": true,
    }))

    assert_true(telemetry.record_event({
        "kind": &"tempo_evaluated",
        "turn_index": 3,
        "line_qualified": true,
        "chain_qualified": true,
        "action_non_pass": true,
        "timeout_occurred": false,
        "board_break_occurred": false,
        "saved_ratio": 0.5,
        "eligible": true,
        "ineligible_reason": "",
        "potency_bonus_ratio": 0.1,
        "applied_potency_ratio": 0.1,
    }))
    assert_eq(telemetry.event_count(), 1)

func test_recording_and_snapshots_are_deep_copied_for_deterministic_evidence() -> void:
    var telemetry = _telemetry()
    if telemetry == null:
        return

    var source := {
        "kind": &"phase_completed",
        "turn_index": 4,
        "phase": "CHAIN",
        "active_used_seconds": 11.0,
        "settle_seconds": 1.25,
        "ready_used": false,
        "timeout_occurred": true,
        "remaining_budget_seconds": 0.0,
        "details": {"cascade_depth": 2},
    }
    assert_true(telemetry.record_event(source))
    source["details"]["cascade_depth"] = 99

    var first_snapshot: Array = telemetry.events_snapshot()
    assert_eq(first_snapshot[0]["details"]["cascade_depth"], 2)
    first_snapshot[0]["details"]["cascade_depth"] = 77
    assert_eq(telemetry.events_snapshot()[0]["details"]["cascade_depth"], 2)

func test_unknown_kind_or_invalid_turn_index_fails_closed_without_append() -> void:
    var telemetry = _telemetry()
    if telemetry == null:
        return

    assert_false(telemetry.record_event({"kind": &"unknown", "turn_index": 1}))
    assert_false(telemetry.record_event({
        "kind": &"turn_started",
        "turn_index": -1,
        "telegraph_action_id": "light_smash#1",
        "profile_id": "NORMAL",
        "base_budget_seconds": 90.0,
        "flat_modifier_seconds": 0.0,
        "effective_budget_seconds": 90.0,
        "tempo_reference_seconds": 90.0,
    }))
    assert_eq(telemetry.event_count(), 0)
