class_name PocSession
extends RefCounted

const CombatStateScript := preload("res://src/core/combat_state.gd")
const ModeControllerScript := preload("res://src/core/mode_controller.gd")
const DebugLineSourceScript := preload("res://src/puzzle/debug_line_source.gd")
const DebugChainSourceScript := preload("res://src/puzzle/debug_chain_source.gd")
const SkillExecutorScript := preload("res://src/skills/skill_executor.gd")
const EnemyPatternScript := preload("res://src/enemies/enemy_pattern.gd")
const TelemetryLogScript := preload("res://src/core/telemetry_log.gd")
const BoardStateScript := preload("res://src/core/board_state.gd")

var combat
var modes
var line_source
var chain_source
var enemy_pattern
var telemetry

var _player_defeated_logged := false
var _enemy_defeated_logged := false

func _init() -> void:
    combat = CombatStateScript.new()
    modes = ModeControllerScript.new()
    line_source = DebugLineSourceScript.new()
    chain_source = DebugChainSourceScript.new()
    enemy_pattern = EnemyPatternScript.new()
    telemetry = TelemetryLogScript.new()
    _sync_source_states()

func tick(delta: float) -> void:
    if delta <= 0.0:
        return
    combat.tick(delta)
    _sync_source_states()
    line_source.advance(delta)
    chain_source.advance(delta)
    var enemy_events: Array = enemy_pattern.process_due(combat)
    for event in enemy_events:
        telemetry.record(&"enemy_action", combat.combat_time, event)
    _record_terminal_states()

func switch_mode(target_mode: StringName) -> bool:
    var accepted := modes.request_switch(target_mode)
    _sync_source_states()
    if accepted:
        telemetry.record(&"mode_switch", combat.combat_time, {
            "target": target_mode,
            "active": modes.active_mode,
            "queued": modes.queued_mode,
        })
    return accepted

func run_active() -> bool:
    var accepted := modes.set_running()
    _sync_source_states()
    if accepted:
        telemetry.record(&"run", combat.combat_time, {"mode": modes.active_mode})
    return accepted

func lock_active() -> bool:
    var accepted := modes.set_locked()
    _sync_source_states()
    if accepted:
        telemetry.record(&"lock", combat.combat_time, {"mode": modes.active_mode})
    return accepted

func begin_active_resolution() -> bool:
    var accepted := modes.begin_resolution()
    _sync_source_states()
    return accepted

func finish_active_resolution() -> bool:
    var accepted := modes.finish_resolution()
    _sync_source_states()
    return accepted

func submit_line_clear(lines: int) -> bool:
    if modes.active_mode != &"line" or modes.line_state != BoardStateScript.RUNNING:
        return false
    var event: Dictionary = line_source.emit_clear(lines)
    if int(event.energy) <= 0 and int(event.score) <= 0:
        return false
    combat.gain_energy(int(event.energy))
    combat.add_score(int(event.score))
    telemetry.record(&"line_clear", combat.combat_time, event)
    return true

func submit_completed_chain(chain_count: int, pieces_cleared: int) -> bool:
    if modes.active_mode != &"chain" or modes.chain_state != BoardStateScript.RUNNING:
        return false
    var event: Dictionary = chain_source.emit_completed_chain(chain_count, pieces_cleared)
    if int(event.stock_value) <= 0:
        return false
    combat.set_chain_stock_from_completed_chain(int(event.stock_value))
    telemetry.record(&"chain_complete", combat.combat_time, event)
    return true

func use_skill(skill) -> bool:
    var accepted := SkillExecutorScript.execute(skill, combat)
    var payload := {
        "id": skill.id if skill != null else &"",
        "role": skill.role if skill != null else &"",
        "tier": skill.tier if skill != null else 0,
    }
    telemetry.record(&"skill_use" if accepted else &"skill_rejected", combat.combat_time, payload)
    _record_terminal_states()
    return accepted

func next_enemy_action() -> Dictionary:
    return enemy_pattern.next_action()

func _sync_source_states() -> void:
    line_source.state = modes.line_state
    chain_source.state = modes.chain_state

func _record_terminal_states() -> void:
    if combat.player_hp <= 0 and not _player_defeated_logged:
        _player_defeated_logged = true
        telemetry.record(&"player_defeated", combat.combat_time)
    if combat.enemy_hp <= 0 and not _enemy_defeated_logged:
        _enemy_defeated_logged = true
        telemetry.record(&"enemy_defeated", combat.combat_time)
