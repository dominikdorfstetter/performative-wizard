extends Node
## Dev tool: stage and capture the marketing screenshot set for the itch page at
## exactly 1152x648. Run WINDOWED (occluded windows capture stale frames):
##   PW_NO_SAVE=1 godot scenes/tools/marketing_shots.tscn
## Writes /tmp/mk_*.png — copy the keepers into dist/screenshots/.

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1152, 648)
	await get_tree().process_frame

	# 1. menu (version footer)
	GameState.new_game()
	await _shot("res://scenes/hub/main_menu.tscn", "/tmp/mk_menu.png")

	# 2. the rack at full unlock (rizz = loudest colors)
	for id in Database.outfits:
		if not GameState.unlocked_outfits.has(id):
			GameState.unlocked_outfits.append(id)
	GameState.start_run(&"rizz")
	await _shot("res://scenes/hub/dressing_room.tscn", "/tmp/mk_dress.png")

	# 3. act 2 the Scene: disco ball + mannequin on the club floor
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	GameState.act = 2
	GameState.map = MapGenerator.generate(12345, 2)
	GameState.enter(0, 0)
	GameState.map[0][0]["enemies"] = [&"disco_ball", &"possessed_mannequin"]
	await _shot("res://scenes/combat/combat.tscn", "/tmp/mk_scene_fight.png", 1.6)

	# 4. act 2 boss: THE BOUNCER at the neon door
	GameState.map[0][0]["enemies"] = [&"the_bouncer"]
	GameState.map[0][0]["type"] = "Boss"
	await _shot("res://scenes/combat/combat.tscn", "/tmp/mk_bouncer.png", 1.6)

	# 5. act 3 the Feed: the IRS mid-audit next to a reply guy
	GameState.act = 3
	GameState.map[0][0]["enemies"] = [&"the_irs", &"reply_guy"]
	GameState.map[0][0]["type"] = "Combat"
	await _shot("res://scenes/combat/combat.tscn", "/tmp/mk_irs.png", 1.6)

	# 6. act 3 finale: the Talent Agent with the roster on stage
	GameState.map[0][0]["enemies"] = [&"the_talent_agent", &"critic_jr", &"bouncer_jr"]
	GameState.map[0][0]["type"] = "Boss"
	await _shot("res://scenes/combat/combat.tscn", "/tmp/mk_agent.png", 1.6)

	# 7. the act 2 map
	GameState.act = 2
	GameState.map = MapGenerator.generate(777, 2)
	GameState.pos_row = -1
	GameState.pos_col = -1
	await _shot("res://scenes/map/map.tscn", "/tmp/mk_map.png")

	# 8. boutique (rarity-tinted relic stall era)
	GameState.clout = 220
	await _shot("res://scenes/hub/boutique.tscn", "/tmp/mk_boutique.png")

	print("marketing shots rendered")
	get_tree().quit()

func _shot(scene: String, path: String, wait := 0.8) -> void:
	var s: Node = load(scene).instantiate()
	add_child(s)
	await get_tree().create_timer(wait).timeout
	get_viewport().get_texture().get_image().save_png(path)
	s.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
