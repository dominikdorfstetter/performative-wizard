extends Control
## Interactive combat. Reads the encounter from the current map node, renders the fight
## (multiple enemies, click to target), and on victory awards gold + routes to the reward
## screen — or, for the boss, ends the run.

const C_BG_PANEL := Color(0.13, 0.11, 0.17)
const C_PANEL_BORDER := Color(0.28, 0.24, 0.36)
const C_HP := Color(0.85, 0.27, 0.24)
const C_HP_TRACK := Color(0.22, 0.12, 0.13)
const C_SWAG := Color(1.0, 0.31, 0.70)
const C_SWAG_TRACK := Color(0.26, 0.10, 0.20)
const C_GOLD := Color(1.0, 0.82, 0.29)
const C_INTENT := Color(1.0, 0.62, 0.36)
const C_TARGET := Color(1.0, 0.82, 0.29)

var cm: CombatManager
var _popups: Control
var _prev_enemy_hp: Array = []
var _prev_player_hp := -1

@onready var _turn_banner: Label = $TurnBanner
@onready var _gold: Label = $GoldLabel
@onready var _artifacts: Label = $ArtifactsLabel
@onready var _enemies_box: HBoxContainer = $Enemies
@onready var _player_name: Label = $PlayerPanel/PlayerName
@onready var _player_hp_bar: ProgressBar = $PlayerPanel/PlayerHPBar
@onready var _player_hp_text: Label = $PlayerPanel/PlayerHPBar/PlayerHPText
@onready var _player_status: Label = $PlayerPanel/PlayerStatus
@onready var _energy: Label = $ResourcePanel/EnergyBadge
@onready var _swag_value: Label = $ResourcePanel/SwagValue
@onready var _swag_bar: ProgressBar = $ResourcePanel/SwagBar
@onready var _thresholds: Label = $ResourcePanel/SwagThresholds
@onready var _log: Label = $LogPanel/LogText
@onready var _piles: Label = $Piles
@onready var _hand: HBoxContainer = $Hand
@onready var _end_turn: Button = $EndTurn
@onready var _result_panel: Panel = $ResultPanel
@onready var _result_label: Label = $ResultPanel/ResultLabel

func _ready() -> void:
	_style_chrome()
	_end_turn.pressed.connect(_on_end_turn)
	$ResultPanel/RestartButton.pressed.connect(_to_menu)
	_result_panel.visible = false
	set_process_unhandled_input(true)
	_popups = Control.new()
	_popups.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_popups)
	# Standalone fallback (headless / direct scene run).
	if GameState.map.is_empty():
		GameState.start_run(&"fire")
		GameState.finalize_loadout()
		GameState.enter(0, 0)
	_start_fight()

func _style_chrome() -> void:
	for p in [$PlayerPanel, $ResourcePanel, $LogPanel, _result_panel]:
		p.add_theme_stylebox_override("panel", _panel_box(C_BG_PANEL, C_PANEL_BORDER))
	_style_bar(_player_hp_bar, C_HP, C_HP_TRACK)
	_style_bar(_swag_bar, C_SWAG, C_SWAG_TRACK)
	_swag_value.add_theme_color_override("font_color", C_SWAG)
	_energy.add_theme_color_override("font_color", C_GOLD)
	_gold.add_theme_color_override("font_color", C_GOLD)
	_end_turn.add_theme_stylebox_override("normal", _panel_box(Color(0.16, 0.36, 0.22), Color(0.36, 0.70, 0.45)))
	_end_turn.add_theme_stylebox_override("hover", _panel_box(Color(0.20, 0.46, 0.28), Color(0.45, 0.85, 0.55)))
	_end_turn.add_theme_stylebox_override("pressed", _panel_box(Color(0.14, 0.30, 0.19), Color(0.36, 0.70, 0.45)))

func _start_fight() -> void:
	var node := GameState.current_node()
	var w := Database.get_wizard(GameState.wizard_id)
	var player := Combatant.new()
	player.display_name = w.title
	player.max_hp = GameState.player_max_hp
	player.hp = GameState.player_hp
	_player_name.text = w.pname
	_player_name.add_theme_color_override("font_color", w.accent.lightened(0.3))
	_player_hp_bar.max_value = player.max_hp
	var wtex := SpriteBank.wizard_texture(GameState.wizard_id)
	if wtex != null:
		var ptr := TextureRect.new()
		ptr.texture = wtex
		ptr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ptr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ptr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ptr.position = Vector2(268, 4)
		ptr.size = Vector2(62, 62)
		$PlayerPanel.add_child(ptr)

	var deck: Array[CardData] = []
	for id in GameState.deck:
		var c := Database.get_card(id)
		if c != null:
			deck.append(c)

	var encounter: Array = []
	for eid in node.get("enemies", [&"alley_cat"]):
		var ed := Database.get_enemy(eid)
		if ed != null:
			encounter.append(ed)

	var scales: Array = GameState.node_scales(node)
	cm = CombatManager.new()
	cm.changed.connect(_refresh)
	cm.combat_ended.connect(_on_combat_ended)
	cm.start_combat(player, encounter, deck, GameState.drip, false, GameState.active_passives(), scales[0], scales[1])
	_prev_enemy_hp = []
	for e in cm.enemies:
		_prev_enemy_hp.append(e.hp)
	_prev_player_hp = cm.player.hp
	print("[Combat] node %s row %d: %d enemies, scale %.2f/%.2f"
		% [node.get("type"), node.get("row"), encounter.size(), scales[0], scales[1]])
	_refresh()

# --- rendering -----------------------------------------------------------

func _refresh() -> void:
	if cm == null:
		return
	var over := cm.state == CombatManager.State.WIN or cm.state == CombatManager.State.LOSE
	_turn_banner.text = "ENEMY TURN" if cm.state == CombatManager.State.ENEMY_TURN else "TURN %d" % cm.turn
	_gold.text = "💰 %d" % GameState.gold
	_artifacts.text = _artifact_text()

	_player_hp_bar.value = cm.player.hp
	_player_hp_text.text = "%d / %d" % [cm.player.hp, cm.player.max_hp]
	_player_status.text = _status_text(cm.player)
	_energy.text = "⚡ Energy  %d / %d" % [cm.energy, cm.max_energy]
	_swag_value.text = "✦ SWAG  %d   (+%d/turn)" % [cm.swag, cm.drip]
	_swag_bar.value = min(cm.swag, _swag_bar.max_value)
	_thresholds.text = _threshold_text()
	_piles.text = "🂠 Draw %d    🗑 Discard %d" % [cm.draw_pile.size(), cm.discard_pile.size()]
	_log.text = "\n".join(cm.log_lines)
	_end_turn.disabled = over or cm.state != CombatManager.State.PLAYER_TURN

	_rebuild_enemies(over)
	_rebuild_hand(over)
	_emit_popups()

func _emit_popups() -> void:
	if _popups == null:
		return
	for i in cm.enemies.size():
		if i < _prev_enemy_hp.size():
			var d: int = int(_prev_enemy_hp[i]) - cm.enemies[i].hp
			if d > 0:
				_float_text(_enemy_center(i), "-%d" % d, C_HP.lightened(0.25))
	if _prev_player_hp >= 0 and cm.player.hp < _prev_player_hp:
		_float_text(Vector2(180, 320), "-%d" % (_prev_player_hp - cm.player.hp), Color(1, 0.5, 0.4))
		_hurt_flash()
	_prev_enemy_hp = []
	for e in cm.enemies:
		_prev_enemy_hp.append(e.hp)
	_prev_player_hp = cm.player.hp

func _enemy_center(i: int) -> Vector2:
	var n := cm.enemies.size()
	var wper := 186.0 + 22.0
	var total := n * 186.0 + (n - 1) * 22.0
	var start_x := 300.0 + (812.0 - total) * 0.5
	return Vector2(start_x + i * wper + 93.0, 150.0)

func _float_text(pos: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", color)
	lbl.position = pos - Vector2(18, 0)
	_popups.add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 48, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(lbl.queue_free)

func _hurt_flash() -> void:
	var fl := ColorRect.new()
	fl.color = Color(0.9, 0.12, 0.12, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popups.add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.16, 0.05)
	tw.tween_property(fl, "color:a", 0.0, 0.25)
	tw.tween_callback(fl.queue_free)

func _rebuild_enemies(over: bool) -> void:
	for c in _enemies_box.get_children():
		c.queue_free()
	for i in cm.enemies.size():
		_enemies_box.add_child(_make_enemy_widget(cm.enemies[i], i, over))

func _make_enemy_widget(e: Combatant, index: int, over: bool) -> Control:
	var dead := e.is_dead()
	var targeted := (not over) and (cm.target_index == index) and not dead
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(186, 188)
	var border := C_TARGET if targeted else C_PANEL_BORDER
	panel.add_theme_stylebox_override("panel", _panel_box(C_BG_PANEL if not dead else Color(0.1, 0.09, 0.11), border, 3 if targeted else 2))
	if not dead and not over:
		panel.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				cm.set_target(index))

	if not dead:
		var shadow := Panel.new()
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0, 0, 0, 0.25)
		ss.set_corner_radius_all(12)
		shadow.add_theme_stylebox_override("panel", ss)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.position = Vector2(56, 62)
		shadow.size = Vector2(74, 12)
		panel.add_child(shadow)

	var tex: Texture2D = null if dead else SpriteBank.texture(e.data.id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(48, 0)
		tr.size = Vector2(90, 66)
		panel.add_child(tr)
	else:
		var sprite := Label.new()
		sprite.text = "☠" if dead else e.data.emoji
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sprite.add_theme_font_size_override("font_size", 50)
		sprite.position = Vector2(43, 6)
		sprite.size = Vector2(100, 60)
		panel.add_child(sprite)

	var intent := Label.new()
	intent.text = "" if (over or dead) else _intent_text_for(e)
	intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent.add_theme_font_size_override("font_size", 18)
	intent.add_theme_color_override("font_color", C_INTENT)
	intent.position = Vector2(8, 64)
	intent.size = Vector2(170, 24)
	panel.add_child(intent)

	var nm := Label.new()
	nm.text = e.display_name
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 14)
	nm.position = Vector2(6, 92)
	nm.size = Vector2(174, 20)
	panel.add_child(nm)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = e.max_hp
	bar.value = e.hp
	bar.position = Vector2(14, 118)
	bar.size = Vector2(158, 22)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(bar, C_HP, C_HP_TRACK)
	var hptext := Label.new()
	hptext.text = "%d / %d" % [e.hp, e.max_hp]
	hptext.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hptext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hptext.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hptext.add_theme_font_size_override("font_size", 13)
	hptext.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(hptext)
	panel.add_child(bar)

	var st := Label.new()
	st.text = _status_text(e)
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_font_size_override("font_size", 13)
	st.position = Vector2(6, 144)
	st.size = Vector2(174, 38)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(st)
	return panel

func _rebuild_hand(over: bool) -> void:
	for child in _hand.get_children():
		child.queue_free()
	if over:
		return
	for card in cm.hand:
		_hand.add_child(CardView.build(card, cm.can_play(card), _play.bind(card)))

func _play(card: CardData) -> void:
	cm.play_card(card)

# --- text helpers --------------------------------------------------------

func _status_text(c: Combatant) -> String:
	var parts: Array[String] = []
	if c.block > 0:
		parts.append("🛡 %d" % c.block)
	for k in c.statuses:
		if c.statuses[k] > 0:
			parts.append("%s %d" % [String(k).capitalize(), c.statuses[k]])
	return "  ".join(parts)

func _intent_text_for(e: Combatant) -> String:
	var it := cm.peek_intent(e)
	if it.is_empty():
		return ""
	var amount := int(round(int(it.get("amount", 0)) * cm.enemy_dmg_scale))
	match String(it.get("op", "")):
		"attack":
			return "Attacks %d" % amount
		"block":
			return "🛡️ %d" % int(it.get("amount", 0))
		"apply_status":
			return "%s %d" % [String(it.get("status", &"")).capitalize(), int(it.get("amount", 0))]
		"buff":
			return "Str +%d" % int(it.get("amount", 0))
	return "?"

func _threshold_text() -> String:
	var d := func(n): return "●" if cm.swag >= n else "○"
	return "%s ≥5 +2dmg    %s ≥10 +draw    %s ≥15 pierce" % [d.call(5), d.call(10), d.call(15)]

func _artifact_text() -> String:
	if GameState.run_artifacts.is_empty():
		return ""
	var parts: Array[String] = []
	for aid in GameState.run_artifacts:
		var a := Database.get_artifact(aid)
		if a != null:
			parts.append(a.emoji)
	return "🎒 " + " ".join(parts)

# --- styles --------------------------------------------------------------

func _panel_box(bg: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(8)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func _style_bar(bar: ProgressBar, fill: Color, track: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = track
	bg.set_corner_radius_all(6)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)

# --- input & flow --------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MAXIMIZED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()

func _on_end_turn() -> void:
	cm.end_turn()

func _on_combat_ended(victory: bool) -> void:
	if victory:
		GameState.player_hp = cm.player.hp
		var node := GameState.current_node()
		if node.get("type") == "Boss":
			GameState.finish_run(true)
			get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/reward.tscn")
		return
	GameState.finish_run(false)
	_result_label.text = "DEFEAT"
	_result_label.add_theme_color_override("font_color", C_HP)
	_result_panel.visible = true
	_refresh()

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
