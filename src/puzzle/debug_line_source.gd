class_name DebugLineSource
extends "res://src/puzzle/puzzle_event_source.gd"

const LineRulesScript := preload("res://src/rules/line_rules.gd")

func emit_clear(lines: int) -> Dictionary:
    return LineRulesScript.make_event(lines)
