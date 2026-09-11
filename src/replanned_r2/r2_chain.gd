## Persistent horizontal/vertical matcher and timed cascade workspace.
extends RefCounted

const KINDS := ["A", "D", "H", "T"]
const WAVE_US := 300000
const MAX_WAVES := 64
const DATA_PATH := "res://docs/design/r2-complete-session.json"

var cells: Array = []
var resolving := false
var chain_id := 0
var wave_index := 0
var category_snapshot := ""
var next_wave_remaining_us := 0
var processed_event_ids: Array = []
var training_stream: Array = []
var training_index := 0
var _rng := RandomNumberGenerator.new()
var _seed := 9112026
var _teaching: Dictionary

func _init(seed_value: int = 9112026) -> void:
    _seed = seed_value
    _rng.seed = seed_value
    _teaching = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))["chain_teaching"]
    generate_stable()

func rows() -> Array:
    return cells.duplicate()

func _put(x: int, y: int, kind: String) -> void:
    var row: String = cells[y]
    cells[y] = row.substr(0, x) + kind + row.substr(x + 1)

func matched_cells() -> Array:
    var found: Dictionary = {}
    for y in range(8):
        var x := 0
        while x < 8:
            var end := x + 1
            while end < 8 and cells[y][end] == cells[y][x]:
                end += 1
            if end - x >= 3:
                for i in range(x, end): found[Vector2i(i, y)] = true
            x = end
    for x in range(8):
        var y := 0
        while y < 8:
            var end := y + 1
            while end < 8 and cells[end][x] == cells[y][x]:
                end += 1
            if end - y >= 3:
                for i in range(y, end): found[Vector2i(x, i)] = true
            y = end
    var result: Array = []
    for x in range(8):
        for y in range(8):
            if found.has(Vector2i(x,y)): result.append([x,y])
    return result

func _swap(a: Vector2i, b: Vector2i) -> void:
    var first: String = cells[a.y][a.x]
    _put(a.x, a.y, cells[b.y][b.x])
    _put(b.x, b.y, first)

func has_valid_move() -> bool:
    for y in range(8):
        for x in range(8):
            for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
                var a := Vector2i(x,y)
                var b: Vector2i = a + direction
                if b.x >= 8 or b.y >= 8: continue
                _swap(a,b)
                var valid := not matched_cells().is_empty()
                _swap(a,b)
                if valid: return true
    return false

func generate_stable() -> void:
    for attempt in range(256):
        cells = []
        for y in range(8):
            var row := ""
            for x in range(8): row += KINDS[_rng.randi_range(0,3)]
            cells.append(row)
        if matched_cells().is_empty() and has_valid_move(): return
    cells = _teaching["rows"].duplicate()

func setup_training() -> void:
    cancel()
    cells = _teaching["rows"].duplicate()
    training_stream = _teaching["refill_stream"].duplicate()
    training_index = 0

func try_swap(a: Vector2i, b: Vector2i, category: String) -> Dictionary:
    if resolving: return {"success":false, "reason":"CASCADE_RUNNING"}
    if category not in ["ATK","DEF","SUP"]: return {"success":false, "reason":"INVALID_CATEGORY"}
    if a.x < 0 or a.x >= 8 or a.y < 0 or a.y >= 8 or b.x < 0 or b.x >= 8 or b.y < 0 or b.y >= 8:
        return {"success":false, "reason":"INVALID_CELL"}
    if absi(a.x-b.x) + absi(a.y-b.y) != 1:
        return {"success":false, "reason":"NOT_ORTHOGONAL_NEIGHBORS"}
    _swap(a,b)
    if matched_cells().is_empty():
        _swap(a,b)
        return {"success":false, "reason":"NO_MATCH"}
    chain_id += 1
    resolving = true
    wave_index = 0
    category_snapshot = category
    next_wave_remaining_us = WAVE_US
    return {"success":true, "reason":"", "chain_id":chain_id}

func advance_time(delta_us: int) -> void:
    if resolving: next_wave_remaining_us = maxi(0, next_wave_remaining_us - delta_us)

func due_cast() -> Dictionary:
    if not resolving or next_wave_remaining_us != 0: return {}
    return {"id":"chain:%d:wave:%d" % [chain_id,wave_index+1], "category":category_snapshot, "wave":wave_index+1}

func commit_wave() -> Dictionary:
    var event := due_cast()
    if event.is_empty(): return {}
    var cleared := matched_cells()
    wave_index += 1
    processed_event_ids.append(event["id"])
    var removed: Dictionary = {}
    for cell in cleared: removed[Vector2i(int(cell[0]),int(cell[1]))] = true
    # Pull surviving tiles down; generate each column's new rows top to bottom.
    for x in range(8):
        var survivors: Array = []
        for y in range(8):
            if not removed.has(Vector2i(x,y)): survivors.append(cells[y][x])
        var missing := 8 - survivors.size()
        for y in range(missing): _put(x,y,_next_kind())
        for y in range(survivors.size()): _put(x,y+missing,survivors[y])
    var completed_wave := wave_index
    var safety_recovery := wave_index >= MAX_WAVES
    if safety_recovery:
        training_stream = []
        training_index = 0
        generate_stable()
        cancel()
    elif matched_cells().is_empty():
        cancel()
        if not has_valid_move(): generate_stable()
    else:
        next_wave_remaining_us = WAVE_US
    return {"success":true, "effect":"CHAIN_WAVE_RESOLVED", "wave":completed_wave,
        "cells":cleared, "safety_recovery":safety_recovery}

func _next_kind() -> String:
    if training_index < training_stream.size():
        var result: String = training_stream[training_index]
        training_index += 1
        return result
    return KINDS[_rng.randi_range(0,3)]

func cancel() -> void:
    resolving = false
    wave_index = 0
    next_wave_remaining_us = 0
    category_snapshot = ""

func snapshot() -> Dictionary:
    return {"cells":rows(), "chain_rng_state":str(_rng.state), "seed":str(_seed),
        "chain_id":chain_id, "wave_index":wave_index, "category_snapshot":category_snapshot,
        "processed_event_ids":processed_event_ids.duplicate(), "next_wave_remaining_us":next_wave_remaining_us,
        "resolving":resolving, "training_stream":training_stream.duplicate(), "training_index":training_index}

func restore(data: Dictionary, terminal: bool = false) -> bool:
    var expected := snapshot().keys()
    if data.size() != expected.size(): return false
    for key in expected:
        if not data.has(key): return false
    if not valid_rows(data.cells): return false
    if not valid_i64(data.chain_rng_state) or not valid_i64(data.seed): return false
    if not valid_integer(data.chain_id,0,2147483647) or not valid_integer(data.training_index,0,2147483647): return false
    if not data.resolving is bool or data.resolving or data.wave_index != 0 or data.next_wave_remaining_us != 0 or data.category_snapshot != "": return false
    if not data.processed_event_ids is Array or not data.training_stream is Array: return false
    var unique: Dictionary = {}
    for id in data.processed_event_ids:
        if not id is String or id.is_empty() or unique.has(id): return false
        unique[id] = true
    for kind in data.training_stream:
        if kind not in KINDS: return false
    if int(data.training_index) > data.training_stream.size(): return false
    var previous := cells
    cells = data.cells.duplicate()
    var stable := matched_cells().is_empty() and has_valid_move()
    cells = previous
    if not terminal and not stable: return false
    cells = data.cells.duplicate()
    _seed = int(data.seed)
    _rng.seed = _seed
    _rng.state = int(data.chain_rng_state)
    chain_id = int(data.chain_id)
    processed_event_ids = data.processed_event_ids.duplicate()
    training_stream = data.training_stream.duplicate()
    training_index = int(data.training_index)
    cancel()
    return true

static func valid_rows(value) -> bool:
    if not value is Array or value.size() != 8: return false
    for row in value:
        if not row is String or row.length() != 8: return false
        for kind in row:
            if kind not in KINDS: return false
    return true

static func valid_i64(value) -> bool:
    return value is String and value.is_valid_int() and str(int(value)) == value

static func valid_integer(value, minimum: int, maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= minimum and value <= maximum
