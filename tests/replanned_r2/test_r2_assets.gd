extends GutTest

const Assets = preload("res://src/replanned_r2/r2_assets.gd")

func test_enemy_binding_exposes_shared_trial_and_never_uses_player_art():
    var assets = Assets.new(ProjectSettings.globalize_path("res://"))
    assert_true(assets.has_method("enemy_binding"))
    if not assets.has_method("enemy_binding"): return
    for encounter in ["outer_breach","foundry","watchtower","rift_core","rift_breaker_r2_intro",""]:
        var binding = assets.enemy_binding(encounter)
        assert_true(binding.success)
        assert_eq(binding.asset_id,"R2-BOSS")
        for pose in ["idle","anticipation","impact","recovery","hurt","defeat"]:
            assert_same(assets.enemy_texture(encounter,pose),assets.texture("R2-BOSS",pose))
    assert_eq(assets.enemy_binding("watchtower").state,"SHARED_TRIAL_FALLBACK")
    assert_false(assets.enemy_binding("unknown").success)
    assert_null(assets.enemy_texture("unknown","idle"))
    assert_null(assets.enemy_texture("watchtower","neutral"))
    assets._regions.erase("R2-BOSS:hurt")
    assert_false(assets.enemy_binding("watchtower").success)
    assert_null(assets.enemy_texture("watchtower","idle"))

func test_external_source_root_preserves_original_hashes_and_remapped_textures():
    var source_root := ProjectSettings.globalize_path("res://")
    var assets = Assets.new(source_root)
    assert_eq(assets.errors, [])
    assert_eq(assets.consumer_manifest().assets.size(), 5)
    assert_not_null(assets.texture("R1-ICONS", "strike"))
    assert_not_null(assets.texture("R1-PORTRAIT", "neutral"))
    assert_not_null(assets.texture("R1-ENV", "full"))
    assert_not_null(assets.texture("R2-TILES", "attack"))
    assert_not_null(assets.texture("R2-BOSS", "idle"))

func test_tampered_external_source_bytes_are_rejected_by_sha256():
    var source_root := ProjectSettings.globalize_path("user://replanned_r2_tests/tampered-source-root")
    var relative_path := "docs/assets/reference/planned/replanning/blueprint/icons.png"
    var tampered_path := source_root.path_join(relative_path)
    assert_eq(DirAccess.make_dir_recursive_absolute(tampered_path.get_base_dir()), OK)
    var file := FileAccess.open(tampered_path, FileAccess.WRITE)
    assert_not_null(file)
    file.store_buffer("deliberately tampered bytes".to_utf8_buffer())
    file.close()
    assert_ne(FileAccess.get_sha256(tampered_path), "")
    var assets = Assets.new(source_root)
    assert_true(assets.errors.has("Asset hash mismatch: R1-ICONS"))

func test_missing_external_source_root_keeps_each_asset_error_explicit():
    var missing_root := ProjectSettings.globalize_path("user://replanned_r2_tests/missing-source-root")
    var assets = Assets.new(missing_root)
    assert_eq(assets.errors.size(), 5)
    for id in ["R1-ICONS", "R1-PORTRAIT", "R1-ENV", "R2-TILES", "R2-BOSS"]:
        assert_true(assets.errors.has("Asset hash mismatch: " + id))
