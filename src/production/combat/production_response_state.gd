class_name ProductionResponseState
extends RefCounted

var _action_id: String = ""
var _direct_mitigation: int = 0
var _counter_ratio: float = 0.0
var _resource_ward_ratio: float = 0.0
var _lethal_hp_floor: int = 0
var _lethal_charges: int = 0

func configure_direct_mitigation(action_id: String, magnitude: int) -> bool:
    if magnitude <= 0 or not _bind_action(action_id):
        return false
    _direct_mitigation = maxi(_direct_mitigation, magnitude)
    return true

func configure_counter(action_id: String, ratio: float) -> bool:
    if ratio <= 0.0 or ratio > 1.0 or not _bind_action(action_id):
        return false
    _counter_ratio = maxf(_counter_ratio, ratio)
    return true

func configure_resource_ward(action_id: String, ratio: float) -> bool:
    if ratio <= 0.0 or ratio > 1.0 or not _bind_action(action_id):
        return false
    _resource_ward_ratio = maxf(_resource_ward_ratio, ratio)
    return true

func configure_lethal_safety(action_id: String, hp_floor: int, charges: int) -> bool:
    if hp_floor < 1 or charges < 1 or not _bind_action(action_id):
        return false
    _lethal_hp_floor = maxi(_lethal_hp_floor, hp_floor)
    _lethal_charges = maxi(_lethal_charges, charges)
    return true

func modifiers_for_action(action_id: String) -> Dictionary:
    if action_id == "" or action_id != _action_id:
        return {}
    return {
        "direct_mitigation": _direct_mitigation,
        "counter_ratio": _counter_ratio,
        "resource_ward_ratio": _resource_ward_ratio,
        "lethal_hp_floor": _lethal_hp_floor,
        "lethal_charges": _lethal_charges,
    }

func clear_after_action(action_id: String) -> bool:
    if action_id == "" or action_id != _action_id:
        return false
    _action_id = ""
    _direct_mitigation = 0
    _counter_ratio = 0.0
    _resource_ward_ratio = 0.0
    _lethal_hp_floor = 0
    _lethal_charges = 0
    return true

func _bind_action(action_id: String) -> bool:
    if action_id == "":
        return false
    if _action_id == "":
        _action_id = action_id
        return true
    return _action_id == action_id
