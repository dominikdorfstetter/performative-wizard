extends Node
## Dev tool: render a row of cards (incl. the longest titles) to check layout.

func _ready() -> void:
	var ids := [&"grand_finale", &"mass_grave", &"soul_siphon", &"macabre_bow", &"flame_lash", &"hex"]
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var hb := HBoxContainer.new()
	hb.position = Vector2(40, 210)
	hb.add_theme_constant_override("separation", 16)
	root.add_child(hb)
	add_child(root)
	for id in ids:
		hb.add_child(CardView.build(Database.get_card(id), true, Callable()))
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/pw_cards.png")
	print("saved /tmp/pw_cards.png")
	get_tree().quit()
