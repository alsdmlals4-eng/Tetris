class_name TempoEvaluator
extends RefCounted

class TempoResult:
    extends RefCounted

    var eligible: bool
    var saved_ratio: float
    var potency_bonus_ratio: float
    var ineligible_reason: String

    func _init(
        p_eligible: bool,
        p_saved_ratio: float,
        p_potency_bonus_ratio: float,
        p_ineligible_reason: String
    ) -> void:
        eligible = p_eligible
        saved_ratio = p_saved_ratio
        potency_bonus_ratio = p_potency_bonus_ratio
        ineligible_reason = p_ineligible_reason

static func evaluate(
    tempo_reference_seconds: float,
    active_used_seconds: float,
    line_qualified: bool,
    chain_qualified: bool,
    action_non_pass: bool,
    timeout_occurred: bool,
    board_break_occurred: bool,
    potency_per_saved_ratio: float,
    potency_bonus_cap_ratio: float
) -> TempoResult:
    if tempo_reference_seconds <= 0.0:
        return TempoResult.new(false, 0.0, 0.0, "INVALID_REFERENCE")

    var safe_active_used := maxf(active_used_seconds, 0.0)
    var saved_ratio := clampf(
        (tempo_reference_seconds - safe_active_used) / tempo_reference_seconds,
        0.0,
        1.0
    )

    if not line_qualified:
        return TempoResult.new(false, saved_ratio, 0.0, "LINE_REQUIRED")
    if not chain_qualified:
        return TempoResult.new(false, saved_ratio, 0.0, "CHAIN_REQUIRED")
    if not action_non_pass:
        return TempoResult.new(false, saved_ratio, 0.0, "NON_PASS_ACTION_REQUIRED")
    if timeout_occurred:
        return TempoResult.new(false, saved_ratio, 0.0, "TIMEOUT")
    if board_break_occurred:
        return TempoResult.new(false, saved_ratio, 0.0, "BOARD_BREAK")

    var safe_scale := maxf(potency_per_saved_ratio, 0.0)
    var safe_cap := maxf(potency_bonus_cap_ratio, 0.0)
    var potency_bonus_ratio := minf(saved_ratio * safe_scale, safe_cap)
    return TempoResult.new(true, saved_ratio, potency_bonus_ratio, "")
