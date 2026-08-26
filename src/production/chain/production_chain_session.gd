class_name ProductionChainSession
extends RefCounted

var board: ChainBoard
var resolver: ChainResolver
var reward_policy: ProductionChainConfig
var input_enabled: bool = true

var _resolving: bool = false
var _events: Array[Dictionary] = []

func _init(
    p_board: ChainBoard,
    p_resolver: ChainResolver,
    p_reward_policy: ProductionChainConfig
) -> void:
    board = p_board
    resolver = p_resolver
    reward_policy = p_reward_policy

func set_input_enabled(enabled: bool) -> void:
    input_enabled = enabled

func can_accept_input() -> bool:
    return input_enabled and not _resolving and board != null and resolver != null

func is_resolving() -> bool:
    return _resolving

func begin_swap(first: Vector2i, second: Vector2i) -> Dictionary:
    if not input_enabled:
        return {
            "accepted": false,
            "reason": "INPUT_CLOSED",
        }
    if _resolving:
        return {
            "accepted": false,
            "reason": "RESOLVING",
        }
    if board == null or resolver == null:
        return {
            "accepted": false,
            "reason": "WORKSPACE_UNAVAILABLE",
        }

    var swap_result: Dictionary = board.try_swap_for_match(first, second)
    if not bool(swap_result.get("accepted", false)):
        return swap_result

    _resolving = true
    return {
        "accepted": true,
        "reason": "SWAP_COMMITTED",
        "from": first,
        "to": second,
        "groups": swap_result.get("groups", []).duplicate(true),
    }

func complete_pending_resolution() -> Dictionary:
    if not _resolving:
        return {
            "success": false,
            "reason": "NO_PENDING_RESOLUTION",
            "chain_depth": 0,
            "waves": [],
        }
    if resolver == null or reward_policy == null:
        _resolving = false
        return {
            "success": false,
            "reason": "WORKSPACE_UNAVAILABLE",
            "chain_depth": 0,
            "waves": [],
        }

    var resolution: Dictionary = resolver.resolve_existing_matches()
    _resolving = false
    if not bool(resolution.get("success", false)):
        return resolution

    var stock_requested := reward_policy.stock_for_resolution(resolution)
    var waves = resolution.get("waves", [])
    _events.append({
        "kind": "production_chain_resolved",
        "success": true,
        "chain_depth": int(resolution.get("chain_depth", 0)),
        "stock_requested": stock_requested,
        "waves": waves.duplicate(true) if waves is Array else [],
    })
    return resolution

func snapshot_runtime_state() -> Dictionary:
    var board_snapshot: Array = []
    if board != null:
        board_snapshot = board.snapshot()

    var rng_state: int = 0
    if resolver != null and resolver.randomizer != null and resolver.randomizer.has_method("get_rng_state"):
        rng_state = int(resolver.randomizer.get_rng_state())

    return {
        "input_enabled": input_enabled,
        "resolving": _resolving,
        "board": board_snapshot,
        "rng_state": rng_state,
    }

func drain_events() -> Array:
    var drained: Array = _events.duplicate(true)
    _events.clear()
    return drained
