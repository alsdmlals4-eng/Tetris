## Actual scene/renderer/dispatch evidence; fixtures are not human balance evidence.
extends SceneTree
var screen
var output="res://docs/validation/short-expedition-20260921"
var shots=[]
func _initialize():call_deferred("run_probe")
func capture(label:String):
    if screen.battle!=null:screen.battle.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    var picture=root.get_texture().get_image()
    assert(picture.save_png(output+"/"+label+".png")==OK)
    shots.append({"label":label,"width":picture.get_width(),"height":picture.get_height()})

func guard_fixture():
    var s=screen.battle.session
    for x in 4:s.chain.cells.append(s.chain._new_cell(x,11,"D"))
    screen.battle.dispatch("switch")
    s.chain.active_pair.axis.kind="H";s.chain.active_pair.satellite.kind="T"
    for i in 3:screen.battle.dispatch("move",{"dx":1})
    screen.battle.dispatch("hard_drop")

func run_probe():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=load("res://scenes/replanned_r3/short_expedition.tscn").instantiate()
    screen.disk=load("res://src/replanned_r3/short_expedition_save.gd").new("user://short-native-probe/save.json")
    root.add_child(screen);current_scene=screen;screen.set_process(false)
    root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    for size in [Vector2i(1280,720),Vector2i(960,540)]:
        root.size=size
        var suffix="-"+str(size.x)
        screen.run=null;screen.show_menu()
        await capture("menu"+suffix)
        screen.start_run("SWAP","RELAXED",42)
        await capture("route"+suffix)
        screen.launch("outer_breach");screen.battle.set_process(false)
        guard_fixture()
        screen.battle._process(0.801)
        await capture("defense-impact"+suffix)
        screen.battle._process(2.0)
        var s=screen.battle.session
        s.combat.ward=0;s.combat.ward_target="";s.combat.armor=0
        screen.battle._process(s.combat.eta_us/1000000.0+0.601)
        assert(s.combat.counter_state().prevented>0)
        await capture("counter-impact"+suffix)
        screen.battle._process(1.0)
        s.command("pause")
        assert(screen.save_checkpoint().success)
        assert(screen.restore_checkpoint().success)
        screen.battle.set_process(false)
        await capture("restored"+suffix)
        s=screen.battle.session;s.combat.paused=false
        s.combat.boss_hp=0;s.combat.outcome="VICTORY";s._finalize_terminal()
        screen._process(0)
        assert(screen.run.view().phase=="SUPPLY")
        await capture("reward"+suffix)
        screen.choose_supply("armor")
        await capture("branch"+suffix)
        screen.launch("watchtower");screen.battle.set_process(false)
        s=screen.battle.session;s.combat.boss_hp=0;s.combat.outcome="VICTORY";s._finalize_terminal();screen._process(0)
        screen.choose_supply("attack");screen.launch("rift_core");screen.battle.set_process(false)
        s=screen.battle.session;s.combat.boss_hp=0;s.combat.outcome="VICTORY";s._finalize_terminal();screen._process(0)
        assert(screen.run.view().phase=="COMPLETE")
        await capture("complete"+suffix)
        screen.start_run("LINE","STANDARD",43);screen.launch("outer_breach");screen.battle.set_process(false)
        s=screen.battle.session;s.combat.hp=0;s.combat.outcome="DEFEAT";s._finalize_terminal();screen._process(0)
        await capture("defeat"+suffix)
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"scene":"short_expedition.tscn","screenshots":shots,"input":"real dispatch/process with authored fixtures; terminal HP forced for phase coverage","human_fun":"NOT_RUN","device_keyboard":"NOT_RUN"},"  "));file.close()
    screen.queue_free();await process_frame;quit()
