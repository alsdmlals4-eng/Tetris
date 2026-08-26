extends GutTest

const RANDOMIZER_PATH := "res://src/production/chain/chain_randomizer.gd"
const BOARD_PATH := "res://src/production/chain/chain_board.gd"

func _randomizer(seed_value: int = 20260824, palette: Array = ["R", "G", "B", "Y"]):
    assert_true(ResourceLoader.exists(RANDOMIZER_PATH), "ChainRandomizer script must exist")
    if not ResourceLoader.exists(RANDOMIZER_PATH):
        return null
    return load(RANDOMIZER_PATH).new(seed_value, palette)

func _board(width: int = 6, height: int = 6):
    assert_true(ResourceLoader.exists(BOARD_PATH))
    return load(BOARD_PATH).new(width, height)

func test_same_seed_and_palette_reproduce_exact_symbol_stream() -> void:
    var first = _randomizer(314159, ["R", "G", "B", "Y"])
    var second = _randomizer(314159, ["R", "G", "B", "Y"])
    if first == null or second == null:
        return

    var first_stream: Array = []
    var second_stream: Array = []
    for _index in range(40):
        first_stream.append(first.next_symbol())
        second_stream.append(second.next_symbol())

    assert_eq(first_stream, second_stream)

func test_different_seed_changes_stream_without_changing_palette_membership() -> void:
    var first = _randomizer(1, ["R", "G", "B", "Y"])
    var second = _randomizer(2, ["R", "G", "B", "Y"])
    if first == null or second == null:
        return

    var first_stream: Array = []
    var second_stream: Array = []
    for _index in range(40):
        first_stream.append(first.next_symbol())
        second_stream.append(second.next_symbol())

    assert_ne(first_stream, second_stream)
    for symbol in first_stream:
        assert_has(["R", "G", "B", "Y"], symbol)
    for symbol in second_stream:
        assert_has(["R", "G", "B", "Y"], symbol)

func test_stable_initial_fill_is_deterministic_and_contains_no_starting_match() -> void:
    var first_randomizer = _randomizer(8080, ["R", "G", "B", "Y", "P"])
    var second_randomizer = _randomizer(8080, ["R", "G", "B", "Y", "P"])
    var first_board = _board(7, 8)
    var second_board = _board(7, 8)
    if first_randomizer == null or second_randomizer == null:
        return

    assert_true(first_randomizer.fill_stable_board(first_board))
    assert_true(second_randomizer.fill_stable_board(second_board))
    assert_eq(first_board.snapshot(), second_board.snapshot())
    assert_true(first_board.find_match_groups().is_empty(), "Authored/runtime initial board must be stable before Chain input")
    for value in first_board.snapshot():
        assert_ne(value, "")

func test_invalid_empty_palette_refuses_generation_without_mutating_board() -> void:
    var randomizer = _randomizer(9, [])
    var board = _board(4, 4)
    if randomizer == null:
        return
    board.set_cell(Vector2i(1, 1), "KEEP")
    var before: Array = board.snapshot()

    assert_eq(randomizer.next_symbol(), "")
    assert_false(randomizer.fill_stable_board(board))
    assert_eq(board.snapshot(), before)

func test_randomizer_state_can_be_restored_for_deterministic_replay() -> void:
    var randomizer = _randomizer(777, ["R", "G", "B", "Y"])
    if randomizer == null:
        return

    for _index in range(5):
        randomizer.next_symbol()
    var checkpoint: int = randomizer.get_rng_state()
    var expected: Array = []
    for _index in range(12):
        expected.append(randomizer.next_symbol())

    assert_true(randomizer.restore_rng_state(checkpoint))
    var replayed: Array = []
    for _index in range(12):
        replayed.append(randomizer.next_symbol())
    assert_eq(replayed, expected)
