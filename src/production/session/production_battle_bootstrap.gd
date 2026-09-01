## CORE-029 continuous combat의 독립 runtime 소유자들을 조립한다.
class_name ProductionBattleBootstrap
extends RefCounted

const TETROMINO_DATA := "res://data/production/line_tetrominoes.json"
const LINE_FEEL_DATA := "res://data/production/line_feel_config.json"
const LINE_REWARD_DATA := "res://data/production/line_reward_seed.json"
const CHAIN_DATA := "res://data/production/chain_runtime_seed.json"
const ACTION_DATA := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA := "res://data/production/gatebreaker_sequence_seed.json"
const TIMING_DATA := "res://data/production/gatebreaker_realtime_timing_seed.json"
const SKILL_DATA := "res://data/production/vanguard_skill_seed.json"

func build_runtime() -> Dictionary:
	var player = load("res://src/production/combat/production_combat_state.gd").new(100)
	var enemy = load("res://src/production/combat/production_combat_state.gd").new(100)
	var line = _make_line()
	var chain = _make_chain()
	var scheduler = _make_scheduler()
	var pause = load("res://src/production/runtime/simulation_pause_controller.gd").new()
	var skill = _make_skill_session(pause, player)
	if line == null or chain == null or scheduler == null or skill == null:
		return {"ready": false, "reason": "INVALID_PRODUCTION_SEED"}
	var workspace = load("res://src/production/runtime/puzzle_workspace_manager.gd").new(line, chain)
	var response = load("res://src/production/combat/production_response_state.gd").new()
	var telemetry = load("res://src/production/telemetry/production_telemetry.gd").new()
	var board_opportunity = load("res://src/production/runtime/player_board_opportunity_state.gd").new()
	var guided_practice = load("res://src/production/session/production_guided_practice_state.gd").new()
	var runtime = load("res://src/production/runtime/production_combat_runtime.gd").new(player, enemy, workspace, scheduler, skill, pause, response, telemetry, board_opportunity, guided_practice)
	var started: Dictionary = runtime.start_battle()
	if not bool(started.get("started", false)):
		return {"ready": false, "reason": started.get("reason", "RUNTIME_START_FAILED")}
	return {"ready": true, "runtime": runtime, "workspace_manager": workspace, "pause_controller": pause, "telemetry": telemetry, "board_opportunity": board_opportunity, "guided_practice": guided_practice, "player": player, "enemy": enemy}

func _make_line():
	var catalog = load("res://src/production/line/tetromino_catalog.gd").from_dictionary(_json(TETROMINO_DATA))
	var feel = load("res://src/production/line/line_feel_config.gd").from_dictionary(_json(LINE_FEEL_DATA))
	var reward = load("res://src/production/line/line_reward_config.gd").from_dictionary(_json(LINE_REWARD_DATA))
	if catalog == null or feel == null or reward == null:
		return null
	var board = load("res://src/production/line/line_board.gd").new(10, 20, 4)
	var cycle = load("res://src/production/line/line_piece_cycle.gd").new(20260826, catalog, board)
	cycle.start()
	return load("res://src/production/line/production_line_session.gd").new(cycle, load("res://src/production/line/line_fall_state.gd").new(feel), reward)

func _make_chain():
	var config = load("res://src/production/chain/production_chain_config.gd").from_dictionary(_json(CHAIN_DATA))
	if config == null:
		return null
	var board = load("res://src/production/chain/chain_board.gd").new(config.board_width, config.board_height)
	var randomizer = load("res://src/production/chain/chain_randomizer.gd").new(config.random_seed, config.palette)
	if not randomizer.fill_playable_board(board):
		return null
	var resolver = load("res://src/production/chain/chain_resolver.gd").new(board, randomizer)
	return load("res://src/production/chain/production_chain_session.gd").new(board, resolver)

func _make_scheduler():
	var catalog = load("res://src/production/combat/gatebreaker_action_catalog.gd").from_dictionary(_json(ACTION_DATA))
	var director = load("res://src/production/combat/gatebreaker_encounter_director.gd").from_dictionary(_json(SEQUENCE_DATA), catalog)
	var timing = load("res://src/production/runtime/gatebreaker_realtime_timing_config.gd").from_dictionary(_json(TIMING_DATA))
	if catalog == null or director == null or timing == null:
		return null
	return load("res://src/production/runtime/enemy_action_scheduler.gd").new(director, timing, load("res://src/production/combat/production_enemy_action_resolver.gd").new())

func _make_skill_session(pause, player):
	var catalog = load("res://src/production/skill/production_skill_catalog.gd").from_dictionary(_json(SKILL_DATA))
	if catalog == null:
		return null
	var executor = load("res://src/production/skill/production_effect_executor.gd").new()
	var resolver = load("res://src/production/skill/production_technique_resolver.gd").new(executor)
	return load("res://src/production/skill/production_skill_session.gd").new(pause, player, catalog, resolver)

func _json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))
