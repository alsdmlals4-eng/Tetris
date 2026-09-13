extends GutTest

func test_watchtower_uses_preferred_sheet_without_replacing_core():
    var assets=load("res://src/replanned_r2/r2_assets.gd").new(ProjectSettings.globalize_path("res://"))
    var binding=assets.enemy_binding("watchtower")
    assert_eq(binding.asset_id,"R2-WATCHTOWER")
    for pose in ["idle","anticipation","impact","recovery","hurt","defeat"]:
        var texture=assets.enemy_texture("watchtower",pose)
        assert_not_null(texture)
        assert_ne(texture,assets.texture("R2-BOSS",pose))
        assert_eq(texture.get_size(),Vector2(900,460),"Pose switch must not change fitting scale")
    assert_same(assets.enemy_texture("rift_core","idle"),assets.texture("R2-BOSS","idle"))

func test_complementary_material_is_limited_to_middle_row():
    var assets=load("res://src/replanned_r2/r2_assets.gd").new(ProjectSettings.globalize_path("res://"))
    for pose in ["idle","anticipation","hurt","defeat"]:
        assert_null(assets.enemy_material("watchtower",pose))
    assert_true(assets.enemy_material("watchtower","impact").get_shader_parameter("keep_left"))
    assert_false(assets.enemy_material("watchtower","recovery").get_shader_parameter("keep_left"))
    assert_null(assets.enemy_material("rift_core","impact"))
    assert_null(assets.enemy_material("unknown","impact"))
