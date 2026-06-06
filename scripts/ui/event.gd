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
	NodeUI.title(self, "❓  Sus Mannequin", Color(0.4, 0.7, 0.9))
	NodeUI.sub(self, "it's serving a look and lowkey staring back. unsettling fr.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Try the fit on", "50%: cop an artefact.\n50%: it bites you for 8.", Color(0.85, 0.4, 0.95), _mannequin_try, true, "🧥"))
	h.add_child(NodeUI.choice("Nope, weird", "dip. some risks ain't it.", Color(0.5, 0.6, 0.7), _leave, true, "🚪"))

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
	NodeUI.title(self, "❓  Sketchy Plug", Color(0.95, 0.8, 0.3))
	NodeUI.sub(self, "a hooded figure's got mystery cards. trust the process?")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Cop one (20g)", "pay 20 gold for a random card.", NodeUI.GOLD, _merchant_buy, GameState.gold >= 20, "🃏"))
	h.add_child(NodeUI.choice("Keep it pushing", "hold onto your coin.", Color(0.5, 0.6, 0.7), _leave, true, "🚶"))

func _merchant_buy() -> void:
	GameState.gold -= 20
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	GameState.deck.append(pool[0])
	_outcome("You bought a %s!" % Database.get_card(pool[0]).title)

func _fountain() -> void:
	NodeUI.title(self, "❓  Wishing Fountain (real?)", Color(0.4, 0.8, 0.95))
	NodeUI.sub(self, "suspiciously clean water, absolutely loaded with old coins.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Take a sip", "heal 16 HP. hydration check.", Color(0.4, 0.85, 0.55), _fountain_drink, true, "💧"))
	h.add_child(NodeUI.choice("Toss 15g, make a wish", "manifest an artefact.", Color(0.85, 0.4, 0.95), _fountain_toss, GameState.gold >= 15, "🪙"))

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
	NodeUI.title(self, "❓  Abandoned Wardrobe", Color(0.9, 0.7, 0.4))
	NodeUI.sub(self, "dusty, ornate, lowkey humming. rummage or nah?")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Dig through it", "60%: find 30 gold.\n40%: moths bite you for 7.", Color(0.9, 0.7, 0.4), _wardrobe_rummage, true, "🔦"))
	h.add_child(NodeUI.choice("Hard pass", "best not to disturb it.", Color(0.5, 0.6, 0.7), _leave, true, "🚪"))

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
