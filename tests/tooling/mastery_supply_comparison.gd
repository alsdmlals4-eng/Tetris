## Reproducible diagnostic driver. Equal scripted decision interval is NOT human throughput.
extends SceneTree
const Session=preload("res://src/replanned_r3/mastery_session.gd")
func _initialize():call_deferred("run")
static func line_choice(s)->Dictionary:
    var best={}
    var best_score=INF
    for rotation in 4:
        for shift in range(-5,6):
            var probe=s.line.get_script().new(s._seed,s._run_id+":line")
            if not probe.restore(s.line.snapshot()):return {}
            for i in rotation:probe.rotate(1)
            for i in absi(shift):probe.move(signi(shift))
            var plan=probe.hard_drop_plan()
            if plan.get("topout",false):continue
            probe.commit_lock()
            var holes=0
            var height=0
            var peak=0
            for x in 10:
                var occupied=false
                for y in 24:
                    if not probe._engine.board.get_cell(Vector2i(x,y)).is_empty():
                        if not occupied:height+=24-y;peak=maxi(peak,24-y)
                        occupied=true
                    elif occupied:holes+=1
            var score=holes*30+height+peak*2-plan.rows.size()*8
            if score<best_score:
                best_score=score
                best={"rotation":rotation,"shift":shift}
    return best
static func swap_choice(board)->Dictionary:
    for y in 8:
        for x in 8:
            for d in [Vector2i.RIGHT,Vector2i.DOWN]:
                var a=Vector2i(x,y)
                var b=a+d
                if b.x>=8 or b.y>=8:continue
                board._swap(a,b)
                var ok=not board.matched_cells().is_empty()
                board._swap(a,b)
                if ok:return {"a":a,"b":b}
    return {}
func run():
    var rows=[]
    for producer in ["LINE","SWAP"]:
        var s=Session.new("RELAXED",42,"comparison","outer_breach")
        s.command("prepare_resource",{"mode":producer})
        for step in 20:
            if s.combat.outcome!="RUNNING":break
            if s.action.is_empty():
                if producer=="LINE":
                    var choice=line_choice(s)
                    assert(not choice.is_empty())
                    for i in choice.rotation:s.command("rotate",{"direction":1})
                    for i in absi(choice.shift):s.command("move",{"dx":signi(choice.shift)})
                    s.command("hard_drop")
                elif not s.swap.resolving:
                    var choice=swap_choice(s.swap)
                    if not choice.is_empty():s.command("resource_swap",choice)
            s.tick(1500000)
        for i in 40:
            if s.can_checkpoint():break
            s.tick(100000)
        assert(s.can_checkpoint())
        var report=s.supply_report()
        report["scripted_wall_us"]=30000000
        report["decision_interval_us"]=1500000
        report["policy"]="lowest weighted holes/height LINE; first legal SWAP; no CHAIN spending"
        var restored=Session.new("RELAXED",42,"comparison","outer_breach")
        assert(restored.restore(JSON.parse_string(JSON.stringify(s.snapshot()))))
        report["save_roundtrip"]=true
        rows.append(report)
    var directory="res://docs/validation/mastery-patterns-20260921"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
    var file=FileAccess.open(directory+"/supply-comparison.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"classification":"SCRIPTED_DIAGNOSTIC_NOT_HUMAN_BALANCE","rows":rows},"  "))
    file.close()
    print(JSON.stringify(rows))
    quit()
