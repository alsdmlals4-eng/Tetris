## Stateless starter selection and aggregate effect policy; no UI-owned effects.
extends RefCounted
const CONFIG="res://data/replanned_r3/finisher.json"
const RULES="res://data/replanned_r3/rules.json"
static var _config:Dictionary={}
static var _skills:Dictionary={}

static func config()->Dictionary:
    if _config.is_empty():_config=JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
    return _config.duplicate(true)

static func starter(cells:Array,axis_id:String)->String:
    if cells.is_empty():return ""
    for cell in cells:
        if cell.cell_id==axis_id:return cell.kind
    var counts={}
    var positions={}
    for cell in cells:
        counts[cell.kind]=int(counts.get(cell.kind,0))+1
        var position=int(cell.y)*6+int(cell.x)
        positions[cell.kind]=mini(int(positions.get(cell.kind,10000)),position)
    var kinds=counts.keys()
    kinds.sort_custom(func(a,b):return counts[a]>counts[b] if counts[a]!=counts[b] else positions[a]<positions[b])
    return kinds[0]

static func category(kind:String)->String:return config().category_by_kind.get(kind,"")

static func power(kind:String,waves:int)->int:
    var selected=category(kind)
    if selected.is_empty() or waves<1:return 0
    if _skills.is_empty():_skills=JSON.parse_string(FileAccess.get_file_as_string(RULES)).skills
    var values:Array=config().time_power_us if selected=="TIME" else _skills[selected]
    if selected in ["DEF","TIME"]:return int(values[mini(waves,6)-1])
    var total=0
    for wave in waves:total+=int(values[mini(wave,5)])
    return total

static func apply(combat,event_id:String,kind:String,waves:int,power_override:int=-1)->Dictionary:
    if combat.paused or combat.outcome!="RUNNING" or waves<1 or waves>21 or category(kind).is_empty():return {"success":false,"reason":"INVALID_FINISHER"}
    if event_id.is_empty() or combat._processed_cast_events.has(event_id):return {"success":false,"reason":"DUPLICATE_EVENT"}
    var amount=power(kind,waves) if power_override<0 else power_override
    var result={"success":true,"effect":"","reason":"","event_id":event_id,"category":category(kind),"starter":kind,"wave":waves,"stage":mini(waves,6),"power":amount}
    combat._processed_cast_events[event_id]=true
    match kind:
        "A":
            var bank:int=combat.attack_bank
            var applied=mini(amount+bank,combat.boss_hp)
            combat.attack_bank=0
            combat.boss_hp-=applied
            if combat.boss_hp==0:combat.outcome="VICTORY"
            result.merge({"effect":"ATK_DAMAGE","bank_consumed":bank,"damage_requested":amount+bank,"damage_applied":applied},true)
        "H":
            var applied=mini(amount,combat.MAX_HP-combat.hp)
            combat.hp+=applied
            result.merge({"effect":"SUP_HEAL","healing_requested":amount,"healing_applied":applied},true)
        "D":
            var reason:String=combat.def_target_reason()
            var before:int=combat.ward
            if reason.is_empty():
                combat.ward=maxi(before,amount)
                combat.ward_target=combat.action_id()
            result.merge({"effect":"DEF_WARD" if reason.is_empty() else "DEF_NO_TARGET","reason":reason,"ward_before":before,"ward_after":combat.ward,"ward_target":combat.ward_target},true)
        "T":
            var reason=""
            var applied=0
            if combat._is_action_committed():reason="ACTION_COMMITTED"
            else:
                applied=mini(amount,combat._extension_cap_us-combat.extension_us)
                if applied<amount:reason="EXTENSION_CAP_REACHED"
                combat.extension_us+=applied
                combat.eta_us+=applied
            result.merge({"effect":"TIME_DELAY","reason":reason,"time_requested_us":amount,"time_applied_us":applied},true)
    return result
