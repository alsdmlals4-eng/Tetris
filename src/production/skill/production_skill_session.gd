class_name ProductionSkillSession
extends RefCounted

var turn_controller: TurnController
var combat_state: ProductionCombatState
var catalog: ProductionSkillCatalog

func _init(p_turn_controller: TurnController, p_combat_state: ProductionCombatState, p_catalog: ProductionSkillCatalog) -> void:
    turn_controller = p_turn_controller
    combat_state = p_combat_state
    catalog = p_catalog

func readiness(technique_id: String) -> Dictionary:
    var definition := catalog.get_by_id(technique_id)
    if definition.is_empty():
        return {
            "ready": false,
            "state": "UNKNOWN_TECHNIQUE",
        }

    var stock_required := int(definition["stock_cost"])
    var energy_required := int(definition["energy_cost"])

    if combat_state.stock < stock_required:
        return {
            "ready": false,
            "state": "STOCK_INSUFFICIENT",
            "stock_required": stock_required,
            "energy_required": energy_required,
        }
    if combat_state.energy < energy_required:
        return {
            "ready": false,
            "state": "ENERGY_INSUFFICIENT",
            "stock_required": stock_required,
            "energy_required": energy_required,
        }

    return {
        "ready": true,
        "state": "READY",
        "stock_required": stock_required,
        "energy_required": energy_required,
    }

func select_technique(technique_id: String) -> Dictionary:
    if turn_controller.phase != TurnPhase.ACTION:
        return {
            "accepted": false,
            "reason": "WRONG_PHASE",
        }

    var definition := catalog.get_by_id(technique_id)
    if definition.is_empty():
        return {
            "accepted": false,
            "reason": "UNKNOWN_TECHNIQUE",
        }

    var ready_state := readiness(technique_id)
    if not bool(ready_state.get("ready", false)):
        return {
            "accepted": false,
            "reason": String(ready_state.get("state", "NOT_READY")),
        }

    var energy_cost := int(definition["energy_cost"])
    var stock_cost := int(definition["stock_cost"])
    if not combat_state.try_spend_skill_cost(energy_cost, stock_cost):
        return {
            "accepted": false,
            "reason": "RESOURCE_SPEND_FAILED",
        }

    if not turn_controller.select_player_action(technique_id):
        combat_state.apply_energy_delta(energy_cost)
        combat_state.gain_stock(stock_cost)
        return {
            "accepted": false,
            "reason": "ACTION_COMMIT_FAILED",
        }

    return {
        "accepted": true,
        "reason": "READY",
        "technique_id": technique_id,
        "energy_spent": energy_cost,
        "stock_spent": stock_cost,
    }
