extends Control
## Random narrative event with risk/reward choices. Keeps the run varied.

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	NodeUI.background(self)
	match _rng.randi_range(0, 3):
		0: _mannequin()
		1: _merchant()
		2: _fountain()
		_: _wardrobe()

# --- events --------------------------------------------------------------

func _mannequin() -> void:
	NodeUI.title(self, "❓  A Suspicious Mannequin", Color(0.4, 0.7, 0.9))
	NodeUI.sub(self, "It wears a fabulous jacket and seems... aware of you.")
	var h := NodeUI.hbox(self, 280)
	h.add_child(NodeUI.choice("Try on the jacket", "50%: gain an artefact.\n50%: it bites you for 8.", Color(0.85, 0.4, 0.95), _mannequin_try))
	h.add_child(NodeUI.choice("Leave it be", "Walk away. Some risks aren't worth it.", Color(0.5, 0.6, 0.7), _leave))

func _mannequin_try() -> void:
	if _rng.randf() < 0.5:
		var aid := _unowned()
		if aid != &"":
			GameState.add_artifact(aid)
			_outcome("It fits like a dream! Gained %s." % Database.get_artifact(aid).title)
		else:
			GameState.gold += 30
			_outcome("Nothing new to wear — you pocket 30 gold instead.")
	else:
		_hurt(8)
		_outcome("The mannequin BIT you! Lost 8 HP.")

func _merchant() -> void:
	NodeUI.title(self, "❓  Travelling Merchant", Color(0.95, 0.8, 0.3))
	NodeUI.sub(self, "A hooded figure spreads out an array of mystery cards.")
	var h := NodeUI.hbox(self, 280)
	h.add_child(NodeUI.choice("Buy mystery card", "Pay 20 gold for a random card.", NodeUI.GOLD, _merchant_buy, GameState.gold >= 20))
	h.add_child(NodeUI.choice("Move along", "Keep your coin.", Color(0.5, 0.6, 0.7), _leave))

func _merchant_buy() -> void:
	GameState.gold -= 20
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	GameState.deck.append(pool[0])
	_outcome("You bought a %s!" % Database.get_card(pool[0]).title)

func _fountain() -> void:
	NodeUI.title(self, "❓  A Wishing Fountain", Color(0.4, 0.8, 0.95))
	NodeUI.sub(self, "Suspiciously clean water glints with old coins.")
	var h := NodeUI.hbox(self, 280)
	h.add_child(NodeUI.choice("Drink deeply", "Heal 16 HP.", Color(0.4, 0.85, 0.55), _fountain_drink))
	h.add_child(NodeUI.choice("Toss 15 gold", "Make a wish: gain an artefact.", Color(0.85, 0.4, 0.95), _fountain_toss, GameState.gold >= 15))

func _fountain_drink() -> void:
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 16)
	_outcome("Refreshing! Healed 16 HP.")

func _fountain_toss() -> void:
	GameState.gold -= 15
	var aid := _unowned()
	if aid != &"":
		GameState.add_artifact(aid)
		_outcome("The fountain grants you %s!" % Database.get_artifact(aid).title)
	else:
		GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 10)
		_outcome("No artefacts left — the water heals you 10 instead.")

func _wardrobe() -> void:
	NodeUI.title(self, "❓  An Abandoned Wardrobe", Color(0.9, 0.7, 0.4))
	NodeUI.sub(self, "Dusty, ornate, and faintly humming. Rummage inside?")
	var h := NodeUI.hbox(self, 280)
	h.add_child(NodeUI.choice("Rummage", "60%: find 30 gold.\n40%: a moth swarm bites you for 7.", Color(0.9, 0.7, 0.4), _wardrobe_rummage))
	h.add_child(NodeUI.choice("Close the doors", "Best not to disturb it.", Color(0.5, 0.6, 0.7), _leave))

func _wardrobe_rummage() -> void:
	if _rng.randf() < 0.6:
		GameState.gold += 30
		_outcome("Jackpot! Found 30 gold stuffed in a pocket.")
	else:
		_hurt(7)
		_outcome("Moths! They bite you for 7.")

# --- helpers -------------------------------------------------------------

func _leave() -> void:
	_outcome("You move on, none the worse.")

func _outcome(text: String) -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()
	NodeUI.title(self, "❓  Event", Color(0.4, 0.7, 0.9))
	NodeUI.sub(self, text, 230)
	var cont := NodeUI.small_button("Continue", _to_map, Color(0.4, 0.85, 0.55))
	cont.position = Vector2(486, 520)
	add_child(cont)

func _hurt(n: int) -> void:
	GameState.player_hp = max(1, GameState.player_hp - n)

func _unowned() -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid):
			return aid
	return &""

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
