class_name ManualValidationTracker
extends RefCounted

const REQUIRED_STEP_COUNT := 10
const REQUIRED_SECONDS := 45.0

var line_run := false
var line_energy := false
var line_lock := false
var chain_switch_locked := false
var chain_run := false
var chain_complete := false
var skill_success := false
var skill_rejected := false
var enemy_during_lock := false
var line_return_preserved := false
var elapsed_seconds := 0.0

var _step_times: Dictionary = {}

func record_line_run(time: float) -> void:
    line_run = true
    _step_times["line_run"] = time

func record_line_energy(time: float, amount: int) -> void:
    if amount <= 0:
        return
    line_energy = true
    _step_times["line_energy"] = time

func record_line_lock(time: float, _line_advance_count: int) -> void:
    line_lock = true
    _step_times["line_lock"] = time

func record_chain_switch_locked(time: float, _line_advance_count: int) -> void:
    chain_switch_locked = true
    _step_times["chain_switch_locked"] = time

func record_chain_run(time: float) -> void:
    chain_run = true
    _step_times["chain_run"] = time

func record_chain_complete(time: float, chain_count: int) -> void:
    if chain_count <= 0:
        return
    chain_complete = true
    _step_times["chain_complete"] = time

func record_skill_success(time: float) -> void:
    skill_success = true
    _step_times["skill_success"] = time

func record_skill_rejected(time: float) -> void:
    skill_rejected = true
    _step_times["skill_rejected"] = time

func record_enemy_during_lock(time: float) -> void:
    enemy_during_lock = true
    _step_times["enemy_during_lock"] = time

func record_line_return_preserved(time: float, before_advance_count: int, after_advance_count: int) -> void:
    line_return_preserved = before_advance_count == after_advance_count
    if line_return_preserved:
        _step_times["line_return_preserved"] = time

func update_elapsed(time: float) -> void:
    elapsed_seconds = maxf(elapsed_seconds, time)

func completed_step_count() -> int:
    var count := 0
    count += 1 if line_run else 0
    count += 1 if line_energy else 0
    count += 1 if line_lock else 0
    count += 1 if chain_switch_locked else 0
    count += 1 if chain_run else 0
    count += 1 if chain_complete else 0
    count += 1 if skill_success else 0
    count += 1 if skill_rejected else 0
    count += 1 if enemy_during_lock else 0
    count += 1 if line_return_preserved else 0
    return count

func is_complete() -> bool:
    return elapsed_seconds >= REQUIRED_SECONDS and completed_step_count() == REQUIRED_STEP_COUNT

func build_report(godot_version: String, gut_version: String, commit: String) -> Dictionary:
    return {
        "verdict": "PASS" if is_complete() else "NOT_COMPLETE",
        "godot_version": godot_version,
        "gut_version": gut_version,
        "commit": commit,
        "elapsed_seconds": elapsed_seconds,
        "completed_steps": completed_step_count(),
        "required_steps": REQUIRED_STEP_COUNT,
        "steps": {
            "line_run": line_run,
            "line_energy": line_energy,
            "line_lock": line_lock,
            "chain_switch_locked": chain_switch_locked,
            "chain_run": chain_run,
            "chain_complete": chain_complete,
            "skill_success": skill_success,
            "skill_rejected": skill_rejected,
            "enemy_during_lock": enemy_during_lock,
            "line_return_preserved": line_return_preserved,
        },
        "step_times": _step_times.duplicate(true),
    }
