## Approved successor: overflow economy, correction transactions and tier payoff.
## Legacy R3 and finisher v1 keep their own unchanged rules and save paths.
extends "res://src/replanned_r3/r3_finisher_session.gd"
const BonusSupply=preload("res://src/replanned_r3/bonus_supply.gd")
const AssistCombat=preload("res://src/replanned_r3/assist_combat.gd")
const ASSIST_CONFIG="res://data/replanned_r3/assist.json"
var _assist_rules:Dictionary={}
var bonus_history:Array=[]
var assist_requested:=false
var assist_open:=false
var practice_mode:=false

func assist_rules()->Dictionary:
    if _assist_rules.is_empty():_assist_rules=JSON.parse_string(FileAccess.get_file_as_string(ASSIST_CONFIG))
    return _assist_rules.duplicate(true)

func _new_supply():return BonusSupply.new()
func _new_combat():return AssistCombat.new(_difficulty,_run_id,_profile)

func bonus_balance()->int:
    var spent=0
    for entry in bonus_history:spent+=int(entry.cost)
    return supply.discarded-spent

func _destruction_count()->int:
    var rules=assist_rules()
    var profile=rules.default_profile if _profile.is_empty() else _profile
    if not rules.disruption.has(profile):return 0
    var pattern:Dictionary=rules.disruption[profile]
    if posmod(combat.action_index,4)!=int(pattern.index):return 0
    return maxi(1,int(pattern.count)-(1 if _difficulty=="RELAXED" else 0))

func command(name:String,args:Dictionary={})->Dictionary:
    if name=="soft_drop" and args.get("enabled") is bool and not args.enabled:return super.command(name,args)
    if name.begins_with("bonus_"):
        if combat.outcome!="RUNNING":return _failure("COMBAT_TERMINAL")
        if combat.paused:return _failure("PAUSED")
        if name=="bonus_cancel":
            assist_requested=false
            assist_open=false
            _spawn_if_needed()
            return {"success":true,"reason":""}
        if name=="bonus_open":
            if bonus_balance()<1:return _failure("INSUFFICIENT_BONUS")
            assist_requested=true
            if not action.is_empty():
                if mode!="CHAIN":queued_workspace="CHAIN"
                return {"success":true,"reason":"BONUS_QUEUED_UNTIL_STABLE"}
            if mode!="CHAIN":
                var switched=super.command("switch")
                if not switched.success:
                    assist_requested=false
                    return switched
            _spawn_if_needed()
            return {"success":true,"reason":"" if assist_open else "BONUS_QUEUED_UNTIL_STABLE"}
        if name=="bonus_apply":return _spend_bonus(args)
        return _failure("INVALID_BONUS_COMMAND")
    if assist_open and name not in ["pause","resume"]:return _failure("BONUS_SELECTION_OPEN")
    return super.command(name,args)

func _simulation_blocked()->bool:return assist_open
func _finalize_terminal()->Array:
    assist_requested=false
    assist_open=false
    return super._finalize_terminal()
func _board_blocked()->bool:return assist_open or super._board_blocked()
func can_checkpoint()->bool:return not practice_mode and not assist_open and not assist_requested and super.can_checkpoint()

func tick(delta_us:int)->Array:
    if practice_mode:combat.eta_us=3600000000
    return super.tick(delta_us)

func setup_practice()->void:
    practice_mode=true
    mode="CHAIN"
    chain.setup_two_chain_practice()
    _spawn_if_needed()
    chain.active_pair.axis.kind="H"
    chain.active_pair.satellite.kind="T"
    for i in 3:chain.command("move",{"dx":1})

func action_view(reduced_motion:bool=false)->Dictionary:
    var view=super.action_view(reduced_motion)
    if view.is_empty():return view
    var tier=maxi(1,int(view.stage))
    view["rings"]=tier
    view["effect_scale"]=1.0+float(tier-1)*0.17
    view["progress"]=float(action.elapsed_us)/float(action.duration_us)
    return view

func _spawn_if_needed()->void:
    if assist_requested and mode=="CHAIN" and chain.phase=="NEED_PAIR":
        if action.is_empty() and _pending.is_empty() and not combat._is_action_committed() and combat.outcome=="RUNNING" and not combat.paused:assist_open=true
        # Do not spawn across the requested boundary while an enemy is committed.
        return
    super._spawn_if_needed()

func finisher_power(kind:String,waves:int)->int:
    var powers:Dictionary=assist_rules().power
    if not powers.has(kind) or waves<1:return 0
    # Tier6 caps presentation, not earned chain value: extra waves retain T6 increments.
    var values:Array=powers[kind]
    var power=int(values[mini(waves,6)-1])
    if kind in ["A","H"] and waves>6:power+=(waves-6)*(int(values[5])-int(values[4]))
    return power

func _player_duration(waves:int)->int:return int(assist_rules().duration_us[clampi(waves-1,0,5)])

func _spend_bonus(args:Dictionary)->Dictionary:
    if not assist_open:return _failure("BONUS_NOT_OPEN")
    var operation=args.get("operation","")
    var rules=assist_rules()
    if not operation is String or not rules.costs.has(operation):return _failure("INVALID_BONUS_OPERATION")
    var cost=int(rules.costs[operation])
    if bonus_balance()<cost:return _failure("INSUFFICIENT_BONUS")
    var result:Dictionary={"success":true,"reason":""}
    if operation in ["change","shift"]:
        if not args.get("cell_id") is String:return _failure("INVALID_CELL")
        if operation=="change" and not args.get("kind") is String:return _failure("INVALID_KIND")
        if operation=="shift" and not Validation.valid_integer(args.get("dx"),-1,1):return _failure("INVALID_DIRECTION")
        result=chain.correct(operation,args.cell_id,args.get("kind",""),int(args.get("dx",0)))
        if not result.success:return result
        _axis_id=result.axis_id
    else:
        var amount=int(rules.emergency_amount)
        if operation=="heal":
            if combat.hp==combat.MAX_HP:return _failure("HP_FULL")
            combat.hp=mini(combat.MAX_HP,combat.hp+amount)
        elif operation=="attack":combat.attack_bank+=amount
        else:combat.armor+=amount
    bonus_history.append({"id":bonus_history.size()+1,"operation":operation,"cost":cost,"earned":supply.discarded,"args":args.duplicate(true),"event_id":result.get("event_id","")})
    combat.bonus_spend_ids.append(JSON.stringify(_normalize(bonus_history[-1])).sha256_text())
    assist_requested=false
    assist_open=false
    result["bonus_remaining"]=bonus_balance()
    result["events"]=_drain_board()
    return result

func snapshot()->Dictionary:
    var result=super.snapshot()
    if result.is_empty():return result
    result.schema="r3-assist-choice-v1" if resource_mode=="SWAP" else "r3-assist-v1"
    result["assist_hash"]=FileAccess.get_sha256(ASSIST_CONFIG)
    result["bonus_history"]=bonus_history.duplicate(true)
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema") not in ["r3-assist-v1","r3-assist-choice-v1"] or data.get("assist_hash")!=FileAccess.get_sha256(ASSIST_CONFIG):return false
    if not _valid_bonus_history(data):return false
    var copy=data.duplicate(true)
    copy.schema="r3-finisher-choice-v1" if data.schema=="r3-assist-choice-v1" else "r3-finisher-v1"
    copy.erase("assist_hash")
    copy.erase("bonus_history")
    if not super.restore(copy):return false
    bonus_history=_normalize(data.bonus_history)
    assist_open=false
    assist_requested=false
    return true

func _valid_bonus_history(data:Dictionary)->bool:
    if not data.get("bonus_history") is Array or not data.get("supply") is Dictionary or not data.get("chain") is Dictionary or not data.get("combat") is Dictionary:return false
    if not data.combat.get("bonus_spend_ids") is Array:return false
    if not Validation.valid_integer(data.supply.get("discarded"),0,2147483647) or not data.chain.get("processed_event_ids") is Array:return false
    var spent=0
    var earned=0
    var ids=[]
    var spend_ids=[]
    var rules=assist_rules()
    for i in data.bonus_history.size():
        var entry=data.bonus_history[i]
        if not entry is Dictionary or entry.size()!=6 or not Validation.valid_integer(entry.get("id"),i+1,i+1):return false
        if not entry.get("operation") is String or not rules.costs.has(entry.operation):return false
        if not Validation.valid_integer(entry.get("cost"),int(rules.costs[entry.operation]),int(rules.costs[entry.operation])) or not Validation.valid_integer(entry.get("earned"),earned,int(data.supply.discarded)):return false
        if not entry.get("args") is Dictionary or entry.args.get("operation")!=entry.operation or not entry.get("event_id") is String:return false
        earned=int(entry.earned)
        spent+=int(entry.cost)
        if spent>earned:return false
        if entry.operation in ["change","shift"]:
            if entry.args.size()!=3 or not entry.args.get("cell_id") is String:return false
            if not _ordinal_id(entry.args.cell_id,_run_id+":chain:cell:",int(data.chain.get("next_cell_id",0))):return false
            if entry.operation=="change" and entry.args.get("kind") not in ["A","D","H","T"]:return false
            if entry.operation=="shift" and entry.args.get("dx") not in [-1,1]:return false
            if entry.event_id in ids or entry.event_id not in data.chain.processed_event_ids or not entry.event_id.ends_with(":ASSIST"):return false
            ids.append(entry.event_id)
        elif entry.args.size()!=1 or not entry.event_id.is_empty():return false
        spend_ids.append(JSON.stringify(_normalize(entry)).sha256_text())
    var actual=[]
    for id in data.chain.processed_event_ids:
        if id.ends_with(":ASSIST"):actual.append(id)
    return ids==actual and spend_ids==data.combat.bonus_spend_ids
