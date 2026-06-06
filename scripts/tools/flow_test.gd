extends Node
## Dev tool: walk the new-game scene path and report each step, so a hang/crash
## shows up at a specific scene instead of just "the window froze".

func _step(label: String, path: String) -> void:
	print("[flow] loading: ", label)
	var scn: PackedScene = load(path)
	if scn == null:
		print("[flow]   FAILED to load ", path)
		return
	var inst: Node = scn.instantiate()
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	for i in 8:
		await get_tree().process_frame
	print("[flow]   ok: ", label)
	inst.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	print("[flow] new_game()")
	GameState.new_game()
	print("[flow]   clout=", GameState.clout, " owned=", GameState.unlocked_outfits.size())
	await _step("main_menu", "res://scenes/hub/main_menu.tscn")
	await _step("class_select", "res://scenes/hub/class_select.tscn")
	print("[flow] start_run(fire)")
	GameState.start_run(&"fire")
	print("[flow]   map rows=", GameState.map.size())
	await _step("dressing_room", "res://scenes/hub/dressing_room.tscn")
	GameState.finalize_loadout()
	print("[flow]   deck=", GameState.deck.size())
	await _step("map", "res://scenes/map/map.tscn")
	# enter the first combat node, like clicking it on the map
	print("[flow] entering combat node 0,0")
	GameState.enter(0, 0)
	var combat: Node = load("res://scenes/combat/combat.tscn").instantiate()
	get_tree().root.add_child(combat)
	get_tree().current_scene = combat
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/tmp/pw_flow_combat.png")
	print("[flow] combat rendered, saved screenshot")
	print("[flow] ALL SCENES OK")
	get_tree().quit()
