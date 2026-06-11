extends Node
## Dev tool: render the dressing room at FULL unlock — every outfit owned — for each
## wizard. This is the worst-case rack density the wardrobe UI must survive, so run it
## after touching dressing_room.gd or adding boutique stock.
## Usage:  PW_NO_SAVE=1 godot scenes/tools/dress_stress.tscn   (window visible)

func _ready() -> void:
	for id in Database.outfits:
		if not GameState.unlocked_outfits.has(id):
			GameState.unlocked_outfits.append(id)
	for wid: StringName in [&"fire", &"necro", &"rizz"]:
		GameState.start_run(wid)
		_equip_worst_case()
		var s: Node = load("res://scenes/hub/dressing_room.tscn").instantiate()
		add_child(s)
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/pw_dress_full_%s.png" % wid)
		s.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	print("rendered full-unlock dressing rooms")
	get_tree().quit()

## Wear the longest-passive piece in every slot, so the perks summary is rendered
## at its maximum line count (the case that used to clip silently).
func _equip_worst_case() -> void:
	var w := Database.get_wizard(GameState.wizard_id)
	for slot in GameState.SLOTS:
		var best: StringName = &""
		var best_len := -1
		for id in GameState.owned_for(slot, w.element):
			var p := Database.get_outfit(id)
			if p != null and p.passive_text.length() > best_len:
				best_len = p.passive_text.length()
				best = id
		if best != &"":
			GameState.equip(slot, best)
