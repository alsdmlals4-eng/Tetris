class_name TetrominoCatalog
extends RefCounted

var _pieces: Dictionary = {}
var _kick_profiles: Dictionary = {}
var _spawn_origin: Vector2i = Vector2i(3, 0)

static func from_dictionary(data: Dictionary) -> TetrominoCatalog:
    var catalog := TetrominoCatalog.new()
    catalog._pieces = data.get("pieces", {}).duplicate(true)
    catalog._kick_profiles = data.get("kick_profiles", {}).duplicate(true)
    var spawn: Array = data.get("spawn_origin", [3, 0])
    if spawn.size() >= 2:
        catalog._spawn_origin = Vector2i(int(spawn[0]), int(spawn[1]))
    return catalog

func get_piece_ids() -> Array:
    return _pieces.keys()

func has_piece(piece_id: String) -> bool:
    return _pieces.has(piece_id)

func get_cells(piece_id: String, rotation: int) -> Array:
    if not has_piece(piece_id):
        return []
    var piece: Dictionary = _pieces[piece_id]
    var rotations: Array = piece.get("rotations", [])
    if rotations.is_empty():
        return []
    var normalized_rotation: int = posmod(rotation, rotations.size())
    var raw_cells: Array = rotations[normalized_rotation]
    var cells: Array = []
    for raw_cell in raw_cells:
        if raw_cell is Array and raw_cell.size() >= 2:
            cells.append(Vector2i(int(raw_cell[0]), int(raw_cell[1])))
    return cells

func get_spawn_origin(piece_id: String, _board_width: int, _hidden_rows: int) -> Vector2i:
    if not has_piece(piece_id):
        return Vector2i.ZERO
    return _spawn_origin

func get_kick_tests(piece_id: String, from_rotation: int, to_rotation: int) -> Array:
    if not has_piece(piece_id):
        return []
    var piece: Dictionary = _pieces[piece_id]
    var profile_id: String = String(piece.get("kick_profile", "JLSTZ"))
    if not _kick_profiles.has(profile_id):
        return []
    var profile: Dictionary = _kick_profiles[profile_id]
    var key := "%d>%d" % [posmod(from_rotation, 4), posmod(to_rotation, 4)]
    var raw_kicks: Array = profile.get(key, [])
    var kicks: Array = []
    for raw_kick in raw_kicks:
        if raw_kick is Array and raw_kick.size() >= 2:
            kicks.append(Vector2i(int(raw_kick[0]), int(raw_kick[1])))
    return kicks
