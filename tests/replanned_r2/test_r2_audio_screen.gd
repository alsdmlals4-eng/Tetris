extends GutTest
var screen
func before_each():
    screen = load("res://scenes/replanned_r2/main.tscn").instantiate()
    screen.save_path="user://replanned_r2_tests/audio-screen/save.json"
    screen.options_path="user://replanned_r2_tests/audio-screen/options.json"
    screen.expedition_save_path="user://replanned_r2_tests/audio-screen/expedition.json"
    add_child_autofree(screen)
    screen.set_process(false)

func test_volume_preview_cancel_and_event_consumer():
    assert_true(screen.has_node("Audio"))
    if not screen.has_node("Audio"): return
    var audio = screen.get_node("Audio")
    var original = screen.options.audio.effects
    screen.open_options()
    screen.get_node("Options/effectsLevel").value = 23
    assert_almost_eq(audio.effects[0].volume_linear,0.23,0.001)
    screen.close_options(false)
    assert_almost_eq(audio.effects[0].volume_linear,float(original)/100.0,0.001)
    screen._events([{"success":true,"effect":"ATK_DAMAGE","damage_applied":1}])
    assert_true(audio.effects.any(func(p): return p.playing))

func test_audio_controls_do_not_overlap_status_at_large_font():
    screen.options.font_scale=125
    screen._apply_font()
    var status=screen.get_node("Options/Status")
    for path in ["Options/AudioCredit","Options/TestEffects","Options/TestMusic"]:
        assert_false(status.get_rect().intersects(screen.get_node(path).get_rect()),path)

func test_details_boundary_stops_playing_feedback():
    screen.session=screen.Session.new("STANDARD",42,"audio-details")
    screen._reset_view()
    screen._show_page("battle")
    screen.audio.play_cue("enemy")
    screen.open_details()
    assert_false(screen.audio.effects.any(func(p): return p.playing))

func test_save_failure_boundary_stops_feedback():
    screen.audio.play_cue("enemy")
    screen._show_save_failure("RESULT","WRITE_FAILED")
    assert_false(screen.audio.effects.any(func(p): return p.playing))
