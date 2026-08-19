class_name PocBattle
extends Control

const PocSessionScript := preload("res://src/core/poc_session.gd")
const SkillDefinitionScript := preload("res://src/skills/skill_definition.gd")
const BoardStateScript := preload("res://src/core/board_state.gd")

var session = PocSessionScript.new()
var attack_skill = SkillDefinitionScript.new(&"attack_t1", &"attack", 1, 15, 25)
var defense_skill = SkillDefinitionScript.new(&"defense_t1", &"defense", 1, 15, 30)
var heal_skill = SkillDefinitionScript.new(&"heal_t1", &"heal", 1, 15, 25)

@onready var player_status: Label = $Layout/HUD/PlayerStatus
@onready var enemy_status: Label = $Layout/HUD/EnemyStatus
@onready var next_action_label: Label = $Layout/HUD/NextAction
@onready var resource_status: Label = $Layout/HUD/ResourceStatus
@onready var mode_status: Label = $Layout/ModeStatus
@onready var line_button: Button = $Layout/ModeControls/LineButton
@onready var chain_button: Button = $Layout/ModeControls/ChainButton
@onready var run_lock_button: Button = $Layout/ModeControls/RunLockButton
@onready var debug_1: Button = $Layout/DebugControls/Debug1
@onready var debug_2: Button = $Layout/DebugControls/Debug2
@onready var debug_3: Button = $Layout/DebugControls/Debug3
@onready var debug_4: Button = $Layout/DebugControls/Debug4
@onready var debug_5: Button = $Layout/DebugControls/Debug5
@onready var attack_button: Button = $Layout/SkillControls/AttackButton
@onready var defense_button: Button = $Layout/SkillControls/DefenseButton
@onready var heal_button: Button = $Layout/SkillControls/HealButton
@onready var event_status: Label = $Layout/EventStatus

func _ready() -> void:
    line_button.pressed.connect(_on_line_mode_pressed)
    chain_button.pressed.connect(_on_chain_mode_pressed)
    run_lock_button.pressed.connect(_on_run_lock_pressed)
    debug_1.pressed.connect(_on_debug_1_pressed)
    debug_2.pressed.connect(_on_debug_2_pressed)
    debug_3.pressed.connect(_on_debug_3_pressed)
    debug_4.pressed.connect(_on_debug_4_pressed)
    debug_5.pressed.connect(_on_debug_5_pressed)
    attack_button.pressed.connect(_on_attack_pressed)
    defense_button.pressed.connect(_on_defense_pressed)
    heal_button.pressed.connect(_on_heal_pressed)
    _refresh_ui()

func _process(delta: float) -> void:
    session.tick(delta)
    _refresh_ui()

func _on_line_mode_pressed() -> void:
    if session.modes.active_mode != &"line":
        session.switch_mode(&"line")
    _refresh_ui()

func _on_chain_mode_pressed() -> void:
    if session.modes.active_mode != &"chain":
        session.switch_mode(&"chain")
    _refresh_ui()

func _on_run_lock_pressed() -> void:
    var active_state: int = session.modes.state_for(session.modes.active_mode)
    if active_state == BoardStateScript.RUNNING:
        session.lock_active()
    elif active_state == BoardStateScript.LOCKED:
        session.run_active()
    _refresh_ui()

func _on_debug_1_pressed() -> void:
    _submit_debug_event(1)

func _on_debug_2_pressed() -> void:
    _submit_debug_event(2)

func _on_debug_3_pressed() -> void:
    _submit_debug_event(3)

func _on_debug_4_pressed() -> void:
    _submit_debug_event(4)

func _on_debug_5_pressed() -> void:
    _submit_debug_event(5)

func _on_attack_pressed() -> void:
    session.use_skill(attack_skill)
    _refresh_ui()

func _on_defense_pressed() -> void:
    session.use_skill(defense_skill)
    _refresh_ui()

func _on_heal_pressed() -> void:
    session.use_skill(heal_skill)
    _refresh_ui()

func _submit_debug_event(value: int) -> void:
    if session.modes.active_mode == &"line":
        if value <= 4:
            session.submit_line_clear(value)
    else:
        session.submit_completed_chain(value, value * 4)
    _refresh_ui()

func _refresh_ui() -> void:
    if not is_node_ready():
        return

    player_status.text = "Player  HP %d/%d   Shield %d" % [
        session.combat.player_hp,
        session.combat.player_max_hp,
        session.combat.shield,
    ]
    enemy_status.text = "Enemy   HP %d/%d" % [session.combat.enemy_hp, session.combat.enemy_max_hp]
    resource_status.text = "Energy %d   Chain Stock %d/5   Score %d" % [
        session.combat.energy,
        session.combat.chain_stock,
        session.combat.score,
    ]

    var next_action: Dictionary = session.next_enemy_action()
    if next_action.is_empty():
        next_action_label.text = "Next: none"
    else:
        var remaining: float = maxf(0.0, float(next_action.get("time", 0.0)) - session.combat.combat_time)
        next_action_label.text = "Next: %s %d  in %.1fs" % [
            String(next_action.get("kind", &"")),
            int(next_action.get("magnitude", 0)),
            remaining,
        ]

    var active_state: int = session.modes.state_for(session.modes.active_mode)
    mode_status.text = "Active: %s   State: %s   Combat %.1fs" % [
        String(session.modes.active_mode).to_upper(),
        _state_name(active_state),
        session.combat.combat_time,
    ]
    line_button.text = "LINE [%s] — Energy %d" % [
        _state_name(session.modes.line_state),
        session.combat.energy,
    ]
    chain_button.text = "CHAIN [%s] — Stock %d" % [
        _state_name(session.modes.chain_state),
        session.combat.chain_stock,
    ]
    line_button.disabled = session.modes.active_mode == &"line"
    chain_button.disabled = session.modes.active_mode == &"chain"
    run_lock_button.text = "LOCK" if active_state == BoardStateScript.RUNNING else "RUN"
    run_lock_button.disabled = active_state == BoardStateScript.RESOLVING

    var puzzle_running: bool = active_state == BoardStateScript.RUNNING
    var debug_buttons: Array[Button] = [debug_1, debug_2, debug_3, debug_4, debug_5]
    for button in debug_buttons:
        button.disabled = not puzzle_running
        button.visible = true

    if session.modes.active_mode == &"line":
        debug_1.text = "Single"
        debug_2.text = "Double"
        debug_3.text = "Triple"
        debug_4.text = "4-Line"
        debug_5.visible = false
    else:
        debug_1.text = "1 Chain"
        debug_2.text = "2 Chain"
        debug_3.text = "3 Chain"
        debug_4.text = "4 Chain"
        debug_5.text = "5 Chain"

    var can_t1: bool = session.combat.can_spend_skill(1, 15)
    var skill_window_open: bool = (
        active_state == BoardStateScript.RUNNING
        or active_state == BoardStateScript.LOCKED
    )
    var can_use_t1: bool = can_t1 and skill_window_open
    attack_button.disabled = not can_use_t1
    defense_button.disabled = not can_use_t1
    heal_button.disabled = not can_use_t1

    if session.telemetry.events.is_empty():
        event_status.text = "Event: none"
    else:
        var latest: Dictionary = session.telemetry.events[-1]
        event_status.text = "Event: %s @ %.1fs" % [String(latest.name), float(latest.time)]

func _state_name(state: int) -> String:
    match state:
        BoardStateScript.RUNNING:
            return "RUNNING"
        BoardStateScript.LOCKED:
            return "LOCKED"
        BoardStateScript.SUSPENDED:
            return "SUSPENDED"
        BoardStateScript.RESOLVING:
            return "RESOLVING"
        _:
            return "UNKNOWN"
