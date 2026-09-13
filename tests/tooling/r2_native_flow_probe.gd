## Test-only actual-command flow probe. Not human play or physical-device evidence.
extends RefCounted
const Driver=preload("res://tests/tooling/r2_expedition_runtime_driver.gd")

func visible_bounds(root: Node) -> Array:
    var failures=[]
    for child in root.get_children():
        if child is Control and child.is_visible_in_tree() and (child is Label or child is Button or child is Panel):
            var rect=child.get_global_rect()
            if rect.position.x < -1 or rect.position.y < -1 or rect.end.x > 1281 or rect.end.y > 721:
                failures.append(String(child.get_path())+":OUTSIDE_1280x720")
        failures.append_array(visible_bounds(child))
    return failures

func run_case(screen, font_scale: int, window_size: Vector2i, middle_choice: int) -> Dictionary:
    if screen==null: return {"ok":false,"failures":["SCREEN_REQUIRED"]}
    if font_scale not in [100,125] or window_size not in [Vector2i(1280,720),Vector2i(1920,1080)] or middle_choice not in [0,1]:
        return {"ok":false,"failures":["UNSUPPORTED_CASE"]}
    var failures=[]
    var checks=[]
    screen.set_process(false)
    screen.disk=screen.Disk.new("user://replanned_r2_tests/native-matrix/save.json","user://replanned_r2_tests/native-matrix/options.json")
    screen.expedition_disk=screen.ExpeditionDisk.new("user://replanned_r2_tests/native-matrix/expedition.json")
    screen.options=screen.Disk.default_options()
    screen.options.font_scale=font_scale
    screen.options.audio={"effects":0,"music":0}
    screen.audio.configure(screen.options.audio)
    screen.get_window().size=window_size
    screen._apply_font()
    screen.start_expedition("STANDARD",83)
    var expected_encounters=[screen.expedition.available_encounters()[0]]
    checks.append("ROUTE")
    failures.append_array(visible_bounds(screen))
    screen._choose_expedition(0)
    if screen.page!="battle": return {"ok":false,"failures":["FIRST_BATTLE_NOT_ENTERED"]}
    checks.append("LINE")
    failures.append_array(visible_bounds(screen))
    if screen.get_node("Battle/Puzzle").size.x!=screen.get_node("Battle/Combat").size.x: failures.append("COLUMN_RATIO")
    var switched=screen.dispatch("switch")
    if not switched.success or screen.session.mode!="CHAIN": failures.append("SWITCH_NOT_CHAIN")
    checks.append("CHAIN")
    failures.append_array(visible_bounds(screen))
    var eta=screen.session.combat.eta_us
    var run_id=screen.session.run_id
    screen.pause_game()
    screen.advance_seconds(30)
    if screen.session.combat.eta_us!=eta: failures.append("PAUSE_ADVANCED_CLOCK")
    if not screen.checkpoint().success: return {"ok":false,"failures":["CHECKPOINT_FAILED"]}
    var previous_session=screen.session
    screen.continue_expedition()
    var restored_new_session=screen.session!=previous_session
    if not restored_new_session: failures.append("RESTORE_DID_NOT_REPLACE_SESSION")
    if not screen.session.combat.paused or screen.session.combat.eta_us!=eta or screen.session.run_id!=run_id:
        failures.append("RESTORE_IDENTITY_CLOCK_PAUSE")
    checks.append("PAUSED_RESTORE")
    failures.append_array(visible_bounds(screen))
    screen.resume_game()
    var driver=Driver.new()
    for battle in 3:
        var result=driver.drive_one_battle(screen)
        if not result.success:
            failures.append("DRIVER:"+String(result.get("reason","")))
            break
        var phase=screen.expedition.view().phase
        checks.append(phase)
        failures.append_array(visible_bounds(screen))
        if battle<2:
            if phase!="SUPPLY":
                failures.append("UNEXPECTED_"+phase)
                break
            screen._choose_expedition(0)
            if screen.page!="expedition" or screen.expedition.view().phase!="ROUTE":
                failures.append("INTERMISSION_NOT_ROUTE")
                break
            checks.append("FORK_ROUTE" if battle==0 else "FINAL_ROUTE")
            failures.append_array(visible_bounds(screen))
            var choice=middle_choice if battle==0 else 0
            var available=screen.expedition.available_encounters()
            if choice>=available.size():
                failures.append("ROUTE_CHOICE_UNAVAILABLE")
                break
            expected_encounters.append(available[choice])
            screen._choose_expedition(choice)
            if screen.expedition.view().active_battle.get("encounter_id","")!=available[choice]:
                failures.append("LAUNCHED_WRONG_ENCOUNTER")
                break
    var ending=screen.expedition.view()
    if ending.phase!="COMPLETE": failures.append("NOT_COMPLETE")
    if ending.route!=expected_encounters: failures.append("ENDING_ROUTE_MISMATCH")
    if screen.get_window().size!=window_size: failures.append("WINDOW_SIZE_NOT_APPLIED")
    return {"ok":failures.is_empty(),"failures":failures,"checks":checks,
        "font_scale":font_scale,"window_size":[window_size.x,window_size.y],"middle_choice":middle_choice,
        "actual_window_size":[screen.get_window().size.x,screen.get_window().size.y],"restored_new_session":restored_new_session,
        "actual_encounters":ending.route,"expected_encounters":expected_encounters,
        "ending_phase":ending.phase,"hp":ending.hp,"synthetic_commands_not_human":true,
        "user_data_scope":"replanned_r2_tests/native-matrix"}
