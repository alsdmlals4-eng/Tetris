## 스킬 효과가 사용할 최소 전투 대상 집합을 해석한다.
class_name TargetPattern
extends RefCounted

static func resolve(mode: String, context: Dictionary) -> Array:
	match mode:
		"SELF":
			return [context.get("player")] if context.get("player") != null else []
		"SINGLE_ENEMY":
			return [context.get("enemy")] if context.get("enemy") != null else []
		"ALL_ENEMIES":
			if context.get("enemies") is Array:
				return context["enemies"].filter(func(target): return target != null)
			return [context.get("enemy")] if context.get("enemy") != null else []
	return []
