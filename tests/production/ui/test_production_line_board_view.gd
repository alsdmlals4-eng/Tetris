## LINE 보드 뷰가 게임 규칙을 복제하지 않고 현재 Hold·Next·클리어 상태를 표시하는지 검증한다.
extends GutTest

const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

func _load_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _make_line_session(seed_value: int = 321) -> ProductionLineSession:
	var catalog := TetrominoCatalog.from_dictionary(_load_json(TETROMINO_DATA_PATH))
	var cycle := LinePieceCycle.new(seed_value, catalog, LineBoard.new(10, 20, 4))
	cycle.start()
	var feel := LineFeelConfig.from_dictionary(_load_json(FEEL_DATA_PATH))
	var rewards := LineRewardConfig.from_dictionary(_load_json(REWARD_DATA_PATH))
	return ProductionLineSession.new(cycle, LineFallState.new(feel), rewards)

func test_meta_snapshot_uses_exact_hold_and_next_five_from_cycle() -> void:
	var view := ProductionLineBoardView.new()
	add_child_autofree(view)
	var session := _make_line_session()
	assert_true(session.try_hold())
	var expected: Array = session.piece_cycle.peek_next(LinePieceCycle.PREVIEW_MIN)
	view.bind_line_session(session)
	assert_true(view.has_method("get_meta_snapshot"))
	if not view.has_method("get_meta_snapshot"):
		return

	var meta: Dictionary = view.call("get_meta_snapshot")
	assert_eq(meta["hold_piece_id"], session.piece_cycle.held_piece_id)
	assert_false(meta["hold_available"])
	assert_eq(meta["next_preview"], expected)

func test_last_clear_label_reports_existing_advanced_fields_without_reward_change() -> void:
	var result := LineClearResult.new(true, "T", 1, "SINGLE", 10, 100)
	result.spin_kind = "T_SPIN"
	result.combo_index = 2
	result.back_to_back = true
	result.perfect_clear = true

	var view := ProductionLineBoardView.new()
	add_child_autofree(view)
	assert_true(view.has_method("format_last_clear"))
	if not view.has_method("format_last_clear"):
		return
	assert_eq(view.call("format_last_clear", result), "PERFECT CLEAR · T-SPIN SINGLE · B2B · COMBO ×3")
	assert_eq(result.energy_delta, 10)
	assert_eq(result.score_delta, 100)

func test_meta_snapshot_is_safe_before_session_binding() -> void:
	var view := ProductionLineBoardView.new()
	add_child_autofree(view)
	var meta := view.get_meta_snapshot()
	assert_eq(meta["next_preview"], [])
	assert_eq(meta["last_clear"], "")

func test_control_guide_lists_all_supported_line_inputs() -> void:
	assert_eq(ProductionLineBoardView.CONTROL_GUIDE, ["← / A", "→ / D", "↓ / S", "↑ / X", "Z", "C HOLD", "SPACE DROP"])

func test_line_board_resolves_every_tetromino_to_a_locked_ornamental_tile_texture() -> void:
	var view := ProductionLineBoardView.new()
	add_child_autofree(view)
	var expected_texture_paths := {
		"I": "res://assets/production/tiles/chain_tile_cyan_v1.png",
		"J": "res://assets/production/tiles/chain_tile_blue_v1.png",
		"L": "res://assets/production/tiles/chain_tile_yellow_v1.png",
		"O": "res://assets/production/tiles/chain_tile_yellow_v1.png",
		"S": "res://assets/production/tiles/chain_tile_green_v1.png",
		"T": "res://assets/production/tiles/chain_tile_purple_v1.png",
		"Z": "res://assets/production/tiles/chain_tile_red_v1.png",
	}
	assert_true(view.has_method("get_piece_texture"), "LINE blocks must resolve their existing tetromino ids to the locked ornamental tile family")
	if not view.has_method("get_piece_texture"):
		return
	for piece_id: String in expected_texture_paths:
		var texture = view.call("get_piece_texture", piece_id) as Texture2D
		assert_not_null(texture, "%s needs a non-flat runtime tile texture" % piece_id)
		if texture != null:
			assert_eq(texture.resource_path, expected_texture_paths[piece_id])
