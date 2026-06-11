extends Node
## Dev tool: renders the itch.io page art at EXACT pixel sizes via SubViewports
## (immune to the window stretch), using the game's own fonts and sprites:
##   dist/itch-cover.png   630x500 — the browse/search thumbnail (itch crops it
##                         to ~315x250: the wordmark + stamp must read at 50%)
##   dist/itch-banner.png  960x300 — the page header
## Run WINDOWED:  PW_NO_SAVE=1 godot scenes/tools/make_itch_art.tscn

const BG_TOP := Color("181024")
const BG_BOT := Color("0e0a14")
const PINK := Color("ff4fb3")
const GOLD := Color("ffd24a")

func _ready() -> void:
	await _render(Vector2i(630, 500), _build_cover, "res://dist/itch-cover.png")
	await _render(Vector2i(960, 300), _build_banner, "res://dist/itch-banner.png")
	print("[make_itch_art] wrote dist/itch-cover.png and dist/itch-banner.png")
	get_tree().quit()

func _render(size: Vector2i, builder: Callable, path: String) -> void:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var root := Control.new()
	root.size = size
	vp.add_child(root)
	builder.call(root, size)
	await get_tree().create_timer(0.5).timeout
	vp.get_texture().get_image().save_png(path)
	vp.queue_free()
	await get_tree().process_frame

func _bg(root: Control, size: Vector2i) -> void:
	NodeUI.gradient_bg(root, BG_TOP, BG_BOT)   # full-rect anchored: tracks root's size
	for p in [[0.12, 0.16], [0.3, 0.08], [0.55, 0.05], [0.78, 0.12], [0.92, 0.2], [0.08, 0.7], [0.9, 0.62], [0.45, 0.9]]:
		var d := ColorRect.new()
		d.color = Color(1, 1, 1, 0.5)
		d.size = Vector2(3, 3)
		d.position = Vector2(p[0] * size.x, p[1] * size.y)
		root.add_child(d)

func _word(root: Control, text: String, y: float, fs: int, color: Color, w: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(w, fs * 1.2)
	root.add_child(l)
	return l

func _sprite(root: Control, id: StringName, px: int, pos: Vector2) -> void:
	var tr := TextureRect.new()
	tr.texture = SpriteBank.texture(id)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.position = pos
	tr.size = Vector2(px, px)
	root.add_child(tr)

func _wizard(root: Control, id: StringName, px: int, pos: Vector2) -> void:
	var tr := TextureRect.new()
	tr.texture = SpriteBank.wizard_texture(id)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.position = pos
	tr.size = Vector2(px, px)
	root.add_child(tr)

## The reward screen's grade stamp, reused as key art: ringed letter, tilted.
func _stamp(root: Control, letter: String, fs: int, pos: Vector2, tilt_deg: float) -> void:
	var stamp := Label.new()
	stamp.text = letter
	stamp.add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	stamp.add_theme_font_size_override("font_size", fs)
	stamp.add_theme_color_override("font_color", GOLD)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.position = pos
	stamp.size = Vector2(fs * 1.1, fs * 1.15)
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation = deg_to_rad(tilt_deg)
	var ring := Panel.new()
	ring.position = Vector2(-fs * 0.12, fs * 0.05)
	ring.size = Vector2(fs * 1.3, fs * 1.12)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(maxi(3, fs / 22))
	sb.border_color = GOLD
	sb.set_corner_radius_all(fs / 7)
	ring.add_theme_stylebox_override("panel", sb)
	stamp.add_child(ring)
	root.add_child(stamp)

func _chip(root: Control, text: String, pos: Vector2, fs: int) -> void:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = GOLD
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	chip.add_theme_stylebox_override("panel", sb)
	chip.position = pos
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color("181024"))
	chip.add_child(l)
	root.add_child(chip)

func _build_cover(root: Control, size: Vector2i) -> void:
	_bg(root, size)
	_word(root, "PERFORMATIVE", 26, 74, PINK, size.x)
	_word(root, "WIZARDS", 102, 74, PINK, size.x)
	_word(root, "she grades every fight", 188, 27, Color(0.88, 0.85, 0.95), size.x)
	# the Critic looms; her verdict is the key art
	_sprite(root, &"the_critic", 240, Vector2(330, 235))
	_stamp(root, "S", 155, Vector2(95, 262), -10.0)
	_chip(root, "FREE  ·  PLAYS IN YOUR BROWSER", Vector2(141, 448), 19)

func _build_banner(root: Control, size: Vector2i) -> void:
	_bg(root, size)
	var t1 := _word(root, "PERFORMATIVE WIZARDS", 36, 56, PINK, 660)
	t1.position.x = 22
	var t2 := _word(root, "a roguelike deckbuilder about drip —", 116, 24, Color(0.88, 0.85, 0.95), 660)
	t2.position.x = 22
	var t3 := _word(root, "reviewed live by The Critic", 148, 24, Color(0.88, 0.85, 0.95), 660)
	t3.position.x = 22
	_chip(root, "FREE  ·  IN YOUR BROWSER", Vector2(212, 218), 18)
	_wizard(root, &"fire", 116, Vector2(656, 158))
	_wizard(root, &"necro", 116, Vector2(758, 158))
	_wizard(root, &"rizz", 116, Vector2(860, 158))
	_stamp(root, "S", 86, Vector2(846, 26), -10.0)
