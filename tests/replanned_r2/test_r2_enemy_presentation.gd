extends GutTest

func test_battle_and_result_share_enemy_owner_for_every_profile():
    var screen = load("res://scenes/replanned_r2/main.tscn").instantiate()
    screen.save_path="user://replanned_r2_tests/enemy-binding/save.json"
    screen.options_path="user://replanned_r2_tests/enemy-binding/options.json"
    screen.expedition_save_path="user://replanned_r2_tests/enemy-binding/expedition.json"
    add_child_autofree(screen)
    screen.set_process(false)
    for profile in ["","outer_breach","foundry","watchtower","rift_core"]:
        screen.session=screen.Session.new("STANDARD",42,"enemy-binding",profile)
        screen._reset_view()
        screen._show_page("battle")
        screen.refresh()
        var id=screen.session.combat.encounter_info().id
        assert_same(screen.get_node("Battle/Combat/Stage/BodyClip/BossVisual").texture,screen.assets.enemy_texture(id,screen.boss_pose))
        screen._impact_us=360000
        screen.refresh()
        var expected_material=screen.assets.enemy_material(id,screen.boss_pose)
        if expected_material==null:
            assert_null(screen.get_node("Battle/Combat/Stage/BodyClip/BossVisual").material)
        else:
            assert_same(screen.get_node("Battle/Combat/Stage/BodyClip/BossVisual").material,expected_material)
        screen._show_result(false,false)
        assert_same(screen.get_node("Result/BossVisual").texture,screen.assets.enemy_texture(id,"idle"))
    assert_eq(screen.assets.consumer_manifest().assets.size(),5,"Preserved original manifest")
    assert_true(screen.assets.consumer_manifest().consumers.has("R2-WATCHTOWER"))
