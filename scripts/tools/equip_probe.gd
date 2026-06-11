extends Node
## Dev tool: headless interaction check for the dressing room rack. Presses a real
## chip and verifies the surgical refresh — exactly one WORN badge, on the right chip,
## rail + summary updated, scroll position untouched — then a rail jump and a no-op
## re-press. Run after touching dressing_room.gd:
##   PW_NO_SAVE=1 godot --headless scenes/tools/equip_probe.tscn

func _ready() -> void:
	var fails := 0
	for id in Database.outfits:
		if not GameState.unlocked_outfits.has(id):
			GameState.unlocked_outfits.append(id)
	GameState.start_run(&"rizz")
	var s: Control = load("res://scenes/hub/dressing_room.tscn").instantiate()
	add_child(s)
	await get_tree().create_timer(0.4).timeout

	var grids: Dictionary = s.get("_grids")
	var rail: Dictionary = s.get("_rail_chips")
	var scroll: ScrollContainer = s.get("_scroll")
	var hint: Label = s.get("_hint")

	# scroll down, then equip a non-worn hat chip
	scroll.scroll_vertical = 30
	await get_tree().process_frame
	var hat_grid: GridContainer = grids["Hat"]
	var target: Button = null
	for chip in hat_grid.get_children():
		if chip.get_meta("piece_id") != GameState.equipped_id("Hat"):
			target = chip
			break
	var prev_worn := GameState.equipped_id("Hat")
	target.pressed.emit()
	await get_tree().process_frame

	var new_id: StringName = target.get_meta("piece_id")
	if GameState.equipped_id("Hat") != new_id:
		fails += 1; print("FAIL: equip did not change GameState")
	var worn_count := 0
	for chip in hat_grid.get_children():
		var badge: Label = chip.get_node("Worn")
		if badge.visible:
			worn_count += 1
			if chip.get_meta("piece_id") != new_id:
				fails += 1; print("FAIL: WORN badge on wrong chip")
	if worn_count != 1:
		fails += 1; print("FAIL: expected exactly 1 WORN badge, got %d" % worn_count)
	if scroll.scroll_vertical != 30:
		fails += 1; print("FAIL: scroll position reset to %d" % scroll.scroll_vertical)
	var rail_hat: Button = rail["Hat"]
	var rail_name: Label = rail_hat.get_node("PieceName")
	if rail_name.text != Loc.t(Database.get_outfit(new_id).title):
		fails += 1; print("FAIL: rail label not updated: " + rail_name.text)
	if not hint.visible:
		fails += 1; print("FAIL: scroll hint should be visible at full unlock")

	# rail jump tweens the scroll toward the Trinket section
	scroll.scroll_vertical = 0
	await get_tree().process_frame
	var before := scroll.scroll_vertical
	(rail["Trinket"] as Button).pressed.emit()
	await get_tree().create_timer(0.4).timeout
	if scroll.scroll_vertical <= before:
		fails += 1; print("FAIL: rail jump did not scroll (still %d)" % scroll.scroll_vertical)

	# equipping the worn piece again is a no-op (no crash, state unchanged)
	target.pressed.emit()
	await get_tree().process_frame
	if GameState.equipped_id("Hat") != new_id:
		fails += 1; print("FAIL: re-press changed state")
	print("equip flow: prev=%s new=%s" % [prev_worn, new_id])
	print("=== equip test: %s ===" % ("PASS" if fails == 0 else "%d FAILS" % fails))
	get_tree().quit()
