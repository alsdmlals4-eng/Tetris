class_name LineBoard
extends RefCounted

var width: int
var visible_height: int
var hidden_rows: int
var total_height: int
var visible_start_y: int

var _cells: Array[String] = []

func _init(p_width: int = 10, p_visible_height: int = 20, p_hidden_rows: int = 4) -> void:
    width = p_width
    visible_height = p_visible_height
    hidden_rows = p_hidden_rows
    total_height = visible_height + hidden_rows
    visible_start_y = hidden_rows
    _cells.resize(width * total_height)
    _cells.fill("")

func _inside(position: Vector2i) -> bool:
    return position.x >= 0 and position.x < width and position.y >= 0 and position.y < total_height

func _cell_index(position: Vector2i) -> int:
    return position.y * width + position.x

func get_cell(position: Vector2i) -> String:
    if not _inside(position):
        return ""
    return _cells[_cell_index(position)]

func set_cell(position: Vector2i, value: String) -> bool:
    if not _inside(position):
        return false
    _cells[_cell_index(position)] = value
    return true

func can_place(cells: Array, origin: Vector2i) -> bool:
    for local_cell in cells:
        var position: Vector2i = origin + Vector2i(local_cell)
        if not _inside(position) or get_cell(position) != "":
            return false
    return true

func lock_cells(cells: Array, origin: Vector2i, value: String) -> bool:
    if not can_place(cells, origin):
        return false
    for local_cell in cells:
        var position: Vector2i = origin + Vector2i(local_cell)
        set_cell(position, value)
    return true

func _row_is_full(y: int) -> bool:
    for x in range(width):
        if get_cell(Vector2i(x, y)) == "":
            return false
    return true

func clear_full_rows() -> int:
    var write_y: int = total_height - 1
    var cleared: int = 0

    for read_y in range(total_height - 1, -1, -1):
        if _row_is_full(read_y):
            cleared += 1
            continue

        if write_y != read_y:
            for x in range(width):
                set_cell(Vector2i(x, write_y), get_cell(Vector2i(x, read_y)))
        write_y -= 1

    for y in range(write_y, -1, -1):
        for x in range(width):
            set_cell(Vector2i(x, y), "")

    return cleared
