extends GutTest

func _board_signature(board: ChainBoard) -> Array:
    return board.snapshot()

func test_board_can_detect_whether_any_legal_match_swap_exists_without_mutation() -> void:
    var board := ChainBoard.new(3, 3)
    var values := [
        "A", "B", "A",
        "B", "A", "C",
        "C", "A", "B",
    ]
    assert_true(board.restore(values))
    var before := board.snapshot()

    assert_true(board.has_available_swap())
    assert_eq(board.snapshot(), before, "Availability inspection must never mutate the board")

func test_board_reports_no_available_swap_for_dead_pattern_without_mutation() -> void:
    var board := ChainBoard.new(3, 3)
    var values := [
        "A", "B", "C",
        "D", "E", "F",
        "G", "H", "I",
    ]
    assert_true(board.restore(values))
    var before := board.snapshot()

    assert_false(board.has_available_swap())
    assert_eq(board.snapshot(), before)

func test_fill_playable_board_is_stable_has_a_move_and_is_seed_deterministic() -> void:
    var palette := ["R", "G", "B", "Y", "P", "C"]
    var first_board := ChainBoard.new(8, 8)
    var second_board := ChainBoard.new(8, 8)
    var first_randomizer := ChainRandomizer.new(54321, palette)
    var second_randomizer := ChainRandomizer.new(54321, palette)

    assert_true(first_randomizer.fill_playable_board(first_board))
    assert_true(second_randomizer.fill_playable_board(second_board))
    assert_true(first_board.find_match_groups().is_empty())
    assert_true(first_board.has_available_swap())
    assert_eq(_board_signature(first_board), _board_signature(second_board))

func test_fill_playable_board_fails_closed_and_restores_original_board() -> void:
    var board := ChainBoard.new(3, 3)
    assert_true(board.restore([
        "Q", "W", "E",
        "R", "T", "Y",
        "U", "I", "O",
    ]))
    var before := board.snapshot()
    var randomizer := ChainRandomizer.new(7, ["A"])

    assert_false(randomizer.fill_playable_board(board, 4))
    assert_eq(board.snapshot(), before)
