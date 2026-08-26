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
