extends Control
## The wardrobe / dressing room (M3). Equip one owned piece per slot — filtered to your
## class rack — then enter the gauntlet. Equipped pieces inject cards, add Swag income,
## and grant passives (baked in by GameState.finalize_loadout).
##
## Layout: THE RACK (left) is the only scrolling region — every owned piece grouped into
## per-slot sections, so future Boutique stock makes it taller, never wider. THE FIT
## (right) is a pinned rail: one chip per slot showing what's worn (click = jump to that
## rack section) above the loadout summary. Equipping restyles chips in place — the rack
## is never rebuilt, so the scroll position survives every click. (The old layout put all
## options of a slot in ONE fixed row; at high unlock counts it overflowed both screen
## edges, clipping the summary and the enter button.)

const TipIcon = preload("res://scripts/ui/tip_icon.gd")

const ELEM_COLOR := {
	"Fire": Color(0.86, 0.30, 0.27),
	"Necro": Color(0.55, 0.78, 0.45),
	"Rizz": Color(0.96, 0.50, 0.72),
	"Neutral": Color(0.6, 0.6, 0.66),
}

# Region geometry on the 1152x648 canvas (absolute, code-built — house style).
const RACK_POS := Vector2(36, 80)
const RACK_SIZE := Vector2(740, 500)
const CHIP_SIZE := Vector2(236, 64)
const RAIL_POS := Vector2(796, 80)
const RAIL_SIZE := Vector2(320, 456)

var _wizard: WizardData
var _scroll: ScrollContainer
var _rack: VBoxContainer
var _headers := {}      # slot -> section header row (rail jump target)
var _grids := {}        # slot -> GridContainer of piece chips
var _rail_chips := {}   # slot -> worn-piece Button on the fit rail
var _stats: Label
var _perks: Label
var _hint: Label

func _ready() -> void:
	NodeUI.gradient_bg(self)
	_wizard = Database.get_wizard(GameState.wizard_id)
	_build_header()
	_build_rack()
	_build_rail()
	_build_buttons()
	for slot in GameState.SLOTS:
		_refresh_rail(slot)
	_update_summary()
	await get_tree().process_frame
	await get_tree().process_frame
	_hint.visible = _rack.size.y > RACK_SIZE.y

func _build_header() -> void:
	var title := Label.new()
	title.text = Loc.t("THE DRESSING ROOM")
	title.add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	title.add_theme_font_size_override("font_size", NodeUI.FS_TITLE)
	title.add_theme_color_override("font_color", NodeUI.PINK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 6)
	title.size = Vector2(1152, 44)
	add_child(title)
	var who := Label.new()
	who.text = Loc.t("%s, the %s    —    pick your drip") % [_wizard.pname, Loc.t(_wizard.title)]
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.position = Vector2(0, 52)
	who.size = Vector2(1152, 24)
	who.add_theme_font_size_override("font_size", 18)
	who.add_theme_color_override("font_color", _wizard.accent.lightened(0.3))
	add_child(who)
	var tex := SpriteBank.wizard_texture(_wizard.id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(28, 8)
		tr.size = Vector2(54, 54)
		add_child(tr)

# --- the rack (left, scrolls) ---------------------------------------------

func _build_rack() -> void:
	_scroll = ScrollContainer.new()
	_scroll.position = RACK_POS
	_scroll.custom_minimum_size = RACK_SIZE
	_scroll.size = RACK_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_rack = VBoxContainer.new()
	_rack.add_theme_constant_override("separation", 8)
	_rack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_rack)
	for slot in GameState.SLOTS:
		_rack.add_child(_make_section_header(slot))
		var options := GameState.owned_for(slot, _wizard.element)
		if options.is_empty():
			var none := Label.new()
			none.text = Loc.t("(nothing owned — the Boutique sells %s drip)") % Loc.t(slot)
			none.add_theme_font_size_override("font_size", NodeUI.FS_CAPTION)
			none.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			_rack.add_child(none)
			continue
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_grids[slot] = grid
		_rack.add_child(grid)
		var pieces: Array[OutfitData] = []
		for id in options:
			var p := Database.get_outfit(id)
			if p != null:
				pieces.append(p)
		pieces.sort_custom(_rack_order)
		for p in pieces:
			grid.add_child(_make_chip(slot, p))
	_hint = Label.new()
	_hint.text = Loc.t("scroll for more drip")
	_hint.position = Vector2(RACK_POS.x, 584)
	_hint.size = Vector2(RACK_SIZE.x, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", NodeUI.FS_CAPTION)
	_hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	_hint.visible = false
	add_child(_hint)

## Stat-shoppers first: highest drip, then most injected cards, then A→Z. The order is
## fixed for the lifetime of the screen, so chips never move while equipping.
static func _rack_order(a: OutfitData, b: OutfitData) -> bool:
	if a.drip != b.drip:
		return a.drip > b.drip
	if a.injected_cards.size() != b.injected_cards.size():
		return a.injected_cards.size() > b.injected_cards.size()
	return a.title < b.title

func _make_section_header(slot: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = Loc.t(slot)
	label.add_theme_font_size_override("font_size", NodeUI.FS_BODY)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.76))
	row.add_child(label)
	var rule := ColorRect.new()
	rule.color = Color(_wizard.accent, 0.3)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule)
	var count := Label.new()
	count.text = Loc.t("%d owned") % GameState.owned_for(slot, _wizard.element).size()
	count.add_theme_font_size_override("font_size", NodeUI.FS_CAPTION)
	count.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	row.add_child(count)
	_headers[slot] = row
	return row

func _make_chip(slot: String, piece: OutfitData) -> Button:
	var ec: Color = ELEM_COLOR.get(piece.element, Color.GRAY)
	var b := Button.new()
	b.custom_minimum_size = CHIP_SIZE
	b.set_meta("piece_id", piece.id)
	b.set_meta("ec", ec)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(_equip_pressed.bind(slot, piece.id))
	var itex := SpriteBank.item_texture(piece.id)
	if itex != null:
		var tr := TextureRect.new()
		tr.texture = itex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(8, 8)
		tr.size = Vector2(48, 48)
		b.add_child(tr)
	_lbl(b, Loc.t(piece.title), Vector2(62, 5), Vector2(126, 36), 14, ec.lightened(0.35))
	var worn := Label.new()
	worn.name = "Worn"
	worn.text = Loc.t("WORN")
	worn.position = Vector2(188, 5)
	worn.size = Vector2(42, 14)
	worn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	worn.add_theme_font_size_override("font_size", 11)
	worn.add_theme_color_override("font_color", NodeUI.GOLD)
	worn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(worn)
	var sub := "+%d Aura" % piece.drip if piece.drip > 0 else ""
	if not piece.injected_cards.is_empty():
		sub += ("   " if sub != "" else "") + Loc.t("+%d card") % piece.injected_cards.size()
	if piece.passive_text != "":
		sub += ("   " if sub != "" else "") + Loc.t("+passive")
	_lbl(b, sub, Vector2(62, 42), Vector2(168, 16), 12, Color(0.8, 0.8, 0.85))
	# the full effect lives in a hover tooltip — the chip only carries the shorthand
	var tip := TipIcon.new()
	tip.set_anchors_preset(Control.PRESET_FULL_RECT)
	tip.mouse_filter = Control.MOUSE_FILTER_PASS   # tooltip shows, click still equips
	tip.set_tip("%s  (%s)" % [Loc.t(piece.title), Loc.t(piece.slot)], _tip_body(piece))
	b.add_child(tip)
	_style_chip(b, ec, GameState.equipped_id(slot) == piece.id)
	return b

func _style_chip(b: Button, ec: Color, worn: bool) -> void:
	var border := NodeUI.GOLD if worn else ec.darkened(0.1)
	var bw := 3 if worn else 1
	b.add_theme_stylebox_override("normal", _chip_panel(Color(0.18, 0.16, 0.22) if worn else Color(0.12, 0.11, 0.15), border, bw))
	b.add_theme_stylebox_override("hover", _chip_panel(Color(0.22, 0.19, 0.27), border.lightened(0.2), bw))
	b.add_theme_stylebox_override("pressed", _chip_panel(Color(0.2, 0.18, 0.25), border, 3))
	(b.get_node("Worn") as Label).visible = worn

func _equip_pressed(slot: String, id: StringName) -> void:
	if GameState.equipped_id(slot) == id:
		return
	Audio.play("click", -7.0)
	GameState.equip(slot, id)
	GameState.save_meta()
	_refresh_slot(slot)
	_refresh_rail(slot)
	_update_summary()

func _refresh_slot(slot: String) -> void:
	if not _grids.has(slot):
		return
	for chip in _grids[slot].get_children():
		_style_chip(chip, chip.get_meta("ec"), GameState.equipped_id(slot) == chip.get_meta("piece_id"))

# --- the fit rail (right, pinned) ------------------------------------------

func _build_rail() -> void:
	var panel := Panel.new()
	panel.position = RAIL_POS
	panel.size = RAIL_SIZE
	panel.add_theme_stylebox_override("panel", _panel(Color(0.13, 0.11, 0.17), Color(0.28, 0.24, 0.36)))
	add_child(panel)
	var title := Label.new()
	title.text = Loc.t("THE FIT")
	title.position = Vector2(12, 10)
	title.size = Vector2(296, 26)
	title.add_theme_font_size_override("font_size", NodeUI.FS_HEADING)
	title.add_theme_color_override("font_color", NodeUI.GOLD)
	panel.add_child(title)
	var y := 42.0
	for slot in GameState.SLOTS:
		var chip := _make_rail_chip(slot)
		chip.position = Vector2(12, y)
		panel.add_child(chip)
		_rail_chips[slot] = chip
		y += 50.0
	var rule := ColorRect.new()
	rule.color = Color(0.28, 0.24, 0.36)
	rule.position = Vector2(12, y + 2.0)
	rule.size = Vector2(296, 2)
	panel.add_child(rule)
	_stats = Label.new()
	_stats.position = Vector2(12, y + 10.0)
	_stats.size = Vector2(296, 44)
	_stats.add_theme_font_size_override("font_size", NodeUI.FS_BODY)
	_stats.add_theme_color_override("font_color", Color(0.86, 0.86, 0.9))
	panel.add_child(_stats)
	_perks = Label.new()
	_perks.position = Vector2(12, y + 60.0)
	_perks.size = Vector2(296, RAIL_SIZE.y - (y + 60.0) - 12.0)
	# One ellipsized line per perk (header + 5 bullets = 6 lines, guaranteed to fit the
	# 92px rect at line_spacing 0) — wrapped text silently dropped perks past line 5.
	# The full effect text lives in the rail-chip and rack-chip tooltips.
	_perks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_perks.add_theme_constant_override("line_spacing", 0)
	_perks.add_theme_font_size_override("font_size", NodeUI.FS_CAPTION)
	_perks.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	panel.add_child(_perks)

func _make_rail_chip(slot: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(296, 44)
	b.size = Vector2(296, 44)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(_jump_to.bind(slot))
	b.pressed.connect(Audio.play.bind("click", -7.0))
	var cap := Label.new()
	cap.text = Loc.t(slot).to_upper()
	cap.position = Vector2(8, 3)
	cap.size = Vector2(160, 12)
	cap.add_theme_font_size_override("font_size", 11)
	cap.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cap)
	var piece_name := Label.new()
	piece_name.name = "PieceName"
	piece_name.position = Vector2(8, 18)
	piece_name.size = Vector2(236, 22)
	piece_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	piece_name.add_theme_font_size_override("font_size", 14)
	piece_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(piece_name)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(250, 2)
	icon.size = Vector2(40, 40)
	b.add_child(icon)
	var tip := TipIcon.new()
	tip.name = "Tip"
	tip.set_anchors_preset(Control.PRESET_FULL_RECT)
	tip.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_child(tip)
	return b

func _refresh_rail(slot: String) -> void:
	var chip: Button = _rail_chips[slot]
	var id := GameState.equipped_id(slot)
	var piece := Database.get_outfit(id) if id != &"" else null
	var piece_name := chip.get_node("PieceName") as Label
	var icon := chip.get_node("Icon") as TextureRect
	var tip = chip.get_node("Tip")
	if piece != null:
		var ec: Color = ELEM_COLOR.get(piece.element, Color.GRAY)
		piece_name.text = Loc.t(piece.title)
		piece_name.add_theme_color_override("font_color", ec.lightened(0.35))
		icon.texture = SpriteBank.item_texture(piece.id)
		icon.visible = icon.texture != null
		_style_rail_chip(chip, ec.darkened(0.1))
		tip.set_tip("%s  (%s)" % [Loc.t(piece.title), Loc.t(slot)],
			_tip_body(piece) + "\n" + Loc.t("click to jump to the %s rack") % Loc.t(slot))
	else:
		piece_name.text = Loc.t("(nothing)")
		piece_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		icon.visible = false
		_style_rail_chip(chip, Color(0.28, 0.24, 0.36))
		tip.set_tip(Loc.t(slot), Loc.t("click to jump to the %s rack") % Loc.t(slot))

func _style_rail_chip(b: Button, border: Color) -> void:
	b.add_theme_stylebox_override("normal", _chip_panel(Color(0.12, 0.11, 0.15), border, 1))
	b.add_theme_stylebox_override("hover", _chip_panel(Color(0.18, 0.16, 0.22), border.lightened(0.25), 1))
	b.add_theme_stylebox_override("pressed", _chip_panel(Color(0.2, 0.18, 0.25), border, 1))

## Glide the rack to a slot's section. Positions are read at click time, when the
## layout is already valid — no cached offsets, no awaited frames.
func _jump_to(slot: String) -> void:
	if not _headers.has(slot):
		return
	create_tween().tween_property(_scroll, "scroll_vertical", int((_headers[slot] as Control).position.y), 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _update_summary() -> void:
	var injected := 0
	var passives: Array[String] = []
	for p in GameState.equipped_pieces():
		injected += p.injected_cards.size()
		if p.passive_text != "":
			passives.append("• " + Loc.t(p.passive_text))
	_stats.text = Loc.t("Aura income: +%d / turn") % GameState.preview_drip() + "\n" \
		+ Loc.t("Cards added to deck: %d") % injected
	var lines: Array[String] = [Loc.t("drip perks:")]
	if passives.is_empty():
		lines.append(Loc.t("  (none)"))
	else:
		lines.append_array(passives)
	_perks.text = "\n".join(lines)

# --- enter / back -----------------------------------------------------------

func _build_buttons() -> void:
	var enter := Button.new()
	enter.text = Loc.t("let's get it")
	enter.position = Vector2(RAIL_POS.x, 548)
	enter.size = Vector2(RAIL_SIZE.x, 52)
	enter.add_theme_font_size_override("font_size", NodeUI.FS_HEADING)
	enter.pressed.connect(_enter)
	enter.pressed.connect(Audio.play.bind("click", -7.0))
	enter.add_theme_stylebox_override("normal", _panel(Color(0.16, 0.36, 0.22), Color(0.36, 0.70, 0.45)))
	enter.add_theme_stylebox_override("hover", _panel(Color(0.20, 0.46, 0.28), Color(0.45, 0.85, 0.55)))
	enter.add_theme_stylebox_override("pressed", _panel(Color(0.13, 0.30, 0.18), Color(0.36, 0.70, 0.45)))
	enter.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_child(enter)
	var back := NodeUI.small_button("Back", func(): Fader.change_scene("res://scenes/hub/class_select.tscn"), Color(0.4, 0.85, 0.55))
	back.position = Vector2(36, 600)
	add_child(back)

func _enter() -> void:
	GameState.finalize_loadout()
	Fader.change_scene("res://scenes/map/map.tscn")

# --- helpers ---

func _tip_body(piece: OutfitData) -> String:
	var body := ""
	if piece.drip > 0:
		body += Loc.t("Drip +%d Aura/turn.") % piece.drip
	if piece.passive_text != "":
		body += ("\n" if body != "" else "") + Loc.t(piece.passive_text)
	if not piece.injected_cards.is_empty():
		body += ("\n" if body != "" else "") + Loc.t("Adds %d cards to your deck.") % piece.injected_cards.size()
	if body == "":
		body = Loc.t("No passive.")
	return body

func _lbl(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)

func _panel(bg: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

## Compact stylebox for the 64px-high rack chips and 44px rail chips, where the
## standard _panel margins would eat the room the labels need.
func _chip_panel(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(6)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s
