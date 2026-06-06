extends Control
## Title screen: New Game (fresh meta) / Continue (keep meta) / Options / Exit.

func _ready() -> void:
	NodeUI.gradient_bg(self)
	set_process_unhandled_input(true)
	_build()

func _build() -> void:
	_clear()
	_title()
	_portraits()
	var vb := VBoxContainer.new()
	vb.position = Vector2(406, 262)
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)
	vb.add_child(NodeUI.menu_button("▶   New Game", _new_game, Color(0.9, 0.4, 0.55)))
	vb.add_child(NodeUI.menu_button(_continue_label(), _continue, Color(0.45, 0.82, 0.55)))
	vb.add_child(NodeUI.menu_button("⚙   Options", _options, Color(0.5, 0.62, 0.85)))
	vb.add_child(NodeUI.menu_button("✕   Exit Game", _exit, Color(0.55, 0.5, 0.58)))
	_footer("F11 toggles fullscreen")

func _title() -> void:
	var t := Label.new()
	t.text = "PERFORMATIVE WIZARD"
	t.add_theme_font_size_override("font_size", 56)
	t.add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 76)
	t.size = Vector2(1152, 64)
	add_child(t)
	var s := Label.new()
	s.text = "a roguelike deckbuilder about drip"
	s.add_theme_font_size_override("font_size", 20)
	s.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.position = Vector2(0, 142)
	s.size = Vector2(1152, 28)
	add_child(s)

func _portraits() -> void:
	_sprite(&"fire", Vector2(150, 300))
	_sprite(&"necro", Vector2(852, 300))

func _sprite(id: StringName, pos: Vector2) -> void:
	var tex := SpriteBank.wizard_texture(id)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = pos
	tr.size = Vector2(150, 150)
	add_child(tr)

func _continue_label() -> String:
	if GameState.has_save():
		return "↻   Continue   (✦ %d)" % GameState.clout
	return "↻   Continue"

# --- actions -------------------------------------------------------------

func _new_game() -> void:
	if GameState.has_save() and _has_progress():
		_confirm_new_game()
	else:
		GameState.new_game()
		_to_class_select()

func _has_progress() -> bool:
	return GameState.clout > 0 or GameState.unlocked_outfits.size() > GameState.STARTER_OWNED.size()

func _confirm_new_game() -> void:
	_clear()
	_title()
	var s := Label.new()
	s.text = "Starting a new game erases your unlocked clothes and Clout. Continue?"
	s.add_theme_font_size_override("font_size", 20)
	s.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD
	s.position = Vector2(276, 280)
	s.size = Vector2(600, 60)
	add_child(s)
	var vb := VBoxContainer.new()
	vb.position = Vector2(406, 360)
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)
	vb.add_child(NodeUI.menu_button("Erase & Start Fresh", func(): GameState.new_game(); _to_class_select(), Color(0.9, 0.35, 0.4)))
	vb.add_child(NodeUI.menu_button("← Cancel", _build, Color(0.5, 0.55, 0.7)))

func _continue() -> void:
	_to_class_select()

func _options() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/options.tscn")

func _exit() -> void:
	get_tree().quit()

func _to_class_select() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")

# --- helpers -------------------------------------------------------------

func _footer(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 612)
	l.size = Vector2(1152, 24)
	add_child(l)

func _clear() -> void:
	for c in get_children():
		if not (c is TextureRect and c.texture is GradientTexture2D):
			c.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MAXIMIZED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
