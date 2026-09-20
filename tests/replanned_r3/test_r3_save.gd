extends GutTest
const Session=preload("res://src/replanned_r3/r3_session.gd")
const PATH="res://src/replanned_r3/r3_save.gd"

func test_r3_checkpoint_and_backup_are_separate_from_r2():
    assert_true(ResourceLoader.exists(PATH))
    if not ResourceLoader.exists(PATH):return
    var path="user://replanned_r3_tests/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/save.json"
    var disk=load(PATH).new(path,path+".options")
    var s=Session.new("STANDARD",42,"r3:save")
    var first=disk.save_session(s)
    assert_true(first.success,str(first))
    s.command("switch")
    s.tick(123456)
    var second=disk.save_session(s,123)
    assert_true(second.success,str(second))
    var saved=disk.load_checkpoint()
    assert_true(saved.success)
    var restored=Session.new("STANDARD",42,"r3:save")
    assert_true(restored.restore(saved.snapshot))
    assert_eq(restored.snapshot(),s.snapshot())
    assert_eq(saved.clock_remainder_ns,123)
    var file=FileAccess.open(path,FileAccess.WRITE)
    file.store_string("corrupt primary preserved")
    file.close()
    assert_eq(disk.load_checkpoint().source,"backup")
    assert_eq(FileAccess.get_file_as_string(path),"corrupt primary preserved")

func test_r2_snapshot_is_rejected_before_writing():
    assert_true(ResourceLoader.exists(PATH))
    if not ResourceLoader.exists(PATH):return
    var path="user://replanned_r3_tests/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/save.json"
    var disk=load(PATH).new(path,path+".options")
    var old=load("res://src/replanned_r2/r2_session.gd").new()
    assert_false(disk.save_session(old).success)
    assert_false(FileAccess.file_exists(path))
