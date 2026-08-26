## persistent Line workspace의 현재 board와 active tetromino를 그린다.
class_name ProductionLineBoardView
extends Control

var _session = null

func bind_line_session(session) -> void:
	_session = session
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("08101c"), true)
	if _session == null or _session.piece_cycle == null or _session.piece_cycle.board == null:
		return
	var board = _session.piece_cycle.board
	var cell_size := minf(size.x / float(board.width), size.y / float(board.visible_height))
	var offset := Vector2((size.x - cell_size * board.width) * 0.5, 0.0)
	for y in range(board.visible_height):
		for x in range(board.width):
			var position := Vector2i(x, y + board.hidden_rows)
			var occupied: bool = board.get_cell(position) != ""
			draw_rect(Rect2(offset + Vector2(x, y) * cell_size, Vector2.ONE * (cell_size - 1.0)), Color("3973b9") if occupied else Color("142238"), true)
	var active = _session.piece_cycle.active_piece
	if active != null:
		for cell_variant in active.get_cells():
			var cell: Vector2i = active.origin + Vector2i(cell_variant)
			var visible_y: int = cell.y - board.hidden_rows
			if visible_y >= 0 and visible_y < board.visible_height:
				draw_rect(Rect2(offset + Vector2(cell.x, visible_y) * cell_size, Vector2.ONE * (cell_size - 1.0)), Color("a35cff"), true)
