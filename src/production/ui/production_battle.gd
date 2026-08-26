## 60/40 전투 화면에서 한 번에 하나의 퍼즐 workspace만 표시한다.
class_name ProductionBattle
extends Control

const LINE := "LINE"
const CHAIN := "CHAIN"

@onready var _line_view: Control = $MainRow/PuzzleColumn/PuzzleHost/LineBoardView
@onready var _chain_view: Control = $MainRow/PuzzleColumn/PuzzleHost/ChainBoardView
@onready var _current_threat: Label = $MainRow/CombatColumn/ThreatPanel/CurrentTelegraph
@onready var _next_forecast: Label = $MainRow/CombatColumn/ThreatPanel/NextForecast
@onready var _resource_bar: Label = $MainRow/CombatColumn/ResourceBar
@onready var _pause_state: Label = $MainRow/CombatColumn/SkillPanel/PauseState

var _runtime = null
var _workspace_manager = null
var _pause_bridge: SimulationPauseBridge = null

func _ready() -> void:
	$MainRow/PuzzleColumn/ModeBar/LineButton.pressed.connect(func(): _request_workspace(LINE))
	$MainRow/PuzzleColumn/ModeBar/ChainButton.pressed.connect(func(): _request_workspace(CHAIN))
	$MainRow/PuzzleColumn/ModeBar/SkillButton.pressed.connect(_toggle_skill)
	var bootstrap = load("res://src/production/session/production_battle_bootstrap.gd").new()
	var result: Dictionary = bootstrap.build_runtime()
	_runtime = result.get("runtime")
	_workspace_manager = result.get("workspace_manager")
	var pause_controller = result.get("pause_controller")
	if pause_controller != null:
		_pause_bridge = SimulationPauseBridge.new()
		add_child(_pause_bridge)
		_pause_bridge.bind_controller(pause_controller)
	set_active_workspace(LINE)
	_refresh_runtime_labels()

func _process(delta: float) -> void:
	if _runtime == null:
		return
	_runtime.tick(delta)
	if _workspace_manager != null:
		set_active_workspace(_workspace_manager.active_workspace())
	_refresh_runtime_labels()

func set_active_workspace(workspace: String) -> bool:
	if workspace != LINE and workspace != CHAIN:
		return false
	_line_view.visible = workspace == LINE
	_chain_view.visible = workspace == CHAIN
	return true

func _request_workspace(workspace: String) -> void:
	if _runtime != null:
		_runtime.process_player_command({"kind": "SWITCH_WORKSPACE", "target": workspace})
	set_active_workspace(workspace)

func _toggle_skill() -> void:
	if _runtime == null:
		return
	if _runtime.is_simulation_paused():
		_runtime.close_skill_without_use()
	else:
		_runtime.open_skill()
	_refresh_runtime_labels()

func _refresh_runtime_labels() -> void:
	if _runtime == null:
		_current_threat.text = "CURRENT THREAT · unavailable"
		return
	var snapshot: Dictionary = _runtime.snapshot()
	_current_threat.text = "CURRENT THREAT · ETA %.1fs" % float(snapshot.get("enemy_eta_seconds", 0.0))
	_next_forecast.text = "NEXT FORECAST · realtime authored schedule"
	_resource_bar.text = "HP %d / 100    ENERGY %d    STOCK %d / 6" % [int(snapshot.get("player_hp", 0)), int(snapshot.get("player_energy", 0)), int(snapshot.get("player_stock", 0))]
	_pause_state.text = "TACTICAL PAUSE" if bool(snapshot.get("paused", false)) else "COMBAT RUNNING"
