extends Node
## Dev tool: drive a real combat to victory exactly as the game does (combat is the
## current scene; the killing blow goes through CombatManager.play_card), so the
## post-fight signal cascade + scene change runs faithfully.

func _ready() -> void:
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	GameState.map[0][0]["enemies"] = [&"alley_cat", &"black_cat"]
	GameState.map[0][0]["type"] = "Boss"
	GameState.enter(0, 0)
	await get_tree().process_frame
	var combat: Node = load("res://scenes/combat/combat.tscn").instantiate()
	get_tree().root.add_child(combat)
	get_tree().current_scene = combat
	await get_tree().process_frame
	await get_tree().process_frame
	var cm = combat.cm
	print("[winflow] combat up, enemy hp=", cm.enemies[0].hp)
	for en in cm.enemies:
		en.hp = 3
	cm.energy = 9
	cm.hand.clear()
	cm.hand.append(Database.get_card(&"cinder_spray"))   # damage_all -> kills both at once
	cm.play_card(cm.hand[0])   # lethal -> _finish -> combat_ended + changed cascade
	print("[winflow] state after lethal=", cm.state)
	for i in 20:
		await get_tree().process_frame
	print("[winflow] survived post-fight; current scene=", get_tree().current_scene)
	get_tree().quit()
