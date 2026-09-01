extends GutTest

const RESOLVER_PATH := "res://src/production/chain/chain_resolver.gd"
const BOARD_PATH := "res://src/production/chain/chain_board.gd"

class ScriptedRandomizer:
    extends RefCounted

    var values: Array[String] = []
    var index: int = 0

    func _init(p_values: Array) -> void:
        for value in p_values:
            values.append(String(value))

    func next_symbol() -> String:
        if values.is_empty():
            return ""
        var value: String = values[index % values.size()]
        index += 1
        return value

func _resolver(board, randomizer):
    assert_true(ResourceLoader.exists(RESOLVER_PATH), "ChainResolver script must exist")
    if not ResourceLoader.exists(RESOLVER_PATH):
        return null
    return load(RESOLVER_PATH).new(board, randomizer)

func _board(width: int, height: int, rows: Array):
    var board = load(BOARD_PATH).new(width, height)
    for y in range(rows.size()):
        for x in range(rows[y].size()):
            board.set_cell(Vector2i(x, y), String(rows[y][x]))
    return board

func test_stable_board_resolves_zero_waves_without_consuming_refill_stream() -> void:
    var board = _board(3, 3, [
        ["A", "B", "C"],
        ["D", "E", "F"],
        ["G", "H", "I"],
    ])
    var randomizer := ScriptedRandomizer.new(["X"])
    var resolver = _resolver(board, randomizer)
    if resolver == null:
        return
    var before: Array = board.snapshot()

    var result: Dictionary = resolver.resolve_existing_matches()

    assert_true(result["success"])
    assert_eq(result["chain_depth"], 0)
    assert_eq(result["waves"].size(), 0)
    assert_eq(board.snapshot(), before)
    assert_eq(randomizer.index, 0)

func test_two_wave_cascade_records_exact_depth_and_finishes_stable() -> void:
    var board = _board(3, 3, [
        ["A", "A", "A"],
        ["B", "C", "D"],
        ["C", "D", "B"],
    ])
    var randomizer := ScriptedRandomizer.new([
        "B", "B", "B",
        "C", "D", "B",
    ])
    var resolver = _resolver(board, randomizer)
    if resolver == null:
        return

    var result: Dictionary = resolver.resolve_existing_matches()

    assert_true(result["success"])
    assert_eq(result["chain_depth"], 2)
    assert_eq(result["waves"].size(), 2)
    assert_eq(result["waves"][0]["depth"], 1)
    assert_eq(result["waves"][0]["cleared_count"], 3)
    assert_eq(result["waves"][0]["groups"][0]["symbol"], "A")
    assert_eq(result["waves"][1]["depth"], 2)
    assert_eq(result["waves"][1]["groups"][0]["symbol"], "B")
    assert_true(board.find_match_groups().is_empty())
    assert_eq(board.snapshot(), [
        "C", "D", "B",
        "B", "C", "D",
        "C", "D", "B",
    ])

func test_cross_match_preserves_two_group_axes_but_clears_center_once() -> void:
    var rows: Array = []
    for y in range(5):
        var row: Array = []
        for x in range(5):
            row.append("%d_%d" % [x, y])
        rows.append(row)
    rows[2][1] = "X"
    rows[2][2] = "X"
    rows[2][3] = "X"
    rows[1][2] = "X"
    rows[3][2] = "X"

    var board = _board(5, 5, rows)
    var refill: Array = []
    for index in range(20):
        refill.append("R%d" % index)
    var resolver = _resolver(board, ScriptedRandomizer.new(refill))
    if resolver == null:
        return

    var result: Dictionary = resolver.resolve_existing_matches()

    assert_true(result["success"])
    assert_eq(result["chain_depth"], 1)
    assert_eq(result["waves"][0]["groups"].size(), 2)
    assert_eq(result["waves"][0]["groups"][0]["axis"], "H")
    assert_eq(result["waves"][0]["groups"][1]["axis"], "V")
    assert_eq(result["waves"][0]["cleared_count"], 5)
    assert_eq(result["waves"][0]["qualified_line_lengths"], [3, 3])
    assert_eq(result["waves"][0]["symbols"], ["X"])
    assert_true(board.find_match_groups().is_empty())

func test_refill_failure_is_reported_instead_of_leaving_false_stable_success() -> void:
    var board = _board(3, 3, [
        ["A", "A", "A"],
        ["B", "C", "D"],
        ["C", "D", "B"],
    ])
    var resolver = _resolver(board, ScriptedRandomizer.new([]))
    if resolver == null:
        return

    var result: Dictionary = resolver.resolve_existing_matches()

    assert_false(result["success"])
    assert_eq(result["reason"], "REFILL_FAILED")
    assert_eq(result["chain_depth"], 1)
