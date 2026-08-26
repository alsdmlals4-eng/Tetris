class_name LineRewardConfig
extends RefCounted

var balance_status: String = ""
var seed_source: String = ""
var _energy_by_kind: Dictionary = {}
var _score_by_kind: Dictionary = {}

static func from_dictionary(data: Dictionary) -> LineRewardConfig:
    var config := LineRewardConfig.new()
    config.balance_status = String(data.get("balance_status", ""))
    config.seed_source = String(data.get("seed_source", ""))
    config._energy_by_kind = data.get("energy_by_clear_kind", {}).duplicate(true)
    config._score_by_kind = data.get("score_by_clear_kind", {}).duplicate(true)
    return config

func energy_for_kind(clear_kind: String) -> int:
    return int(_energy_by_kind.get(clear_kind, 0))

func score_for_kind(clear_kind: String) -> int:
    return int(_score_by_kind.get(clear_kind, 0))

func make_result(piece_id: String, lines_cleared: int) -> LineClearResult:
    var clear_kind := LineClearResult.classify(lines_cleared)
    if clear_kind == "INVALID":
        return LineClearResult.failed(piece_id)
    return LineClearResult.new(
        true,
        piece_id,
        lines_cleared,
        clear_kind,
        energy_for_kind(clear_kind),
        score_for_kind(clear_kind)
    )
