extends Node
## Dev tool: render the map scene for inspection.

func _ready() -> void:
	GameState.start_run(&"necro")
	GameState.finalize_loadout()
	var m: Node = load("res://scenes/map/map.tscn").instantiate()
	add_child(m)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/pw_map.png")
	print("saved /tmp/pw_map.png")
	get_tree().quit()
