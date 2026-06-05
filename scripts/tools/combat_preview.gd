extends Node
## Dev tool: set up a fight, render the combat scene, screenshot it for inspection.

func _ready() -> void:
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	# force a 2-enemy node so we can see the multi-enemy layout
	GameState.map[0][0]["enemies"] = [&"alley_cat", &"angry_toaster"]
	GameState.enter(0, 0)
	var combat: Node = load("res://scenes/combat/combat.tscn").instantiate()
	add_child(combat)
	await get_tree().create_timer(0.8).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/pw_combat.png")
	print("saved /tmp/pw_combat.png")
	get_tree().quit()
