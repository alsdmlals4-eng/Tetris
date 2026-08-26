extends GutTest

const SESSION_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"

func _turn_in_action() -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(30.0, 0.0, 0.0, 30.0)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    return turn

func _skill_catalog():
    return ProductionSkillCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(SKILL_DATA_PATH)))

func _enemy_catalog():
    return GatebreakerActionCatalog.from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(ENEMY_DATA_PATH)))

func _fixture(current_key: String = "light_smash", next_key: String = "gatebreaker_slam") -> Dictionary:
    assert_true(ResourceLoader.exists(SESSION_PATH), "ProductionBattleSession script must exist")
    if not ResourceLoader.exists(SESSION_PATH):
        return {}

    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var skill_catalog = _skill_catalog()
    var enemy_catalog = _enemy_catalog()
    var current: Dictionary = enemy_catalog.instantiate_action(current_key, 1)
    var next: Dictionary = enemy_catalog.instantiate_action(next_key, 2)
    var telegraph := GatebreakerTelegraphState.new(current, next)
    var status := ProductionStatusState.new()
    var response := ProductionResponseState.new()
    var time_effects := TimeEffectState.new()
    var technique_resolver := ProductionTechniqueResolver.new(ProductionEffectExecutor.new())
    var enemy_resolver := ProductionEnemyActionResolver.new()
    var session = load(SESSION_PATH).new(
        turn,
        player,
        enemy,
        skill_catalog,
        telegraph,
        status,
        response,
        time_effects,
        technique_resolver,
        enemy_resolver
    )
    return {
        "session": session,
        "turn": turn,
        "player": player,
        "enemy": enemy,
        "skill_catalog": skill_catalog,
        "enemy_catalog": enemy_catalog,
        "telegraph": telegraph,
        "status": status,
        "response": response,
        "time_effects": time_effects,
    }

func _fund_player(fixture: Dictionary) -> void:
    var player: ProductionCombatState = fixture["player"]
    player.apply_energy_delta(100)
    player.gain_stock(6)

func test_runtime_unresolved_technique_is_rejected_before_any_resource_spend() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    _fund_player(f)
    var player: ProductionCombatState = f["player"]
    var turn: TurnController = f["turn"]

    var result: Dictionary = f["session"].select_technique("sup_t4_mark_weakness")

    assert_false(result["accepted"])
    assert_eq(result["reason"], "EFFECT_CONTRACT_UNRESOLVED")
    assert_eq(player.energy, 100)
    assert_eq(player.stock, 6)
    assert_eq(turn.phase, TurnPhase.ACTION)
    assert_null(turn.pending_player_action)

func test_forecast_scope_mismatch_is_rejected_before_any_resource_spend() -> void:
    var f := _fixture("light_smash", "rift_siphon")
    if f.is_empty():
        return
    _fund_player(f)
    var player: ProductionCombatState = f["player"]

    var result: Dictionary = f["session"].select_technique("atk_t5_suppressive_break")

    assert_false(result["accepted"])
    assert_eq(result["reason"], "FORECAST_SCOPE_MISMATCH")
    assert_eq(player.energy, 100)
    assert_eq(player.stock, 6)
    assert_eq(f["turn"].phase, TurnPhase.ACTION)

func test_valid_technique_commits_cost_and_pending_action_without_changing_locked_telegraphs() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    _fund_player(f)
    var current_before: String = f["telegraph"].current_action()["id"]
    var next_before: String = f["telegraph"].next_action()["id"]

    var result: Dictionary = f["session"].select_technique("atk_t3_rift_breach")

    assert_true(result["accepted"])
    assert_eq(f["player"].energy, 84)
    assert_eq(f["player"].stock, 3)
    assert_eq(f["turn"].phase, TurnPhase.PLAYER_RESOLVE)
    assert_eq(f["turn"].pending_player_action.id, "atk_t3_rift_breach")
    assert_eq(f["telegraph"].current_action()["id"], current_before)
    assert_eq(f["telegraph"].next_action()["id"], next_before)

func test_player_resolve_executes_committed_technique_then_enters_enemy_resolve() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    _fund_player(f)
    assert_true(f["session"].select_technique("atk_t3_rift_breach")["accepted"])

    var result: Dictionary = f["session"].resolve_player_action()

    assert_true(result["resolved"])
    assert_eq(result["technique_id"], "atk_t3_rift_breach")
    assert_eq(f["enemy"].hp, 82)
    assert_true(f["status"].has_status("BREACH", "enemy"))
    assert_eq(f["turn"].phase, TurnPhase.ENEMY_RESOLVE)

func test_pass_player_resolve_enters_enemy_resolve_without_skill_effect() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    assert_true(f["turn"].select_player_action("PASS"))
    var enemy_hp_before: int = f["enemy"].hp

    var result: Dictionary = f["session"].resolve_player_action()

    assert_true(result["resolved"])
    assert_true(result["passed"])
    assert_eq(f["enemy"].hp, enemy_hp_before)
    assert_eq(f["turn"].phase, TurnPhase.ENEMY_RESOLVE)

func test_invalid_new_next_telegraph_blocks_enemy_resolve_before_combat_mutation() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    assert_true(f["turn"].select_player_action("PASS"))
    assert_true(f["session"].resolve_player_action()["resolved"])
    var current_before: String = f["telegraph"].current_action()["id"]
    var next_before: String = f["telegraph"].next_action()["id"]

    var result: Dictionary = f["session"].resolve_enemy_action({"kind": "DIRECT_HP_RATIO", "hp_ratio": 0.99})

    assert_false(result["resolved"])
    assert_eq(result["reason"], "INVALID_NEXT_AUTHORED_ACTION")
    assert_eq(f["player"].hp, 100)
    assert_eq(f["turn"].phase, TurnPhase.ENEMY_RESOLVE)
    assert_eq(f["telegraph"].current_action()["id"], current_before)
    assert_eq(f["telegraph"].next_action()["id"], next_before)

func test_valid_enemy_resolve_applies_locked_current_then_advances_prior_next_and_turn() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    assert_true(f["turn"].select_player_action("PASS"))
    assert_true(f["session"].resolve_player_action()["resolved"])
    var prior_next: Dictionary = f["telegraph"].next_action()
    var authored_next: Dictionary = f["enemy_catalog"].instantiate_action("rift_siphon", 3)

    var result: Dictionary = f["session"].resolve_enemy_action(authored_next)

    assert_true(result["resolved"])
    assert_eq(result["enemy_action_result"]["damage_applied"], 12)
    assert_eq(f["player"].hp, 88)
    assert_eq(f["telegraph"].current_action()["id"], prior_next["id"])
    assert_eq(f["telegraph"].next_action()["id"], authored_next["id"])
    assert_eq(f["turn"].phase, TurnPhase.ENEMY_TELEGRAPH)
    assert_null(f["turn"].pending_player_action)

func test_lethal_player_action_ends_battle_and_cancels_locked_enemy_action() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    _fund_player(f)
    f["enemy"].apply_damage(80)
    var current_before: String = f["telegraph"].current_action()["id"]
    assert_true(f["session"].select_technique("atk_t4_crushing_strike")["accepted"])

    var result: Dictionary = f["session"].resolve_player_action()

    assert_true(result["resolved"])
    assert_true(result["enemy_action_cancelled"])
    assert_true(f["session"].battle_over)
    assert_eq(f["session"].outcome, "PLAYER_VICTORY")
    assert_eq(f["enemy"].hp, 0)
    assert_eq(f["player"].hp, 100)
    assert_eq(f["telegraph"].current_action()["id"], current_before)
    assert_eq(f["turn"].phase, TurnPhase.PLAYER_RESOLVE)

func test_lethal_enemy_action_ends_battle_without_starting_another_turn() -> void:
    var f := _fixture()
    if f.is_empty():
        return
    f["player"].apply_damage(90)
    assert_true(f["turn"].select_player_action("PASS"))
    assert_true(f["session"].resolve_player_action()["resolved"])
    var current_before: String = f["telegraph"].current_action()["id"]
    var authored_next: Dictionary = f["enemy_catalog"].instantiate_action("rift_siphon", 3)

    var result: Dictionary = f["session"].resolve_enemy_action(authored_next)

    assert_true(result["resolved"])
    assert_true(f["session"].battle_over)
    assert_eq(f["session"].outcome, "PLAYER_DEFEAT")
    assert_eq(f["player"].hp, 0)
    assert_eq(f["telegraph"].current_action()["id"], current_before)
    assert_eq(f["turn"].phase, TurnPhase.ENEMY_RESOLVE)
