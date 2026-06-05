extends Node
## Autoload. Holds the current run (map, deck, gold, artefacts, equipped outfit) plus
## meta progression (unlocked wardrobe + Clout), persisted to user://save.json.

const SAVE_PATH := "user://save.json"

const SLOTS: Array[String] = ["Hat", "Robe", "Staff", "Boots", "Trinket"]

const DEFAULT_OWNED: Array[StringName] = [
	&"apprentice_hat", &"pointed_hat_swag",
	&"drip_robe", &"robe_of_excess",
	&"plain_wand", &"char_wand", &"bone_scepter",
	&"worn_boots", &"smolder_boots",
	&"lucky_charm", &"crowd_pleaser",
]
const DEFAULT_EQUIP := {
	"Hat": &"apprentice_hat", "Robe": &"drip_robe", "Staff": &"plain_wand",
	"Boots": &"worn_boots", "Trinket": &"lucky_charm",
}

# Premium pieces unlockable in the Boutique for Clout (meta progression sink).
const BOUTIQUE: Array[Dictionary] = [
	{"id": &"influencer_ring", "cost": 90},
	{"id": &"showstopper_hat", "cost": 110},
	{"id": &"phoenix_gown", "cost": 130},
	{"id": &"diva_heels", "cost": 160},
]

# --- Meta: persists across runs ---
var unlocked_outfits: Array[StringName] = []
var equipped: Dictionary = {}
var clout := 0                               # meta currency, spent in the Boutique

# --- Current run ---
var wizard_id: StringName = &"fire"
var deck: Array[StringName] = []
var passives: Array[StringName] = []         # outfit passives
var player_max_hp := 0
var player_hp := 0
var drip := 0
var gold := 0
var run_artifacts: Array[StringName] = []    # artefact ids held this run
var map: Array = []
var pos_row := -1                            # -1 = haven't entered row 0 yet
var pos_col := -1

var message := ""

func _ready() -> void:
	load_meta()
	_ensure_defaults()

func _ensure_defaults() -> void:
	var changed := false
	for id in DEFAULT_OWNED:
		if id not in unlocked_outfits:
			unlocked_outfits.append(id)
			changed = true
	if changed:
		save_meta()
	if equipped.is_empty():
		equipped = DEFAULT_EQUIP.duplicate()

# --- wardrobe ------------------------------------------------------------

func owned_for(slot: String, element: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in unlocked_outfits:
		var p := Database.get_outfit(id)
		if p != null and p.slot == slot and (p.element == "Neutral" or p.element == element):
			out.append(id)
	return out

func equip(slot: String, id: StringName) -> void:
	equipped[slot] = id

func equipped_id(slot: String) -> StringName:
	return equipped.get(slot, &"")

func equipped_pieces() -> Array[OutfitData]:
	var out: Array[OutfitData] = []
	for slot in SLOTS:
		var id: StringName = equipped.get(slot, &"")
		if id != &"":
			var p := Database.get_outfit(id)
			if p != null:
				out.append(p)
	return out

func preview_drip() -> int:
	var d := 0
	for p in equipped_pieces():
		d += p.drip
	return d

# --- run flow ------------------------------------------------------------

func start_run(wid: StringName) -> void:
	var w := Database.get_wizard(wid)
	if w == null:
		push_error("[GameState] unknown wizard: " + String(wid))
		return
	wizard_id = wid
	player_max_hp = w.max_hp
	player_hp = w.max_hp
	gold = 30
	run_artifacts = []
	_validate_equip_for(w.element)
	map = MapGenerator.generate(randi())
	pos_row = -1
	pos_col = -1

func _validate_equip_for(element: String) -> void:
	for slot in SLOTS:
		var id: StringName = equipped.get(slot, &"")
		var ok := false
		if id != &"" and id in unlocked_outfits:
			var p := Database.get_outfit(id)
			ok = p != null and p.slot == slot and (p.element == "Neutral" or p.element == element)
		if not ok:
			var opts := owned_for(slot, element)
			equipped[slot] = opts[0] if opts.size() > 0 else &""

func finalize_loadout() -> void:
	var w := Database.get_wizard(wizard_id)
	deck = w.starter_deck.duplicate()
	drip = 0
	passives = []
	for p in equipped_pieces():
		drip += p.drip
		if p.passive_id != &"":
			passives.append(p.passive_id)
		for cid in p.injected_cards:
			deck.append(cid)

# Outfit passives + artefact passives, for combat.
func active_passives() -> Array[StringName]:
	var out: Array[StringName] = passives.duplicate()
	for aid in run_artifacts:
		var a := Database.get_artifact(aid)
		if a != null and a.passive_id != &"" and a.passive_id not in out:
			out.append(a.passive_id)
	return out

func gold_income() -> int:
	var g := 0
	for aid in run_artifacts:
		var a := Database.get_artifact(aid)
		if a != null:
			g += a.gold_per_combat
	return g

func add_artifact(id: StringName) -> bool:
	if id in run_artifacts:
		return false
	run_artifacts.append(id)
	return true

func has_artifact(id: StringName) -> bool:
	return id in run_artifacts

# --- map navigation ------------------------------------------------------

func node_at(row: int, col: int) -> Dictionary:
	if row < 0 or row >= map.size():
		return {}
	for n in map[row]:
		if n.col == col:
			return n
	return {}

func current_node() -> Dictionary:
	return node_at(pos_row, pos_col)

## Which nodes can the player move to next?
func available() -> Array:
	if pos_row < 0:
		return map[0] if map.size() > 0 else []
	var node := current_node()
	var out: Array = []
	if pos_row + 1 < map.size():
		for col in node.get("links", []):
			out.append(node_at(pos_row + 1, col))
	return out

func can_enter(row: int, col: int) -> bool:
	for n in available():
		if n.get("row") == row and n.get("col") == col:
			return true
	return false

func enter(row: int, col: int) -> Dictionary:
	pos_row = row
	pos_col = col
	var n := current_node()
	n["visited"] = true
	return n

func node_scales(node: Dictionary) -> Array:
	if node.get("type") == "Boss":
		return [1.0, 1.0]
	var r: int = node.get("row", 0)
	return [1.0 + 0.09 * r, 1.0 + 0.07 * r]

func combat_reward(node: Dictionary) -> int:
	var base := 9 + int(node.get("row", 0)) * 2
	if node.get("type") == "Elite":
		base += 25
	base += (node.get("enemies", []).size() - 1) * 6
	return base

func finish_run(victory: bool) -> void:
	var earned := 20 + int(gold / 3)
	if victory:
		earned += 80
	clout += earned
	message = "Run over. +%d Clout (total %d)." % [earned, clout]
	save_meta()

# --- meta save -----------------------------------------------------------

func buy_boutique(id: StringName, cost: int) -> bool:
	if id in unlocked_outfits or clout < cost:
		return false
	clout -= cost
	unlocked_outfits.append(id)
	save_meta()
	return true

func unlock_outfit(id: StringName) -> bool:
	if id in unlocked_outfits:
		return false
	unlocked_outfits.append(id)
	save_meta()
	return true

func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	unlocked_outfits.clear()
	for o in data.get("unlocked_outfits", []):
		unlocked_outfits.append(StringName(o))
	for slot in data.get("equipped", {}):
		equipped[slot] = StringName(data["equipped"][slot])
	clout = int(data.get("clout", 0))

func save_meta() -> void:
	var owned: Array[String] = []
	for id in unlocked_outfits:
		owned.append(String(id))
	var eq := {}
	for slot in equipped:
		eq[slot] = String(equipped[slot])
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[GameState] could not open save file for writing")
		return
	f.store_string(JSON.stringify({"unlocked_outfits": owned, "equipped": eq, "clout": clout}, "\t"))
