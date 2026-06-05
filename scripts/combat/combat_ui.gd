extends Control
## Interactive combat. Reads the active wizard/deck/enemy from GameState, renders the
## fight, routes clicks into the CombatManager, and on victory hands off to the reward
## screen (persisting HP between fights).

# palette
const C_BG_PANEL := Color(0.13, 0.11, 0.17)
const C_PANEL_BORDER := Color(0.28, 0.24, 0.36)
const C_HP := Color(0.85, 0.27, 0.24)
const C_HP_TRACK := Color(0.22, 0.12, 0.13)
const C_SWAG := Color(1.0, 0.31, 0.70)
const C_SWAG_TRACK := Color(0.26, 0.10, 0.20)
const C_GOLD := Color(1.0, 0.82, 0.29)
const C_INTENT := Color(1.0, 0.62, 0.36)
const C_DIM := Color(0.62, 0.60, 0.68)

var cm: CombatManager

@onready var _turn_banner: Label = $TurnBanner
@onready var _enemy_sprite: Label = $EnemyPanel/EnemySprite
@onready var _enemy_name: Label = $EnemyPanel/EnemyName
@onready var _enemy_hp_bar: ProgressBar = $EnemyPanel/EnemyHPBar
@onready var _enemy_hp_text: Label = $EnemyPanel/EnemyHPBar/EnemyHPText
@onready var _enemy_status: Label = $EnemyPanel/EnemyStatus
@onready var _intent_badge: Panel = $EnemyPanel/IntentBadge
@onready var _intent_text: Label = $EnemyPanel/IntentBadge/IntentText
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
	# Allow running combat.tscn standalone (e.g. headless smoke test).
	if GameState.deck.is_empty():
		GameState.start_run(&"fire")
		GameState.finalize_loadout()
	_start_fight()

func _style_chrome() -> void:
	for p in [$EnemyPanel, $PlayerPanel, $ResourcePanel, $LogPanel, _result_panel, _intent_badge]:
		p.add_theme_stylebox_override("panel", _panel_box(C_BG_PANEL, C_PANEL_BORDER))
	_intent_badge.add_theme_stylebox_override("panel", _panel_box(Color(0.22, 0.13, 0.08), C_INTENT))
	_style_bar(_enemy_hp_bar, C_HP, C_HP_TRACK)
	_style_bar(_player_hp_bar, C_HP, C_HP_TRACK)
	_style_bar(_swag_bar, C_SWAG, C_SWAG_TRACK)
	_swag_value.add_theme_color_override("font_color", C_SWAG)
	_energy.add_theme_color_override("font_color", C_GOLD)
	_intent_text.add_theme_color_override("font_color", C_INTENT)
	_end_turn.add_theme_stylebox_override("normal", _panel_box(Color(0.16, 0.36, 0.22), Color(0.36, 0.70, 0.45)))
	_end_turn.add_theme_stylebox_override("hover", _panel_box(Color(0.20, 0.46, 0.28), Color(0.45, 0.85, 0.55)))
	_end_turn.add_theme_stylebox_override("pressed", _panel_box(Color(0.14, 0.30, 0.19), Color(0.36, 0.70, 0.45)))

func _start_fight() -> void:
	var w := Database.get_wizard(GameState.wizard_id)
	var player := Combatant.new()
	player.display_name = w.title
	player.max_hp = GameState.player_max_hp
	player.hp = GameState.player_hp

	var deck: Array[CardData] = []
	for id in GameState.deck:
		var c := Database.get_card(id)
		if c != null:
			deck.append(c)

	var enemy := Database.get_enemy(GameState.current_enemy())
	_enemy_sprite.text = enemy.emoji
	_player_name.text = "%s  %s" % [w.title, w.emoji]
	_player_name.add_theme_color_override("font_color", w.accent.lightened(0.3))
	_player_hp_bar.max_value = player.max_hp

	cm = CombatManager.new()
	cm.changed.connect(_refresh)
	cm.combat_ended.connect(_on_combat_ended)
	cm.start_combat(player, enemy, deck, GameState.drip, false, GameState.passives)
	_enemy_hp_bar.max_value = cm.enemy.max_hp
	print("[Combat] fight %d: %s %d HP vs %s %d HP, deck=%d"
		% [GameState.fight_index + 1, w.title, player.hp, enemy.title, enemy.max_hp, deck.size()])
	_refresh()

# --- rendering -----------------------------------------------------------

func _refresh() -> void:
	if cm == null:
		return
	var over := cm.state == CombatManager.State.WIN or cm.state == CombatManager.State.LOSE

	_turn_banner.text = "ENEMY TURN" if cm.state == CombatManager.State.ENEMY_TURN else "TURN %d   ·   Fight %d / %d" % [cm.turn, GameState.fight_index + 1, GameState.RUN_ENEMIES.size()]

	_enemy_name.text = cm.enemy.display_name
	_enemy_hp_bar.value = cm.enemy.hp
	_enemy_hp_text.text = "%d / %d" % [cm.enemy.hp, cm.enemy.max_hp]
	_enemy_status.text = _status_text(cm.enemy)
	_intent_badge.visible = not over and cm.state == CombatManager.State.PLAYER_TURN
	_intent_text.text = _intent_text_for()

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

	_rebuild_hand(over)

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
	return "    ".join(parts)

func _intent_text_for() -> String:
	var it := cm.peek_intent()
	if it.is_empty():
		return ""
	var amount := int(it.get("amount", 0))
	match String(it.get("op", "")):
		"attack":
			return "⚔ %d" % amount
		"block":
			return "🛡 %d" % amount
		"apply_status":
			return "☠ %s %d" % [String(it.get("status", &"")).capitalize(), amount]
		"buff":
			return "↑ %s %d" % [String(it.get("status", &"")).capitalize(), amount]
	return "?"

func _threshold_text() -> String:
	var d := func(n): return "●" if cm.swag >= n else "○"
	return "%s ≥5 +2dmg    %s ≥10 +draw    %s ≥15 pierce" % [d.call(5), d.call(10), d.call(15)]

# --- style builders ------------------------------------------------------

func _panel_box(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
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
		GameState.player_hp = cm.player.hp           # carry damage to the next fight
		get_tree().change_scene_to_file("res://scenes/reward.tscn")
		return
	_result_label.text = "DEFEAT"
	_result_label.add_theme_color_override("font_color", C_HP)
	_result_panel.visible = true
	_refresh()

func _to_menu() -> void:
	GameState.message = "Defeated by the %s. Try again?" % cm.enemy.display_name
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
