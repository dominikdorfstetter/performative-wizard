extends Node
## Dev tool: summon a squad of goons, screenshot them on the field, then sacrifice
## one and screenshot the consume animation.

func _ready() -> void:
	GameState.start_run(&"necro")
	GameState.finalize_loadout()
	GameState.map[0][0]["enemies"] = [&"feral_houseplant"]
	GameState.enter(0, 0)
	await get_tree().process_frame
	var combat: Node = load("res://scenes/combat/combat.tscn").instantiate()
	get_tree().root.add_child(combat)
	get_tree().current_scene = combat
	await get_tree().process_frame
	await get_tree().process_frame
	var cm = combat.cm
	cm.energy = 9
	# summon 4 goons
	cm.hand.clear()
	cm.hand.append(Database.get_card(&"mass_grave"))
	cm.play_card(cm.hand[0])
	cm.hand.clear()
	cm.hand.append(Database.get_card(&"mass_grave"))
	cm.play_card(cm.hand[0])
	await get_tree().create_timer(0.7).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/pw_goons.png")
	print("saved /tmp/pw_goons.png  (undead=%d)" % cm.player.status(&"undead"))
	# sacrifice one to KILL the last enemy -> goon consume + combat-end together
	cm.enemies[0].hp = 3
	cm.energy = 9
	cm.hand.clear()
	cm.hand.append(Database.get_card(&"macabre_bow"))
	cm.play_card(cm.hand[0])
	await get_tree().create_timer(0.12).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/pw_goons_sac.png")
	print("saved /tmp/pw_goons_sac.png  (undead=%d)" % cm.player.status(&"undead"))
	await get_tree().create_timer(0.6).timeout
	print("done, no crash")
	get_tree().quit()
