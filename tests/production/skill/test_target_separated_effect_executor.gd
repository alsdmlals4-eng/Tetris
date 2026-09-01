## 보드 기회와 현재 ETA 효과가 서로의 시간 소유자를 침범하지 않는지 검증한다.
extends GutTest

const EXECUTOR_PATH := "res://src/production/skill/production_effect_executor.gd"
const RESOLVER_PATH := "res://src/production/skill/production_technique_resolver.gd"

class FakeBoardOpportunity:
	var granted_seconds: float = 0.0
	func grant(seconds: float) -> Dictionary:
		granted_seconds += seconds
		return {"granted": true, "granted_seconds": seconds, "remaining_seconds": granted_seconds}

class FakeEnemyScheduler:
	var adjusted_action_id := ""
	var adjusted_seconds: float = 0.0
	func adjust_current_eta(action_id: String, seconds: float) -> Dictionary:
		adjusted_action_id = action_id
		adjusted_seconds += seconds
		return {"adjusted": true, "action_id": action_id, "before_seconds": 8.0, "after_seconds": 8.0 + adjusted_seconds}

func test_board_opportunity_effect_never_receives_or_changes_enemy_scheduler() -> void:
	var executor = load(EXECUTOR_PATH).new()
	var board_opportunity = FakeBoardOpportunity.new()
	var scheduler = FakeEnemyScheduler.new()
	var result: Dictionary = executor.execute(
		{"op": "GRANT_PLAYER_BOARD_OPPORTUNITY", "magnitude": 3},
		{"board_opportunity": board_opportunity, "enemy_scheduler": scheduler, "telegraph_action_id": "gatebreaker:light_smash:1"}
	)
	assert_true(bool(result.get("ok", false)))
	assert_almost_eq(board_opportunity.granted_seconds, 3.0, 0.001)
	assert_eq(scheduler.adjusted_action_id, "")

func test_current_eta_effect_uses_only_the_current_telegraph_action_and_never_grants_board_time() -> void:
	var executor = load(EXECUTOR_PATH).new()
	var board_opportunity = FakeBoardOpportunity.new()
	var scheduler = FakeEnemyScheduler.new()
	var action_id := "gatebreaker:light_smash:1"
	var result: Dictionary = executor.execute(
		{"op": "ADJUST_CURRENT_ENEMY_ETA", "magnitude": 2},
		{"board_opportunity": board_opportunity, "enemy_scheduler": scheduler, "telegraph_action_id": action_id}
	)
	assert_true(bool(result.get("ok", false)))
	assert_eq(scheduler.adjusted_action_id, action_id)
	assert_almost_eq(scheduler.adjusted_seconds, 2.0, 0.001)
	assert_almost_eq(board_opportunity.granted_seconds, 0.0, 0.001)

func test_resolver_requires_the_matching_owner_for_each_time_primitive() -> void:
	var executor = load(EXECUTOR_PATH).new()
	var resolver = load(RESOLVER_PATH).new(executor)
	var board_definition := {"effects": [{"op": "GRANT_PLAYER_BOARD_OPPORTUNITY", "magnitude": 2}]}
	var eta_definition := {"effects": [{"op": "ADJUST_CURRENT_ENEMY_ETA", "magnitude": 2}]}

	assert_false(bool(resolver.readiness(board_definition, {"enemy_scheduler": FakeEnemyScheduler.new()}).get("ready", true)))
	assert_false(bool(resolver.readiness(eta_definition, {"board_opportunity": FakeBoardOpportunity.new(), "telegraph_action_id": "gatebreaker:light_smash:1"}).get("ready", true)))
	assert_true(bool(resolver.readiness(board_definition, {"board_opportunity": FakeBoardOpportunity.new()}).get("ready", false)))
	assert_true(bool(resolver.readiness(eta_definition, {"enemy_scheduler": FakeEnemyScheduler.new(), "telegraph_action_id": "gatebreaker:light_smash:1"}).get("ready", false)))
