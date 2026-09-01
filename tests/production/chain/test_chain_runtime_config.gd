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
    assert_eq(config.seed_source, "TETRIS_CHAIN_038_WAVE_FORMULA_RUNTIME_SEED")
    assert_eq(config.board_width, 8)
    assert_eq(config.board_height, 8)
    assert_eq(config.palette.size(), 6)
    assert_eq(config.random_seed, 54321)

func test_runtime_config_owns_board_generation_only_not_legacy_depth_rewards() -> void:
    var config = _config()
    if config == null:
        return

    assert_false(config.get_property_list().any(func(property): return String(property.get("name", "")) == "stock_by_chain_depth"))
    assert_false(config.has_method("stock_for_resolution"))

func test_runtime_config_cannot_mint_legacy_depth_rewards() -> void:
    var config = _config()
    if config == null:
        return

    assert_false(config.has_method("stock_for_resolution"))

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
    }))
