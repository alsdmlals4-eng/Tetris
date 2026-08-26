## CORE-029 bootstrap이 turn 계층 없이 continuous runtime의 필수 소유자를 조립하는지 검증한다.
extends GutTest

const BOOTSTRAP_PATH := "res://src/production/session/production_battle_bootstrap.gd"

func test_bootstrap_builds_a_started_realtime_runtime_with_line_active_and_chain_persistent() -> void:
	assert_true(ResourceLoader.exists(BOOTSTRAP_PATH), "continuous production bootstrap must exist")
	if not ResourceLoader.exists(BOOTSTRAP_PATH):
		return
	var bootstrap = load(BOOTSTRAP_PATH).new()
	assert_true(bootstrap.has_method("build_runtime"))
	var result: Dictionary = bootstrap.build_runtime()
	assert_true(bool(result.get("ready", false)), String(result.get("reason", "bootstrap failed")))
	var runtime = result.get("runtime")
	assert_not_null(runtime)
	assert_true(bool(runtime.snapshot().get("started", false)))
	assert_eq(String(result.get("workspace_manager").active_workspace()), "LINE")
	assert_false(runtime.is_simulation_paused())
