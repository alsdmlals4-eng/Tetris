extends GutTest

const BAG_PATH := "res://src/production/line/seven_bag.gd"
const EXPECTED_IDS := ["I", "J", "L", "O", "S", "T", "Z"]

func _make_bag(seed_value: int):
    assert_true(ResourceLoader.exists(BAG_PATH), "production SevenBag script must exist")
    if not ResourceLoader.exists(BAG_PATH):
        return null
    return load(BAG_PATH).new(seed_value)

func _draw(bag, count: int) -> Array:
    var result: Array = []
    for _index in range(count):
        result.append(bag.next_piece_id())
    return result

func _sorted_copy(values: Array) -> Array:
    var copy := values.duplicate()
    copy.sort()
    return copy

func test_each_bag_contains_all_seven_piece_ids_once() -> void:
    var bag = _make_bag(12345)
    if bag == null:
        return
    assert_eq(_sorted_copy(_draw(bag, 7)), EXPECTED_IDS)

func test_same_seed_reproduces_the_same_sequence() -> void:
    var a = _make_bag(777)
    var b = _make_bag(777)
    if a == null or b == null:
        return
    assert_eq(_draw(a, 28), _draw(b, 28))

func test_each_consecutive_group_of_seven_is_complete() -> void:
    var bag = _make_bag(20260824)
    if bag == null:
        return
    var first := _draw(bag, 7)
    var second := _draw(bag, 7)
    assert_eq(_sorted_copy(first), EXPECTED_IDS)
    assert_eq(_sorted_copy(second), EXPECTED_IDS)
