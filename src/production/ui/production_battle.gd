class_name ProductionBattleUI
extends Control

signal ready_requested
signal technique_requested(technique_id: String)

const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const LANES := ["ATTACK", "DEFENSE", "SUPPORT"]

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
@onready var attack_lane_button: Button = $Layout/MainRow/ActionPanel/LaneTabs/AttackLaneButton
@onready var defense_lane_button: Button = $Layout/MainRow/ActionPanel/LaneTabs/DefenseLaneButton
@onready var support_lane_button: Button = $Layout/MainRow/ActionPanel/LaneTabs/SupportLaneButton
@onready var skill_list: VBoxContainer = $Layout/MainRow/ActionPanel/SkillList
@onready var skill_detail_panel: Control = $Layout/MainRow/ActionPanel/SkillDetailPanel
@onready var skill_detail_title: Label = $Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailTitle
@onready var skill_detail_meta: Label = $Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailMeta
@onready var skill_detail_effects: Label = $Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailEffects
@onready var skill_detail_readiness: Label = $Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/SkillDetailReadiness
@onready var use_technique_button: Button = $Layout/MainRow/ActionPanel/SkillDetailPanel/DetailContent/UseTechniqueButton
@onready var ready_button: Button = $Layout/MainRow/ActionPanel/ReadyButton

var skill_buttons_by_id: Dictionary = {}
var skill_definitions_by_id: Dictionary = {}
var skill_ids_by_lane: Dictionary = {
    "ATTACK": [],
    "DEFENSE": [],
    "SUPPORT": [],
}
var selected_lane: String = "ATTACK"
var selected_technique_id: String = ""
var current_phase: String = "ENEMY_TELEGRAPH"
var current_readiness: Dictionary = {}

func _ready() -> void:
    _load_skill_data()
    _bind_lane_tabs()
    _bind_skill_rows()
    use_technique_button.pressed.connect(_on_use_technique_pressed)
    ready_button.pressed.connect(_on_ready_pressed)
    _select_lane("ATTACK")
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

    current_phase = String(state.get("phase", "ENEMY_TELEGRAPH")).to_upper()
    phase_label.text = "PHASE · %s" % current_phase
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

    line_board_host.visible = current_phase == "LINE" or current_phase == "LINE_SETTLE"
    chain_board_host.visible = current_phase == "CHAIN" or current_phase == "CHAIN_SETTLE"

    var ready_available := bool(state.get("ready_available", false))
    ready_button.visible = current_phase == "LINE" or current_phase == "CHAIN"
    ready_button.disabled = not ready_available

    var tempo_eligible := bool(state.get("tempo_eligible", false))
    var bonus_ratio := maxf(0.0, float(state.get("tempo_potency_bonus_ratio", 0.0)))
    if tempo_eligible:
        tempo_label.text = "TEMPO · +%d%%" % roundi(bonus_ratio * 100.0)
    else:
        tempo_label.text = "TEMPO · 조건 확인 중"

    var readiness_value = state.get("technique_readiness", {})
    current_readiness = Dictionary(readiness_value).duplicate(true) if readiness_value is Dictionary else {}
    _refresh_skill_rows()
    if selected_technique_id != "":
        _show_technique_detail(selected_technique_id)

func _load_skill_data() -> void:
    skill_definitions_by_id.clear()
    for lane in LANES:
        skill_ids_by_lane[lane] = []

    var parsed = JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH))
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    for technique_value in parsed.get("techniques", []):
        if not technique_value is Dictionary:
            continue
        var technique: Dictionary = technique_value
        var technique_id := String(technique.get("id", ""))
        var lane := String(technique.get("lane", ""))
        var tier := int(technique.get("tier", 0))
        if technique_id == "" or not LANES.has(lane) or tier < 1 or tier > ProductionCombatState.STOCK_CAP:
            continue

        skill_definitions_by_id[technique_id] = technique.duplicate(true)
        var lane_ids: Array = skill_ids_by_lane[lane]
        lane_ids.append(technique_id)
        skill_ids_by_lane[lane] = lane_ids

    for lane in LANES:
        var lane_ids: Array = skill_ids_by_lane[lane]
        lane_ids.sort_custom(func(a, b):
            var a_definition: Dictionary = skill_definitions_by_id.get(String(a), {})
            var b_definition: Dictionary = skill_definitions_by_id.get(String(b), {})
            return int(a_definition.get("tier", 0)) < int(b_definition.get("tier", 0))
        )
        skill_ids_by_lane[lane] = lane_ids

func _bind_lane_tabs() -> void:
    attack_lane_button.pressed.connect(_select_lane.bind("ATTACK"))
    defense_lane_button.pressed.connect(_select_lane.bind("DEFENSE"))
    support_lane_button.pressed.connect(_select_lane.bind("SUPPORT"))

func _bind_skill_rows() -> void:
    for index in range(skill_list.get_child_count()):
        var row := skill_list.get_child(index) as Button
        if row != null:
            row.pressed.connect(_on_skill_row_pressed.bind(index))

func _select_lane(lane: String) -> void:
    if not LANES.has(lane):
        return
    selected_lane = lane
    selected_technique_id = ""
    skill_detail_panel.visible = false
    use_technique_button.disabled = true
    attack_lane_button.button_pressed = lane == "ATTACK"
    defense_lane_button.button_pressed = lane == "DEFENSE"
    support_lane_button.button_pressed = lane == "SUPPORT"
    _render_selected_lane()

func _render_selected_lane() -> void:
    skill_buttons_by_id.clear()
    var lane_ids: Array = skill_ids_by_lane.get(selected_lane, [])
    for index in range(skill_list.get_child_count()):
        var row := skill_list.get_child(index) as Button
        if row == null:
            continue
        if index >= lane_ids.size():
            row.set_meta("technique_id", "")
            row.text = "-"
            row.disabled = true
            row.tooltip_text = ""
            continue

        var technique_id := String(lane_ids[index])
        var definition: Dictionary = skill_definitions_by_id.get(technique_id, {})
        var tier := int(definition.get("tier", index + 1))
        row.set_meta("technique_id", technique_id)
        row.text = "T%d · %s    Stock %d · Energy %d" % [
            tier,
            String(definition.get("name_ko", definition.get("name_en", technique_id))),
            int(definition.get("stock_cost", tier)),
            int(definition.get("energy_cost", 0)),
        ]
        row.disabled = false
        skill_buttons_by_id[technique_id] = row
    _refresh_skill_rows()

func _refresh_skill_rows() -> void:
    for technique_id_value in skill_buttons_by_id.keys():
        var technique_id := String(technique_id_value)
        var row: Button = skill_buttons_by_id[technique_id]
        var entry: Dictionary = current_readiness.get(technique_id, {})
        row.disabled = false
        if current_phase != "ACTION":
            row.tooltip_text = "상세 확인 가능 · ACTION 단계에서 사용"
        elif entry.is_empty():
            row.tooltip_text = "상세 확인 가능 · 현재 사용 불가"
        elif bool(entry.get("ready", false)):
            row.tooltip_text = "상세 확인 · 사용 가능"
        else:
            row.tooltip_text = "상세 확인 · %s" % _readiness_text(entry)

func _on_skill_row_pressed(index: int) -> void:
    if index < 0 or index >= skill_list.get_child_count():
        return
    var row := skill_list.get_child(index) as Button
    if row == null:
        return
    var technique_id := String(row.get_meta("technique_id", ""))
    if technique_id == "" or not skill_definitions_by_id.has(technique_id):
        return
    _show_technique_detail(technique_id)

func _show_technique_detail(technique_id: String) -> void:
    if not skill_definitions_by_id.has(technique_id):
        return
    selected_technique_id = technique_id
    var definition: Dictionary = skill_definitions_by_id[technique_id]
    var tier := int(definition.get("tier", 0))
    skill_detail_panel.visible = true
    skill_detail_title.text = "%s" % String(definition.get("name_ko", definition.get("name_en", technique_id)))
    skill_detail_meta.text = "T%d · Stock %d · Energy %d · 대상: %s" % [
        tier,
        int(definition.get("stock_cost", tier)),
        int(definition.get("energy_cost", 0)),
        _target_text(String(definition.get("target", ""))),
    ]
    skill_detail_effects.text = _effects_text(Array(definition.get("effects", [])))
    var entry: Dictionary = current_readiness.get(technique_id, {})
    skill_detail_readiness.text = _readiness_text(entry)
    use_technique_button.disabled = not (
        current_phase == "ACTION"
        and bool(entry.get("ready", false))
    )

func _on_use_technique_pressed() -> void:
    if selected_technique_id == "" or current_phase != "ACTION":
        return
    var entry: Dictionary = current_readiness.get(selected_technique_id, {})
    if not bool(entry.get("ready", false)):
        return
    technique_requested.emit(selected_technique_id)

func _on_ready_pressed() -> void:
    if ready_button.visible and not ready_button.disabled:
        ready_requested.emit()

func _target_text(target: String) -> String:
    match target:
        "SINGLE_ENEMY":
            return "적 1체"
        "ALL_ENEMIES":
            return "모든 적"
        "SELF":
            return "자신"
        "CURRENT_TELEGRAPH":
            return "현재 예고 행동"
        "NEXT_FORECAST":
            return "다음 예고 행동"
        _:
            return "상황 대상"

func _effects_text(effects: Array) -> String:
    if effects.is_empty():
        return "효과 정보 준비 중"
    var lines: Array[String] = []
    for effect_value in effects:
        if not effect_value is Dictionary:
            lines.append("효과 정보 준비 중")
            continue
        var effect: Dictionary = effect_value
        if String(effect.get("status_contract", "")) == "TUNE_REQUIRED":
            lines.append("상세 효과 조정 중")
            continue
        lines.append(_effect_text(effect))
    return "\n".join(lines)

func _effect_text(effect: Dictionary) -> String:
    var op := String(effect.get("op", ""))
    match op:
        "DAMAGE_SINGLE":
            return "단일 적 피해 %d" % int(effect.get("magnitude", 0))
        "DAMAGE_AOE":
            return "모든 적 피해 %d" % int(effect.get("magnitude", 0))
        "MITIGATE_CURRENT_DIRECT":
            return "현재 직접 공격 피해 %d 감소" % int(effect.get("magnitude", 0))
        "COUNTER_FROM_PREVENTED_DAMAGE":
            return "막은 피해의 %d%% 반격" % roundi(float(effect.get("ratio", 0.0)) * 100.0)
        "HEAL_SELF":
            return "HP %d 회복" % int(effect.get("magnitude", 0))
        "APPLY_SELF_BUFF":
            return "%s 강화 상태 적용" % _status_text(String(effect.get("status", "")))
        "APPLY_ENEMY_DEBUFF":
            return "%s 약화 상태 적용" % _status_text(String(effect.get("status", "")))
        "PROTECT_RESOURCE_LOSS":
            return "현재 자원 손실 %d%% 보호" % roundi(float(effect.get("ratio", 0.0)) * 100.0)
        "MODIFY_NEXT_TURN_BUDGET":
            var seconds := float(effect.get("seconds", 0.0))
            return "다음 Turn 시간 %+.0fs" % seconds
        "CONDITIONAL_MULTIPLIER":
            return "조건 충족 시 효과 ×%.1f" % float(effect.get("multiplier", 1.0))
        "LETHAL_SAFETY":
            return "치명 공격을 받아도 HP %d 이상 유지" % int(effect.get("hp_floor", 1))
        "TARGET_PATTERN":
            return "대상 패턴: %s" % _target_text(String(effect.get("pattern", "")))
        _:
            return "효과 정보 준비 중"

func _status_text(status: String) -> String:
    match status:
        "BREACH":
            return "브리치"
        "FORTIFY":
            return "요새화"
        "RALLY":
            return "재정비"
        "WEAKEN":
            return "약화"
        "RIFT_WARD":
            return "균열 방호"
        "RIFT_SEAL":
            return "균열 봉인"
        "BATTLE_TRANCE":
            return "전투 몰입"
        _:
            return "전술"

func _readiness_text(entry: Dictionary) -> String:
    if current_phase != "ACTION":
        return "ACTION 단계에서 사용 가능"
    if bool(entry.get("ready", false)):
        return "사용 가능"
    var reason := String(entry.get("reason", entry.get("state", "UNAVAILABLE")))
    match reason:
        "STOCK_INSUFFICIENT", "STOCK_SHORTAGE":
            return "Stock 부족"
        "ENERGY_INSUFFICIENT", "ENERGY_SHORTAGE":
            return "Energy 부족"
        "UNRESOLVED_EFFECT_CONTRACT", "TUNE_REQUIRED":
            return "효과 조정 중 · 현재 사용 불가"
        "FORECAST_SCOPE_MISMATCH":
            return "현재 예고 대상과 맞지 않음"
        "WRONG_PHASE":
            return "ACTION 단계에서 사용 가능"
        _:
            return "현재 사용 불가"
