class_name TurnController
extends RefCounted

class PendingAction:
    extends RefCounted

    var id: String

    func _init(p_id: String) -> void:
        id = p_id

var phase: int = TurnPhase.ENEMY_TELEGRAPH
var turn_budget: TurnBudget
var chain_input_skipped_for_timeout: bool = false
var pending_player_action: PendingAction = null

var _timeout_pending: bool = false

func _init(p_turn_budget: TurnBudget) -> void:
    turn_budget = p_turn_budget

func start_player_turn(config, profile_id: String, effects: TimeEffectState = null) -> Dictionary:
    if phase != TurnPhase.ENEMY_TELEGRAPH:
        return {
            "started": false,
            "reason": "WRONG_PHASE",
        }
    if config == null:
        return {
            "started": false,
            "reason": "MISSING_TIME_CONFIG",
        }
    if not config.has_difficulty_profile(profile_id):
        return {
            "started": false,
            "reason": "UNKNOWN_DIFFICULTY_PROFILE",
        }

    var flat_modifier_seconds := 0.0
    if effects != null:
        flat_modifier_seconds = effects.get_total_flat_seconds_for_next_turn()

    var fresh_budget = config.create_budget(profile_id, effects)
    if fresh_budget == null:
        return {
            "started": false,
            "reason": "BUDGET_SNAPSHOT_FAILED",
        }

    turn_budget = fresh_budget
    _timeout_pending = false
    chain_input_skipped_for_timeout = false
    pending_player_action = null
    if effects != null:
        effects.advance_turn_boundary()
    phase = TurnPhase.LINE

    return {
        "started": true,
        "reason": "STARTED",
        "profile_id": profile_id,
        "base_budget_seconds": config.get_base_budget_seconds(profile_id),
        "flat_modifier_seconds": flat_modifier_seconds,
        "effective_budget_seconds": turn_budget.effective_budget_seconds,
        "tempo_reference_seconds": config.tempo_reference_seconds,
    }

func enter_line() -> void:
    if phase != TurnPhase.ENEMY_TELEGRAPH:
        return
    phase = TurnPhase.LINE

func tick_player_time(delta: float) -> void:
    if phase != TurnPhase.LINE and phase != TurnPhase.CHAIN and phase != TurnPhase.ACTION:
        return

    turn_budget.consume(delta)
    if not turn_budget.is_expired():
        return

    match phase:
        TurnPhase.LINE:
            _timeout_pending = true
            phase = TurnPhase.LINE_SETTLE
        TurnPhase.CHAIN:
            _timeout_pending = true
            phase = TurnPhase.CHAIN_SETTLE
        TurnPhase.ACTION:
            _resolve_timeout_pass()

func request_ready() -> void:
    match phase:
        TurnPhase.LINE:
            _timeout_pending = false
            phase = TurnPhase.LINE_SETTLE
        TurnPhase.CHAIN:
            _timeout_pending = false
            phase = TurnPhase.CHAIN_SETTLE

func complete_line_settle() -> void:
    if phase != TurnPhase.LINE_SETTLE:
        return
    if _timeout_pending:
        chain_input_skipped_for_timeout = true
        _resolve_timeout_pass()
        return
    phase = TurnPhase.CHAIN

func complete_chain_settle() -> void:
    if phase != TurnPhase.CHAIN_SETTLE:
        return
    if _timeout_pending:
        _resolve_timeout_pass()
        return
    phase = TurnPhase.ACTION

func select_player_action(action_id: String) -> bool:
    if phase != TurnPhase.ACTION or action_id == "":
        return false
    pending_player_action = PendingAction.new(action_id)
    turn_budget.freeze()
    phase = TurnPhase.PLAYER_RESOLVE
    return true

func complete_player_resolve() -> bool:
    if phase != TurnPhase.PLAYER_RESOLVE:
        return false
    phase = TurnPhase.ENEMY_RESOLVE
    return true

func complete_enemy_resolve() -> bool:
    if phase != TurnPhase.ENEMY_RESOLVE:
        return false
    phase = TurnPhase.ENEMY_TELEGRAPH
    pending_player_action = null
    chain_input_skipped_for_timeout = false
    return true

func _resolve_timeout_pass() -> void:
    _timeout_pending = false
    pending_player_action = PendingAction.new("PASS")
    turn_budget.freeze()
    phase = TurnPhase.PLAYER_RESOLVE
