class_name ProductionBattleBootstrap
extends Node

const ENEMY_ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const ENEMY_SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

const LINE_CLEAR_KINDS := ["NONE", "SINGLE", "DOUBLE", "TRIPLE", "FOUR"]

# Deterministic engineering seed for the first standalone Production scene.
# This is replay/bootstrap identity, not a balance or Human-evidence claim.
const DEFAULT_LINE_SEED := 12345

var bootstrap_state: String = "NOT_RUN"
var failure_reason: String = ""
var line_seed: int = DEFAULT_LINE_SEED

func _ready() -> void:
    call_deferred("_bootstrap_runtime")

func _bootstrap_runtime() -> void:
    if bootstrap_state != "NOT_RUN":
        return
    bootstrap_state = "BOOTSTRAPPING"

    var bridge = get_parent().get_node_or_null("RuntimeBridge")
    if bridge == null or not bridge.has_method("bind_coordinator"):
        _fail("MISSING_RUNTIME_BRIDGE")
        return

    var action_catalog = GatebreakerActionCatalog.from_dictionary(_json(ENEMY_ACTION_DATA_PATH))
    if action_catalog == null:
        _fail("INVALID_ENEMY_ACTION_DATA")
        return

    var director = GatebreakerEncounterDirector.from_dictionary(
        _json(ENEMY_SEQUENCE_DATA_PATH),
        action_catalog
    )
    if director == null:
        _fail("INVALID_ENCOUNTER_SEQUENCE_DATA")
        return

    var telegraphs: Dictionary = director.bootstrap()
    if telegraphs.is_empty():
        _fail("ENCOUNTER_BOOTSTRAP_FAILED")
        return

    var skill_catalog = ProductionSkillCatalog.from_dictionary(_json(SKILL_DATA_PATH))
    if skill_catalog == null:
        _fail("INVALID_SKILL_DATA")
        return

    var turn := TurnController.new(TurnBudget.new())
    var player := ProductionCombatState.new()
    var enemy := ProductionCombatState.new()
    var battle := ProductionBattleSession.new(
        turn,
        player,
        enemy,
        skill_catalog,
        GatebreakerTelegraphState.new(telegraphs["current"], telegraphs["next"]),
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )
    if not battle.attach_encounter_director(director):
        _fail("ENCOUNTER_DIRECTOR_ATTACH_FAILED")
        return

    var line = _make_line(turn)
    if line == null:
        _fail("LINE_SESSION_BOOTSTRAP_FAILED")
        return

    var time_data := _json(TIME_DATA_PATH)
    if not _time_data_is_bootstrap_ready(time_data):
        _fail("INVALID_TIME_DATA")
        return
    var time_config := TurnTimeConfig.from_dictionary(time_data)
    var turn_start: Dictionary = battle.start_next_player_turn(time_config, "NORMAL")
    if not bool(turn_start.get("started", false)):
        _fail("TURN_START_FAILED:%s" % String(turn_start.get("reason", "UNKNOWN")))
        return
    if not line.can_accept_input():
        _fail("LINE_INPUT_NOT_READY")
        return

    # Chain is intentionally not constructed here. The branch has Chain runtime
    # mechanics, but no Production-owned Chain Stock reward policy/seed yet.
    var coordinator := ProductionBattleCoordinator.new(
        battle,
        line,
        null,
        ProductionBattlePresenter.new()
    )
    if not bridge.bind_coordinator(coordinator):
        _fail("RUNTIME_BRIDGE_BIND_FAILED")
        return

    failure_reason = ""
    bootstrap_state = "READY"

func _make_line(turn: TurnController):
    var tetromino_data := _json(TETROMINO_DATA_PATH)
    if not _tetromino_data_is_bootstrap_ready(tetromino_data):
        return null
    var catalog := TetrominoCatalog.from_dictionary(tetromino_data)
    if catalog == null:
        return null

    var feel_data := _json(FEEL_DATA_PATH)
    if not _feel_data_is_bootstrap_ready(feel_data):
        return null
    var feel := LineFeelConfig.from_dictionary(feel_data)
    if feel == null:
        return null

    var reward_data := _json(REWARD_DATA_PATH)
    if not _reward_data_is_bootstrap_ready(reward_data):
        return null
    var reward := LineRewardConfig.from_dictionary(reward_data)
    if reward == null:
        return null

    var board := LineBoard.new()
    var cycle := LinePieceCycle.new(line_seed, catalog, board)
    cycle.start()
    if cycle.active_piece == null or cycle.is_active_spawn_blocked():
        return null

    return ProductionLineSession.new(
        turn,
        cycle,
        LineFallState.new(feel),
        reward
    )

func _time_data_is_bootstrap_ready(data: Dictionary) -> bool:
    if not data.has("balance_status") or String(data["balance_status"]) == "":
        return false
    if not data.has("shared_turn_budget") or typeof(data["shared_turn_budget"]) != TYPE_DICTIONARY:
        return false
    if not data.has("difficulty_profiles") or typeof(data["difficulty_profiles"]) != TYPE_DICTIONARY:
        return false
    if not data.has("tempo_reward") or typeof(data["tempo_reward"]) != TYPE_DICTIONARY:
        return false

    var shared: Dictionary = data["shared_turn_budget"]
    for key in ["min_budget_seconds", "max_budget_seconds", "tempo_reference_seconds"]:
        if not shared.has(key) or not _is_number(shared[key]):
            return false

    var min_budget := float(shared["min_budget_seconds"])
    var max_budget := float(shared["max_budget_seconds"])
    var tempo_reference := float(shared["tempo_reference_seconds"])
    if min_budget <= 0.0 or max_budget < min_budget or tempo_reference <= 0.0:
        return false

    var profiles: Dictionary = data["difficulty_profiles"]
    if not profiles.has("NORMAL") or typeof(profiles["NORMAL"]) != TYPE_DICTIONARY:
        return false
    var normal_profile: Dictionary = profiles["NORMAL"]
    if not normal_profile.has("base_budget_seconds") or not _is_number(normal_profile["base_budget_seconds"]):
        return false
    if float(normal_profile["base_budget_seconds"]) <= 0.0:
        return false

    var tempo_reward: Dictionary = data["tempo_reward"]
    for key in ["potency_per_saved_ratio", "potency_bonus_cap_ratio"]:
        if not tempo_reward.has(key) or not _is_number(tempo_reward[key]):
            return false
        if float(tempo_reward[key]) < 0.0:
            return false
    return true

func _tetromino_data_is_bootstrap_ready(data: Dictionary) -> bool:
    if data.is_empty():
        return false
    if not data.has("pieces") or typeof(data["pieces"]) != TYPE_DICTIONARY:
        return false
    if not data.has("kick_profiles") or typeof(data["kick_profiles"]) != TYPE_DICTIONARY:
        return false
    if not data.has("spawn_origin") or typeof(data["spawn_origin"]) != TYPE_ARRAY:
        return false

    var spawn_origin: Array = data["spawn_origin"]
    if spawn_origin.size() < 2:
        return false

    var pieces: Dictionary = data["pieces"]
    var kick_profiles: Dictionary = data["kick_profiles"]
    if pieces.size() != SevenBag.PIECE_IDS.size():
        return false

    for piece_id in SevenBag.PIECE_IDS:
        if not pieces.has(piece_id) or typeof(pieces[piece_id]) != TYPE_DICTIONARY:
            return false
        var piece: Dictionary = pieces[piece_id]
        var kick_profile := String(piece.get("kick_profile", ""))
        if kick_profile == "" or not kick_profiles.has(kick_profile):
            return false
        if typeof(kick_profiles[kick_profile]) != TYPE_DICTIONARY:
            return false
        if not piece.has("rotations") or typeof(piece["rotations"]) != TYPE_ARRAY:
            return false
        var rotations: Array = piece["rotations"]
        if rotations.size() != 4:
            return false
        for rotation_value in rotations:
            if typeof(rotation_value) != TYPE_ARRAY:
                return false
            var rotation: Array = rotation_value
            if rotation.size() != 4:
                return false
            for cell_value in rotation:
                if typeof(cell_value) != TYPE_ARRAY or cell_value.size() < 2:
                    return false
    return true

func _feel_data_is_bootstrap_ready(data: Dictionary) -> bool:
    var numeric_keys := [
        "gravity_seconds_per_cell",
        "soft_drop_multiplier",
        "lock_delay_seconds",
        "max_lock_resets",
        "das_seconds",
        "arr_seconds",
    ]
    if not data.has("balance_status") or String(data["balance_status"]) == "":
        return false
    for key in numeric_keys:
        if not data.has(key) or not _is_number(data[key]):
            return false

    return (
        float(data["gravity_seconds_per_cell"]) > 0.0
        and float(data["soft_drop_multiplier"]) >= 1.0
        and float(data["lock_delay_seconds"]) >= 0.0
        and int(data["max_lock_resets"]) >= 0
        and float(data["das_seconds"]) >= 0.0
        and float(data["arr_seconds"]) >= 0.0
    )

func _reward_data_is_bootstrap_ready(data: Dictionary) -> bool:
    if not data.has("balance_status") or String(data["balance_status"]) == "":
        return false
    if not data.has("seed_source") or String(data["seed_source"]) == "":
        return false
    if not data.has("energy_by_clear_kind") or typeof(data["energy_by_clear_kind"]) != TYPE_DICTIONARY:
        return false
    if not data.has("score_by_clear_kind") or typeof(data["score_by_clear_kind"]) != TYPE_DICTIONARY:
        return false

    var energy_by_kind: Dictionary = data["energy_by_clear_kind"]
    var score_by_kind: Dictionary = data["score_by_clear_kind"]
    for clear_kind in LINE_CLEAR_KINDS:
        if not energy_by_kind.has(clear_kind) or not _is_number(energy_by_kind[clear_kind]):
            return false
        if not score_by_kind.has(clear_kind) or not _is_number(score_by_kind[clear_kind]):
            return false
        if float(energy_by_kind[clear_kind]) < 0.0 or float(score_by_kind[clear_kind]) < 0.0:
            return false
    return true

func _is_number(value) -> bool:
    return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

func _fail(reason: String) -> void:
    failure_reason = reason
    bootstrap_state = "FAILED"
