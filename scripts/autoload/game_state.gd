extends Node
## Autoload. Holds the current run (reset each run), the equipped outfit, and meta
## progression (the unlocked wardrobe), persisted to user://save.json.

const SAVE_PATH := "user://save.json"

# The fixed enemy gauntlet for the mini-run (M4 replaces this with a map).
const RUN_ENEMIES: Array[StringName] = [&"alley_cat", &"disgruntled_pigeon", &"possessed_wardrobe"]

const SLOTS: Array[String] = ["Hat", "Robe", "Staff", "Boots", "Trinket"]

# Wardrobe you own from the very start.
const DEFAULT_OWNED: Array[StringName] = [
	&"apprentice_hat", &"pointed_hat_swag",
	&"drip_robe", &"robe_of_excess",
	&"plain_wand", &"char_wand", &"bone_scepter",
	&"worn_boots", &"smolder_boots",
	&"lucky_charm", &"crowd_pleaser",
]
# The modest starting loadout (so progression is felt as you swap pieces in).
const DEFAULT_EQUIP := {
	"Hat": &"apprentice_hat", "Robe": &"drip_robe", "Staff": &"plain_wand",
	"Boots": &"worn_boots", "Trinket": &"lucky_charm",
}

# --- Meta: persists across runs ---
var unlocked_outfits: Array[StringName] = []
var equipped: Dictionary = {}                 # slot (String) -> outfit id (StringName)

# --- Current run: reset on new run ---
var wizard_id: StringName = &"fire"
var deck: Array[StringName] = []
var passives: Array[StringName] = []
var player_max_hp := 0
var player_hp := 0
var drip := 0
var fight_index := 0

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
	fight_index = 0
	_validate_equip_for(w.element)

## Make sure every slot holds a piece that's owned and legal for this class.
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

## Bake the equipped outfit into the run's deck, Swag income, and passives.
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

func current_enemy() -> StringName:
	return RUN_ENEMIES[fight_index] if fight_index < RUN_ENEMIES.size() else &""

func advance_fight() -> void:
	fight_index += 1

func run_complete() -> bool:
	return fight_index >= RUN_ENEMIES.size()

# --- meta save -----------------------------------------------------------

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
	f.store_string(JSON.stringify({"unlocked_outfits": owned, "equipped": eq}, "\t"))
