## Approved successor; older assist saves and rules stay independently loadable.
extends "res://src/replanned_r3/r3_assist_session.gd"
const MasteryLine=preload("res://src/replanned_r3/mastery_line.gd")
const MasterySupply=preload("res://src/replanned_r3/mastery_supply.gd")
const PatternCombat=preload("res://src/replanned_r3/pattern_combat.gd")
const MASTERY_CONFIG="res://data/replanned_r3/mastery.json"
var line_practice:=""

func setup_line_practice(kind:String)->void:
    practice_mode=true
    line_practice=kind
    preload("res://src/replanned_r3/mastery_practice.gd").setup(line,kind)

func tick(delta_us:int)->Array:
    if not line_practice.is_empty():return []
    return super.tick(delta_us)

func command(name:String,args:Dictionary={})->Dictionary:
    if not line_practice.is_empty() and name in ["switch","hold"]:return _failure("PRACTICE_LINE_ONLY")
    if not line_practice.is_empty() and practice_complete() and name not in ["pause","resume"]:return _failure("PRACTICE_COMPLETE")
    return super.command(name,args)

func practice_complete()->bool:
    if line_practice.is_empty() or line.history.is_empty():return false
    var last=MasteryLine.evaluate(line.history)[-1]
    return last.lines==4 if line_practice=="FOUR" else ((last.spin=="T_SPIN" and last.lines==2) if line_practice=="SPIN" else last.combo>=2)

func _new_line():return MasteryLine.new(_seed,_run_id+":line")
func _new_supply():return MasterySupply.new()
func _new_combat():return PatternCombat.new(_difficulty,_run_id,_profile)
func _elapse_combat(step:int)->void:
    super._elapse_combat(step)
    combat.elapse_status(step)
func _apply_finisher(target,event_id:String,kind:String,waves:int)->Dictionary:
    if kind=="A":return target.apply_attack_finisher(event_id,waves,finisher_power(kind,waves))
    return super._apply_finisher(target,event_id,kind,waves)
func _prepare_cast_probe(probe,cast:Dictionary)->bool:
    if cast.starter!="A":return true
    return probe.restore_attack_context(cast.get("pattern_context"))

func _credit_line(target,plan:Dictionary,ids:Array)->Dictionary:
    var result:Dictionary=target.credit(plan.id,ids)
    if not result.success:return result
    var units=int(plan.mastery.units)
    if units>0:
        var bonus:Dictionary=target.credit_mastery(plan.id,units)
        if not bonus.success:return bonus
        result.applied+=bonus.applied
        result.overflow+=bonus.overflow
    result["mastery"]=plan.mastery.duplicate(true)
    return result

func supply_report()->Dictionary:
    var units=0
    for entry in supply.mastery:units+=int(entry.units)
    var evaluated=MasteryLine.evaluate(line.history)
    return {"elapsed_us":elapsed_simulation_us,"seed":str(_seed),"producer":resource_mode,"base_units":supply._cells.size(),"mastery_units":units,"overflow":supply.discarded,"pairs":supply.pairs,"remainder":supply.remainder,"last":{} if evaluated.is_empty() else evaluated[-1]}

func snapshot()->Dictionary:
    var result=super.snapshot()
    if result.is_empty():return result
    result.schema="r3-mastery-choice-v1" if resource_mode=="SWAP" else "r3-mastery-v1"
    result["mastery_hash"]=FileAccess.get_sha256(MASTERY_CONFIG)
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema") not in ["r3-mastery-v1","r3-mastery-choice-v1"] or data.get("mastery_hash")!=FileAccess.get_sha256(MASTERY_CONFIG):return false
    var copy=data.duplicate(true)
    copy.schema="r3-assist-choice-v1" if data.schema=="r3-mastery-choice-v1" else "r3-assist-v1"
    copy.erase("mastery_hash")
    return super.restore(copy)

func _valid_resource_and_destruction_ledgers(data:Dictionary)->bool:
    if not super._valid_resource_and_destruction_ledgers(data):return false
    var expected=[]
    var clears=[]
    for entry in MasteryLine.evaluate(line.history):
        if entry.lines>0:clears.append(entry.id)
        if entry.units>0:expected.append({"id":entry.id,"units":entry.units})
    if data.supply.mastery!=expected:return false
    if resource_mode=="LINE" and data.supply.clears!=clears:return false
    return true
