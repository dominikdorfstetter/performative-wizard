extends Control
## Post-victory reward. Awards gold (scaled by encounter difficulty), grants an artefact
## on Elite kills, and offers a card to add. Returns to the map.

@onready var _options: HBoxContainer = %Options

func _ready() -> void:
	NodeUI.gradient_bg(self)
	(%Title as Label).add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	(%Banner as Label).text = ""

	var node := GameState.current_node()
	var gain := GameState.combat_reward(node) + GameState.gold_income()
	GameState.gold += gain
	(%Subtitle as Label).text = "+%d gold  (now %d)    ·    HP %d/%d    ·    Deck %d" % [
		gain, GameState.gold, GameState.player_hp, GameState.player_max_hp, GameState.deck.size()]

	if node.get("type") == "Elite":
		var aid := _random_unowned_artifact()
		if aid != &"":
			GameState.add_artifact(aid)
			var a := Database.get_artifact(aid)
			(%Banner as Label).text = "🎒  you looted:  %s %s — %s" % [a.emoji, a.title, a.description]
			(%Banner as Label).add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))

	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	for id in pool.slice(0, min(3, pool.size())):
		var card := Database.get_card(id)
		if card != null:
			_options.add_child(_big_card(card, id))

	(%Skip as Button).pressed.connect(_to_map)

# scale cards up and box them so they spread across the screen instead of clustering
func _big_card(card: CardData, id: StringName) -> Control:
	var view := CardView.build(card, true, _take.bind(id))
	view.pivot_offset = Vector2(75, 100)
	view.scale = Vector2(1.45, 1.45)
	view.position = Vector2(34, 45)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(218, 290)
	holder.add_child(view)
	return holder

func _random_unowned_artifact() -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid):
			return aid
	return &""

func _take(id: StringName) -> void:
	GameState.deck.append(id)
	_to_map()

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
