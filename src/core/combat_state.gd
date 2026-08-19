class_name CombatState
extends RefCounted

const CHAIN_STOCK_CAP := 5
const EMERGENCY_ENERGY_FLOOR := 15

var player_hp: int = 200
var player_max_hp: int = 200
var shield: int = 0
var enemy_hp: int = 300
var enemy_max_hp: int = 300
var energy: int = 0
var chain_stock: int = 0
var score: int = 0
var combat_time: float = 0.0

var _energy_recovery_accumulator: float = 0.0

func tick(delta: float) -> void:
    if delta <= 0.0:
        return
    combat_time += delta
    if energy >= EMERGENCY_ENERGY_FLOOR:
        _energy_recovery_accumulator = 0.0
        return
    _energy_recovery_accumulator += delta
    while _energy_recovery_accumulator >= 1.0 and energy < EMERGENCY_ENERGY_FLOOR:
        energy += 1
        _energy_recovery_accumulator -= 1.0
    if energy >= EMERGENCY_ENERGY_FLOOR:
        energy = EMERGENCY_ENERGY_FLOOR
        _energy_recovery_accumulator = 0.0

func gain_energy(amount: int) -> void:
    if amount <= 0:
        return
    energy += amount
    if energy >= EMERGENCY_ENERGY_FLOOR:
        _energy_recovery_accumulator = 0.0

func add_score(amount: int) -> void:
    if amount > 0:
        score += amount

func set_chain_stock_from_completed_chain(chain_count: int) -> void:
    var clamped_chain := clampi(chain_count, 0, CHAIN_STOCK_CAP)
    chain_stock = maxi(chain_stock, clamped_chain)

func can_spend_skill(tier: int, energy_cost: int) -> bool:
    if tier < 1 or tier > CHAIN_STOCK_CAP:
        return false
    if energy_cost < 0:
        return false
    return chain_stock >= tier and energy >= energy_cost

func spend_skill(tier: int, energy_cost: int) -> bool:
    if not can_spend_skill(tier, energy_cost):
        return false
    if energy >= EMERGENCY_ENERGY_FLOOR:
        _energy_recovery_accumulator = 0.0
    energy -= energy_cost
    chain_stock -= tier
    return true

func apply_incoming_damage(amount: int) -> void:
    if amount <= 0:
        return
    var absorbed := mini(shield, amount)
    shield -= absorbed
    var remaining := amount - absorbed
    player_hp = clampi(player_hp - remaining, 0, player_max_hp)
