extends Control
## Random narrative event with risk/reward choices. Keeps the run varied.

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	NodeUI.background(self)
	match _rng.randi_range(0, 10):
		0: _mannequin()
		1: _merchant()
		2: _fountain()
		3: _wardrobe()
		4: _therapist()
		5: _bargain()
		6: _critic_cafe()
		7: _fit_check()
		8: _hype_man()
		9: _lost_found()
		_: _group_chat()

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
			Audio.play("buff", -4.0)
			_outcome_item("It fits like a dream!", aid)
		else:
			GameState.gold += 30
			_outcome("Nothing new to wear — you pocket 30 gold instead.")
	else:
		_hurt(8)
		_outcome("The mannequin BIT you! Lost 8 HP.")

func _merchant() -> void:
	NodeUI.title(self, "Sketchy Merch Stand", Color(0.95, 0.8, 0.3), SpriteBank.icon_texture(&"quest"))
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
	_outcome(Loc.t("You bought a %s!") % (Loc.t(c.title) if c != null else "?"))

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
	NodeUI.card_picker(self, GameState.deck, _therapist_remove)

func _therapist_remove(id: StringName) -> void:
	GameState.deck.erase(id)
	var c := Database.get_card(id)
	_outcome(Loc.t("Released %s. you feel lighter.") % (Loc.t(c.title) if c != null else "?"))

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
		Audio.play("buff", -4.0)
		_outcome_item("You trade 6 MAX HP. worth it?", aid)
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
		Audio.play("buff", -4.0)
		_outcome_item("The fountain grants your wish!", aid)
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

# --- the Critic, encountered (she IS the run — events finally touch her) ---

func _critic_cafe() -> void:
	NodeUI.title(self, "The Critic, Off Duty", Color(1.0, 0.42, 0.75), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "she's at a corner table, reviewing a matcha. she has DEFINITELY seen you.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Send over a matcha (15g)", "she pre-writes a rave. VIP treatment next fight.", NodeUI.GOLD, _cafe_bribe, GameState.gold >= 15, "", SpriteBank.icon_texture(&"coin")))
	h.add_child(NodeUI.choice("Roast her latte order", "50%: she's amused (VIP).\n50%: offended (heckler).", Color(0.95, 0.5, 0.4), _cafe_roast, true, "", SpriteBank.icon_texture(&"mic")))
	h.add_child(NodeUI.choice("Pretend you didn't see her", "eyes front. keep walking.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

func _cafe_bribe() -> void:
	GameState.gold -= 15
	GameState.pending_critic = "S"
	GameState.pending_freshness = 1.0
	Audio.play("buff", -4.0)
	_outcome("She sips. She nods, slowly. Your next fight is pre-reviewed: VIP room ahead.")

func _cafe_roast() -> void:
	if _rng.randf() < 0.5:
		GameState.pending_critic = "S"
		GameState.pending_freshness = 1.0
		_outcome("A beat. Then she LAUGHS. \"okay. that was good.\" VIP room ahead.")
	else:
		GameState.pending_critic = "C"
		GameState.pending_freshness = 1.0
		Audio.play("hurt", -6.0)
		_outcome("Her pen comes out. It's already writing. A heckler will attend your next fight.")

func _fit_check() -> void:
	NodeUI.title(self, "Fit Check Patrol", Color(0.85, 0.4, 0.95), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "two clipboard interns from the Critic's office. they're rating fits today.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Strike a pose", "your equipped drip decides the rating.", Color(0.85, 0.4, 0.95), _fit_pose, true, "", SpriteBank.icon_texture(&"star")))
	h.add_child(NodeUI.choice("Decline the cameras", "you owe interns nothing.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

func _fit_pose() -> void:
	if GameState.preview_drip() >= 3:
		Audio.play("coin", -5.0)
		GameState.gold += 25
		_outcome("The fit is RATED. 25 gold appearance fee, effective immediately.")
	else:
		GameState.gold += 5
		_outcome("\"...mid,\" they write, handing you 5 pity gold. the wardrobe remembers this.")

# --- flavour + economy events ----------------------------------------------

func _hype_man() -> void:
	NodeUI.title(self, "Freelance Hype Man", Color(0.95, 0.8, 0.3), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "a guy with a speaker offers to gas you up. rates negotiable.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Hire him (25g)", "+5 MAX HP. confidence is structural.", NodeUI.GOLD, _hype_hire, GameState.gold >= 25, "", SpriteBank.icon_texture(&"mic")))
	h.add_child(NodeUI.choice("Dap him up and dip", "the free sample: heal 6 HP.", Color(0.4, 0.85, 0.55), _hype_free, true, "", SpriteBank.icon_texture(&"boot")))

func _hype_hire() -> void:
	GameState.gold -= 25
	GameState.player_max_hp += 5
	GameState.player_hp += 5
	Audio.play("buff", -4.0)
	_outcome("He announces you EVERYWHERE you go now. +5 MAX HP.")

func _hype_free() -> void:
	Audio.play("heal", -4.0)
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 6)
	_outcome("One (1) free compliment. Surprisingly effective — healed 6 HP.")

func _lost_found() -> void:
	NodeUI.title(self, "Lost & Found Bin", Color(0.9, 0.7, 0.4), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "backstage at a venue. finders keepers is the law of the land here.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Dig", "50%: 25 gold.\n30%: someone's card.\n20%: a mousetrap (6 HP).", Color(0.9, 0.7, 0.4), _lost_dig, true, "", SpriteBank.icon_texture(&"dice")))
	h.add_child(NodeUI.choice("Too sus", "what's lost can stay lost.", Color(0.5, 0.6, 0.7), _leave, true, "", SpriteBank.icon_texture(&"door")))

func _lost_dig() -> void:
	var roll := _rng.randf()
	if roll < 0.5:
		Audio.play("coin", -5.0)
		GameState.gold += 25
		_outcome("25 gold, loose, at the bottom. the venue owes you nothing now.")
	elif roll < 0.8:
		var w := Database.get_wizard(GameState.wizard_id)
		var pool := GameState.unlocked_cards(w.reward_pool)
		pool.shuffle()
		if pool.is_empty():
			pool = [&"ember"]
		GameState.deck.append(pool[0])
		var c := Database.get_card(pool[0])
		_outcome(Loc.t("Someone lost a %s. tragic. it's yours now.") % (Loc.t(c.title) if c != null else "?"))
	else:
		_hurt(6)
		_outcome("A mousetrap. For your protection, apparently. Lost 6 HP.")

func _group_chat() -> void:
	NodeUI.title(self, "The Group Chat", Color(0.4, 0.8, 0.95), SpriteBank.icon_texture(&"quest"))
	NodeUI.sub(self, "the wizard group chat is BEEFING at 3am. someone has to say something.")
	var h := NodeUI.hbox(self, 250)
	h.add_child(NodeUI.choice("Drop the perfect meme", "instant credibility. someone airdrops you a card.", Color(0.4, 0.8, 0.95), _chat_meme, true, "", SpriteBank.icon_texture(&"star")))
	h.add_child(NodeUI.choice("Mute the chat", "peace. quiet. heal 8 HP.", Color(0.4, 0.85, 0.55), _chat_mute, true, "", SpriteBank.icon_texture(&"zzz")))

func _chat_meme() -> void:
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := GameState.unlocked_cards(w.reward_pool)
	pool.shuffle()
	if pool.is_empty():
		pool = [&"ember"]
	GameState.deck.append(pool[0])
	var c := Database.get_card(pool[0])
	Audio.play("buff", -4.0)
	_outcome(Loc.t("Devastating. Legendary. Someone airdrops you a %s in tribute.") % (Loc.t(c.title) if c != null else "?"))

func _chat_mute() -> void:
	Audio.play("heal", -4.0)
	GameState.player_hp = min(GameState.player_max_hp, GameState.player_hp + 8)
	_outcome("You mute all 7 chats. The silence heals 8 HP. self-care undefeated.")

# --- helpers -------------------------------------------------------------

func _leave() -> void:
	_outcome("You move on, none the worse.")

## Outcome + the canonical item panel, so a new relic always teaches its effect.
func _outcome_item(text: String, aid: StringName) -> void:
	_outcome(text)
	var a := Database.get_artifact(aid)
	if a != null:
		NodeUI.item_reveal(self, SpriteBank.artifact_texture(aid), a.title, [a.description], Vector2(406, 280))

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
