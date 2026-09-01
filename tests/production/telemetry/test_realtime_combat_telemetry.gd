## continuous 전투 telemetry가 simulation 시간과 tactical pause를 분리해 기록하는지 검증한다.
extends GutTest

const TELEMETRY_PATH := "res://src/production/telemetry/production_telemetry.gd"

func test_telemetry_records_required_events_and_excludes_pause_from_active_simulation_time() -> void:
	assert_true(ResourceLoader.exists(TELEMETRY_PATH), "continuous telemetry must exist")
	if not ResourceLoader.exists(TELEMETRY_PATH):
		return
	var telemetry = load(TELEMETRY_PATH).new()
	telemetry.record("BATTLE_STARTED")
	telemetry.advance_simulation(2.5, "LINE")
	telemetry.begin_tactical_pause()
	telemetry.advance_wall_clock(4.0)
	telemetry.end_tactical_pause()
	telemetry.record("TECHNIQUE_USED")
	var summary: Dictionary = telemetry.summary()
	assert_almost_eq(float(summary.get("active_simulation_duration", 0.0)), 2.5, 0.001)
	assert_almost_eq(float(summary.get("tactical_pause_duration", 0.0)), 4.0, 0.001)
	assert_eq(int(summary.get("technique_use_count", 0)), 1)
	assert_eq(telemetry.events().size(), 4)

func test_telemetry_tracks_manual_pause_and_total_wall_clock_without_charging_reading_time_to_simulation() -> void:
	var telemetry = load(TELEMETRY_PATH).new()
	telemetry.advance_simulation(2.0, "CHAIN")
	telemetry.begin_manual_pause()
	telemetry.advance_wall_clock(3.0)
	telemetry.end_manual_pause()
	var summary: Dictionary = telemetry.summary()
	assert_almost_eq(float(summary.get("active_simulation_duration", 0.0)), 2.0, 0.001)
	assert_almost_eq(float(summary.get("chain_residency_duration", 0.0)), 2.0, 0.001)
	assert_almost_eq(float(summary.get("manual_pause_duration", 0.0)), 3.0, 0.001)
	assert_almost_eq(float(summary.get("wall_clock_encounter_duration", 0.0)), 5.0, 0.001)
	assert_eq(telemetry.events().map(func(event): return String(event.get("kind", ""))), ["SYSTEM_PAUSE_OPENED", "SYSTEM_PAUSE_CLOSED"])

func test_telemetry_retains_tutorial_transition_events_at_the_current_simulation_time() -> void:
	var telemetry = load(TELEMETRY_PATH).new()
	telemetry.advance_simulation(4.0, "LINE")
	telemetry.record("TUTORIAL_SAFE_OPENING_STARTED")
	telemetry.record("TUTORIAL_STEP_COMPLETED", {"step": "LINE_REWARD"})
	telemetry.record("TUTORIAL_FREE_PLAY_STARTED")
	var events: Array = telemetry.events()
	assert_eq(events.map(func(event): return String(event.get("kind", ""))), ["TUTORIAL_SAFE_OPENING_STARTED", "TUTORIAL_STEP_COMPLETED", "TUTORIAL_FREE_PLAY_STARTED"])
	assert_almost_eq(float(events[0].get("simulation_time_seconds", -1.0)), 4.0, 0.001)
