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
    counter_grants[event_id]={"tier":tier,"action_index":action_index}
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
    var receipt={"action_id":action_id(),"damage":int(preview.damage),"ward_absorbed":int(preview.ward_absorbed),"armor_absorbed":int(preview.armor_absorbed),"hp_before":hp,"boss_before":boss_hp,"charge_before":charge_damage}
    var result=super._resolve_current_action()
    var prevented=int(preview.counter_prevented)
    var reflected=mini(boss_hp,prevented)
    if prevented>0:
        counter_charges-=1
        boss_hp-=reflected
        if boss_hp==0 and hp>0:outcome="VICTORY"
    receipt["prevented"]=prevented
    receipt["reflected"]=reflected
    counter_hits.append(receipt)
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
    if not Validate.valid_integer(data.get("action_index"),0,2147483647):return false
    var expected=0
    for id in state.grants:
        var grant=state.grants[id]
        if not id is String or id not in data.processed_cast_event_ids or not grant is Dictionary or grant.size()!=2:return false
        if not Validate.valid_integer(grant.get("tier"),1,6) or not Validate.valid_integer(grant.get("action_index"),0,int(data.action_index)):return false
    if state.hits.size()!=data.pattern_events.size():return false
    var probe=get_script().new(_mode,_run_id,_pattern_profile)
    for i in state.hits.size():
        for grant in state.grants.values():
            if int(grant.action_index)==i:expected+=int(grant.tier)
        var hit=state.hits[i]
        if not hit is Dictionary or hit.size()!=9 or hit.get("action_id")!=data.pattern_events[i]:return false
        for key in ["damage","ward_absorbed","armor_absorbed","prevented","reflected"]:
            if not Validate.valid_integer(hit.get(key),0,2147483647):return false
        if not Validate.valid_integer(hit.get("hp_before"),1,100):return false
        if not probe.restore_attack_context({"boss_hp":hit.get("boss_before"),"shield":0,"weakness_us":0,"charge_damage":hit.get("charge_before"),"action_index":i}):return false
        if int(hit.damage)!=int(probe.current_action().damage):return false
        var residual=int(hit.damage)-int(hit.ward_absorbed)-int(hit.armor_absorbed)
        if residual<0:return false
        var prevented=ceili(residual/2.0) if expected>0 else 0
        if int(hit.prevented)!=prevented or int(hit.reflected)!=mini(int(hit.boss_before),prevented):return false
        if prevented>0:expected-=1
    for grant in state.grants.values():
        if int(grant.action_index)>=state.hits.size():expected+=int(grant.tier)
    if expected!=int(state.charges):return false
    var copy=data.duplicate(true)
    copy.schema="r3-pattern-combat-v1"
    copy.erase("counter")
    if not super.restore(copy):return false
    counter_charges=int(state.charges)
    counter_grants={}
    for id in state.grants:counter_grants[id]={"tier":int(state.grants[id].tier),"action_index":int(state.grants[id].action_index)}
    counter_hits=[]
    for hit in state.hits:
        var normalized={"action_id":hit.action_id}
        for key in hit:
            if key!="action_id":normalized[key]=int(hit[key])
        counter_hits.append(normalized)
    return true
