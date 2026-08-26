class_name ChainRandomizer
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _palette: Array[String] = []

func _init(seed_value: int, palette: Array) -> void:
    _rng.seed = seed_value
    for raw_symbol in palette:
        var symbol := String(raw_symbol)
        if symbol == "" or _palette.has(symbol):
            continue
        _palette.append(symbol)

func next_symbol() -> String:
    if _palette.is_empty():
        return ""
    return _palette[_rng.randi_range(0, _palette.size() - 1)]

func get_rng_state() -> int:
    return _rng.state

func restore_rng_state(saved_state: int) -> bool:
    _rng.state = saved_state
    return true

func fill_stable_board(board: ChainBoard) -> bool:
    if board == null or _palette.is_empty():
        return false

    var before: Array = board.snapshot()
    for y in range(board.height):
        for x in range(board.width):
            var candidates: Array[String] = []
            for symbol in _palette:
                if _would_create_starting_match(board, Vector2i(x, y), symbol):
                    continue
                candidates.append(symbol)

            if candidates.is_empty():
                board.restore(before)
                return false

            var chosen: String = candidates[_rng.randi_range(0, candidates.size() - 1)]
            board.set_cell(Vector2i(x, y), chosen)

    return board.find_match_groups().is_empty()

func _would_create_starting_match(board: ChainBoard, position: Vector2i, symbol: String) -> bool:
    if position.x >= 2:
        if board.get_cell(position + Vector2i(-1, 0)) == symbol and board.get_cell(position + Vector2i(-2, 0)) == symbol:
            return true
    if position.y >= 2:
        if board.get_cell(position + Vector2i(0, -1)) == symbol and board.get_cell(position + Vector2i(0, -2)) == symbol:
            return true
    return false
