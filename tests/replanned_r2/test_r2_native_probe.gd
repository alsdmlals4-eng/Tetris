extends GutTest

func test_native_probe_rejects_invalid_case_before_mutation():
    var script=load("res://tests/tooling/r2_native_flow_probe.gd")
    assert_not_null(script)
    if script==null: return
    var probe=script.new()
    var result=probe.run_case(null,100,Vector2i(1280,720),0)
    assert_false(result.ok)
    assert_eq(result.failures,["SCREEN_REQUIRED"])

func test_visible_bounds_probe_reports_overflow_without_editing():
    var script=load("res://tests/tooling/r2_native_flow_probe.gd")
    assert_not_null(script)
    if script==null: return
    var root=add_child_autofree(Control.new())
    var label=Label.new()
    label.name="Outside"
    root.add_child(label)
    label.position=Vector2(1270,0)
    label.size=Vector2(100,30)
    var failures=script.new().visible_bounds(root)
    assert_eq(failures.size(),1)
    assert_eq(label.position,Vector2(1270,0))

func test_case_reads_actual_window_and_restores_a_new_session_object():
    var screen=load("res://scenes/replanned_r2/main.tscn").instantiate()
    screen.save_path="user://replanned_r2_tests/native-probe-gut/save.json"
    screen.options_path="user://replanned_r2_tests/native-probe-gut/options.json"
    screen.expedition_save_path="user://replanned_r2_tests/native-probe-gut/expedition.json"
    add_child_autofree(screen)
    var result=load("res://tests/tooling/r2_native_flow_probe.gd").new().run_case(screen,100,Vector2i(1280,720),0)
    assert_true(result.ok,str(result.failures))
    assert_eq(result.get("actual_window_size",[]),[screen.get_window().size.x,screen.get_window().size.y])
    assert_true(result.get("restored_new_session",false))
    assert_eq(result.get("actual_encounters",[]),["outer_breach","foundry","rift_core"])
    assert_true("FORK_ROUTE" in result.checks)
