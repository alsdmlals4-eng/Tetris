class_name ProductionBattleBootstrap
extends Node

const ENEMY_ACTION_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const ENEMY_SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const TIME_DATA_PATH := "res://data/production/turn_time_config.json"
const TETROMINO_DATA_PATH := "res://data/production/line_tetrominoes.json"
const FEEL_DATA_PATH := "res://data/production/line_feel_config.json"
const REWARD_DATA_PATH := "res://data/production/line_reward_seed.json"

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

    var time_config := TurnTimeConfig.from_dictionary(_json(TIME_DATA_PATH))
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
    var catalog := TetrominoCatalog.from_dictionary(_json(TETROMINO_DATA_PATH))
    if catalog == null:
        return null

    var feel := LineFeelConfig.from_dictionary(_json(FEEL_DATA_PATH))
    if feel == null:
        return null

    var reward := LineRewardConfig.from_dictionary(_json(REWARD_DATA_PATH))
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

func _json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}

func _fail(reason: String) -> void:
    failure_reason = reason
    bootstrap_state = "FAILED"
