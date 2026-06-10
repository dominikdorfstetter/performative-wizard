extends Control
## The run map. Draws the branching node graph (connections via _draw, nodes as buttons),
## shows run status, and routes the chosen node to the right scene.

const TYPE_PIX := {
	"Combat": "fist", "Elite": "skull", "Event": "quest", "Shop": "coin",
	"Rest": "zzz", "Chest": "chest", "Boss": "crown",
}
const TYPE_WORD := {
	"Combat": "fight", "Elite": "elite", "Event": "event", "Shop": "shop",
	"Rest": "rest", "Chest": "chest", "Boss": "boss",
}
const TipIcon = preload("res://scripts/ui/tip_icon.gd")
const TYPE_COLOR := {
	"Combat": Color(0.86, 0.30, 0.27), "Elite": Color(0.85, 0.4, 0.95),
	"Event": Color(0.4, 0.7, 0.9), "Shop": Color(0.95, 0.8, 0.3),
	"Rest": Color(0.4, 0.85, 0.55), "Chest": Color(0.9, 0.7, 0.4),
	"Boss": Color(0.95, 0.25, 0.25),
}
const SCENE := {
	"Combat": "res://scenes/combat/combat.tscn", "Elite": "res://scenes/combat/combat.tscn",
	"Boss": "res://scenes/combat/combat.tscn", "Rest": "res://scenes/nodes/rest.tscn",
	"Shop": "res://scenes/nodes/shop.tscn", "Event": "res://scenes/nodes/event.tscn",
	"Chest": "res://scenes/nodes/chest.tscn",
}
const LEFT := 150.0
const RIGHT := 1010.0
const TOP := 116.0
const BOT := 572.0
const NODE := 50.0

var _pos := {}
var _info: Label

func _ready() -> void:
	if GameState.map.is_empty():           # standalone fallback
		GameState.start_run(GameState.wizard_id)
		GameState.finalize_loadout()
	GameState.save_run()                   # quit-safe checkpoint: the run resumes from here
	Audio.play_music("menu")
	_compute_positions()
	_build_info()
	_build_nodes()
	if GameState.message != "":
		_info.text += "\n" + GameState.message
		GameState.message = ""
	queue_redraw()

func _compute_positions() -> void:
	var rows := GameState.map
	var n := rows.size()
	for r in n:
		var y: float = BOT - float(r) / float(n - 1) * (BOT - TOP)
		var row: Array = rows[r]
		var w := row.size()
		for c in w:
			var x: float = LEFT + (float(c) + 0.5) / float(w) * (RIGHT - LEFT)
			_pos["%d_%d" % [r, c]] = Vector2(x, y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.11))
	var rows := GameState.map
	for r in rows.size() - 1:
		for node in rows[r]:
			var a: Vector2 = _pos["%d_%d" % [r, node.col]]
			var from_current: bool = r == GameState.pos_row and node.col == GameState.pos_col
			for l in node.links:
				var b: Vector2 = _pos["%d_%d" % [r + 1, l]]
				var hot: bool = from_current or GameState.pos_row < 0 and r == 0
				draw_line(a, b, Color(0.95, 0.78, 0.35) if hot else Color(0.28, 0.26, 0.34), 3.0 if hot else 2.0)

func _build_nodes() -> void:
	var rows := GameState.map
	for r in rows.size():
		for node in rows[r]:
			_add_node_button(r, node)

func _add_node_button(r: int, node: Dictionary) -> void:
	var c: int = node.col
	var type: String = node.type
	var avail := GameState.can_enter(r, c)
	var current := r == GameState.pos_row and c == GameState.pos_col
	var col: Color = TYPE_COLOR.get(type, Color.GRAY)
	var border := Color(0.95, 0.78, 0.35) if avail else (Color(0.5, 0.9, 0.6) if current else col.darkened(0.2))
	var b := Button.new()
	b.size = Vector2(NODE, NODE)
	b.position = _pos["%d_%d" % [r, c]] - Vector2(NODE, NODE) * 0.5
	b.disabled = not avail
	var bg := Color(0.17, 0.15, 0.21) if (avail or current) else Color(0.11, 0.10, 0.13)
	b.add_theme_stylebox_override("normal", _circle(bg, border, 3 if (avail or current) else 2))
	b.add_theme_stylebox_override("hover", _circle(col.darkened(0.4), Color(1, 1, 0.7), 3))
	b.add_theme_stylebox_override("pressed", _circle(col.darkened(0.3), border, 3))
	b.add_theme_stylebox_override("disabled", _circle(bg, border, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if avail:
		b.pressed.connect(_enter.bind(r, c, type))

	var pix := SpriteBank.icon_texture(StringName(TYPE_PIX.get(type, "swirl")))
	if pix != null:
		var icon := TextureRect.new()
		icon.texture = pix
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(11, 10)
		icon.size = Vector2(28, 28)
		icon.modulate = Color.WHITE if (avail or current) else Color(1, 1, 1, 0.4)
		b.add_child(icon)
	# enemy-count badge so you can read the encounter before entering
	if type == "Combat" or type == "Elite":
		var cnt: int = node.get("enemies", []).size()
		if cnt > 0:
			var badge := Label.new()
			badge.text = str(cnt)
			badge.position = Vector2(NODE - 16, NODE - 18)
			badge.size = Vector2(16, 16)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_theme_font_size_override("font_size", 13)
			badge.add_theme_color_override("font_color", Color(1, 1, 1) if (avail or current) else Color(1, 1, 1, 0.4))
			b.add_child(badge)
		# The Critic's pending verdict will rewrite the next fight you enter — show it
		# ON THE MAP (crown = VIP gold ahead, heckler = she's sending one).
		if avail and (GameState.pending_critic == "S" or GameState.pending_critic == "C"):
			var mark := TextureRect.new()
			mark.texture = SpriteBank.icon_texture(&"crown") if GameState.pending_critic == "S" else SpriteBank.texture(&"heckler")
			mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.position = Vector2(-7, -9)
			mark.size = Vector2(20, 20)
			b.add_child(mark)
			var tw := mark.create_tween().set_loops()
			tw.tween_property(mark, "modulate:a", 0.45, 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(mark, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	add_child(b)

func _build_info() -> void:
	_info = Label.new()
	_info.position = Vector2(20, 14)
	_info.size = Vector2(1112, 80)
	_info.add_theme_font_size_override("font_size", 18)
	var w := Database.get_wizard(GameState.wizard_id)
	var parts: Array[String] = [
		Loc.t(w.title),
		Loc.t("Act %d/%d") % [GameState.act, GameState.MAX_ACTS],
	]
	if GameState.asc_level > 0:
		parts.append(Loc.t("Asc %d") % GameState.asc_level)
	parts.append("HP %d/%d" % [GameState.player_hp, GameState.player_max_hp])
	parts.append(Loc.t("Gold %d") % GameState.gold)
	parts.append(Loc.t("Clout %d") % GameState.clout)
	_info.text = "    ".join(parts)
	var trend := GameState.trend_label()
	if trend != "":
		_info.text += "\n%s    %s" % [trend, Loc.t("Critic score %d") % GameState.critic_score]
	add_child(_info)
	_build_artifact_row()
	var deck_btn := Button.new()
	deck_btn.text = Loc.t("deck (%d)") % GameState.deck.size()
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.add_theme_stylebox_override("normal", NodeUI.box(Color(0.15, 0.13, 0.2), Color(0.45, 0.5, 0.62), 2))
	deck_btn.add_theme_stylebox_override("hover", NodeUI.box(Color(0.22, 0.19, 0.3), Color(0.6, 0.66, 0.78), 2))
	deck_btn.add_theme_stylebox_override("pressed", NodeUI.box(Color(0.2, 0.17, 0.27), Color(0.45, 0.5, 0.62), 2))
	deck_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	deck_btn.position = Vector2(968, 12)
	deck_btn.size = Vector2(164, 34)
	deck_btn.pressed.connect(_show_deck)
	add_child(deck_btn)
	# Pixel-icon legend (matches the node buttons), replacing the emoji hint line.
	var legend := HBoxContainer.new()
	legend.position = Vector2(20, 614)
	legend.add_theme_constant_override("separation", 12)
	add_child(legend)
	var intro := Label.new()
	intro.text = Loc.t("tap a glowing node:")
	intro.add_theme_font_size_override("font_size", 14)
	intro.add_theme_color_override("font_color", Color(0.6, 0.6, 0.66))
	legend.add_child(intro)
	for t in ["Combat", "Elite", "Event", "Shop", "Rest", "Chest", "Boss"]:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 3)
		var ic := TextureRect.new()
		ic.texture = SpriteBank.icon_texture(StringName(TYPE_PIX[t]))
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.custom_minimum_size = Vector2(18, 18)
		pair.add_child(ic)
		var l := Label.new()
		l.text = Loc.t(TYPE_WORD[t])
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", TYPE_COLOR[t].lightened(0.2))
		pair.add_child(l)
		legend.add_child(pair)
	var hint := Label.new()
	hint.text = Loc.t("(badge = number of enemies)")
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.55, 0.55, 0.62))
	legend.add_child(hint)

# Relics as pixel charms with hover tooltips (was an emoji list in the header label).
func _build_artifact_row() -> void:
	var x := 700.0
	for aid in GameState.run_artifacts:
		var a := Database.get_artifact(aid)
		if a == null:
			continue
		var tex := SpriteBank.artifact_texture(aid)
		if tex == null:
			continue
		var tr := TipIcon.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(22, 22)
		tr.size = Vector2(22, 22)
		tr.position = Vector2(x, 16)
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		tr.set_tip(Loc.t(a.title), Loc.t(a.description))
		add_child(tr)
		x += 25

func _show_deck() -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.07, 0.93)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg)
	var title := Label.new()
	title.text = Loc.t("your deck  (%d cards)") % GameState.deck.size()
	title.position = Vector2(0, 36)
	title.size = Vector2(1152, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	overlay.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 90)
	scroll.size = Vector2(1012, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for id in GameState.deck:
		var card := Database.get_card(id)
		if card != null:
			grid.add_child(CardView.build(card, true, Callable()))
	overlay.add_child(scroll)
	var close := NodeUI.menu_button("Close", func(): overlay.queue_free(), Color(0.9, 0.4, 0.5), 200.0)
	close.position = Vector2(476, 580)
	overlay.add_child(close)
	add_child(overlay)

func _enter(r: int, c: int, type: String) -> void:
	GameState.enter(r, c)
	get_tree().change_scene_to_file(SCENE.get(type, "res://scenes/combat/combat.tscn"))

func _circle(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(25)
	return s
