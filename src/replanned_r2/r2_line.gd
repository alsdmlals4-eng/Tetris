## LINE collision/rotation reuse with independently bagged piece resources.
extends RefCounted

const Board = preload("res://src/production/line/line_board.gd")
const Piece = preload("res://src/production/line/active_tetromino.gd")
const Catalog = preload("res://src/production/line/tetromino_catalog.gd")
const Validation = preload("res://src/replanned_r2/r2_chain.gd")
const SHAPES := ["I","J","L","O","S","T","Z"]
const KINDS := ["A","D","H","T"]
const GRAVITY_US := 1000000
const LOCK_US := 500000
const RESET_LIMIT := 15
const CATALOG_PATH := "res://data/production/line_tetrominoes.json"

var board: LineBoard
var catalog: TetrominoCatalog
var active: ActiveTetromino
var active_resource := ""
var hold_shape := ""
var hold_resource := ""
var hold_available := true
var next_queue: Array = []
var gravity_accumulator_us := 0
var grounded_us := 0
var lock_reset_count := 0
var lock_sequence := 0
var reset_sequence := 0
var _draw_count := 0
var _shape_bag: Array = []
var _resource_bag: Array = []
var _shape_rng := RandomNumberGenerator.new()
var _resource_rng := RandomNumberGenerator.new()
var _shape_seed := 9112026
var _resource_seed := 0

func _init(seed_value: int = 9112026) -> void:
    _shape_seed = seed_value
    _resource_seed = hash("r2-resource:%d" % seed_value)
    _shape_rng.seed = _shape_seed
    _resource_rng.seed = _resource_seed
    catalog = Catalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH)))
    board = Board.new()
    _fill_next()
    _spawn_next()

func _shuffled(values: Array, rng: RandomNumberGenerator) -> Array:
    var result := values.duplicate()
    for index in range(result.size()-1,0,-1):
        var other := rng.randi_range(0,index)
        var temporary = result[index]
        result[index] = result[other]
        result[other] = temporary
    return result

func _fill_next() -> void:
    while next_queue.size() < 5:
        if _shape_bag.is_empty(): _shape_bag = _shuffled(SHAPES,_shape_rng)
        if _resource_bag.is_empty(): _resource_bag = _shuffled(KINDS,_resource_rng)
        next_queue.append({"shape":_shape_bag.pop_front(), "resource":_resource_bag.pop_front()})
        _draw_count += 1

func _spawn_pair(pair: Dictionary) -> void:
    active = Piece.new(pair.shape,catalog.get_spawn_origin(pair.shape,10,4),catalog)
    active_resource = pair.resource
    gravity_accumulator_us = 0
    grounded_us = 0
    lock_reset_count = 0

func _spawn_next() -> void:
    var pair: Dictionary = next_queue.pop_front()
    _fill_next()
    _spawn_pair(pair)

func active_pair() -> Dictionary:
    return {"shape":active.piece_id,"resource":active_resource}

func hold_pair() -> Dictionary:
    return {"shape":hold_shape,"resource":hold_resource}

func active_cells() -> Array:
    var result: Array = []
    for cell in active.get_cells():
        result.append([active.origin.x+cell.x,active.origin.y+cell.y])
    return result

func ghost_cells() -> Array:
    var distance := 0
    while board.can_place(active.get_cells(),active.origin+Vector2i(0,distance+1)): distance += 1
    var result: Array = []
    for cell in active.get_cells():
        result.append([active.origin.x+cell.x,active.origin.y+cell.y+distance])
    return result

func rows(visible_only: bool = true) -> Array:
    var result: Array = []
    for y in range(4 if visible_only else 0,24):
        var row := ""
        for x in range(10):
            var kind := board.get_cell(Vector2i(x,y))
            row += "." if kind.is_empty() else kind
        result.append(row)
    return result

func grounded() -> bool:
    return not board.can_place(active.get_cells(),active.origin+Vector2i.DOWN)

func spawn_blocked() -> bool:
    return not board.can_place(active.get_cells(),active.origin)

func move(dx: int, dy: int = 0) -> bool:
    if spawn_blocked() or absi(dx)+absi(dy) != 1: return false
    var was_grounded := grounded()
    if not active.try_move(board,Vector2i(dx,dy)): return false
    if dx != 0: _reset_lock(was_grounded)
    elif not grounded(): grounded_us = 0
    return true

func rotate(direction: int) -> bool:
    if spawn_blocked() or direction not in [-1,1]: return false
    var was_grounded := grounded()
    if not active.try_rotate(board,direction): return false
    _reset_lock(was_grounded)
    return true

func _reset_lock(was_grounded: bool) -> void:
    if was_grounded and lock_reset_count < RESET_LIMIT:
        grounded_us = 0
        lock_reset_count += 1
    if not grounded(): grounded_us = 0

func hold() -> bool:
    if not hold_available or spawn_blocked(): return false
    var previous := active_pair()
    if hold_shape.is_empty(): _spawn_next()
    else: _spawn_pair(hold_pair())
    hold_shape = previous.shape
    hold_resource = previous.resource
    hold_available = false
    return true

func next_event_us() -> int:
    if spawn_blocked(): return 0
    if grounded(): return maxi(0,LOCK_US-grounded_us)
    return maxi(0,GRAVITY_US-gravity_accumulator_us)

func advance_time(delta_us: int) -> void:
    if spawn_blocked(): return
    var was_grounded := grounded()
    # Grounded pieces advance lock time only. Gravity residual survives a lift.
    if was_grounded:
        grounded_us = mini(LOCK_US,grounded_us+delta_us)
    else:
        gravity_accumulator_us += delta_us
        if gravity_accumulator_us >= GRAVITY_US:
            gravity_accumulator_us -= GRAVITY_US
            active.try_move(board,Vector2i.DOWN)
            grounded_us = 0

func hard_drop_plan() -> Dictionary:
    if spawn_blocked(): return {"topout":true}
    active.hard_drop(board)
    return lock_plan()

func lock_plan() -> Dictionary:
    if spawn_blocked(): return {"topout":true}
    var occupied: Dictionary = {}
    for cell in active_cells(): occupied[Vector2i(int(cell[0]),int(cell[1]))] = active_resource
    var full: Array = []
    for y in range(24):
        var complete := true
        for x in range(10):
            if board.get_cell(Vector2i(x,y)).is_empty() and not occupied.has(Vector2i(x,y)):
                complete = false
                break
        if complete: full.append(y)
    var id := "line:%d" % (lock_sequence+1)
    var reward: Array = []
    for y in full:
        for x in range(10):
            var p := Vector2i(x,int(y))
            reward.append({"id":"%s:%d:%d" % [id,x,y], "kind":occupied.get(p,board.get_cell(p))})
    return {"topout":false,"id":id,"cells":reward,"rows":full}

func commit_lock() -> void:
    board.lock_cells(active.get_cells(),active.origin,active_resource)
    board.clear_full_rows()
    lock_sequence += 1
    hold_available = true
    _spawn_next()

func reset_after_topout() -> void:
    reset_sequence += 1
    board.clear_all()
    _spawn_pair(active_pair())
    hold_available = true

func setup_training(fixture: Dictionary) -> void:
    board.clear_all()
    var all_rows: Array = fixture.hidden_rows + fixture.visible_rows
    _set_rows(all_rows)
    _spawn_pair({"shape":String(fixture.piece), "resource":"A"})
    # The authored landing columns identify the starting horizontal lane.
    active.origin.x = int(fixture.landing[0][0])
    hold_shape = ""
    hold_resource = ""
    hold_available = true

func _set_rows(all_rows: Array) -> void:
    for y in range(24):
        for x in range(10):
            board.set_cell(Vector2i(x,y),"" if all_rows[y][x] == "." else all_rows[y][x])

func snapshot() -> Dictionary:
    var all_rows := rows(false)
    return {"visible_cells":all_rows.slice(4), "hidden_cells":all_rows.slice(0,4),
        "active_shape":active.piece_id, "active_resource":active_resource,
        "active_x":active.origin.x, "active_y":active.origin.y,"active_rotation":active.rotation,
        "gravity_accumulator_us":gravity_accumulator_us, "grounded_us":grounded_us,
        "lock_reset_count":lock_reset_count,"grounded":grounded(),
        "hold_shape":hold_shape, "hold_resource":hold_resource,"hold_available":hold_available,
        "next_queue":next_queue.duplicate(true),"shape_bag_remaining":_shape_bag.duplicate(),
        "resource_bag_remaining":_resource_bag.duplicate(),"shape_rng_state":str(_shape_rng.state),
        "resource_rng_state":str(_resource_rng.state),"shape_seed":str(_shape_seed),"resource_seed":str(_resource_seed),
        "lock_sequence":lock_sequence,"reset_sequence":reset_sequence,"draw_count":_draw_count}

func restore(data: Dictionary) -> bool:
    var expected := snapshot().keys()
    if data.size() != expected.size(): return false
    for key in expected:
        if not data.has(key): return false
    if not _valid_rows(data.visible_cells,20) or not _valid_rows(data.hidden_cells,4): return false
    if not _valid_pair({"shape":data.active_shape,"resource":data.active_resource}): return false
    if not data.hold_shape is String or not data.hold_resource is String: return false
    if (data.hold_shape == "") != (data.hold_resource == ""): return false
    if data.hold_shape != "" and not _valid_pair({"shape":data.hold_shape,"resource":data.hold_resource}): return false
    if not data.hold_available is bool or not data.grounded is bool: return false
    if not data.next_queue is Array or data.next_queue.size() != 5: return false
    for pair in data.next_queue:
        if not _valid_pair(pair): return false
    if not _valid_bag(data.shape_bag_remaining,SHAPES) or not _valid_bag(data.resource_bag_remaining,KINDS): return false
    for key in ["shape_rng_state","resource_rng_state","shape_seed","resource_seed"]:
        if not Validation.valid_i64(data[key]): return false
    var limits := {"active_x":[-4,9],"active_y":[-4,23],"active_rotation":[0,3],
        "gravity_accumulator_us":[0,GRAVITY_US-1],"grounded_us":[0,LOCK_US],
        "lock_reset_count":[0,RESET_LIMIT],"lock_sequence":[0,2147483647],"reset_sequence":[0,2147483647],"draw_count":[6,2147483647]}
    for key in limits:
        if not Validation.valid_integer(data[key],limits[key][0],limits[key][1]): return false
    if int(data.draw_count) < 6 + int(data.lock_sequence): return false
    if data.shape_bag_remaining.size() != posmod(-int(data.draw_count),7): return false
    if data.resource_bag_remaining.size() != posmod(-int(data.draw_count),4): return false
    if not _queue_bag_consistent(data.next_queue,data.shape_bag_remaining,"shape",int(data.draw_count),7): return false
    if not _queue_bag_consistent(data.next_queue,data.resource_bag_remaining,"resource",int(data.draw_count),4): return false
    var candidate_board := Board.new()
    var all_rows: Array = data.hidden_cells + data.visible_cells
    for y in range(24):
        for x in range(10):
            candidate_board.set_cell(Vector2i(x,y),"" if all_rows[y][x] == "." else all_rows[y][x])
    var candidate_piece := Piece.new(data.active_shape,Vector2i(int(data.active_x),int(data.active_y)),catalog)
    candidate_piece.rotation = int(data.active_rotation)
    if not candidate_board.can_place(candidate_piece.get_cells(),candidate_piece.origin): return false
    var actual_grounded := not candidate_board.can_place(candidate_piece.get_cells(),candidate_piece.origin+Vector2i.DOWN)
    if actual_grounded != data.grounded or (not actual_grounded and int(data.grounded_us) != 0): return false
    board = candidate_board
    active = candidate_piece
    active_resource = data.active_resource
    hold_shape = data.hold_shape
    hold_resource = data.hold_resource
    hold_available = data.hold_available
    next_queue = data.next_queue.duplicate(true)
    _shape_bag = data.shape_bag_remaining.duplicate()
    _resource_bag = data.resource_bag_remaining.duplicate()
    _shape_seed = int(data.shape_seed)
    _resource_seed = int(data.resource_seed)
    _shape_rng.seed = _shape_seed
    _resource_rng.seed = _resource_seed
    _shape_rng.state = int(data.shape_rng_state)
    _resource_rng.state = int(data.resource_rng_state)
    gravity_accumulator_us = int(data.gravity_accumulator_us)
    grounded_us = int(data.grounded_us)
    lock_reset_count = int(data.lock_reset_count)
    lock_sequence = int(data.lock_sequence)
    reset_sequence = int(data.reset_sequence)
    _draw_count = int(data.draw_count)
    return true

static func _valid_pair(value) -> bool:
    return value is Dictionary and value.size() == 2 and value.has("shape") and value.has("resource") and value.shape in SHAPES and value.resource in KINDS

static func _valid_bag(value, allowed: Array) -> bool:
    if not value is Array or value.size() > allowed.size(): return false
    var unique: Dictionary = {}
    for item in value:
        if item not in allowed or unique.has(item): return false
        unique[item] = true
    return true

static func _valid_rows(value, height: int) -> bool:
    if not value is Array or value.size() != height: return false
    for row in value:
        if not row is String or row.length() != 10: return false
        for kind in row:
            if kind not in [".","A","D","H","T"]: return false
    return true

static func _queue_bag_consistent(queue: Array, remaining: Array, key: String, drawn: int, bag_size: int) -> bool:
    var values: Array = []
    for pair in queue: values.append(pair[key])
    values.append_array(remaining)
    var unique: Dictionary = {}
    for offset in range(values.size()):
        if (drawn-5+offset) % bag_size == 0: unique.clear()
        if unique.has(values[offset]): return false
        unique[values[offset]] = true
    return true
