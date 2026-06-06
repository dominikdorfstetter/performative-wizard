class_name CardView
extends RefCounted
## Builds a styled card Button from CardData. Shared by combat (playable hand) and
## the reward screen (pickable cards) so cards look identical everywhere.

const C_GOLD := Color(1.0, 0.82, 0.29)
const C_SWAG := Color(1.0, 0.31, 0.70)
const C_DIM := Color(0.62, 0.60, 0.68)

# Hand-picked icon per card for flavour (falls back to effect-based rules below).
const ICON_BY_ID := {
	&"quick_read": "eye", &"second_wind": "bolt", &"lucky_strike": "dice",
	&"finger_guns": "lips", &"wink": "lips", &"smooth_talk": "lips", &"pickup_line": "lips",
	&"rizz_up": "rizz", &"flex": "fist", &"composure": "shield", &"delulu": "note",
	&"grand_finale": "crown", &"flourish": "wing", &"vogue": "wing", &"strike_a_pose": "star",
	&"macabre_bow": "arrow", &"touch_grass": "drop", &"shroud": "wing", &"hot_streak": "bolt",
	&"soul_siphon": "heart", &"drain": "heart",
	&"slow_burn": "fire", &"hive_mind": "bones", &"grindset": "fist", &"spread_rumors": "flask",
}

const RARITY_COLOR := {
	"Common": Color(0.60, 0.60, 0.66), "Uncommon": Color(0.40, 0.80, 0.50),
	"Rare": Color(1.0, 0.82, 0.29),
}

static func build(card: CardData, enabled: bool, on_press: Callable) -> Button:
	var accent := type_color(card.type)
	var rare := card.rarity == "Rare"
	var bw := 3 if rare else 2
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 200)
	b.disabled = not enabled
	b.add_theme_stylebox_override("normal", _box(Color(0.12, 0.11, 0.16), accent, bw))
	b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.15, 0.24), accent.lightened(0.25), bw))
	b.add_theme_stylebox_override("pressed", _box(Color(0.2, 0.17, 0.27), accent, bw))
	b.add_theme_stylebox_override("disabled", _box(Color(0.10, 0.09, 0.12), Color(0.3, 0.3, 0.34), 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if on_press.is_valid():
		b.pressed.connect(on_press)
	b.mouse_entered.connect(_hover.bind(b, true))
	b.mouse_exited.connect(_hover.bind(b, false))

	var rc := rarity_color(card.rarity)

	# coloured header band with the card's icon on an inset "art" tile
	var header := Panel.new()
	header.position = Vector2(3, 3)
	header.size = Vector2(144, 48)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hs := StyleBoxFlat.new()
	hs.bg_color = accent.darkened(0.52)
	hs.corner_radius_top_left = 9
	hs.corner_radius_top_right = 9
	header.add_theme_stylebox_override("panel", hs)
	b.add_child(header)

	# art tile makes the motif pop off the band
	var tile := Panel.new()
	tile.position = Vector2(50, 5)
	tile.size = Vector2(50, 42)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts := StyleBoxFlat.new()
	ts.bg_color = accent.darkened(0.34)
	ts.set_corner_radius_all(8)
	ts.set_border_width_all(1)
	ts.border_color = accent.lightened(0.1)
	tile.add_theme_stylebox_override("panel", ts)
	b.add_child(tile)

	var ic := SpriteBank.icon_texture(icon_for(card))
	if ic != null:
		var tr := TextureRect.new()
		tr.texture = ic
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(53, 6)
		tr.size = Vector2(44, 40)
		b.add_child(tr)

	# accent rule along the header's bottom edge (rarity-coloured)
	var rule := ColorRect.new()
	rule.color = rc
	rule.position = Vector2(6, 49)
	rule.size = Vector2(138, 2)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(rule)

	var upgraded := GameState.is_upgraded(card.id)
	var eff_cost := GameState.card_cost(card)
	_add_label(b, str(eff_cost), Vector2(7, 7), Vector2(34, 34), 20, Color.BLACK, _circle(C_SWAG if upgraded else C_GOLD))
	# rarity gem (every card), brighter diamond for higher rarities
	_add_label(b, "◆", Vector2(119, 8), Vector2(24, 22), 14, rc)
	if upgraded:
		_add_label(b, "✦+", Vector2(96, 6), Vector2(22, 18), 13, C_SWAG)

	# type tag ABOVE the title so 2-line titles never collide with it
	_add_label(b, Loc.t(card.type).to_upper(), Vector2(6, 52), Vector2(138, 14), 10, C_DIM)
	# shrink the title font for longer names so 2-line titles aren't cramped
	var disp_title := Loc.t(card.title)
	var tlen := disp_title.length()
	var tsize := 16 if tlen <= 11 else (14 if tlen <= 17 else 12)
	_add_label(b, disp_title, Vector2(5, 66), Vector2(140, 48), tsize, accent.lightened(0.45))
	var body := Panel.new()
	body.position = Vector2(8, 116)
	body.size = Vector2(134, 80)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0, 0, 0, 0.16)
	bs.set_corner_radius_all(7)
	body.add_theme_stylebox_override("panel", bs)
	b.add_child(body)
	# description fills the inset box; shrinks for long text; leaves room for the footer
	var has_footer := card.swag_gain > 0
	var dh := 48 if has_footer else 72
	var disp_desc := Loc.t(card.description)
	var dsize := 13 if disp_desc.length() <= 58 else 12
	_add_label(b, disp_desc, Vector2(9, 120), Vector2(132, dh), dsize, Color(0.87, 0.87, 0.92))
	if has_footer:
		_add_label(b, "✦ Aura +%d" % card.swag_gain, Vector2(6, 176), Vector2(138, 16), 13, C_SWAG)
	return b

static func _hover(b: Button, on: bool) -> void:
	if b == null or b.disabled or not is_instance_valid(b):
		return
	b.pivot_offset = b.size * 0.5 if b.size != Vector2.ZERO else Vector2(75, 101)
	b.z_index = 5 if on else 0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.08, 1.08) if on else Vector2.ONE, 0.1)

static func icon_for(card: CardData) -> StringName:
	if card.id in ICON_BY_ID:
		return StringName(ICON_BY_ID[card.id])
	for e in card.effects:
		var op := String(e.get("op", ""))
		if op == "damage_all":
			return &"burst"
		if op == "summon":
			return &"bones"
		if op == "sacrifice_strike" or op.begins_with("finisher"):
			return &"skull"
		if op == "heal":
			return &"heart"
		if op == "cleanse":
			return &"drop"
		if op == "draw":
			return &"eye"
		if op == "damage_x_burn":
			return &"fire"
		if op == "apply_status" and StringName(e.get("status", &"")) == &"burn":
			return &"fire"
		if op == "self_status" and StringName(e.get("status", &"")) == &"strength":
			return &"rizz"
	if card.type == "Attack":
		return &"sword"
	if card.swag_gain > 0:
		return &"star"
	if card.type == "Skill":
		return &"shield"
	return &"swirl"

static func rarity_color(r: String) -> Color:
	return RARITY_COLOR.get(r, Color(0.6, 0.6, 0.66))

static func type_color(t: String) -> Color:
	match t:
		"Attack":
			return Color(0.86, 0.30, 0.27)
		"Skill":
			return Color(0.30, 0.58, 0.82)
		"Power":
			return Color(0.64, 0.42, 0.86)
	return Color(0.5, 0.5, 0.55)

static func _add_label(parent: Control, text: String, pos: Vector2, sz: Vector2, font_size: int, color: Color, box: StyleBox = null) -> void:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if box != null:
		l.add_theme_stylebox_override("normal", box)
	parent.add_child(l)

static func _box(bg: Color, border: Color, bw := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(10)
	return s

static func _circle(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(17)
	return s
