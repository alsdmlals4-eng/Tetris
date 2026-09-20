## Actual native renderer, isolated saves; authored puzzle fixture uses real commands.
extends SceneTree
var screen
var output="res://docs/validation/starter-finisher-20260920"

func _initialize():call_deferred("run")

func capture(label:String):
    screen.refresh()
    await process_frame
    await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/"+label+".png")==OK)

func run():
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    screen=load("res://scenes/replanned_r3/resource_choice.tscn").instantiate()
    screen.preference_path="user://finisher-native-probe/preference.cfg"
    screen.disk=load("res://src/replanned_r3/r3_save.gd").new("user://finisher-native-probe/save.json","user://finisher-native-probe/options.json")
    root.add_child(screen)
    current_scene=screen
    root.content_scale_size=Vector2i(1280,720)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.size=Vector2i(1280,720)
    screen.set_process(false)
    screen.start_resource_battle("LINE")
    var s=screen.session
    s.combat.hp=60
    s.combat.boss_hp=100
    s.combat.attack_bank=6
    var lines=["HH....","AA....","AAHH.."]
    for row in lines.size():
        for x in 6:
            if lines[row][x]!=".":s.chain.cells.append(s.chain._new_cell(x,9+row,lines[row][x]))
    screen.dispatch("switch")
    s.chain.active_pair.axis.kind="H"
    s.chain.active_pair.satellite.kind="T"
    for i in 3:screen.dispatch("move",{"dx":1})
    await capture("starter-preview")
    screen.dispatch("hard_drop")
    s.tick(180000)
    await capture("starter-locked")
    s.tick(420000+650000)
    assert(s.metrics.casts==1 and s.combat.boss_hp==84)
    var frozen_eta=s.combat.eta_us
    await capture("player-impact")
    s.tick(750000)
    assert(s.combat.eta_us==frozen_eta)
    screen.dispatch("pause")
    assert(screen.save_checkpoint().success)
    assert(screen.restore_checkpoint().success)
    s=screen.session
    assert(s.metrics.casts==1 and s.action.is_empty())
    screen.dispatch("resume")
    s.combat.eta_us=100000
    s.tick(100000+700000)
    assert(s.action.owner=="ENEMY" and s.action.applied)
    await capture("enemy-impact")
    s.tick(900000)
    screen.dispatch("pause")
    root.size=Vector2i(960,540)
    await capture("paused-960")
    var receipt={"renderer":RenderingServer.get_video_adapter_name(),"viewports":[[1280,720],[960,540]],"resource_entry":"resource_choice.tscn","starter":"A","two_chain_casts":s.metrics.casts,"boss_hp_after_finisher":84,"attack_bank_consumed":6,"same_eta_during_recovery":true,"enemy_contact_and_recovery":true,"disk_roundtrip":true,"manual_category_nodes":false,"storage":"user://finisher-native-probe","human_fun":"NOT_RUN"}
    var file=FileAccess.open(output+"/runtime.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(receipt,"  "))
    file.close()
    screen.queue_free()
    await process_frame
    quit()
