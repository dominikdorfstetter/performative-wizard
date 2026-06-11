extends Control
## Loot drop: roll a reward — usually an artefact, sometimes gold or a card.

func _ready() -> void:
	NodeUI.background(self)
	NodeUI.title(self, "Loot Drop", Color(0.9, 0.7, 0.4), SpriteBank.icon_texture(&"chest"))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# two beats: the closed chest shivers, THEN the loot pops
	var lid := TextureRect.new()
	lid.texture = SpriteBank.icon_texture(&"chest")
	lid.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lid.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lid.position = Vector2(526, 250)
	lid.size = Vector2(100, 100)
	lid.pivot_offset = Vector2(50, 50)
	add_child(lid)
	var shiver := create_tween()
	for i in 3:
		shiver.tween_property(lid, "rotation", deg_to_rad(-7), 0.07)
		shiver.tween_property(lid, "rotation", deg_to_rad(7), 0.07)
	shiver.tween_property(lid, "rotation", 0.0, 0.05)
	shiver.tween_callback(func():
		lid.queue_free()
		_open(rng))
	var cont := NodeUI.small_button("Continue", _to_map, Color(0.4, 0.85, 0.55))
	cont.position = Vector2(486, 566)
	add_child(cont)

func _open(rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	if roll < 0.6:
		var aid := _unowned(rng)
		if aid != &"":
			GameState.add_artifact(aid)
			Audio.play("buff", -4.0)
			_reveal_artifact(aid)
			return
		GameState.gold += 40
		Audio.play("coin", -4.0)
		_reveal_text("every artefact's already yours — have 40 gold")
		return
	elif roll < 0.85:
		var g := rng.randi_range(25, 45)
		GameState.gold += g
		Audio.play("coin", -4.0)
		_reveal_text("+%d gold. secure the bag." % g)
		return
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := GameState.unlocked_cards(w.reward_pool)   # respect the unlock gate (was leaking locked cards)
	if pool.is_empty():
		GameState.gold += 40
		_reveal_text("nothing new to cop — have 40 gold")
		return
	pool.shuffle()
	GameState.deck.append(pool[0])
	Audio.play("card", -4.0)
	_reveal_card(pool[0])

func _reveal_artifact(aid: StringName) -> void:
	var a := Database.get_artifact(aid)
	NodeUI.sub(self, "W — you looted an artefact:", 180)
	NodeUI.item_reveal(self, SpriteBank.artifact_texture(aid), a.title, [a.description],
		Vector2(406, 236), CardView.rarity_color(a.rarity))

func _reveal_card(cid: StringName) -> void:
	NodeUI.sub(self, "a spare card fell out", 190)
	var c := CardView.build(Database.get_card(cid), false, Callable())
	c.position = Vector2(501, 250)
	add_child(c)
	_pop(c)

func _reveal_text(msg: String) -> void:
	var l := NodeUI.sub(self, msg, 300)
	l.add_theme_font_size_override("font_size", 26)

# --- helpers -------------------------------------------------------------

func _pop(node: Control) -> void:
	node.pivot_offset = node.size * 0.5 if node.size != Vector2.ZERO else node.custom_minimum_size * 0.5
	node.scale = Vector2(0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unowned(_rng: RandomNumberGenerator) -> StringName:
	return GameState.random_unowned_artifact()

func _to_map() -> void:
	Fader.change_scene("res://scenes/map/map.tscn")
