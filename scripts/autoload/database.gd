extends Node
## Autoload. Loads every data resource at boot and provides lookup by id.

var cards: Dictionary = {}      # StringName -> CardData
var outfits: Dictionary = {}    # StringName -> OutfitData
var enemies: Dictionary = {}    # StringName -> EnemyData
var wizards: Dictionary = {}    # StringName -> WizardData

func _ready() -> void:
	_load_dir("res://data/cards", cards)
	_load_dir("res://data/outfits", outfits)
	_load_dir("res://data/enemies", enemies)
	_load_dir("res://data/wizards", wizards)
	print("[Database] loaded %d cards, %d outfits, %d enemies, %d wizards"
		% [cards.size(), outfits.size(), enemies.size(), wizards.size()])

func _load_dir(path: String, into: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[Database] missing dir: " + path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			var res: Resource = load(path + "/" + file_name)
			if res != null and ("id" in res) and res.id != &"":
				into[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_card(id: StringName) -> CardData:
	return cards.get(id)

func get_outfit(id: StringName) -> OutfitData:
	return outfits.get(id)

func get_enemy(id: StringName) -> EnemyData:
	return enemies.get(id)

func get_wizard(id: StringName) -> WizardData:
	return wizards.get(id)
