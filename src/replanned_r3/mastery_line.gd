## Opt-in movement adapter. Reuses production recognition; only player locks advance history.
extends "res://src/replanned_r3/r3_line.gd"
const Spin=preload("res://src/production/line/line_spin_recognizer.gd")
const Streak=preload("res://src/production/line/line_streak_state.gd")
const Result=preload("res://src/production/line/line_clear_result.gd")
const CONFIG="res://data/replanned_r3/mastery.json"
var history:Array=[]

static func evaluate(entries:Array)->Array:
    var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONFIG)).line
    var streak=Streak.new()
    var result:Array=[]
    for entry in entries:
        var clear=Result.new(true,"",int(entry.lines),Result.classify(int(entry.lines)),0,0)
        clear.lines_cleared=int(entry.lines)
        clear.clear_kind="FOUR" if clear.lines_cleared==4 else "ORDINARY"
        clear.spin_kind=entry.spin
        streak.decorate(clear)
        var base=int(rules.four) if clear.lines_cleared==4 else (int(rules.spin_per_line)*clear.lines_cleared if entry.spin=="T_SPIN" else 0)
        var combo=mini(int(rules.combo_cap),maxi(0,clear.combo_index)*int(rules.combo_step))
        var b2b=int(rules.back_to_back) if clear.back_to_back else 0
        result.append({"id":entry.id,"lines":clear.lines_cleared,"spin":entry.spin,"combo":maxi(0,clear.combo_index+1),"b2b":clear.back_to_back,"base":base,"combo_bonus":combo,"b2b_bonus":b2b,"units":mini(int(rules.placement_cap),base+combo+b2b)})
    return result

func mastery_preview()->Dictionary:
    var plan=super.lock_plan()
    if plan.get("topout",false):return {}
    var entries=history.duplicate(true)
    entries.append({"id":plan.id,"lines":plan.rows.size(),"spin":Spin.classify(_engine.board,_engine.active)})
    return evaluate(entries)[-1]

func lock_plan()->Dictionary:
    var plan=super.lock_plan()
    if not plan.get("topout",false):plan["mastery"]=mastery_preview()
    return plan

func commit_lock()->void:
    if spawn_blocked():return
    var preview=mastery_preview()
    history.append({"id":preview.id,"lines":preview.lines,"spin":preview.spin})
    super.commit_lock()

func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-mastery-line-v1"
    result["history"]=history.duplicate(true)
    result["last_action"]=_engine.active.last_successful_action
    return result

func restore(data:Dictionary)->bool:
    if data.size()!=8 or data.get("schema")!="r3-mastery-line-v1" or not data.get("history") is Array:return false
    if data.get("last_action") not in ["NONE","MOVE","ROTATE","HARD_DROP"]:return false
    if not data.get("engine") is Dictionary or data.history.size()!=data.engine.get("lock_sequence"):return false
    for i in data.history.size():
        var entry=data.history[i]
        if not entry is Dictionary or entry.size()!=3 or entry.get("id")!=_namespace+":line:"+str(i+1):return false
        if not Validation.valid_integer(entry.get("lines"),0,4) or entry.get("spin") not in ["NONE","T_SPIN"]:return false
        if int(entry.lines)==4 and entry.spin=="T_SPIN":return false
    var copy=data.duplicate(true)
    copy.schema="r3-line-v1"
    copy.erase("history")
    copy.erase("last_action")
    if not super.restore(copy):return false
    history=[]
    for entry in data.history:history.append({"id":entry.id,"lines":int(entry.lines),"spin":entry.spin})
    _engine.active.last_successful_action=data.last_action
    return true
