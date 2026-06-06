extends Control
## Boutique: spend gold on cards, an artefact, or card removal.

const REMOVE_COST := 50

var _card_stock: Array = []      # [{id, price, sold}]
var _art_stock := {}             # {id, price, sold} or empty

func _ready() -> void:
	NodeUI.background(self)
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	for id in pool.slice(0, min(3, pool.size())):
		var c := Database.get_card(id)
		_card_stock.append({"id": id, "price": (70 if c.rarity == "Rare" else 40), "sold": false})
	var aid := _unowned()
	if aid != &"":
		_art_stock = {"id": aid, "price": 75, "sold": false}
	_build()

func _build() -> void:
	_clear()
	NodeUI.title(self, "🛒  The Plug", NodeUI.GOLD)
	NodeUI.sub(self, "💰 %d gold  ·  treat yourself" % GameState.gold)

	# cards for sale
	var row := HBoxContainer.new()
	row.position = Vector2(140, 160)
	row.size = Vector2(620, 230)
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	for i in _card_stock.size():
		row.add_child(_card_stall(i))

	# artefact for sale
	if not _art_stock.is_empty():
		var a := Database.get_artifact(_art_stock.id)
		var afford: bool = not _art_stock.sold and GameState.gold >= _art_stock.price
		var label := "SOLD" if _art_stock.sold else "%s\n\n💰 %d" % [a.description, _art_stock.price]
		var ab := NodeUI.choice(a.title, label, Color(0.85, 0.4, 0.95), _buy_artifact, afford, a.emoji)
		ab.position = Vector2(800, 150)
		add_child(ab)

	# services
	var remove := NodeUI.small_button("yeet a card (%dg)" % REMOVE_COST, _remove_menu, Color(0.4, 0.7, 0.9))
	remove.custom_minimum_size = Vector2(240, 44)
	remove.position = Vector2(830, 350)
	remove.disabled = GameState.gold < REMOVE_COST or GameState.deck.size() <= 1
	add_child(remove)

	var leave := NodeUI.small_button("dip ✌", _to_map, Color(0.4, 0.85, 0.55))
	leave.position = Vector2(486, 600)
	add_child(leave)

func _card_stall(i: int) -> Control:
	var item: Dictionary = _card_stock[i]
	var card := Database.get_card(item.id)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var afford: bool = not item.sold and GameState.gold >= item.price
	v.add_child(CardView.build(card, afford, _buy_card.bind(i)))
	var price := Label.new()
	price.text = "SOLD" if item.sold else "💰 %d" % item.price
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 16)
	price.add_theme_color_override("font_color", NodeUI.GOLD if afford else Color(0.6, 0.6, 0.66))
	v.add_child(price)
	return v

func _buy_card(i: int) -> void:
	var item: Dictionary = _card_stock[i]
	if item.sold or GameState.gold < item.price:
		return
	GameState.gold -= item.price
	GameState.deck.append(item.id)
	item.sold = true
	_build()

func _buy_artifact() -> void:
	if _art_stock.is_empty() or _art_stock.sold or GameState.gold < _art_stock.price:
		return
	GameState.gold -= _art_stock.price
	GameState.add_artifact(_art_stock.id)
	_art_stock.sold = true
	_build()

func _remove_menu() -> void:
	_clear()
	NodeUI.title(self, "Remove which card?  (%d gold)" % REMOVE_COST, Color(0.4, 0.7, 0.9))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.position = Vector2(70, 140)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for id in GameState.deck:
		var card := Database.get_card(id)
		if card != null:
			grid.add_child(CardView.build(card, true, _do_remove.bind(id)))
	var back := NodeUI.small_button("Cancel", _build)
	back.position = Vector2(486, 604)
	add_child(back)

func _do_remove(id: StringName) -> void:
	GameState.gold -= REMOVE_COST
	GameState.deck.erase(id)
	_build()

func _unowned() -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid):
			return aid
	return &""

func _clear() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
