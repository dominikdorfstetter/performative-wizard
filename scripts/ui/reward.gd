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
	Audio.play("coin", -4.0)
	(%Subtitle as Label).text = "+%d gold  (now %d)    ·    HP %d/%d    ·    Deck %d" % [
		gain, GameState.gold, GameState.player_hp, GameState.player_max_hp, GameState.deck.size()]

	# The Critic's review of the fight you just had — and a heads-up on what her
	# verdict did to the road ahead.
	if GameState.critic_last_rating != "":
		var quip := GameState.critic_quip(GameState.critic_last_rating)
		if GameState.pending_critic == "S":
			quip += "   " + Loc.t("→ a VIP room opens ahead. 👑")
		elif GameState.pending_critic == "C":
			quip += "   " + Loc.t("→ a heckler's waiting in your next fight. 🗣")
		(%Subtitle as Label).text += "\n" + Loc.t("👀 THE CRITIC:  ") + quip

	if node.get("type") == "Elite":
		var aid := _random_unowned_artifact()
		if aid != &"":
			GameState.add_artifact(aid)
			var a := Database.get_artifact(aid)
			(%Banner as Label).text = "🎒  you looted:  %s %s — %s" % [a.emoji, a.title, a.description]
			(%Banner as Label).add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))

	for id in GameState.reward_offer(3):
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
		if not GameState.has_artifact(aid) and GameState.artifact_unlocked(aid):
			return aid
	return &""

func _take(id: StringName) -> void:
	GameState.deck.append(id)
	_to_map()

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
