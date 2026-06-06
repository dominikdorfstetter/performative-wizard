extends Node
## Dev tool: click all the way through a real new game into a rendered, played fight,
## firing real button signals and using real change_scene_to_file transitions.

func _all_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for c in node.get_children():
		_all_buttons(c, out)

func _scene() -> Node:
	return get_tree().current_scene

func _click_text(contains: String) -> bool:
	var bs: Array = []
	_all_buttons(_scene(), bs)
	for b in bs:
		if contains.to_lower() in (b as Button).text.to_lower():
			print("[click]   press text '", b.text, "'")
			b.emit_signal("pressed")
			return true
	print("[click]   text '", contains, "' NOT FOUND")
	return false

func _click_big() -> bool:
	var bs: Array = []
	_all_buttons(_scene(), bs)
	for b in bs:
		if (b as Button).custom_minimum_size.x >= 280:
			print("[click]   press big button")
			b.emit_signal("pressed")
			return true
	print("[click]   no big button")
	return false

func _click_node() -> bool:
	var bs: Array = []
	_all_buttons(_scene(), bs)
	for b in bs:
		var bb := b as Button
		if not bb.disabled and bb.text == "" and bb.size.x <= 70 and bb.size.x > 0:
			print("[click]   press map node")
			bb.emit_signal("pressed")
			return true
	print("[click]   no clickable map node")
	return false

func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame

func _ready() -> void:
	GameState.new_game()
	await _wait(4)
	var mm: Node = load("res://scenes/hub/main_menu.tscn").instantiate()
	get_tree().root.add_child(mm)
	get_tree().current_scene = mm
	await _wait(20)
	print("[click] @", _scene().name)
	_click_text("New Game")
	await _wait(25)
	print("[click] @", _scene().name)
	_click_big()                       # pick first wizard
	await _wait(25)
	print("[click] @", _scene().name)
	_click_text("get it")              # dressing room -> map
	await _wait(25)
	print("[click] @", _scene().name)
	_click_node()                      # first map node -> combat
	await _wait(30)
	print("[click] @", _scene().name)
	get_viewport().get_texture().get_image().save_png("/tmp/pw_click_combat.png")
	print("[click] combat screenshot saved")
	# play through a couple of turns in the real UI
	var combat := _scene()
	if combat.has_method("_on_end_turn"):
		for t in 3:
			var cm = combat.cm
			if cm == null or cm.state >= 2:
				break
			cm.energy = 9
			for card in cm.hand.duplicate():
				if cm.can_play(card):
					cm.play_card(card)
					await _wait(6)
			await _wait(6)
			if cm.state < 2:
				combat._on_end_turn()
			await _wait(20)
		print("[click] played turns, state handled")
	await _wait(20)
	print("[click] DONE without hang @", _scene().name)
	get_tree().quit()
