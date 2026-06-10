extends Control
## The Boutique: spend Clout (meta currency) to permanently unlock premium outfit
## pieces. Stock is grouped by WHO can wear it — each section wears its wizard's
## portrait and accent colour, so you always know whose drip you're funding.

const ELEMENT_WIZ := {"Fire": &"fire", "Necro": &"necro", "Rizz": &"rizz"}

func _ready() -> void:
	NodeUI.background(self)
	_build()

func _build() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()
	NodeUI.title(self, "The Boutique", NodeUI.PINK, SpriteBank.icon_texture(&"crown"))
	NodeUI.sub(self, Loc.t("permanent drip — sorted by who can serve it"))
	_wallet_chip()
	_twinkles()

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(78, 150)
	scroll.custom_minimum_size = Vector2(996, 424)
	scroll.size = Vector2(996, 424)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vb)

	# group the stock by element; everyone-wear first, then per-wizard racks
	var groups := {}
	for entry in GameState.BOUTIQUE:
		var p := Database.get_outfit(entry.id)
		var el: String = p.element if p != null else "Neutral"
		if not groups.has(el):
			groups[el] = []
		groups[el].append(entry)
	for el in ["Neutral", "Fire", "Necro", "Rizz"]:
		if not groups.has(el):
			continue
		var entries: Array = groups[el]
		entries.sort_custom(func(a, b): return a.cost < b.cost)
		vb.add_child(_section_header(el))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 16)
		vb.add_child(grid)
		for entry in entries:
			grid.add_child(_stall(entry, _element_accent(el)))

	var more := Label.new()
	more.text = Loc.t("scroll for more")
	more.position = Vector2(78, 576)
	more.size = Vector2(996, 18)
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	more.add_theme_font_size_override("font_size", 13)
	more.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	add_child(more)

	var back := NodeUI.small_button("Back", _to_menu, Color(0.4, 0.85, 0.55))
	back.position = Vector2(486, 600)
	add_child(back)

func _element_accent(el: String) -> Color:
	if ELEMENT_WIZ.has(el):
		var w := Database.get_wizard(ELEMENT_WIZ[el])
		if w != null:
			return w.accent
	return NodeUI.GOLD

## Top-right Clout wallet — the budget stays on screen while you scroll the racks.
func _wallet_chip() -> void:
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.11, 0.17)
	sb.set_border_width_all(2)
	sb.border_color = NodeUI.GOLD.darkened(0.25)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	box.add_theme_stylebox_override("panel", sb)
	box.position = Vector2(952, 24)
	add_child(box)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 7)
	box.add_child(h)
	var coin := TextureRect.new()
	coin.texture = SpriteBank.icon_texture(&"coin")
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coin.custom_minimum_size = Vector2(20, 20)
	h.add_child(coin)
	var amount := Label.new()
	amount.text = Loc.t("%d Clout") % GameState.clout
	amount.add_theme_font_size_override("font_size", 16)
	amount.add_theme_color_override("font_color", NodeUI.GOLD)
	h.add_child(amount)

## A little ambient sparkle so the racks feel like a storefront, not a spreadsheet.
func _twinkles() -> void:
	for spec in [[150, 70, 14, 0.5], [248, 110, 9, 1.3], [880, 64, 12, 0.2], [1006, 122, 8, 1.7], [60, 480, 10, 0.9], [1090, 420, 11, 2.2]]:
		var t := TextureRect.new()
		t.texture = SpriteBank.icon_texture(&"star")
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.position = Vector2(spec[0], spec[1])
		t.size = Vector2(spec[2], spec[2])
		t.modulate = Color(1, 0.85, 0.5, 0.16)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		var tw := t.create_tween().set_loops()
		tw.tween_interval(spec[3])
		tw.tween_property(t, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
		tw.tween_property(t, "modulate:a", 0.16, 1.1).set_trans(Tween.TRANS_SINE)

## "for everyone" / "for <wizard>" rack header: portrait, name, coloured rule.
func _section_header(el: String) -> Control:
	var accent := _element_accent(el)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	if ELEMENT_WIZ.has(el):
		var w := Database.get_wizard(ELEMENT_WIZ[el])
		var face := TextureRect.new()
		face.texture = SpriteBank.wizard_texture(ELEMENT_WIZ[el])
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.custom_minimum_size = Vector2(34, 34)
		row.add_child(face)
		row.add_child(_header_label(Loc.t("for %s") % (Loc.t(w.pname) if w != null else el), accent))
	else:
		var star := TextureRect.new()
		star.texture = SpriteBank.icon_texture(&"star")
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		star.custom_minimum_size = Vector2(26, 34)
		star.modulate = NodeUI.GOLD
		row.add_child(star)
		row.add_child(_header_label(Loc.t("for everyone"), accent))
	var rule := ColorRect.new()
	rule.color = Color(accent, 0.35)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule)
	return row

func _header_label(text: String, accent: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", NodeUI.FS_HEADING)
	l.add_theme_color_override("font_color", accent.lightened(0.25))
	return l

func _stall(entry: Dictionary, accent: Color) -> Control:
	var p := Database.get_outfit(entry.id)
	var owned: bool = entry.id in GameState.unlocked_outfits
	var afford: bool = not owned and GameState.clout >= entry.cost
	var desc := "%s · +%d Aura/turn\n%s" % [Loc.t(p.slot), p.drip, Loc.t(p.passive_text)]
	var ab := NodeUI.choice(p.title, desc, accent if not owned else Color(0.45, 0.62, 0.5), _buy.bind(entry), afford)
	# the piece itself, big, top-right
	var itex := SpriteBank.item_texture(entry.id)
	if itex != null:
		var tr := TextureRect.new()
		tr.texture = itex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(244, 10)
		tr.size = Vector2(46, 46)
		tr.modulate = Color.WHITE if (afford or owned) else Color(0.55, 0.55, 0.6)
		ab.add_child(tr)
	# wizard chip top-left on element pieces: whose rack this really is
	var pel: String = p.element if p != null else "Neutral"
	if ELEMENT_WIZ.has(pel):
		var face := TextureRect.new()
		face.texture = SpriteBank.wizard_texture(ELEMENT_WIZ[pel])
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.position = Vector2(10, 10)
		face.size = Vector2(30, 30)
		ab.add_child(face)
	# price chip: gold when you can swing it, muted when not, green when collected
	var price := Label.new()
	price.text = Loc.t("OWNED") if owned else Loc.t("%d Clout") % entry.cost
	price.position = Vector2(0, 148)
	price.size = Vector2(300, 20)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 15)
	price.add_theme_color_override("font_color",
		Color(0.55, 0.85, 0.6) if owned else (NodeUI.GOLD if afford else Color(0.6, 0.5, 0.45)))
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ab.add_child(price)
	return ab

func _buy(entry: Dictionary) -> void:
	if GameState.buy_boutique(entry.id, entry.cost):
		Audio.play("buff", -3.0)   # a permanent unlock deserves a fanfare
		_build()

func _to_menu() -> void:
	Fader.change_scene("res://scenes/hub/class_select.tscn")
