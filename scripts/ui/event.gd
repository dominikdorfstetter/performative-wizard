extends Control
## Random narrative event with risk/reward choices. Keeps the run varied.

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	NodeUI.background(self)
	match _rng.randi_range(0, 5):
		0: _mannequin()
		1: _merchant()
		2: _fountain()
		3: _wardrobe()
		4: _therapist()
		_: _bargain()

# --- events --------------------------------------------------------------

func _mannequin() -> void:
	NodeUI.title(self, "Sus Mannequin", Color(0.4, 0.7, 0.9), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "it's serving a look and lowkey staring back. unsettling fr.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Try the fit on", "50%: cop an artefact.\n50%: it bites you for 8.", Color(0.85, 0.4, 0.95), _mannequin_try, true, "", SpriteBank.icon_texture(&"star")))
	h.add_child(NodeUI.choice("Nope, weird", "dip. some risks ain't it.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

func _mannequin_try() -> void:
	if _rng.randf() < 0.5:
		var aid := _unowned()
		if aid != &"":
			GameState.add_artifact(aid)
			var a := Database.get_artifact(aid)
			_outcome("It fits like a dream! Gained %s." % (a.title if a != null else "an artefact"))
		else:
			GameState.gold += 30
			_outcome("Nothing new to wear — you pocket 30 gold instead.")
	else:
		_hurt(8)
		_outcome("The mannequin BIT you! Lost 8 HP.")

func _merchant() -> void:
	NodeUI.title(self, "Sketchy Plug", Color(0.95, 0.8, 0.3), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "a hooded figure's got mystery cards. trust the process?")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Cop one (20g)", "pay 20 gold for a random card.", NodeUI.GOLD, _merchant_buy, GameState.gold >= 20, "", SpriteBank.icon_texture(&"dice")))
	h.add_child(NodeUI.choice("Keep it pushing", "hold onto your coin.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"boot")))

func _merchant_buy() -> void:
	GameState.gold -= 20
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := GameState.unlocked_cards(w.reward_pool)
	pool.shuffle()
	if pool.is_empty():
		pool = [&"ember"]
	GameState.deck.append(pool[0])
	var c := Database.get_card(pool[0])
	_outcome("You bought a %s!" % (c.title if c != null else "mystery card"))

# --- build-shaping events (deterministic choices, not coin flips) ----------

func _therapist() -> void:
	NodeUI.title(self, "The Therapist", Color(0.55, 0.82, 0.6), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "\"let's unpack that deck, bestie.\" cut one card from your deck for good.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Do the work", "remove a card from your deck.", Color(0.5, 0.85, 0.6), _therapist_menu, GameState.deck.size() > 1, "", SpriteBank.icon_texture(&"scissors")))
	h.add_child(NodeUI.choice("I'm fine actually", "skip it, pocket 20 gold (copay refund).", NodeUI.GOLD, _therapist_skip, true, "", SpriteBank.icon_texture(&"coin")))

func _therapist_skip() -> void:
	Audio.play("coin", -5.0)
	GameState.gold += 20
	_outcome("You ghost the session and pocket 20 gold. growth!")

func _therapist_menu() -> void:
	for c in get_children():
		if not (c is ColorRect or c is TextureRect):
			c.queue_free()
	NodeUI.title(self, "release which card?", Color(0.5, 0.85, 0.6))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(80, 160)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for id in GameState.deck:
		var card := Database.get_card(id)
		if card != null:
			var b := NodeUI.small_button(card.title, _therapist_remove.bind(id))
			b.custom_minimum_size = Vector2(150, 46)
			grid.add_child(b)

func _therapist_remove(id: StringName) -> void:
	GameState.deck.erase(id)
	var c := Database.get_card(id)
	_outcome("Released %s. you feel lighter." % (c.title if c != null else "it"))

func _bargain() -> void:
	NodeUI.title(self, "Cursed Bargain", Color(0.82, 0.4, 0.5), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "a velvet box hums. \"trade a little vitality for a little power?\"")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Pay in vitality", "lose 6 MAX HP, gain an artefact.", Color(0.85, 0.4, 0.5), _bargain_take, GameState.player_max_hp > 24, "", SpriteBank.icon_texture(&"skull")))
	h.add_child(NodeUI.choice("Not worth it", "keep your health, walk away.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

func _bargain_take() -> void:
	var aid := _unowned()
	if aid != &"":
		GameState.player_max_hp -= 6
		GameState.player_hp = min(GameState.player_hp, GameState.player_max_hp)
		GameState.add_artifact(aid)
		var a := Database.get_artifact(aid)
		_outcome("You trade 6 MAX HP for %s. worth it?" % (a.title if a != null else "a relic"))
	else:
		GameState.gold += 40
		_outcome("Nothing answers the call — you find 40 gold instead.")

func _fountain() -> void:
	NodeUI.title(self, "Wishing Fountain (real?)", Color(0.4, 0.8, 0.95), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "suspiciously clean water, absolutely loaded with old coins.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Take a sip", "heal 16 HP. hydration check.", Color(0.4, 0.85, 0.55), _fountain_drink, true, "", SpriteBank.icon_texture(&"drop")))
	h.add_child(NodeUI.choice("Toss 15g, make a wish", "manifest an artefact.", Color(0.85, 0.4, 0.95), _fountain_toss, GameState.gold >= 15, "", SpriteBank.icon_texture(&"coin")))

func _fountain_drink() -> void:
	Audio.play("heal", -4.0)
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 16)
	_outcome("Refreshing! Healed 16 HP.")

func _fountain_toss() -> void:
	GameState.gold -= 15
	var aid := _unowned()
	if aid != &"":
		GameState.add_artifact(aid)
		var a := Database.get_artifact(aid)
		_outcome("The fountain grants you %s!" % (a.title if a != null else "a relic"))
	else:
		GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 10)
		_outcome("No artefacts left — the water heals you 10 instead.")

func _wardrobe() -> void:
	NodeUI.title(self, "Abandoned Wardrobe", Color(0.9, 0.7, 0.4), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "dusty, ornate, lowkey humming. rummage or nah?")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Dig through it", "60%: find 30 gold.\n40%: moths bite you for 7.", Color(0.9, 0.7, 0.4), _wardrobe_rummage, true, "", SpriteBank.icon_texture(&"torch")))
	h.add_child(NodeUI.choice("Hard pass", "best not to disturb it.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

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
	NodeUI.title(self, "Event", Color(0.4, 0.7, 0.9), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, text, 230)
	var cont := NodeUI.small_button("Continue", _to_map, Color(0.4, 0.85, 0.55))
	cont.position = Vector2(486, 520)
	add_child(cont)

func _hurt(n: int) -> void:
	Audio.play("hurt", -4.0)
	GameState.player_hp = max(1, GameState.player_hp - n)

func _unowned() -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid) and GameState.artifact_unlocked(aid):
			return aid
	return &""

func _to_map() -> void:
	Fader.change_scene("res://scenes/map/map.tscn")
