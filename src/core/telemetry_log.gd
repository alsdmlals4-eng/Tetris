class_name TelemetryLog
extends RefCounted

var events: Array = []

func record(event_name: StringName, combat_time: float, payload: Dictionary = {}) -> Dictionary:
    var event := {
        "name": event_name,
        "time": combat_time,
        "payload": payload.duplicate(true),
    }
    events.append(event)
    return event.duplicate(true)

func clear() -> void:
    events.clear()
