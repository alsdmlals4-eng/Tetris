class_name PocBattle
extends Control

const PocSessionScript := preload("res://src/core/poc_session.gd")
const SkillDefinitionScript := preload("res://src/skills/skill_definition.gd")
const BoardStateScript := preload("res://src/core/board_state.gd")
const ManualValidationTrackerScript := preload("res://src/validation/manual_validation_tracker.gd")

var session = PocSessionScript.new()
var attack_skill = SkillDefinitionScript.new(&"attack_t1", &"attack", 1, 15, 25)
var defense_skill = SkillDefinitionScript.new(&"defense_t1", &"defense", 1, 15, 30)
var heal_skill = SkillDefinitionScript.new(&"heal_t1", &"heal", 1, 15, 25)
var rejected_t5_skill = SkillDefinitionScript.new(&"validation_attack_t5", &"attack", 5, 85, 150)

var manual_validation = ManualValidationTrackerScript.new()
var manual_validation_enabled: bool = OS.get_environment("POC_MANUAL_VALIDATION") == "1"
var manual_validation_report_path: String = OS.get_environment("POC_VALIDATION_REPORT_PATH")
var manual_validation_gut_version: String = OS.get_environment("POC_VALIDATION_GUT_VERSION")
var manual_validation_commit: String = OS.get_environment("POC_VALIDATION_COMMIT")
var _manual_line_snapshot: int = -1
var _manual_last_telemetry_count: int = 0
var _manual_report_written := false
var _manual_report_failed := false

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
@onready var manual_validation_status: Label = $Layout/ManualValidationStatus
@onready var rejected_skill_button: Button = $Layout/ManualValidationControls/RejectedSkillButton
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
    rejected_skill_button.pressed.connect(_on_validation_rejected_skill_pressed)
    manual_validation_status.visible = manual_validation_enabled
    rejected_skill_button.visible = manual_validation_enabled
    _manual_last_telemetry_count = session.telemetry.events.size()
    _refresh_ui()

func _process(delta: float) -> void:
    session.tick(delta)
    if manual_validation_enabled:
        manual_validation.update_elapsed(session.combat.combat_time)
        _observe_manual_enemy_actions()
        _try_write_manual_validation_report()
    _refresh_ui()

func _on_line_mode_pressed() -> void:
    var previous_mode: StringName = session.modes.active_mode
    var accepted := false
    if previous_mode != &"line":
        accepted = session.switch_mode(&"line")
    if manual_validation_enabled and accepted and previous_mode == &"chain" and manual_validation.enemy_during_lock:
        manual_validation.record_line_return_preserved(
            session.combat.combat_time,
            _manual_line_snapshot,
            session.line_source.advance_count
        )
    _refresh_ui()

func _on_chain_mode_pressed() -> void:
    var previous_mode: StringName = session.modes.active_mode
    var accepted := false
    if previous_mode != &"chain":
        accepted = session.switch_mode(&"chain")
    if manual_validation_enabled and accepted and previous_mode == &"line" and session.modes.chain_state == BoardStateScript.LOCKED:
        manual_validation.record_chain_switch_locked(
            session.combat.combat_time,
            session.line_source.advance_count
        )
    _refresh_ui()

func _on_run_lock_pressed() -> void:
    var active_mode: StringName = session.modes.active_mode
    var active_state: int = session.modes.state_for(active_mode)
    var accepted := false
    if active_state == BoardStateScript.RUNNING:
        accepted = session.lock_active()
        if manual_validation_enabled and accepted and active_mode == &"line" and not manual_validation.line_lock:
            _manual_line_snapshot = session.line_source.advance_count
            manual_validation.record_line_lock(
                session.combat.combat_time,
                _manual_line_snapshot
            )
    elif active_state == BoardStateScript.LOCKED:
        accepted = session.run_active()
        if manual_validation_enabled and accepted:
            if active_mode == &"line" and not manual_validation.line_run:
                manual_validation.record_line_run(session.combat.combat_time)
            elif active_mode == &"chain":
                manual_validation.record_chain_run(session.combat.combat_time)
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
    _use_skill(attack_skill)

func _on_defense_pressed() -> void:
    _use_skill(defense_skill)

func _on_heal_pressed() -> void:
    _use_skill(heal_skill)

func _on_validation_rejected_skill_pressed() -> void:
    var accepted: bool = session.use_skill(rejected_t5_skill)
    if manual_validation_enabled and not accepted:
        manual_validation.record_skill_rejected(session.combat.combat_time)
    _refresh_ui()

func _use_skill(skill) -> void:
    var accepted: bool = session.use_skill(skill)
    if manual_validation_enabled and accepted:
        manual_validation.record_skill_success(session.combat.combat_time)
    _refresh_ui()

func _submit_debug_event(value: int) -> void:
    if session.modes.active_mode == &"line":
        if value <= 4:
            var energy_before: int = session.combat.energy
            var accepted: bool = session.submit_line_clear(value)
            if manual_validation_enabled and accepted:
                manual_validation.record_line_energy(
                    session.combat.combat_time,
                    session.combat.energy - energy_before
                )
    else:
        var accepted: bool = session.submit_completed_chain(value, value * 4)
        if manual_validation_enabled and accepted:
            manual_validation.record_chain_complete(session.combat.combat_time, value)
    _refresh_ui()

func _observe_manual_enemy_actions() -> void:
    var events: Array = session.telemetry.events
    for index in range(_manual_last_telemetry_count, events.size()):
        var event: Dictionary = events[index]
        if event.get("name", &"") != &"enemy_action":
            continue
        var active_state: int = session.modes.state_for(session.modes.active_mode)
        if active_state == BoardStateScript.LOCKED:
            manual_validation.record_enemy_during_lock(float(event.get("time", session.combat.combat_time)))
    _manual_last_telemetry_count = events.size()

func _try_write_manual_validation_report() -> void:
    if _manual_report_written or not manual_validation.is_complete():
        return
    if manual_validation_report_path.is_empty() or manual_validation_gut_version.is_empty() or manual_validation_commit.is_empty():
        _manual_report_failed = true
        return
    var version_info: Dictionary = Engine.get_version_info()
    var godot_version := String(version_info.get("string", ""))
    _manual_report_written = manual_validation.write_report(
        manual_validation_report_path,
        godot_version,
        manual_validation_gut_version,
        manual_validation_commit
    )
    _manual_report_failed = not _manual_report_written

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
    var skill_state_allowed: bool = active_state == BoardStateScript.RUNNING or active_state == BoardStateScript.LOCKED
    var skill_enabled: bool = can_t1 and skill_state_allowed
    attack_button.disabled = not skill_enabled
    defense_button.disabled = not skill_enabled
    heal_button.disabled = not skill_enabled

    manual_validation_status.visible = manual_validation_enabled
    rejected_skill_button.visible = manual_validation_enabled
    if manual_validation_enabled:
        _refresh_manual_validation_status()

    if session.telemetry.events.is_empty():
        event_status.text = "Event: none"
    else:
        var latest: Dictionary = session.telemetry.events[-1]
        event_status.text = "Event: %s @ %.1fs" % [String(latest.name), float(latest.time)]

func _refresh_manual_validation_status() -> void:
    var verdict := "PASS" if manual_validation.is_complete() else "NOT_COMPLETE"
    var evidence_state := ""
    if _manual_report_written:
        evidence_state = " | EVIDENCE SAVED"
    elif manual_validation.is_complete() and _manual_report_failed:
        evidence_state = " | EVIDENCE NOT SAVED"
    manual_validation_status.text = "Manual validation: %d/10 | %.1f/45s | %s%s | NEXT: %s" % [
        manual_validation.completed_step_count(),
        manual_validation.elapsed_seconds,
        verdict,
        evidence_state,
        _manual_next_instruction(),
    ]

func _manual_next_instruction() -> String:
    if not manual_validation.line_run:
        return "RUN Line"
    if not manual_validation.line_energy:
        return "Create a Line clear"
    if not manual_validation.line_lock:
        return "LOCK Line"
    if not manual_validation.chain_switch_locked:
        return "Switch to Chain"
    if not manual_validation.chain_run:
        return "RUN Chain"
    if not manual_validation.chain_complete:
        return "Complete a Chain"
    if not manual_validation.skill_success:
        return "Use an available T1 Skill"
    if not manual_validation.skill_rejected:
        return "Attempt unavailable T5"
    if not manual_validation.enemy_during_lock:
        return "LOCK and wait for enemy action"
    if not manual_validation.line_return_preserved:
        return "Switch back to Line"
    if manual_validation.elapsed_seconds < 45.0:
        return "Keep the encounter open until 45s"
    if _manual_report_written:
        return "Close window; evidence is complete"
    return "Evidence file was not saved"

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
