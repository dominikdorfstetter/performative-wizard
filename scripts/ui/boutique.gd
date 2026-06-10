extends Control
## The Boutique: spend Clout (meta currency) to permanently unlock premium outfit pieces.

func _ready() -> void:
	NodeUI.background(self)
	_build()

func _build() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()
	NodeUI.title(self, "The Boutique", NodeUI.PINK, SpriteBank.icon_texture(&"crown"))
	NodeUI.sub(self, Loc.t("Spend Clout on permanent drip. You have %d Clout.") % GameState.clout)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(78, 160)
	scroll.custom_minimum_size = Vector2(996, 412)
	scroll.size = Vector2(996, 412)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	for entry in GameState.BOUTIQUE:
		grid.add_child(_stall(entry))

	if GameState.BOUTIQUE.size() > 6:
		var more := Label.new()
		more.text = Loc.t("scroll for more")
		more.position = Vector2(78, 574)
		more.size = Vector2(996, 18)
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more.add_theme_font_size_override("font_size", 13)
		more.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
		add_child(more)

	var back := NodeUI.small_button("Back", _to_menu, Color(0.4, 0.85, 0.55))
	back.position = Vector2(486, 596)
	add_child(back)

func _stall(entry: Dictionary) -> Control:
	var p := Database.get_outfit(entry.id)
	var owned: bool = entry.id in GameState.unlocked_outfits
	var afford: bool = not owned and GameState.clout >= entry.cost
	var desc := "%s\n+%d Aura/turn\n%s\n\n%s" % [
		Loc.t(p.slot), p.drip, Loc.t(p.passive_text),
		(Loc.t("OWNED") if owned else "%d Clout" % entry.cost)]
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
