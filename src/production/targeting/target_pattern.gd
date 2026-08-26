class_name TargetPattern
extends RefCounted

static func resolve(mode: String, context: Dictionary) -> Array:
    match mode:
        "SELF":
            var player = context.get("player")
            return [player] if player != null else []
        "SINGLE_ENEMY":
            var enemy = context.get("enemy")
            return [enemy] if enemy != null else []
        "ALL_ENEMIES":
            var enemies_value = context.get("enemies", [])
            if enemies_value is Array and not enemies_value.is_empty():
                var targets: Array = []
                for enemy in enemies_value:
                    if enemy != null:
                        targets.append(enemy)
                return targets
            var fallback = context.get("enemy")
            return [fallback] if fallback != null else []
        _:
            return []
