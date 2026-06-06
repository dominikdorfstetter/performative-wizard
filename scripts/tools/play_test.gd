extends Node
## Dev tool: play a real fight across multiple turns (cards + end_turn -> enemy
## turn -> goon end-of-turn attacks), for each wizard, watching for a hang/crash.

func _play_wizard(wid: StringName) -> void:
	print("[play] === ", wid, " ===")
	GameState.new_game()
	GameState.start_run(wid)
	GameState.finalize_loadout()
	GameState.map[0][0]["enemies"] = [&"black_cat", &"shade_thrower"]
	GameState.enter(0, 0)
	await get_tree().process_frame
	var combat: Node = load("res://scenes/combat/combat.tscn").instantiate()
	get_tree().root.add_child(combat)
	get_tree().current_scene = combat
	await get_tree().process_frame
	await get_tree().process_frame
	var cm = combat.cm
	var guard := 0
	while cm.state == 0 or cm.state == 1:   # PLAYER_TURN or ENEMY_TURN
		guard += 1
		if guard > 200:
			print("[play]   !!! turn loop exceeded 200 iterations — HANG")
			break
		if cm.state == 0:
			cm.energy = 9
			# play every playable card in hand
			var played := false
			for card in cm.hand.duplicate():
				if cm.can_play(card):
					cm.play_card(card)
					played = true
					if cm.state >= 2:
						break
			if cm.state >= 2:
				break
			cm.end_turn()
			await get_tree().process_frame
	print("[play]   ended in state=", cm.state, " after ", guard, " iters")
	if is_instance_valid(combat):
		combat.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	for wid in [&"fire", &"necro", &"rizz"]:
		await _play_wizard(wid)
	print("[play] ALL WIZARDS OK")
	get_tree().quit()
