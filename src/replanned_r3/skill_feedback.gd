## Presentation of authoritative receipts only; never computes or applies gameplay.
extends RefCounted
const PATH="res://data/replanned_r3/presentation.json"
var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PATH))

func skill(kind:String)->Dictionary:return config.skills.get(kind,{})

func effect(receipt:Dictionary)->String:
    if receipt.is_empty():return ""
    match String(receipt.get("starter","")):
        "A":
            var text="피해 %d"%int(receipt.get("damage_applied",0))
            if int(receipt.get("shield_absorbed",0))>0:text+=" · 적 장갑 흡수 %d"%int(receipt.shield_absorbed)
            if int(receipt.get("bank_consumed",0))>0:text+="\n공격 가산 %d 사용"%int(receipt.bank_consumed)
            return text
        "D":
            if receipt.get("effect")=="DEF_NO_TARGET":return "보호막 증가 0 · 적용 대상 없음"
            return "보호막 +%d · 현재 %d"%[maxi(0,int(receipt.get("ward_after",0))-int(receipt.get("ward_before",0))),int(receipt.get("ward_after",0))]
        "H":return "HP %d 회복%s"%[int(receipt.get("healing_applied",0))," · 체력 가득" if int(receipt.get("healing_applied",0))==0 else ""]
        "T":
            var reason={"EXTENSION_CAP_REACHED":" · 연장 상한","ACTION_COMMITTED":" · 적 행동 확정"}.get(receipt.get("reason",""),"")
            return "공유 시간 +%.2f초%s"%[float(receipt.get("time_applied_us",0))/1000000.0,reason]
    return ""

func refresh(screen)->void:
    var session=screen.session
    var preview:Dictionary=session.starter_preview()
    var last:Dictionary=session.last_cast
    var kind=String(preview.starter)
    var displayed=kind if not kind.is_empty() else String(last.get("starter",""))
    var item=skill(displayed)
    if item.is_empty():return
    screen.get_node("Combat/Skills/Icon").texture=screen.assets.texture(item.atlas,item.region)
    var lines=[]
    if not kind.is_empty():
        var waves=maxi(1,int(preview.waves))
        lines.append("%s · T%d · %s"%[item.name,mini(6,waves),item.role])
        var amount=session.finisher_power(kind,waves)
        if kind=="A" and session.combat.has_method("attack_preview"):
            lines.append("예상 HP 피해 %d · 현재 상태 기준"%int(session.combat.attack_preview(amount).damage_applied))
        elif kind=="T":lines.append("예상 최대 +%.2f초 · 상한 적용"%(amount/1000000.0))
        else:lines.append("예상 최대 %d · 실제 적용량은 발동 후 표시"%amount)
    if not last.is_empty():
        lines.append("최근 %s T%d · %s"%[skill(last.starter).name,last.stage,effect(last).replace("\n"," / ")])
    screen.get_node("Combat/Skills/Description").text="\n".join(lines)
    var view:Dictionary=session.action_view(screen.reduced_motion)
    if view.is_empty():return
    var caption=screen.get_node("Combat/CutIn/Caption")
    caption.position=Vector2(405,32)
    caption.size=Vector2(188,186)
    caption.add_theme_font_size_override("font_size",20)
    if view.owner=="ENEMY":
        caption.text="적 행동\n"+String(view.label)+("\n발동 완료" if view.applied else "\n발동 준비")
        return
    item=skill(view.starter)
    screen.get_node("Combat/CutIn/Effect").texture=screen.assets.texture(item.atlas,item.region)
    caption.text="%s\nT%d · %d연쇄\n%s"%[item.name,view.stage,view.wave,effect(last) if view.applied else item.role]
