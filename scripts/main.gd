extends Control
## M0 entry point. Verifies the Database loaded and renders a single card so we can
## see data flow end-to-end before building real combat (M1).

func _ready() -> void:
	var card := Database.get_card(&"ember")
	if card != null:
		$Panel/Cost.text = str(card.cost)
		$Panel/Title.text = card.title
		$Panel/Desc.text = card.description
		print("[Main] rendered card: %s (cost %d)" % [card.title, card.cost])
	else:
		$Panel/Title.text = "MISSING"
		$Panel/Desc.text = "ember card not found"
		push_warning("[Main] ember card not found in Database")
