extends GutTest

const TARGET_PATTERN_PATH := "res://src/production/targeting/target_pattern.gd"

func _resolver():
    assert_true(ResourceLoader.exists(TARGET_PATTERN_PATH), "TargetPattern script must exist")
    if not ResourceLoader.exists(TARGET_PATTERN_PATH):
        return null
    return load(TARGET_PATTERN_PATH)

func test_all_enemies_with_single_gatebreaker_keeps_all_enemies_semantics_and_returns_one_target() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var gatebreaker := ProductionCombatState.new(120)

    var targets: Array = resolver.resolve("ALL_ENEMIES", {"enemies": [gatebreaker]})

    assert_eq(targets.size(), 1)
    assert_same(targets[0], gatebreaker)

func test_single_enemy_and_self_resolve_only_their_declared_targets() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var player := ProductionCombatState.new(100)
    var gatebreaker := ProductionCombatState.new(120)

    var self_targets: Array = resolver.resolve("SELF", {"player": player, "enemy": gatebreaker})
    var enemy_targets: Array = resolver.resolve("SINGLE_ENEMY", {"player": player, "enemy": gatebreaker})

    assert_eq(self_targets.size(), 1)
    assert_same(self_targets[0], player)
    assert_eq(enemy_targets.size(), 1)
    assert_same(enemy_targets[0], gatebreaker)

func test_all_enemies_can_use_first_slice_single_enemy_fallback_without_inventing_a_mob_roster() -> void:
    var resolver = _resolver()
    if resolver == null:
        return
    var gatebreaker := ProductionCombatState.new(120)

    var targets: Array = resolver.resolve("ALL_ENEMIES", {"enemy": gatebreaker})

    assert_eq(targets.size(), 1)
    assert_same(targets[0], gatebreaker)

func test_missing_or_unknown_targets_fail_closed() -> void:
    var resolver = _resolver()
    if resolver == null:
        return

    assert_true(resolver.resolve("SELF", {}).is_empty())
    assert_true(resolver.resolve("SINGLE_ENEMY", {}).is_empty())
    assert_true(resolver.resolve("ALL_ENEMIES", {}).is_empty())
    assert_true(resolver.resolve("INVENTED_TARGET_MODE", {"enemy": ProductionCombatState.new(100)}).is_empty())
