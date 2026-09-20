extends GutTest
const Screen=preload("res://scenes/replanned_r3/resource_choice.tscn")
const Line=preload("res://src/replanned_r3/mastery_line.gd")
const Session=preload("res://src/replanned_r3/mastery_session.gd")

func test_exact_skill_table_combo_break_b2b_gap_and_cap():
    var entries=[]
    var patterns=[[4,"NONE",10],[0,"NONE",0],[2,"T_SPIN",15],[3,"T_SPIN",20],[1,"NONE",4],[1,"T_SPIN",11],[0,"T_SPIN",0],[1,"T_SPIN",10]]
    for i in patterns.size():
        entries.append({"id":str(i),"lines":patterns[i][0],"spin":patterns[i][1]})
        assert_eq(Line.evaluate(entries)[-1].units,patterns[i][2])
    assert_eq(Line.evaluate(entries)[-1].combo,1)

func test_rotation_marker_and_streak_survive_json_restore_and_destroy():
    var s=Session.new()
    assert_true(s.command("rotate",{"direction":1}).success)
    s.command("pause")
    var data=JSON.parse_string(JSON.stringify(s.snapshot()))
    var copy=Session.new()
    assert_true(copy.restore(data))
    assert_eq(copy.line._engine.active.last_successful_action,"ROTATE")
    copy.command("resume")
    copy.command("hard_drop")
    var before=copy.line.history.duplicate(true)
    copy.line.destroy_cells("enemy",[copy.line._cells[0].cell_id])
    assert_eq(copy.line.history,before,"enemy destruction neither earns nor advances/resets streak")
    assert_eq(copy.supply._cells.size(),0)

func test_restore_rejects_forged_mastery_and_fractional_credit_atomically():
    var s=Session.new()
    var before=s.snapshot()
    var bad=before.duplicate(true)
    bad.supply.history.append({"operation":"mastery","id":"fake","units":1.5})
    assert_false(s.restore(bad))
    assert_eq(s.snapshot(),before)
    s.supply.credit_mastery("fake",10)
    assert_false(Session.new().restore(s.snapshot()),"a valid supply ledger still needs a matching real lock")

func test_real_four_line_clear_credits_cells_once_plus_ten_skill_units():
    var s=Session.new()
    fixture_four(s.line)
    var result=s.command("hard_drop")
    assert_true(result.success)
    assert_eq(s.metrics.line_clears,4)
    assert_eq(s.combat.attack_bank,40,"only real tiles award attack")
    assert_eq(s.supply._cells.size(),40)
    assert_eq(s.supply_report().mastery_units,10)
    assert_eq(s.supply.pairs,10)
    assert_eq(s.bonus_balance(),9,"4 initial + 12 basic +3 skill -10 reserve")

static func fixture_four(line):
    line._engine.board.clear_all()
    line._cells=[]
    var n=0
    for y in range(20,24):
        for x in 10:
            if x==5:continue
            n+=1
            line._engine.board.set_cell(Vector2i(x,y),"A")
            line._cells.append({"cell_id":line._namespace+":"+str(n),"x":x,"y":y,"kind":"A"})
    line._sequence=n
    line._engine._spawn_pair({"shape":"I","resource":"A"})
    line._engine.active.rotation=1
    line._engine.active.origin=Vector2i(3,4)

func test_playable_entry_exposes_mastery_without_changing_tile_rewards():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    assert_true(screen.session.has_method("supply_report"),"actual consumer needs mastery reporting")
    assert_true(screen.session.line.has_method("mastery_preview"),"reuse spin/streak on actual LINE")

func test_mastery_bonus_has_a_separate_replayable_credit_ledger():
    var screen=Screen.instantiate()
    add_child_autofree(screen)
    screen.start_resource_battle("LINE")
    var supply=screen.session.supply
    assert_true(supply.has_method("credit_mastery"),"bonus must not invent cleared tile IDs")
    if not supply.has_method("credit_mastery"):return
    assert_true(supply.credit_mastery("line:1",10).success)
    assert_eq(supply.pairs,7)
    assert_eq(supply.snapshot().cells,[])
    assert_false(supply.credit_mastery("line:1",10).success)
    var copy=supply.get_script().new()
    assert_true(copy.restore(supply.snapshot()))
    assert_eq(copy.snapshot(),supply.snapshot())
