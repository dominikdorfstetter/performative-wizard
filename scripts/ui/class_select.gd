extends Control
## Hub stand-in: pick your wizard (base robe set) to begin a run. M3 grows this into
## the dressing room with the full wardrobe.

@onready var _message: Label = %Message
@onready var _choices: HBoxContainer = %Choices

func _ready() -> void:
	NodeUI.gradient_bg(self)
	Audio.play_music("menu")
	(%Title as Label).add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	(%Title as Label).add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	(%Subtitle as Label).text = Loc.t("pick your fighter — all your power is in the fit.    Clout to spend: %d") % GameState.clout
	if GameState.message != "":
		_message.text = GameState.message
		_message.add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
		GameState.message = ""
	if GameState.ascension > 0:
		_build_ascension_picker()
	for id in [&"fire", &"necro", &"rizz"]:
		var w := Database.get_wizard(id)
		if w != null:
			_choices.add_child(_make_wizard_button(w))
	(%Boutique as Button).text = Loc.t("Boutique  (spend Clout)")
	(%Boutique as Button).pressed.connect(func(): Fader.change_scene("res://scenes/hub/boutique.tscn"))
	var menu := Button.new()
	menu.text = Loc.t("Menu")
	menu.add_theme_font_size_override("font_size", 16)
	_style_btn(menu)
	menu.position = Vector2(24, 24)
	menu.size = Vector2(120, 38)
	menu.pressed.connect(func(): Fader.change_scene("res://scenes/hub/main_menu.tscn"))
	add_child(menu)
	var coll := Button.new()
	coll.text = Loc.t("Collection")
	coll.add_theme_font_size_override("font_size", 16)
	_style_btn(coll)
	coll.position = Vector2(24, 70)
	coll.size = Vector2(120, 38)
	coll.pressed.connect(func(): Fader.change_scene("res://scenes/hub/collection.tscn"))
	add_child(coll)

func _make_wizard_button(w: WizardData) -> Button:
	var locked := not GameState.wizard_unlocked(w.id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 320)
	b.disabled = locked
	var border: Color = Color(0.4, 0.4, 0.46) if locked else w.accent
	b.add_theme_stylebox_override("normal", _box(Color(0.14, 0.12, 0.18), border))
	b.add_theme_stylebox_override("hover", _box(Color(0.20, 0.17, 0.26), border.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.22, 0.19, 0.28), border))
	b.add_theme_stylebox_override("disabled", _box(Color(0.10, 0.09, 0.12), Color(0.32, 0.30, 0.36)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if not locked:
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
		tr.modulate = Color(0.25, 0.25, 0.3) if locked else Color.WHITE
		b.add_child(tr)
	var nm: Color = Color(0.6, 0.6, 0.66) if locked else w.accent.lightened(0.35)
	_label(b, w.pname, Vector2(12, 114), Vector2(276, 32), 24, nm)
	_label(b, Loc.t("the %s") % Loc.t(w.title), Vector2(12, 148), Vector2(276, 24), 17, Color(0.7, 0.7, 0.78))
	if locked:
		_label(b, GameState.locked_wizard_hint(w.id), Vector2(14, 184), Vector2(272, 110), 16, Color(0.85, 0.7, 0.4))
	else:
		_label(b, Loc.t("%d HP") % w.max_hp, Vector2(12, 176), Vector2(276, 24), 16, Color(0.8, 0.8, 0.85))
		_label(b, Loc.t(w.blurb), Vector2(18, 204), Vector2(264, 104), 16, Color(0.78, 0.78, 0.82))
	return b

var _asc_label: Label

func _build_ascension_picker() -> void:
	GameState.asc_level = clampi(GameState.asc_level, 0, GameState.ascension)
	var col := %Subtitle.get_parent()
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	var dec := Button.new()
	dec.text = "-"
	dec.add_theme_font_size_override("font_size", 20)
	_style_btn(dec)
	dec.pressed.connect(_asc_change.bind(-1))
	box.add_child(dec)
	_asc_label = Label.new()
	_asc_label.add_theme_font_size_override("font_size", 18)
	_asc_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
	_asc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_asc_label.custom_minimum_size = Vector2(420, 0)
	_asc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_asc_label)
	var inc := Button.new()
	inc.text = "+"
	inc.add_theme_font_size_override("font_size", 20)
	_style_btn(inc)
	inc.pressed.connect(_asc_change.bind(1))
	box.add_child(inc)
	col.add_child(box)
	col.move_child(box, 3)   # after Title/Subtitle/Message
	_update_asc_label()

func _asc_change(delta: int) -> void:
	GameState.asc_level = clampi(GameState.asc_level + delta, 0, GameState.ascension)
	_update_asc_label()

func _update_asc_label() -> void:
	var n := GameState.asc_level
	if n == 0:
		_asc_label.text = Loc.t("Ascension 0 / %d  —  base difficulty") % GameState.ascension
	else:
		_asc_label.text = Loc.t("Ascension %d / %d  —  +%d%% enemy HP, +%d%% dmg, +%d Clout") % [
			n, GameState.ascension, n * 8, n * 6, n * 10]

func _choose(id: StringName) -> void:
	Audio.play("click", -6.0)
	GameState.start_run(id)
	Fader.change_scene("res://scenes/hub/dressing_room.tscn")

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

func _style_btn(b: Button) -> void:
	b.add_theme_stylebox_override("normal", NodeUI.box(Color(0.15, 0.13, 0.2), Color(0.45, 0.5, 0.62), 2))
	b.add_theme_stylebox_override("hover", NodeUI.box(Color(0.22, 0.19, 0.3), Color(0.6, 0.66, 0.78), 2))
	b.add_theme_stylebox_override("pressed", NodeUI.box(Color(0.2, 0.17, 0.27), Color(0.45, 0.5, 0.62), 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(3)
	s.border_color = border
	s.set_corner_radius_all(12)
	return s
