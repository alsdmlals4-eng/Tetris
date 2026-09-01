class_name ChainResolver
extends RefCounted

const MAX_CASCADE_DEPTH: int = 128

var board: ChainBoard
var randomizer

func _init(p_board: ChainBoard, p_randomizer) -> void:
    board = p_board
    randomizer = p_randomizer

func resolve_existing_matches() -> Dictionary:
    var waves: Array = []
    var depth: int = 0

    while true:
        var groups: Array = board.find_match_groups()
        if groups.is_empty():
            return {
                "success": true,
                "reason": "STABLE",
                "chain_depth": depth,
                "waves": waves,
            }

        if depth >= MAX_CASCADE_DEPTH:
            return {
                "success": false,
                "reason": "CASCADE_LIMIT",
                "chain_depth": depth,
                "waves": waves,
            }

        depth += 1
        var matched: Array = board.matched_cells()
        var symbols: Array = []
        for group in groups:
            var symbol: String = String(group["symbol"])
            if not symbols.has(symbol):
                symbols.append(symbol)

        var cleared_count: int = board.clear_cells(matched)
        var qualified_line_lengths: Array[int] = []
        for group in groups:
            qualified_line_lengths.append((group["cells"] as Array).size())
        waves.append({
            "depth": depth,
            "groups": groups.duplicate(true),
            "cleared_count": cleared_count,
            "qualified_line_lengths": qualified_line_lengths,
            "symbols": symbols,
        })

        board.apply_gravity()
        if not _refill_empty_cells():
            return {
                "success": false,
                "reason": "REFILL_FAILED",
                "chain_depth": depth,
                "waves": waves,
            }

    return {
        "success": false,
        "reason": "UNREACHABLE",
        "chain_depth": depth,
        "waves": waves,
    }

func _refill_empty_cells() -> bool:
    var before_refill: Array = board.snapshot()
    for y in range(board.height):
        for x in range(board.width):
            var position := Vector2i(x, y)
            if board.get_cell(position) != "":
                continue
            var symbol: String = String(randomizer.next_symbol())
            if symbol == "":
                board.restore(before_refill)
                return false
            board.set_cell(position, symbol)
    return true
