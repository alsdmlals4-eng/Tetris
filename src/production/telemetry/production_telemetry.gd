class_name ProductionTelemetry
extends RefCounted

var _events: Array[Dictionary] = []

func record_event(event: Dictionary) -> bool:
    var kind := StringName(event.get("kind", &""))
    if not _valid_turn_index(event):
        return false

    match kind:
        &"turn_started":
            if not _valid_turn_started(event):
                return false
        &"phase_completed":
            if not _valid_phase_completed(event):
                return false
        &"tempo_evaluated":
            if not _valid_tempo_evaluated(event):
                return false
        _:
            return false

    _events.append(event.duplicate(true))
    return true

func event_count() -> int:
    return _events.size()

func events_snapshot() -> Array:
    var snapshot: Array = []
    for event in _events:
        snapshot.append(event.duplicate(true))
    return snapshot

func clear() -> void:
    _events.clear()

func _valid_turn_index(event: Dictionary) -> bool:
    return event.has("turn_index") and int(event.get("turn_index", -1)) >= 0

func _valid_turn_started(event: Dictionary) -> bool:
    var required := [
        "telegraph_action_id",
        "profile_id",
        "base_budget_seconds",
        "flat_modifier_seconds",
        "effective_budget_seconds",
        "tempo_reference_seconds",
    ]
    if not _has_all(event, required):
        return false
    if String(event.get("telegraph_action_id", "")) == "" or String(event.get("profile_id", "")) == "":
        return false
    return float(event.get("base_budget_seconds", -1.0)) >= 0.0 \
        and float(event.get("effective_budget_seconds", -1.0)) >= 0.0 \
        and float(event.get("tempo_reference_seconds", -1.0)) > 0.0

func _valid_phase_completed(event: Dictionary) -> bool:
    var required := [
        "phase",
        "active_used_seconds",
        "settle_seconds",
        "ready_used",
        "timeout_occurred",
        "remaining_budget_seconds",
    ]
    if not _has_all(event, required) or String(event.get("phase", "")) == "":
        return false
    return float(event.get("active_used_seconds", -1.0)) >= 0.0 \
        and float(event.get("settle_seconds", -1.0)) >= 0.0 \
        and float(event.get("remaining_budget_seconds", -1.0)) >= 0.0

func _valid_tempo_evaluated(event: Dictionary) -> bool:
    var required := [
        "line_qualified",
        "chain_qualified",
        "action_non_pass",
        "timeout_occurred",
        "board_break_occurred",
        "saved_ratio",
        "eligible",
        "ineligible_reason",
        "potency_bonus_ratio",
        "applied_potency_ratio",
    ]
    if not _has_all(event, required):
        return false
    var saved_ratio := float(event.get("saved_ratio", -1.0))
    var potency_bonus_ratio := float(event.get("potency_bonus_ratio", -1.0))
    var applied_potency_ratio := float(event.get("applied_potency_ratio", -1.0))
    return saved_ratio >= 0.0 and saved_ratio <= 1.0 \
        and potency_bonus_ratio >= 0.0 \
        and applied_potency_ratio >= 0.0

func _has_all(event: Dictionary, fields: Array) -> bool:
    for field in fields:
        if not event.has(field):
            return false
    return true
