## R3 public transaction owner. Views issue commands; no swap or free refill.
extends RefCounted
const Combat=preload("res://src/replanned_r3/r3_combat.gd")
const Line=preload("res://src/replanned_r3/r3_line.gd")
const Chain=preload("res://src/replanned_r3/r3_pair_board.gd")
const Supply=preload("res://src/replanned_r3/r3_pair_supply.gd")
const Disruption=preload("res://src/replanned_r3/r3_disruption.gd")
const Validation=preload("res://src/replanned_r2/r2_chain.gd")
const Swap=preload("res://src/replanned_r3/resource_swap.gd")
const Rewards=preload("res://src/replanned_r3/resource_rewards.gd")
var resource_mode:="LINE"
var resource_locked:=false
var swap
var resource_rewards
var combat
var line
var chain
var supply
var disruption
var mode:="LINE"
var selected_category:="ATK"
var queued_workspace:=""
var last_cast:Dictionary={}
var elapsed_simulation_us:=0
var metrics:={"casts":0,"max_combo":0,"line_clears":0,"switches":0,"topouts":0,"destroyed":0,"supply_overflow":0}
var _seed:int
var _run_id:String
var _difficulty:String
var _profile:String
var _spawn_sequence:=0
var _pending:Array=[]
var _casts:Array=[]
var _destruction_events:Array=[]

func _init(difficulty:String="STANDARD",seed_value:int=9112026,run_identity:String="r3:standalone",profile:String=""):
    _seed=seed_value
    _run_id=run_identity
    _difficulty=difficulty
    _profile=profile
    combat=_new_combat()
    line=Line.new(seed_value,run_identity+":line")
    chain=Chain.new(hash("r3-chain:%d"%seed_value),run_identity+":chain")
    supply=_new_supply()
    disruption=Disruption.new(seed_value)
    _begin_threat()

func _new_supply():return Supply.new()
func _new_combat():return Combat.new(_difficulty,_run_id,_profile)

func command(action:String,args:Dictionary={})->Dictionary:
    if action=="prepare_resource":
        if resource_locked or elapsed_simulation_us>0 or mode!="LINE" or _spawn_sequence>0 or int(line.snapshot().engine.lock_sequence)>0:return _failure("RESOURCE_CHOICE_LOCKED")
        if args.get("mode") not in ["LINE","SWAP"]:return _failure("INVALID_RESOURCE_MODE")
        resource_mode=args.mode
        resource_locked=true
        if resource_mode=="SWAP":
            swap=Swap.new(hash("resource-swap:%d"%_seed),_run_id+":swap")
            resource_rewards=Rewards.new(_run_id+":resource","SWAP")
        return {"success":true}
    if action=="pause":
        combat.paused=true
        return {"success":true}
    if action=="resume" and combat.outcome=="RUNNING":
        combat.paused=false
        return {"success":true}
    if combat.outcome!="RUNNING":return _failure("COMBAT_TERMINAL")
    if combat.paused:return _failure("PAUSED")
    if action=="resource_swap":
        if mode!="LINE" or resource_mode!="SWAP":return _failure("RESOURCE_BOARD_INACTIVE")
        if not args.get("a") is Vector2i or not args.get("b") is Vector2i:return _failure("INVALID_CELL")
        return swap.try_swap(args.a,args.b,"ATK")
    if action=="category":
        if chain.is_resolving():return _failure("CASCADE_CATEGORY_LOCKED")
        if args.get("category") not in ["ATK","DEF","SUP"]:return _failure("INVALID_CATEGORY")
        selected_category=args.category
        chain.selected_category=selected_category
        return {"success":true}
    if action=="switch":
        var target="CHAIN" if mode=="LINE" else "LINE"
        if chain.is_resolving() or (resource_mode=="SWAP" and swap.resolving):
            queued_workspace=target
            return {"success":true,"reason":"QUEUED_UNTIL_STABLE"}
        mode=target
        metrics.switches+=1
        _spawn_if_needed()
        return {"success":true}
    if action not in ["move","rotate","soft_drop","hold","hard_drop"]:return _failure("UNSUPPORTED_R3_COMMAND")
    if mode=="CHAIN":
        if action=="hold":return _failure("CHAIN_HAS_NO_HOLD")
        var result:Dictionary=chain.command(action,args)
        if result.success: result.events=_drain_board()
        return result
    if resource_mode=="SWAP":return _failure("SWAP_USES_CELL_SELECTION")
    if line.spawn_blocked():return {"success":true,"events":_line_topout()}
    if action=="move":
        if not Validation.valid_integer(args.get("dx"),-1,1) or int(args.dx)==0:return _failure("INVALID_DIRECTION")
        return {"success":line.move(int(args.dx))}
    if action=="rotate":
        if not Validation.valid_integer(args.get("direction"),-1,1) or int(args.direction)==0:return _failure("INVALID_DIRECTION")
        return {"success":line.rotate(int(args.direction))}
    if action=="soft_drop":return {"success":line.move(0,1)}
    if action=="hold":
        var success:bool=line.hold()
        return {"success":success,"events":_line_topout() if success and line.spawn_blocked() else []}
    return {"success":true,"events":_commit_line(line.hard_drop_plan())}

func tick(delta_us:int)->Array:
    if delta_us<0:return [_failure("INVALID_DELTA")]
    if combat.paused or combat.outcome!="RUNNING":return []
    if delta_us>0:resource_locked=true
    var events:Array=[]
    var remaining=delta_us
    while remaining>0 and combat.outcome=="RUNNING":
        _reserve_threat()
        events.append_array(_drain_board())
        if combat.outcome!="RUNNING":break
        var step=mini(remaining,combat.eta_us)
        if not disruption.preview().get("reserved",false) and combat.eta_us>2000000:
            step=mini(step,combat.eta_us-2000000)
        if mode=="LINE" and resource_mode=="LINE":step=mini(step,line.next_event_us())
        if resource_mode=="SWAP" and swap.resolving:step=mini(step,swap.next_wave_remaining_us)
        var chain_due:int=chain.next_event_us() if mode=="CHAIN" or chain.is_resolving() else -1
        if chain_due>=0:step=mini(step,chain_due)
        if step==0:
            events.append(_failure("UNRESOLVED_ZERO_TIME_EVENT"))
            break
        if mode=="LINE" and resource_mode=="LINE":line.advance_time(step)
        if resource_mode=="SWAP" and swap.resolving:swap.advance_time(step)
        if mode=="CHAIN" or chain.is_resolving():chain.advance_time(step)
        var boss_events:Array=combat.tick(step)
        elapsed_simulation_us+=step
        remaining-=step
        events.append_array(boss_events)
        if combat.outcome=="DEFEAT":
            disruption.commit()
            _pending.clear()
            queued_workspace=""
            events.append_array(_finalize_terminal())
            break
        for event in boss_events:
            if event.get("effect")=="ENEMY_ACTION_RESOLVED":
                var payload:Dictionary=disruption.commit()
                if payload.success:_pending.append(payload)
                _begin_threat()
        _reserve_threat()
        events.append_array(_drain_board())
    if combat.outcome!="RUNNING":events.append_array(_finalize_terminal())
    return events

func _spawn_if_needed()->void:
    if _board_blocked():return
    if mode!="CHAIN" or chain.phase!="NEED_PAIR" or supply.pairs<=0 or combat.outcome!="RUNNING":return
    var id=_run_id+":pair:"+str(_spawn_sequence+1)
    var result:Dictionary=chain.spawn(id)
    if result.success:
        supply.consume(id)
        _spawn_sequence+=1
        chain.selected_category=selected_category

func _drain_board()->Array:
    var events:Array=[]
    for safety in 256:
        if _board_blocked():break
        if combat.outcome=="DEFEAT":break
        if combat.outcome=="VICTORY" and _pending.is_empty():break
        var changed=false
        if not _pending.is_empty():
            var pending:Dictionary=_pending[0]
            var result:Dictionary={}
            if pending.target_board=="LINE":
                result=swap.destroy_cells(pending.action_id,pending.target_ids) if resource_mode=="SWAP" else line.destroy_cells(pending.action_id,pending.target_ids)
            else:
                var plan:Dictionary=chain.plan_disruption(pending.action_id,pending.target_ids)
                if not plan.is_empty():result=chain.commit(plan)
            if not result.is_empty():
                _pending.pop_front()
                if result.success:
                    var removed:Array=result.get("removed",[]).duplicate()
                    if pending.target_board=="CHAIN":
                        for cell in result.get("cells",[]):removed.append(cell.cell_id)
                    var missing:Array=[]
                    for id in pending.target_ids:
                        if id not in removed:missing.append(id)
                    result.merge({"event_id":pending.action_id,"target_board":pending.target_board,
                        "target_ids":pending.target_ids.duplicate(),"removed_ids":removed,"missing_ids":missing,
                        "cause":"ENEMY_DESTROY","origin":"ENEMY_DESTROY","rewards":[]},true)
                    metrics.destroyed+=removed.size()
                    _destruction_events.append({"event_id":pending.action_id,"target_board":pending.target_board,
                        "target_ids":pending.target_ids.duplicate(),"removed_ids":removed,"missing_ids":missing})
                events.append(result)
                changed=true
        if combat.outcome=="RUNNING" and resource_mode=="SWAP" and swap.resolving and swap.next_wave_remaining_us==0:
            events.append_array(_commit_swap())
            changed=true
        if combat.outcome=="RUNNING" and mode=="LINE" and resource_mode=="LINE" and line.spawn_blocked():
            events.append_array(_line_topout())
            changed=true
        elif combat.outcome=="RUNNING" and mode=="LINE" and resource_mode=="LINE" and line.grounded() and line.grounded_time()>=Line.LOCK_US:
            events.append_array(_commit_line(line.lock_plan()))
            changed=true
        if (mode=="CHAIN" or chain.is_resolving()) and chain.next_event_us()==0:
            var plan:Dictionary=chain.plan_due_event()
            if not plan.is_empty():
                if combat.outcome=="RUNNING" and plan.type=="WAVE_RESOLVED" and plan.cause=="PLAYER_LOCK":
                    events.append_array(_resolve_player_wave(plan))
                if combat.outcome=="RUNNING" and plan.type=="TOP_OUT":
                    events.append(combat.apply_topout(plan.event_id))
                    metrics.topouts+=1
                var committed:Dictionary=chain.commit(plan)
                events.append(committed)
                if committed.success:_after_chain_commit(plan)
                changed=true
        if not chain.is_resolving() and not (resource_mode=="SWAP" and swap.resolving) and not queued_workspace.is_empty():
            mode=queued_workspace
            queued_workspace=""
            metrics.switches+=1
            changed=true
        _spawn_if_needed()
        if not changed:break
    if combat.outcome!="RUNNING" and _pending.is_empty():events.append_array(_finalize_terminal())
    return events

func _board_blocked()->bool:return false

func _resolve_player_wave(plan:Dictionary)->Array:
    var cast:Dictionary=combat.cast(plan.event_id,plan.category,int(plan.wave))
    if cast.success:_record_cast(cast)
    return [cast]

func _record_cast(cast:Dictionary)->void:
    last_cast=cast.duplicate(true)
    _casts.append(cast.duplicate(true))
    metrics.casts+=1
    metrics.max_combo=maxi(metrics.max_combo,int(cast.wave))

func _after_chain_commit(_plan:Dictionary)->void:pass

func _finalize_terminal()->Array:
    var events:Array=[]
    if combat.outcome=="RUNNING":return events
    if combat.outcome=="VICTORY":
        # Already-paid destruction finishes without advancing the battle clock
        # or awarding any additional player effect. Uncommitted attacks cancel.
        for safety in 256:
            if chain.cause!="ENEMY_SETTLE" or not chain.is_resolving():break
            var due:int=chain.next_event_us()
            if due<0:break
            chain.advance_time(due)
            var plan:Dictionary=chain.plan_due_event()
            if plan.is_empty():break
            var result:Dictionary=chain.commit(plan)
            result.reward_eligible=false
            events.append(result)
    chain.finalize_terminal()
    if resource_mode=="SWAP":swap.cancel()
    disruption.cancel_uncommitted()
    queued_workspace=""
    _pending.clear()
    return events

func _commit_line(plan:Dictionary)->Array:
    if plan.get("topout",false):return _line_topout()
    var events:Array=[]
    if not plan.cells.is_empty():
        var ids:Array=[]
        for cell in plan.cells:ids.append(cell.id)
        var next_combat=_new_combat()
        var next_supply=_new_supply()
        if not next_combat.restore(combat.snapshot()) or not next_supply.restore(supply.snapshot()):return [_failure("INVALID_TRANSACTION_SOURCE")]
        var reward:Dictionary=next_combat.apply_line(plan.id,plan.cells)
        var credit:Dictionary=next_supply.credit(plan.id,ids)
        if not reward.success or not credit.success:return [_failure("LINE_TRANSACTION_REJECTED")]
        combat=next_combat
        supply=next_supply
        events.append(reward)
        events.append(credit)
        metrics.supply_overflow+=credit.overflow
        metrics.line_clears+=plan.rows.size()
    line.commit_lock()
    return events

func _commit_swap()->Array:
    var plan:Dictionary=swap.clear_plan()
    if plan.is_empty():return []
    var rewards=Rewards.new(_run_id+":resource","SWAP")
    var next_combat=_new_combat()
    var next_supply=_new_supply()
    if not rewards.restore(resource_rewards.snapshot()) or not next_combat.restore(combat.snapshot()) or not next_supply.restore(supply.snapshot()):return [_failure("INVALID_TRANSACTION_SOURCE")]
    var normalized:Dictionary=rewards.credit(plan.id,plan.cells)
    if not normalized.success:return [_failure("INVALID_RESOURCE_CLEAR")]
    var events:Array=[]
    if not normalized.cells.is_empty():
        var reward:Dictionary=next_combat.apply_line(plan.id,normalized.cells)
        var ids:Array=[]
        for cell in normalized.cells:ids.append(cell.id)
        var credit:Dictionary=next_supply.credit(plan.id,ids)
        if not reward.success or not credit.success:return [_failure("RESOURCE_TRANSACTION_REJECTED")]
        events.append(reward)
        events.append(credit)
        metrics.supply_overflow+=credit.overflow
    combat=next_combat
    supply=next_supply
    resource_rewards=rewards
    events.append(swap.commit_wave())
    return events

func _line_topout()->Array:
    var id=_run_id+":line-topout:"+str(int(line.snapshot().engine.reset_sequence)+1)
    var event:Dictionary=combat.apply_topout(id)
    if event.get("reset_required",false):
        line.reset_after_topout()
        metrics.topouts+=1
    var events:Array=[event]
    if combat.outcome!="RUNNING":events.append_array(_finalize_terminal())
    return events

func _begin_threat()->void:
    disruption.begin(combat.action_id(),mode,_destruction_count())

func _destruction_count()->int:
    var count=0
    var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Supply.RULES_PATH)).disruption
    if rules.action_indices.has(_profile) and posmod(combat.action_index,4)==int(rules.action_indices[_profile]):
        count=int(rules.get(_profile+"_count",2))
        if _difficulty=="RELAXED":count=maxi(1,count-1)
    return count

func _reserve_threat()->void:
    if combat.eta_us>2000000:return
    var preview:Dictionary=disruption.preview()
    if preview.is_empty() or preview.reserved:return
    var candidates:Array=resource_candidates() if preview.target_board=="LINE" else chain.target_candidates()
    disruption.reserve(combat.eta_us,candidates)

func resource_candidates()->Array:
    return swap.target_candidates() if resource_mode=="SWAP" else line.target_candidates()

func can_checkpoint()->bool:return not chain.is_resolving() and not (resource_mode=="SWAP" and swap.resolving) and _pending.is_empty() and queued_workspace.is_empty()

func snapshot()->Dictionary:
    if not can_checkpoint():return {}
    var result={"schema":"r3-session-v1","rules_hash":FileAccess.get_sha256(Supply.RULES_PATH),"seed":str(_seed),"run_id":_run_id,
        "difficulty":_difficulty,"profile":_profile,"mode":mode,"category":selected_category,"spawn_sequence":_spawn_sequence,
        "elapsed_us":elapsed_simulation_us,"last_cast":last_cast.duplicate(true),"metrics":metrics.duplicate(),
        "combat":combat.snapshot(),"line":line.snapshot(),"chain":chain.snapshot(),"supply":supply.snapshot(),"disruption":disruption.snapshot(),
        "casts":_casts.duplicate(true),"destruction_events":_destruction_events.duplicate(true)}
    if resource_mode=="SWAP":
        result.schema="r3-session-choice-v1"
        result["resource_mode"]=resource_mode
        result["swap"]=swap.export_state()
        result["resource_rewards"]=resource_rewards.snapshot()
    return result

func restore(data:Dictionary)->bool:
    var choice=data.get("schema")=="r3-session-choice-v1"
    if data.size()!=(22 if choice else 19) or data.get("schema") not in ["r3-session-v1","r3-session-choice-v1"] or data.get("rules_hash")!=FileAccess.get_sha256(Supply.RULES_PATH):return false
    if data.get("seed")!=str(_seed) or data.get("run_id")!=_run_id or data.get("difficulty")!=_difficulty or data.get("profile")!=_profile:return false
    if data.get("mode") not in ["LINE","CHAIN"] or data.get("category") not in ["ATK","DEF","SUP"]:return false
    if not Validation.valid_integer(data.get("spawn_sequence"),0,2147483647) or not Validation.valid_integer(data.get("elapsed_us"),0,9000000000000000):return false
    for key in ["combat","line","chain","supply","disruption","last_cast","metrics"]:
        if not data.get(key) is Dictionary:return false
    var candidate=get_script().new(_difficulty,_seed,_run_id,_profile)
    if choice:
        if data.get("resource_mode")!="SWAP" or not data.get("swap") is Dictionary or not data.get("resource_rewards") is Dictionary:return false
        candidate.command("prepare_resource",{"mode":"SWAP"})
        if not candidate.swap.load_state(data.swap,data.combat.get("outcome")!="RUNNING") or not candidate.resource_rewards.restore(data.resource_rewards):return false
    for key in ["combat","line","chain","supply","disruption"]:
        if not candidate.get(key).restore(data[key]):return false
    if candidate.chain.is_resolving():return false
    if (candidate.chain.phase=="TERMINAL")!=(candidate.combat.outcome!="RUNNING"):return false
    if data.chain.spawn_ids!=data.supply.spawns or data.chain.spawn_ids.size()!=int(data.spawn_sequence):return false
    if data.chain.namespace!=_run_id+":chain" or data.chain.seed!=str(hash("r3-chain:%d"%_seed)):return false
    if data.line.engine.shape_seed!=str(_seed) or data.line.engine.resource_seed!=str(hash("r2-resource:%d"%_seed)):return false
    if data.chain.selected_category!=data.category:return false
    for i in int(data.spawn_sequence):
        if data.chain.spawn_ids[i]!=_run_id+":pair:"+str(i+1):return false
    for fields in [["processed_line_event_ids","clears"],["processed_line_cell_ids","cells"]]:
        var supplied:Array=data.supply[fields[1]].duplicate()
        supplied.sort()
        if data.combat[fields[0]]!=supplied:return false
    if data.combat.run_id!=_run_id or data.combat.mode!=_difficulty:return false
    var preview:Dictionary=candidate.disruption.preview()
    if candidate.combat.outcome=="RUNNING" and (preview.is_empty() or preview.action_id!=candidate.combat.action_id()):return false
    if candidate.combat.outcome!="RUNNING" and not preview.is_empty():return false
    var completed_count:int=candidate.combat.action_index
    if candidate.combat.outcome=="DEFEAT" and candidate.combat.eta_us==0:completed_count+=1
    if data.disruption.completed.size()!=completed_count:return false
    for i in completed_count:
        if data.disruption.completed[i]!=_run_id+":"+str(i):return false
    if not preview.is_empty() and int(preview.count)!=candidate._destruction_count():return false
    if data.metrics.size()!=metrics.size():return false
    for key in metrics:
        if not Validation.valid_integer(data.metrics.get(key),0,2147483647):return false
    if not candidate._valid_ledgers(data):return false
    combat=candidate.combat
    line=candidate.line
    chain=candidate.chain
    supply=candidate.supply
    disruption=candidate.disruption
    resource_mode=candidate.resource_mode
    swap=candidate.swap
    resource_rewards=candidate.resource_rewards
    resource_locked=true
    mode=data.mode
    selected_category=data.category
    _spawn_sequence=int(data.spawn_sequence)
    elapsed_simulation_us=int(data.elapsed_us)
    last_cast=_normalize(data.last_cast)
    _casts=_normalize(data.casts)
    _destruction_events=data.destruction_events.duplicate(true)
    for key in metrics:metrics[key]=int(data.metrics[key])
    queued_workspace=""
    _pending=[]
    return true

func _valid_ledgers(data:Dictionary)->bool:
    if not data.get("casts") is Array or not data.get("destruction_events") is Array:return false
    if not _valid_cast_ledger(data):return false
    return _valid_resource_and_destruction_ledgers(data)

func _valid_cast_ledger(data:Dictionary)->bool:
    var ids:Array=[]
    var maximum=0
    var skills:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Supply.RULES_PATH)).skills
    for receipt in data.casts:
        if not receipt is Dictionary or not receipt.get("event_id") is String or receipt.event_id in ids:return false
        if receipt.event_id not in data.chain.processed_event_ids or not receipt.event_id.ends_with(":WAVE_RESOLVED"):return false
        if receipt.get("success")!=true or receipt.get("category") not in ["ATK","DEF","SUP"]:return false
        if not Validation.valid_integer(receipt.get("wave"),1,21) or not Validation.valid_integer(receipt.get("stage"),1,6):return false
        if int(receipt.stage)!=mini(int(receipt.wave),6):return false
        var power=int(skills[receipt.category][int(receipt.stage)-1])
        var common=["success","effect","reason","event_id","category","wave","stage"]
        var extra:Array=[]
        if receipt.category=="ATK":
            extra=["power","bank_consumed","damage_requested","damage_applied"]
            if receipt.get("effect")!="ATK_DAMAGE" or receipt.get("reason")!="":return false
            for field in extra:
                if not Validation.valid_integer(receipt.get(field),0,2147483647):return false
            if int(receipt.power)!=power or int(receipt.damage_requested)!=power+int(receipt.bank_consumed) or int(receipt.damage_applied)>int(receipt.damage_requested):return false
        elif receipt.category=="SUP":
            extra=["power","healing_requested","healing_applied"]
            if receipt.get("effect")!="SUP_HEAL" or receipt.get("reason")!="":return false
            for field in extra:
                if not Validation.valid_integer(receipt.get(field),0,100):return false
            if int(receipt.power)!=power or int(receipt.healing_requested)!=power or int(receipt.healing_applied)>power:return false
        else:
            extra=["ward_before","ward_after","ward_target"]
            if receipt.get("effect") not in ["DEF_WARD","DEF_NO_TARGET"] or not receipt.get("ward_target") is String:return false
            for field in ["ward_before","ward_after"]:
                if not Validation.valid_integer(receipt.get(field),0,100):return false
            if receipt.effect=="DEF_WARD":
                if receipt.get("reason")!="" or int(receipt.ward_after)!=maxi(int(receipt.ward_before),power):return false
            elif receipt.get("reason") not in ["NO_DAMAGE_ACTION","ACTION_COMMITTED","ACTION_FINISHED"] or receipt.ward_before!=receipt.ward_after:return false
        if receipt.size()!=common.size()+extra.size():return false
        ids.append(receipt.event_id)
        maximum=maxi(maximum,int(receipt.wave))
    var sorted=ids.duplicate()
    sorted.sort()
    if sorted!=data.combat.processed_cast_event_ids or ids.size()!=int(data.metrics.casts) or maximum!=int(data.metrics.max_combo):return false
    if data.last_cast!=({} if data.casts.is_empty() else data.casts[-1]):return false
    return true

func _valid_resource_and_destruction_ledgers(data:Dictionary)->bool:
    if resource_mode=="LINE" and int(data.metrics.line_clears)*10!=data.supply.cells.size():return false
    if int(data.metrics.supply_overflow)!=int(data.supply.discarded):return false
    if data.combat.processed_topout_event_ids.size()!=int(data.metrics.topouts):return false
    var line_prefix=_run_id+":line:line:"
    if resource_mode=="LINE":
        for id in data.supply.clears:
            if not _ordinal_id(id,line_prefix,int(data.line.engine.lock_sequence)):return false
        for id in data.supply.cells:
            if not _ordinal_id(id,_run_id+":line:",int(data.line.sequence)):return false
    else:
        if data.supply.clears!=resource_rewards.reward_events() or data.supply.cells!=resource_rewards.unit_ids() or int(data.metrics.line_clears)!=0:return false
        for event in data.resource_rewards.history:
            var prefix=_run_id+":swap:clear:"
            if not event.event_id.begins_with(prefix):return false
            var engine_id="chain:"+event.event_id.trim_prefix(prefix).replace(":",":wave:")
            if engine_id not in data.swap.engine.processed_event_ids:return false
            for cell in event.cells:
                if not _ordinal_id(cell.id,_run_id+":swap:",int(data.swap.sequence)):return false
                for row in data.swap.ids:
                    if cell.id in row:return false
    var total=0
    var destruction_ids:Array=[]
    for event in data.destruction_events:
        if not event is Dictionary or event.size()!=5 or not event.get("event_id") is String or event.event_id in destruction_ids:return false
        if event.event_id not in data.disruption.completed or event.get("target_board") not in ["LINE","CHAIN"]:return false
        var processed:Array=(data.swap.destructions if resource_mode=="SWAP" else data.line.destructions) if event.target_board=="LINE" else data.chain.processed_event_ids
        if event.event_id not in processed:return false
        for key in ["target_ids","removed_ids","missing_ids"]:
            if not event.get(key) is Array:return false
            var unique:Dictionary={}
            for id in event[key]:
                if not id is String or id.is_empty() or unique.has(id):return false
                unique[id]=true
        var partition:Array=event.removed_ids+event.missing_ids
        partition.sort()
        var targets:Array=event.target_ids.duplicate()
        targets.sort()
        if partition!=targets:return false
        total+=event.removed_ids.size()
        destruction_ids.append(event.event_id)
    return total==int(data.metrics.destroyed)

static func _ordinal_id(id:String,prefix:String,limit:int)->bool:
    if not id.begins_with(prefix):return false
    var suffix=id.substr(prefix.length())
    return suffix.is_valid_int() and str(int(suffix))==suffix and int(suffix)>0 and int(suffix)<=limit

static func _normalize(value):
    if value is float:return int(value)
    if value is Dictionary:
        var result={}
        for key in value:result[key]=_normalize(value[key])
        return result
    if value is Array:
        var result=[]
        for item in value:result.append(_normalize(item))
        return result
    return value

static func _failure(reason:String)->Dictionary:return {"success":false,"reason":reason}
