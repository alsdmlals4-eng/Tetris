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

func _resolve_timeout_pass() -> void:
    _timeout_pending = false
    pending_player_action = PendingAction.new("PASS")
    turn_budget.freeze()
    phase = TurnPhase.PLAYER_RESOLVE
