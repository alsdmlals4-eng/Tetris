## persistent Line workspace의 현재 board와 active tetromino를 그린다.
class_name ProductionLineBoardView
extends Control

const CONTROL_GUIDE := ["← / A", "→ / D", "↓ / S", "↑ / X", "Z", "C HOLD", "SPACE DROP"]

var _session = null

func bind_line_session(session) -> void:
	_session = session
	queue_redraw()

func get_meta_snapshot() -> Dictionary:
	if _session == null or _session.piece_cycle == null:
		return {
			"hold_piece_id": "",
			"hold_available": false,
			"next_preview": [],
			"last_clear": "",
		}
	var cycle = _session.piece_cycle
	return {
		"hold_piece_id": cycle.held_piece_id,
		"hold_available": not cycle.hold_used_for_active,
		"next_preview": cycle.peek_next(LinePieceCycle.PREVIEW_MIN).duplicate(),
		"last_clear": format_last_clear(_session.last_line_result),
	}

func format_last_clear(result: LineClearResult) -> String:
	if result == null or not result.success:
		return ""
	var parts: Array[String] = []
	if result.perfect_clear:
		parts.append("PERFECT CLEAR")
	var clear_label := _clear_label(result.clear_kind)
	if result.spin_kind == "T_SPIN":
		parts.append("T-SPIN" if clear_label == "" else "T-SPIN %s" % clear_label)
	elif clear_label != "":
		parts.append(clear_label)
	if result.back_to_back:
		parts.append("B2B")
	if result.combo_index >= 0:
		parts.append("COMBO ×%d" % (result.combo_index + 1))
	return " · ".join(parts)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("08101c"), true)
	if _session == null or _session.piece_cycle == null or _session.piece_cycle.board == null:
		return
	var rail_width := minf(maxf(128.0, size.x * 0.28), 172.0)
	var rail_rect := Rect2(Vector2.ZERO, Vector2(rail_width, size.y))
	var board_rect := Rect2(Vector2(rail_width + 8.0, 0.0), Vector2(maxf(0.0, size.x - rail_width - 8.0), size.y))
	_draw_meta_rail(rail_rect, get_meta_snapshot())
	_draw_board(board_rect)

func _draw_board(board_rect: Rect2) -> void:
	var board = _session.piece_cycle.board
	var cell_size := minf(board_rect.size.x / float(board.width), board_rect.size.y / float(board.visible_height))
	var offset := board_rect.position + Vector2((board_rect.size.x - cell_size * board.width) * 0.5, (board_rect.size.y - cell_size * board.visible_height) * 0.5)
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

func _draw_meta_rail(rail_rect: Rect2, meta: Dictionary) -> void:
	draw_rect(rail_rect, Color("0d1929"), true)
	draw_line(Vector2(rail_rect.end.x, 0.0), rail_rect.end, Color("38506d"), 1.0)
	var font := ThemeDB.fallback_font
	var x := rail_rect.position.x + 10.0
	var y := rail_rect.position.y + 20.0
	_draw_text(font, Vector2(x, y), "LINE CONTROLS", 14, Color("b7d5f4"))
	y += 18.0
	for guide in CONTROL_GUIDE:
		_draw_text(font, Vector2(x, y), guide, 12, Color("d9e7f6"))
		y += 16.0

	y += 8.0
	_draw_section(rail_rect, y, "HOLD", bool(meta.get("hold_available", false)))
	var hold_piece_id := String(meta.get("hold_piece_id", ""))
	if hold_piece_id == "":
		_draw_text(font, Vector2(x, y + 24.0), "EMPTY", 11, Color("65788e"))
	else:
		_draw_piece_preview(hold_piece_id, Vector2(x + 4.0, y + 21.0), 9.0, _piece_color(hold_piece_id))
	if not bool(meta.get("hold_available", false)):
		_draw_text(font, Vector2(x + 52.0, y + 27.0), "USED", 10, Color("8391a2"))

	y += 64.0
	_draw_section(rail_rect, y, "NEXT", true)
	var next_preview: Array = meta.get("next_preview", [])
	for index in range(next_preview.size()):
		var piece_id := String(next_preview[index])
		_draw_text(font, Vector2(x, y + 22.0 + index * 27.0), "%d" % (index + 1), 10, Color("71869c"))
		_draw_piece_preview(piece_id, Vector2(x + 18.0, y + 12.0 + index * 27.0), 6.5, _piece_color(piece_id))

	var last_clear := String(meta.get("last_clear", ""))
	if last_clear != "":
		var clear_y := minf(rail_rect.end.y - 22.0, y + 22.0 + next_preview.size() * 27.0 + 12.0)
		_draw_text(font, Vector2(x, clear_y), "LAST CLEAR", 10, Color("71869c"))
		_draw_text(font, Vector2(x, clear_y + 14.0), last_clear, 10, Color("f7d67d"))

func _draw_section(rail_rect: Rect2, y: float, title: String, active: bool) -> void:
	var color := Color("8cc8ff") if active else Color("65788e")
	draw_line(Vector2(rail_rect.position.x + 8.0, y - 13.0), Vector2(rail_rect.end.x - 8.0, y - 13.0), Color("273d57"), 1.0)
	_draw_text(ThemeDB.fallback_font, Vector2(rail_rect.position.x + 10.0, y), title, 12, color)

func _draw_text(font: Font, position: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _draw_piece_preview(piece_id: String, origin: Vector2, cell_size: float, color: Color) -> void:
	if _session == null or _session.piece_cycle == null:
		return
	var cells: Array = _session.piece_cycle.catalog.get_cells(piece_id, 0)
	if cells.is_empty():
		return
	var min_cell := Vector2i(99, 99)
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
	for cell_variant in cells:
		var cell: Vector2i = cell_variant
		var position := origin + Vector2(cell - min_cell) * cell_size
		draw_rect(Rect2(position, Vector2.ONE * maxf(2.0, cell_size - 1.0)), color, true)

func _piece_color(piece_id: String) -> Color:
	var colors := {
		"I": Color("50c8ff"), "J": Color("4776dc"), "L": Color("f2a64a"), "O": Color("f4dc50"),
		"S": Color("5acb71"), "T": Color("a35cff"), "Z": Color("e2606f"),
	}
	return colors.get(piece_id, Color("8294aa"))

func _clear_label(clear_kind: String) -> String:
	match clear_kind:
		"SINGLE", "DOUBLE", "TRIPLE":
			return clear_kind
		"FOUR":
			return "TETRIS"
	return ""
