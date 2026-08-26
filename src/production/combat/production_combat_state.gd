class_name ProductionCombatState
extends RefCounted

const STOCK_CAP: int = 6

var max_hp: int
var hp: int
var energy: int = 0
var stock: int = 0

func _init(p_max_hp: int = 100) -> void:
    max_hp = maxi(1, p_max_hp)
    hp = max_hp

func gain_stock(amount: int) -> Dictionary:
    if amount <= 0:
        return {
            "applied": 0,
            "lost_at_cap": 0,
        }

    var capacity: int = maxi(0, STOCK_CAP - stock)
    var applied: int = mini(amount, capacity)
    stock += applied
    return {
        "applied": applied,
        "lost_at_cap": amount - applied,
    }

func lose_stock(amount: int) -> int:
    if amount <= 0:
        return 0
    var applied := mini(amount, stock)
    stock -= applied
    return applied

func apply_energy_delta(delta: int) -> int:
    var before: int = energy
    energy = maxi(0, energy + delta)
    return energy - before

func try_spend_skill_cost(energy_cost: int, stock_cost: int) -> bool:
    if energy_cost < 0 or stock_cost < 0 or stock_cost > STOCK_CAP:
        return false
    if energy < energy_cost or stock < stock_cost:
        return false

    energy -= energy_cost
    stock -= stock_cost
    return true

func stock_cost_for_tier(tier: int) -> int:
    if tier < 1 or tier > STOCK_CAP:
        return -1
    return tier

func apply_line_event(event: Dictionary) -> bool:
    if event.get("kind", &"") != &"production_line_resolved":
        return false
    if not event.has("energy_delta"):
        return false

    var delta: int = int(event["energy_delta"])
    if delta < 0:
        return false

    apply_energy_delta(delta)
    return true

func apply_damage(amount: int) -> int:
    if amount <= 0:
        return 0
    var before: int = hp
    hp = maxi(0, hp - amount)
    return before - hp

func heal(amount: int) -> int:
    if amount <= 0:
        return 0
    var before: int = hp
    hp = mini(max_hp, hp + amount)
    return hp - before

func is_defeated() -> bool:
    return hp <= 0
