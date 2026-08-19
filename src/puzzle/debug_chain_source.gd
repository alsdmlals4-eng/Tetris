class_name DebugChainSource
extends "res://src/puzzle/puzzle_event_source.gd"

const ChainRulesScript := preload("res://src/rules/chain_rules.gd")

func emit_completed_chain(chain_count: int, pieces_cleared: int) -> Dictionary:
    return ChainRulesScript.make_completed_event(chain_count, pieces_cleared)
