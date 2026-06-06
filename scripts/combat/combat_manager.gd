class_name CombatManager
extends RefCounted
## The combat engine: turn loop, energy, banked-Swag economy, draw/discard, an encounter
## of one-or-more enemies with their own intents, targeting, and win/lose. Pure logic
## (no UI) so it can be unit-tested headless. A view connects to `changed` and re-renders.

signal changed
signal combat_ended(victory: bool)

enum State { PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

const HAND_SIZE := 5
const MAX_ENERGY := 3
const LOG_KEEP := 6

const THRESHOLD_DAMAGE := 6
const THRESHOLD_DRAW := 12
const THRESHOLD_PIERCE := 18
const SWAG_DAMAGE_BONUS := 2

# Gen-Z display names for the internal status keywords.
const _DISP := {&"strength": "Rizz", &"vulnerable": "Cooked", &"weak": "Mid", &"burn": "Roasted", &"undead": "Goons", &"jinx": "Jinxed", &"frail": "Exposed", &"poison": "Toxic"}

var state: State = State.PLAYER_TURN
var player: Combatant
var enemies: Array[Combatant] = []
var target_index := 0
var turn := 0

var energy := 0
var max_energy := MAX_ENERGY
var swag := 0
var drip := 0
var spells_this_turn := 0

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var passives: Array[StringName] = []
var enemy_dmg_scale := 1.0
var crit_chance := 0.0
var last_crit := false
var log_lines: Array[String] = []

# --- setup ---------------------------------------------------------------

func start_combat(p: Combatant, encounter: Array, deck: Array[CardData], drip_value: int, deterministic := false, outfit_passives: Array[StringName] = [], hp_scale := 1.0, dmg_scale := 1.0) -> void:
	player = p
	enemies.clear()
	for edata in encounter:
		var e := Combatant.new()
		e.display_name = edata.title
		e.data = edata
		e.max_hp = int(round(edata.max_hp * hp_scale))
		e.hp = e.max_hp
		enemies.append(e)
	target_index = 0
	enemy_dmg_scale = dmg_scale
	drip = drip_value
	passives = outfit_passives
	_compute_crit()
	draw_pile = deck.duplicate()
	if not deterministic:
		randomize()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	turn = 0
	log_lines.clear()
	state = State.PLAYER_TURN
	_apply_combat_start_passives()
	var names := []
	for e in enemies:
		names.append(e.display_name)
	_say("the opps pulled up: %s" % ", ".join(names))
	_start_player_turn()

func has_passive(id: StringName) -> bool:
	return id in passives

# Crit chance from passives named "crit_<percent>" (e.g. crit_15 = +15%).
func _compute_crit() -> void:
	crit_chance = 0.0
	for p in passives:
		var s := String(p)
		if s.begins_with("crit_"):
			crit_chance += float(s.substr(5)) / 100.0

# Current crit chance including The Rizzard's dynamic Rizz scaling.
func live_crit_chance() -> float:
	var cc := crit_chance
	if has_passive(&"rizz_crit"):
		cc += player.status(&"strength") * 0.06
	cc -= player.status(&"jinx") * 0.10
	return max(0.0, cc)

func _apply_combat_start_passives() -> void:
	if has_passive(&"energy_plus_1"):
		max_energy += 1
	if has_passive(&"start_block_5"):
		player.block += 5
	if has_passive(&"swag_start_3"):
		swag += 3
	# artefact passives
	if has_passive(&"swag_income_2"):
		drip += 2
	if has_passive(&"strength_start_2"):
		player.add_status(&"strength", 2)
	if has_passive(&"enemies_start_vulnerable"):
		for e in enemies:
			e.add_status(&"vulnerable", 1)

# --- targeting -----------------------------------------------------------

func living_enemies() -> Array[Combatant]:
	return enemies.filter(func(e): return not e.is_dead())

func target() -> Combatant:
	if target_index < enemies.size() and not enemies[target_index].is_dead():
		return enemies[target_index]
	for i in enemies.size():
		if not enemies[i].is_dead():
			target_index = i
			return enemies[i]
	return null

func set_target(i: int) -> void:
	if i >= 0 and i < enemies.size() and not enemies[i].is_dead():
		target_index = i
		_emit()

func all_dead() -> bool:
	return living_enemies().is_empty()

# --- Swag economy --------------------------------------------------------

func gain_swag(amount: int) -> void:
	swag = max(0, swag + amount)

func swag_damage_bonus() -> int:
	return SWAG_DAMAGE_BONUS if swag >= THRESHOLD_DAMAGE else 0

func swag_extra_draw() -> int:
	return 1 if swag >= THRESHOLD_DRAW else 0

func swag_pierces() -> bool:
	return swag >= THRESHOLD_PIERCE

# --- turn loop -----------------------------------------------------------

func _start_player_turn() -> void:
	state = State.PLAYER_TURN
	spells_this_turn = 0
	turn += 1
	var pois := _tick_poison(player)
	if pois > 0:
		_say("you're Toxic'd for %d" % pois)
		if player.is_dead():
			_finish(false)
			return
	energy = max_energy
	var before := swag
	gain_swag(drip)
	_tick_powers()
	if has_passive(&"strength_at_10_swag") and swag >= THRESHOLD_DRAW:
		player.add_status(&"strength", 1)
		_say("Catwalk Heels: +1 Rizz")
	if has_passive(&"heal_3_per_turn") and turn > 1:
		player.heal(3)
	var draw_n := HAND_SIZE + swag_extra_draw()
	if has_passive(&"draw_plus_1"):
		draw_n += 1
	_draw(draw_n)
	if drip > 0:
		_say("— Your turn %d  (+%d aura → %d) —" % [turn, swag - before, swag])
	else:
		_say("— Your turn %d —" % turn)
	_emit()

## Persistent Power-card effects, applied at the start of each player turn.
func _tick_powers() -> void:
	var ritual := player.status(&"ritual")          # ramp Rizz each turn
	if ritual > 0:
		player.add_status(&"strength", ritual)
		_say("locked in: +%d Rizz" % ritual)
	var engine := player.status(&"aura_engine")      # bonus Aura each turn
	if engine > 0:
		gain_swag(engine)
	var hive := player.status(&"hive_mind")          # raise goons each turn
	if hive > 0:
		player.add_status(&"undead", hive)
		_say("the squad multiplies: +%d Goon" % hive)
	var barrier := player.status(&"barrier")         # standing Block each turn
	if barrier > 0:
		player.block += barrier

func can_play(card: CardData) -> bool:
	return state == State.PLAYER_TURN and energy >= card.cost

func play_card(card: CardData) -> bool:
	if not can_play(card) or card not in hand:
		return false
	energy -= card.cost
	hand.erase(card)
	discard_pile.append(card)

	var swag0 := swag
	if card.swag_gain > 0:
		gain_swag(card.swag_gain)
		if has_passive(&"pose_plus_1"):
			gain_swag(1)

	var tgt := target()
	var is_attack := card.type == "Attack"
	var first_spell := spells_this_turn == 0
	var pierced := is_attack and first_spell and swag_pierces()
	var atk_bonus := swag_damage_bonus() if is_attack else 0
	if is_attack and first_spell and has_passive(&"first_spell_plus_3"):
		atk_bonus += 3
	last_crit = is_attack and randf() < live_crit_chance()
	var ctx := {
		"source": player,
		"target": tgt,
		"enemies": enemies,
		"combat": self,
		"passives": passives,
		"bonus_damage": atk_bonus,
		"pierce": pierced,
		"crit": last_crit,
	}

	var hp0 := _total_enemy_hp()
	var pblk0 := player.block
	var tburn0 := tgt.status(&"burn") if tgt != null else 0

	var enemy_hp_before: Array = []
	for e in enemies:
		enemy_hp_before.append(e.hp)

	var normal: Array = []
	for e in card.effects:
		if String(e.get("op", "")).begins_with("finisher"):
			_resolve_finisher(e, ctx)
		else:
			normal.append(e)
	EffectResolver.apply(normal, ctx)

	# Enrage: an enemy that got hit this card gains Strength.
	for i in enemies.size():
		var en := enemies[i]
		if not en.is_dead() and en.data != null and en.data.enrage > 0 and en.hp < int(enemy_hp_before[i]):
			en.add_status(&"strength", en.data.enrage)
			_say("%s is ENRAGED → +%d Rizz" % [en.display_name, en.data.enrage])

	if is_attack:
		spells_this_turn += 1

	var tburn1 := tgt.status(&"burn") if tgt != null else 0
	if last_crit:
		_say("✦ CRIT! that's lethal rizz ✦")
	_log_card(card, hp0 - _total_enemy_hp(), player.block - pblk0, tburn1 - tburn0, swag - swag0, pierced)
	if all_dead():
		_finish(true)
	_emit()
	return true

func _resolve_finisher(e: Dictionary, ctx: Dictionary) -> void:
	var tgt: Combatant = ctx.get("target")
	if tgt == null:
		return
	match String(e.get("op", "")):
		"finisher_swag_x3":
			var raw := swag * 3 + int(ctx.get("bonus_damage", 0))
			var dmg := EffectResolver.compute_damage(raw, player, tgt)
			if ctx.get("crit", false):
				dmg *= 2
			tgt.take_damage(dmg, ctx.get("pierce", false))
			swag = 0
		_:
			push_warning("[CombatManager] unknown finisher: " + String(e.get("op", "")))

func end_turn() -> void:
	if state != State.PLAYER_TURN:
		return
	discard_pile.append_array(hand)
	hand.clear()
	var undead := player.status(&"undead")
	if undead > 0:
		var tgt := target()
		if tgt != null:
			tgt.take_damage(undead * 2)
			_say("your %d Goons threw hands for %d" % [undead, undead * 2])
			if all_dead():
				_finish(true)
				return
	player.block = 0
	_decay(player)
	_enemy_turn()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	_emit()
	for e in enemies:
		if e.is_dead():
			continue
		var burned := _tick_burn(e)
		if burned > 0:
			_say("%s got Roasted for %d" % [e.display_name, burned])
		var poisoned := _tick_poison(e)
		if poisoned > 0:
			_say("%s is Toxic'd for %d" % [e.display_name, poisoned])
		if e.is_dead():
			continue
		if e.data == null or e.data.intents.is_empty():
			continue
		var intent: Dictionary = e.data.intents[e.intent_index % e.data.intents.size()]
		_resolve_intent(e, intent)
		e.intent_index += 1
		_decay(e)
		e.block = 0
		if player.is_dead():
			_finish(false)
			return
	if all_dead():
		_finish(true)
		return
	_start_player_turn()

func _resolve_intent(src: Combatant, intent: Dictionary) -> void:
	var amount := int(intent.get("amount", 0))
	var name := src.display_name
	match String(intent.get("op", "")):
		"attack":
			var hits: int = max(1, int(intent.get("hits", 1)))
			var dmg := int(round(amount * enemy_dmg_scale))
			var hp0 := player.hp
			for _h in hits:
				player.take_damage(EffectResolver.compute_damage(dmg, src, player))
			if hits > 1:
				_say("%s went off — %d×%d (%d)" % [name, dmg, hits, hp0 - player.hp])
			else:
				_say("%s threw hands for %d" % [name, hp0 - player.hp])
			if not src.is_dead() and has_passive(&"thorns_3"):
				src.take_damage(3)
				_say("thorns! %s caught a fade for 3" % name)
		"heal":
			var before := src.hp
			src.heal(amount)
			_say("%s restocked %d HP" % [name, src.hp - before])
		"block":
			src.block += amount
			_say("%s is being unbothered (Block %d)" % [name, amount])
		"apply_status":
			var s := StringName(intent.get("status", &""))
			player.add_status(s, amount)
			_say("%s hit you with %s %d" % [name, _disp(s), amount])
		"buff":
			var s2 := StringName(intent.get("status", &""))
			src.add_status(s2, amount)
			_say("%s locked in: %s +%d" % [name, _disp(s2), amount])
		"drain_swag":
			var before := swag
			swag = max(0, swag - amount)
			_say("%s drained %d of your Aura 😤" % [name, before - swag])
		_:
			push_warning("[CombatManager] unknown intent: " + String(intent.get("op", "")))

func peek_intent(e: Combatant) -> Dictionary:
	if e == null or e.data == null or e.data.intents.is_empty():
		return {}
	return e.data.intents[e.intent_index % e.data.intents.size()]

# --- helpers -------------------------------------------------------------

func _total_enemy_hp() -> int:
	var t := 0
	for e in enemies:
		t += e.hp
	return t

func _tick_burn(c: Combatant) -> int:
	var b := c.status(&"burn")
	if b <= 0:
		return 0
	c.take_damage(b, true)
	if b - 1 <= 0:
		c.statuses.erase(&"burn")
	else:
		c.statuses[&"burn"] = b - 1
	return b

# Poison: deal stacks as unblockable damage at the victim's turn start, then ramp down 1.
func _tick_poison(c: Combatant) -> int:
	var p := c.status(&"poison")
	if p <= 0:
		return 0
	c.take_damage(p, true)
	if p - 1 <= 0:
		c.statuses.erase(&"poison")
	else:
		c.statuses[&"poison"] = p - 1
	return p

func _decay(c: Combatant) -> void:
	for s in [&"weak", &"vulnerable", &"jinx", &"frail"]:
		var v := c.status(s)
		if v > 0:
			if v - 1 <= 0:
				c.statuses.erase(s)
			else:
				c.statuses[s] = v - 1

func draw_cards(n: int) -> void:
	_draw(n)

func _draw(n: int) -> void:
	for i in n:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func _log_card(card: CardData, dmg: int, blk: int, burn_added: int, swag_delta: int, pierced: bool) -> void:
	var parts: Array[String] = []
	if dmg > 0:
		parts.append("%d dmg" % dmg)
	if blk > 0:
		parts.append("%d block" % blk)
	if burn_added > 0:
		parts.append("%d burn" % burn_added)
	if swag_delta > 0:
		parts.append("+%d aura" % swag_delta)
	elif swag_delta < 0:
		parts.append("spent %d aura" % -swag_delta)
	if pierced and dmg > 0:
		parts.append("pierced!")
	var msg := "You play %s" % card.title
	if not parts.is_empty():
		msg += "  →  " + ", ".join(parts)
	_say(msg)

func _finish(victory: bool) -> void:
	state = State.WIN if victory else State.LOSE
	_say("✦ BIG W ✦" if victory else "you took an L 💀")
	# Emit the final UI update first (death poofs/popups run while the combat scene
	# is still in the tree), THEN signal the end — which may change scene and detach us.
	_emit()
	combat_ended.emit(victory)

func _disp(s: StringName) -> String:
	return _DISP.get(s, String(s).capitalize())

func _say(msg: String) -> void:
	log_lines.append(msg)
	while log_lines.size() > LOG_KEEP:
		log_lines.pop_front()

func _emit() -> void:
	changed.emit()
