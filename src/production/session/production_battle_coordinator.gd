class_name ProductionBattleCoordinator
extends RefCounted

var battle_session: ProductionBattleSession
var line_session: ProductionLineSession
var chain_session: ProductionChainSession
var presenter: ProductionBattlePresenter

var _routed_events: Array = []

func _init(
    p_battle_session: ProductionBattleSession,
    p_line_session: ProductionLineSession,
    p_chain_session: ProductionChainSession,
    p_presenter: ProductionBattlePresenter
) -> void:
    battle_session = p_battle_session
    line_session = p_line_session
    chain_session = p_chain_session
    presenter = p_presenter

func snapshot() -> Dictionary:
    if presenter == null or battle_session == null:
        return {}
    return presenter.snapshot(battle_session, line_session, chain_session)

func request_ready() -> bool:
    if battle_session == null or battle_session.turn_controller == null:
        return false

    match battle_session.turn_controller.phase:
        TurnPhase.LINE:
            return line_session != null and line_session.request_ready()
        TurnPhase.CHAIN:
            return chain_session != null and chain_session.request_ready()
        _:
            return false

func complete_settle() -> bool:
    if battle_session == null or battle_session.turn_controller == null:
        return false

    match battle_session.turn_controller.phase:
        TurnPhase.LINE_SETTLE:
            return line_session != null and line_session.complete_settle()
        TurnPhase.CHAIN_SETTLE:
            return chain_session != null and chain_session.complete_settle()
        _:
            return false

func line_hard_drop():
    if line_session == null:
        return null

    var result = line_session.hard_drop_and_commit()
    _route_line_events()
    return result

func chain_swap(first: Vector2i, second: Vector2i) -> Dictionary:
    if chain_session == null:
        return {
            "accepted": false,
            "reason": "MISSING_CHAIN_SESSION",
            "groups": [],
        }
    return chain_session.begin_swap(first, second)

func complete_chain_resolution() -> Dictionary:
    if chain_session == null:
        return {
            "success": false,
            "reason": "MISSING_CHAIN_SESSION",
            "chain_depth": 0,
            "waves": [],
        }

    var resolution: Dictionary = chain_session.complete_pending_resolution()
    _route_chain_events()
    return resolution

func select_technique(technique_id: String) -> Dictionary:
    if battle_session == null:
        return {
            "accepted": false,
            "reason": "MISSING_BATTLE_SESSION",
        }
    return battle_session.select_technique(technique_id)

func drain_routed_events() -> Array:
    var drained: Array = _routed_events.duplicate(true)
    _routed_events.clear()
    return drained

func _route_line_events() -> void:
    if line_session == null or battle_session == null:
        return

    for event_value in line_session.drain_events():
        if not event_value is Dictionary:
            continue
        var event: Dictionary = event_value
        if event.get("kind", &"") == &"production_line_resolved" and battle_session.player_state != null:
            battle_session.player_state.apply_line_event(event)
        battle_session.record_turn_performance_event(event)
        _routed_events.append(event.duplicate(true))

func _route_chain_events() -> void:
    if chain_session == null or battle_session == null:
        return

    for event_value in chain_session.drain_events():
        if not event_value is Dictionary:
            continue
        var event: Dictionary = event_value
        battle_session.record_turn_performance_event(event)
        _routed_events.append(event.duplicate(true))
