extends GutTest
const PATH="res://src/replanned_r3/r3_line.gd"

func model():
    assert_true(ResourceLoader.exists(PATH))
    return load(PATH).new(42,"battle-a:line") if ResourceLoader.exists(PATH) else null

func test_placement_identity_and_enemy_deletion_do_not_reward_or_apply_gravity():
    var line=model()
    if line==null: return
    var plan=line.hard_drop_plan()
    line.commit_lock()
    var cells=line.target_candidates()
    assert_eq(cells.size(),4)
    var before=line.rows(false)
    var victim=cells[0]
    var result=line.destroy_cells("enemy-1",[victim.cell_id])
    assert_eq(result.removed,[victim.cell_id])
    assert_eq(result.origin,"ENEMY_DESTROY")
    assert_eq(result.rewards,[])
    assert_eq(line.target_candidates().size(),3)
    assert_eq(line.rows(false)[victim.y][victim.x],".")
    for remaining in line.target_candidates():
        assert_eq(line.rows(false)[remaining.y][remaining.x],before[remaining.y][remaining.x])
    assert_false(line.destroy_cells("enemy-1",[cells[1].cell_id]).success)
    var saved=line.snapshot()
    var restored=model()
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(saved))))
    assert_false(restored.destroy_cells("enemy-1",[cells[1].cell_id]).success)
    assert_eq(restored.snapshot(),saved)

func test_identity_snapshot_roundtrip_and_invalid_restore_is_atomic():
    var line=model()
    if line==null: return
    line.hard_drop_plan()
    line.commit_lock()
    var snapshot=line.snapshot()
    var restored=model()
    assert_true(restored.restore(JSON.parse_string(JSON.stringify(snapshot))))
    assert_eq(restored.snapshot(),snapshot)
    var bad=snapshot.duplicate(true)
    bad.cells[1].cell_id=bad.cells[0].cell_id
    assert_false(restored.restore(bad))
    assert_eq(restored.snapshot(),snapshot)
    bad=snapshot.duplicate(true)
    bad.cells[0].kind="X"
    assert_false(restored.restore(bad))
    assert_eq(restored.snapshot(),snapshot)

func test_topout_reset_does_not_reuse_cell_identifiers():
    var line=model()
    if line==null: return
    line.hard_drop_plan()
    line.commit_lock()
    var old=line.target_candidates()
    line.reset_after_topout()
    line.hard_drop_plan()
    line.commit_lock()
    for cell in line.target_candidates():
        for previous in old: assert_ne(cell.cell_id,previous.cell_id)

func test_line_compression_moves_identity_and_missing_target_is_not_replaced():
    var line=model()
    if line==null: return
    for i in 3:
        line.hard_drop_plan()
        line.commit_lock()
    line.reset_after_topout()
    var fixture=line.snapshot()
    fixture.engine.active_shape="O"
    fixture.engine.active_rotation=0
    fixture.engine.active_x=3
    fixture.engine.visible_cells[19]="AAAA..AAAA"
    fixture.engine.visible_cells[18]="H........."
    fixture.cells=[]
    var serial=0
    for y in [22,23]:
        for x in 10:
            var kind=fixture.engine.visible_cells[y-4][x]
            if kind==".": continue
            serial+=1
            fixture.cells.append({"cell_id":"battle-a:line:"+str(serial),"x":x,"y":y,"kind":kind})
    fixture.sequence=12
    fixture.engine.lock_sequence=3
    assert_true(line.restore(fixture))
    var follows=fixture.cells[0].cell_id
    var already_cleared=fixture.cells[1].cell_id
    var plan=line.hard_drop_plan()
    assert_eq(plan.rows,[23])
    assert_eq(plan.cells.size(),10)
    line.commit_lock()
    var moved=line.target_candidates().filter(func(c):return c.cell_id==follows)
    assert_eq(moved.size(),1)
    assert_eq(moved[0].y,23)
    var result=line.destroy_cells("follow-id",[follows,already_cleared])
    assert_eq(result.removed,[follows])
    assert_eq(line.target_candidates().size(),2)

func test_restore_rejects_rewound_sequence_after_cells_are_removed():
    var line=model()
    if line==null:return
    line.hard_drop_plan()
    line.commit_lock()
    line.reset_after_topout()
    var original=line.snapshot()
    var bad=original.duplicate(true)
    bad.sequence=0
    assert_false(line.restore(bad))
    assert_eq(line.snapshot(),original)
