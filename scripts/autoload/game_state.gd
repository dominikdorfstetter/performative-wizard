extends Node
## Autoload. Holds the current run (map, deck, gold, artefacts, equipped outfit) plus
## meta progression (unlocked wardrobe + Clout), persisted to user://save.json.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

# The demo's conversion funnel — shown on run-end screens and the act interstitial.
# An empty string hides its button (set the Discord invite before launch).
const LINK_ITCH := "https://dorfid.itch.io/performative-wizards"
const LINK_DISCORD := "https://discord.gg/bXppC4WdNb"
const LINK_ISSUES := "https://github.com/dominikdorfstetter/performative-wizard/issues"

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
	{"id": &"flash_cannon", "cost": 90},
	{"id": &"slow_burn_robe", "cost": 90},
	{"id": &"mourning_veil", "cost": 90},
	{"id": &"shroud_squad", "cost": 110},
	{"id": &"pallbearer_boots", "cost": 95},
	{"id": &"mirror_shades", "cost": 85},
	{"id": &"snakeskin_jacket", "cost": 120},
	{"id": &"selfie_stick", "cost": 75},
]

# --- Meta: persists across runs ---
var unlocked_outfits: Array[StringName] = []
var equipped: Dictionary = {}
var clout := 0                               # meta currency, spent in the Boutique
var clout_earned := 0                        # lifetime Clout (never spent down) — gates unlocks
var ascension := 0                           # highest cleared difficulty tier
var critic_score := 0                        # lifetime style score from The Critic's reviews
var sfx_on := true
var music_on := true
var locale := "en"
var seen_tutorial := false                   # the first-fight teaching beats fire once
var fullscreen_on := false                   # persisted; ignored on web (browser-controlled)
var effects_on := true                       # screen shake + full-screen hit flashes (a11y)
var music_vol := 1.0
var sfx_vol := 1.0

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
var card_upgrades: Dictionary = {}           # card_id -> "cost"|"value" (legacy true == "cost")
var map: Array = []
var pos_row := -1                            # -1 = haven't entered row 0 yet
var pos_col := -1

# The Critic (run-scoped): her verdict on the LAST fight, and the verdict still
# waiting to reshape the NEXT room the player enters.
var critic_last_rating := ""
var critic_last_details: Dictionary = {}     # full rating dict — the reward screen's "because"
var critic_last_signature: StringName = &""
var critic_last_freshness := 1.0
var pending_critic := ""
var pending_freshness := 1.0
# P2 anti-solve: how tired she is of each style you keep serving (run-scoped).
var critic_fatigue: Dictionary = {}

# The Feed (P4): a Trend that re-prices Aura income, rotating per act.
var trend: StringName = &""

var message := ""

# The serialized run-in-progress (snapshotted at each map entry, cleared when the run
# ends). Lives inside save.json next to the meta keys.
var _run_snapshot: Dictionary = {}

func _ready() -> void:
	var fresh := not FileAccess.file_exists(SAVE_PATH)
	load_meta()
	_ensure_defaults()
	if fresh:
		# first boot ever: greet DE/ES players in their OS language (README sells
		# EN/DE/ES, but nothing ever consulted the locale before)
		var sys := OS.get_locale_language()
		if sys in Loc.LOCALES:
			locale = sys
	Audio.set_sfx_muted(not sfx_on)
	Audio.set_music_muted(not music_on)
	Audio.set_music_volume(music_vol)
	Audio.set_sfx_volume(sfx_vol)
	Loc.set_locale(locale)
	if fullscreen_on and not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

## One global fullscreen handler (F11, or Cmd+Ctrl+F for the macOS convention) —
## it used to be copy-pasted onto exactly 2 of ~10 screens while the menu footer
## advertised it everywhere.
func _unhandled_input(event: InputEvent) -> void:
	if OS.has_feature("web"):
		return   # the browser owns fullscreen
	if event is InputEventKey and event.pressed and not event.echo:
		var combo: bool = event.keycode == KEY_F and event.ctrl_pressed and event.meta_pressed
		if event.keycode == KEY_F11 or combo:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_on = not fs
	save_meta()

## Abandoning mid-run counts as a loss: Clout still banks, the snapshot clears.
func abandon_run() -> void:
	finish_run(false)

func set_language(l: String) -> void:
	locale = l
	Loc.set_locale(l)
	save_meta()

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
	critic_score = 0
	run_artifacts = []
	map = []
	_run_snapshot = {}
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
	critic_fatigue = {}
	pending_critic = ""
	pending_freshness = 1.0
	critic_last_rating = ""
	_roll_trend()
	map = MapGenerator.generate(randi(), act)
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
	return Loc.t("Locked — unlock at %d Clout  (you have %d earned)") % [w.unlock_clout, clout_earned]

func is_upgraded(id: StringName) -> bool:
	return card_upgrades.has(id)

## "cost" (Glow Up classic: 1 cheaper) or "value" (+2 on damage/Block/heal amounts).
## Legacy saves stored `true`, which reads as "cost".
func upgrade_mode(id: StringName) -> String:
	if not card_upgrades.has(id):
		return ""
	return "value" if str(card_upgrades[id]) == "value" else "cost"

func upgrade_card(id: StringName, mode := "cost") -> void:
	card_upgrades[id] = mode

## Effective energy cost after Glow-Up (costs 1 less, min 0).
func card_cost(card: CardData) -> int:
	if card == null:
		return 0
	return max(0, card.cost - (1 if upgrade_mode(card.id) == "cost" else 0))

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

## The archetype the player is leaning into this run (>=2 drafted cards of one tag), else &"".
## Starters/finishers/neutrals are untagged, so a fresh deck reads as &"" (offers are free).
func deck_archetype() -> StringName:
	var counts := {}
	for id in deck:
		var c := Database.get_card(id)
		if c != null and c.archetype != &"":
			counts[c.archetype] = int(counts.get(c.archetype, 0)) + 1
	var best: StringName = &""
	var bn := 0
	for k in counts:
		if int(counts[k]) > bn:
			bn = int(counts[k])
			best = k
	return best if bn >= 2 else &""

## Up to n reward options, biased toward the deck's emerging archetype: once you've drafted
## >=2 of one tag, at least 2 of the offers share it (so a build comes together), otherwise
## a flat-random draw. Respects the unlock gate. This is what makes "two builds" real.
func reward_offer(n: int) -> Array:
	var w := Database.get_wizard(wizard_id)
	var pool: Array = unlocked_cards(w.reward_pool)
	pool.shuffle()
	var dom := deck_archetype()
	if dom == &"":
		return pool.slice(0, min(n, pool.size()))
	var on: Array = []
	var off: Array = []
	for id in pool:
		var c := Database.get_card(id)
		if c != null and c.archetype == dom:
			on.append(id)
		else:
			off.append(id)
	var offer: Array = []
	for id in on:                       # up to 2 on-archetype, so the build coheres
		if offer.size() >= 2:
			break
		offer.append(id)
	for id in off:                      # fill the rest with variety
		if offer.size() >= n:
			break
		offer.append(id)
	for id in on:                       # top up if the off-pool was thin
		if offer.size() >= n:
			break
		if id not in offer:
			offer.append(id)
	return offer.slice(0, n)

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
	apply_critic_mutation(n)
	return n

func node_scales(node: Dictionary) -> Array:
	# deeper acts and ascension make everything tougher
	# Softened 2026-06-07 after the balance playtest: the act2→act3 spike was a
	# damage-driven attrition cliff. Lowered per-act/row HP+dmg to smooth the ramp.
	# Balance pass #4 (2026-06-10): asc-HP now kinks at 4 (0.08 -> 0.05/level).
	# Pure HP sponges past asc4 only punished the flat-damage classes — the asc8
	# boss spread was fire 10 / necro 19 / rizz 82. Threat (dmg) stays linear.
	var asc_hp := 0.08 * mini(asc_level, 4) + 0.05 * maxi(0, asc_level - 4)
	var asc_dmg := 0.05 * mini(asc_level, 4) + 0.035 * maxi(0, asc_level - 4)
	var act_hp := 1.0 + 0.30 * (act - 1) + asc_hp
	var act_dmg := 1.0 + 0.17 * (act - 1) + asc_dmg
	if node.get("type") == "Boss":
		return [act_hp, act_dmg]
	var r: int = node.get("row", 0)
	return [act_hp + 0.07 * r, act_dmg + 0.05 * r]

func combat_reward(node: Dictionary) -> int:
	var base := 9 + int(node.get("row", 0)) * 2
	if node.get("type") == "Elite":
		base += 25
	base += (node.get("enemies", []).size() - 1) * 6
	base += int(node.get("critic_bonus_gold", 0))   # The Critic's VIP ovation
	return base

# --- The Critic: review the run ------------------------------------------

# Several voice lines per grade so back-to-back fights don't repeat verbatim.
const CRITIC_LINES := {
	"S": ["S — serve. obsessed. devastating.", "S — the giiirls are SERVING. iconic.", "S — i felt that in my SOUL. headliner."],
	"A": ["A — ate. left a crumb on the plate.", "A — a real look. almost made me clap.", "A — so close to perfect it's annoying."],
	"B": ["B — mid showing, bestie. do better.", "B — it was giving... fine. i guess.", "B — i've seen worse. i've seen way better."],
	"C": ["C — flop era. who told you that was giving?", "C — boo. i've seen NPCs with more drip.", "C — that wasn't a fit, that was a cry for help."],
}

## Bank The Critic's verdict on the fight that just ended. Her taste DRIFTS (P2):
## the style you just served tires her (its bonus shrinks next time), while styles
## you've laid off recover. Repeating the same cash-out — the degenerate
## hoard-then-one-finisher line — decays its own reward, so variety is the meta.
func record_show_rating(r: Dictionary) -> void:
	var rating := String(r.get("rating", "B"))
	var sig: StringName = r.get("signature", &"grind")
	var fat := int(critic_fatigue.get(sig, 0))
	critic_last_rating = rating
	critic_last_details = r.duplicate()
	critic_last_signature = sig
	critic_last_freshness = maxf(0.0, 1.0 - 0.34 * fat)
	pending_critic = rating
	pending_freshness = critic_last_freshness
	critic_score += {"S": 3, "A": 2, "B": 1, "C": 0}.get(rating, 0)
	# drift: every style cools by 1, then the style just served heats by 2 (net +1)
	for k in critic_fatigue.keys():
		critic_fatigue[k] = max(0, int(critic_fatigue[k]) - 1)
	critic_fatigue[sig] = min(3, fat + 2)
	save_meta()

## Her review rewrites the room ahead. An S opens a VIP room (richer reward) — but
## only if the style was FRESH; serve the same finish over and over and she's seen
## it (no VIP). A C sends a heckler into the next fight. Penalties touch ROOMS ONLY
## — never the starting-combat math (no starting-Aura debuff, no death spiral).
## Non-fight rooms (Rest/Shop/Event/Boss) are left alone.
func apply_critic_mutation(n: Dictionary) -> void:
	if pending_critic == "":
		return
	var rating := pending_critic
	var freshness := pending_freshness
	pending_critic = ""
	pending_freshness = 1.0
	var t := String(n.get("type", ""))
	if t != "Combat" and t != "Elite":
		return
	if rating == "S":
		var bonus := int(round(20 * freshness))
		if bonus > 0:
			n["critic_bonus_gold"] = int(n.get("critic_bonus_gold", 0)) + bonus
			n["critic_note"] = "vip"
		else:
			n["critic_note"] = "bored"   # she's seen this exact finish too many times
	elif rating == "C":
		var ens: Array = n.get("enemies", []).duplicate()
		ens.append(&"heckler")
		n["enemies"] = ens
		n["critic_note"] = "heckler"

## The Critic's spoken verdict (localized). When you keep serving the same fresh-out
## style she gets bored and demands something new — the drift made audible.
func critic_quip(rating: String) -> String:
	if (rating == "S" or rating == "A") and critic_last_freshness <= 0.0:
		return Loc.t("again? serve me something NEW.")
	var arr: Array = CRITIC_LINES.get(rating, CRITIC_LINES["C"])
	return Loc.t(arr[critic_score % arr.size()])

# --- The Feed: rotating Trend (P4) ---------------------------------------

# Trend → Aura-income modifier. Re-prices the show without ever zeroing income.
const TRENDS: Array[StringName] = [&"its_giving", &"flop_era", &"going_viral"]
const TREND_MOD := {&"its_giving": 1, &"flop_era": -1, &"going_viral": 1}
const TREND_LABEL := {
	&"its_giving": "TREND: it's giving abundance  (+1 Aura/turn)",
	&"flop_era": "TREND: flop era  (-1 Aura/turn)",
	&"going_viral": "TREND: going viral  (+1 Aura/turn)",
}

func _roll_trend() -> void:
	trend = TRENDS[(act - 1) % TRENDS.size()]

func trend_drip_mod() -> int:
	return int(TREND_MOD.get(trend, 0))

## Aura income with the current Trend priced in (floored at 0 — never negative).
func effective_drip() -> int:
	return max(0, drip + trend_drip_mod())

func trend_label() -> String:
	return Loc.t(String(TREND_LABEL.get(trend, "")))

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
		message += "\nNEW FIT UNLOCKED: %s!" % ", ".join(unlocked)
	_run_snapshot = {}   # the run is over; Resume must not bring it back
	save_meta()

## Names of wizards whose unlock threshold falls in (lo, hi] — i.e. just unlocked.
func _wizards_unlocked_between(lo: int, hi: int) -> Array:
	var names: Array = []
	for wid in [&"fire", &"necro", &"rizz"]:
		var w := Database.get_wizard(wid)
		if w != null and w.unlock_clout > lo and w.unlock_clout <= hi:
			names.append(w.pname)
	return names

## EVERYTHING that unlocked when lifetime Clout moved (lo, hi] — wizards, cards,
## relics. The game computed these forever but never announced them anywhere.
func unlocks_between(lo: int, hi: int) -> Array[String]:
	var out: Array[String] = []
	out.append_array(_wizards_unlocked_between(lo, hi))
	for cid in Database.cards:
		var c: CardData = Database.cards[cid]
		if c.unlock_clout > lo and c.unlock_clout <= hi:
			out.append(Loc.t(c.title))
	for aid in Database.artifacts:
		var a: ArtifactData = Database.artifacts[aid]
		if a.unlock_clout > lo and a.unlock_clout <= hi:
			out.append(Loc.t(a.title))
	return out

## The closest still-locked wizard: {name, need} or {} when everything's unlocked.
## Powers the 'one more run' progress bar on the run-end screen.
func next_wizard_unlock() -> Dictionary:
	var best := {}
	for wid in [&"necro", &"rizz"]:
		var w := Database.get_wizard(wid)
		if w != null and clout_earned < w.unlock_clout:
			if best.is_empty() or w.unlock_clout < int(best.need):
				best = {"name": w.pname, "need": w.unlock_clout}
	return best

## Called when a boss dies. Returns true if the run continues into a new act.
func advance_act() -> bool:
	if act >= MAX_ACTS:
		return false
	act += 1
	gold += 15
	_roll_trend()
	map = MapGenerator.generate(randi(), act)
	pos_row = -1
	pos_col = -1
	message = "— ACT %d —  the gauntlet escalates." % act
	return true

# --- run snapshot (quit-safe resume) ---------------------------------------
# The run is snapshotted whenever the player stands ON THE MAP (map_ui calls
# save_run). Combat state is deliberately never serialized: resuming after a
# mid-fight quit costs that one fight, not the run.

func has_run_save() -> bool:
	return not _run_snapshot.is_empty()

func run_save_act() -> int:
	return int(_run_snapshot.get("act", 1))

func save_run() -> void:
	_run_snapshot = _run_to_dict()
	save_meta()

## Restore the saved run into the live fields. Returns false (and drops the
## snapshot) if it fails validation, so callers can fall back to the hub.
func resume_run() -> bool:
	if _run_snapshot.is_empty():
		return false
	if not _run_from_dict(_run_snapshot):
		push_warning("[GameState] run snapshot failed validation — discarding it")
		_run_snapshot = {}
		save_meta()
		return false
	return true

func _run_to_dict() -> Dictionary:
	var rows: Array = []
	for row in map:
		var r: Array = []
		for n in row:
			r.append(_node_to_dict(n))
		rows.append(r)
	var dk: Array = []
	for id in deck:
		dk.append(String(id))
	var arts: Array = []
	for id in run_artifacts:
		arts.append(String(id))
	var pas: Array = []
	for p in passives:
		pas.append(String(p))
	var ups := {}
	for k in card_upgrades:
		ups[String(k)] = upgrade_mode(k)
	var fat := {}
	for k in critic_fatigue:
		fat[String(k)] = int(critic_fatigue[k])
	return {
		"wizard_id": String(wizard_id), "deck": dk, "passives": pas,
		"player_max_hp": player_max_hp, "player_hp": player_hp, "drip": drip,
		"gold": gold, "act": act, "asc_level": asc_level, "artifacts": arts,
		"card_upgrades": ups, "map": rows, "pos_row": pos_row, "pos_col": pos_col,
		"critic_last_rating": critic_last_rating,
		"critic_last_signature": String(critic_last_signature),
		"critic_last_freshness": critic_last_freshness,
		"pending_critic": pending_critic, "pending_freshness": pending_freshness,
		"critic_fatigue": fat, "trend": String(trend),
	}

func _node_to_dict(n: Dictionary) -> Dictionary:
	var ens: Array = []
	for e in n.get("enemies", []):
		ens.append(String(e))
	var links: Array = []
	for l in n.get("links", []):
		links.append(int(l))
	var nd := {
		"type": String(n.get("type", "Combat")), "row": int(n.get("row", 0)),
		"col": int(n.get("col", 0)), "links": links, "enemies": ens,
		"visited": bool(n.get("visited", false)),
	}
	if n.has("critic_bonus_gold"):
		nd["critic_bonus_gold"] = int(n["critic_bonus_gold"])
	if n.has("critic_note"):
		nd["critic_note"] = String(n["critic_note"])
	return nd

## Apply a (JSON-round-tripped, so numbers may be floats) snapshot. Every field is
## re-typed explicitly; validation failures leave meta untouched and return false.
func _run_from_dict(d: Dictionary) -> bool:
	var wid := StringName(String(d.get("wizard_id", "")))
	if Database.get_wizard(wid) == null:
		return false
	var rows_in: Array = d.get("map", [])
	var deck_in: Array = d.get("deck", [])
	if rows_in.is_empty() or deck_in.is_empty():
		return false
	wizard_id = wid
	deck = []
	for id in deck_in:
		deck.append(StringName(String(id)))
	passives = []
	for p in d.get("passives", []):
		passives.append(StringName(String(p)))
	player_max_hp = max(1, int(d.get("player_max_hp", 1)))
	player_hp = clampi(int(d.get("player_hp", 1)), 1, player_max_hp)
	drip = int(d.get("drip", 0))
	gold = max(0, int(d.get("gold", 0)))
	act = clampi(int(d.get("act", 1)), 1, MAX_ACTS)
	asc_level = max(0, int(d.get("asc_level", 0)))
	run_artifacts = []
	for a in d.get("artifacts", []):
		run_artifacts.append(StringName(String(a)))
	card_upgrades = {}
	var ups_in: Dictionary = d.get("card_upgrades", {})
	for k in ups_in:
		card_upgrades[StringName(String(k))] = "value" if String(ups_in[k]) == "value" else "cost"
	map = []
	for row_in in rows_in:
		if typeof(row_in) != TYPE_ARRAY:
			return false
		var row_out: Array = []
		for n in row_in:
			if typeof(n) != TYPE_DICTIONARY:
				return false
			row_out.append(_node_from_dict(n))
		map.append(row_out)
	pos_row = int(d.get("pos_row", -1))
	pos_col = int(d.get("pos_col", -1))
	critic_last_rating = String(d.get("critic_last_rating", ""))
	critic_last_signature = StringName(String(d.get("critic_last_signature", "")))
	critic_last_freshness = float(d.get("critic_last_freshness", 1.0))
	pending_critic = String(d.get("pending_critic", ""))
	pending_freshness = float(d.get("pending_freshness", 1.0))
	critic_fatigue = {}
	var fat_in: Dictionary = d.get("critic_fatigue", {})
	for k in fat_in:
		critic_fatigue[StringName(String(k))] = int(fat_in[k])
	trend = StringName(String(d.get("trend", "")))
	if trend == &"":
		_roll_trend()
	message = ""
	return true

func _node_from_dict(n: Dictionary) -> Dictionary:
	var ens: Array = []
	for e in n.get("enemies", []):
		ens.append(StringName(String(e)))
	var links: Array = []
	for l in n.get("links", []):
		links.append(int(l))
	var nd := {
		"type": String(n.get("type", "Combat")), "row": int(n.get("row", 0)),
		"col": int(n.get("col", 0)), "links": links, "enemies": ens,
		"visited": bool(n.get("visited", false)),
	}
	if n.has("critic_bonus_gold"):
		nd["critic_bonus_gold"] = int(n["critic_bonus_gold"])
	if n.has("critic_note"):
		nd["critic_note"] = String(n["critic_note"])
	return nd

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
	_meta_from_dict(data)

## Payload half of load_meta — kept separate so tests can round-trip the save
## format in memory without touching the real user://save.json.
func _meta_from_dict(data: Dictionary) -> void:
	unlocked_outfits.clear()
	for o in data.get("unlocked_outfits", []):
		unlocked_outfits.append(StringName(o))
	for slot in data.get("equipped", {}):
		equipped[slot] = StringName(data["equipped"][slot])
	clout = int(data.get("clout", 0))
	# legacy saves: treat current Clout as already-earned so nothing re-locks
	clout_earned = int(data.get("clout_earned", clout))
	ascension = int(data.get("ascension", 0))
	critic_score = int(data.get("critic_score", 0))
	sfx_on = bool(data.get("sfx_on", true))
	music_on = bool(data.get("music_on", true))
	locale = String(data.get("locale", "en"))
	seen_tutorial = bool(data.get("seen_tutorial", false))
	fullscreen_on = bool(data.get("fullscreen_on", false))
	effects_on = bool(data.get("effects_on", true))
	music_vol = clampf(float(data.get("music_vol", 1.0)), 0.0, 1.0)
	sfx_vol = clampf(float(data.get("sfx_vol", 1.0)), 0.0, 1.0)
	var run: Variant = data.get("run", {})
	_run_snapshot = run if typeof(run) == TYPE_DICTIONARY else {}

func save_meta() -> void:
	if OS.has_environment("PW_NO_SAVE"):
		return   # dev tools / CI runs must never touch the real save file
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("[GameState] could not open save file for writing")
		return
	f.store_string(JSON.stringify(_meta_to_dict(), "\t"))

func _meta_to_dict() -> Dictionary:
	var owned: Array[String] = []
	for id in unlocked_outfits:
		owned.append(String(id))
	var eq := {}
	for slot in equipped:
		eq[slot] = String(equipped[slot])
	var payload := {"save_version": SAVE_VERSION, "unlocked_outfits": owned, "equipped": eq, "clout": clout, "clout_earned": clout_earned, "ascension": ascension, "critic_score": critic_score, "sfx_on": sfx_on, "music_on": music_on, "locale": locale, "seen_tutorial": seen_tutorial, "fullscreen_on": fullscreen_on, "effects_on": effects_on, "music_vol": music_vol, "sfx_vol": sfx_vol}
	if not _run_snapshot.is_empty():
		payload["run"] = _run_snapshot
	return payload
