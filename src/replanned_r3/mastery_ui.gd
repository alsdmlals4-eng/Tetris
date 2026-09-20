## Read-only descriptions of the current authoritative skill supply and enemy status.
extends RefCounted
var s
func attach(screen)->void:
    s=screen
    s._label(s.get_node("Combat"),"PatternStatus",Rect2(16,252,590,29),"",17)
    var prep=s.get_node("Preparation")
    prep.position.y=85
    prep.size.y=550
    prep.get_node("Status").position.y=516
    var row=s._panel(prep,"LinePractice",Rect2(28,439,800,60))
    var kinds=["FOUR","SPIN","COMBO"]
    var labels=["4줄 클리어 연습","T스핀 더블 연습","연속 클리어 연습"]
    for i in 3:
        var kind=kinds[i]
        s._button(row,kind,Rect2(i*270,4,260,48),labels[i],func():s.start_line_practice(kind))
    prep.get_node("Balance").text="교체: 2칸 → 자원1 / 테트리스: 1칸 → 자원1\n테트리스 기술 보정: 추가 보급 · 1회 최대20 / 비교용 수치"

func refresh()->void:
    var session=s.session
    if not session.has_method("supply_report"):
        s.get_node("Combat/PatternStatus").text=""
        return
    var c=session.combat
    var status=[]
    if c.enemy_shield>0:status.append("적 장갑 %d · 다음 행동까지"%c.enemy_shield)
    if c.weakness_us>0:status.append("약점 %.1f초 · 다음 공격 +25%%"%(c.weakness_us/1000000.0))
    if c.current_action().pattern=="charge":status.append("차징 중단 %d / 20 피해"%c.charge_damage)
    s.get_node("Combat/PatternStatus").text=" / ".join(status)
    var current=c.current_action()
    var next=c.next_action()
    var descriptions={"shield":"장갑12 · 다음 행동까지","armor_break":"방어도 최대6 제거","charge":"준비 중 피해20 → 추가피해 취소","weakness":"이후8초 · 다음 공격 +25%","":""}
    if session.action.is_empty():
        var threat=c.threat_preview()
        s.get_node("Combat/Current").text+="\n피해 %d → HP %d · %s"%[current.damage,threat.damage_to_hp,descriptions[current.pattern]]
        s.get_node("Combat/Next").text+=" · 피해%d · %s"%[next.damage,descriptions[next.pattern]]
    var report=session.supply_report()
    if session.mode=="LINE" and session.resource_mode=="LINE":
        var help=s.get_node("Puzzle/Help")
        help.visible=true
        help.text="추가 보급\n\n4줄 +10\nT스핀 1/2/3줄\n+5 / +10 / +15\n\n연속 소거\n+2 → +4 → +6\n어려운 소거 연속 +5\n\n1회 최대 +20\n10단위 → 3쌍\n타일 자원과 별도"
        if not report.last.is_empty():
            var last=report.last
            var title="T스핀" if last.spin=="T_SPIN" else ("테트리스" if last.lines==4 else "%d줄"%last.lines)
            help.text=title+" · 보급 +%d\n연속 %d / B2B %s\n\n"%[last.units,last.combo,"ON" if last.b2b else "OFF"]+help.text
        if not session.line_practice.is_empty():
            var hints={"FOUR":"Space로 세로 I를 내려\n4줄을 한 번에 소거","SPIN":"회전 버튼 / ↑ 또는 X\n한 번 회전한 뒤 Space\nT스핀으로 두 줄 소거","COMBO":"Space로 첫 줄 소거\n다시 Space로 다음 줄\n연속2회 보급 +2"}
            help.text=("성공!\n기술 보급 +%d\n\n"%report.mastery_units if session.practice_complete() else hints[session.line_practice]+"\n\n")+"연습은 시간 제한 없음\n저장·전투에 영향 없음\n하단 연습 종료"
            for control in ["Switch","Hold"]:s.get_node("Puzzle/"+control).disabled=true
    if session.starter_preview().get("starter")=="A":
        var waves=maxi(1,int(session.starter_preview().waves))
        var hit=c.attack_preview(session.finisher_power("A",waves))
        s.get_node("Combat/Skills/Description").text="공격 예상 %d · 적 장갑 흡수 %d\n실제 HP 피해 %d / 현재 상태 기준\n%s"%[hit.damage_requested,hit.shield_absorbed,hit.damage_applied,"최근 공격 피해 %d"%session.last_cast.get("damage_applied",0) if not session.last_cast.is_empty() else "연쇄 종료 후 1회 발동"]
