class_name LineFeelConfig
extends RefCounted

var balance_status: String = ""
var gravity_seconds_per_cell: float = 0.0
var soft_drop_multiplier: float = 1.0
var lock_delay_seconds: float = 0.0
var max_lock_resets: int = 0
var das_seconds: float = 0.0
var arr_seconds: float = 0.0

static func from_dictionary(data: Dictionary) -> LineFeelConfig:
    var config := LineFeelConfig.new()
    config.balance_status = String(data.get("balance_status", ""))
    config.gravity_seconds_per_cell = float(data.get("gravity_seconds_per_cell", 0.0))
    config.soft_drop_multiplier = maxf(float(data.get("soft_drop_multiplier", 1.0)), 1.0)
    config.lock_delay_seconds = float(data.get("lock_delay_seconds", 0.0))
    config.max_lock_resets = maxi(int(data.get("max_lock_resets", 0)), 0)
    config.das_seconds = maxf(float(data.get("das_seconds", 0.0)), 0.0)
    config.arr_seconds = maxf(float(data.get("arr_seconds", 0.0)), 0.0)
    return config
