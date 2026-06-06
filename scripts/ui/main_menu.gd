extends Control
## Title screen: New Game (fresh meta) / Continue (keep meta) / Options / Exit.
## The two wizards face each other and trade Gen-Z banter in speech bubbles.

const BANTER := [
	"ngl your drip is mid",
	"bestie you ATE that 💅",
	"it's giving necromancer-core",
	"lowkey bussin no cap",
	"my rizz? immaculate",
	"that fit is so slay fr",
	"skibidi drip incoming",
	"let me cook 🔥",
	"delulu is the solulu",
	"we stan a serve",
	"touch grass? in THIS economy??",
	"vibe check: passed bestie",
	"no thoughts just drip",
	"sheeeesh that's hard 😤",
	"main character energy ✨",
	"you're so fr rn 💀",
]

var _fire_tr: TextureRect
var _necro_tr: TextureRect
var _fire_bubble: Control
var _necro_bubble: Control
var _talk_i := 0

func _ready() -> void:
	NodeUI.gradient_bg(self)
	set_process_unhandled_input(true)
	Audio.play_music("menu")
	_add_decor()
	_build()

func _add_decor() -> void:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 6.0
	p.position = Vector2(576, 660)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(600, 6)
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -4)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.5, 0.85, 0.5)
	p.add_to_group("decor")
	add_child(p)
	var i := 0
	for pos in [[140, 120], [320, 90], [560, 100], [760, 80], [900, 140], [220, 170], [680, 160], [430, 70], [1000, 110]]:
		var c := ColorRect.new()
		c.color = Color(1, 1, 1)
		c.size = Vector2(3, 3)
		c.position = Vector2(pos[0], pos[1])
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_to_group("decor")
		add_child(c)
		var tw := c.create_tween().set_loops()
		tw.tween_interval(0.28 * i)
		tw.tween_property(c, "modulate:a", 0.12, 0.95).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "modulate:a", 1.0, 0.95).set_trans(Tween.TRANS_SINE)
		i += 1

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
	t.pivot_offset = Vector2(576, 32)
	add_child(t)
	# gentle glow pulse so the title feels alive
	var tw := t.create_tween().set_loops()
	tw.tween_property(t, "modulate", Color(1.15, 1.0, 1.2), 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(t, "modulate", Color.WHITE, 1.6).set_trans(Tween.TRANS_SINE)
	var s := Label.new()
	s.text = "a roguelike deckbuilder about drip"
	s.add_theme_font_size_override("font_size", 20)
	s.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.position = Vector2(0, 142)
	s.size = Vector2(1152, 28)
	add_child(s)

func _portraits() -> void:
	_fire_tr = _sprite(&"fire", Vector2(150, 300), 1)     # glancing right, toward necro
	_necro_tr = _sprite(&"necro", Vector2(852, 300), -1)  # glancing left, toward fire
	if _fire_tr:
		_bob(_fire_tr, 0.0)
	if _necro_tr:
		_bob(_necro_tr, 0.5)
	_fire_bubble = _make_bubble(Vector2(108, 206))
	_necro_bubble = _make_bubble(Vector2(814, 206))
	_setup_talk()

func _sprite(id: StringName, pos: Vector2, look := 0) -> TextureRect:
	var tex := SpriteBank.wizard_texture(id, look)
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = pos
	tr.size = Vector2(150, 150)
	add_child(tr)
	return tr

# --- banter & animation --------------------------------------------------

func _make_bubble(pos: Vector2) -> Control:
	var w := 236.0
	var h := 62.0
	var c := Control.new()
	c.position = pos
	c.size = Vector2(w, h)
	c.visible = false
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(w * 0.5 - 11, h - 2), Vector2(w * 0.5 + 11, h - 2), Vector2(w * 0.5, h + 16)])
	tail.color = Color(0.96, 0.95, 0.98)
	c.add_child(tail)
	var panel := Panel.new()
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.95, 0.98)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.85, 0.45, 0.72)
	panel.add_theme_stylebox_override("panel", sb)
	c.add_child(panel)
	var lbl := Label.new()
	lbl.name = "Label"
	lbl.add_theme_color_override("font_color", Color(0.14, 0.1, 0.17))
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 10
	lbl.offset_right = -10
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)
	add_child(c)
	return c

func _setup_talk() -> void:
	var t := Timer.new()
	t.wait_time = 2.6
	t.autostart = true
	add_child(t)
	t.timeout.connect(_next_talk)
	_next_talk()

func _next_talk() -> void:
	var fire_turn := _talk_i % 2 == 0
	var line: String = BANTER[_talk_i % BANTER.size()]
	_talk_i += 1
	if fire_turn:
		_hide_bubble(_necro_bubble)
		_show_bubble(_fire_bubble, line)
		_react(_fire_tr)
	else:
		_hide_bubble(_fire_bubble)
		_show_bubble(_necro_bubble, line)
		_react(_necro_tr)

func _show_bubble(b: Control, text: String) -> void:
	if b == null:
		return
	b.get_node("Label").text = text
	b.visible = true
	b.pivot_offset = Vector2(b.size.x * 0.5, b.size.y)
	b.scale = Vector2(0.4, 0.4)
	# bind the tween to the bubble, not to self — so _clear() freeing the bubble
	# kills its tween instead of leaving it animating a freed node.
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_bubble(b: Control) -> void:
	if b != null:
		b.visible = false

func _bob(tr: TextureRect, delay: float) -> void:
	var y := tr.position.y
	# Bind to tr (not self): a looping tween whose target is freed by _clear() while
	# the menu lives on would spin a zero-duration loop and hang the window.
	var tw := tr.create_tween().set_loops()
	tw.tween_interval(delay)
	tw.tween_property(tr, "position:y", y - 9, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(tr, "position:y", y, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _react(tr: TextureRect) -> void:
	if tr == null:
		return
	tr.pivot_offset = tr.size * 0.5
	tr.scale = Vector2(1.14, 0.88)
	var tw := tr.create_tween()
	tw.tween_property(tr, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

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
		if c.is_in_group("decor"):
			continue
		if not (c is TextureRect and c.texture is GradientTexture2D):
			c.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MAXIMIZED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
