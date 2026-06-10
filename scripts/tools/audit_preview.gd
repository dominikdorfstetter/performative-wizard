extends Node
## Dev tool: render every screen for a design audit.

const SCENES := [
	["res://scenes/hub/main_menu.tscn", "/tmp/a_menu.png"],
	["res://scenes/hub/class_select.tscn", "/tmp/a_class.png"],
	["res://scenes/hub/dressing_room.tscn", "/tmp/a_dress.png"],
	["res://scenes/hub/boutique.tscn", "/tmp/a_boutique.png"],
	["res://scenes/hub/options.tscn", "/tmp/a_options.png"],
	["res://scenes/map/map.tscn", "/tmp/a_map.png"],
	["res://scenes/combat/combat.tscn", "/tmp/a_combat.png"],
	["res://scenes/reward.tscn", "/tmp/a_reward.png"],
	["res://scenes/nodes/shop.tscn", "/tmp/a_shop.png"],
	["res://scenes/nodes/rest.tscn", "/tmp/a_rest.png"],
	["res://scenes/nodes/event.tscn", "/tmp/a_event.png"],
	["res://scenes/nodes/chest.tscn", "/tmp/a_chest.png"],
]

func _ready() -> void:
	GameState.start_run(&"necro")
	GameState.finalize_loadout()
	GameState.gold = 150
	GameState.clout = 180
	GameState.enter(0, 0)
	GameState.map[0][0]["enemies"] = [&"garden_gnome", &"sock_puppet", &"haunted_umbrella"]
	for pair in SCENES:
		var s: Node = load(pair[0]).instantiate()
		add_child(s)
		await get_tree().create_timer(0.7).timeout
		get_viewport().get_texture().get_image().save_png(pair[1])
		s.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("audit rendered")
	get_tree().quit()
