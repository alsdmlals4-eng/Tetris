## persistent Chain workspace의 현재 8x8 symbol board를 그린다.
class_name ProductionChainBoardView
extends Control

const PALETTE := {"R": Color("d85a61"), "G": Color("66c97a"), "B": Color("5c94e0"), "Y": Color("e7c85f"), "P": Color("b071db"), "C": Color("60c8ce")}
var _session = null
var _selected_cell := Vector2i(-1, -1)

func bind_chain_session(session) -> void:
	_session = session
	queue_redraw()

func set_selected_cell(cell: Vector2i) -> void:
	_selected_cell = cell
	queue_redraw()

func cell_at_local_position(local_position: Vector2) -> Vector2i:
	if _session == null or _session.board == null:
		return Vector2i(-1, -1)
	var board = _session.board
	var cell_size := minf(size.x / float(board.width), size.y / float(board.height))
	var offset := (size - Vector2(board.width, board.height) * cell_size) * 0.5
	var cell := Vector2i(floori((local_position.x - offset.x) / cell_size), floori((local_position.y - offset.y) / cell_size))
	if cell.x < 0 or cell.x >= board.width or cell.y < 0 or cell.y >= board.height:
		return Vector2i(-1, -1)
	return cell

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("120b20"), true)
	if _session == null or _session.board == null:
		return
	var board = _session.board
	var cell_size := minf(size.x / float(board.width), size.y / float(board.height))
	var offset := (size - Vector2(board.width, board.height) * cell_size) * 0.5
	for y in range(board.height):
		for x in range(board.width):
			var symbol: String = board.get_cell(Vector2i(x, y))
			draw_rect(Rect2(offset + Vector2(x, y) * cell_size, Vector2.ONE * (cell_size - 2.0)), PALETTE.get(symbol, Color("302247")), true)
	if _selected_cell.x >= 0 and _selected_cell.y >= 0:
		draw_rect(Rect2(offset + Vector2(_selected_cell) * cell_size, Vector2.ONE * (cell_size - 2.0)), Color("f7dd75"), false, 2.0)
