extends GutTest

const CATALOG_PATH := "res://src/production/skill/production_skill_catalog.gd"
const SESSION_PATH := "res://src/production/skill/production_skill_session.gd"
const DATA_PATH := "res://data/production/vanguard_skill_seed.json"

func _catalog():
    if not ResourceLoader.exists(CATALOG_PATH) or not FileAccess.file_exists(DATA_PATH):
        return null
    return load(CATALOG_PATH).from_dictionary(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))

func _turn_in_action(seconds: float = 30.0) -> TurnController:
    var budget := TurnBudget.new()
    budget.snapshot(seconds, 0.0, 0.0, seconds)
    var turn := TurnController.new(budget)
    turn.enter_line()
    turn.request_ready()
    turn.complete_line_settle()
    turn.request_ready()
    turn.complete_chain_settle()
    return turn

func _make_session(in_action: bool = true):
    assert_true(ResourceLoader.exists(SESSION_PATH), "ProductionSkillSession script must exist")
    if not ResourceLoader.exists(SESSION_PATH):
        return null
    var catalog = _catalog()
    assert_not_null(catalog)
    if catalog == null:
        return null
    var combat := ProductionCombatState.new(100)
    var turn := _turn_in_action() if in_action else TurnController.new(TurnBudget.new())
    return {
        "session": load(SESSION_PATH).new(turn, combat, catalog),
        "turn": turn,
        "combat": combat,
    }

func test_action_input_is_rejected_before_action_phase_without_resource_mutation() -> void:
    var fixture = _make_session(false)
    if fixture == null:
        return
    var combat: ProductionCombatState = fixture["combat"]
    combat.apply_energy_delta(100)
    combat.gain_stock(6)
    var energy_before: int = combat.energy
    var stock_before: int = combat.stock

    var result: Dictionary = fixture["session"].select_technique("atk_t1_quick_cut")

    assert_false(result["accepted"])
    assert_eq(result["reason"], "WRONG_PHASE")
    assert_eq(combat.energy, energy_before)
    assert_eq(combat.stock, stock_before)

func test_readiness_distinguishes_stock_shortage_from_energy_shortage() -> void:
    var fixture = _make_session()
    if fixture == null:
        return
    var combat: ProductionCombatState = fixture["combat"]

    var stock_missing: Dictionary = fixture["session"].readiness("atk_t3_rift_breach")
    assert_eq(stock_missing["state"], "STOCK_INSUFFICIENT")
    assert_eq(stock_missing["stock_required"], 3)

    combat.gain_stock(3)
    var energy_missing: Dictionary = fixture["session"].readiness("atk_t3_rift_breach")
    assert_eq(energy_missing["state"], "ENERGY_INSUFFICIENT")
    assert_eq(energy_missing["energy_required"], 16)

    combat.apply_energy_delta(16)
    var ready: Dictionary = fixture["session"].readiness("atk_t3_rift_breach")
    assert_eq(ready["state"], "READY")
    assert_true(ready["ready"])

func test_unknown_technique_is_rejected_without_mutation() -> void:
    var fixture = _make_session()
    if fixture == null:
        return
    var combat: ProductionCombatState = fixture["combat"]
    combat.apply_energy_delta(100)
    combat.gain_stock(6)

    var result: Dictionary = fixture["session"].select_technique("missing_technique")

    assert_false(result["accepted"])
    assert_eq(result["reason"], "UNKNOWN_TECHNIQUE")
    assert_eq(combat.energy, 100)
    assert_eq(combat.stock, 6)

func test_legal_selection_spends_exact_dual_resource_cost_and_exits_action_phase() -> void:
    var fixture = _make_session()
    if fixture == null:
        return
    var combat: ProductionCombatState = fixture["combat"]
    var turn: TurnController = fixture["turn"]
    combat.apply_energy_delta(40)
    combat.gain_stock(6)

    var result: Dictionary = fixture["session"].select_technique("atk_t3_rift_breach")

    assert_true(result["accepted"])
    assert_eq(result["technique_id"], "atk_t3_rift_breach")
    assert_eq(combat.energy, 24, "T3 seed cost is 16 Energy")
    assert_eq(combat.stock, 3, "Tier 3 spends exactly 3 Stock")
    assert_eq(turn.phase, TurnPhase.PLAYER_RESOLVE)
    assert_not_null(turn.pending_player_action)
    assert_eq(turn.pending_player_action.id, "atk_t3_rift_breach")
    assert_true(turn.turn_budget.frozen, "Action selection ends player decision time")

func test_failed_selection_is_atomic_when_one_resource_is_missing() -> void:
    var fixture = _make_session()
    if fixture == null:
        return
    var combat: ProductionCombatState = fixture["combat"]
    var turn: TurnController = fixture["turn"]
    combat.apply_energy_delta(100)
    combat.gain_stock(2)

    var result: Dictionary = fixture["session"].select_technique("atk_t3_rift_breach")

    assert_false(result["accepted"])
    assert_eq(result["reason"], "STOCK_INSUFFICIENT")
    assert_eq(combat.energy, 100)
    assert_eq(combat.stock, 2)
    assert_eq(turn.phase, TurnPhase.ACTION)
    assert_null(turn.pending_player_action)
