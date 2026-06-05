extends Control
## Chest: roll a reward — usually an artefact, sometimes gold or a card.

func _ready() -> void:
	NodeUI.background(self)
	NodeUI.title(self, "📦  A Chest!", Color(0.9, 0.7, 0.4))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var msg := _open(rng)
	NodeUI.sub(self, msg, 210)
	var cont := NodeUI.small_button("Continue", _to_map, Color(0.4, 0.85, 0.55))
	cont.position = Vector2(486, 520)
	add_child(cont)

func _open(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	if roll < 0.6:
		var aid := _unowned(rng)
		if aid != &"":
			GameState.add_artifact(aid)
			var a := Database.get_artifact(aid)
			return "You found an artefact!\n\n%s  %s\n%s" % [a.emoji, a.title, a.description]
		GameState.gold += 40
		return "Every artefact is already yours — take 40 gold instead."
	elif roll < 0.85:
		var g := rng.randi_range(25, 45)
		GameState.gold += g
		return "💰  %d gold spills out!" % g
	var w := Database.get_wizard(GameState.wizard_id)
	var pool := w.reward_pool.duplicate()
	pool.shuffle()
	var cid: StringName = pool[0]
	GameState.deck.append(cid)
	return "A spare card was tucked inside:\n\n%s" % Database.get_card(cid).title

func _unowned(rng: RandomNumberGenerator) -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid):
			return aid
	return &""

func _to_map() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
