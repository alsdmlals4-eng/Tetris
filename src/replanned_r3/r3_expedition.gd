## R3 sessions on the existing finite route/supply progression.
extends "res://src/replanned_r2/r2_expedition.gd"
const R3Session=preload("res://src/replanned_r3/r3_session.gd")

func make_battle_session():
    if _state.is_empty() or _state.phase!="BATTLE":return null
    var meta:Dictionary=_state.active_battle
    var session=R3Session.new(meta.difficulty,int(meta.seed),meta.run_id,meta.encounter_id)
    if session.combat.encounter_info().is_empty():return null
    var initial:Dictionary=session.combat.snapshot()
    initial.hp=meta.hp
    initial.attack_bank=meta.attack_bank
    initial.armor=meta.armor
    if not session.combat.restore(initial):return null
    return session

func snapshot()->Dictionary:
    var state=super.snapshot()
    if not state.is_empty():state.schema="r3-expedition-v1"
    return state

func restore(data:Dictionary)->bool:
    if data.get("schema")!="r3-expedition-v1":return false
    var converted=data.duplicate(true)
    converted.schema="r2-expedition-v1"
    return super.restore(converted)
