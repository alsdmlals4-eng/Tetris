class_name SevenBag
extends RefCounted

const PIECE_IDS: Array[String] = ["I", "J", "L", "O", "S", "T", "Z"]

var _rng := RandomNumberGenerator.new()
var _queue: Array[String] = []

func _init(seed_value: int) -> void:
    _rng.seed = seed_value

func next_piece_id() -> String:
    if _queue.is_empty():
        _refill()
    var piece_id: String = _queue.pop_front()
    return piece_id

func _refill() -> void:
    var bag: Array[String] = PIECE_IDS.duplicate()
    for index in range(bag.size() - 1, 0, -1):
        var swap_index: int = _rng.randi_range(0, index)
        var temporary: String = bag[index]
        bag[index] = bag[swap_index]
        bag[swap_index] = temporary
    _queue.append_array(bag)
