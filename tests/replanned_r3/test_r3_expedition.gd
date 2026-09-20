extends GutTest
const PATH="res://src/replanned_r3/r3_expedition.gd"

func test_both_routes_create_r3_battles_and_finish_finite_progression():
    var script=load(PATH)
    for branch in ["watchtower","foundry"]:
        var expedition=script.new("r3:route-"+branch,42,"STANDARD")
        for encounter in ["outer_breach",branch,"rift_core"]:
            assert_true(expedition.launch(encounter).success)
            var battle=expedition.make_battle_session()
            assert_not_null(battle)
            assert_eq(battle.snapshot().schema,"r3-session-v1")
            assert_eq(battle.supply.pairs,4)
            assert_eq(battle.chain.phase,"NEED_PAIR")
            var snapshot=expedition.snapshot()
            var restored=script.new()
            assert_true(restored.restore(JSON.parse_string(JSON.stringify(snapshot))))
            assert_eq(restored.view(),expedition.view())
            # Route-only boundary test; does not claim a playable victory.
            assert_true(expedition.finish_battle({"run_id":battle._run_id,"outcome":"VICTORY","hp":70}).success)
            if expedition.view().phase=="SUPPLY":
                assert_true(expedition.choose_supply(expedition.catalog().supplies.keys()[0]).success)
        assert_eq(expedition.view().phase,"COMPLETE")

func test_expedition_disk_resumes_r3_only_and_recovers_terminal_defeat():
    var path="res://src/replanned_r3/r3_expedition_save.gd"
    assert_true(ResourceLoader.exists(path))
    if not ResourceLoader.exists(path):return
    var disk=load(path).new("user://replanned_r3_tests/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/expedition.json")
    var expedition=load(PATH).new("r3:route-save",42,"RELAXED")
    assert_true(disk.save_expedition(expedition,null).success)
    expedition.launch("outer_breach")
    var battle=expedition.make_battle_session()
    assert_true(disk.save_expedition(expedition,battle,123).success)
    var loaded=disk.load_expedition()
    assert_true(loaded.success)
    assert_eq(loaded.session.snapshot(),battle.snapshot())
    battle.command("switch")
    battle.tick(1000000000)
    assert_eq(battle.combat.outcome,"DEFEAT")
    expedition.finish_battle({"run_id":battle._run_id,"outcome":"DEFEAT","hp":0})
    assert_true(disk.save_expedition(expedition,battle).success)
    assert_eq(disk.load_expedition().expedition.view().phase,"DEFEAT")
