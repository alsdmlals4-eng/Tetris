class_name ChainBoard
extends RefCounted

var width: int
var height: int
var _cells: Array[String] = []

func _init(p_width: int = 3, p_height: int = 3) -> void:
    width = maxi(1, p_width)
    height = maxi(1, p_height)
    _cells.resize(width * height)
    _cells.fill("")

func _inside(position: Vector2i) -> bool:
    return position.x >= 0 and position.x < width and position.y >= 0 and position.y < height

func _index(position: Vector2i) -> int:
    return position.y * width + position.x

func get_cell(position: Vector2i) -> String:
    if not _inside(position):
        return ""
    return _cells[_index(position)]

func set_cell(position: Vector2i, value: String) -> bool:
    if not _inside(position):
        return false
    _cells[_index(position)] = value
    return true

func snapshot() -> Array:
    return _cells.duplicate()

func restore(values: Array) -> bool:
    if values.size() != _cells.size():
        return false
    for index in range(values.size()):
        _cells[index] = String(values[index])
    return true

func _is_adjacent(first: Vector2i, second: Vector2i) -> bool:
    if not _inside(first) or not _inside(second):
        return false
    return absi(first.x - second.x) + absi(first.y - second.y) == 1

func _swap_cells(first: Vector2i, second: Vector2i) -> void:
    var first_value: String = get_cell(first)
    var second_value: String = get_cell(second)
    set_cell(first, second_value)
    set_cell(second, first_value)

func find_match_groups(minimum_run: int = 3) -> Array:
    var groups: Array = []
    var threshold: int = maxi(3, minimum_run)

    for y in range(height):
        var x: int = 0
        while x < width:
            var symbol: String = get_cell(Vector2i(x, y))
            if symbol == "":
                x += 1
                continue
            var end_x: int = x + 1
            while end_x < width and get_cell(Vector2i(end_x, y)) == symbol:
                end_x += 1
            if end_x - x >= threshold:
                var cells: Array = []
                for matched_x in range(x, end_x):
                    cells.append(Vector2i(matched_x, y))
                groups.append({
                    "axis": "H",
                    "symbol": symbol,
                    "cells": cells,
                })
            x = end_x

    for x in range(width):
        var y: int = 0
        while y < height:
            var symbol: String = get_cell(Vector2i(x, y))
            if symbol == "":
                y += 1
                continue
            var end_y: int = y + 1
            while end_y < height and get_cell(Vector2i(x, end_y)) == symbol:
                end_y += 1
            if end_y - y >= threshold:
                var cells: Array = []
                for matched_y in range(y, end_y):
                    cells.append(Vector2i(x, matched_y))
                groups.append({
                    "axis": "V",
                    "symbol": symbol,
                    "cells": cells,
                })
            y = end_y

    return groups

func matched_cells(minimum_run: int = 3) -> Array:
    var unique_cells: Array = []
    for group in find_match_groups(minimum_run):
        for position in group["cells"]:
            if not unique_cells.has(position):
                unique_cells.append(position)
    return unique_cells

func try_swap_for_match(first: Vector2i, second: Vector2i) -> Dictionary:
    if not _is_adjacent(first, second):
        return {
            "accepted": false,
            "reason": "NOT_ADJACENT",
            "groups": [],
        }

    var before: Array = snapshot()
    _swap_cells(first, second)
    var groups: Array = find_match_groups()
    if groups.is_empty():
        restore(before)
        return {
            "accepted": false,
            "reason": "NO_MATCH",
            "groups": [],
        }

    return {
        "accepted": true,
        "reason": "MATCH",
        "groups": groups,
    }
