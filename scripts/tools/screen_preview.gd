extends Node
## Dev tool: render several screens to PNGs for inspection.

const SCENES := [
	["res://scenes/hub/dressing_room.tscn", "/tmp/pw_dress.png"],
	["res://scenes/nodes/shop.tscn", "/tmp/pw_shop.png"],
	["res://scenes/nodes/rest.tscn", "/tmp/pw_rest.png"],
]

func _ready() -> void:
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	GameState.gold = 120
	for pair in SCENES:
		var s: Node = load(pair[0]).instantiate()
		add_child(s)
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png(pair[1])
		s.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("rendered screens")
	get_tree().quit()
