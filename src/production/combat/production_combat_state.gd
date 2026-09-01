## 전투 중 HP와 Energy·Stock 자원을 소유하는 최소 상태 모델이다.
class_name ProductionCombatState
extends RefCounted

const MP_CAP: int = 60
const COMBO_CAP: int = 10
const STOCK_CAP: int = COMBO_CAP

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

    var capacity: int = maxi(0, COMBO_CAP - stock)
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
    energy = clampi(energy + delta, 0, MP_CAP)
    return energy - before

func apply_chain_wave(line_lengths: Array[int]) -> Dictionary:
    var qualified_total: int = 0
    for length in line_lengths:
        if length >= 3:
            qualified_total += length
    if qualified_total == 0:
        return {
            "combo_before": stock,
            "combo_after": stock,
            "mp_requested": 0,
            "mp_applied": 0,
            "mp_lost_at_cap": 0,
        }

    var combo_before: int = stock
    stock = mini(COMBO_CAP, stock + 1)
    var requested: int = qualified_total - 3 + stock
    var before_mp: int = energy
    energy = clampi(energy + requested, 0, MP_CAP)
    var applied: int = energy - before_mp
    return {
        "combo_before": combo_before,
        "combo_after": stock,
        "mp_requested": requested,
        "mp_applied": applied,
        "mp_lost_at_cap": requested - applied,
    }

func reset_combo() -> int:
    var previous: int = stock
    stock = 0
    return previous

func try_spend_mp(amount: int) -> bool:
    if amount <= 0 or energy < amount:
        return false
    energy -= amount
    return true

func try_commit_combo_skill(mp_cost: int, opening_combo: int, resolved_stage: int) -> Dictionary:
    var converted: int = opening_combo - resolved_stage
    if opening_combo != stock or resolved_stage < 1 or converted < 0 or mp_cost < 0:
        return {"committed": false, "reason": "INVALID_COMBO_TRANSACTION"}

    var available: int = mini(MP_CAP, energy + converted * 5)
    if available < mp_cost:
        return {"committed": false, "reason": "INSUFFICIENT_RESOURCE"}

    energy = available - mp_cost
    stock = 0
    return {
        "committed": true,
        "resolved_stage": resolved_stage,
        "converted_combo": converted,
        "mp_spent": mp_cost,
        "combo_spent": opening_combo,
    }

func try_spend_skill_cost(energy_cost: int, stock_cost: int) -> bool:
    if energy_cost < 0 or stock_cost < 0 or stock_cost > COMBO_CAP:
        return false
    if energy < energy_cost or stock < stock_cost:
        return false

    energy -= energy_cost
    stock -= stock_cost
    return true

func stock_cost_for_tier(tier: int) -> int:
    if tier < 1 or tier > COMBO_CAP:
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

func snapshot_state() -> Dictionary:
    return {"max_hp": max_hp, "hp": hp, "energy": energy, "stock": stock}

func restore_state(snapshot: Dictionary) -> bool:
    for key in ["max_hp", "hp", "energy", "stock"]:
        if not snapshot.has(key) or not (snapshot[key] is int):
            return false
    var restored_max_hp := int(snapshot["max_hp"])
    var restored_hp := int(snapshot["hp"])
    var restored_energy := int(snapshot["energy"])
    var restored_stock := int(snapshot["stock"])
    if restored_max_hp != max_hp or restored_hp < 0 or restored_hp > max_hp or restored_energy < 0 or restored_energy > MP_CAP or restored_stock < 0 or restored_stock > COMBO_CAP:
        return false
    hp = restored_hp
    energy = restored_energy
    stock = restored_stock
    return true

func resource_snapshot() -> Dictionary:
    return snapshot_state()

func restore_resource_snapshot(snapshot: Dictionary) -> bool:
    return restore_state(snapshot)
