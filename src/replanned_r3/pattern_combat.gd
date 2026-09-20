## Encounter-specific counterplay; authoritative effects occur at the shared impact boundary.
extends "res://src/replanned_r3/assist_combat.gd"
const PATTERN_CONFIG="res://data/replanned_r3/mastery.json"
const Validate=preload("res://src/replanned_r2/r2_chain.gd")
var enemy_shield:=0
var shield_expiry:=-1
var weakness_us:=0
var charge_damage:=0
var pattern_events:Array=[]
var _pattern_rules:Dictionary={}
var _pattern_profile:String

func _init(mode:String="STANDARD",run_identity:String="r3:standalone",profile:String=""):
    _pattern_profile="rift_core" if profile.is_empty() else profile
    _pattern_rules=JSON.parse_string(FileAccess.get_file_as_string(PATTERN_CONFIG))
    super(mode,run_identity,profile)
    _rule_pack="r3-mastery-effects-v1"
    _rule_pack_hash=(_rule_pack_hash+":"+FileAccess.get_sha256(PATTERN_CONFIG)).sha256_text()

func _action_for_index(index:int,mode:String="")->Dictionary:
    var result=super._action_for_index(index,mode)
    result["pattern"]=""
    var spec:Dictionary=_pattern_rules.encounters.get(_pattern_profile,{})
    if spec.is_empty() or posmod(index,4)!=int(spec.index):return result
    result.pattern=spec.kind
    result.label=spec.label
    if spec.kind in ["shield","armor_break"]:result.damage=0
    if spec.kind=="charge" and (index!=action_index or charge_damage<int(_pattern_rules.patterns.charge_cancel_damage)):
        result.damage+=int(_pattern_rules.patterns.charge_bonus)
    return result

func pattern_state()->Dictionary:
    return {"shield":enemy_shield,"shield_expiry":shield_expiry,"weakness_us":weakness_us,"charge_damage":charge_damage}

func elapse_status(delta_us:int)->void:
    weakness_us=maxi(0,weakness_us-maxi(0,delta_us))

func _resolve_current_action()->Dictionary:
    if action_id() in pattern_events:return {"success":false,"reason":"DUPLICATE_ENEMY_IMPACT"}
    var kind=String(current_action().pattern)
    var before_ward=ward
    var before_target=ward_target
    var result=super._resolve_current_action()
    if action_index>=shield_expiry:
        enemy_shield=0
        shield_expiry=-1
    if kind=="shield":
        enemy_shield=int(_pattern_rules.patterns.shield)
        shield_expiry=action_index+1
    elif kind=="armor_break":
        var removed=mini(armor,int(_pattern_rules.patterns.armor_break))
        armor-=removed
        ward=before_ward
        ward_target=before_target
        result["armor_removed"]=removed
    elif kind=="weakness":weakness_us=int(_pattern_rules.patterns.weakness_us)
    if outcome!="RUNNING":
        enemy_shield=0
        shield_expiry=-1
        weakness_us=0
        charge_damage=0
    result["pattern"]=kind
    result["pattern_state"]=pattern_state()
    pattern_events.append(action_id())
    return result

func _schedule_next_action()->void:
    super._schedule_next_action()
    charge_damage=0

func attack_preview(amount:int)->Dictionary:
    var requested=amount+attack_bank
    if weakness_us>0:requested=int(ceil(float(requested)*(100+int(_pattern_rules.patterns.weakness_percent))/100.0))
    var absorbed=mini(enemy_shield,requested)
    return {"damage_requested":requested,"shield_absorbed":absorbed,"damage_applied":mini(boss_hp,requested-absorbed)}

func apply_attack_finisher(event_id:String,waves:int,amount:int)->Dictionary:
    if paused or outcome!="RUNNING" or waves<1 or waves>21:return {"success":false,"reason":"INVALID_FINISHER"}
    if event_id.is_empty() or _processed_cast_events.has(event_id):return {"success":false,"reason":"DUPLICATE_EVENT"}
    var context={"boss_hp":boss_hp,"shield":enemy_shield,"weakness_us":weakness_us,"charge_damage":charge_damage,"action_index":action_index}
    var result={"success":true,"effect":"ATK_DAMAGE","reason":"","event_id":event_id,"category":"ATK","starter":"A","wave":waves,"stage":mini(waves,6),"power":amount,"bank_consumed":attack_bank,"pattern_context":context}
    result.merge(attack_preview(amount))
    _processed_cast_events[event_id]=true
    attack_bank=0
    boss_hp-=int(result.damage_applied)
    enemy_shield-=int(result.shield_absorbed)
    weakness_us=0
    if current_action().pattern=="charge":charge_damage=mini(int(_pattern_rules.patterns.charge_cancel_damage),charge_damage+int(result.damage_applied))
    if boss_hp==0:outcome="VICTORY"
    result["shield_after"]=enemy_shield
    result["charge_after"]=charge_damage
    return result

func restore_attack_context(context)->bool:
    if not context is Dictionary or context.size()!=5:return false
    var limits={"boss_hp":[1,int(_encounter.boss_hp)],"shield":[0,int(_pattern_rules.patterns.shield)],"weakness_us":[0,int(_pattern_rules.patterns.weakness_us)],"charge_damage":[0,int(_pattern_rules.patterns.charge_cancel_damage)],"action_index":[0,2147483647]}
    for key in limits:
        if not Validate.valid_integer(context.get(key),limits[key][0],limits[key][1]):return false
    if _pattern_profile!="foundry" and context.shield!=0:return false
    if _pattern_profile!="outer_breach" and context.weakness_us!=0:return false
    if (_pattern_profile!="rift_core" or posmod(int(context.action_index),4)!=1) and context.charge_damage!=0:return false
    boss_hp=int(context.boss_hp)
    enemy_shield=int(context.shield)
    weakness_us=int(context.weakness_us)
    charge_damage=int(context.charge_damage)
    action_index=int(context.action_index)
    return true

func snapshot()->Dictionary:
    var result=super.snapshot()
    result.schema="r3-pattern-combat-v1"
    result["pattern_state"]=pattern_state()
    result["pattern_events"]=pattern_events.duplicate()
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema")!="r3-pattern-combat-v1" or not data.get("pattern_state") is Dictionary or not data.get("pattern_events") is Array:return false
    var state:Dictionary=data.pattern_state
    if state.size()!=4:return false
    if not Validate.valid_integer(data.get("boss_hp"),0,int(_encounter.boss_hp)):return false
    var probe=get_script().new(_mode,_run_id,_pattern_profile)
    # Context validation also forbids statuses belonging to another encounter.
    if not probe.restore_attack_context({"boss_hp":maxi(1,int(data.get("boss_hp",0))),"shield":state.get("shield"),"weakness_us":state.get("weakness_us"),"charge_damage":state.get("charge_damage"),"action_index":data.get("action_index")}):return false
    if not Validate.valid_integer(state.get("shield_expiry"),-1,2147483647):return false
    if state.shield_expiry!=-1 and (_pattern_profile!="foundry" or state.shield_expiry!=data.action_index or posmod(int(data.action_index),4)!=1):return false
    if state.shield>0 and state.shield_expiry==-1:return false
    if state.weakness_us>0 and (_pattern_profile!="outer_breach" or posmod(int(data.action_index),4)!=2):return false
    var completed=int(data.get("action_index",-1))
    if data.get("outcome")=="DEFEAT" and data.get("eta_us")==0:completed+=1
    if data.pattern_events.size()!=completed:return false
    for i in data.pattern_events.size():
        if data.pattern_events[i]!=_run_id+":"+str(i):return false
    var copy=data.duplicate(true)
    copy.schema="r3-assist-combat-v1"
    copy.erase("pattern_state")
    copy.erase("pattern_events")
    if not super.restore(copy):return false
    enemy_shield=int(state.shield)
    shield_expiry=int(state.shield_expiry)
    weakness_us=int(state.weakness_us)
    charge_damage=int(state.charge_damage)
    pattern_events=data.pattern_events.duplicate()
    return true
