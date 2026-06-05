class_name NodeUI
extends RefCounted
## Shared UI builders for the map node screens (rest / shop / event / chest), so they
## share a consistent look.

const BG := Color(0.08, 0.06, 0.11)
const PINK := Color(1.0, 0.31, 0.70)
const GOLD := Color(1.0, 0.82, 0.29)

static func background(parent: Control) -> void:
	var c := ColorRect.new()
	c.color = BG
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)

static func title(parent: Control, text: String, color: Color = PINK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 48)
	l.size = Vector2(1152, 50)
	parent.add_child(l)
	return l

static func sub(parent: Control, text: String, y: float = 108.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(1152, 28)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(l)
	return l

## A large choice card-button with a title and description.
static func choice(text: String, desc: String, accent: Color, cb: Callable, enabled := true) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 178)
	b.disabled = not enabled
	b.add_theme_stylebox_override("normal", box(Color(0.14, 0.12, 0.18), accent))
	b.add_theme_stylebox_override("hover", box(Color(0.20, 0.17, 0.26), accent.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", box(Color(0.22, 0.19, 0.28), accent))
	b.add_theme_stylebox_override("disabled", box(Color(0.11, 0.10, 0.13), Color(0.3, 0.3, 0.34)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if enabled and cb.is_valid():
		b.pressed.connect(cb)
	_label(b, text, Vector2(14, 14), Vector2(272, 30), 22, accent.lightened(0.35))
	_label(b, desc, Vector2(16, 52), Vector2(268, 116), 16, Color(0.82, 0.82, 0.88))
	return b

static func small_button(text: String, cb: Callable, accent: Color = Color(0.4, 0.6, 0.8)) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(180, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", box(Color(0.15, 0.14, 0.2), accent))
	b.add_theme_stylebox_override("hover", box(Color(0.2, 0.18, 0.27), accent.lightened(0.25)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.text = text
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static func hbox(parent: Control, y: float, sep := 30) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.position = Vector2(126, y)
	h.size = Vector2(900, 160)
	h.add_theme_constant_override("separation", sep)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(h)
	return h

static func box(bg: Color, border: Color, bw := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(10)
	return s

static func _label(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
