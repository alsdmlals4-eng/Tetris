class_name ProductionChainSession
extends RefCounted

var board: ChainBoard
var resolver: ChainResolver
var reward_policy: ProductionChainConfig
var input_enabled: bool = true

var _resolving: bool = false
var _events: Array[Dictionary] = []
var _pending_failed_swap: Dictionary = {}

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

func has_pending_failed_swap() -> bool:
    return not _pending_failed_swap.is_empty()

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
    if has_pending_failed_swap():
        return {
            "accepted": false,
            "reason": "FAILED_SWAP_PENDING_LOCK",
        }
    if board == null or resolver == null:
        return {
            "accepted": false,
            "reason": "WORKSPACE_UNAVAILABLE",
        }

    var swap_result: Dictionary = board.try_swap_for_match(first, second)
    if not bool(swap_result.get("accepted", false)):
        if String(swap_result.get("reason", "")) == "NO_MATCH" and swap_result.has("before_snapshot") and swap_result.has("swapped_snapshot"):
            _pending_failed_swap = {
                "before_snapshot": (swap_result.get("before_snapshot", []) as Array).duplicate(),
                "swapped_snapshot": (swap_result.get("swapped_snapshot", []) as Array).duplicate(),
                "from": first,
                "to": second,
            }
            input_enabled = false
            return {
                "accepted": false,
                "reason": "NO_MATCH_PENDING_LOCK",
                "lock_available": true,
            }
        return swap_result

    _resolving = true
    return {
        "accepted": true,
        "reason": "SWAP_COMMITTED",
        "from": first,
        "to": second,
        "groups": swap_result.get("groups", []).duplicate(true),
    }

func keep_pending_failed_swap() -> Dictionary:
    if not has_pending_failed_swap() or board == null:
        return {"accepted": false, "reason": "NO_PENDING_FAILED_SWAP"}
    var swapped: Array = _pending_failed_swap.get("swapped_snapshot", [])
    if not board.restore(swapped):
        return {"accepted": false, "reason": "INVALID_PENDING_SNAPSHOT"}
    _pending_failed_swap.clear()
    input_enabled = true
    return {"accepted": true, "reason": "SWAP_LOCKED", "swapped": true}

func discard_pending_failed_swap() -> Dictionary:
    if not has_pending_failed_swap() or board == null:
        return {"accepted": false, "reason": "NO_PENDING_FAILED_SWAP"}
    var before: Array = _pending_failed_swap.get("before_snapshot", [])
    if not board.restore(before):
        return {"accepted": false, "reason": "INVALID_PENDING_SNAPSHOT"}
    _pending_failed_swap.clear()
    input_enabled = true
    return {"accepted": true, "reason": "SWAP_RESTORED", "swapped": false}

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

    var waves = resolution.get("waves", [])
    _events.append({
        "kind": "production_chain_resolved",
        "success": true,
        "chain_depth": int(resolution.get("chain_depth", 0)),
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
        "pending_failed_swap": _pending_failed_swap.duplicate(true),
        "board": board_snapshot,
        "rng_state": rng_state,
    }

func drain_events() -> Array:
    var drained: Array = _events.duplicate(true)
    _events.clear()
    return drained
