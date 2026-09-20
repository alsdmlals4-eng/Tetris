## Opt-in resource-choice successor. Legacy R3 sessions/saves retain their rules.
extends "res://src/replanned_r3/r3_session.gd"
const Finisher=preload("res://src/replanned_r3/r3_finisher.gd")
var action:Dictionary={}
var _bundle:Dictionary={}
var _axis_id=""
var _preview_revision=-1
var _preview_board
var _preview:Dictionary={}

func command(name:String,args:Dictionary={})->Dictionary:
    if name=="category":return _failure("STARTER_DETERMINES_SKILL")
    # Releasing a held key is state cleanup, not a puzzle action during cut-in.
    if name=="soft_drop" and args.get("enabled") is bool and not args.enabled:
        return chain.command(name,args)
    if name=="resume" and not action.is_empty():
        combat.paused=false
        return {"success":true}
    if name not in ["pause","resume"] and not action.is_empty():return _failure("ACTION_PRESENTATION_LOCKED")
    return super.command(name,args)

func _board_blocked()->bool:return not action.is_empty()

func can_checkpoint()->bool:return action.is_empty() and _bundle.is_empty() and super.can_checkpoint()

func _finalize_terminal()->Array:
    if combat.outcome!="RUNNING":_bundle={}
    return super._finalize_terminal()

func _resolve_player_wave(plan:Dictionary)->Array:
    _bundle.wave_ids.append(plan.event_id)
    return []

func _after_chain_commit(plan:Dictionary)->void:
    if plan.type=="LOCK_PAIR":_axis_id=plan.cells[0].cell_id
    if plan.type=="CLEAR_CELLS" and plan.cause=="PLAYER_LOCK" and _bundle.is_empty():
        _bundle={"starter":Finisher.starter(plan.cells,_axis_id),"wave_ids":[],"first_cells":plan.cells.duplicate(true),"axis_id":_axis_id,"chain_id":chain.chain_id}
    if not chain.is_resolving() and not _bundle.is_empty() and combat.outcome=="RUNNING":
        var rules=Finisher.config()
        var waves:int=_bundle.wave_ids.size()
        action={"owner":"PLAYER","elapsed_us":0,"impact_us":int(rules.player_impact_us),"duration_us":int(rules.high_chain_duration_us if waves>=int(rules.high_chain_min) else rules.player_duration_us),"applied":false,"bundle":_bundle.duplicate(true)}
        _bundle={}

func starter_preview()->Dictionary:
    var bundle:Dictionary=action.get("bundle",_bundle)
    if not bundle.is_empty():return {"starter":bundle.starter,"waves":bundle.wave_ids.size(),"locked":true}
    if chain.active_pair.is_empty():return {"starter":"","waves":0,"locked":false}
    if _preview_board==chain and _preview_revision==chain.revision:return _preview.duplicate()
    # Run the actual lock/compact rule on a detached model, including split landing.
    var preview=Chain.new(hash("r3-chain:%d"%_seed),_run_id+":chain")
    if not preview.restore(chain.snapshot()):return {"starter":"","waves":0,"locked":false}
    var axis=String(preview.active_pair.axis.cell_id)
    preview.command("hard_drop")
    preview.commit(preview.plan_due_event())
    _preview={"starter":Finisher.starter(preview.matched_cells(),axis),"waves":1,"locked":false}
    _preview_board=chain
    _preview_revision=chain.revision
    return _preview.duplicate()

func tick(delta_us:int)->Array:
    if delta_us<0:return [_failure("INVALID_DELTA")]
    if combat.paused:return []
    var events:Array=[]
    var remaining=delta_us
    if delta_us>0:resource_locked=true
    while remaining>0:
        if not action.is_empty():
            var boundary=int(action.duration_us) if action.applied else int(action.impact_us)
            var step=mini(remaining,boundary-int(action.elapsed_us))
            action.elapsed_us+=step
            remaining-=step
            if not action.applied and int(action.elapsed_us)>=int(action.impact_us):
                action.applied=true
                events.append_array(_impact())
            if int(action.elapsed_us)>=int(action.duration_us):
                action={}
                if combat.outcome!="RUNNING":
                    _bundle={}
                    events.append_array(_finalize_terminal())
            continue
        if combat.outcome!="RUNNING":break
        _reserve_threat()
        # A committed enemy deadline wins over a board event at the same instant.
        if combat.eta_us==0:
            _start_enemy()
            continue
        events.append_array(_drain_board())
        if not action.is_empty():continue
        if combat.outcome!="RUNNING":break
        var step=mini(remaining,combat.eta_us)
        if not disruption.preview().get("reserved",false) and combat.eta_us>2000000:step=mini(step,combat.eta_us-2000000)
        if mode=="LINE" and resource_mode=="LINE":step=mini(step,line.next_event_us())
        if resource_mode=="SWAP" and swap.resolving:step=mini(step,swap.next_wave_remaining_us)
        var due:int=chain.next_event_us() if mode=="CHAIN" or chain.is_resolving() else -1
        if due>=0:step=mini(step,due)
        if step<=0:
            events.append(_failure("UNRESOLVED_ZERO_TIME_EVENT"))
            break
        if mode=="LINE" and resource_mode=="LINE":line.advance_time(step)
        if resource_mode=="SWAP" and swap.resolving:swap.advance_time(step)
        if mode=="CHAIN" or chain.is_resolving():chain.advance_time(step)
        combat.eta_us-=step
        elapsed_simulation_us+=step
        remaining-=step
        _reserve_threat()
        if combat.eta_us==0:_start_enemy()
        else:events.append_array(_drain_board())
    return events

func _start_enemy()->void:
    var rules=Finisher.config()
    action={"owner":"ENEMY","label":combat.current_action().get("label","적 공격"),"elapsed_us":0,"impact_us":int(rules.enemy_impact_us),"duration_us":int(rules.enemy_duration_us),"applied":false}

func _impact()->Array:
    if action.owner=="PLAYER":
        var bundle:Dictionary=action.bundle
        var id=String(bundle.wave_ids[-1])+":FINISHER"
        var cast=Finisher.apply(combat,id,bundle.starter,bundle.wave_ids.size())
        if cast.success:
            cast.merge({"wave_ids":bundle.wave_ids.duplicate(),"first_cells":bundle.first_cells.duplicate(true),"axis_id":bundle.axis_id,"chain_id":bundle.chain_id})
            _record_cast(cast)
        return [cast]
    # Resolve at the already-reached deadline; this is not another simulation tick.
    var resolved:Dictionary=combat._resolve_current_action()
    combat._action_finished=true
    var payload:Dictionary=disruption.commit()
    if combat.outcome=="RUNNING":
        if payload.success:_pending.append(payload)
        combat._schedule_next_action()
        _begin_threat()
    else:
        _bundle={}
        _pending.clear()
    return [resolved]

func action_view(reduced_motion:bool=false)->Dictionary:
    if action.is_empty():return {}
    var elapsed=int(action.elapsed_us)
    var impact=int(action.impact_us)
    var duration=int(action.duration_us)
    var phase="entrance" if elapsed<impact else ("impact" if elapsed<impact+350000 else "exit")
    var kind=String(action.bundle.starter) if action.owner=="PLAYER" else ""
    var waves=action.bundle.wave_ids.size() if action.owner=="PLAYER" else 0
    var fade=1.0 if reduced_motion else (minf(1.0,float(elapsed)/200000.0) if elapsed<impact else minf(1.0,float(duration-elapsed)/300000.0))
    return {"owner":action.owner,"category":Finisher.category(kind),"starter":kind,"stage":mini(waves,6),"wave":waves,"phase":phase,"alpha":fade,"offset_x":0.0 if reduced_motion else -60.0*(1.0-fade),"label":action.get("label",""),"applied":action.applied}

func snapshot()->Dictionary:
    var result=super.snapshot()
    if result.is_empty():return result
    result.schema="r3-finisher-choice-v1" if resource_mode=="SWAP" else "r3-finisher-v1"
    result["finisher_hash"]=FileAccess.get_sha256(Finisher.CONFIG)
    return result

func restore(data:Dictionary)->bool:
    if data.get("schema") not in ["r3-finisher-v1","r3-finisher-choice-v1"] or data.get("finisher_hash")!=FileAccess.get_sha256(Finisher.CONFIG):return false
    var copy=data.duplicate(true)
    copy.schema="r3-session-choice-v1" if data.schema=="r3-finisher-choice-v1" else "r3-session-v1"
    copy.erase("finisher_hash")
    if not super.restore(copy):return false
    action={}
    _bundle={}
    _axis_id=""
    return true

func _valid_cast_ledger(data:Dictionary)->bool:
    var ids:Array=[]
    var waves_seen:Array=[]
    var maximum=0
    var previous_chain=0
    var first_ids=[]
    for cast in data.casts:
        if not cast is Dictionary or not cast.get("wave_ids") is Array or cast.wave_ids.is_empty() or cast.wave_ids.size()>21:return false
        if not cast.get("first_cells") is Array or cast.first_cells.size()<4 or not cast.get("axis_id") is String:return false
        if not _ordinal_id(cast.axis_id,_run_id+":chain:cell:",int(data.chain.next_cell_id)):return false
        if not Validation.valid_integer(cast.get("chain_id"),previous_chain+1,int(data.chain.chain_id)):return false
        previous_chain=int(cast.chain_id)
        if cast.get("starter") not in ["A","D","H","T"] or cast.get("category")!=Finisher.category(cast.starter):return false
        if not Validation.valid_integer(cast.get("wave"),1,21) or int(cast.wave)!=cast.wave_ids.size() or cast.get("stage")!=mini(int(cast.wave),6):return false
        if cast.get("event_id")!=str(cast.wave_ids[-1])+":FINISHER" or cast.event_id in ids:return false
        for id in cast.wave_ids:
            if not id is String or id in waves_seen or id not in data.chain.processed_event_ids or not id.ends_with(":WAVE_RESOLVED"):return false
            waves_seen.append(id)
        var seen=[]
        for cell in cast.first_cells:
            if not cell is Dictionary or cell.size()!=4 or not cell.get("cell_id") is String or cell.cell_id in seen:return false
            if not _ordinal_id(cell.cell_id,_run_id+":chain:cell:",int(data.chain.next_cell_id)):return false
            if cell.get("kind") not in ["A","D","H","T"] or not Validation.valid_integer(cell.get("x"),0,5) or not Validation.valid_integer(cell.get("y"),-2,11):return false
            seen.append(cell.cell_id)
            if cell.cell_id in first_ids:return false
            first_ids.append(cell.cell_id)
            for live in data.chain.cells:
                if live.cell_id==cell.cell_id:return false
        if chain._matched_cells_in(cast.first_cells).size()!=cast.first_cells.size():return false
        if Finisher.starter(cast.first_cells,cast.axis_id)!=cast.starter:return false
        # Recompute the exact receipt against a bounded isolated pre-effect state.
        var probe=Combat.new(_difficulty,_run_id,_profile)
        if cast.starter=="A":
            for key in ["bank_consumed","damage_applied"]:
                if not Validation.valid_integer(cast.get(key),0,2147483647):return false
            probe.attack_bank=int(cast.bank_consumed)
            probe.boss_hp=int(cast.damage_applied)
        elif cast.starter=="H":
            if not Validation.valid_integer(cast.get("healing_applied"),0,100):return false
            probe.hp=100-int(cast.healing_applied)
        elif cast.starter=="D":
            if not Validation.valid_integer(cast.get("ward_before"),0,100) or not cast.get("ward_target") is String:return false
            probe.ward=int(cast.ward_before)
            probe.ward_target=cast.ward_target
            if cast.get("reason")=="ACTION_COMMITTED":probe.eta_us=0
            elif cast.get("reason")=="ACTION_FINISHED":probe._action_finished=true
            elif cast.get("reason")=="NO_DAMAGE_ACTION":
                for i in probe._actions.size():
                    if int(probe._actions[i].get("damage",0))==0:probe.action_index=i;break
            elif cast.get("reason")=="":
                var suffix=String(cast.ward_target).trim_prefix(_run_id+":")
                if not cast.ward_target.begins_with(_run_id+":") or not suffix.is_valid_int():return false
                probe.action_index=int(suffix)
        else:
            if not Validation.valid_integer(cast.get("time_applied_us"),0,1500000):return false
            if cast.get("reason")=="ACTION_COMMITTED":probe.eta_us=0
            else:probe.extension_us=probe._extension_cap_us-int(cast.time_applied_us)
        var expected=Finisher.apply(probe,cast.event_id,cast.starter,int(cast.wave))
        var core=cast.duplicate(true)
        for key in ["wave_ids","first_cells","axis_id","chain_id"]:core.erase(key)
        for value in core.values():
            if value is float or value is int:
                if not Validation.valid_integer(value,0,2147483647):return false
        if _normalize(core)!=expected:return false
        ids.append(cast.event_id)
        maximum=maxi(maximum,int(cast.wave))
    var sorted=ids.duplicate()
    sorted.sort()
    return sorted==data.combat.processed_cast_event_ids and ids.size()==int(data.metrics.casts) and maximum==int(data.metrics.max_combo) and data.last_cast==({} if data.casts.is_empty() else data.casts[-1])
