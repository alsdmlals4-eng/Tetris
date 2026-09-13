extends GutTest

func _make_audio():
    var script = load("res://src/replanned_r2/r2_audio.gd")
    assert_not_null(script, "Audio settings require a real playback owner")
    if script == null: return null
    return add_child_autofree(script.new())

func test_volume_zero_mutes_and_channels_are_independent():
    var audio = _make_audio()
    if audio == null: return
    audio.configure({"effects":0,"music":50})
    assert_false(audio.play_cue("confirm"))
    assert_true(audio.play_cue("victory"))
    assert_almost_eq(audio.music.volume_linear,0.5,0.001)
    audio.configure({"effects":70,"music":0})
    assert_false(audio.music.playing)
    assert_false(audio.play_cue("victory"))
    assert_true(audio.play_cue("confirm"))

func test_pool_is_bounded_unknown_and_failed_events_are_silent():
    var audio = _make_audio()
    if audio == null: return
    var count = audio.get_child_count()
    for i in 50: audio.play_cue("confirm")
    assert_eq(audio.get_child_count(),count)
    assert_false(audio.play_cue("unknown"))
    assert_eq(audio.cue_for_event({"success":false,"effect":"ATK_DAMAGE"}),"")
    assert_eq(audio.cue_for_event({"success":true,"effect":"ATK_DAMAGE"}),"attack")
    assert_eq(audio.cue_for_event({"success":true,"effect":"LINE_RESOURCES_APPLIED"}),"line")
    assert_eq(audio.cue_for_event({"success":true,"effect":"CHAIN_WAVE_RESOLVED"}),"chain")
    assert_eq(audio.cue_for_event({"success":true,"effect":"ENEMY_ACTION_RESOLVED","damage":16}),"enemy")
    assert_eq(audio.cue_for_event({"success":true,"effect":"ENEMY_ACTION_RESOLVED","damage":0}),"")

func test_all_registered_streams_are_real_and_have_positive_duration():
    var audio = _make_audio()
    if audio == null: return
    for cue in audio.CUES:
        var stream = load(audio.CUES[cue])
        assert_true(stream is AudioStream, cue)
        assert_gt(stream.get_length(),0.0,cue)

func test_battle_loop_pause_mute_and_end_are_separate():
    var audio = _make_audio()
    assert_true(audio.has_method("set_battle_state"))
    if not audio.has_method("set_battle_state"): return
    audio.set_battle_state(true,false)
    assert_true(audio.background.playing)
    assert_true(audio.background.stream.loop)
    audio.set_battle_state(true,true)
    assert_true(audio.background.stream_paused)
    audio.configure({"effects":70,"music":0})
    audio.set_battle_state(true,false)
    assert_true(audio.background.stream_paused)
    audio.configure({"effects":70,"music":50})
    assert_false(audio.background.stream_paused)
    assert_true(audio.background.playing)
    audio.set_battle_state(false,false)
    assert_false(audio.background.playing)
    assert_true(audio.play_cue("victory"))
    assert_false(audio.background.playing)
