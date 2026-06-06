extends Node
## Dev tool: reproduce New Game *with existing progress* (so _confirm_new_game runs
## and _clear() frees the banter timer/bubbles mid-animation), then let time pass so
## any tween/timer touching a freed node surfaces.

func _find_button(node: Node, contains: String) -> Button:
	if node is Button and contains.to_lower() in (node as Button).text.to_lower():
		return node
	for c in node.get_children():
		var r := _find_button(c, contains)
		if r != null:
			return r
	return null

func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame

func _ready() -> void:
	# fake existing progress so New Game shows the confirm dialog
	GameState.clout = 50
	GameState.unlocked_outfits.append(&"pointed_hat_swag")
	await _wait(4)
	var mm: Node = load("res://scenes/hub/main_menu.tscn").instantiate()
	get_tree().root.add_child(mm)
	get_tree().current_scene = mm
	# let a banter bubble appear (its pop tween is mid-flight), then click New Game
	await _wait(8)
	var b := _find_button(mm, "New Game")
	print("[confirm] clicking New Game (has_progress)")
	b.emit_signal("pressed")
	# now sit on the confirm dialog across several banter-timer intervals (2.6s each)
	print("[confirm] waiting through banter timer ticks...")
	await _wait(360)   # ~6s at 60fps
	print("[confirm] DONE")
	get_tree().quit()
