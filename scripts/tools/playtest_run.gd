extends Node
## Dev tool: full 3-act bot playtest through the REAL run state machine — map
## navigation, every node type, real combats (driven by the balance-sim bot),
## critic ratings + room mutations, IRS gold flow, thematic boss transitions.
## Plays one complete run per wizard and fails loudly on any broken invariant.
##   PW_NO_SAVE=1 godot --headless scenes/tools/playtest_run.tscn

const SimBot = preload("res://scripts/tests/balance_sim.gd")

var _fails := 0
var _act_cast := {}    # act -> {id: true} — every enemy id allowed on that floor

func _ready() -> void:
	for act in [1, 2, 3]:
		var ids := {}
		for stage in ["early", "mid", "late"]:
			for grp in Encounters.NORMAL[act][stage]:
				for id in grp:
					ids[id] = true
		for grp in Encounters.ELITE[act]:
			for id in grp:
				ids[id] = true
		# headliners + everything that can be SUMMONED into a fight on this floor
		for s in [&"the_critic", &"the_bouncer", &"the_algorithm", &"the_talent_agent",
				&"heckler", &"sock_puppet", &"critic_jr", &"bouncer_jr", &"algo_jr",
				&"rabid_roomba", &"goon"]:
			ids[s] = true
		_act_cast[act] = ids
	var i := 0
	for wid: StringName in [&"fire", &"necro", &"rizz"]:
		for s in 3:
			seed(1337 + i * 100 + s)
			_play_run(wid)
		i += 1
	# act-entry sweeps: drop in at act 2/3 with an act-grown loadout, so the later
	# floors (the Bouncer, the Feed cast, the Algorithm/Talent Agent) get exercised
	# even when the bot can't climb the whole tower in one life.
	for act_in in [2, 3]:
		for wid: StringName in [&"fire", &"necro", &"rizz"]:
			for s in 2:
				seed(9000 + act_in * 100 + i * 10 + s)
				_play_run(wid, act_in)
			i += 1
	print("\n=== playtest: %s ===" % ("ALL RUNS OK" if _fails == 0 else "%d FAILURES" % _fails))
	get_tree().quit(1 if _fails > 0 else 0)

func _fail(msg: String) -> void:
	_fails += 1
	print("  !! FAIL: " + msg)

func _play_run(wid: StringName, start_act := 1) -> void:
	print("\n#### RUN: %s (from act %d) ####" % [wid, start_act])
	var bot = SimBot.new()
	GameState.new_game()
	GameState.start_run(wid)
	GameState.finalize_loadout()
	if start_act > 1:
		# fast-forward: an act-appropriate deck, purse and relic count, fresh HP
		GameState.act = start_act
		GameState.map = MapGenerator.generate(randi(), start_act)
		GameState.pos_row = -1
		GameState.pos_col = -1
		var w := Database.get_wizard(wid)
		var pool := GameState.unlocked_cards(w.reward_pool)
		for k in range(start_act * 3):
			if pool.size() > 0:
				GameState.deck.append(pool[randi() % pool.size()])
		GameState.gold += 60 * (start_act - 1)
		for k in range(start_act - 1):
			var aid := GameState.random_unowned_artifact()
			if aid != &"":
				GameState.add_artifact(aid)
	var fight_idx := 0
	var ratings := {"S": 0, "A": 0, "B": 0, "C": 0}
	var guard := 0
	while guard < 200:
		guard += 1
		var avail := GameState.available()
		if avail.is_empty():
			_fail("no available nodes (act %d, row %d)" % [GameState.act, GameState.pos_row])
			bot.free()
			return
		var node: Dictionary = _pick_node(avail)
		GameState.enter(int(node.row), int(node.col))
		node = GameState.current_node()
		var t := String(node.type)
		match t:
			"Combat", "Elite", "Boss":
				fight_idx += 1
				var won := _fight(node, bot, fight_idx, ratings)
				if not won:
					print("  -- DEFEAT in act %d vs %s — run over (a loss is a valid outcome)" % [GameState.act, _enc_str(node)])
					GameState.finish_run(false)
					bot.free()
					return
				if t == "Boss":
					if GameState.advance_act():
						print("  >> ACT %d — %s" % [GameState.act, GameState.trend_label()])
					else:
						GameState.finish_run(true)
						print("  ** FULL 3-ACT CLEAR — hp %d/%d, gold %d, deck %d, relics %d, grades S/A/B/C %d/%d/%d/%d" % [
							GameState.player_hp, GameState.player_max_hp, GameState.gold,
							GameState.deck.size(), GameState.run_artifacts.size(),
							ratings.S, ratings.A, ratings.B, ratings.C])
						bot.free()
						return
			"Shop":
				_shop()
			"Rest":
				_rest()
			"Chest":
				_chest()
			"Event":
				print("  ~ event (skipped — UI-driven choices)")
			_:
				_fail("unknown node type '%s'" % t)
		if GameState.gold < 0:
			_fail("gold went negative (%d)" % GameState.gold)
		if GameState.player_hp <= 0 or GameState.player_hp > GameState.player_max_hp:
			_fail("hp out of bounds (%d/%d)" % [GameState.player_hp, GameState.player_max_hp])
	_fail("run guard tripped — map walk did not terminate")
	bot.free()

## Minimal human competence: rest when hurting, avoid elites when weak,
## otherwise wander — enough variety to hit every node type.
func _pick_node(avail: Array) -> Dictionary:
	var hp_frac := float(GameState.player_hp) / GameState.player_max_hp
	for n in avail:
		if String(n.type) == "Rest" and hp_frac < 0.65:
			return n
	if hp_frac < 0.6:
		var safe := avail.filter(func(n): return String(n.type) != "Elite")
		if not safe.is_empty():
			return safe[randi() % safe.size()]
	return avail[randi() % avail.size()]

func _fight(node: Dictionary, bot, fight_idx: int, ratings: Dictionary) -> bool:
	var t := String(node.type)
	var act := GameState.act
	if t == "Boss":
		var want: Array = [[&"the_critic"], [&"the_bouncer"], [&"the_algorithm", &"the_talent_agent"]][act - 1]
		if not (node.enemies[0] in want):
			_fail("act %d boss is %s — off-theme" % [act, node.enemies[0]])
	var enc: Array = []
	for id in node.enemies:
		var ed := Database.get_enemy(id)
		if ed == null:
			_fail("unknown enemy id %s" % id)
			continue
		if not _act_cast[act].has(id):
			_fail("enemy %s is off-theme for act %d" % [id, act])
		enc.append(ed)
	var sc := GameState.node_scales(node)
	var p := Combatant.new()
	p.max_hp = GameState.player_max_hp
	p.hp = GameState.player_hp
	var deck: Array[CardData] = []
	for id in GameState.deck:
		var c := Database.get_card(id)
		if c != null:
			deck.append(c)
	var cm := CombatManager.new()
	cm.start_combat(p, enc, deck, GameState.effective_drip(), false, GameState.active_passives(), sc[0], sc[1], GameState.card_upgrades)
	cm.player_gold = GameState.gold
	var gold0 := GameState.gold
	var g := 0
	while cm.state == CombatManager.State.PLAYER_TURN and g < 80:
		bot._bot_turn(cm, "balanced", fight_idx)
		g += 1
	if g >= 80 and cm.state == CombatManager.State.PLAYER_TURN:
		_fail("fight stalled past 80 turns vs %s" % _enc_str(node))
		return false
	var win := cm.state == CombatManager.State.WIN
	GameState.gold = max(0, cm.player_gold)
	for e in cm.enemies:
		if e.fled and e.stolen_gold > 0:
			print("    $ the IRS dipped with %d gold" % e.stolen_gold)
		elif e.stolen_gold == 0 and e.data != null and e.data.id == &"the_irs" and e.hp <= 0 and gold0 > GameState.gold:
			pass   # killed before stealing — nothing to settle
	if not win:
		return false
	GameState.player_hp = cm.player.hp
	GameState.record_show_rating(cm.compute_show_rating())
	var r := GameState.critic_last_rating
	ratings[r] = int(ratings.get(r, 0)) + 1
	if t != "Boss":
		var gain := GameState.combat_reward(node) + GameState.gold_income()
		GameState.gold += gain
		if GameState.deck.size() < 17:   # players curate; unchecked bloat dilutes the deck
			var offer := GameState.reward_offer(4 if GameState.has_artifact(&"for_you_page") else 3)
			var best: StringName = &""
			var best_rank := -1
			var ranks := {"Common": 0, "Rare": 1, "Epic": 2, "Legendary": 3}
			for oid in offer:
				var oc := Database.get_card(oid)
				if oc != null and int(ranks.get(oc.rarity, 0)) > best_rank:
					best_rank = int(ranks.get(oc.rarity, 0))
					best = oid
			if best != &"":
				GameState.deck.append(best)
		if t == "Elite":
			var aid := GameState.random_unowned_artifact(GameState.RELIC_WEIGHTS_ELITE)
			if aid != &"":
				GameState.add_artifact(aid)
				print("    + elite relic: %s" % Database.get_artifact(aid).title)
	print("  %s a%d r%d %-34s WIN  [%s] t%-2d hp %d/%d gold %d->%d" % [
		"B!" if t == "Boss" else ("E " if t == "Elite" else "  "), act, int(node.row),
		_enc_str(node), r, cm.turn, p.hp, p.max_hp, gold0, GameState.gold])
	return true

func _shop() -> void:
	var aid := GameState.random_unowned_artifact()
	if aid == &"":
		return
	var a := Database.get_artifact(aid)
	var price: int = {"Common": 55, "Rare": 75, "Epic": 100, "Legendary": 145}.get(a.rarity, 75)
	if GameState.has_artifact(&"girl_math"):
		price = int(round(price * 0.8))
	if GameState.gold >= price:
		GameState.gold -= price
		GameState.add_artifact(aid)
		print("    + shop relic: %s (%d gold, %s)" % [a.title, price, a.rarity])

func _rest() -> void:
	if GameState.player_hp < int(GameState.player_max_hp * 0.7):
		var heal := int(ceil(GameState.player_max_hp * 0.3))
		GameState.player_hp = mini(GameState.player_max_hp, GameState.player_hp + heal)
		print("    z rest: healed to %d/%d" % [GameState.player_hp, GameState.player_max_hp])
	else:
		for id in GameState.deck:
			if not GameState.is_upgraded(id) and Database.get_card(id) != null:
				GameState.upgrade_card(id, "value")
				print("    z rest: glowed up %s" % id)
				break

func _chest() -> void:
	var aid := GameState.random_unowned_artifact()
	if aid != &"":
		GameState.add_artifact(aid)
		print("    + chest relic: %s" % Database.get_artifact(aid).title)
	else:
		GameState.gold += 25

func _enc_str(node: Dictionary) -> String:
	var names: Array[String] = []
	for id in node.get("enemies", []):
		names.append(String(id))
	return "+".join(names)
