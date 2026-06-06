extends Control
## The Boutique: spend Clout (meta currency) to permanently unlock premium outfit pieces.

func _ready() -> void:
	NodeUI.background(self)
	_build()

func _build() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()
	NodeUI.title(self, "✦ The Boutique", NodeUI.PINK)
	NodeUI.sub(self, "Spend Clout on permanent drip. You have ✦ %d Clout." % GameState.clout)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(252, 166)
	scroll.custom_minimum_size = Vector2(652, 400)
	scroll.size = Vector2(652, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	for entry in GameState.BOUTIQUE:
		grid.add_child(_stall(entry))

	var back := NodeUI.small_button("← Back", _to_menu, Color(0.4, 0.85, 0.55))
	back.position = Vector2(486, 596)
	add_child(back)

func _stall(entry: Dictionary) -> Control:
	var p := Database.get_outfit(entry.id)
	var owned: bool = entry.id in GameState.unlocked_outfits
	var afford: bool = not owned and GameState.clout >= entry.cost
	var desc := "%s\n✦ +%d/turn\n%s\n\n%s" % [
		p.slot, p.drip, p.passive_text,
		("OWNED" if owned else "✦ %d Clout" % entry.cost)]
	var accent := Color(0.55, 0.78, 0.45) if owned else (NodeUI.GOLD if afford else Color(0.5, 0.5, 0.56))
	var ab := NodeUI.choice(p.title, desc, accent, _buy.bind(entry), afford)
	var itex := SpriteBank.item_texture(entry.id)
	if itex != null:
		var tr := TextureRect.new()
		tr.texture = itex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(248, 12)
		tr.size = Vector2(42, 42)
		ab.add_child(tr)
	return ab

func _buy(entry: Dictionary) -> void:
	if GameState.buy_boutique(entry.id, entry.cost):
		_build()

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
