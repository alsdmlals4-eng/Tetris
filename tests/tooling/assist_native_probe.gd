## Native renderer evidence. Presentation fixtures are explicitly distinct from earned gameplay.
extends SceneTree
var screen
var output="res://docs/validation/bonus-assist-20260920"
var shots=[]
func _initialize():call_deferred("run")
func capture(label:String):
    screen.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)
    shots.append(label)
func legal_move(board)->Dictionary:
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
func advance(us:int):
    screen.assist_ui.before_tick()
    var events=screen.session.tick(us)
    screen.assist_ui.observe(events,us)
func run():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    screen.preference_path="user://assist-native-probe/preference.cfg"
    screen.disk=load("res://src/replanned_r3/r3_save.gd").new("user://assist-native-probe/save.json","user://assist-native-probe/options.json")
    root.add_child(screen)
    current_scene=screen
    root.content_scale_size=Vector2i(1280,720)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.size=Vector2i(1280,720)
    screen.set_process(false)
    await capture("preparation")
    screen.start_chain_practice()
    await capture("two-chain-practice")
    screen.dispatch("hard_drop")
    advance(1250000)
    assert(screen.session.metrics.casts==1 and screen.session.last_cast.wave==2)
    await capture("practice-t2-impact")
    screen.end_chain_practice()
    screen.preferred_encounter="outer_breach"
    screen.start_resource_battle("SWAP")
    var s=screen.session
    for attempt in 40:
        if s.bonus_balance()>=4:break
        assert(screen.dispatch("resource_swap",legal_move(s.swap)).success)
        for wave in 64:
            if not s.swap.resolving:break
            advance(300000)
    assert(s.bonus_balance()>=4)
    var earned=s.bonus_balance()
    assert(screen.dispatch("switch").success)
    # Real generated pairs are placed through commands, not inserted into the board.
    screen.dispatch("hard_drop")
    screen.dispatch("bonus_open")
    for i in 40:
        if s.assist_open:break
        if s.chain.phase=="FALLING":screen.dispatch("hard_drop")
        advance(100000)
    assert(s.assist_open and not s.chain.cells.is_empty())
    var cell=s.chain.cells[0]
    screen.assist_ui.select(Vector2i(cell.x,cell.y))
    var eta=s.combat.eta_us
    advance(2000000)
    assert(s.combat.eta_us==eta)
    await capture("bonus-selection")
    root.size=Vector2i(960,540)
    await capture("bonus-selection-960")
    root.size=Vector2i(1280,720)
    var kind="D" if cell.kind=="A" else "A"
    screen.assist_ui.apply({"operation":"change","cell_id":cell.cell_id,"kind":kind})
    assert(s.bonus_balance()==earned-2)
    for i in 40:
        if s.can_checkpoint():break
        advance(100000)
    screen.dispatch("pause")
    assert(screen.save_checkpoint().success)
    assert(screen.restore_checkpoint().success)
    s=screen.session
    assert(s.bonus_balance()==earned-2)
    screen.dispatch("resume")
    screen.dispatch("switch")
    for i in 3000:
        advance(16667)
        if screen.assist_ui.shatter_us>0:break
    assert(s.metrics.destroyed>0)
    assert(screen.assist_ui.shatter_us>0)
    await capture("enemy-destruction")
    # Six-tier comparison fixtures validate presentation only, not earned six-chain skill.
    for tier in [1,3,6]:
        var ids=[]
        for i in tier:ids.append("visual-fixture-"+str(i))
        s.action={"owner":"PLAYER","elapsed_us":650000,"impact_us":500000,"duration_us":s._player_duration(tier),"applied":true,"bundle":{"starter":"A","wave_ids":ids}}
        await capture("tier-%d-presentation-fixture"%tier)
    var receipt={"renderer":RenderingServer.get_video_adapter_name(),"viewports":[[1280,720],[960,540]],"scene":"resource_choice.tscn","screenshots":shots,"practice_two_wave_one_cast":true,"actual_swap_earned_bonus":earned,"selected_change_cost":2,"selection_freezes_both_clocks":true,"paid_correction_disk_roundtrip":true,"enemy_destroyed":s.metrics.destroyed,"tier_1_3_6":"PRESENTATION_FIXTURE_ONLY","human_fun":"NOT_RUN","save_namespace":"user://assist-native-probe"}
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt,"  "))
    file.close()
    screen.queue_free()
    await process_frame
    quit()
