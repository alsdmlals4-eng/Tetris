extends GutTest
const Session = preload("res://src/replanned_r2/r2_session.gd")
const PATH = "user://replanned_r2_tests/task3/save.json"
var disk
func before_each():
    for suffix in ["",".bak",".tmp",".bak.tmp"]:
        if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
    if ResourceLoader.exists("res://src/replanned_r2/r2_save.gd"):
        disk = load("res://src/replanned_r2/r2_save.gd").new(PATH,PATH+".options")
    else: disk = null
func ready_disk() -> bool:
    assert_not_null(disk,"R2 recoverable disk owner must exist")
    return disk != null
func write_raw(path: String, text: String):
    var f = FileAccess.open(path,FileAccess.WRITE)
    f.store_string(text)
    f.close()
func test_canonical_json_recursively_sorts_and_normalizes_integers():
    if not ready_disk(): return
    assert_eq(disk.canonical_json({"z":[2.0,{"b":true,"a":"한글"}],"a":1}),"{\"a\":1,\"z\":[2,{\"a\":\"한글\",\"b\":true}]}")
func test_complete_roundtrip_restores_identity_paused_and_clock():
    if not ready_disk(): return
    var s = Session.new("RELAXED",9112026,"disk-run")
    s.tick(123456)
    assert_true(disk.save_session(s,321).success)
    var loaded = disk.load_checkpoint()
    assert_true(loaded.success)
    assert_eq(loaded.source,"primary")
    assert_eq(loaded.clock_remainder_ns,321)
    var restored = Session.new()
    assert_true(restored.restore(loaded.snapshot))
    assert_eq(restored.run_id,"disk-run")
    assert_true(restored.combat.paused)
    assert_eq(restored.combat.eta_us,s.combat.eta_us)
func test_corrupt_primary_uses_last_valid_backup_never_temporary():
    if not ready_disk(): return
    var s = Session.new("STANDARD",1,"previous")
    assert_true(disk.save_session(s).success)
    s.tick(100000)
    assert_true(disk.save_session(s).success)
    write_raw(PATH,"broken")
    write_raw(PATH+".tmp","{}")
    var loaded = disk.load_checkpoint()
    assert_true(loaded.success)
    assert_eq(loaded.source,"backup")
    assert_eq(int(loaded.snapshot.identity.elapsed_simulation_us),0)
func test_valid_backup_not_replaced_by_corrupt_primary():
    if not ready_disk(): return
    var s = Session.new("STANDARD",1,"previous")
    disk.save_session(s)
    s.tick(100)
    disk.save_session(s)
    write_raw(PATH,"corrupt")
    s.tick(100)
    assert_true(disk.save_session(s).success)
    write_raw(PATH,"corrupt again")
    assert_eq(int(disk.load_checkpoint().snapshot.identity.elapsed_simulation_us),0)
func test_cascade_partial_and_checksum_tampering_rejected():
    if not ready_disk(): return
    var s = Session.new()
    s.setup_training("CHAIN")
    s.command("chain_swap",{"from":[4,5],"to":[5,5]})
    assert_false(disk.save_session(s).success)
    assert_false(disk.load_checkpoint().success)
    var full = Session.new()
    disk.save_session(full)
    var payload = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    payload.snapshot.player.hp = 1
    write_raw(PATH,JSON.stringify(payload))
    assert_false(disk.load_checkpoint().success)
    payload.erase("snapshot")
    write_raw(PATH,JSON.stringify(payload))
    assert_false(disk.load_checkpoint().success)
func test_interruption_after_primary_disappears_keeps_complete_backup():
    if not ready_disk(): return
    var s = Session.new("STANDARD",1,"old")
    disk.save_session(s)
    s.tick(1000)
    disk.failure_point = "after_primary_removed"
    assert_false(disk.save_session(s).success)
    assert_false(FileAccess.file_exists(PATH))
    var loaded = disk.load_checkpoint()
    assert_true(loaded.success)
    assert_eq(loaded.source,"backup")
    assert_eq(int(loaded.snapshot.identity.elapsed_simulation_us),0)
func test_failed_rename_and_backup_preservation_never_report_success():
    if not ready_disk(): return
    for point in ["rename","backup"]:
        disk.failure_point = ""
        var s = Session.new("STANDARD",1,"safe")
        assert_true(disk.save_session(s).success)
        s.tick(500)
        disk.failure_point = point
        assert_false(disk.save_session(s).success)
        assert_true(disk.load_checkpoint().success)
        assert_eq(int(disk.load_checkpoint().snapshot.identity.elapsed_simulation_us),0)
func test_options_persist_and_conflicting_remap_rejects_without_mutation():
    if not ready_disk(): return
    var options = disk.default_options()
    var old = options.duplicate(true)
    assert_false(disk.remap(options,"keyboard_mapping","left",KEY_RIGHT).success)
    assert_eq(options,old)
    assert_true(disk.remap(options,"keyboard_mapping","left",KEY_Q).success)
    options.font_scale = 125
    options.reduced_motion = true
    assert_true(disk.save_options(options))
    var readback = disk.load_options()
    assert_eq(readback.font_scale,125)
    assert_true(readback.reduced_motion)
    assert_eq(readback.keyboard_mapping.left,[KEY_Q])
