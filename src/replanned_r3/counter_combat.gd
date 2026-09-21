## Opt-in successor. Guard state belongs to combat, never to the cut-in/UI.
extends "res://src/replanned_r3/pattern_combat.gd"
var counter_charges:=0
var counter_grants:Dictionary={}
var counter_hits:Array=[]

func _init(mode:String="STANDARD",run_identity:String="r3:standalone",profile:String=""):
    super(mode,run_identity,profile)
    _rule_pack="r3-counter-guard-v1"
    _rule_pack_hash=(_rule_pack_hash+":counter-half-after-mitigation-v1").sha256_text()

func grant_counter(event_id:String,tier:int)->void:
    if counter_grants.has(event_id):return
    counter_grants[event_id]=tier
    counter_charges+=tier

func counter_state()->Dictionary:
    var prevented=0
    var reflected=0
    for hit in counter_hits:
        prevented+=int(hit.prevented)
        reflected+=int(hit.reflected)
    return {"charges":counter_charges,"prevented":prevented,"reflected":reflected}

func threat_preview()->Dictionary:
    var preview=super.threat_preview()
    var residual=int(preview.damage)-int(preview.ward_absorbed)-int(preview.armor_absorbed)
    var prevented=ceili(residual/2.0) if counter_charges>0 and residual>0 and preview.active else 0
    preview["counter_prevented"]=prevented
    preview.damage_to_hp=mini(hp,residual-prevented)
    preview.hp_after=hp-int(preview.damage_to_hp)
    preview.lethal=preview.active and preview.hp_after==0
    return preview

func _resolve_current_action()->Dictionary:
    if action_id() in pattern_events:return {"success":false,"reason":"DUPLICATE_ENEMY_IMPACT"}
    var preview=threat_preview()
    var result=super._resolve_current_action()
    var prevented=int(preview.counter_prevented)
    var reflected=mini(boss_hp,prevented)
    if prevented>0:
        counter_charges-=1
        boss_hp-=reflected
        counter_hits.append({"action_id":action_id(),"prevented":prevented,"reflected":reflected})
        if boss_hp==0 and hp>0:outcome="VICTORY"
    if outcome!="RUNNING":
        enemy_shield=0;shield_expiry=-1;weakness_us=0;charge_damage=0
        result.pattern_state=pattern_state()
    result["counter_prevented"]=prevented
    result["counter_reflected"]=reflected
    result["counter_remaining"]=counter_charges
    return result

func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-counter-combat-v1"
    result["counter"]={"charges":counter_charges,"grants":counter_grants.duplicate(true),"hits":counter_hits.duplicate(true)}
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema")!="r3-counter-combat-v1" or not data.get("counter") is Dictionary:return false
    var state:Dictionary=data.counter
    if state.size()!=3 or not Validate.valid_integer(state.get("charges"),0,2147483647) or not state.get("grants") is Dictionary or not state.get("hits") is Array:return false
    if not data.get("processed_cast_event_ids") is Array or not data.get("pattern_events") is Array:return false
    var expected=0
    for id in state.grants:
        if not id is String or id not in data.processed_cast_event_ids or not Validate.valid_integer(state.grants[id],1,6):return false
        expected+=int(state.grants[id])
    var seen=[]
    for hit in state.hits:
        if not hit is Dictionary or hit.size()!=3 or not hit.get("action_id") is String or hit.action_id not in data.pattern_events or hit.action_id in seen:return false
        if not Validate.valid_integer(hit.get("prevented"),1,100) or not Validate.valid_integer(hit.get("reflected"),0,int(hit.prevented)):return false
        seen.append(hit.action_id)
        expected-=1
    if expected!=int(state.charges):return false
    var copy=data.duplicate(true)
    copy.schema="r3-pattern-combat-v1"
    copy.erase("counter")
    if not super.restore(copy):return false
    counter_charges=int(state.charges)
    counter_grants={}
    for id in state.grants:counter_grants[id]=int(state.grants[id])
    counter_hits=[]
    for hit in state.hits:counter_hits.append({"action_id":hit.action_id,"prevented":int(hit.prevented),"reflected":int(hit.reflected)})
    return true
