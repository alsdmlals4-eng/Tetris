## Current battle successor; legacy Mastery save schemas remain independently loadable.
extends "res://src/replanned_r3/mastery_session.gd"
const CounterCombat=preload("res://src/replanned_r3/counter_combat.gd")
func _new_combat():return CounterCombat.new(_difficulty,_run_id,_profile)

func _impact()->Array:
    var enemy=action.get("owner")=="ENEMY"
    var events=super._impact()
    if enemy and not events.is_empty():action["counter_receipt"]=events[0].duplicate(true)
    return events

func _apply_finisher(target,event_id:String,kind:String,waves:int)->Dictionary:
    var result=super._apply_finisher(target,event_id,kind,waves)
    if result.get("success",false) and kind=="D":
        target.grant_counter(event_id,mini(waves,6))
        result["counter_granted"]=mini(waves,6)
        # Pattern-only zero-damage actions need their actual index during replay.
        result["counter_action_index"]=target.action_index
    return result

func _prepare_cast_probe(probe,cast:Dictionary)->bool:
    if cast.starter=="D":
        if not Validation.valid_integer(cast.get("counter_action_index"),0,2147483647):return false
        probe.action_index=int(cast.counter_action_index)
    return super._prepare_cast_probe(probe,cast)

func _valid_cast_ledger(data:Dictionary)->bool:
    if not super._valid_cast_ledger(data):return false
    var expected={}
    for cast in data.casts:
        if cast.starter=="D":
            if int(cast.counter_action_index)>int(data.combat.action_index):return false
            expected[cast.event_id]=int(cast.stage)
    return _normalize(data.combat.counter.grants)==expected

func snapshot()->Dictionary:
    var result=super.snapshot()
    if not result.is_empty():result.schema="r3-counter-choice-v1" if resource_mode=="SWAP" else "r3-counter-v1"
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema") not in ["r3-counter-v1","r3-counter-choice-v1"]:return false
    var copy=data.duplicate(true)
    copy.schema="r3-mastery-choice-v1" if data.schema=="r3-counter-choice-v1" else "r3-mastery-v1"
    return super.restore(copy)
