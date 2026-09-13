extends GutTest
const PATH="res://src/replanned_r3/r3_disruption.gd"
func model():
    assert_true(ResourceLoader.exists(PATH))
    return load(PATH).new(42) if ResourceLoader.exists(PATH) else null
func candidates()->Array:
    return [{"cell_id":"c3"},{"cell_id":"c1"},{"cell_id":"c4"},{"cell_id":"c2"}]

func test_fixed_reservation_is_order_independent_and_not_rerolled():
    var a=model()
    var b=model()
    if a==null or b==null: return
    assert_true(a.begin("attack-1","LINE",3).success)
    assert_true(b.begin("attack-1","LINE",3).success)
    assert_false(a.reserve(2000001,candidates()).success)
    assert_true(a.reserve(2000000,candidates()).success)
    var reverse=candidates()
    reverse.reverse()
    assert_true(b.reserve(2000000,reverse).success)
    assert_eq(a.preview(),b.preview())
    var first=a.preview()
    assert_eq(first.target_board,"LINE")
    assert_eq(first.target_ids.size(),3)
    assert_false(a.reserve(2500000,[{"cell_id":"replacement"}]).success)
    assert_eq(a.preview(),first)
    assert_false(a.begin("attack-1","CHAIN",4).success)
    assert_eq(a.preview(),first)

func test_shortage_empty_and_dedup_have_no_reward_payload():
    var a=model()
    if a==null: return
    a.begin("empty","CHAIN",4)
    assert_true(a.reserve(0,[]).success)
    var event=a.commit()
    assert_true(event.success)
    assert_eq(event.target_ids,[])
    assert_eq(event.origin,"ENEMY_DESTROY")
    assert_eq(event.rewards,[])
    assert_false(a.commit().success)
    assert_false(a.begin("empty","LINE",2).success)
    a.begin("short","CHAIN",4)
    a.reserve(0,[{"cell_id":"one"}])
    assert_eq(a.commit().target_ids,["one"])

func test_snapshot_roundtrip_and_invalid_reservations_fail_atomically():
    var a=model()
    if a==null: return
    a.begin("saved","LINE",2)
    a.reserve(1000000,candidates())
    var state=a.snapshot()
    var b=model()
    assert_true(b.restore(JSON.parse_string(JSON.stringify(state))))
    assert_eq(b.preview(),a.preview())
    assert_eq(b.commit(),a.commit())
    var before=b.snapshot()
    var bad=state.duplicate(true)
    bad.reservation.target_ids=["same","same"]
    assert_false(b.restore(bad))
    assert_eq(b.snapshot(),before)
