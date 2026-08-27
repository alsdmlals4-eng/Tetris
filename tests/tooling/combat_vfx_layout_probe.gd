# 전투 VFX의 실제 CombatStage 배치와 렌더 출력을 점검하는 일회성 Godot probe입니다.
extends SceneTree

func _init() -> void:
	var battle: Node = load("res://scenes/production/battle.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await process_frame
	battle.call("_trigger_vanguard_attack_fx")
	await process_frame
	var stage := battle.get_node("MainRow/CombatColumn/CombatStage") as Control
	var slash := battle.get_node("MainRow/CombatColumn/CombatStage/VanguardAttackAccent") as TextureRect
	var telegraph := battle.get_node("MainRow/CombatColumn/CombatStage/GatebreakerThreatTelegraph") as TextureRect
	var vanguard := battle.get_node("MainRow/CombatColumn/CombatStage/VanguardReference") as TextureRect
	var gatebreaker := battle.get_node("MainRow/CombatColumn/CombatStage/GatebreakerReference") as TextureRect
	print("stage_rect=%s slash_rect=%s telegraph_rect=%s vanguard_rect=%s gatebreaker_rect=%s" % [stage.get_global_rect(), slash.get_global_rect(), telegraph.get_global_rect(), vanguard.get_global_rect(), gatebreaker.get_global_rect()])
	print("telegraph_visible=%s slash_visible=%s" % [telegraph.visible, slash.visible])
	var output_path := "user://combat_vfx_layout_probe.png"
	print("render_path=%s save_error=%s" % [ProjectSettings.globalize_path(output_path), root.get_viewport().get_texture().get_image().save_png(output_path)])
	quit()
