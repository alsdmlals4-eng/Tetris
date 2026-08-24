class_name ProductionChainSession
extends RefCounted

var turn_controller: TurnController
var board: ChainBoard
var resolver: ChainResolver
var combat_state: ProductionCombatState
var reward_policy
var is_resolving: bool = false

var _events: Array = []

func _init(
    p_turn_controller: TurnController,
    p_board: ChainBoard,
    p_resolver: ChainResolver,
    p_combat_state: ProductionCombatState,
    p_reward_policy
) -> void:
    turn_controller = p_turn_controller
    board = p_board
    resolver = p_resolver
    combat_state = p_combat_state
    reward_policy = p_reward_policy

func can_accept_input() -> bool:
    return (
        turn_controller != null
        and turn_controller.phase == TurnPhase.CHAIN
        and not is_resolving
        and not turn_controller.turn_budget.is_expired()
    )

func begin_swap(first: Vector2i, second: Vector2i) -> Dictionary:
    if is_resolving:
        return {
            "accepted": false,
            "reason": "RESOLVING",
            "groups": [],
        }
    if not can_accept_input():
        return {
            "accepted": false,
            "reason": "INPUT_CLOSED",
            "groups": [],
        }

    var result: Dictionary = board.try_swap_for_match(first, second)
    if bool(result.get("accepted", false)):
        is_resolving = true
    return result

func tick_player_time(delta: float) -> void:
    if turn_controller == null:
        return
    turn_controller.tick_player_time(delta)

func request_ready() -> bool:
    if is_resolving or not can_accept_input():
        return false

    turn_controller.request_ready()
    return turn_controller.phase == TurnPhase.CHAIN_SETTLE

func complete_pending_resolution() -> Dictionary:
    if not is_resolving:
        return {
            "success": false,
            "reason": "NO_PENDING_RESOLUTION",
            "chain_depth": 0,
            "waves": [],
        }

    var resolution: Dictionary = resolver.resolve_existing_matches()
    is_resolving = false
    if not bool(resolution.get("success", false)):
        return resolution

    if reward_policy == null or not reward_policy.has_method("stock_for_resolution"):
        return {
            "success": false,
            "reason": "REWARD_POLICY_MISSING",
            "chain_depth": int(resolution.get("chain_depth", 0)),
            "waves": resolution.get("waves", []).duplicate(true),
        }

    var requested: int = maxi(0, int(reward_policy.stock_for_resolution(resolution)))
    var stock_result: Dictionary = combat_state.gain_stock(requested)
    _events.append({
        "kind": &"production_chain_resolved",
        "chain_depth": int(resolution.get("chain_depth", 0)),
        "waves": resolution.get("waves", []).duplicate(true),
        "stock_requested": requested,
        "stock_applied": int(stock_result.get("applied", 0)),
        "stock_lost_at_cap": int(stock_result.get("lost_at_cap", 0)),
    })
    return resolution

func complete_settle() -> bool:
    if turn_controller == null or turn_controller.phase != TurnPhase.CHAIN_SETTLE or is_resolving:
        return false

    turn_controller.complete_chain_settle()
    return (
        turn_controller.phase == TurnPhase.ACTION
        or turn_controller.phase == TurnPhase.PLAYER_RESOLVE
    )

func drain_events() -> Array:
    var drained: Array = _events.duplicate(true)
    _events.clear()
    return drained
