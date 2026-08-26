extends GutTest

const CONFIG_SCRIPT_PATH := "res://src/production/chain/production_chain_config.gd"
const CONFIG_DATA_PATH := "res://data/production/chain_runtime_seed.json"

func _config():
    assert_true(FileAccess.file_exists(CONFIG_DATA_PATH), "Production Chain runtime seed data must exist")
    var raw: String = FileAccess.get_file_as_string(CONFIG_DATA_PATH) if FileAccess.file_exists(CONFIG_DATA_PATH) else ""
    var parsed = JSON.parse_string(raw)
    assert_true(parsed is Dictionary, "Production Chain runtime seed must parse as a dictionary")

    var script = load(CONFIG_SCRIPT_PATH)
    assert_not_null(script, "ProductionChainConfig must exist")
    if script == null or not parsed is Dictionary:
        return null
    return script.from_dictionary(parsed)

func test_runtime_seed_is_explicitly_non_final_and_traceable() -> void:
    var config = _config()
    if config == null:
        return

    assert_eq(config.balance_status, "TUNING_SEED_NOT_FINAL")
    assert_eq(config.seed_source, "HISTORICAL_FOUNDATION_CHAIN_DEPTH_MAPPING_ADAPTED_TO_PRODUCTION_CAP_6")
    assert_eq(config.board_width, 8)
    assert_eq(config.board_height, 8)
    assert_eq(config.palette.size(), 6)
    assert_eq(config.random_seed, 54321)

func test_stock_reward_uses_data_driven_chain_depth_seed_and_production_cap_six() -> void:
    var config = _config()
    if config == null:
        return

    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 0}), 0)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 1}), 1)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 2}), 2)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 5}), 5)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 6}), 6)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": 99}), 6)

func test_failed_or_invalid_resolution_never_mints_stock() -> void:
    var config = _config()
    if config == null:
        return

    assert_eq(config.stock_for_resolution({"success": false, "chain_depth": 3}), 0)
    assert_eq(config.stock_for_resolution({"chain_depth": 3}), 0)
    assert_eq(config.stock_for_resolution({"success": true, "chain_depth": -1}), 0)

func test_invalid_seed_shape_fails_closed() -> void:
    var script = load(CONFIG_SCRIPT_PATH)
    assert_not_null(script)
    if script == null:
        return

    assert_null(script.from_dictionary({}))
    assert_null(script.from_dictionary({
        "balance_status": "TUNING_SEED_NOT_FINAL",
        "seed_source": "TEST",
        "board": {"width": 2, "height": 2, "palette": ["A", "B"], "random_seed": 1},
        "stock_by_chain_depth": {"1": 1},
    }))
