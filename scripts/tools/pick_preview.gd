extends Node
## Dev tool: render the peek_pick modal (Vision Board's "take one" overlay).
## Run windowed:  PW_NO_SAVE=1 godot scenes/tools/pick_preview.tscn
## Writes /tmp/a_pick.png.

func _ready() -> void:
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	GameState.seen_tutorial = true   # keep the tutorial layer out of the shot
	GameState.enter(0, 0)
	var s: Node = load("res://scenes/combat/combat.tscn").instantiate()
	add_child(s)
	await get_tree().create_timer(0.6).timeout
	s.cm.request_pick(3)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/a_pick.png")
	print("[pick_preview] wrote /tmp/a_pick.png")
	get_tree().quit()
