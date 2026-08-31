class_name ProductionChainSession
extends RefCounted

var board: ChainBoard
var resolver: ChainResolver
var input_enabled: bool = true

var _resolving: bool = false
var _events: Array[Dictionary] = []
var _pending_failed_swap_snapshot: Array = []

func _init(
    p_board: ChainBoard,
    p_resolver: ChainResolver
) -> void:
    board = p_board
    resolver = p_resolver

func set_input_enabled(enabled: bool) -> void:
    input_enabled = enabled

func can_accept_input() -> bool:
    return input_enabled and not _resolving and not has_pending_failed_swap() and board != null and resolver != null

func is_resolving() -> bool:
    return _resolving

func has_pending_failed_swap() -> bool:
    return not _pending_failed_swap_snapshot.is_empty()

func begin_swap(first: Vector2i, second: Vector2i) -> Dictionary:
    if has_pending_failed_swap():
        return {
            "accepted": false,
            "reason": "FAILED_SWAP_PENDING",
        }
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

    var before_swap: Array = board.snapshot()
    var swap_result: Dictionary = board.try_swap_for_match(first, second)
    if not bool(swap_result.get("accepted", false)):
        if String(swap_result.get("reason", "")) == "NO_MATCH":
            var swapped_snapshot: Array = _snapshot_after_swap(first, second, before_swap)
            if not swapped_snapshot.is_empty():
                _pending_failed_swap_snapshot = swapped_snapshot
                swap_result["swapped_snapshot"] = swapped_snapshot.duplicate()
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
    if resolver == null:
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

func keep_pending_failed_swap() -> bool:
    if not has_pending_failed_swap() or board == null:
        return false
    if not board.restore(_pending_failed_swap_snapshot):
        return false
    _pending_failed_swap_snapshot.clear()
    return true

func discard_pending_failed_swap() -> bool:
    if not has_pending_failed_swap():
        return false
    _pending_failed_swap_snapshot.clear()
    return true

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
        "failed_swap_pending": has_pending_failed_swap(),
        "failed_swap_snapshot": _pending_failed_swap_snapshot.duplicate(),
        "board": board_snapshot,
        "rng_state": rng_state,
    }

func drain_events() -> Array:
    var drained: Array = _events.duplicate(true)
    _events.clear()
    return drained

func _snapshot_after_swap(first: Vector2i, second: Vector2i, before_swap: Array) -> Array:
    if board == null or not board.restore(before_swap):
        return []
    var first_value: String = board.get_cell(first)
    var second_value: String = board.get_cell(second)
    if not board.set_cell(first, second_value) or not board.set_cell(second, first_value):
        board.restore(before_swap)
        return []
    var swapped_snapshot: Array = board.snapshot()
    board.restore(before_swap)
    return swapped_snapshot
