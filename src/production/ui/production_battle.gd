class_name ProductionBattleUI
extends Control

signal ready_requested
signal technique_requested(technique_id: String)

const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"

@onready var current_telegraph_label: Label = $Layout/TopBar/TelegraphPanel/CurrentTelegraph
@onready var next_forecast_label: Label = $Layout/TopBar/TelegraphPanel/NextForecast
@onready var phase_label: Label = $Layout/TopBar/TurnPanel/PhaseLabel
@onready var shared_timer_label: Label = $Layout/TopBar/TurnPanel/SharedTimer
@onready var hp_label: Label = $Layout/ResourceBar/HPLabel
@onready var energy_label: Label = $Layout/ResourceBar/EnergyLabel
@onready var stock_label: Label = $Layout/ResourceBar/StockLabel
@onready var line_board_host: Control = $Layout/MainRow/PuzzlePanel/LineBoardHost
@onready var chain_board_host: Control = $Layout/MainRow/PuzzlePanel/ChainBoardHost
@onready var tempo_label: Label = $Layout/MainRow/ActionPanel/TempoLabel
@onready var skill_grid: GridContainer = $Layout/MainRow/ActionPanel/SkillGrid
@onready var ready_button: Button = $Layout/MainRow/ActionPanel/ReadyButton

var skill_buttons_by_id: Dictionary = {}

func _ready() -> void:
    _bind_skill_grid_from_data()
    ready_button.pressed.connect(_on_ready_pressed)
    apply_presentation({
        "current_telegraph": "대기 중",
        "next_forecast": "미확인",
        "phase": "ENEMY_TELEGRAPH",
        "remaining_seconds": 0.0,
        "player_hp": 100,
        "player_max_hp": 100,
        "energy": 0,
        "stock": 0,
        "ready_available": false,
        "tempo_eligible": false,
        "tempo_potency_bonus_ratio": 0.0,
        "technique_readiness": {},
    })

func apply_presentation(state: Dictionary) -> void:
    current_telegraph_label.text = "CURRENT · %s" % String(state.get("current_telegraph", "미확인"))
    next_forecast_label.text = "NEXT · %s" % String(state.get("next_forecast", "미확인"))

    var phase := String(state.get("phase", "ENEMY_TELEGRAPH")).to_upper()
    phase_label.text = "PHASE · %s" % phase
    shared_timer_label.text = "TURN · %.1fs" % maxf(0.0, float(state.get("remaining_seconds", 0.0)))

    hp_label.text = "HP · %d / %d" % [
        int(state.get("player_hp", 0)),
        int(state.get("player_max_hp", 0)),
    ]
    energy_label.text = "ENERGY · %d" % int(state.get("energy", 0))
    stock_label.text = "STOCK · %d / %d" % [
        int(state.get("stock", 0)),
        ProductionCombatState.STOCK_CAP,
    ]

    line_board_host.visible = phase == "LINE" or phase == "LINE_SETTLE"
    chain_board_host.visible = phase == "CHAIN" or phase == "CHAIN_SETTLE"

    var ready_available := bool(state.get("ready_available", false))
    ready_button.visible = phase == "LINE" or phase == "CHAIN"
    ready_button.disabled = not ready_available

    var tempo_eligible := bool(state.get("tempo_eligible", false))
    var bonus_ratio := maxf(0.0, float(state.get("tempo_potency_bonus_ratio", 0.0)))
    if tempo_eligible:
        tempo_label.text = "TEMPO · +%d%%" % roundi(bonus_ratio * 100.0)
    else:
        tempo_label.text = "TEMPO · 조건 확인 중"

    _apply_skill_readiness(phase, state.get("technique_readiness", {}))

func _bind_skill_grid_from_data() -> void:
    skill_buttons_by_id.clear()
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var lane_prefixes := {
        "ATTACK": "ATK",
        "DEFENSE": "DEF",
        "SUPPORT": "SUP",
    }
    for technique_value in parsed.get("techniques", []):
        if not technique_value is Dictionary:
            continue
        var technique: Dictionary = technique_value
        var technique_id := String(technique.get("id", ""))
        var lane := String(technique.get("lane", ""))
        var tier := int(technique.get("tier", 0))
        if technique_id == "" or not lane_prefixes.has(lane) or tier < 1 or tier > ProductionCombatState.STOCK_CAP:
            continue

        var node_name := "%s_T%d" % [String(lane_prefixes[lane]), tier]
        var button := skill_grid.get_node_or_null(node_name) as Button
        if button == null:
            continue

        button.set_meta("technique_id", technique_id)
        button.text = "%s T%d\n%s\nS%d / E%d · %s" % [
            String(lane_prefixes[lane]),
            tier,
            String(technique.get("name_ko", technique.get("name_en", technique_id))),
            int(technique.get("stock_cost", tier)),
            int(technique.get("energy_cost", 0)),
            String(technique.get("tactical_tag", "")),
        ]
        button.disabled = true
        button.pressed.connect(_on_technique_pressed.bind(technique_id))
        skill_buttons_by_id[technique_id] = button

func _apply_skill_readiness(phase: String, readiness_value) -> void:
    var readiness: Dictionary = readiness_value if readiness_value is Dictionary else {}
    for technique_id_value in skill_buttons_by_id.keys():
        var technique_id := String(technique_id_value)
        var button: Button = skill_buttons_by_id[technique_id]
        var entry: Dictionary = readiness.get(technique_id, {})
        var ready := phase == "ACTION" and bool(entry.get("ready", false))
        button.disabled = not ready
        if phase != "ACTION":
            button.tooltip_text = "ACTION 단계에서 선택"
        elif entry.is_empty():
            button.tooltip_text = "UNAVAILABLE"
        else:
            button.tooltip_text = String(entry.get("reason", "READY"))

func _on_ready_pressed() -> void:
    if ready_button.visible and not ready_button.disabled:
        ready_requested.emit()

func _on_technique_pressed(technique_id: String) -> void:
    var button := skill_buttons_by_id.get(technique_id) as Button
    if button == null or button.disabled:
        return
    technique_requested.emit(technique_id)
