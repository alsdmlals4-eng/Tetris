## Preserves supplied Line and Chain sessions while owning active input and safe handoff state.
## It never ticks puzzles, drains or mints rewards, acquires simulation pause, or controls enemy time.
class_name PuzzleWorkspaceManager
extends RefCounted

## Public workspace identifiers accepted by request_switch().
const LINE := "LINE"
const CHAIN := "CHAIN"

var line_session: ProductionLineSession
var chain_session: ProductionChainSession

var _active_workspace: String = LINE
var _pending_workspace: String = ""

func _init(
    p_line_session: ProductionLineSession,
    p_chain_session: ProductionChainSession
) -> void:
    line_session = p_line_session
    chain_session = p_chain_session
    _sync_input_ownership()

## Returns the workspace that currently owns input after the last safe handoff.
func active_workspace() -> String:
    return _active_workspace

## Records a target handoff and closes both inputs until cancellation or safe processing.
func request_switch(target: String) -> Dictionary:
    if target != LINE and target != CHAIN:
        return {
            "accepted": false,
            "reason": "INVALID_WORKSPACE",
        }

    if target == _active_workspace:
        if _pending_workspace == "":
            return {
                "accepted": false,
                "reason": "ALREADY_ACTIVE",
            }
        _pending_workspace = ""
        _sync_input_ownership()
        return {
            "accepted": true,
            "reason": "PENDING_SWITCH_CANCELLED",
        }

    _pending_workspace = target
    _sync_input_ownership()
    return {
        "accepted": true,
        "reason": "SWITCH_PENDING",
        "target": target,
    }

## Call after a session atomic operation returns or a Chain resolution settles to apply safe ownership.
func process_safe_handoff() -> Dictionary:
    if _pending_workspace == "":
        _sync_input_ownership()
        return {
            "switched": false,
            "reason": "NO_PENDING_SWITCH",
        }

    if _active_workspace == CHAIN and chain_session != null and chain_session.is_resolving():
        _sync_input_ownership()
        return {
            "switched": false,
            "reason": "CHAIN_RESOLVING",
        }

    _active_workspace = _pending_workspace
    _pending_workspace = ""
    _sync_input_ownership()
    return {
        "switched": true,
        "active_workspace": _active_workspace,
    }

## Returns whether a requested handoff still awaits its safe boundary.
func is_switch_pending() -> bool:
    return _pending_workspace != ""

## Returns whether the supplied Line session currently accepts manager-owned input.
func line_input_enabled() -> bool:
    return line_session != null and line_session.input_enabled

## Returns whether the supplied Chain session currently accepts manager-owned input.
func chain_input_enabled() -> bool:
    return chain_session != null and chain_session.input_enabled

func _sync_input_ownership() -> void:
    if _pending_workspace != "":
        if line_session != null:
            line_session.set_input_enabled(false)
        if chain_session != null:
            chain_session.set_input_enabled(false)
        return
    if line_session != null:
        line_session.set_input_enabled(_active_workspace == LINE)
    if chain_session != null:
        var chain_can_receive_input := _active_workspace == CHAIN and not chain_session.is_resolving()
        chain_session.set_input_enabled(chain_can_receive_input)
