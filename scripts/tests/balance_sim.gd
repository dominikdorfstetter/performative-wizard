extends Node
## Headless balance playtest. A heuristic bot plays thousands of real combats through the
## actual CombatManager across acts / ascension / the whole roster, plus a drift-economy
## experiment that stress-tests the Critic's anti-solve (P2). Prints a metrics report.
##
## Run: godot --headless scenes/balance_sim.tscn

const FIN_IDS := [&"grand_finale", &"take_a_bow", &"encore_for_fans", &"soak_it_in"]
const K := 200          # samples per config

var _rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# Bot policy
# ---------------------------------------------------------------------------

func _is_finisher(card: CardData) -> bool:
	for e in card.effects:
		if String(e.get("op", "")).begins_with("finisher"):
			return true
	return false

func _is_block(card: CardData) -> bool:
	for e in card.effects:
		if String(e.get("op", "")) == "block":
			return true
	return false

func _est_damage(card: CardData, cm: CombatManager) -> int:
	var d := 0
	for e in card.effects:
		var op := String(e.get("op", ""))
		if op == "damage" or op == "damage_all":
			d += int(e.get("amount", 0))
		elif op == "damage_if_status":
			d += int(e.get("amount", 0)) + int(e.get("bonus", 0)) / 2
		elif op == "damage_x_burn":
			d += 5
	if d > 0:
		d += cm.swag_damage_bonus()
	return d

func _est_finisher(card: CardData, cm: CombatManager) -> int:
	var boost := 1.5 if cm.has_passive(&"finisher_boost") else 1.0
	for e in card.effects:
		match String(e.get("op", "")):
			"finisher_swag_x3": return int(cm.swag * 3 * boost)
			"finisher_encore": return int(cm.swag * (2 + cm.encore) * boost)
			"finisher_spread": return int(cm.swag * 1.5 * boost)
			"finisher_drain": return int(cm.swag * 2 * boost)
	return 0

func _incoming(cm: CombatManager) -> int:
	var dmg := 0
	for e in cm.living_enemies():
		var it := cm.peek_intent(e)
		if String(it.get("op", "")) == "attack":
			var amt := int(round(int(it.get("amount", 0)) * cm.enemy_dmg_scale))
			dmg += amt * max(1, int(it.get("hits", 1)))
	return dmg

func _set_focus(cm: CombatManager) -> void:
	var bi := -1
	var bh := 1 << 30
	for i in cm.enemies.size():
		var e: Combatant = cm.enemies[i]
		if not e.is_dead() and e.hp < bh:
			bh = e.hp
			bi = i
	if bi >= 0:
		cm.set_target(bi)

func _pick_finisher(fins: Array, policy: String, fight_idx: int, cm: CombatManager) -> CardData:
	match policy:
		"spammer":
			for c in fins:
				if c.id == &"grand_finale":
					return c
			return fins[0]
		"varied":
			return fins[fight_idx % fins.size()]
		_:
			var best: CardData = fins[0]
			var bd := -1
			for c in fins:
				var d := _est_finisher(c, cm)
				if d > bd:
					bd = d
					best = c
			return best

func _choose_card(cm: CombatManager, policy: String, fight_idx: int) -> CardData:
	var playable: Array[CardData] = []
	for c in cm.hand:
		if cm.can_play(c):
			playable.append(c)
	if playable.is_empty():
		return null
	var focus := cm.target()
	var fins := playable.filter(_is_finisher)
	if not fins.is_empty() and focus != null:
		var fin := _pick_finisher(fins, policy, fight_idx, cm)
		var fd := _est_finisher(fin, cm)
		var dump := false
		match policy:
			"spammer": dump = cm.swag >= 18
			"hoarder": dump = fd >= cm._total_enemy_hp() or cm.swag >= 40
			"varied": dump = fd >= focus.hp or cm.swag >= 26
			"flash": dump = fd >= focus.hp or cm.swag >= 30   # hoard hard for the boosted burst
			_: dump = fd >= focus.hp or cm.swag >= 28
		if dump:
			return fin
	if _incoming(cm) > cm.player.block + 6:
		for c in playable:
			if _is_block(c):
				return c
	# Flash playstyle: hoard the spotlight — prefer building Aura (Pose) over chipping,
	# so the big boosted finisher is realized AND a bold tell (encore/flex) accrues.
	if policy == "flash" and cm.swag < 30:
		var bp: CardData = null
		var bg := 0
		for c in playable:
			if _is_finisher(c):
				continue
			if c.swag_gain > bg:
				bg = c.swag_gain
				bp = c
		if bp != null and bg > 0:
			return bp
	var best: CardData = null
	var bestd := 0
	for c in playable:
		if _is_finisher(c):
			continue
		var d := _est_damage(c, cm)
		if d > bestd:
			bestd = d
			best = c
	if best != null and bestd > 0:
		return best
	var bs: CardData = null
	var bsg := -1
	for c in playable:
		if _is_finisher(c):
			continue
		if c.swag_gain > bsg:
			bsg = c.swag_gain
			bs = c
	if bs != null:
		return bs
	return playable[0]

func _bot_turn(cm: CombatManager, policy: String, fight_idx: int) -> void:
	var g := 0
	while cm.state == CombatManager.State.PLAYER_TURN and g < 30:
		g += 1
		_set_focus(cm)
		var card := _choose_card(cm, policy, fight_idx)
		if card == null:
			break
		cm.play_card(card)
	if cm.state == CombatManager.State.PLAYER_TURN:
		cm.end_turn()

# ---------------------------------------------------------------------------
# Single combat
# ---------------------------------------------------------------------------

func _scales(act: int, asc: int, type: String, row: int) -> Array:
	# MUST mirror GameState.node_scales() exactly, or the report silently lies.
	var hp := 1.0 + 0.30 * (act - 1) + 0.08 * asc
	var dmg := 1.0 + 0.17 * (act - 1) + 0.05 * asc
	if type == "Boss":
		return [hp, dmg]
	return [hp + 0.07 * row, dmg + 0.05 * row]

func _sim_combat(wid: StringName, enc_ids: Array, deck_ids: Array, drip: int, passives: Array, hp_scale: float, dmg_scale: float, policy: String, fight_idx: int, start_hp: int) -> Dictionary:
	var w := Database.get_wizard(wid)
	var p := Combatant.new()
	p.max_hp = w.max_hp
	p.hp = start_hp if start_hp > 0 else w.max_hp
	var enc: Array = []
	for id in enc_ids:
		var ed := Database.get_enemy(id)
		if ed != null:
			enc.append(ed)
	var deck: Array[CardData] = []
	for id in deck_ids:
		var c := Database.get_card(id)
		if c != null:
			deck.append(c)
	var pp: Array[StringName] = []
	for x in passives:
		pp.append(x)
	var cm := CombatManager.new()
	cm.start_combat(p, enc, deck, drip, false, pp, hp_scale, dmg_scale)
	var encore_max := 0
	var booed := 0
	var g := 0
	while cm.state == CombatManager.State.PLAYER_TURN and g < 80:
		encore_max = max(encore_max, cm.encore)
		if cm.booed:
			booed += 1
		_bot_turn(cm, policy, fight_idx)
		g += 1
	return {
		"win": cm.state == CombatManager.State.WIN,
		"turns": cm.turn,
		"hp_left": p.hp,
		"max_hp": p.max_hp,
		"rating": cm.compute_show_rating(),
		"encore_max": encore_max,
		"booed": booed,
	}

# ---------------------------------------------------------------------------
# Deck building
# ---------------------------------------------------------------------------

func _build_deck(wid: StringName, act: int) -> Array:
	var w := Database.get_wizard(wid)
	var deck: Array = w.starter_deck.duplicate()
	var adds: Array = []
	for id in w.reward_pool:
		if id not in FIN_IDS and Database.get_card(id) != null:
			adds.append(id)
	for i in range(act * 2):
		if adds.size() > 0:
			deck.append(adds[i % adds.size()])
	deck.append(&"grand_finale")
	if act >= 2:
		deck.append(&"take_a_bow")
	if act >= 3:
		deck.append(&"soak_it_in")
	return deck

# ---------------------------------------------------------------------------
# Sweeps
# ---------------------------------------------------------------------------

func _agg(results: Array) -> Dictionary:
	var wins := 0
	var turns := 0.0
	var hp_lost := 0.0
	var ratings := {"S": 0, "A": 0, "B": 0, "C": 0}
	var booed := 0
	var enc_max := 0
	for r in results:
		if r.win:
			wins += 1
		turns += r.turns
		hp_lost += 100.0 * (r.max_hp - r.hp_left) / float(r.max_hp)
		ratings[String(r.rating.rating)] += 1
		booed += r.booed
		enc_max = max(enc_max, r.encore_max)
	var n: float = max(1, results.size())
	return {
		"n": results.size(),
		"win_pct": round(100.0 * wins / n),
		"avg_turns": snappedf(turns / n, 0.1),
		"avg_hp_lost_pct": round(hp_lost / n),
		"ratings": ratings,
		"booed_total": booed,
		"encore_peak": enc_max,
	}

func _sweep(label: String, wid: StringName, enc_kind: String, act: int, asc: int, depth: float) -> void:
	var deck := _build_deck(wid, act)
	var drip: int = [0, 3, 4, 5][act]
	var results: Array = []
	for i in K:
		var enc_ids: Array
		match enc_kind:
			"elite": enc_ids = Encounters.elite(_rng)
			"boss": enc_ids = Encounters.boss(_rng)
			_: enc_ids = Encounters.normal(depth, _rng)
		var row := int(depth * 9)
		var sc := _scales(act, asc, "Boss" if enc_kind == "boss" else ("Elite" if enc_kind == "elite" else "Combat"), row)
		results.append(_sim_combat(wid, enc_ids, deck, drip, [], sc[0], sc[1], "balanced", i, 0))
	var a := _agg(results)
	print("  %-22s win %3d%%  turns %4.1f  hp-lost %3d%%  S/A/B/C %d/%d/%d/%d  booed %d  encorePk %d" % [
		label, a.win_pct, a.avg_turns, a.avg_hp_lost_pct,
		a.ratings.S, a.ratings.A, a.ratings.B, a.ratings.C, a.booed_total, a.encore_peak])

func _attrition(wid: StringName, act: int, asc: int) -> void:
	# chained normal fights, HP carries over (no heal). How many before death?
	var deck := _build_deck(wid, act)
	var drip: int = [0, 3, 4, 5][act]
	var depth: float = [0.0, 0.25, 0.55, 0.85][act]
	var survived_sum := 0.0
	var deaths := 0
	for run in K:
		var w := Database.get_wizard(wid)
		var hp := w.max_hp
		var fights := 0
		for f in 8:
			var enc_ids := Encounters.normal(depth, _rng)
			var sc := _scales(act, asc, "Combat", int(depth * 9))
			var r := _sim_combat(wid, enc_ids, deck, drip, [], sc[0], sc[1], "balanced", f, hp)
			if r.win:
				fights += 1
				hp = r.hp_left + int(0.12 * r.max_hp)   # ~rest/chip recovery between rooms
				hp = min(hp, r.max_hp)
			else:
				deaths += 1
				break
		survived_sum += fights
	print("  %s act%d asc%d:  avg %.1f/8 fights survived,  death rate %d%%" % [
		wid, act, asc, survived_sum / K, round(100.0 * deaths / K)])

func _drift_experiment(sigs: Array) -> Dictionary:
	GameState.critic_fatigue = {}
	GameState.pending_critic = ""
	var saved_cs: int = GameState.critic_score
	GameState.critic_score = 0
	var total_vip := 0
	var log: Array = []
	for sig in sigs:
		GameState.record_show_rating({"rating": "S", "signature": sig})
		var node := {"type": "Combat", "enemies": [&"alley_cat"]}
		GameState.apply_critic_mutation(node)
		var g := int(node.get("critic_bonus_gold", 0))
		total_vip += g
		log.append("%s fresh=%.2f vip=%d" % [String(sig), GameState.critic_last_freshness, g])
	GameState.critic_score = saved_cs
	GameState.critic_fatigue = {}
	GameState.pending_critic = ""
	return {"total_vip": total_vip, "log": log}

# ---------------------------------------------------------------------------

func _ready() -> void:
	_rng.seed = 1234567
	print("=== PERFORMATIVE WIZARD — balance playtest (K=%d/config) ===" % K)

	for wid in [&"fire", &"necro", &"rizz"]:
		print("\n## %s — difficulty sweep (balanced bot, full HP)" % wid)
		_sweep("act1 normal asc0", wid, "normal", 1, 0, 0.2)
		_sweep("act2 normal asc0", wid, "normal", 2, 0, 0.5)
		_sweep("act3 normal asc0", wid, "normal", 3, 0, 0.85)
		_sweep("act1 elite  asc0", wid, "elite", 1, 0, 0.3)
		_sweep("act2 elite  asc0", wid, "elite", 2, 0, 0.5)
		_sweep("act3 elite  asc0", wid, "elite", 3, 0, 0.85)
		_sweep("act3 boss   asc0", wid, "boss", 3, 0, 1.0)
		_sweep("act3 normal asc4", wid, "normal", 3, 4, 0.85)
		_sweep("act3 boss   asc8", wid, "boss", 3, 8, 1.0)

	print("\n## Attrition (chained fights, HP carries)")
	for wid in [&"fire", &"necro", &"rizz"]:
		_attrition(wid, 1, 0)
		_attrition(wid, 2, 0)
		_attrition(wid, 3, 0)
		_attrition(wid, 3, 4)

	print("\n## Critic drift anti-solve (P2): VIP gold over an 8-fight run")
	var spam := _drift_experiment([&"swag_x3", &"swag_x3", &"swag_x3", &"swag_x3", &"swag_x3", &"swag_x3", &"swag_x3", &"swag_x3"])
	var vary := _drift_experiment([&"swag_x3", &"encore", &"spread", &"drain", &"swag_x3", &"encore", &"spread", &"drain"])
	print("  spammer (same finish ×8):  total VIP gold = %d" % spam.total_vip)
	for l in spam.log:
		print("      " + l)
	print("  varied (4 finishers cycled): total VIP gold = %d" % vary.total_vip)
	for l in vary.log:
		print("      " + l)

	print("\n## Flash vs slow-burn persona (act2 normal, fair drip + hoard policy)")
	_persona("flash  drip5 +boost  HOARD ", &"fire", 2, ["finisher_boost"], 5, "flash")
	_persona("flash  drip5 +boost  balncd", &"fire", 2, ["finisher_boost"], 5, "balanced")
	_persona("slowbn drip7         balncd", &"fire", 2, [], 7, "balanced")

	print("\n=== done ===")
	get_tree().quit(0)

func _persona(label: String, wid: StringName, act: int, passives: Array, drip: int, policy: String) -> void:
	var deck := _build_deck(wid, act)
	var results: Array = []
	for i in K:
		var enc_ids := Encounters.normal(0.5, _rng)
		var sc := _scales(act, 0, "Combat", 4)
		results.append(_sim_combat(wid, enc_ids, deck, drip, passives, sc[0], sc[1], policy, i, 0))
	var a := _agg(results)
	print("  %s  win %3d%%  turns %4.1f  hp-lost %3d%%  S/A/B/C %d/%d/%d/%d" % [
		label, a.win_pct, a.avg_turns, a.avg_hp_lost_pct, a.ratings.S, a.ratings.A, a.ratings.B, a.ratings.C])
