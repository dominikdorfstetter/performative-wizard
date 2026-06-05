class_name CardView
extends RefCounted
## Builds a styled card Button from CardData. Shared by combat (playable hand) and
## the reward screen (pickable cards) so cards look identical everywhere.

const C_GOLD := Color(1.0, 0.82, 0.29)
const C_SWAG := Color(1.0, 0.31, 0.70)
const C_DIM := Color(0.62, 0.60, 0.68)

static func build(card: CardData, enabled: bool, on_press: Callable) -> Button:
	var accent := type_color(card.type)
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 192)
	b.disabled = not enabled
	b.add_theme_stylebox_override("normal", _box(Color(0.14, 0.12, 0.18), accent))
	b.add_theme_stylebox_override("hover", _box(Color(0.20, 0.17, 0.26), accent.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.22, 0.19, 0.28), accent))
	b.add_theme_stylebox_override("disabled", _box(Color(0.10, 0.09, 0.12), Color(0.3, 0.3, 0.34)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if on_press.is_valid():
		b.pressed.connect(on_press)

	_add_label(b, str(card.cost), Vector2(8, 8), Vector2(34, 34), 20, Color.BLACK, _circle(C_GOLD.darkened(0.1)))
	_add_label(b, card.title, Vector2(6, 46), Vector2(138, 44), 17, accent.lightened(0.35))
	_add_label(b, card.type.to_upper(), Vector2(6, 92), Vector2(138, 16), 11, C_DIM)
	_add_label(b, card.description, Vector2(8, 112), Vector2(134, 56), 13, Color(0.86, 0.86, 0.9))
	if card.swag_gain > 0:
		_add_label(b, "✦ Pose +%d" % card.swag_gain, Vector2(6, 170), Vector2(138, 18), 13, C_SWAG)
	return b

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

static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(10)
	return s

static func _circle(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(17)
	return s
