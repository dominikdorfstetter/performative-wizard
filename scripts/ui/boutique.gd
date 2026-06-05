extends Control
## The Boutique: spend Clout (meta currency) to permanently unlock premium outfit pieces.

func _ready() -> void:
	NodeUI.background(self)
	_build()

func _build() -> void:
	for c in get_children():
		if not (c is ColorRect):
			c.queue_free()
	NodeUI.title(self, "✦ The Boutique", NodeUI.PINK)
	NodeUI.sub(self, "Spend Clout on permanent drip. You have ✦ %d Clout." % GameState.clout)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(264, 178)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	add_child(grid)
	for entry in GameState.BOUTIQUE:
		grid.add_child(_stall(entry))

	var back := NodeUI.small_button("← Back", _to_menu, Color(0.4, 0.85, 0.55))
	back.position = Vector2(486, 600)
	add_child(back)

func _stall(entry: Dictionary) -> Control:
	var p := Database.get_outfit(entry.id)
	var owned: bool = entry.id in GameState.unlocked_outfits
	var afford: bool = not owned and GameState.clout >= entry.cost
	var desc := "%s\n✦ +%d/turn\n%s\n\n%s" % [
		p.slot, p.drip, p.passive_text,
		("OWNED" if owned else "✦ %d Clout" % entry.cost)]
	var accent := Color(0.55, 0.78, 0.45) if owned else (NodeUI.GOLD if afford else Color(0.5, 0.5, 0.56))
	return NodeUI.choice(p.title, desc, accent, _buy.bind(entry), afford)

func _buy(entry: Dictionary) -> void:
	if GameState.buy_boutique(entry.id, entry.cost):
		_build()

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn")
