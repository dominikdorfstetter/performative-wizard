extends Node
## Headless test harness for the combat engine. Scripts deterministic fights and asserts
## the Swag economy, Burn, thresholds, finisher, Necro mechanics, outfit passives, and
## multi-enemy targeting / AoE / scaling.

var _pass := 0
var _fail := 0

func _check(label: String, got, want) -> void:
	if got == want:
		_pass += 1
		print("  PASS  %s == %s" % [label, str(want)])
	else:
		_fail += 1
		print("  FAIL  %s : got %s, want %s" % [label, str(got), str(want)])

func _ready() -> void:
	print("=== combat engine test ===")
	var cm := CombatManager.new()

	var player := Combatant.new()
	player.max_hp = 72
	player.hp = 72

	var cat := Database.get_enemy(&"alley_cat")
	_check("enemy loaded", cat != null, true)

	var deck: Array[CardData] = [Database.get_card(&"ember"), Database.get_card(&"ignite")]
	cm.start_combat(player, [cat], deck, 2, true)

	_check("t1 energy", cm.energy, 3)
	_check("t1 swag (drip)", cm.swag, 2)

	cm.hand = [Database.get_card(&"ignite")]
	cm.play_card(cm.hand[0])
	_check("enemy burn after ignite", cm.enemies[0].status(&"burn"), 3)
	_check("swag after ignite pose", cm.swag, 3)

	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after ember (no bonus)", cm.enemies[0].hp, 22)

	cm.end_turn()
	_check("enemy hp after burn tick", cm.enemies[0].hp, 19)
	_check("enemy burn decayed", cm.enemies[0].status(&"burn"), 2)
	_check("player hp after cat attack", cm.player.hp, 66)

	_check("t2 swag", cm.swag, 5)
	cm.swag = 6                                      # cross the (new) +2 threshold
	_check("swag damage bonus active (>=6)", cm.swag_damage_bonus(), 2)

	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after boosted ember", cm.enemies[0].hp, 11)

	cm.swag = 6
	cm.hand = [Database.get_card(&"grand_finale")]
	cm.play_card(cm.hand[0])
	_check("swag spent by finisher", cm.swag, 0)
	_check("enemy defeated by finisher", cm.enemies[0].is_dead(), true)
	_check("state is WIN", cm.state, CombatManager.State.WIN)

	# --- Necro: Undead + Sacrifice -------------------------------------------
	print("--- necro: undead & sacrifice ---")
	var cm2 := CombatManager.new()
	var necro := Combatant.new()
	necro.max_hp = 68
	necro.hp = 68
	var deck2: Array[CardData] = [Database.get_card(&"bone_dart")]
	cm2.start_combat(necro, [Database.get_enemy(&"alley_cat")], deck2, 0, true)

	cm2.hand = [Database.get_card(&"raise_dead")]
	cm2.play_card(cm2.hand[0])
	cm2.hand = [Database.get_card(&"raise_dead")]
	cm2.play_card(cm2.hand[0])
	_check("undead summoned", cm2.player.status(&"undead"), 2)
	_check("swag from two poses", cm2.swag, 2)

	cm2.end_turn()
	_check("cat hp after undead strike", cm2.enemies[0].hp, 24)
	_check("undead persist across turn", cm2.player.status(&"undead"), 2)

	var ehp := cm2.enemies[0].hp
	cm2.hand = [Database.get_card(&"macabre_bow")]
	cm2.play_card(cm2.hand[0])
	_check("undead after sacrifice", cm2.player.status(&"undead"), 1)
	_check("cat hp after macabre bow", cm2.enemies[0].hp, ehp - 7)
	_check("swag after macabre bow", cm2.swag, 5)

	# --- M3: outfit passives -------------------------------------------------
	print("--- m3: outfit passives ---")
	var cm3 := CombatManager.new()
	var pp := Combatant.new()
	pp.max_hp = 72
	pp.hp = 72
	var deck3: Array[CardData] = [Database.get_card(&"ember")]
	var pass3: Array[StringName] = [&"energy_plus_1", &"burn_plus_1", &"start_block_5", &"pose_plus_1"]
	cm3.start_combat(pp, [Database.get_enemy(&"alley_cat")], deck3, 0, true, pass3)
	_check("energy_plus_1 → max energy 4", cm3.max_energy, 4)
	_check("start_block_5 → 5 block", cm3.player.block, 5)
	cm3.hand = [Database.get_card(&"ignite")]
	cm3.play_card(cm3.hand[0])
	_check("burn_plus_1 → 4 burn", cm3.enemies[0].status(&"burn"), 4)
	_check("pose_plus_1 → swag 2", cm3.swag, 2)

	var cm4 := CombatManager.new()
	var p4 := Combatant.new()
	p4.max_hp = 68
	p4.hp = 68
	var deck4: Array[CardData] = [Database.get_card(&"bone_dart")]
	cm4.start_combat(p4, [Database.get_enemy(&"alley_cat")], deck4, 0, true, [&"undead_plus_1_on_summon"])
	cm4.hand = [Database.get_card(&"raise_dead")]
	cm4.play_card(cm4.hand[0])
	_check("undead_plus_1_on_summon → 2 undead", cm4.player.status(&"undead"), 2)

	# --- multi-enemy: targeting, AoE, scaling --------------------------------
	print("--- multi-enemy ---")
	var cm5 := CombatManager.new()
	var p5 := Combatant.new()
	p5.max_hp = 72
	p5.hp = 72
	var enc: Array = [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")]
	var deck5: Array[CardData] = [Database.get_card(&"ember")]
	cm5.start_combat(p5, enc, deck5, 0, true)
	_check("two enemies", cm5.enemies.size(), 2)
	cm5.hand = [Database.get_card(&"ember")]
	cm5.play_card(cm5.hand[0])
	_check("single-target hits enemy0", cm5.enemies[0].hp, 22)
	_check("enemy1 untouched", cm5.enemies[1].hp, 28)
	cm5.set_target(1)
	cm5.hand = [Database.get_card(&"ember")]
	cm5.play_card(cm5.hand[0])
	_check("retarget hits enemy1", cm5.enemies[1].hp, 22)
	cm5.energy = 2                                   # refund for the test; Flashfire costs 2
	cm5.hand = [Database.get_card(&"flashfire")]
	cm5.play_card(cm5.hand[0])
	_check("aoe hits enemy0", cm5.enemies[0].hp, 14)
	_check("aoe hits enemy1", cm5.enemies[1].hp, 14)

	var cm6 := CombatManager.new()
	var p6 := Combatant.new()
	p6.max_hp = 72
	p6.hp = 72
	var deck6: Array[CardData] = [Database.get_card(&"ember")]
	cm6.start_combat(p6, [Database.get_enemy(&"alley_cat")], deck6, 0, true, [], 1.5, 2.0)
	_check("hp scaled 1.5x", cm6.enemies[0].max_hp, 42)

	# --- crit / Rizz / aura-drain / draw ------------------------------------
	print("--- crit / rizz / drain / draw ---")
	var cmc := CombatManager.new()
	var pc := Combatant.new()
	pc.max_hp = 72
	pc.hp = 72
	cmc.start_combat(pc, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true, [&"crit_100"])
	_check("crit chance from passive", cmc.crit_chance, 1.0)
	cmc.hand = [Database.get_card(&"ember")]
	cmc.play_card(cmc.hand[0])
	_check("ember crit deals double", cmc.enemies[0].hp, 16)
	_check("last_crit flag set", cmc.last_crit, true)

	var cmr := CombatManager.new()
	var pr := Combatant.new()
	pr.max_hp = 72
	pr.hp = 72
	cmr.start_combat(pr, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"finger_guns")], 0, true, [&"rizz_crit"])
	cmr.player.add_status(&"strength", 20)
	cmr.hand = [Database.get_card(&"finger_guns")]
	cmr.play_card(cmr.hand[0])
	_check("rizz crit (5+20)x2 kills cat", cmr.enemies[0].is_dead(), true)

	var cmd2 := CombatManager.new()
	var pd := Combatant.new()
	pd.max_hp = 72
	pd.hp = 72
	cmd2.start_combat(pd, [Database.get_enemy(&"cursed_mirror")], [Database.get_card(&"ember")], 0, true)
	cmd2.swag = 10
	cmd2.end_turn()
	_check("enemy drained 4 aura", cmd2.swag, 6)

	var cmw := CombatManager.new()
	var pw := Combatant.new()
	pw.max_hp = 72
	pw.hp = 72
	var deckw: Array[CardData] = []
	for n in 8:
		deckw.append(Database.get_card(&"ember"))
	cmw.start_combat(pw, [Database.get_enemy(&"alley_cat")], deckw, 0, true)
	cmw.hand = [Database.get_card(&"quick_read")]
	cmw.play_card(cmw.hand[0])
	_check("quick read drew 2", cmw.hand.size(), 2)

	# jinx lowers crit chance (luck debuff)
	var cmj := CombatManager.new()
	var pj := Combatant.new()
	pj.max_hp = 72
	pj.hp = 72
	cmj.start_combat(pj, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true, [&"crit_100"])
	_check("crit before jinx", cmj.live_crit_chance(), 1.0)
	cmj.player.add_status(&"jinx", 4)
	_check("jinx -40% crit", cmj.live_crit_chance(), 0.6)
	cmj.player.add_status(&"jinx", 20)
	_check("crit floored at 0", cmj.live_crit_chance(), 0.0)

	# touch grass cleanses debuffs
	var cmt := CombatManager.new()
	var pt := Combatant.new()
	pt.max_hp = 72
	pt.hp = 72
	cmt.start_combat(pt, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"touch_grass")], 0, true)
	cmt.player.add_status(&"weak", 2)
	cmt.player.add_status(&"vulnerable", 2)
	cmt.player.add_status(&"jinx", 3)
	cmt.hand = [Database.get_card(&"touch_grass")]
	cmt.play_card(cmt.hand[0])
	_check("cleanse cleared weak", cmt.player.status(&"weak"), 0)
	_check("cleanse cleared jinx", cmt.player.status(&"jinx"), 0)
	_check("touch grass gave block", cmt.player.block, 5)

	# --- new enemy verbs: multi-hit, heal, frail -----------------------------
	print("--- enemy verbs ---")
	# rabid_roomba opens with attack 4 x3 = 12
	var cmm := CombatManager.new()
	var pm := Combatant.new()
	pm.max_hp = 72
	pm.hp = 72
	cmm.start_combat(pm, [Database.get_enemy(&"rabid_roomba")], [Database.get_card(&"ember")], 0, true)
	cmm.end_turn()
	_check("roomba flurry hit for 12", 72 - cmm.player.hp, 12)

	# vending machine heal intent restores its own HP
	var cmv := CombatManager.new()
	var pv := Combatant.new()
	pv.max_hp = 72
	pv.hp = 72
	cmv.start_combat(pv, [Database.get_enemy(&"vending_machine")], [Database.get_card(&"ember")], 0, true)
	cmv.enemies[0].hp = 20
	cmv.enemies[0].intent_index = 2   # heal 10
	cmv.end_turn()
	_check("vending machine healed", cmv.enemies[0].hp, 30)

	# frail makes the player gain 25% less Block
	var cmf := CombatManager.new()
	var pf := Combatant.new()
	pf.max_hp = 72
	pf.hp = 72
	cmf.start_combat(pf, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"bone_wall")], 0, true)
	cmf.player.add_status(&"frail", 2)
	cmf.hand = [Database.get_card(&"bone_wall")]   # Block 9
	cmf.play_card(cmf.hand[0])
	_check("frail softens block (9->6)", cmf.player.block, 6)

	# --- enemy summoners -----------------------------------------------------
	print("--- summoners ---")
	var cms := CombatManager.new()
	var psm := Combatant.new()
	psm.max_hp = 72
	psm.hp = 72
	cms.start_combat(psm, [Database.get_enemy(&"possessed_wardrobe")], [Database.get_card(&"ember")], 0, true)
	cms.enemies[0].intent_index = 1            # summon_ally sock_puppet
	var n0: int = cms.enemies.size()
	cms.end_turn()
	_check("wardrobe summoned backup", cms.enemies.size(), n0 + 1)

	# --- second-tier statuses: poison + enrage -------------------------------
	print("--- poison / enrage ---")
	# poison ramps down and ticks at the victim's turn start
	var cmpo := CombatManager.new()
	var ppo := Combatant.new()
	ppo.max_hp = 72
	ppo.hp = 72
	cmpo.start_combat(ppo, [Database.get_enemy(&"garden_gnome")], [Database.get_card(&"spread_rumors")], 0, true)
	cmpo.hand = [Database.get_card(&"spread_rumors")]
	cmpo.play_card(cmpo.hand[0])               # apply poison 4
	var ehp0: int = cmpo.enemies[0].hp
	cmpo.end_turn()                            # enemy turn: poison ticks 4, then ->3
	_check("poison ticked 4", ehp0 - cmpo.enemies[0].hp, 4)
	_check("poison ramped to 3", cmpo.enemies[0].status(&"poison"), 3)

	# enrage: gym_rat gains Strength when hit
	var cme := CombatManager.new()
	var pe := Combatant.new()
	pe.max_hp = 72
	pe.hp = 72
	cme.start_combat(pe, [Database.get_enemy(&"gym_rat")], [Database.get_card(&"ember")], 0, true)
	_check("gym rat starts at 0 Rizz", cme.enemies[0].status(&"strength"), 0)
	cme.hand = [Database.get_card(&"ember")]
	cme.play_card(cme.hand[0])                 # deal 6 -> enrage +2
	_check("gym rat enraged +2", cme.enemies[0].status(&"strength"), 2)

	# artifact passives: poison_plus_1 + enemies_start_vulnerable
	var cmap := CombatManager.new()
	var pap := Combatant.new()
	pap.max_hp = 72
	pap.hp = 72
	cmap.start_combat(pap, [Database.get_enemy(&"garden_gnome")], [Database.get_card(&"spread_rumors")], 0, true, [&"poison_plus_1", &"enemies_start_vulnerable"])
	_check("Spotlight: enemy starts Cooked", cmap.enemies[0].status(&"vulnerable"), 1)
	cmap.hand = [Database.get_card(&"spread_rumors")]
	cmap.play_card(cmap.hand[0])
	_check("Venom Vial: poison 4->5", cmap.enemies[0].status(&"poison"), 5)

	# --- Power cards: persistent start-of-turn effects -----------------------
	print("--- powers ---")
	var cm_pow := CombatManager.new()
	var p_pow := Combatant.new()
	p_pow.max_hp = 72
	p_pow.hp = 72
	var deck_pow: Array[CardData] = []
	for n in 6:
		deck_pow.append(Database.get_card(&"ember"))
	cm_pow.start_combat(p_pow, [Database.get_enemy(&"alley_cat")], deck_pow, 2, true)
	cm_pow.hand = [Database.get_card(&"pickup_line"), Database.get_card(&"slow_burn")]
	cm_pow.energy = 9
	cm_pow.play_card(cm_pow.hand[0])   # ritual 1
	cm_pow.play_card(cm_pow.hand[0])   # aura_engine 1
	var str0: int = cm_pow.player.status(&"strength")
	var swag0: int = cm_pow.swag
	cm_pow.end_turn()                  # enemy turn -> player start: powers tick
	_check("ritual ramped Rizz", cm_pow.player.status(&"strength"), str0 + 1)
	_check("aura engine + drip added", cm_pow.swag >= swag0 + 1 + 2, true)

	# --- progression: wizard unlock + multi-act ------------------------------
	print("--- progression ---")
	var saved_ce: int = GameState.clout_earned
	var saved_act: int = GameState.act
	GameState.clout_earned = 0
	_check("fire unlocked at 0", GameState.wizard_unlocked(&"fire"), true)
	_check("necro locked at 0", GameState.wizard_unlocked(&"necro"), false)
	GameState.clout_earned = 120
	_check("necro unlocks at 120", GameState.wizard_unlocked(&"necro"), true)
	_check("rizz still locked at 120", GameState.wizard_unlocked(&"rizz"), false)
	GameState.clout_earned = 320
	_check("rizz unlocks at 320", GameState.wizard_unlocked(&"rizz"), true)
	GameState.clout_earned = 0
	_check("ember always unlocked", GameState.card_unlocked(&"ember"), true)
	_check("inferno locked at 0", GameState.card_unlocked(&"inferno"), false)
	GameState.clout_earned = 50
	_check("inferno unlocks (40<=50)", GameState.card_unlocked(&"inferno"), true)
	_check("combust still locked (90>50)", GameState.card_unlocked(&"combust"), false)
	var fpool: Array = GameState.unlocked_cards([&"ember", &"inferno", &"combust"])
	_check("pool filters to unlocked", fpool.size(), 2)
	# card upgrade: Glow Up makes a card cost 1 less
	var infc := Database.get_card(&"inferno")
	_check("base cost 2", GameState.card_cost(infc), 2)
	GameState.upgrade_card(&"inferno")
	_check("glow'd up cost 1", GameState.card_cost(infc), 1)
	GameState.card_upgrades = {}
	GameState.act = 1
	_check("boss 1 -> act 2", GameState.advance_act(), true)
	_check("act is 2", GameState.act, 2)
	GameState.advance_act()                       # -> act 3
	_check("no act past max", GameState.advance_act(), false)
	GameState.clout_earned = saved_ce
	GameState.act = saved_act

	print("=== result: %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
