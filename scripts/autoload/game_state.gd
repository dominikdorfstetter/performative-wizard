extends Node
## Autoload. Holds the current run (map, deck, gold, artefacts, equipped outfit) plus
## meta progression (unlocked wardrobe + Clout), persisted to user://save.json.

const SAVE_PATH := "user://save.json"

const SLOTS: Array[String] = ["Hat", "Robe", "Staff", "Boots", "Trinket"]

# The bare wardrobe a fresh run starts with — one basic piece per slot.
const STARTER_OWNED: Array[StringName] = [
	&"apprentice_hat", &"drip_robe", &"plain_wand", &"worn_boots", &"lucky_charm",
]
const DEFAULT_EQUIP := {
	"Hat": &"apprentice_hat", "Robe": &"drip_robe", "Staff": &"plain_wand",
	"Boots": &"worn_boots", "Trinket": &"lucky_charm",
}

# Every other piece is unlocked in the Boutique with Clout (the meta-progression sink).
const BOUTIQUE: Array[Dictionary] = [
	{"id": &"pointed_hat_swag", "cost": 40},
	{"id": &"smolder_boots", "cost": 50},
	{"id": &"char_wand", "cost": 60},
	{"id": &"bone_scepter", "cost": 60},
	{"id": &"robe_of_excess", "cost": 70},
	{"id": &"crowd_pleaser", "cost": 70},
	{"id": &"influencer_ring", "cost": 90},
	{"id": &"lucky_cap", "cost": 95},
	{"id": &"catwalk_heels", "cost": 100},
	{"id": &"showstopper_hat", "cost": 110},
	{"id": &"phoenix_gown", "cost": 130},
	{"id": &"diva_heels", "cost": 160},
]

# --- Meta: persists across runs ---
var unlocked_outfits: Array[StringName] = []
var equipped: Dictionary = {}
var clout := 0                               # meta currency, spent in the Boutique
var clout_earned := 0                        # lifetime Clout (never spent down) — gates unlocks
var ascension := 0                           # highest cleared difficulty tier
var sfx_on := true
var music_on := true

const MAX_ACTS := 3

# --- Current run ---
var wizard_id: StringName = &"fire"
var deck: Array[StringName] = []
var passives: Array[StringName] = []         # outfit passives
var player_max_hp := 0
var player_hp := 0
var drip := 0
var gold := 0
var act := 1                                 # 1..MAX_ACTS
var asc_level := 0                           # ascension modifiers active this run
var run_artifacts: Array[StringName] = []    # artefact ids held this run
var card_upgrades: Dictionary = {}           # card_id -> true (Glow'd Up: costs 1 less)
var map: Array = []
var pos_row := -1                            # -1 = haven't entered row 0 yet
var pos_col := -1

var message := ""

func _ready() -> void:
	load_meta()
	_ensure_defaults()
	Audio.set_sfx_muted(not sfx_on)
	Audio.set_music_muted(not music_on)

func set_audio(sfx: bool, music: bool) -> void:
	sfx_on = sfx
	music_on = music
	Audio.set_sfx_muted(not sfx)
	Audio.set_music_muted(not music)
	save_meta()

func _ensure_defaults() -> void:
	var changed := false
	for id in STARTER_OWNED:
		if id not in unlocked_outfits:
			unlocked_outfits.append(id)
			changed = true
	if changed:
		save_meta()
	if equipped.is_empty():
		equipped = DEFAULT_EQUIP.duplicate()

## Wipe meta progression — a brand-new game with only the basic wardrobe.
func new_game() -> void:
	unlocked_outfits = STARTER_OWNED.duplicate()
	equipped = DEFAULT_EQUIP.duplicate()
	clout = 0
	clout_earned = 0
	ascension = 0
	run_artifacts = []
	map = []
	save_meta()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

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
	act = 1
	run_artifacts = []
	card_upgrades = {}
	_validate_equip_for(w.element)
	map = MapGenerator.generate(randi())
	pos_row = -1
	pos_col = -1

# --- wizard unlocking ----------------------------------------------------

func wizard_unlocked(id: StringName) -> bool:
	var w := Database.get_wizard(id)
	return w != null and clout_earned >= w.unlock_clout

func locked_wizard_hint(id: StringName) -> String:
	var w := Database.get_wizard(id)
	if w == null or wizard_unlocked(id):
		return ""
	return "🔒  Unlock at ✦ %d  (you have ✦ %d earned)" % [w.unlock_clout, clout_earned]

func is_upgraded(id: StringName) -> bool:
	return card_upgrades.get(id, false)

func upgrade_card(id: StringName) -> void:
	card_upgrades[id] = true

## Effective energy cost after Glow-Up (costs 1 less, min 0).
func card_cost(card: CardData) -> int:
	if card == null:
		return 0
	return max(0, card.cost - (1 if is_upgraded(card.id) else 0))

func card_unlocked(id: StringName) -> bool:
	var c := Database.get_card(id)
	return c != null and clout_earned >= c.unlock_clout

func artifact_unlocked(id: StringName) -> bool:
	var a := Database.get_artifact(id)
	return a != null and clout_earned >= a.unlock_clout

## Filter a card-id list down to what the player has unlocked (for reward/shop pools).
func unlocked_cards(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		if card_unlocked(id):
			out.append(id)
	return out

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
	var w := Database.get_wizard(wizard_id)
	if w != null:
		for ip in w.innate_passives:
			if ip not in out:
				out.append(ip)
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
	# deeper acts and ascension make everything tougher
	var act_hp := 1.0 + 0.35 * (act - 1) + 0.08 * asc_level
	var act_dmg := 1.0 + 0.22 * (act - 1) + 0.06 * asc_level
	if node.get("type") == "Boss":
		return [act_hp, act_dmg]
	var r: int = node.get("row", 0)
	return [act_hp + 0.09 * r, act_dmg + 0.07 * r]

func combat_reward(node: Dictionary) -> int:
	var base := 9 + int(node.get("row", 0)) * 2
	if node.get("type") == "Elite":
		base += 25
	base += (node.get("enemies", []).size() - 1) * 6
	return base

func finish_run(victory: bool) -> void:
	var earned := 20 + int(gold / 3)
	if victory:
		earned += 80 + asc_level * 10
	var before := clout_earned
	clout += earned
	clout_earned += earned
	if victory and asc_level >= ascension:
		ascension = asc_level + 1   # banked a new difficulty tier
	message = "Run over. +%d Clout (total %d)." % [earned, clout]
	var unlocked := _wizards_unlocked_between(before, clout_earned)
	if not unlocked.is_empty():
		message += "\n✦ NEW FIT UNLOCKED: %s!" % ", ".join(unlocked)
	save_meta()

## Names of wizards whose unlock threshold falls in (lo, hi] — i.e. just unlocked.
func _wizards_unlocked_between(lo: int, hi: int) -> Array:
	var names: Array = []
	for wid in [&"fire", &"necro", &"rizz"]:
		var w := Database.get_wizard(wid)
		if w != null and w.unlock_clout > lo and w.unlock_clout <= hi:
			names.append(w.pname)
	return names

## Called when a boss dies. Returns true if the run continues into a new act.
func advance_act() -> bool:
	if act >= MAX_ACTS:
		return false
	act += 1
	gold += 15
	map = MapGenerator.generate(randi())
	pos_row = -1
	pos_col = -1
	message = "✦ ACT %d ✦  the gauntlet escalates." % act
	return true

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
	# legacy saves: treat current Clout as already-earned so nothing re-locks
	clout_earned = int(data.get("clout_earned", clout))
	ascension = int(data.get("ascension", 0))
	sfx_on = bool(data.get("sfx_on", true))
	music_on = bool(data.get("music_on", true))

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
	f.store_string(JSON.stringify({"unlocked_outfits": owned, "equipped": eq, "clout": clout, "clout_earned": clout_earned, "ascension": ascension, "sfx_on": sfx_on, "music_on": music_on}, "\t"))
