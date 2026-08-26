extends GutTest

const BATTLE_PATH := "res://src/production/combat/production_battle_session.gd"
const SKILL_DATA_PATH := "res://data/production/vanguard_skill_seed.json"
const ENEMY_DATA_PATH := "res://data/production/gatebreaker_action_seed.json"
const SEQUENCE_DATA_PATH := "res://data/production/gatebreaker_sequence_seed.json"

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

func _director(catalog: GatebreakerActionCatalog):
    return GatebreakerEncounterDirector.from_dictionary(
        JSON.parse_string(FileAccess.get_file_as_string(SEQUENCE_DATA_PATH)),
        catalog
    )

func _session(turn: TurnController, player: ProductionCombatState, enemy: ProductionCombatState, telegraph: GatebreakerTelegraphState):
    return load(BATTLE_PATH).new(
        turn,
        player,
        enemy,
        _skill_catalog(),
        telegraph,
        ProductionStatusState.new(),
        ProductionResponseState.new(),
        TimeEffectState.new(),
        ProductionTechniqueResolver.new(ProductionEffectExecutor.new()),
        ProductionEnemyActionResolver.new()
    )

func _attach_or_fail(session, director) -> bool:
    assert_true(session.has_method("attach_encounter_director"), "ProductionBattleSession must expose bounded Gatebreaker director attachment")
    assert_true(session.has_method("resolve_directed_enemy_action"), "ProductionBattleSession must expose directed Enemy Resolve")
    if not session.has_method("attach_encounter_director") or not session.has_method("resolve_directed_enemy_action"):
        return false
    assert_true(session.attach_encounter_director(director))
    return true

func test_first_directed_enemy_resolve_keeps_prior_next_then_schedules_authored_followup() -> void:
    var catalog = _enemy_catalog()
    var director = _director(catalog)
    var pair: Dictionary = director.bootstrap()
    var telegraph := GatebreakerTelegraphState.new(pair["current"], pair["next"])
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var session = _session(turn, player, enemy, telegraph)
    if not _attach_or_fail(session, director):
        return

    assert_true(turn.select_player_action("PASS"))
    assert_true(session.resolve_player_action()["resolved"])
    var result: Dictionary = session.resolve_directed_enemy_action()

    assert_true(result["resolved"])
    assert_eq(player.hp, 88)
    assert_eq(telegraph.current_action()["id"], "gatebreaker:gatebreaker_slam:2")
    assert_eq(telegraph.next_action()["id"], "gatebreaker:light_smash:3")
    assert_eq(director.current_phase, 1)
    assert_eq(turn.phase, TurnPhase.ENEMY_TELEGRAPH)

func test_player_damage_crossing_phase_two_threshold_does_not_replace_already_locked_next() -> void:
    var catalog = _enemy_catalog()
    var director = _director(catalog)
    var pair: Dictionary = director.bootstrap()
    var telegraph := GatebreakerTelegraphState.new(pair["current"], pair["next"])
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    enemy.apply_damage(28)
    player.apply_energy_delta(100)
    player.gain_stock(6)
    var session = _session(turn, player, enemy, telegraph)
    if not _attach_or_fail(session, director):
        return

    assert_true(session.select_technique("atk_t1_quick_cut")["accepted"])
    assert_true(session.resolve_player_action()["resolved"])
    assert_eq(enemy.hp, 60)

    var result: Dictionary = session.resolve_directed_enemy_action()

    assert_true(result["resolved"])
    assert_eq(telegraph.current_action()["id"], "gatebreaker:gatebreaker_slam:2", "already previewed Next becomes Current unchanged")
    assert_eq(telegraph.next_action()["id"], "gatebreaker:rift_siphon:3", "only the newly authored Next may enter Phase 2")
    assert_eq(director.current_phase, 2)

func test_counter_damage_crossing_threshold_uses_projected_post_enemy_resolve_boss_hp() -> void:
    var catalog = _enemy_catalog()
    var director = _director(catalog)
    var pair: Dictionary = director.bootstrap()
    var locked_after_slam: Dictionary = director.schedule_next_after_resolve(0.72)
    assert_eq(locked_after_slam["id"], "gatebreaker:light_smash:3")
    var telegraph := GatebreakerTelegraphState.new(pair["next"], locked_after_slam)
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    enemy.apply_damage(28)
    player.apply_energy_delta(100)
    player.gain_stock(6)
    var session = _session(turn, player, enemy, telegraph)
    if not _attach_or_fail(session, director):
        return

    assert_true(session.select_technique("def_t3_counter_stance")["accepted"])
    assert_true(session.resolve_player_action()["resolved"])
    assert_eq(enemy.hp, 72, "counter damage must not happen before Enemy Resolve")

    var result: Dictionary = session.resolve_directed_enemy_action()

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 64, "16 prevented damage at 0.5 ratio counters for 8")
    assert_eq(telegraph.current_action()["id"], "gatebreaker:light_smash:3")
    assert_eq(telegraph.next_action()["id"], "gatebreaker:rift_siphon:4")
    assert_eq(director.current_phase, 2, "new Next must use projected post-counter boss HP")

func test_phase_two_repair_heal_above_seventy_percent_never_rewinds_director() -> void:
    var catalog = _enemy_catalog()
    var director = _director(catalog)
    director.bootstrap()
    var siphon: Dictionary = director.schedule_next_after_resolve(0.69)
    var repair: Dictionary = director.schedule_next_after_resolve(0.49)
    var prior_next: Dictionary = director.schedule_next_after_resolve(0.49)
    assert_eq(siphon["template_key"], "rift_siphon")
    assert_eq(repair["template_key"], "rift_repair")
    assert_eq(prior_next["template_key"], "gatebreaker_slam")
    var telegraph := GatebreakerTelegraphState.new(repair, prior_next)
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    enemy.apply_damage(35)
    var session = _session(turn, player, enemy, telegraph)
    if not _attach_or_fail(session, director):
        return

    assert_true(turn.select_player_action("PASS"))
    assert_true(session.resolve_player_action()["resolved"])
    var result: Dictionary = session.resolve_directed_enemy_action()

    assert_true(result["resolved"])
    assert_eq(enemy.hp, 73)
    assert_eq(director.current_phase, 2)
    assert_eq(telegraph.current_action()["id"], prior_next["id"])
    assert_eq(telegraph.next_action()["template_key"], "chain_fracture")

func test_directed_resolve_fails_closed_without_attached_director() -> void:
    var catalog = _enemy_catalog()
    var director = _director(catalog)
    var pair: Dictionary = director.bootstrap()
    var telegraph := GatebreakerTelegraphState.new(pair["current"], pair["next"])
    var turn := _turn_in_action()
    var player := ProductionCombatState.new(100)
    var enemy := ProductionCombatState.new(100)
    var session = _session(turn, player, enemy, telegraph)

    assert_true(session.has_method("resolve_directed_enemy_action"), "ProductionBattleSession must expose directed Enemy Resolve")
    if not session.has_method("resolve_directed_enemy_action"):
        return
    assert_true(turn.select_player_action("PASS"))
    assert_true(session.resolve_player_action()["resolved"])

    var result: Dictionary = session.resolve_directed_enemy_action()

    assert_false(result["resolved"])
    assert_eq(result["reason"], "MISSING_ENCOUNTER_DIRECTOR")
    assert_eq(player.hp, 100)
    assert_eq(turn.phase, TurnPhase.ENEMY_RESOLVE)
    assert_eq(telegraph.current_action()["id"], pair["current"]["id"])
