class_name ProductionBattlePresenter
extends RefCounted

func snapshot(session, line_session = null, chain_session = null) -> Dictionary:
    if session == null:
        return {}
    if session.turn_controller == null or session.player_state == null or session.telegraph_state == null or session.skill_catalog == null:
        return {}

    var turn: TurnController = session.turn_controller
    var player: ProductionCombatState = session.player_state
    var current: Dictionary = session.telegraph_state.current_action()
    var next: Dictionary = session.telegraph_state.next_action()
    var readiness: Dictionary = {}

    for technique_id_value in session.skill_catalog.all_ids():
        var technique_id := String(technique_id_value)
        readiness[technique_id] = session.technique_readiness(technique_id)

    var tempo := _provisional_tempo(session)
    return {
        "current_telegraph": _format_current_action(current, player),
        "next_forecast": _format_forecast(next),
        "phase": _phase_name(turn.phase),
        "remaining_seconds": float(turn.turn_budget.remaining_seconds) if turn.turn_budget != null else 0.0,
        "player_hp": player.hp,
        "player_max_hp": player.max_hp,
        "energy": player.energy,
        "stock": player.stock,
        "ready_available": _ready_available(turn.phase, line_session, chain_session),
        "tempo_eligible": bool(tempo.get("eligible", false)),
        "tempo_saved_ratio": float(tempo.get("saved_ratio", 0.0)),
        "tempo_potency_bonus_ratio": float(tempo.get("potency_bonus_ratio", 0.0)),
        "tempo_ineligible_reason": String(tempo.get("ineligible_reason", "")),
        "technique_readiness": readiness,
    }

func _ready_available(phase: int, line_session, chain_session) -> bool:
    match phase:
        TurnPhase.LINE:
            return line_session != null and line_session.has_method("can_accept_input") and bool(line_session.can_accept_input())
        TurnPhase.CHAIN:
            return chain_session != null and chain_session.has_method("can_accept_input") and bool(chain_session.can_accept_input())
        _:
            return false

func _provisional_tempo(session) -> Dictionary:
    var turn: TurnController = session.turn_controller
    if turn.phase != TurnPhase.ACTION:
        return _tempo_unavailable("NON_ACTION_PHASE")
    if session.current_turn_time_config == null:
        return _tempo_unavailable("MISSING_TIME_CONFIG")

    var performance: ProductionTurnPerformanceState = session.turn_performance_state
    var config: TurnTimeConfig = session.current_turn_time_config
    var result := TempoEvaluator.evaluate(
        config.tempo_reference_seconds,
        turn.turn_budget.active_used_seconds,
        performance.line_qualified,
        performance.chain_qualified,
        true,
        performance.timeout_occurred or turn.timed_out_this_turn,
        performance.board_break_occurred,
        config.potency_per_saved_ratio,
        config.potency_bonus_cap_ratio
    )
    return {
        "eligible": result.eligible,
        "saved_ratio": result.saved_ratio,
        "potency_bonus_ratio": result.potency_bonus_ratio,
        "ineligible_reason": result.ineligible_reason,
    }

func _tempo_unavailable(reason: String) -> Dictionary:
    return {
        "eligible": false,
        "saved_ratio": 0.0,
        "potency_bonus_ratio": 0.0,
        "ineligible_reason": reason,
    }

func _format_current_action(action: Dictionary, player: ProductionCombatState) -> String:
    if action.is_empty():
        return "미확인"

    var name := _action_name(action)
    match String(action.get("kind", "")):
        "DIRECT_HP_RATIO":
            var damage := maxi(1, roundi(float(player.max_hp) * float(action.get("hp_ratio", 0.0))))
            return "%s · 예상 피해 %d" % [name, damage]
        "ENERGY_LOSS":
            return "%s · Energy -%d" % [name, int(action.get("amount", 0))]
        "STOCK_LOSS":
            return "%s · Stock -%d" % [name, int(action.get("amount", 0))]
        "ENEMY_HEAL_RATIO":
            return "%s · 보스 회복" % name
        _:
            return name

func _format_forecast(action: Dictionary) -> String:
    if action.is_empty():
        return "미확인"
    return _action_name(action)

func _action_name(action: Dictionary) -> String:
    var key := String(action.get("template_key", ""))
    if key == "":
        return String(action.get("id", "미확인"))
    return key.replace("_", " ").capitalize()

func _phase_name(phase: int) -> String:
    match phase:
        TurnPhase.ENEMY_TELEGRAPH:
            return "ENEMY_TELEGRAPH"
        TurnPhase.LINE:
            return "LINE"
        TurnPhase.LINE_SETTLE:
            return "LINE_SETTLE"
        TurnPhase.CHAIN:
            return "CHAIN"
        TurnPhase.CHAIN_SETTLE:
            return "CHAIN_SETTLE"
        TurnPhase.ACTION:
            return "ACTION"
        TurnPhase.PLAYER_RESOLVE:
            return "PLAYER_RESOLVE"
        TurnPhase.ENEMY_RESOLVE:
            return "ENEMY_RESOLVE"
        _:
            return "UNKNOWN"
