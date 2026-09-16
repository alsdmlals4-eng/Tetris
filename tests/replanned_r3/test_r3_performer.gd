extends GutTest
const PATH="res://src/replanned_r3/r3_performer.gd"

func test_candidate_has_all_nine_cells_and_rejects_unknown_states():
    assert_true(ResourceLoader.exists(PATH))
    if not ResourceLoader.exists(PATH):return
    var art=load(PATH).new()
    assert_true(art.errors.is_empty(),str(art.errors))
    for category in ["ATK","DEF","SUP"]:
        for phase in ["entrance","impact","exit"]:
            var texture=art.texture(category,phase)
            assert_not_null(texture)
            if texture!=null:assert_eq(texture.get_size(),Vector2(448,448))
        assert_eq(art.texture(category,"compact"),art.texture(category,"impact"))
    assert_null(art.texture("UNKNOWN","impact"))
    assert_null(art.texture("ATK","unknown"))
