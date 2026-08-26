class_name LinePieceCycle
extends RefCounted

const PREVIEW_MIN := 5

var board: LineBoard
var catalog: TetrominoCatalog
var bag: SevenBag
var active_piece: ActiveTetromino = null
var held_piece_id: String = ""
var hold_used_for_active: bool = false
var streak_state := LineStreakState.new()

var _upcoming: Array[String] = []

func _init(seed_value: int, p_catalog: TetrominoCatalog, p_board: LineBoard) -> void:
    catalog = p_catalog
    board = p_board
    bag = SevenBag.new(seed_value)

func start() -> void:
    if active_piece != null:
        return
    _spawn_from_stream()

func _ensure_upcoming(count: int) -> void:
    while _upcoming.size() < count:
        _upcoming.append(bag.next_piece_id())

func peek_next(count: int) -> Array:
    if count <= 0:
        return []
    _ensure_upcoming(count)
    return _upcoming.slice(0, count)

func _take_next_id() -> String:
    _ensure_upcoming(1)
    var piece_id: String = _upcoming.pop_front()
    _ensure_upcoming(PREVIEW_MIN)
    return piece_id

func _spawn_piece(piece_id: String) -> void:
    var spawn_origin := catalog.get_spawn_origin(piece_id, board.width, board.hidden_rows)
    active_piece = ActiveTetromino.new(piece_id, spawn_origin, catalog)

func _spawn_from_stream() -> void:
    _spawn_piece(_take_next_id())

func is_active_spawn_blocked() -> bool:
    if active_piece == null:
        return false
    return not board.can_place(active_piece.get_cells(), active_piece.origin)

func reset_after_board_break(reason: String) -> LineBoardBreakResult:
    if active_piece == null:
        return LineBoardBreakResult.rejected(reason)

    var piece_id := active_piece.piece_id
    board.clear_all()
    _spawn_piece(piece_id)
    return LineBoardBreakResult.new(true, reason, piece_id, true)

func complete_lock_and_spawn_next() -> void:
    hold_used_for_active = false
    _spawn_from_stream()

func commit_active_piece(reward_config: LineRewardConfig) -> LineClearResult:
    if active_piece == null or reward_config == null:
        return LineClearResult.failed("")

    var piece_id := active_piece.piece_id
    var spin_kind := LineSpinRecognizer.classify(board, active_piece)
    if not board.lock_cells(active_piece.get_cells(), active_piece.origin, piece_id):
        return LineClearResult.failed(piece_id)

    var lines_cleared := board.clear_full_rows()
    var result := reward_config.make_result(piece_id, lines_cleared)
    result.spin_kind = spin_kind
    result.perfect_clear = lines_cleared > 0 and board.is_empty()
    streak_state.decorate(result)
    complete_lock_and_spawn_next()
    return result

func try_hold() -> bool:
    if active_piece == null or hold_used_for_active:
        return false

    var outgoing_piece_id := active_piece.piece_id
    if held_piece_id == "":
        held_piece_id = outgoing_piece_id
        _spawn_from_stream()
    else:
        var incoming_piece_id := held_piece_id
        held_piece_id = outgoing_piece_id
        _spawn_piece(incoming_piece_id)

    hold_used_for_active = true
    return true

func get_ghost_origin() -> Vector2i:
    if active_piece == null:
        return Vector2i.ZERO

    var distance := 0
    var cells: Array = active_piece.get_cells()
    while board.can_place(cells, active_piece.origin + Vector2i(0, distance + 1)):
        distance += 1
    return active_piece.origin + Vector2i(0, distance)
