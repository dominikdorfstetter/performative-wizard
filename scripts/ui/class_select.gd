extends Control
## Hub stand-in: pick your wizard (base robe set) to begin a run. M3 grows this into
## the dressing room with the full wardrobe.

@onready var _message: Label = $Message
@onready var _choices: HBoxContainer = $Choices

func _ready() -> void:
	$Background.visible = false
	NodeUI.gradient_bg(self)
	$Title.add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	$Subtitle.text = "Choose your base robe set — all power comes from the clothes.    ✦ Clout: %d" % GameState.clout
	if GameState.message != "":
		_message.text = GameState.message
		_message.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
		GameState.message = ""
	for id in [&"fire", &"necro"]:
		var w := Database.get_wizard(id)
		if w != null:
			_choices.add_child(_make_wizard_button(w))
	var boutique := Button.new()
	boutique.text = "✦ Boutique  (spend Clout)"
	boutique.add_theme_font_size_override("font_size", 18)
	boutique.position = Vector2(456, 548)
	boutique.size = Vector2(240, 42)
	boutique.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub/boutique.tscn"))
	add_child(boutique)

func _make_wizard_button(w: WizardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(330, 320)
	b.add_theme_stylebox_override("normal", _box(Color(0.14, 0.12, 0.18), w.accent))
	b.add_theme_stylebox_override("hover", _box(Color(0.20, 0.17, 0.26), w.accent.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.22, 0.19, 0.28), w.accent))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): _choose(w.id))

	var tex := SpriteBank.wizard_texture(w.id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(115, 10)
		tr.size = Vector2(100, 100)
		b.add_child(tr)
	_label(b, w.pname, Vector2(15, 114), Vector2(300, 32), 25, w.accent.lightened(0.35))
	_label(b, "the " + w.title, Vector2(15, 148), Vector2(300, 24), 17, Color(0.7, 0.7, 0.78))
	_label(b, "❤ %d HP" % w.max_hp, Vector2(15, 176), Vector2(300, 24), 16, Color(0.8, 0.8, 0.85))
	_label(b, w.blurb, Vector2(24, 204), Vector2(282, 104), 16, Color(0.78, 0.78, 0.82))
	return b

func _choose(id: StringName) -> void:
	GameState.start_run(id)
	get_tree().change_scene_to_file("res://scenes/hub/dressing_room.tscn")

func _label(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, color: Color) -> void:
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

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(3)
	s.border_color = border
	s.set_corner_radius_all(12)
	return s
