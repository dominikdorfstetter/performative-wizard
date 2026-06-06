extends Control
## Rest site: heal, or visit the tailor to remove (thin) a card from your deck.

func _ready() -> void:
	NodeUI.background(self)
	_menu()

func _menu() -> void:
	_clear()
	NodeUI.title(self, "🛋  Touch Grass", Color(0.4, 0.85, 0.55))
	NodeUI.sub(self, "HP %d/%d    ·    deck: %d cards" % [GameState.player_hp, GameState.player_max_hp, GameState.deck.size()])
	var heal := int(ceil(GameState.player_max_hp * 0.3))
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Log Off", "Heal %d HP. self-care era." % heal, Color(0.4, 0.85, 0.55), _heal.bind(heal), true, "💤"))
	h.add_child(NodeUI.choice("Get Snatched", "Yeet a card from your deck.", Color(0.4, 0.7, 0.9), _remove_menu, GameState.deck.size() > 1, "✂"))

func _heal(n: int) -> void:
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + n)
	_to_map()

func _remove_menu() -> void:
	_clear()
	NodeUI.title(self, "yeet which card?", Color(0.4, 0.7, 0.9))
	_deck_grid(_do_remove)
	var back := NodeUI.small_button("Cancel", _menu)
	back.position = Vector2(486, 604)
	add_child(back)

func _do_remove(id: StringName) -> void:
	GameState.deck.erase(id)
	_to_map()

func _deck_grid(on_pick: Callable) -> void:
	var grid := GridContainer.new()
	grid.columns = 7
	grid.position = Vector2(70, 140)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for id in GameState.deck:
		var card := Database.get_card(id)
		if card != null:
			grid.add_child(CardView.build(card, true, on_pick.bind(id)))

func _clear() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
