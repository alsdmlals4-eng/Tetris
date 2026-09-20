extends GutTest

const PATH="res://src/replanned_r3/r3_pair_supply.gd"

func supply():
    assert_true(ResourceLoader.exists(PATH),"R3 supply must enforce finite placement")
    return load(PATH).new() if ResourceLoader.exists(PATH) else null

func test_restore_rejects_truncated_dedup_ledgers():
    var s=supply()
    if s==null:return
    s.consume("used-spawn")
    s.credit("used-clear",ids("prior",10))
    var original=s.snapshot()
    for key in ["clears","spawns","history"]:
        var bad=original.duplicate(true)
        bad[key]=[]
        assert_false(s.restore(bad))
        assert_eq(s.snapshot(),original)

func ids(prefix: String, count: int) -> Array:
    var result=[]
    for i in count: result.append(prefix+str(i))
    return result

func test_clear_supplies_three_pairs_and_spawn_charges_once():
    var s=supply()
    if s==null: return
    assert_eq(s.pairs,4)
    assert_true(s.consume("p1").success)
    assert_eq(s.pairs,3)
    assert_false(s.consume("p1").success)
    assert_true(s.credit("l1",ids("a",10)).success)
    assert_eq(s.pairs,6)
    assert_false(s.credit("l1",ids("a",10)).success)
    assert_eq(s.pairs,6)

func test_cap_discards_overflow_without_later_refund():
    var s=supply()
    if s==null: return
    for i in 2: s.consume("p"+str(i))
    s.credit("l1",ids("a",30))
    assert_eq(s.pairs,11)
    var result=s.credit("l2",ids("b",20))
    assert_eq(s.pairs,12)
    assert_eq(result.applied,1)
    assert_eq(result.overflow,5)
    s.consume("p3")
    assert_eq(s.pairs,11)

func test_empty_supply_does_not_consume_future_spawn_id():
    var s=supply()
    if s==null: return
    for i in 4: assert_true(s.consume("p"+str(i)).success)
    assert_eq(s.consume("future").reason,"NO_PAIR_SUPPLY")
    assert_eq(s.pairs,0)
    s.credit("l1",ids("a",10))
    assert_true(s.consume("future").success)
    assert_eq(s.pairs,2)

func test_partial_cells_remainder_and_duplicate_ids_fail_atomically():
    var s=supply()
    if s==null: return
    s.credit("l1",ids("a",6))
    assert_eq(s.pairs,4)
    assert_eq(s.remainder,6)
    var before=s.snapshot()
    assert_false(s.credit("l2",["z","z"]).success)
    assert_false(s.credit("l2",["a0","z"]).success)
    assert_false(s.credit("",["z"]).success)
    assert_false(s.credit("l2",[12]).success)
    assert_eq(s.snapshot(),before)
    s.credit("l2",ids("b",4))
    assert_eq(s.pairs,7)
    assert_eq(s.remainder,0)

func test_restore_retains_guards_and_rejects_malformed_without_change():
    var s=supply()
    if s==null: return
    s.consume("p1")
    s.credit("l1",ids("a",6))
    var restored=supply()
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(s.snapshot()))))
    assert_eq(restored.snapshot(),s.snapshot())
    assert_false(restored.consume("p1").success)
    var before=restored.snapshot()
    for invalid in [-1,13,1.5,"4"]:
        var bad=before.duplicate(true)
        bad.pairs=invalid
        assert_false(restored.restore(bad))
        assert_eq(restored.snapshot(),before)
    var bad=before.duplicate(true)
    bad.extra=true
    assert_false(restored.restore(bad))
