extends Control
## Post-victory card reward. Offers 3 cards from the wizard's reward pool; the picked
## card joins the run deck. Then advances to the next fight (or ends the run).

@onready var _options: HBoxContainer = $Options

func _ready() -> void:
	$Background.color = Color(0.08, 0.06, 0.11)
	$Title.add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	$Subtitle.text = "HP %d / %d   ·   Deck size %d" % [GameState.player_hp, GameState.player_max_hp, GameState.deck.size()]

	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	for id in pool.slice(0, min(3, pool.size())):
		var card := Database.get_card(id)
		if card != null:
			_options.add_child(CardView.build(card, true, _take.bind(id)))

	$Skip.pressed.connect(_skip)

func _take(id: StringName) -> void:
	GameState.deck.append(id)
	_next()

func _skip() -> void:
	_next()

func _next() -> void:
	GameState.advance_fight()
	if GameState.run_complete():
		var msg := "✦ You cleared the gauntlet, you fabulous menace. ✦"
		if GameState.unlock_outfit(&"catwalk_heels"):
			msg += "\nUnlocked new drip: Catwalk Heels (Boots)!"
		GameState.message = msg
		get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/combat/combat.tscn")
