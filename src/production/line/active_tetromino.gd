class_name ActiveTetromino
extends RefCounted

var piece_id: String
var origin: Vector2i
var rotation: int = 0
var catalog: TetrominoCatalog

func _init(p_piece_id: String, p_origin: Vector2i, p_catalog: TetrominoCatalog) -> void:
    piece_id = p_piece_id
    origin = p_origin
    catalog = p_catalog

func get_cells() -> Array:
    return catalog.get_cells(piece_id, rotation)

func try_move(board: LineBoard, delta: Vector2i) -> bool:
    var candidate_origin := origin + delta
    if not board.can_place(get_cells(), candidate_origin):
        return false
    origin = candidate_origin
    return true

func try_rotate(board: LineBoard, direction: int) -> bool:
    if direction == 0:
        return false
    var target_rotation: int = posmod(rotation + (1 if direction > 0 else -1), 4)
    var target_cells: Array = catalog.get_cells(piece_id, target_rotation)
    for kick in catalog.get_kick_tests(piece_id, rotation, target_rotation):
        var candidate_origin: Vector2i = origin + Vector2i(kick)
        if board.can_place(target_cells, candidate_origin):
            origin = candidate_origin
            rotation = target_rotation
            return true
    return false

func hard_drop(board: LineBoard) -> int:
    var distance := 0
    while board.can_place(get_cells(), origin + Vector2i(0, distance + 1)):
        distance += 1
    origin += Vector2i(0, distance)
    return distance
