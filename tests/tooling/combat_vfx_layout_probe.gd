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
	# 표시 가능한 렌더러에서는 PNG를 남기고, headless에서는 명확한 실패 코드로 끝낸다.
	if DisplayServer.get_name() == "headless":
		push_error("combat_vfx_layout_probe requires a display-capable renderer to capture a viewport PNG")
		quit(2)
		return
	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		push_error("combat_vfx_layout_probe requires a display-capable renderer to capture a viewport PNG")
		quit(2)
		return
	var viewport_image := viewport_texture.get_image()
	if viewport_image == null:
		push_error("combat_vfx_layout_probe could not obtain a viewport image")
		quit(2)
		return
	var output_path := "user://combat_vfx_layout_probe.png"
	var save_error := viewport_image.save_png(output_path)
	print("render_path=%s save_error=%s" % [ProjectSettings.globalize_path(output_path), save_error])
	quit(save_error)
