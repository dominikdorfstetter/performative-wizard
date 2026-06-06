extends Control
## Hub stand-in: pick your wizard (base robe set) to begin a run. M3 grows this into
## the dressing room with the full wardrobe.

@onready var _message: Label = %Message
@onready var _choices: HBoxContainer = %Choices

func _ready() -> void:
	NodeUI.gradient_bg(self)
	(%Title as Label).add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	(%Subtitle as Label).text = "pick your fighter — all your power is in the fit.    ✦ Clout: %d" % GameState.clout
	if GameState.message != "":
		_message.text = GameState.message
		_message.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
		GameState.message = ""
	for id in [&"fire", &"necro", &"rizz"]:
		var w := Database.get_wizard(id)
		if w != null:
			_choices.add_child(_make_wizard_button(w))
	(%Boutique as Button).pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub/boutique.tscn"))
	var menu := Button.new()
	menu.text = "← Menu"
	menu.add_theme_font_size_override("font_size", 16)
	menu.position = Vector2(24, 24)
	menu.size = Vector2(120, 38)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub/main_menu.tscn"))
	add_child(menu)

func _make_wizard_button(w: WizardData) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 320)
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
		tr.position = Vector2(100, 10)
		tr.size = Vector2(100, 100)
		b.add_child(tr)
	_label(b, w.pname, Vector2(12, 114), Vector2(276, 32), 24, w.accent.lightened(0.35))
	_label(b, "the " + w.title, Vector2(12, 148), Vector2(276, 24), 17, Color(0.7, 0.7, 0.78))
	_label(b, "❤ %d HP" % w.max_hp, Vector2(12, 176), Vector2(276, 24), 16, Color(0.8, 0.8, 0.85))
	_label(b, w.blurb, Vector2(18, 204), Vector2(264, 104), 16, Color(0.78, 0.78, 0.82))
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
