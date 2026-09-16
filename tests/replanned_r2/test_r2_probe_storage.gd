extends GutTest
const PATH="res://tests/tooling/r2_probe_storage.gd"

func _helper():
    assert_true(ResourceLoader.exists(PATH),"Native probes need a shared storage boundary")
    return load(PATH).new() if ResourceLoader.exists(PATH) else null

func test_factory_binds_real_writers_before_ready():
    var helper=_helper()
    if helper==null: return
    var screen=helper.create_screen()
    assert_false(screen.is_inside_tree())
    add_child_autofree(screen)
    screen.set_process(false)
    assert_true(helper.is_isolated(screen))
    assert_eq(screen.disk.save_path,screen.save_path)
    assert_eq(screen.disk.options_path,screen.options_path)
    assert_eq(screen.expedition_disk.save_path,screen.expedition_save_path)
    screen.start_expedition("STANDARD",41)
    assert_true(screen.expedition_disk.load_expedition().success)

func test_properties_do_not_disguise_unsafe_bound_writer():
    var helper=_helper()
    if helper==null: return
    var screen=helper.create_screen()
    add_child_autofree(screen)
    screen.set_process(false)
    # No write: only bind an unsafe real writer and prove rejection before commands.
    screen.expedition_disk=screen.ExpeditionDisk.new()
    assert_false(helper.is_isolated(screen))
    var page=screen.page
    var result=load("res://tests/tooling/r2_native_flow_probe.gd").new().run_case(screen,100,Vector2i(1280,720),0)
    assert_eq(result.failures,["UNSAFE_PROBE_STORAGE"])
    assert_eq(screen.page,page)
    assert_null(screen.expedition)
    var driver_result=load("res://tests/tooling/r2_expedition_runtime_driver.gd").new().drive_one_battle(screen)
    assert_eq(driver_result.reason,"UNSAFE_PROBE_STORAGE")

func test_path_escape_and_sibling_prefix_are_rejected():
    var helper=_helper()
    if helper==null: return
    var screen=helper.create_screen()
    add_child_autofree(screen)
    screen.set_process(false)
    for path in ["user://replanned_r2_tests/../replanned_r2/save.json","user://replanned_r2_tests_bad/save.json","user://replanned_r2/save.json"]:
        screen.disk.save_path=path
        assert_false(helper.is_isolated(screen),path)

func test_report_destination_must_also_be_isolated():
    var helper=_helper()
    if helper==null: return
    var screen=helper.create_screen()
    add_child_autofree(screen)
    screen.set_process(false)
    screen.report_directory="user://replanned_r2/reports"
    assert_false(helper.is_isolated(screen),"Reports must not escape into player data")

func test_different_isolated_writer_is_not_the_configured_destination():
    var helper=_helper()
    if helper==null: return
    var screen=helper.create_screen()
    add_child_autofree(screen)
    screen.set_process(false)
    screen.disk.save_path="user://replanned_r2_tests/other/save.json"
    assert_false(helper.is_isolated(screen),"Reject stale writer even when both paths are isolated")

func _normal_save_fingerprints() -> Dictionary:
    var result={}
    for path in ["user://replanned_r2/save.json","user://replanned_r2/options.json","user://replanned_r2/expedition.json"]:
        for suffix in ["",".bak"]:
            var file_path=path+suffix
            result[file_path]=FileAccess.get_sha256(file_path) if FileAccess.file_exists(file_path) else "ABSENT"
    return result

func test_real_scene_flows_preserve_normal_saves_and_backups():
    var helper=_helper()
    if helper==null: return
    var before=_normal_save_fingerprints()
    for route in [0,1]:
        var screen=helper.create_screen()
        add_child_autofree(screen)
        screen.set_process(false)
        screen.start_run("STANDARD",41)
        screen.pause_game()
        assert_true(screen.checkpoint().success)
        assert_true(screen.disk.load_checkpoint().success)
        screen.open_options()
        screen.options_draft.font_scale=125
        screen.close_options(true)
        assert_true(FileAccess.file_exists(screen.disk.options_path))
        var result=load("res://tests/tooling/r2_native_flow_probe.gd").new().run_case(screen,100,Vector2i(1280,720),route)
        assert_true(result.ok,str(result.failures))
        var report=screen.PlaytestReport.new().write_snapshot(screen.session.snapshot(),false,screen.report_directory)
        assert_true(report.success,str(report))
    assert_eq(_normal_save_fingerprints(),before,"Player files and backups must remain byte-identical")
