extends Node
## Autoload. Loads every data resource at boot and provides lookup by id.

var cards: Dictionary = {}      # StringName -> CardData
var outfits: Dictionary = {}    # StringName -> OutfitData
var enemies: Dictionary = {}    # StringName -> EnemyData
var wizards: Dictionary = {}    # StringName -> WizardData
var artifacts: Dictionary = {}  # StringName -> ArtifactData

func _ready() -> void:
	_load_dir("res://data/cards", cards)
	_load_dir("res://data/outfits", outfits)
	_load_dir("res://data/enemies", enemies)
	_load_dir("res://data/wizards", wizards)
	_load_dir("res://data/artifacts", artifacts)
	print("[Database] loaded %d cards, %d outfits, %d enemies, %d wizards, %d artifacts"
		% [cards.size(), outfits.size(), enemies.size(), wizards.size(), artifacts.size()])

func _load_dir(path: String, into: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[Database] missing dir: " + path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			# Exported PCKs list resources as "name.tres.remap"; strip it and load the original.
			var fn := file_name
			if fn.ends_with(".remap"):
				fn = fn.substr(0, fn.length() - 6)
			if fn.ends_with(".tres") or fn.ends_with(".res"):
				var res: Resource = load(path + "/" + fn)
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

func get_artifact(id: StringName) -> ArtifactData:
	return artifacts.get(id)

func all_artifact_ids() -> Array:
	return artifacts.keys()
