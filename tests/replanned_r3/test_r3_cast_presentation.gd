extends GutTest
const Presentation=preload("res://src/replanned_r3/r3_cast_presentation.gd")
const Combat=preload("res://src/replanned_r3/r3_combat.gd")

func receipts(count:int)->Array:
    var c=Combat.new()
    var result:Array=[]
    for i in count:
        result.append(c.cast("visual-test:%d"%i,"ATK",1))
    return result

func test_committed_cast_is_visible_without_mutating_ledger():
    var ledger=receipts(1)
    var before=ledger.duplicate(true)
    var p=Presentation.new()
    assert_true(p.sync(ledger))
    assert_eq(p.view().get("event_id"),"visual-test:0")
    assert_eq(p.view().get("phase"),"entrance")
    assert_eq(ledger,before)

func test_same_ledger_never_restarts_finished_cast():
    var ledger=receipts(1)
    var p=Presentation.new()
    assert_true(p.sync(ledger))
    p.tick(620000)
    assert_true(p.view().is_empty())
    assert_true(p.sync(ledger))
    assert_true(p.view().is_empty())

func test_restore_skips_historical_effects_but_next_cast_appears():
    var ledger=receipts(3)
    var p=Presentation.new()
    assert_true(p.sync(ledger.slice(0,2),true))
    assert_true(p.view().is_empty())
    assert_true(p.sync(ledger))
    assert_eq(p.view().get("event_id"),"visual-test:2")

func test_burst_keeps_first_entrance_and_coalesces_followup_without_unbounded_queue():
    var p=Presentation.new()
    assert_true(p.sync(receipts(8)))
    assert_eq(p.view().get("event_id"),"visual-test:0")
    assert_eq(p.view().get("pending_count"),7)
    p.tick(620000)
    assert_eq(p.view().get("event_id"),"visual-test:7")
    assert_eq(p.view().get("coalesced_count"),7)
    assert_eq(p.view().get("phase"),"compact")
    p.tick(240000)
    assert_true(p.view().is_empty())

func test_pause_freezes_cosmetic_clock_and_large_delta_closes_both_segments():
    var p=Presentation.new()
    p.sync(receipts(3))
    var before=p.view()
    p.tick(999999,true)
    assert_eq(p.view(),before)
    p.tick(-1)
    assert_eq(p.view(),before)
    p.tick(1000000)
    assert_true(p.view().is_empty())

func test_reduced_motion_has_no_translation_and_preserves_receipt():
    var p=Presentation.new()
    p.sync(receipts(1))
    assert_eq(p.view(true).get("offset_x"),0.0)
    assert_eq(p.view(true).get("event_id"),"visual-test:0")
    assert_eq(p.view(true).get("reduced_motion"),true)

func test_corrupt_duplicate_or_truncated_ledger_is_atomic():
    var ledger=receipts(2)
    var p=Presentation.new()
    p.sync(ledger)
    var before=p.view()
    assert_false(p.sync(ledger.slice(0,1)))
    var broken=ledger.duplicate(true)
    broken.append(ledger[0].duplicate(true))
    assert_false(p.sync(broken))
    broken=ledger.duplicate(true)
    broken[0].category="SUP"
    assert_false(p.sync(broken))
    assert_eq(p.view(),before)

func test_cancel_does_not_allow_historical_replay():
    var p=Presentation.new()
    var ledger=receipts(2)
    p.sync(ledger)
    p.cancel()
    assert_true(p.view().is_empty())
    assert_true(p.sync(ledger))
    assert_true(p.view().is_empty())
