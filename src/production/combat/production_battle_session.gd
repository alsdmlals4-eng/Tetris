class_name ProductionBattleSession
extends RefCounted

var turn_controller: TurnController
var player_state: ProductionCombatState
var enemy_state: ProductionCombatState
var skill_catalog: ProductionSkillCatalog
var telegraph_state: GatebreakerTelegraphState
var status_state: ProductionStatusState
var response_state: ProductionResponseState
var time_effect_state: TimeEffectState
var technique_resolver: ProductionTechniqueResolver
var enemy_action_resolver: ProductionEnemyActionResolver
var skill_session: ProductionSkillSession
var encounter_director: GatebreakerEncounterDirector = null

var battle_over: bool = false
var outcome: String = "ONGOING"

func _init(
    p_turn_controller: TurnController,
    p_player_state: ProductionCombatState,
    p_enemy_state: ProductionCombatState,
    p_skill_catalog: ProductionSkillCatalog,
    p_telegraph_state: GatebreakerTelegraphState,
    p_status_state: ProductionStatusState,
    p_response_state: ProductionResponseState,
    p_time_effect_state: TimeEffectState,
    p_technique_resolver: ProductionTechniqueResolver,
    p_enemy_action_resolver: ProductionEnemyActionResolver
) -> void:
    turn_controller = p_turn_controller
    player_state = p_player_state
    enemy_state = p_enemy_state
    skill_catalog = p_skill_catalog
    telegraph_state = p_telegraph_state
    status_state = p_status_state
    response_state = p_response_state
    time_effect_state = p_time_effect_state
    technique_resolver = p_technique_resolver
    enemy_action_resolver = p_enemy_action_resolver
    skill_session = ProductionSkillSession.new(turn_controller, player_state, skill_catalog)

func attach_encounter_director(director: GatebreakerEncounterDirector) -> bool:
    if director == null:
        return false
    if not director.has_method("preview_next_after_resolve") or not director.has_method("commit_next_after_resolve"):
        return false
    encounter_director = director
    return true

func select_technique(technique_id: String) -> Dictionary:
    if battle_over:
        return _selection_failed("BATTLE_OVER")
    if turn_controller.phase != TurnPhase.ACTION:
        return _selection_failed("WRONG_PHASE")

    var definition := skill_catalog.get_by_id(technique_id)
    if definition.is_empty():
        return _selection_failed("UNKNOWN_TECHNIQUE")

    var runtime_ready := technique_resolver.readiness(definition, _technique_context())
    if not bool(runtime_ready.get("ready", false)):
        return _selection_failed(String(runtime_ready.get("reason", "RUNTIME_NOT_READY")))

    return skill_session.select_technique(technique_id)

func resolve_player_action() -> Dictionary:
    if battle_over:
        return _resolve_failed("BATTLE_OVER")
    if turn_controller.phase != TurnPhase.PLAYER_RESOLVE or turn_controller.pending_player_action == null:
        return _resolve_failed("WRONG_PHASE")

    var technique_id := turn_controller.pending_player_action.id
    if technique_id == "PASS":
        if not turn_controller.complete_player_resolve():
            return _resolve_failed("PLAYER_RESOLVE_TRANSITION_FAILED")
        return {
            "resolved": true,
            "reason": "RESOLVED",
            "technique_id": "PASS",
            "passed": true,
            "enemy_action_cancelled": false,
        }

    var definition := skill_catalog.get_by_id(technique_id)
    if definition.is_empty():
        return _resolve_failed("UNKNOWN_COMMITTED_TECHNIQUE")

    var technique_result := technique_resolver.resolve(definition, _technique_context())
    if not bool(technique_result.get("resolved", false)):
        var failed := technique_result.duplicate(true)
        failed["resolved"] = false
        return failed

    if enemy_state.is_defeated():
        battle_over = true
        outcome = "PLAYER_VICTORY"
        var victory := technique_result.duplicate(true)
        victory["resolved"] = true
        victory["battle_over"] = true
        victory["outcome"] = outcome
        victory["enemy_action_cancelled"] = true
        return victory

    if not turn_controller.complete_player_resolve():
        return _resolve_failed("PLAYER_RESOLVE_TRANSITION_FAILED")

    var resolved := technique_result.duplicate(true)
    resolved["enemy_action_cancelled"] = false
    resolved["battle_over"] = false
    return resolved

func resolve_directed_enemy_action() -> Dictionary:
    if battle_over:
        return _resolve_failed("BATTLE_OVER")
    if encounter_director == null:
        return _resolve_failed("MISSING_ENCOUNTER_DIRECTOR")
    if turn_controller.phase != TurnPhase.ENEMY_RESOLVE:
        return _resolve_failed("WRONG_PHASE")

    var current_action := telegraph_state.current_action()
    if current_action.is_empty():
        return _resolve_failed("MISSING_CURRENT_TELEGRAPH")

    var preview := enemy_action_resolver.preview(current_action, {
        "player": player_state,
        "enemy": enemy_state,
        "response_state": response_state,
    })
    if not bool(preview.get("ready", false)):
        return _resolve_failed(String(preview.get("reason", "ENEMY_ACTION_PREVIEW_FAILED")))

    var projected_enemy_hp := int(preview.get("projected_enemy_hp", -1))
    if projected_enemy_hp < 0 or enemy_state.max_hp <= 0:
        return _resolve_failed("INVALID_PROJECTED_ENEMY_HP")
    var projected_hp_ratio := clampf(float(projected_enemy_hp) / float(enemy_state.max_hp), 0.0, 1.0)

    var authored_next := encounter_director.preview_next_after_resolve(projected_hp_ratio)
    if authored_next.is_empty():
        return _resolve_failed("DIRECTOR_NEXT_PREVIEW_FAILED")

    var current_action_id := String(current_action.get("id", ""))
    var advance_ready := telegraph_state.advance_readiness(current_action_id, authored_next)
    if not bool(advance_ready.get("ready", false)):
        return _resolve_failed(String(advance_ready.get("reason", "TELEGRAPH_ADVANCE_NOT_READY")))

    var result := resolve_enemy_action(authored_next)
    if not bool(result.get("resolved", false)):
        return result

    result["projected_post_resolve_enemy_hp"] = projected_enemy_hp
    result["projected_post_resolve_enemy_hp_ratio"] = projected_hp_ratio
    result["director_candidate_action_id"] = String(authored_next.get("id", ""))

    if battle_over:
        result["director_committed"] = false
        return result

    var committed := encounter_director.commit_next_after_resolve(
        projected_hp_ratio,
        String(authored_next.get("id", ""))
    )
    if committed.is_empty() or String(committed.get("id", "")) != String(authored_next.get("id", "")):
        return _resolve_failed("DIRECTOR_COMMIT_MISMATCH")

    result["director_committed"] = true
    result["director_action_id"] = String(committed.get("id", ""))
    return result

func resolve_enemy_action(authored_next: Dictionary) -> Dictionary:
    if battle_over:
        return _resolve_failed("BATTLE_OVER")
    if turn_controller.phase != TurnPhase.ENEMY_RESOLVE:
        return _resolve_failed("WRONG_PHASE")

    var current_action := telegraph_state.current_action()
    if current_action.is_empty():
        return _resolve_failed("MISSING_CURRENT_TELEGRAPH")

    var current_action_id := String(current_action.get("id", ""))
    var advance_ready := telegraph_state.advance_readiness(current_action_id, authored_next)
    if not bool(advance_ready.get("ready", false)):
        return _resolve_failed(String(advance_ready.get("reason", "TELEGRAPH_ADVANCE_NOT_READY")))

    var enemy_result := enemy_action_resolver.resolve(current_action, {
        "player": player_state,
        "enemy": enemy_state,
        "response_state": response_state,
    })
    if not bool(enemy_result.get("resolved", false)):
        return _resolve_failed(String(enemy_result.get("reason", "ENEMY_ACTION_RESOLVE_FAILED")))

    if player_state.is_defeated():
        battle_over = true
        outcome = "PLAYER_DEFEAT"
        return {
            "resolved": true,
            "reason": "RESOLVED",
            "battle_over": true,
            "outcome": outcome,
            "enemy_action_result": enemy_result,
        }

    var advance_result := telegraph_state.advance_after_resolve(current_action_id, authored_next)
    if not bool(advance_result.get("advanced", false)):
        return _resolve_failed("POST_RESOLVE_TELEGRAPH_ADVANCE_FAILED")
    if not turn_controller.complete_enemy_resolve():
        return _resolve_failed("ENEMY_RESOLVE_TRANSITION_FAILED")

    return {
        "resolved": true,
        "reason": "RESOLVED",
        "battle_over": false,
        "enemy_action_result": enemy_result,
        "telegraph_advance": advance_result,
    }

func _technique_context() -> Dictionary:
    var context := telegraph_state.forecast_context()
    context["player"] = player_state
    context["enemy"] = enemy_state
    context["status_state"] = status_state
    context["response_state"] = response_state
    context["time_effect_state"] = time_effect_state
    return context

func _selection_failed(reason: String) -> Dictionary:
    return {
        "accepted": false,
        "reason": reason,
    }

func _resolve_failed(reason: String) -> Dictionary:
    return {
        "resolved": false,
        "reason": reason,
    }
