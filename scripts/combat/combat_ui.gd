extends Control
## Battle-scene combat: the wizard stands on the left, monsters on the right over a
## pixel backdrop. Attacks lunge, blocks flash, hits recoil. Reads the encounter from
## the current map node; on victory awards gold and routes to the reward screen.

const C_PANEL_BORDER := Color(0.28, 0.24, 0.36)
const C_HP := Color(0.85, 0.27, 0.24)
const C_HP_TRACK := Color(0.22, 0.12, 0.13)
const C_SWAG := Color(1.0, 0.31, 0.70)
const C_SWAG_TRACK := Color(0.26, 0.10, 0.20)
const C_GOLD := Color(1.0, 0.82, 0.29)
const C_INTENT := Color(1.0, 0.62, 0.36)
const C_TARGET := Color(1.0, 0.82, 0.29)

# Summoned-goon row, between the wizard and the enemies, standing on the floor.
const GOON_Y := 250.0
const GOON_X0 := 252.0
const GOON_STEP := 40.0
const GOON_SIZE := 50.0

const STATUS_NAME := {&"strength": "Rizz", &"vulnerable": "Cooked", &"weak": "Mid", &"burn": "Roasted", &"undead": "Goons", &"jinx": "Jinxed"}
const STATUS_ICON := {&"block": "shield", &"burn": "fire", &"undead": "bones", &"strength": "rizz", &"vulnerable": "cooked", &"weak": "mid", &"jinx": "swirl"}
const PLAYER_LINES := ["aura farming fr 🧿", "I'm so BACK", "the aura is auraing", "+1000 aura", "main character energy ✨", "locked TF in", "we mogging rn 😤"]
const ENEMY_TAUNTS := ["skill issue", "you're so cooked", "ratio + L", "couldn't be me", "cope harder", "down bad ngl", "you fell off", "0 aura detected", "this you? 💀", "stay mad bestie"]

var cm: CombatManager
var _popups: Control
var _player_sprite: TextureRect
var _player_hp_bar: ProgressBar
var _player_hp_text: Label
var _player_status_box: HBoxContainer
var _goons_box: Control
var _goon_sprites: Array = []
var _enemy_widgets: Array = []
var _enemy_sprites: Array = []
var _prev_enemy_hp: Array = []
var _prev_player_hp := -1
var _prev_swag := 0
var _prev_state := -1
var _player_home := Vector2.ZERO

@onready var _bg: TextureRect = $Background
@onready var _hudbg: Panel = $HudBg
@onready var _turn_banner: Label = $TurnBanner
@onready var _gold: Label = $GoldLabel
@onready var _log_line: Label = $LogLine
@onready var _enemies_box: HBoxContainer = $Enemies
@onready var _energy: Label = $EnergyLabel
@onready var _swag_value: Label = $SwagValue
@onready var _swag_bar: ProgressBar = $SwagBar
@onready var _thresholds: Label = $SwagThresholds
@onready var _end_turn: Button = $EndTurn
@onready var _hand: HBoxContainer = $Hand
@onready var _result_panel: Panel = $ResultPanel
@onready var _result_label: Label = $ResultPanel/ResultLabel

func _ready() -> void:
	_bg.texture = SpriteBank.battle_bg()
	_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_hudbg.add_theme_stylebox_override("panel", _panel_box(Color(0.08, 0.06, 0.11, 0.92), Color(0.2, 0.17, 0.26)))
	_style_bar(_swag_bar, C_SWAG, C_SWAG_TRACK)
	_swag_value.add_theme_color_override("font_color", C_SWAG)
	_energy.add_theme_color_override("font_color", C_GOLD)
	_gold.add_theme_color_override("font_color", C_GOLD)
	_end_turn.pressed.connect(_on_end_turn)
	_end_turn.add_theme_stylebox_override("normal", _panel_box(Color(0.16, 0.36, 0.22), Color(0.36, 0.70, 0.45)))
	_end_turn.add_theme_stylebox_override("hover", _panel_box(Color(0.20, 0.46, 0.28), Color(0.45, 0.85, 0.55)))
	_result_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.13, 0.11, 0.17), C_PANEL_BORDER))
	$ResultPanel/RestartButton.pressed.connect(_to_menu)
	_result_panel.visible = false
	set_process_unhandled_input(true)
	_popups = Control.new()
	_popups.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_popups)
	_add_sparkles()
	_add_twinkles()
	Audio.play_music()
	if GameState.map.is_empty():
		GameState.start_run(&"fire")
		GameState.finalize_loadout()
		GameState.enter(0, 0)
	_start_fight()

func _start_fight() -> void:
	var node := GameState.current_node()
	var w := Database.get_wizard(GameState.wizard_id)
	var player := Combatant.new()
	player.display_name = w.pname
	player.max_hp = GameState.player_max_hp
	player.hp = GameState.player_hp

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
	_build_player_widget(w)
	_build_fit_strip()
	_prev_enemy_hp = []
	for e in cm.enemies:
		_prev_enemy_hp.append(e.hp)
	_prev_player_hp = cm.player.hp
	_prev_swag = cm.swag
	_prev_state = cm.state
	_refresh()

# --- player widget (left, persistent) ------------------------------------

func _build_player_widget(w: WizardData) -> void:
	var nm := Label.new()
	nm.text = w.pname
	nm.position = Vector2(20, 150)
	nm.size = Vector2(280, 26)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", w.accent.lightened(0.32))
	add_child(nm)

	_player_sprite = TextureRect.new()
	_player_sprite.texture = SpriteBank.wizard_texture(w.id, 1)
	_player_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_player_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_sprite.position = Vector2(90, 180)
	_player_sprite.size = Vector2(150, 150)
	_player_home = _player_sprite.position
	add_child(_player_sprite)
	_idle_bob(_player_sprite, 0.0, 7.0)

	_goons_box = Control.new()
	_goons_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_goons_box)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.show_percentage = false
	_player_hp_bar.max_value = cm.player.max_hp
	_player_hp_bar.position = Vector2(45, 336)
	_player_hp_bar.size = Vector2(240, 22)
	_style_bar(_player_hp_bar, C_HP, C_HP_TRACK)
	_player_hp_text = Label.new()
	_player_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_player_hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_hp_text.add_theme_font_size_override("font_size", 15)
	_player_hp_bar.add_child(_player_hp_text)
	add_child(_player_hp_bar)

	_player_status_box = HBoxContainer.new()
	_player_status_box.position = Vector2(20, 360)
	_player_status_box.custom_minimum_size = Vector2(280, 24)
	_player_status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_player_status_box.add_theme_constant_override("separation", 8)
	_player_status_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_status_box)

func _build_fit_strip() -> void:
	var x := 16.0
	for p in GameState.equipped_pieces():
		var tex := SpriteBank.item_texture(p.id)
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(x, 64)
		tr.size = Vector2(24, 24)
		add_child(tr)
		x += 27

# --- summoned goons ------------------------------------------------------

func _goon_pos(i: int) -> Vector2:
	return Vector2(GOON_X0 + i * GOON_STEP, GOON_Y)

## Keep the visible goon row in sync with the player's Undead stacks: spawn new
## ones with a pop, and send consumed ones (e.g. Sacrifice Strike) lunging at the
## enemies before they poof — so a summon reads as bodies on the field.
func _sync_goons() -> void:
	if _goons_box == null:
		return
	var want: int = cm.player.status(&"undead")
	var have: int = _goon_sprites.size()
	if want > have:
		for i in range(have, want):
			_add_goon(i)
	elif want < have:
		var doomed: Array = _goon_sprites.slice(want, have)
		_goon_sprites = _goon_sprites.slice(0, want)
		for g in doomed:
			_consume_goon(g)

func _add_goon(i: int) -> void:
	var g := TextureRect.new()
	g.texture = SpriteBank.texture(&"goon")
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size = Vector2(GOON_SIZE, GOON_SIZE)
	g.position = _goon_pos(i)
	g.pivot_offset = Vector2(GOON_SIZE * 0.5, GOON_SIZE * 0.5)
	g.scale = Vector2(0.1, 0.1)
	_goons_box.add_child(g)
	_goon_sprites.append(g)
	# stagger each goon's idle bob so a freshly-raised squad isn't in lockstep
	var delay := (i % 3) * 0.3
	var tw := create_tween()
	tw.tween_property(g, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if is_instance_valid(g):
			_idle_bob(g, delay, 4.0))

func _consume_goon(g) -> void:
	if not is_instance_valid(g):
		return
	var home_x: float = g.position.x
	var tw := create_tween()
	tw.tween_property(g, "position:x", home_x + 72, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(g, "modulate", Color(1.9, 1.9, 1.9), 0.14)
	tw.tween_callback(func():
		if not is_instance_valid(g):
			return
		var c: Vector2 = g.position + Vector2(GOON_SIZE * 0.5, GOON_SIZE * 0.5)
		_death_poof(c)
		_hit_spark(c)
		g.queue_free())

# --- rendering -----------------------------------------------------------

func _refresh() -> void:
	if cm == null:
		return
	# After a winning blow the combat_ended signal swaps the scene out; a trailing
	# `changed` emission must not run the animation helpers (they need get_tree()).
	if not is_inside_tree():
		return
	var over := cm.state == CombatManager.State.WIN or cm.state == CombatManager.State.LOSE
	_turn_banner.text = "THEIR TURN" if cm.state == CombatManager.State.ENEMY_TURN else "TURN %d" % cm.turn
	_gold.text = "💰 %d" % GameState.gold
	_log_line.text = cm.log_lines[-1] if not cm.log_lines.is_empty() else ""

	if _player_hp_bar != null:
		_player_hp_bar.value = cm.player.hp
		_player_hp_text.text = "%d / %d" % [cm.player.hp, cm.player.max_hp]
		_fill_status(_player_status_box, cm.player)

	_energy.text = "⚡ Energy  %d / %d" % [cm.energy, cm.max_energy]
	_swag_value.text = "✦ AURA  %d   (+%d/turn)" % [cm.swag, cm.drip]
	_swag_bar.value = min(cm.swag, _swag_bar.max_value)
	_thresholds.text = _threshold_text()
	_end_turn.disabled = over or cm.state != CombatManager.State.PLAYER_TURN

	_rebuild_enemies(over)
	_rebuild_hand(over)
	_sync_goons()
	_emit_popups()
	_banter()

func _rebuild_enemies(over: bool) -> void:
	for c in _enemies_box.get_children():
		c.queue_free()
	_enemy_widgets = []
	_enemy_sprites = []
	for i in cm.enemies.size():
		var pair := _make_enemy_widget(cm.enemies[i], i, over)
		_enemy_widgets.append(pair[0])
		_enemy_sprites.append(pair[1])
		_enemies_box.add_child(pair[0])

func _make_enemy_widget(e: Combatant, index: int, over: bool) -> Array:
	var dead := e.is_dead()
	var targeted := (not over) and (cm.target_index == index) and not dead
	var w := Control.new()
	w.custom_minimum_size = Vector2(150, 210)
	if not dead and not over:
		w.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				cm.set_target(index))

	# intent chip above the monster (icon + amount)
	var intent := HBoxContainer.new()
	intent.position = Vector2(0, 0)
	intent.custom_minimum_size = Vector2(150, 22)
	intent.alignment = BoxContainer.ALIGNMENT_CENTER
	intent.add_theme_constant_override("separation", 4)
	intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not (over or dead):
		_fill_intent(intent, e)
	w.add_child(intent)

	var nm := Label.new()
	nm.text = e.display_name
	nm.position = Vector2(0, 26)
	nm.size = Vector2(150, 18)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD
	nm.add_theme_font_size_override("font_size", 14)
	w.add_child(nm)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = e.max_hp
	bar.value = e.hp
	bar.position = Vector2(14, 50)
	bar.size = Vector2(122, 18)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_bar(bar, C_HP, C_HP_TRACK)
	var hptext := Label.new()
	hptext.text = "%d / %d" % [e.hp, e.max_hp]
	hptext.set_anchors_preset(Control.PRESET_FULL_RECT)
	hptext.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hptext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hptext.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hptext.add_theme_font_size_override("font_size", 12)
	bar.add_child(hptext)
	w.add_child(bar)

	var stbox := HBoxContainer.new()
	stbox.position = Vector2(0, 70)
	stbox.custom_minimum_size = Vector2(150, 22)
	stbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stbox.add_theme_constant_override("separation", 6)
	stbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.add_child(stbox)
	_fill_status(stbox, e)

	# ground shadow + monster sprite
	var shadow := Panel.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0, 0, 0, 0.3)
	ss.set_corner_radius_all(14)
	shadow.add_theme_stylebox_override("panel", ss)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.position = Vector2(40, 188)
	shadow.size = Vector2(70, 12)
	w.add_child(shadow)

	var sprite := TextureRect.new()
	var tex: Texture2D = null if dead else SpriteBank.texture(e.data.id)
	sprite.texture = tex
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.position = Vector2(33, 100)
	sprite.size = Vector2(84, 90)
	if dead:
		var skull := Label.new()
		skull.text = "☠"
		skull.set_anchors_preset(Control.PRESET_FULL_RECT)
		skull.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skull.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		skull.add_theme_font_size_override("font_size", 40)
		sprite.add_child(skull)
	w.add_child(sprite)
	if not dead:
		_idle_bob(sprite, index * 0.3, 5.0)

	if targeted:
		var arrow := Label.new()
		arrow.text = "▼"
		arrow.position = Vector2(0, 90)
		arrow.size = Vector2(150, 18)
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.add_theme_color_override("font_color", C_TARGET)
		w.add_child(arrow)
	return [w, sprite]

func _rebuild_hand(over: bool) -> void:
	for child in _hand.get_children():
		child.queue_free()
	if over:
		return
	for card in cm.hand:
		var btn := CardView.build(card, cm.can_play(card), Callable())
		if cm.can_play(card):
			btn.pressed.connect(_play_card.bind(card, btn))
		_hand.add_child(btn)

func _play_card(card: CardData, btn: Button) -> void:
	if cm.state != CombatManager.State.PLAYER_TURN or not cm.can_play(card):
		return
	var gpos := btn.global_position
	_hand.remove_child(btn)
	_popups.add_child(btn)
	btn.global_position = gpos
	btn.disabled = true
	btn.pivot_offset = btn.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(btn, "position:y", gpos.y - 140, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "rotation", deg_to_rad(5), 0.3)
	tw.chain().tween_property(btn, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(btn.queue_free)

	var is_attack := card.type == "Attack"
	var blk0 := cm.player.block
	var ti := cm.target_index
	Audio.play("card")
	cm.play_card(card)
	if is_attack:
		_lunge(_player_sprite)
		_shoot_projectile(Vector2(210, 248), _enemy_center(ti), SpriteBank.icon_texture(CardView.icon_for(card)))
	if cm.last_crit:
		_crit_popup(_enemy_center(ti))
		_shake(10.0)
		Audio.play("crit", -3.0)
	if cm.player.block > blk0:
		_block_flash()
		Audio.play("block")

# --- animations ----------------------------------------------------------

func _idle_bob(node: Control, delay: float, amp: float) -> void:
	var y := node.position.y
	var tw := node.create_tween().set_loops()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "position:y", y - amp, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _add_sparkles() -> void:
	var p := CPUParticles2D.new()
	p.amount = 44
	p.lifetime = 8.0
	p.preprocess = 5.0
	p.position = Vector2(576, 656)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(600, 8)
	p.direction = Vector2(0, -1)
	p.spread = 22.0
	p.gravity = Vector2(0, -5)
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 24.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.6, 0.88, 0.55)
	add_child(p)
	move_child(p, 1)

func _add_twinkles() -> void:
	var i := 0
	for pos in [[118, 70], [300, 52], [520, 58], [700, 46], [822, 86], [200, 104], [640, 96], [410, 80]]:
		var c := ColorRect.new()
		c.color = Color(1, 1, 1)
		c.size = Vector2(3, 3)
		c.position = Vector2(pos[0], pos[1])
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		move_child(c, 2)
		var tw := c.create_tween().set_loops()
		tw.tween_interval(0.3 * i)
		tw.tween_property(c, "modulate:a", 0.15, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
		i += 1

func _shoot_projectile(from: Vector2, to: Vector2, tex: Texture2D) -> void:
	if tex == null:
		return
	var p := TextureRect.new()
	p.texture = tex
	p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(30, 30)
	p.pivot_offset = Vector2(15, 15)
	p.position = from - Vector2(15, 15)
	_popups.add_child(p)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "position", to - Vector2(15, 15), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(p, "rotation", deg_to_rad(420), 0.16)
	tw.chain().tween_callback(p.queue_free)

func _crit_popup(pos: Vector2) -> void:
	var l := Label.new()
	l.text = "CRIT!"
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", C_GOLD)
	l.position = pos - Vector2(70, 70)
	l.pivot_offset = Vector2(70, 30)
	l.scale = Vector2(0.4, 0.4)
	_popups.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)

func _hit_spark(pos: Vector2) -> void:
	var tr := TextureRect.new()
	tr.texture = SpriteBank.icon_texture(&"burst")
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size = Vector2(52, 52)
	tr.pivot_offset = Vector2(26, 26)
	tr.position = pos - Vector2(26, 26)
	tr.modulate = Color(2.2, 2.2, 2.2, 1.0)
	tr.scale = Vector2(0.5, 0.5)
	_popups.add_child(tr)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(tr, "scale", Vector2(1.5, 1.5), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(tr, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(tr.queue_free)

func _death_poof(pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = true
	p.amount = 18
	p.lifetime = 0.6
	p.explosiveness = 0.92
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 95.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.82, 0.80, 0.86, 0.85)
	_popups.add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 5:
		tw.tween_property(self, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.05)

func _lunge(node: Control) -> void:
	if node == null:
		return
	var home := _player_home
	var tw := create_tween()
	tw.tween_property(node, "position:x", home.x + 34, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position:x", home.x, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _punch(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	var sz := node.size if node.size != Vector2.ZERO else node.custom_minimum_size
	node.pivot_offset = sz * 0.5
	node.scale = Vector2(1.18, 0.85)
	node.modulate = Color(1.7, 1.7, 1.7)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate", Color.WHITE, 0.24)

func _block_flash() -> void:
	_float_text(Vector2(150, 250), "🛡", Color(0.45, 0.7, 1.0))
	var fl := ColorRect.new()
	fl.color = Color(0.3, 0.55, 1.0, 0.0)
	fl.set_anchors_preset(Control.PRESET_FULL_RECT)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popups.add_child(fl)
	var tw := create_tween()
	tw.tween_property(fl, "color:a", 0.12, 0.05)
	tw.tween_property(fl, "color:a", 0.0, 0.25)
	tw.tween_callback(fl.queue_free)

func _emit_popups() -> void:
	if _popups == null:
		return
	var max_dmg := 0
	var enemy_hit := false
	var any_death := false
	for i in cm.enemies.size():
		if i < _prev_enemy_hp.size():
			var d: int = int(_prev_enemy_hp[i]) - cm.enemies[i].hp
			if d > 0:
				max_dmg = max(max_dmg, d)
				enemy_hit = true
				_float_text(_enemy_center(i), "-%d" % d, C_HP.lightened(0.25))
				_hit_spark(_enemy_center(i))
				if i < _enemy_sprites.size() and is_instance_valid(_enemy_sprites[i]):
					_punch(_enemy_sprites[i])
				if int(_prev_enemy_hp[i]) > 0 and cm.enemies[i].hp <= 0:
					_death_poof(_enemy_center(i))
					any_death = true
	if enemy_hit:
		Audio.play("hit")
	if any_death:
		Audio.play("death", -3.0)
	if _prev_player_hp >= 0 and cm.player.hp < _prev_player_hp:
		max_dmg = max(max_dmg, _prev_player_hp - cm.player.hp)
		_float_text(Vector2(150, 250), "-%d" % (_prev_player_hp - cm.player.hp), Color(1, 0.5, 0.4))
		_hurt_flash()
		_punch(_player_sprite)
		Audio.play("hurt")
	if max_dmg >= 14:
		_shake(7.0)
	_prev_enemy_hp = []
	for e in cm.enemies:
		_prev_enemy_hp.append(e.hp)
	_prev_player_hp = cm.player.hp

func _banter() -> void:
	if _popups == null:
		return
	for thr in [12, 18]:
		if _prev_swag < thr and cm.swag >= thr:
			_say_bubble(Vector2(150, 130), PLAYER_LINES[randi() % PLAYER_LINES.size()], C_SWAG)
			Audio.play("aura", -5.0)
			break
	_prev_swag = cm.swag
	if cm.state == CombatManager.State.ENEMY_TURN and _prev_state != CombatManager.State.ENEMY_TURN:
		var alive := cm.living_enemies()
		if not alive.is_empty():
			var idx: int = cm.enemies.find(alive[randi() % alive.size()])
			_say_bubble(_enemy_center(idx) + Vector2(0, -120), ENEMY_TAUNTS[randi() % ENEMY_TAUNTS.size()], C_INTENT)
	_prev_state = cm.state

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

func _enemy_center(i: int) -> Vector2:
	var n := cm.enemies.size()
	var wper := 150.0 + 18.0
	var total := n * 150.0 + (n - 1) * 18.0
	var start_x := 432.0 + (700.0 - total) * 0.5
	return Vector2(start_x + i * wper + 75.0, 240.0)

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

func _say_bubble(pos: Vector2, text: String, accent: Color) -> void:
	var w := 206.0
	var h := 46.0
	var c := Control.new()
	c.position = pos - Vector2(w * 0.5, 0)
	c.size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(w * 0.5 - 9, h - 2), Vector2(w * 0.5 + 9, h - 2), Vector2(w * 0.5, h + 13)])
	tail.color = Color(0.96, 0.95, 0.98)
	c.add_child(tail)
	var panel := Panel.new()
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.95, 0.98)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = accent
	panel.add_theme_stylebox_override("panel", sb)
	c.add_child(panel)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.14, 0.1, 0.17))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 8
	lbl.offset_right = -8
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)
	_popups.add_child(c)
	c.pivot_offset = Vector2(w * 0.5, h)
	c.scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.5)
	tw.tween_property(c, "modulate:a", 0.0, 0.3)
	tw.tween_callback(c.queue_free)

# --- text helpers --------------------------------------------------------

func _fill_status(box: HBoxContainer, c: Combatant) -> void:
	if box == null:
		return
	for ch in box.get_children():
		ch.queue_free()
	if c.block > 0:
		box.add_child(_status_chip(&"block", c.block))
	for k in c.statuses:
		if c.statuses[k] > 0:
			box.add_child(_status_chip(k, c.statuses[k]))

func _status_chip(id: StringName, value: int) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 1)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_name: String = STATUS_ICON.get(id, "")
	if icon_name != "":
		var tr := TextureRect.new()
		tr.texture = SpriteBank.icon_texture(icon_name)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.custom_minimum_size = Vector2(18, 18)
		h.add_child(tr)
	var lbl := Label.new()
	lbl.text = str(value)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(lbl)
	return h

func _status_text(c: Combatant) -> String:
	var parts: Array[String] = []
	if c.block > 0:
		parts.append("🛡 %d" % c.block)
	for k in c.statuses:
		if c.statuses[k] > 0:
			parts.append("%s %d" % [STATUS_NAME.get(k, String(k).capitalize()), c.statuses[k]])
	return "  ".join(parts)

func _fill_intent(box: HBoxContainer, e: Combatant) -> void:
	var it := cm.peek_intent(e)
	if it.is_empty():
		return
	var icon := ""
	var text := ""
	var col := C_INTENT
	match String(it.get("op", "")):
		"attack":
			var amount := int(round(int(it.get("amount", 0)) * cm.enemy_dmg_scale))
			icon = "sword"
			text = str(amount)
			col = Color(0.95, 0.5, 0.45)
		"block":
			icon = "shield"
			text = str(int(it.get("amount", 0)))
			col = Color(0.55, 0.78, 0.95)
		"apply_status":
			var sid := StringName(it.get("status", &""))
			icon = STATUS_ICON.get(sid, "cooked")
			text = str(int(it.get("amount", 0)))
			col = Color(0.95, 0.7, 0.4)
		"buff":
			icon = "rizz"
			text = "+%d" % int(it.get("amount", 0))
			col = Color(0.95, 0.6, 0.85)
		"drain_swag":
			icon = "star"
			text = "−%d" % int(it.get("amount", 0))
			col = Color(0.95, 0.85, 0.45)
		_:
			text = "?"
	if icon != "":
		var tr := TextureRect.new()
		tr.texture = SpriteBank.icon_texture(icon)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.custom_minimum_size = Vector2(20, 20)
		box.add_child(tr)
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", col)
	box.add_child(lbl)

func _threshold_text() -> String:
	var d := func(n): return "●" if cm.swag >= n else "○"
	return "%s ≥6 +2dmg    %s ≥12 +draw    %s ≥18 pierce" % [d.call(6), d.call(12), d.call(18)]

# --- styles --------------------------------------------------------------

func _panel_box(bg: Color, border: Color, bw := 2) -> StyleBoxFlat:
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
	Audio.play("win" if victory else "lose", -2.0)
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
	_result_label.text = "BIG L 💀"
	_result_label.add_theme_color_override("font_color", C_HP)
	_result_panel.visible = true
	_refresh()

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
