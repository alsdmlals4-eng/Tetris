class_name LineRules
extends RefCounted

static func energy_for_clear(lines: int) -> int:
    match lines:
        1:
            return 10
        2:
            return 22
        3:
            return 36
        4:
            return 52
        _:
            return 0

static func score_for_clear(lines: int, level: int = 1) -> int:
    var base := 0
    match lines:
        1:
            base = 100
        2:
            base = 300
        3:
            base = 500
        4:
            base = 800
        _:
            base = 0
    return base * maxi(level, 0)

static func make_event(lines: int, level: int = 1) -> Dictionary:
    return {
        "kind": &"line_clear",
        "lines": lines,
        "energy": energy_for_clear(lines),
        "score": score_for_clear(lines, level),
    }
