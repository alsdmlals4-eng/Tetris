class_name ProductionLineBoardView
extends Control

const PREVIEW_COUNT := 5

var line_session: ProductionLineSession = null
var _model: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func bind_line_session(value: ProductionLineSession) -> bool:
    if value == null:
        line_session = null
        _model = {}
        queue_redraw()
        return false
    line_session = value
    return refresh()

func refresh() -> bool:
    if line_session == null or line_session.piece_cycle == null:
        _model = {}
        queue_redraw()
        return false

    var cycle := line_session.piece_cycle
    var board := cycle.board
    var active := cycle.active_piece
    if board == null or active == null:
        _model = {}
        queue_redraw()
        return false

    var visible_rows: Array = []
    for visible_y in range(board.visible_height):
        var row: Array = []
        var board_y: int = board.visible_start_y + visible_y
        for x in range(board.width):
            row.append(board.get_cell(Vector2i(x, board_y)))
        visible_rows.append(row)

    var active_cells: Array = []
    for local_cell in active.get_cells():
        active_cells.append(active.origin + Vector2i(local_cell))

    var ghost_origin: Vector2i = cycle.get_ghost_origin()
    var ghost_cells: Array = []
    for local_cell in active.get_cells():
        ghost_cells.append(ghost_origin + Vector2i(local_cell))

    _model = {
        "width": board.width,
        "height": board.visible_height,
        "visible_start_y": board.visible_start_y,
        "cells": visible_rows,
        "active_piece_id": active.piece_id,
        "active_origin": active.origin,
        "active_rotation": active.rotation,
        "active_cells": active_cells,
        "ghost_origin": ghost_origin,
        "ghost_cells": ghost_cells,
        "held_piece_id": cycle.held_piece_id,
        "next_piece_ids": cycle.peek_next(PREVIEW_COUNT).duplicate(),
    }
    queue_redraw()
    return true

func snapshot() -> Dictionary:
    return _model.duplicate(true)

func _draw() -> void:
    if _model.is_empty() or line_session == null or line_session.piece_cycle == null:
        return

    var width: int = int(_model.get("width", 0))
    var height: int = int(_model.get("height", 0))
    if width <= 0 or height <= 0:
        return

    var board_width_limit := maxf(120.0, size.x - 150.0)
    var cell_size := floorf(minf(size.y / float(height), board_width_limit / float(width)))
    if cell_size < 4.0:
        return

    var board_size := Vector2(cell_size * width, cell_size * height)
    var board_origin := Vector2((size.x - board_size.x) * 0.5, (size.y - board_size.y) * 0.5)
    var visible_start_y: int = int(_model.get("visible_start_y", 0))
    var rows: Array = _model.get("cells", [])

    draw_rect(Rect2(board_origin, board_size), Color(0.035, 0.045, 0.065, 1.0), true)
    for y in range(height):
        for x in range(width):
            var rect := Rect2(board_origin + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
            draw_rect(rect, Color(0.18, 0.21, 0.27, 0.55), false, 1.0)
            if y < rows.size() and x < (rows[y] as Array).size():
                var piece_id := String((rows[y] as Array)[x])
                if piece_id != "":
                    draw_rect(rect.grow(-1.0), _piece_color(piece_id), true)

    for cell_value in _model.get("ghost_cells", []):
        var cell := Vector2i(cell_value)
        var visible_y := cell.y - visible_start_y
        if cell.x < 0 or cell.x >= width or visible_y < 0 or visible_y >= height:
            continue
        var rect := Rect2(board_origin + Vector2(cell.x, visible_y) * cell_size, Vector2.ONE * cell_size)
        draw_rect(rect.grow(-2.0), Color(0.78, 0.84, 0.95, 0.38), false, 2.0)

    var active_piece_id := String(_model.get("active_piece_id", ""))
    for cell_value in _model.get("active_cells", []):
        var cell := Vector2i(cell_value)
        var visible_y := cell.y - visible_start_y
        if cell.x < 0 or cell.x >= width or visible_y < 0 or visible_y >= height:
            continue
        var rect := Rect2(board_origin + Vector2(cell.x, visible_y) * cell_size, Vector2.ONE * cell_size)
        draw_rect(rect.grow(-1.0), _piece_color(active_piece_id), true)

    _draw_preview_slots(board_origin, board_size, cell_size)

func _draw_preview_slots(board_origin: Vector2, board_size: Vector2, board_cell_size: float) -> void:
    var preview_cell := clampf(board_cell_size * 0.62, 6.0, 13.0)
    var left_origin := Vector2(maxf(4.0, board_origin.x - preview_cell * 4.0 - 12.0), board_origin.y + 18.0)
    var right_origin := Vector2(board_origin.x + board_size.x + 12.0, board_origin.y + 18.0)

    draw_rect(Rect2(left_origin - Vector2(4, 4), Vector2(preview_cell * 4.0 + 8.0, preview_cell * 4.0 + 8.0)), Color(0.32, 0.34, 0.40, 0.65), false, 1.0)
    _draw_piece_preview(String(_model.get("held_piece_id", "")), left_origin, preview_cell)

    var next_ids: Array = _model.get("next_piece_ids", [])
    for index in range(next_ids.size()):
        var slot_origin := right_origin + Vector2(0.0, index * preview_cell * 3.15)
        draw_rect(Rect2(slot_origin - Vector2(3, 3), Vector2(preview_cell * 4.0 + 6.0, preview_cell * 3.0 + 6.0)), Color(0.32, 0.34, 0.40, 0.55), false, 1.0)
        _draw_piece_preview(String(next_ids[index]), slot_origin, preview_cell)

func _draw_piece_preview(piece_id: String, origin: Vector2, cell_size: float) -> void:
    if piece_id == "":
        return
    var catalog := line_session.piece_cycle.catalog
    if catalog == null:
        return
    for local_cell in catalog.get_cells(piece_id, 0):
        var cell := Vector2i(local_cell)
        var rect := Rect2(origin + Vector2(cell.x, cell.y) * cell_size, Vector2.ONE * cell_size)
        draw_rect(rect.grow(-1.0), _piece_color(piece_id), true)

func _piece_color(piece_id: String) -> Color:
    match piece_id:
        "I": return Color(0.24, 0.78, 0.92, 1.0)
        "J": return Color(0.33, 0.47, 0.88, 1.0)
        "L": return Color(0.92, 0.58, 0.24, 1.0)
        "O": return Color(0.93, 0.82, 0.28, 1.0)
        "S": return Color(0.38, 0.78, 0.40, 1.0)
        "T": return Color(0.67, 0.40, 0.84, 1.0)
        "Z": return Color(0.88, 0.34, 0.35, 1.0)
        _: return Color(0.68, 0.72, 0.78, 1.0)
