class_name ProductionChainConfig
extends RefCounted

const STOCK_CAP: int = 6

var balance_status: String = ""
var seed_source: String = ""
var board_width: int = 0
var board_height: int = 0
var palette: Array[String] = []
var random_seed: int = 0
var stock_by_chain_depth: Dictionary = {}
var stock_cap: int = STOCK_CAP

static func _integer_value(raw):
    if not (raw is int or raw is float):
        return null
    var numeric := float(raw)
    var converted := int(numeric)
    if not is_equal_approx(numeric, float(converted)):
        return null
    return converted

static func from_dictionary(data):
    if not data is Dictionary:
        return null

    var status := String(data.get("balance_status", ""))
    var source := String(data.get("seed_source", ""))
    var board_data = data.get("board", null)
    var stock_data = data.get("stock_by_chain_depth", null)
    if status == "" or source == "" or not board_data is Dictionary or not stock_data is Dictionary:
        return null

    var width_value = _integer_value(board_data.get("width", null))
    var height_value = _integer_value(board_data.get("height", null))
    var seed_value = _integer_value(board_data.get("random_seed", null))
    if width_value == null or height_value == null or seed_value == null:
        return null
    if int(width_value) < 3 or int(height_value) < 3:
        return null

    var raw_palette = board_data.get("palette", null)
    if not raw_palette is Array:
        return null
    var parsed_palette: Array[String] = []
    for raw_symbol in raw_palette:
        var symbol := String(raw_symbol)
        if symbol == "" or parsed_palette.has(symbol):
            return null
        parsed_palette.append(symbol)
    if parsed_palette.size() < 3:
        return null

    var parsed_stock: Dictionary = {}
    for depth in range(1, STOCK_CAP + 1):
        var key := str(depth)
        if not stock_data.has(key):
            return null
        var stock_value = _integer_value(stock_data[key])
        if stock_value == null:
            return null
        var stock_int := int(stock_value)
        if stock_int < 0 or stock_int > STOCK_CAP:
            return null
        parsed_stock[key] = stock_int

    var config := ProductionChainConfig.new()
    config.balance_status = status
    config.seed_source = source
    config.board_width = int(width_value)
    config.board_height = int(height_value)
    config.palette = parsed_palette
    config.random_seed = int(seed_value)
    config.stock_by_chain_depth = parsed_stock
    config.stock_cap = STOCK_CAP
    return config

func stock_for_resolution(resolution) -> int:
    if not resolution is Dictionary or not bool(resolution.get("success", false)):
        return 0

    var raw_depth = resolution.get("chain_depth", null)
    var depth_value = _integer_value(raw_depth)
    if depth_value == null:
        return 0
    var depth := int(depth_value)
    if depth <= 0:
        return 0

    var capped_depth := mini(depth, stock_cap)
    return clampi(int(stock_by_chain_depth.get(str(capped_depth), 0)), 0, stock_cap)
