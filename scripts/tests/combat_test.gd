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
	_check("enemy burn after ignite", cm.enemies[0].status(&"burn"), 4)
	_check("swag after ignite pose", cm.swag, 3)

	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after ember (no bonus)", cm.enemies[0].hp, 22)

	cm.end_turn()
	_check("enemy hp after burn tick", cm.enemies[0].hp, 18)
	_check("enemy burn decayed", cm.enemies[0].status(&"burn"), 3)
	_check("player hp after cat attack", cm.player.hp, 66)

	_check("t2 swag", cm.swag, 5)
	cm.swag = 6                                      # cross the (new) +2 threshold
	_check("swag damage bonus active (>=6)", cm.swag_damage_bonus(), 2)

	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after boosted ember", cm.enemies[0].hp, 10)

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
	_check("burn_plus_1 → 5 burn", cm3.enemies[0].status(&"burn"), 5)
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

	# swag_on_crit (Rizz × Critic, pass #2.5): a crit serves +1 active Aura
	var cmsc := CombatManager.new()
	var psc := Combatant.new()
	psc.max_hp = 72
	psc.hp = 72
	cmsc.start_combat(psc, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true, [&"crit_100", &"swag_on_crit"])
	_check("swag_on_crit starts at 0 aura", cmsc.swag, 0)
	cmsc.hand = [Database.get_card(&"ember")]
	cmsc.play_card(cmsc.hand[0])
	_check("crit served +1 aura", cmsc.swag, 1)
	_check("crit aura is active (pose_swag)", cmsc.pose_swag, 1)

	var cmr := CombatManager.new()
	var pr := Combatant.new()
	pr.max_hp = 72
	pr.hp = 72
	cmr.start_combat(pr, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"finger_guns")], 0, true, [&"rizz_crit"])
	cmr.player.add_status(&"strength", 25)   # 25 x 0.04 = guaranteed crit (pass #4 shave)
	cmr.hand = [Database.get_card(&"finger_guns")]
	cmr.play_card(cmr.hand[0])
	_check("rizz crit (5+25)x2 kills cat", cmr.enemies[0].is_dead(), true)

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

	# --- The Critic: show rating (P1a) ---------------------------------------
	print("--- critic: show rating ---")
	# S: peak into the spotlight (>=24), then close on a clean Aura cash-out with a bold tell.
	# Pass #3: S also requires peak>=THRESHOLD_ENCORE (24) — simmering to 18 and dumping caps at A.
	var cmcr := CombatManager.new()
	var pcr := Combatant.new()
	pcr.max_hp = 72
	pcr.hp = 72
	cmcr.start_combat(pcr, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"grand_finale")], 0, true)
	cmcr.gain_swag(24)
	cmcr.flexed = true                                # the bold tell S now requires
	_check("peak tracks gains", cmcr.peak_swag, 24)
	cmcr.energy = 9
	cmcr.hand = [Database.get_card(&"grand_finale")]
	cmcr.play_card(cmcr.hand[0])
	_check("finisher cleaned the fight", cmcr.finisher_clean, true)
	_check("peak survives the cash-out drain", cmcr.peak_swag, 24)
	_check("S rank: bold + clean finisher + spotlight peak", cmcr.compute_show_rating()["rating"], "S")
	_check("S rank thresholds lit", cmcr.compute_show_rating()["thresholds_lit"], 3)
	# A (not S): same bold flex + clean finisher but the show only SIMMERED to lit-3 (18),
	# never cresting the spotlight (24) — the pass #3 peak gate caps this at A.
	var cmsim := CombatManager.new()
	var psim := Combatant.new()
	psim.max_hp = 72
	psim.hp = 72
	cmsim.start_combat(psim, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"grand_finale")], 0, true)
	cmsim.gain_swag(18)
	cmsim.flexed = true
	cmsim.energy = 9
	cmsim.hand = [Database.get_card(&"grand_finale")]
	cmsim.play_card(cmsim.hand[0])
	_check("simmered to 18 (no spotlight peak) caps at A", cmsim.compute_show_rating()["rating"], "A")

	# C: win scrappy, never crossing a threshold, no finisher.
	var cmc2 := CombatManager.new()
	var pc2 := Combatant.new()
	pc2.max_hp = 72
	pc2.hp = 72
	cmc2.start_combat(pc2, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmc2.enemies[0].hp = 5
	cmc2.energy = 3
	cmc2.hand = [Database.get_card(&"ember")]
	cmc2.play_card(cmc2.hand[0])
	_check("scrappy win state", cmc2.state, CombatManager.State.WIN)
	_check("C rank: low aura", cmc2.compute_show_rating()["rating"], "C")
	_check("C rank no thresholds", cmc2.compute_show_rating()["thresholds_lit"], 0)
	_check("C rank finisher not clean", cmc2.finisher_clean, false)

	# A: parked high (lit all three) but the kill was NOT a finisher.
	var cma := CombatManager.new()
	var pa := Combatant.new()
	pa.max_hp = 72
	pa.hp = 72
	cma.start_combat(pa, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cma.gain_swag(18)
	cma.enemies[0].hp = 5
	cma.energy = 3
	cma.hand = [Database.get_card(&"ember")]
	cma.play_card(cma.hand[0])
	_check("A rank: parked high, no clean finisher", cma.compute_show_rating()["rating"], "A")

	# A (not S): a clean finisher with NO bold tell (no flex, no spotlight) caps at A
	var cmco := CombatManager.new()
	var pco := Combatant.new()
	pco.max_hp = 72
	pco.hp = 72
	cmco.start_combat(pco, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"grand_finale")], 0, true)
	cmco.gain_swag(18)
	cmco.energy = 9
	cmco.hand = [Database.get_card(&"grand_finale")]
	cmco.play_card(cmco.hand[0])
	_check("coasted clean finisher caps at A (no bold tell)", cmco.compute_show_rating()["rating"], "A")

	# context-aware C (pass #2): a LONG fight coasted flat (lit-1 only, no pose, no
	# finisher, low peak) earns a C even on a win; a quick win or any engagement stays B.
	var cmfl := CombatManager.new()
	var pfl := Combatant.new()
	pfl.max_hp = 72
	pfl.hp = 72
	cmfl.start_combat(pfl, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmfl.gain_swag(8)                          # peak 8 → lit 1, but NOT from a Pose
	cmfl.turn = 6
	_check("long flat fight (no pose/finisher) → C", cmfl.compute_show_rating()["rating"], "C")
	cmfl.pose_swag = 1
	_check("same long fight but actively posed → B", cmfl.compute_show_rating()["rating"], "B")
	cmfl.pose_swag = 0
	cmfl.turn = 2
	_check("quick win is not punished → B", cmfl.compute_show_rating()["rating"], "B")

	# --- The Critic: score + map mutation + persistence (P1c) ----------------
	print("--- critic: score + map mutation ---")
	var saved_cs: int = GameState.critic_score
	var saved_pending: String = GameState.pending_critic
	GameState.critic_score = 0
	GameState.pending_critic = ""
	GameState.record_show_rating({"rating": "S", "peak_swag": 18, "thresholds_lit": 3, "finisher_clean": true, "turns": 3, "hp_lost": 0})
	_check("S adds 3 to critic_score", GameState.critic_score, 3)
	_check("last rating recorded", GameState.critic_last_rating, "S")
	var snode := {"row": 1, "col": 0, "type": "Combat", "enemies": [&"alley_cat"], "links": [], "visited": false}
	GameState.apply_critic_mutation(snode)
	_check("S enriches next room gold", int(snode.get("critic_bonus_gold", 0)), 20)
	_check("reward includes critic bonus", GameState.combat_reward(snode) >= 20, true)
	_check("pending cleared after apply", GameState.pending_critic, "")
	# C injects a heckler into the next fight room (room-only, not starting-combat math)
	GameState.pending_critic = "C"
	var cnode := {"row": 2, "col": 0, "type": "Combat", "enemies": [&"alley_cat"], "links": [], "visited": false}
	var scales_before: Array = GameState.node_scales(cnode)
	GameState.apply_critic_mutation(cnode)
	_check("C injects a heckler", cnode["enemies"].size(), 2)
	_check("heckler is the add", cnode["enemies"][1], &"heckler")
	_check("heckler enemy exists in db", Database.get_enemy(&"heckler") != null, true)
	_check("penalty leaves scaling untouched", GameState.node_scales(cnode), scales_before)
	# non-combat rooms are never mutated
	GameState.pending_critic = "C"
	var rnode := {"row": 3, "col": 0, "type": "Rest", "enemies": [], "links": [], "visited": false}
	GameState.apply_critic_mutation(rnode)
	_check("rest room untouched", rnode.get("enemies", []).size(), 0)
	# critic_score round-trips through the save format — in memory only, so the
	# suite never touches user://save.json and passes under PW_NO_SAVE=1 (CI)
	GameState.critic_score = 7
	var meta_json: Dictionary = JSON.parse_string(JSON.stringify(GameState._meta_to_dict()))
	GameState.critic_score = 999
	GameState._meta_from_dict(meta_json)
	_check("critic_score persists via save", GameState.critic_score, 7)
	GameState.critic_score = saved_cs
	GameState.pending_critic = saved_pending
	_check("clean finisher names its style", cmcr.style_signature(), &"swag_x3")

	# --- Commit to the Bit: encore / booed / tax (P3) ------------------------
	print("--- commit to the bit ---")
	var cmen := CombatManager.new()
	var pen := Combatant.new()
	pen.max_hp = 72
	pen.hp = 72
	cmen.start_combat(pen, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmen.swag = 26                              # above the spotlight line (24)
	cmen.end_turn()
	_check("encore builds in the spotlight", cmen.encore, 1)
	cmen.end_turn()
	_check("encore keeps building", cmen.encore, 2)
	cmen.energy = 9
	cmen.set_target(0)
	cmen.hand = [Database.get_card(&"take_a_bow")]
	cmen.play_card(cmen.hand[0])               # 26 × (2+2) = 104, lethal
	_check("take a bow zeroed Aura", cmen.swag, 0)
	_check("take a bow reset encore", cmen.encore, 0)
	_check("take a bow is a clean finish", cmen.enemies[0].is_dead(), true)
	_check("take a bow signature = encore", cmen.finisher_kind, &"encore")

	# booed: losing a REAL built-up Encore (>=2) applies a soft loss, not a cascade
	var cmbo := CombatManager.new()
	var pbo := Combatant.new()
	pbo.max_hp = 72
	pbo.hp = 72
	cmbo.start_combat(pbo, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmbo.swag = 26
	cmbo.end_turn()                            # encore 1
	cmbo.end_turn()                            # encore 2 (still in the spotlight)
	_check("encore built to 2", cmbo.encore, 2)
	cmbo.swag = 10                             # knocked below the line
	cmbo.end_turn()
	_check("booed cleared the encore", cmbo.encore, 0)
	_check("booed flag set", cmbo.booed, true)
	_check("booed soft loss (−4)", cmbo.swag, 6)

	# a brief 1-turn spotlight touch (encore 1) that drops does NOT boo (pass #2 gate)
	var cmbt := CombatManager.new()
	var pbt := Combatant.new()
	pbt.max_hp = 72
	pbt.hp = 72
	cmbt.start_combat(pbt, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmbt.swag = 26
	cmbt.end_turn()                            # encore 1
	cmbt.swag = 10
	cmbt.end_turn()                            # encore was only 1 → reset, no boo
	_check("brief spotlight touch doesn't boo", cmbt.booed, false)
	_check("encore reset after a touch", cmbt.encore, 0)
	_check("no aura lost on a touch", cmbt.swag, 10)

	# tax: punishes hoarding only while you're sitting on a pile
	var cmtx := CombatManager.new()
	var ptx := Combatant.new()
	ptx.max_hp = 72
	ptx.hp = 72
	cmtx.start_combat(ptx, [Database.get_enemy(&"cursed_mirror")], [Database.get_card(&"ember")], 0, true)
	cmtx.swag = 20
	cmtx.enemies[0].intent_index = 2          # the tax intent
	cmtx.end_turn()
	_check("tax skims a hoard above threshold", cmtx.swag, 15)
	cmtx.swag = 5
	cmtx.enemies[0].intent_index = 2
	cmtx.end_turn()
	_check("tax no-ops when you're broke", cmtx.swag, 5)

	# --- new finishers + flash persona (P4) ----------------------------------
	print("--- finishers ---")
	var cmsp := CombatManager.new()
	var psp := Combatant.new()
	psp.max_hp = 72
	psp.hp = 72
	cmsp.start_combat(psp, [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")], [Database.get_card(&"encore_for_fans")], 0, true)
	cmsp.swag = 10
	cmsp.energy = 9
	cmsp.hand = [Database.get_card(&"encore_for_fans")]
	cmsp.play_card(cmsp.hand[0])              # 10 × 1.5 = 15, +2 threshold bonus = 17 to ALL
	_check("spread finisher hits enemy0", cmsp.enemies[0].hp, 11)
	_check("spread finisher hits enemy1", cmsp.enemies[1].hp, 11)
	_check("spread finisher signature", cmsp.style_signature(), &"spread")

	var cmdr := CombatManager.new()
	var pdr := Combatant.new()
	pdr.max_hp = 72
	pdr.hp = 40
	cmdr.start_combat(pdr, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"soak_it_in")], 0, true)
	cmdr.swag = 10
	cmdr.energy = 9
	cmdr.hand = [Database.get_card(&"soak_it_in")]
	cmdr.play_card(cmdr.hand[0])             # 10×2=20, +2 threshold = 22 dmg, heal 11
	_check("drain finisher dealt 22", cmdr.enemies[0].hp, 6)
	_check("drain finisher healed half", cmdr.player.hp, 51)

	var cmfb := CombatManager.new()
	var pfb := Combatant.new()
	pfb.max_hp = 72
	pfb.hp = 72
	cmfb.start_combat(pfb, [Database.get_enemy(&"the_critic")], [Database.get_card(&"grand_finale")], 0, true, [&"finisher_boost"])
	cmfb.swag = 10
	cmfb.energy = 9
	var vhp := cmfb.enemies[0].hp
	cmfb.hand = [Database.get_card(&"grand_finale")]
	cmfb.play_card(cmfb.hand[0])             # 10×3×1.5 flash boost = 45, +2 threshold = 47
	_check("finisher_boost scales ×1.5", vhp - cmfb.enemies[0].hp, 47)

	# --- The Critic: drifting taste (P2) -------------------------------------
	print("--- critic: drifting taste ---")
	var saved_cs2: int = GameState.critic_score
	var saved_fat: Dictionary = GameState.critic_fatigue.duplicate()
	GameState.critic_fatigue = {}
	GameState.critic_score = 0
	GameState.pending_critic = ""
	GameState.record_show_rating({"rating": "S", "signature": &"swag_x3"})
	_check("first serve is fresh", GameState.critic_last_freshness, 1.0)
	var dn1 := {"type": "Combat", "enemies": [&"alley_cat"]}
	GameState.apply_critic_mutation(dn1)
	_check("fresh S → full VIP bonus", int(dn1.get("critic_bonus_gold", 0)), 20)
	GameState.record_show_rating({"rating": "S", "signature": &"swag_x3"})
	_check("repeating a style cools it", GameState.critic_last_freshness < 1.0, true)
	GameState.record_show_rating({"rating": "S", "signature": &"swag_x3"})
	GameState.record_show_rating({"rating": "S", "signature": &"swag_x3"})
	_check("spammed style goes stale", GameState.critic_last_freshness, 0.0)
	var dn2 := {"type": "Combat", "enemies": [&"alley_cat"]}
	GameState.apply_critic_mutation(dn2)
	_check("stale S → no VIP bonus", int(dn2.get("critic_bonus_gold", 0)), 0)
	_check("stale verdict nags for novelty", GameState.critic_quip("S"), Loc.t("again? serve me something NEW."))
	GameState.record_show_rating({"rating": "S", "signature": &"spread"})
	_check("a fresh new style pays out again", GameState.critic_last_freshness, 1.0)
	GameState.critic_fatigue = saved_fat
	GameState.critic_score = saved_cs2
	GameState.pending_critic = ""
	GameState.save_meta()

	# --- The Feed: rotating Trend (P4) ---------------------------------------
	print("--- the feed ---")
	var saved_act2: int = GameState.act
	var saved_drip: int = GameState.drip
	GameState.act = 1
	GameState._roll_trend()
	_check("act 1 trend = it's giving", GameState.trend, &"its_giving")
	_check("its-giving = +1 income", GameState.trend_drip_mod(), 1)
	GameState.drip = 2
	_check("trend re-prices income", GameState.effective_drip(), 3)
	GameState.act = 2
	GameState._roll_trend()
	_check("act 2 trend = flop era", GameState.trend, &"flop_era")
	GameState.drip = 0
	_check("income never goes negative", GameState.effective_drip(), 0)
	GameState.act = saved_act2
	GameState.drip = saved_drip
	GameState._roll_trend()

	# --- localization --------------------------------------------------------
	print("--- localization ---")
	Loc.set_locale("de")
	_check("de translates card text", Loc.t("Deal 5."), "5 Schaden.")
	_check("de keeps slang status", Loc.t("Cooked"), "Cooked")
	_check("de passthrough untranslated", Loc.t("xyz not real"), "xyz not real")
	_check("de translates log line", Loc.t("%s threw hands for %d"), "%s hat zugeschlagen für %d")
	Loc.set_locale("es")
	_check("es translates card text", Loc.t("Deal 5."), "Inflige 5.")
	_check("es translates enemy", Loc.t("Angry Toaster"), "Tostadora Furiosa")
	_check("es translates banter", Loc.t("you fell off"), "te caíste")
	_check("es translates critic name", Loc.t("The Critic"), "La Crítica")
	_check("es translates critic verdict", Loc.t("THE CRITIC:  %s"), "LA CRÍTICA:  %s")
	Loc.set_locale("de")
	_check("de translates meter tier", Loc.t("PIERCE"), "DURCHBRUCH")
	_check("de translates critic quip", Loc.t("S — serve. obsessed. devastating."), "S — serve. besessen. vernichtend.")
	_check("de translates heckler", Loc.t("Heckler"), "Zwischenrufer")
	_check("de translates encore line", Loc.t("ENCORE ×%d — the crowd wants MORE"), "ENCORE ×%d — der Saal will MEHR")
	_check("de translates trend", Loc.t("TREND: flop era  (-1 Aura/turn)"), "TREND: flop era  (-1 Aura/Zug)")
	Loc.set_locale("es")
	_check("es translates finisher desc", Loc.t("Finisher. Spend ALL Aura. Deal Aura × 1.5 to ALL enemies."), "Finisher. Gasta TODA la Aura. Inflige Aura × 1,5 a TODOS los enemigos.")
	Loc.set_locale("en")
	_check("en is passthrough", Loc.t("Deal 5."), "Deal 5.")
	_check("en critic passthrough", Loc.t("The Critic"), "The Critic")

	# --- regression: Block absorbs ENEMY attacks (was cleared before the enemy turn) ---
	print("--- block vs enemy attacks ---")
	var cmbk := CombatManager.new()
	var pbk := Combatant.new()
	pbk.max_hp = 72
	pbk.hp = 72
	cmbk.start_combat(pbk, [Database.get_enemy(&"sock_puppet"), Database.get_enemy(&"sock_puppet")], [Database.get_card(&"ember")], 0, true)
	cmbk.player.block = 10                       # you blocked for 10
	cmbk.end_turn()                              # two Sock Puppets attack 5 each
	_check("10 block fully absorbs 5+5 (no HP lost)", cmbk.player.hp, 72)
	_check("block was consumed by the hits", cmbk.player.block, 0)
	var cmbk2 := CombatManager.new()
	var pbk2 := Combatant.new()
	pbk2.max_hp = 72
	pbk2.hp = 72
	cmbk2.start_combat(pbk2, [Database.get_enemy(&"sock_puppet"), Database.get_enemy(&"sock_puppet")], [Database.get_card(&"ember")], 0, true)
	cmbk2.player.block = 7
	cmbk2.end_turn()
	_check("7 block vs 10 incoming -> take 3", cmbk2.player.hp, 69)
	# --- archetypes slice 2: new commons + flame_lash fix ---
	print("--- new commons + flame_lash fix ---")
	# flame_lash: deal 4, +4 if Roasted
	var cmfx := CombatManager.new()
	var pfx := Combatant.new()
	pfx.max_hp = 72
	pfx.hp = 72
	cmfx.start_combat(pfx, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"flame_lash")], 0, true)
	cmfx.hand = [Database.get_card(&"flame_lash")]
	cmfx.play_card(cmfx.hand[0])
	_check("flame_lash base 4 (no Roast)", cmfx.enemies[0].hp, 24)
	cmfx.enemies[0].add_status(&"burn", 3)
	cmfx.energy = 3
	cmfx.hand = [Database.get_card(&"flame_lash")]
	cmfx.play_card(cmfx.hand[0])
	_check("flame_lash +4 if Roasted (deal 8)", cmfx.enemies[0].hp, 16)

	# serve_face: pose +2 (active aura)
	var cmsf := CombatManager.new()
	var psf := Combatant.new()
	psf.max_hp = 72
	psf.hp = 72
	cmsf.start_combat(psf, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"serve_face")], 0, true)
	cmsf.hand = [Database.get_card(&"serve_face")]
	cmsf.play_card(cmsf.hand[0])
	_check("serve_face poses +2 aura", cmsf.swag, 2)
	_check("serve_face is active (pose_swag)", cmsf.pose_swag, 2)

	# bone_offering: sacrifice a goon for +3 aura
	var cmbf := CombatManager.new()
	var pbf := Combatant.new()
	pbf.max_hp = 68
	pbf.hp = 68
	cmbf.start_combat(pbf, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"bone_offering")], 0, true)
	cmbf.player.add_status(&"undead", 1)
	cmbf.hand = [Database.get_card(&"bone_offering")]
	cmbf.play_card(cmbf.hand[0])
	_check("bone_offering sacked the goon", cmbf.player.status(&"undead"), 0)
	_check("bone_offering gave +3 aura", cmbf.swag, 3)

	# gravecall: summon 1 + draw 1
	var cmgc := CombatManager.new()
	var pgc := Combatant.new()
	pgc.max_hp = 68
	pgc.hp = 68
	cmgc.start_combat(pgc, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"bone_dart")], 0, true)
	cmgc.draw_pile = [Database.get_card(&"bone_dart")]
	cmgc.hand = [Database.get_card(&"gravecall")]
	cmgc.play_card(cmgc.hand[0])
	_check("gravecall summoned a goon", cmgc.player.status(&"undead"), 1)
	_check("gravecall drew 1", cmgc.hand.size(), 1)

	# double_tap: 3 twice (two crit rolls) = 6
	var cmdt := CombatManager.new()
	var pdt := Combatant.new()
	pdt.max_hp = 72
	pdt.hp = 72
	cmdt.start_combat(pdt, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"double_tap")], 0, true)
	cmdt.hand = [Database.get_card(&"double_tap")]
	cmdt.play_card(cmdt.hand[0])
	_check("double_tap deals 3 twice = 6", cmdt.enemies[0].hp, 22)

	# smoulder: aura_engine power ticks +1/turn
	var cmsm := CombatManager.new()
	var psmo := Combatant.new()
	psmo.max_hp = 72
	psmo.hp = 72
	var decksm: Array[CardData] = []
	for n in 6:
		decksm.append(Database.get_card(&"ember"))
	cmsm.start_combat(psmo, [Database.get_enemy(&"alley_cat")], decksm, 0, true)
	cmsm.hand = [Database.get_card(&"smoulder")]
	cmsm.play_card(cmsm.hand[0])
	var sw0: int = cmsm.swag
	cmsm.end_turn()
	_check("smoulder aura engine ticks +1", cmsm.swag >= sw0 + 1, true)

	# unlock gate respects the new cards
	var saved_ce2: int = GameState.clout_earned
	GameState.clout_earned = 0
	_check("double_tap locked at 0 clout", GameState.card_unlocked(&"double_tap"), false)
	GameState.clout_earned = 30
	_check("double_tap unlocks by 30 clout", GameState.card_unlocked(&"double_tap"), true)
	GameState.clout_earned = saved_ce2

	# --- archetypes slice 3: vanilla starters + draft bias ---
	print("--- starters + draft bias ---")
	for wid in [&"fire", &"necro", &"rizz"]:
		var ww := Database.get_wizard(wid)
		_check("%s starter is 10 cards" % [wid], ww.starter_deck.size(), 10)
		_check("%s starter has a guaranteed Pose" % [wid], &"strike_a_pose" in ww.starter_deck, true)
	# USP visible from fight 1: fire starter lights threshold 1 with no crit luck
	var cmst := CombatManager.new()
	var pst := Combatant.new()
	pst.max_hp = 72
	pst.hp = 72
	var fdeck: Array[CardData] = []
	for id in Database.get_wizard(&"fire").starter_deck:
		fdeck.append(Database.get_card(id))
	cmst.start_combat(pst, [Database.get_enemy(&"alley_cat")], fdeck, 2, true)
	cmst.energy = 9
	cmst.hand = [Database.get_card(&"strike_a_pose"), Database.get_card(&"ignite")]
	cmst.play_card(cmst.hand[0])
	cmst.play_card(cmst.hand[0])
	_check("fire starter lights threshold 1 by fight 1", cmst.swag >= CombatManager.THRESHOLD_DAMAGE, true)
	# draft bias
	var saved_wiz: StringName = GameState.wizard_id
	var saved_deck: Array = GameState.deck.duplicate()
	var saved_ce3: int = GameState.clout_earned
	GameState.clout_earned = 99999
	GameState.wizard_id = &"fire"
	GameState.deck = [&"ember", &"kindle"]
	_check("fresh/neutral deck has no dominant archetype", GameState.deck_archetype(), &"")
	GameState.deck = [&"inferno", &"combust"]
	_check("2 roast cards → roast dominant", GameState.deck_archetype(), &"roast")
	var offer: Array = GameState.reward_offer(3)
	var roast_n := 0
	for id in offer:
		var oc := Database.get_card(id)
		if oc != null and oc.archetype == &"roast":
			roast_n += 1
	_check("roast-dominant deck → 2 roast in the offer", roast_n, 2)
	GameState.wizard_id = saved_wiz
	GameState.deck = saved_deck
	GameState.clout_earned = saved_ce3

	# --- archetypes slice 4: Legendary chase cards ---
	print("--- legendaries ---")
	# main_character (Rizz): deal 8 + 3 Rizz
	var cmmc := CombatManager.new()
	var pmc := Combatant.new()
	pmc.max_hp = 72
	pmc.hp = 72
	cmmc.start_combat(pmc, [Database.get_enemy(&"the_critic")], [Database.get_card(&"main_character")], 0, true)
	cmmc.energy = 9
	cmmc.hand = [Database.get_card(&"main_character")]
	var mc_hp0: int = cmmc.enemies[0].hp
	cmmc.play_card(cmmc.hand[0])
	_check("main_character deals 8", mc_hp0 - cmmc.enemies[0].hp, 8)
	_check("main_character gives 3 Rizz", cmmc.player.status(&"strength"), 3)
	# mass_sacrifice (Necro): 3 goons -> deal 16 + 6 aura
	var cmms := CombatManager.new()
	var pms := Combatant.new()
	pms.max_hp = 68
	pms.hp = 68
	cmms.start_combat(pms, [Database.get_enemy(&"the_critic")], [Database.get_card(&"mass_sacrifice")], 0, true)
	cmms.player.add_status(&"undead", 3)
	cmms.energy = 9
	var ms_hp0: int = cmms.enemies[0].hp
	cmms.hand = [Database.get_card(&"mass_sacrifice")]
	cmms.play_card(cmms.hand[0])
	_check("mass_sacrifice ate 3 goons", cmms.player.status(&"undead"), 0)
	_check("mass_sacrifice deals 16", ms_hp0 - cmms.enemies[0].hp, 16)
	_check("mass_sacrifice gives 6 aura", cmms.swag, 6)
	# mass_sacrifice with <3 goons = no-op
	var cmms2 := CombatManager.new()
	var pms2 := Combatant.new()
	pms2.max_hp = 68
	pms2.hp = 68
	cmms2.start_combat(pms2, [Database.get_enemy(&"the_critic")], [Database.get_card(&"mass_sacrifice")], 0, true)
	cmms2.player.add_status(&"undead", 2)
	cmms2.energy = 9
	cmms2.hand = [Database.get_card(&"mass_sacrifice")]
	cmms2.play_card(cmms2.hand[0])
	_check("mass_sacrifice no-ops under 3 goons", cmms2.player.status(&"undead"), 2)
	# flashpoint (Fire): 3x Roast then +3 Roast
	var cmfp := CombatManager.new()
	var pfp := Combatant.new()
	pfp.max_hp = 72
	pfp.hp = 72
	cmfp.start_combat(pfp, [Database.get_enemy(&"the_critic")], [Database.get_card(&"flashpoint")], 0, true)
	cmfp.enemies[0].add_status(&"burn", 4)
	cmfp.energy = 9
	var fp_hp0: int = cmfp.enemies[0].hp
	cmfp.hand = [Database.get_card(&"flashpoint")]
	cmfp.play_card(cmfp.hand[0])
	_check("flashpoint deals 3x Roast (12)", fp_hp0 - cmfp.enemies[0].hp, 12)
	_check("flashpoint then applies 3 Roast (4->7)", cmfp.enemies[0].status(&"burn"), 7)
	# Legendary rarity + 150 unlock gate
	_check("flashpoint is Legendary", Database.get_card(&"flashpoint").rarity, "Legendary")
	var saved_ce4: int = GameState.clout_earned
	GameState.clout_earned = 100
	_check("Legendary locked at 100 clout", GameState.card_unlocked(&"flashpoint"), false)
	GameState.clout_earned = 150
	_check("Legendary unlocks at 150 clout", GameState.card_unlocked(&"flashpoint"), true)
	GameState.clout_earned = saved_ce4

	# --- archetypes slice 5: wide-S path + Necro swarm fingerprint ---
	print("--- wide-S + swarm fingerprint ---")
	var cmep := CombatManager.new()
	var pep := Combatant.new()
	pep.max_hp = 72
	pep.hp = 72
	cmep.start_combat(pep, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"ember")], 0, true)
	cmep.peak_swag = 24                              # crested the spotlight (pass #3 S peak gate)
	cmep.finisher_clean = true
	cmep.aoe_plays = 2
	_check("wide (>=2 AoE) clean finish -> S", cmep.compute_show_rating()["rating"], "S")
	cmep.aoe_plays = 0
	cmep.pose_swag = 12
	_check("active-aura clean finish -> S", cmep.compute_show_rating()["rating"], "S")
	cmep.pose_swag = 0
	_check("coasted single-target clean finish still caps at A", cmep.compute_show_rating()["rating"], "A")
	# pass #3: even a wide clean finish that only simmered to 18 (no spotlight peak) caps at A
	cmep.peak_swag = 18
	cmep.aoe_plays = 2
	_check("wide finish that never crested 24 caps at A", cmep.compute_show_rating()["rating"], "A")
	cmep.aoe_plays = 0
	cmep.peak_swag = 24
	# swarm fingerprint from a big Goon board
	cmep.finisher_clean = false
	cmep.player.add_status(&"undead", 4)
	cmep._emit()
	_check("peak_undead tracks the board", cmep.peak_undead, 4)
	_check("big goon board -> swarm signature", cmep.style_signature(), &"swarm")

	# --- sequenced enemy turn (step_delay > 0): suspends at the first beat, then
	# completes asynchronously; enemy_acting fires once per living attacker. The
	# default step_delay == 0 path is what every other test in this file exercises.
	print("--- sequenced enemy turn ---")
	var cmsq := CombatManager.new()
	var psq := Combatant.new()
	psq.max_hp = 80
	psq.hp = 80
	var seq_acts: Array = []
	cmsq.enemy_acting.connect(func(i: int, _intent: Dictionary): seq_acts.append(i))
	var sqdeck: Array[CardData] = [Database.get_card(&"ember")]
	cmsq.start_combat(psq, [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")], sqdeck, 0, true)
	cmsq.step_delay = 0.02
	var hp_before_seq := cmsq.player.hp
	cmsq.end_turn()
	_check("sequenced turn suspends mid-enemy-turn", cmsq.state, CombatManager.State.ENEMY_TURN)
	await get_tree().create_timer(0.6).timeout
	_check("sequenced turn completes to player turn", cmsq.state, CombatManager.State.PLAYER_TURN)
	_check("sequenced turn advanced the turn counter", cmsq.turn, 2)
	_check("enemy_acting fired once per living attacker", seq_acts, [0, 1])
	_check("both sequenced attackers landed their hits", cmsq.player.hp < hp_before_seq, true)

	# --- run snapshot: JSON round-trip restores the run exactly (no disk I/O here —
	# save_run/save_meta write user://save.json, which tests must never touch) ---
	print("--- run snapshot ---")
	GameState.start_run(&"fire")
	GameState.finalize_loadout()
	GameState.gold = 123
	GameState.player_hp = 17
	GameState.act = 2
	GameState.run_artifacts = [&"ember_pin"] as Array[StringName]
	GameState.card_upgrades = {&"ember": true}
	GameState.pending_critic = "S"
	GameState.pending_freshness = 1.0
	GameState.critic_fatigue = {&"hoard": 2}
	var first_col: int = GameState.map[0][0].col
	GameState.enter(0, first_col)   # consumes pending_critic into a VIP node mutation
	var snap_rows: int = GameState.map.size()
	var snap_deck: int = GameState.deck.size()
	var snap: Variant = JSON.parse_string(JSON.stringify(GameState._run_to_dict()))
	_check("snapshot serializes to a dictionary", typeof(snap), TYPE_DICTIONARY)
	GameState.start_run(&"fire")    # scramble the live run
	GameState.finalize_loadout()
	GameState.gold = 0
	_check("snapshot restores after the scramble", GameState._run_from_dict(snap), true)
	_check("restored gold", GameState.gold, 123)
	_check("restored hp", GameState.player_hp, 17)
	_check("restored act", GameState.act, 2)
	_check("restored deck size", GameState.deck.size(), snap_deck)
	_check("restored map rows", GameState.map.size(), snap_rows)
	_check("restored position", [GameState.pos_row, GameState.pos_col], [0, first_col])
	_check("restored artifacts", GameState.run_artifacts, [&"ember_pin"] as Array[StringName])
	_check("restored upgrade flag", GameState.is_upgraded(&"ember"), true)
	_check("restored critic fatigue", int(GameState.critic_fatigue.get(&"hoard", 0)), 2)
	_check("restored critic mutation on the entered node", String(GameState.node_at(0, first_col).get("critic_note", "")), "vip")
	_check("map cols re-typed to int after JSON round-trip", typeof(GameState.map[0][0].col), TYPE_INT)
	var bad_snap := {"wizard_id": "nope", "map": [], "deck": []}
	_check("invalid snapshot rejected", GameState._run_from_dict(bad_snap), false)

	# --- pile manipulation: peek / shuffle_discard / retain + the hand cap ---
	print("--- pile manipulation ---")
	var cmpile := CombatManager.new()
	var ppile := Combatant.new()
	ppile.max_hp = 60
	ppile.hp = 60
	var pile_deck: Array[CardData] = []
	for i in 8:
		pile_deck.append(Database.get_card(&"ember"))
	cmpile.start_combat(ppile, [Database.get_enemy(&"alley_cat")], pile_deck, 0, true)
	_check("draw pile holds the undrawn 3", cmpile.draw_pile.size(), 3)
	var peeked_titles: Array = []
	cmpile.peeked.connect(func(t): peeked_titles.append_array(t))
	cmpile.peek_draw(2)
	_check("peek reveals 2", peeked_titles.size(), 2)
	_check("peek 1st matches the next draw", peeked_titles[0], cmpile.draw_pile[cmpile.draw_pile.size() - 1].title)
	_check("peek does not consume cards", cmpile.draw_pile.size(), 3)
	# peek on a dry draw pile reshuffles the discard in first (same as _draw would)
	cmpile.discard_pile.append_array(cmpile.draw_pile)
	cmpile.draw_pile.clear()
	cmpile.peek_draw(1)
	_check("dry peek reshuffles the discard in", cmpile.draw_pile.size(), 3)
	_check("dry peek leaves no discard behind", cmpile.discard_pile.size(), 0)
	# peek_pick (Vision Board): headless auto-takes the top card == a plain draw
	var cmvb := CombatManager.new()
	var pvb := Combatant.new()
	pvb.max_hp = 60
	pvb.hp = 60
	var vb_deck: Array[CardData] = []
	for i in 8:
		vb_deck.append(Database.get_card(&"ember"))
	cmvb.start_combat(pvb, [Database.get_enemy(&"alley_cat")], vb_deck, 0, true)
	cmvb.hand = [Database.get_card(&"vision_board")]   # 5 embers out, 3 in the pile
	var vb_pile0: int = cmvb.draw_pile.size()
	var vb_hand0: int = cmvb.hand.size()
	cmvb.play_card(cmvb.hand[0])
	_check("headless peek_pick takes the top card", cmvb.draw_pile.size(), vb_pile0 - 1)
	_check("the taken card landed in hand", cmvb.hand.size(), vb_hand0)   # -1 played, +1 taken
	_check("pick resolved, nothing pending", cmvb.pending_pick_n, 0)
	# with a view attached the pick defers: the signal lays the cards out
	# top-first and resolve_pick removes the exact position that was shown
	var cmpk := CombatManager.new()
	var ppk := Combatant.new()
	ppk.max_hp = 60
	ppk.hp = 60
	cmpk.start_combat(ppk, [Database.get_enemy(&"alley_cat")], [] as Array[CardData], 0, true)
	cmpk.step_delay = 0.45   # "view attached" — emit only, no await runs here
	cmpk.draw_pile = [Database.get_card(&"ember"), Database.get_card(&"thrift_flip"), Database.get_card(&"side_eye")]
	cmpk.hand.clear()
	var laid_out: Array = []
	cmpk.pick_requested.connect(func(cards): laid_out.append_array(cards))
	cmpk.request_pick(3)
	_check("pick lays out 3", laid_out.size(), 3)
	_check("first laid-out card is the pile top", laid_out[0].id, &"side_eye")
	_check("pick is pending under a view", cmpk.pending_pick_n, 3)
	cmpk.resolve_pick(1)
	_check("picked the middle card", cmpk.hand[0].id, &"thrift_flip")
	_check("pile keeps its promised order", cmpk.draw_pile[cmpk.draw_pile.size() - 1].id, &"side_eye")
	_check("pile shrank by one", cmpk.draw_pile.size(), 2)
	# a turn can't end mid-pick: the default (top) card resolves first
	cmpk.energy = 3
	cmpk.request_pick(2)
	_check("second pick pending", cmpk.pending_pick_n, 2)
	cmpk.step_delay = 0.0   # keep end_turn fully synchronous for the test
	cmpk.end_turn()
	_check("end_turn auto-resolved the pick", cmpk.pending_pick_n, 0)
	# a full hand refuses the pick and leaves the pile untouched
	var cmfh := CombatManager.new()
	var pfh := Combatant.new()
	pfh.max_hp = 60
	pfh.hp = 60
	var fh_deck: Array[CardData] = []
	for i in 13:
		fh_deck.append(Database.get_card(&"ember"))
	cmfh.start_combat(pfh, [Database.get_enemy(&"alley_cat")], fh_deck, 0, true)
	cmfh.draw_cards(20)
	_check("full-hand setup", cmfh.hand.size(), CombatManager.HAND_CAP)
	var fh_pile: int = cmfh.draw_pile.size()
	cmfh.request_pick(3)
	_check("full hand refuses the pick", cmfh.hand.size(), CombatManager.HAND_CAP)
	_check("refused pick leaves the pile alone", cmfh.draw_pile.size(), fh_pile)

	# thrift_flip: its own discard joins the recycle, then draw 1
	var cmflip := CombatManager.new()
	var pflip := Combatant.new()
	pflip.max_hp = 60
	pflip.hp = 60
	cmflip.start_combat(pflip, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"thrift_flip")], 0, true)
	cmflip.discard_pile.append(Database.get_card(&"ember"))
	cmflip.discard_pile.append(Database.get_card(&"ember"))
	var flip_swag0 := cmflip.swag
	_check("thrift flip is in hand", cmflip.hand.size(), 1)
	_check("thrift flip plays", cmflip.play_card(cmflip.hand[0]), true)
	_check("thrift flip recycles + draws 1", cmflip.hand.size(), 1)
	_check("thrift flip leaves no discard", cmflip.discard_pile.size(), 0)
	_check("thrift flip banks aura", cmflip.swag > flip_swag0, true)
	# saved_drafts: the unplayed hand survives end_turn, then next turn tops it up
	var cmret := CombatManager.new()
	var pret := Combatant.new()
	pret.max_hp = 60
	pret.hp = 60
	var ret_deck: Array[CardData] = [Database.get_card(&"saved_drafts"), Database.get_card(&"ember"), Database.get_card(&"ember")]
	cmret.start_combat(pret, [Database.get_enemy(&"alley_cat")], ret_deck, 0, true)
	_check("retain test hand", cmret.hand.size(), 3)
	for c in cmret.hand:
		if c.id == &"saved_drafts":
			cmret.play_card(c)
			break
	_check("retain flag set", cmret.retain_hand, true)
	cmret.end_turn()
	_check("retain consumed", cmret.retain_hand, false)
	var kept_embers := 0
	for c in cmret.hand:
		if c.id == &"ember":
			kept_embers += 1
	_check("both embers survived end_turn", kept_embers, 2)
	_check("next turn topped the hand up", cmret.hand.size(), 3)
	# the hand cap stops pathological retain+draw loops
	var cmcap := CombatManager.new()
	var pcap := Combatant.new()
	pcap.max_hp = 60
	pcap.hp = 60
	var cap_deck: Array[CardData] = []
	for i in 14:
		cap_deck.append(Database.get_card(&"ember"))
	cmcap.start_combat(pcap, [Database.get_enemy(&"alley_cat")], cap_deck, 0, true)
	cmcap.draw_cards(20)
	_check("hand caps at 10", cmcap.hand.size(), CombatManager.HAND_CAP)
	# the nine new cards exist and sit in the right pools
	var new_ids: Array = [&"vision_board", &"thrift_flip", &"saved_drafts", &"side_eye", &"love_bomb", &"glow_check", &"bold_move", &"future_spouse", &"crowd_work"]
	var missing_cards: Array = []
	for nid in new_ids:
		if Database.get_card(nid) == null:
			missing_cards.append(nid)
	_check("all nine new cards load", missing_cards, [])
	var rizz_pool: Array = Database.get_wizard(&"rizz").reward_pool
	_check("rizz pool grew to 30", rizz_pool.size(), 30)
	_check("necro pool grew to 30", Database.get_wizard(&"necro").reward_pool.size(), 30)
	_check("rizz pool has the new commons", &"side_eye" in rizz_pool and &"love_bomb" in rizz_pool and &"glow_check" in rizz_pool, true)
	var fire_pool: Array = Database.get_wizard(&"fire").reward_pool
	_check("neutral utilities reach fire too", &"vision_board" in fire_pool and &"saved_drafts" in fire_pool, true)

	# --- glow up flavours: "cost" (classic) vs "value" (+2 amounts) ------------
	print("--- glow up flavours ---")
	var ember_card := Database.get_card(&"ember")
	var cmup := CombatManager.new()
	var pup := Combatant.new()
	pup.max_hp = 60
	pup.hp = 60
	cmup.start_combat(pup, [Database.get_enemy(&"alley_cat")], [ember_card], 0, true, [], 1.0, 1.0, {&"ember": "value"})
	_check("value upgrade keeps the cost", cmup.card_cost(ember_card), 1)
	var cat_hp0: int = cmup.enemies[0].hp
	cmup.set_target(0)
	cmup.play_card(cmup.hand[0])
	_check("value upgrade deals 6+2", cat_hp0 - cmup.enemies[0].hp, 8)
	var cmup2 := CombatManager.new()
	var pup2 := Combatant.new()
	pup2.max_hp = 60
	pup2.hp = 60
	cmup2.start_combat(pup2, [Database.get_enemy(&"alley_cat")], [ember_card], 0, true, [], 1.0, 1.0, {&"ember": "cost"})
	_check("cost upgrade shaves 1 energy", cmup2.card_cost(ember_card), 0)
	var cat_hp1: int = cmup2.enemies[0].hp
	cmup2.set_target(0)
	cmup2.play_card(cmup2.hand[0])
	_check("cost upgrade keeps base damage", cat_hp1 - cmup2.enemies[0].hp, 6)
	var cmup3 := CombatManager.new()
	var pup3 := Combatant.new()
	pup3.max_hp = 60
	pup3.hp = 60
	cmup3.start_combat(pup3, [Database.get_enemy(&"alley_cat")], [ember_card], 0, true, [], 1.0, 1.0, {&"ember": true})
	_check("legacy true reads as cost", cmup3.card_cost(ember_card), 0)
	# upgrade modes survive the run-snapshot JSON round-trip
	var saved_ups: Dictionary = GameState.card_upgrades.duplicate()
	GameState.card_upgrades = {&"ember": "value", &"wink": "cost"}
	var up_run: Dictionary = JSON.parse_string(JSON.stringify(GameState._run_to_dict()))
	GameState.card_upgrades = {}
	GameState._run_from_dict(up_run)
	_check("value mode survives the snapshot", GameState.upgrade_mode(&"ember"), "value")
	_check("cost mode survives the snapshot", GameState.upgrade_mode(&"wink"), "cost")
	GameState.card_upgrades = saved_ups

	# --- per-act music variants build, cache, and leave the menu alone ----------
	print("--- act music variants ---")
	_check("act 2 combat gets its own variant", Audio._variant_key("combat", 2), "combat@2")
	_check("variant is cached as a stream", Audio._tracks.has("combat@2"), true)
	_check("act 1 stays the base track", Audio._variant_key("combat", 1), "combat")
	_check("menu never varies", Audio._variant_key("menu", 3), "menu")
	_check("variant keys don't re-wrap", Audio._variant_key("combat@2", 3), "combat@2")

	# --- the Goon squad: targeting, command cards, wardrobe hooks --------------
	print("--- goon squad ---")
	var cmgs := CombatManager.new()
	var pgs := Combatant.new()
	pgs.max_hp = 60
	pgs.hp = 60
	cmgs.start_combat(pgs, [Database.get_enemy(&"alley_cat")], [Database.get_card(&"sic_em")], 0, true)
	cmgs.player.add_status(&"undead", 3)
	var gs_hp0: int = cmgs.enemies[0].hp
	cmgs.energy = 3
	_check("sic_em plays", cmgs.play_card(cmgs.hand[0]), true)
	_check("commanded goons dealt 3x2", gs_hp0 - cmgs.enemies[0].hp, 6)
	_check("the squad survives the command", cmgs.player.status(&"undead"), 3)
	# critical mass applies to commanded strikes too
	cmgs.player.add_status(&"undead", 2)   # now 5
	var gs_hp1: int = cmgs.enemies[0].hp
	cmgs.goon_strike()
	_check("critical mass: 5 goons hit for 15", gs_hp1 - cmgs.enemies[0].hp, 15)
	# targeting: weakest / strongest via wardrobe + relic hooks
	var cmgt := CombatManager.new()
	var pgt := Combatant.new()
	pgt.max_hp = 60
	pgt.hp = 60
	cmgt.start_combat(pgt, [Database.get_enemy(&"vending_machine"), Database.get_enemy(&"alley_cat")], [] as Array[CardData], 0, true, [&"goons_target_weakest"])
	cmgt.enemies[1].hp = 5   # the runt
	cmgt.player.add_status(&"undead", 2)
	cmgt.goon_strike()
	_check("weakest-targeting jumps the runt", cmgt.enemies[1].hp, 1)
	var cmgt2 := CombatManager.new()
	var pgt2 := Combatant.new()
	pgt2.max_hp = 60
	pgt2.hp = 60
	cmgt2.start_combat(pgt2, [Database.get_enemy(&"vending_machine"), Database.get_enemy(&"alley_cat")], [] as Array[CardData], 0, true, [&"goons_target_strongest"])
	var big_hp0: int = cmgt2.enemies[0].hp
	cmgt2.player.add_status(&"undead", 2)
	cmgt2.goon_strike()
	_check("strongest-targeting jumps the big one", big_hp0 - cmgt2.enemies[0].hp, 4)
	# fight-start hooks: Shroud of the Squad + Mourning Veil
	var cmsh := CombatManager.new()
	var psh := Combatant.new()
	psh.max_hp = 60
	psh.hp = 60
	cmsh.start_combat(psh, [Database.get_enemy(&"alley_cat")], [] as Array[CardData], 0, true, [&"undead_start_2", &"poison_start_2"])
	_check("Shroud: start with 2 Goons", cmsh.player.status(&"undead"), 2)
	_check("Veil: enemies enter with 2 Toxic", cmsh.enemies[0].status(&"poison"), 2)
	# Snakeskin Jacket: crits refund 1 Energy (crit_100 forces the roll)
	var cmcr2 := CombatManager.new()
	var pcr2 := Combatant.new()
	pcr2.max_hp = 60
	pcr2.hp = 60
	cmcr2.start_combat(pcr2, [Database.get_enemy(&"vending_machine")], [Database.get_card(&"ember")], 0, true, [&"crit_100", &"crit_refund_energy"])
	cmcr2.hand = [Database.get_card(&"ember")]
	cmcr2.energy = 3
	cmcr2.set_target(0)
	cmcr2.play_card(cmcr2.hand[0])
	_check("crit happened", cmcr2.last_crit, true)
	_check("crit refunded the energy", cmcr2.energy, 3)
	# Post the Receipts: damage scales on Toxic
	var cmpr := CombatManager.new()
	var ppr := Combatant.new()
	ppr.max_hp = 60
	ppr.hp = 60
	cmpr.start_combat(ppr, [Database.get_enemy(&"vending_machine")], [Database.get_card(&"post_receipts")], 0, true)
	cmpr.enemies[0].add_status(&"poison", 4)
	cmpr.hand = [Database.get_card(&"post_receipts")]
	cmpr.energy = 3
	cmpr.set_target(0)
	var pr_hp0: int = cmpr.enemies[0].hp
	cmpr.play_card(cmpr.hand[0])
	_check("receipts deal 2x Toxic", pr_hp0 - cmpr.enemies[0].hp, 8)
	# Morticia's starter finally teaches HER loop
	var nstart: Array = Database.get_wizard(&"necro").starter_deck
	_check("necro starter still 10 cards", nstart.size(), 10)
	_check("necro starter commands the squad", &"sic_em" in nstart, true)
	_check("necro starter raises 3", nstart.count(&"raise_dead"), 3)
	# re-elemented pieces can't stay equipped on the wrong wizard
	var saved_eq: Dictionary = GameState.equipped.duplicate()
	var saved_unlocked: Array = GameState.unlocked_outfits.duplicate()
	if &"diva_heels" not in GameState.unlocked_outfits:
		GameState.unlocked_outfits.append(&"diva_heels")
	GameState.equipped["Boots"] = &"diva_heels"
	GameState.start_run(&"fire")
	_check("rizz-only heels revert on a fire run", GameState.equipped_id("Boots") != &"diva_heels", true)
	GameState.equipped = saved_eq
	GameState.unlocked_outfits.assign(saved_unlocked)
	# the new content all loads
	var missing_new: Array = []
	for nid2 in [&"sic_em", &"mosh_pit", &"post_receipts", &"group_project", &"shoot_your_shot", &"paparazzi"]:
		if Database.get_card(nid2) == null:
			missing_new.append(nid2)
	for oid2 in [&"mourning_veil", &"shroud_squad", &"pallbearer_boots", &"mirror_shades", &"snakeskin_jacket", &"selfie_stick"]:
		if Database.get_outfit(oid2) == null:
			missing_new.append(oid2)
	for aid2 in [&"ouija_board", &"hype_reel"]:
		if Database.get_artifact(aid2) == null:
			missing_new.append(aid2)
	_check("all new wardrobe content loads", missing_new, [])
	_check("boutique stocks 20 pieces", GameState.BOUTIQUE.size(), 20)
	_check("ghoul sprites render", SpriteBank.ghoul_texture(0) != null and SpriteBank.ghoul_texture(2) != null, true)

	# --- map generation: structure guarantees hold across many seeds ----------
	print("--- map generation ---")
	var bad_cross: Array = []
	var bad_reach: Array = []
	var bad_consec: Array = []
	var bad_rowdupe: Array = []
	var bad_shop: Array = []
	var bad_shape: Array = []
	for seed_v in range(1, 41):
		var mrows: Array = MapGenerator.generate(seed_v)
		if mrows.size() != MapGenerator.ROWS or mrows[-1].size() != 1 or mrows[-1][0].type != "Boss":
			bad_shape.append(seed_v)
		for r in mrows.size() - 1:
			var mrow: Array = mrows[r]
			# edges never cross: for i < j, max(links_i) <= min(links_j)
			for i in mrow.size():
				for j in range(i + 1, mrow.size()):
					if not mrow[i].links.is_empty() and not mrow[j].links.is_empty() \
							and mrow[i].links.max() > mrow[j].links.min():
						bad_cross.append(seed_v)
			# every node has an exit, every next-row node an entrance
			var incoming := {}
			for i in mrow.size():
				if mrow[i].links.is_empty():
					bad_reach.append(seed_v)
				for l in mrow[i].links:
					incoming[l] = true
			for k in mrows[r + 1].size():
				if not incoming.has(k):
					bad_reach.append(seed_v)
			# no special repeats along an edge (the "two rests in a row" report)
			for i in mrow.size():
				var mt: String = mrow[i].type
				if mt == "Combat" or mt == "Boss":
					continue
				for l in mrow[i].links:
					if mrows[r + 1][l].type == mt:
						bad_consec.append("%d:%s" % [seed_v, mt])
		# at most one Rest/Shop/Chest per row (pre-boss rest row exempt by design)
		for r in range(1, mrows.size() - 2):
			var counts := {}
			for node in mrows[r]:
				counts[node.type] = int(counts.get(node.type, 0)) + 1
			for t in ["Rest", "Shop", "Chest"]:
				if int(counts.get(t, 0)) > 1:
					bad_rowdupe.append("%d:%s" % [seed_v, t])
		var has_shop := false
		for r in range(1, mrows.size() - 1):
			for node in mrows[r]:
				if node.type == "Shop":
					has_shop = true
		if not has_shop:
			bad_shop.append(seed_v)
	_check("map: boss row shape holds (40 seeds)", bad_shape, [])
	_check("map: edges never cross (40 seeds)", bad_cross, [])
	_check("map: all nodes reachable with exits (40 seeds)", bad_reach, [])
	_check("map: no same special twice in a row (40 seeds)", bad_consec, [])
	_check("map: max one Rest/Shop/Chest per row (40 seeds)", bad_rowdupe, [])
	_check("map: every act has a shop (40 seeds)", bad_shop, [])

	# --- loc coverage: the teaching layer + key chrome exists in BOTH tables, so a
	# string change can never silently regress DE/ES back to English again ---
	print("--- loc coverage ---")
	var de_tbl: Dictionary = preload("res://scripts/autoload/loc_de.gd").TABLE
	var es_tbl: Dictionary = preload("res://scripts/autoload/loc_es.gd").TABLE
	var cu_script := preload("res://scripts/combat/combat_ui.gd")
	var must: Array = []
	for k in cu_script.STATUS_DESC:
		must.append(cu_script.STATUS_DESC[k])
	must.append_array([
		"Their next move", "Attacks for %d.", "Attacks %d times for %d each (%d total).",
		"Braces for %d Block.", "Heals %d HP.", "Hits you with %s %d. ",
		"Buffs itself: %s +%d.", "Drains %d of your Aura.",
		"Taxes %d Aura if you're hoarding above a threshold.",
		"Summons backup into the fight.", "Bides its time.",
		"Energy", "Aura", "Gold",
		"Spent to play cards; refills to max at the start of each turn.",
		"Banked style — it persists the whole fight. 6+: +2 dmg · 12+: +1 draw · 18+: pierce · 24+: the Encore spotlight. Finishers spend it all.",
		"Run currency — spend it in shops on cards, removals, and relics.",
		"End Turn", "BLOCKED %d", "+Block", "+2DMG", "DRAW", "PIERCE",
		"Act %d/%d", "Gold %d", "Clout %d", "deck (%d)", "your deck  (%d cards)",
		"THE CRITIC:  ", "— FINALE —", "ENCORE ×%d!", "BOOED!",
		"Locked — unlock at %d Clout  (you have %d earned)",
		"Resume Run   (Act %d)", "Continue   (%d Clout)", "%d gold", "SOLD",
		"No passive.", "Drip +%d Aura/turn.",
		"Draw %d", "Discard %d", "Draw pile", "Discard pile",
		"%d cards. When it runs dry, your discard shuffles back in.",
		"%d cards. Played and discarded cards land here.", "up next", "up next: %s",
		"fresh rotation — the discard shuffles back in",
		"you keep the hand — it's all part of the plan",
		"nothing left to peek — your piles are empty",
		"your next %d cards — take one", "left is the top of the pile",
		"you reach for %s", "your hands are FULL — it stays in the pile",
	])
	# blanket rule: EVERY card description ships in both languages — 10 archetype-PR
	# cards had silently slipped the triple-edit rule before this assert existed
	for cid in Database.cards:
		must.append(Database.cards[cid].description)
	# events finally translate (all 11); spot-check one string per event so a
	# dropped key can't silently regress a whole encounter back to English
	must.append_array([
		"it's serving a look and lowkey staring back. unsettling fr.",
		"a hooded figure's got mystery cards. trust the process?",
		"\"let's unpack that deck, bestie.\" cut one card from your deck for good.",
		"a velvet box hums. \"trade a little vitality for a little power?\"",
		"suspiciously clean water, absolutely loaded with old coins.",
		"dusty, ornate, lowkey humming. rummage or nah?",
		"she's at a corner table, reviewing a matcha. she has DEFINITELY seen you.",
		"She sips. She nods, slowly. Your next fight is pre-reviewed: VIP room ahead.",
		"Her pen comes out. It's already writing. A heckler will attend your next fight.",
		"two clipboard interns from the Critic's office. they're rating fits today.",
		"a guy with a speaker offers to gas you up. rates negotiable.",
		"backstage at a venue. finders keepers is the law of the land here.",
		"the wizard group chat is BEEFING at 3am. someone has to say something.",
		"You move on, none the worse.",
	])
	for t in GameState.TREND_LABEL.values():
		must.append(String(t))
	for arr in GameState.CRITIC_LINES.values():
		for line in arr:
			must.append(String(line))
	var missing_de: Array = []
	var missing_es: Array = []
	for k in must:
		if not de_tbl.has(k):
			missing_de.append(k)
		if not es_tbl.has(k):
			missing_es.append(k)
	_check("teaching layer + chrome covered in DE", missing_de, [])
	_check("teaching layer + chrome covered in ES", missing_es, [])

	# --- rarity ladder: every card is a known tier with a colour (no silent grey gems) ---
	print("--- rarity ladder ---")
	var ladder := ["Common", "Rare", "Epic", "Legendary"]
	var bad_rarity: Array = []
	for cid in Database.cards:
		var c: CardData = Database.cards[cid]
		if c.rarity not in ladder or not CardView.RARITY_COLOR.has(c.rarity):
			bad_rarity.append("%s=%s" % [cid, c.rarity])
	_check("all cards have a valid rarity+colour", bad_rarity, [])

	# --- expansion: 30/30/30 pools + 30 relics, new ops, Ghosted, swag_cost, hooks ---
	print("--- expansion: content counts ---")
	_check("76 cards loaded", Database.cards.size(), 76)
	_check("30 relics loaded", Database.artifacts.size(), 30)
	_check("fire pool is 30", Database.get_wizard(&"fire").reward_pool.size(), 30)
	var bad_arti_rarity: Array = []
	for xaid in Database.artifacts:
		var xa: ArtifactData = Database.artifacts[xaid]
		if xa.rarity not in ["Common", "Rare", "Epic", "Legendary"]:
			bad_arti_rarity.append("%s=%s" % [xaid, xa.rarity])
	_check("all relics have a valid rarity", bad_arti_rarity, [])

	print("--- expansion: new ops ---")
	var xp1 := Combatant.new()
	xp1.max_hp = 80
	xp1.hp = 80
	var xcm1 := CombatManager.new()
	var xdeck: Array[CardData] = [Database.get_card(&"ember")]
	xcm1.start_combat(xp1, [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xcm1.hand = [Database.get_card(&"put_on_blast")]
	xcm1.play_card(xcm1.hand[0])
	_check("apply_status_all roasts every opp", [xcm1.enemies[0].status(&"burn"), xcm1.enemies[1].status(&"burn"), xcm1.enemies[2].status(&"burn")], [3, 3, 3])
	_check("apply_status_all counts as an AoE play", xcm1.aoe_plays, 1)
	# ember_pin boosts the room-wide apply PER enemy
	var xp2 := Combatant.new()
	xp2.max_hp = 80
	xp2.hp = 80
	var xcm2 := CombatManager.new()
	xcm2.start_combat(xp2, [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"burn_plus_1"])
	xcm2.hand = [Database.get_card(&"put_on_blast")]
	xcm2.play_card(xcm2.hand[0])
	_check("burn_plus_1 boosts apply_status_all per enemy", [xcm2.enemies[0].status(&"burn"), xcm2.enemies[1].status(&"burn")], [4, 4])

	# damage_x_status of:"self" — Unspoken Rizz at 5 Rizz: 5*2 + strength again = 15
	var xp3 := Combatant.new()
	xp3.max_hp = 80
	xp3.hp = 80
	var xcm3 := CombatManager.new()
	xcm3.start_combat(xp3, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xp3.add_status(&"strength", 5)
	var xhp0 := xcm3.enemies[0].hp
	xcm3.hand = [Database.get_card(&"unspoken_rizz")]
	xcm3.play_card(xcm3.hand[0])
	_check("unspoken_rizz deals (mult+1)x rizz", xhp0 - xcm3.enemies[0].hp, 15)

	# damage_x_status all:true — Burn Book reads each opp's OWN roast, then re-roasts
	var xp4 := Combatant.new()
	xp4.max_hp = 80
	xp4.hp = 80
	var xcm4 := CombatManager.new()
	xcm4.start_combat(xp4, [Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat"), Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xcm4.enemies[0].add_status(&"burn", 4)
	xcm4.enemies[2].add_status(&"burn", 2)
	var xhps: Array = [xcm4.enemies[0].hp, xcm4.enemies[1].hp, xcm4.enemies[2].hp]
	xcm4.hand = [Database.get_card(&"burn_book")]
	xcm4.play_card(xcm4.hand[0])
	_check("burn_book hits 2x each opp's own roast", [xhps[0] - xcm4.enemies[0].hp, xhps[1] - xcm4.enemies[1].hp, xhps[2] - xcm4.enemies[2].hp], [8, 0, 4])
	_check("burn_book re-roasts the room", [xcm4.enemies[0].status(&"burn"), xcm4.enemies[1].status(&"burn"), xcm4.enemies[2].status(&"burn")], [6, 2, 4])
	_check("burn_book counts as an AoE play", xcm4.aoe_plays, 1)

	# block_x_status of:"self" — Block Party scales with the Goon board
	var xp5 := Combatant.new()
	xp5.max_hp = 80
	xp5.hp = 80
	var xcm5 := CombatManager.new()
	xcm5.start_combat(xp5, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xp5.add_status(&"undead", 3)
	xcm5.hand = [Database.get_card(&"block_party")]
	xcm5.play_card(xcm5.hand[0])
	_check("block_party: 3 goons = 9 block", xp5.block, 9)
	_check("block_party leaves the goons alive", xp5.status(&"undead"), 3)
	xp5.block = 0
	xp5.add_status(&"undead", 1)
	xp5.add_status(&"frail", 1)
	xcm5.energy = 3
	xcm5.hand = [Database.get_card(&"block_party")]
	xcm5.play_card(xcm5.hand[0])
	_check("exposed softens both block parts", xp5.block, 8)
	# value-Glow flows through the flat op only (judge ruling: no whitelist change)
	var xp6 := Combatant.new()
	xp6.max_hp = 80
	xp6.hp = 80
	var xcm6 := CombatManager.new()
	xcm6.start_combat(xp6, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [], 1.0, 1.0, {&"block_party": "value"})
	xp6.add_status(&"undead", 2)
	xcm6.hand = [Database.get_card(&"block_party")]
	xcm6.play_card(xcm6.hand[0])
	_check("value-glow'd block_party: (3+2) flat + 4 scaled", xp6.block, 9)

	# self_status_x_self — Left on Read converts Rizz to Ghosted, capped at 4
	var xp7 := Combatant.new()
	xp7.max_hp = 80
	xp7.hp = 80
	var xcm7 := CombatManager.new()
	xcm7.start_combat(xp7, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xp7.add_status(&"strength", 3)
	xcm7.hand = [Database.get_card(&"left_on_read")]
	xcm7.play_card(xcm7.hand[0])
	_check("left_on_read: ghosted = rizz", xp7.status(&"evade"), 3)
	xp7.statuses.erase(&"evade")
	xp7.add_status(&"strength", 4)   # now 7
	xcm7.energy = 3
	xcm7.hand = [Database.get_card(&"left_on_read")]
	xcm7.play_card(xcm7.hand[0])
	_check("left_on_read caps at 4", xp7.status(&"evade"), 4)
	var xp8 := Combatant.new()
	xp8.max_hp = 80
	xp8.hp = 80
	var xcm8 := CombatManager.new()
	xcm8.start_combat(xp8, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xcm8.hand = [Database.get_card(&"left_on_read")]
	xcm8.play_card(xcm8.hand[0])
	_check("left_on_read is dead at 0 rizz", xp8.status(&"evade"), 0)

	print("--- expansion: Ghosted ---")
	var xp9 := Combatant.new()
	xp9.max_hp = 80
	xp9.hp = 80
	var xcm9 := CombatManager.new()
	xcm9.start_combat(xp9, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xp9.add_status(&"evade", 2)
	xcm9.swag = 20   # hoarding above pierce — a dodged hit must NOT count as a flex
	xcm9._resolve_intent(xcm9.enemies[0], {"op": "attack", "amount": 5, "hits": 3})
	_check("ghosted eats 2 of 3 hits", xp9.hp, 75)
	_check("ghosted stacks consumed", xp9.status(&"evade"), 0)
	_check("dodged hits are not a flex", xcm9.flexed, true)   # 3rd hit landed while hoarding
	var xp10 := Combatant.new()
	xp10.max_hp = 80
	xp10.hp = 80
	var xcm10 := CombatManager.new()
	xcm10.start_combat(xp10, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xp10.add_status(&"evade", 3)
	xcm10.swag = 20
	xcm10._resolve_intent(xcm10.enemies[0], {"op": "attack", "amount": 5, "hits": 2})
	_check("full dodge leaves hp untouched", xp10.hp, 80)
	_check("a fully dodged turn never flexes", xcm10.flexed, false)
	xcm10.end_turn()
	_check("ghosted wiped at next turn start", xp10.status(&"evade"), 0)

	print("--- expansion: swag_cost ---")
	var xp11 := Combatant.new()
	xp11.max_hp = 80
	xp11.hp = 80
	var xcm11 := CombatManager.new()
	xcm11.start_combat(xp11, [Database.get_enemy(&"alley_cat")], xdeck, 0, true)
	xcm11.swag = 5
	_check("hard_launch unplayable below its aura cost", xcm11.can_play(Database.get_card(&"hard_launch")), false)
	xcm11.gain_swag(13)   # 5 -> 18, through gain_swag so the peak tracks
	var xhp1 := xcm11.enemies[0].hp
	xcm11.hand = [Database.get_card(&"hard_launch")]
	xcm11.play_card(xcm11.hand[0])
	_check("hard_launch spends AFTER the threshold snapshot (18+2 dmg)", xhp1 - xcm11.enemies[0].hp, 20)
	_check("hard_launch leaves the rest banked", xcm11.swag, 10)
	_check("aura spend is not pose_swag", xcm11.pose_swag, 0)
	_check("aura spend never lowers the peak", xcm11.peak_swag, 18)

	print("--- expansion: relic hooks ---")
	var xp12 := Combatant.new()
	xp12.max_hp = 80
	xp12.hp = 80
	var xcm12 := CombatManager.new()
	xcm12.start_combat(xp12, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"no_boo"])
	xcm12.encore = 2
	xcm12.swag = 10
	xcm12.end_turn()
	_check("velvet_rope: no boo, no aura loss", [xcm12.booed, xcm12.swag >= 10, xcm12.encore], [false, true, 0])

	var xp13 := Combatant.new()
	xp13.max_hp = 80
	xp13.hp = 80
	var xcm13 := CombatManager.new()
	xcm13.start_combat(xp13, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"finisher_refund_25"])
	xcm13.swag = 16
	xcm13.hand = [Database.get_card(&"grand_finale")]
	xcm13.play_card(xcm13.hand[0])
	_check("royalties refunds a quarter of the spend", xcm13.swag, 4)

	var xp14 := Combatant.new()
	xp14.max_hp = 80
	xp14.hp = 80
	var xcm14 := CombatManager.new()
	xcm14.start_combat(xp14, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"block_carryover_6"])
	xp14.block = 20
	xcm14.end_turn()
	_check("set_spray keeps up to 6 block", xp14.block, 6)

	var xp15 := Combatant.new()
	xp15.max_hp = 80
	xp15.hp = 80
	var xcm15 := CombatManager.new()
	xcm15.start_combat(xp15, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"pierce_at_12"])
	xcm15.gain_swag(12)
	_check("backstage_pass pierces at 12", xcm15.swag_pierces(), true)
	_check("critic grading lines unmoved by backstage_pass", xcm15.thresholds_lit(), 2)

	var xp16 := Combatant.new()
	xp16.max_hp = 80
	xp16.hp = 80
	var xcm16 := CombatManager.new()
	xcm16.start_combat(xp16, [Database.get_enemy(&"possessed_wardrobe")], xdeck, 0, true, [&"goons_strike_on_pose"])
	xp16.add_status(&"undead", 3)
	var xhp2 := xcm16.enemies[0].hp
	xcm16.hand = [Database.get_card(&"serve_face")]
	xcm16.play_card(xcm16.hand[0])
	_check("fan_behavior: first pose commands a goon strike", xhp2 - xcm16.enemies[0].hp, 6)
	xcm16.energy = 3
	var xhp3 := xcm16.enemies[0].hp
	xcm16.hand = [Database.get_card(&"strike_a_pose")]
	xcm16.play_card(xcm16.hand[0])
	_check("fan_behavior fires once per turn", xhp3 - xcm16.enemies[0].hp, 0)

	var xp17 := Combatant.new()
	xp17.max_hp = 80
	xp17.hp = 80
	var xcm17 := CombatManager.new()
	xcm17.start_combat(xp17, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"retain_hand_always"])
	var xkeep := Database.get_card(&"ember")
	xcm17.hand = [xkeep]
	xcm17.end_turn()
	_check("camera_roll keeps the hand", xkeep in xcm17.hand, true)

	var xp18 := Combatant.new()
	xp18.max_hp = 80
	xp18.hp = 80
	var xcm18 := CombatManager.new()
	xcm18.start_combat(xp18, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"borrowed_drip"])
	_check("borrowed_designer: +12 aura, exposed 2", [xcm18.swag, xp18.status(&"frail"), xcm18.peak_swag], [12, 2, 12])

	var xp19 := Combatant.new()
	xp19.max_hp = 80
	xp19.hp = 80
	var xcm19 := CombatManager.new()
	xcm19.start_combat(xp19, [Database.get_enemy(&"alley_cat")], xdeck, 0, true, [&"sac_swag_1"])
	xp19.add_status(&"undead", 1)
	var xswag0 := xcm19.swag
	xcm19.hand = [Database.get_card(&"bone_offering")]
	xcm19.play_card(xcm19.hand[0])
	_check("celebration_of_life tips +1 aura per sac", xcm19.swag - xswag0, 4)
	_check("the sendoff counts as pose_swag", xcm19.pose_swag, 1)

	print("--- expansion: meta relics ---")
	var sv_arts: Array[StringName] = GameState.run_artifacts.duplicate()
	var sv_fat: Dictionary = GameState.critic_fatigue.duplicate()
	var sv_rating := GameState.critic_last_rating
	var sv_pending := GameState.pending_critic
	var sv_trend: StringName = GameState.trend
	var sv_pub := GameState.publicist_used
	GameState.run_artifacts = [&"publicist"]
	GameState.publicist_used = false
	GameState.record_show_rating({"rating": "C", "signature": &"grind"})
	_check("publicist spins the first C into a B", GameState.critic_last_rating, "B")
	_check("publicist took the call", GameState.publicist_used, true)
	GameState.record_show_rating({"rating": "C", "signature": &"grind"})
	_check("publicist works once per act", GameState.critic_last_rating, "C")
	var xsnap := GameState._run_to_dict()
	GameState.publicist_used = false
	_check("publicist_used survives the run snapshot", bool(xsnap.get("publicist_used", false)), true)
	GameState.run_artifacts = [&"parasocial"]
	GameState.critic_fatigue = {}
	GameState.record_show_rating({"rating": "S", "signature": &"spread"})
	GameState.record_show_rating({"rating": "S", "signature": &"spread"})
	_check("parasocial: fatigue never builds", GameState.critic_fatigue.is_empty(), true)
	_check("parasocial: freshness pinned at 1.0", GameState.critic_last_freshness, 1.0)
	GameState.run_artifacts = []
	GameState.trend = &"flop_era"
	_check("flop_era drains 1 without trendsetter", GameState.trend_drip_mod(), -1)
	GameState.run_artifacts = [&"trendsetter"]
	_check("trendsetter floors a negative trend at 0", GameState.trend_drip_mod(), 0)
	GameState.trend = &"its_giving"
	_check("trendsetter leaves positive trends alone", GameState.trend_drip_mod(), 1)
	var sv_clout := GameState.clout_earned
	GameState.clout_earned = 9999
	GameState.run_artifacts = []
	var xpick := GameState.random_unowned_artifact()
	_check("weighted picker returns a real relic", Database.get_artifact(xpick) != null, true)
	var xall: Array[StringName] = []
	for xid in Database.artifacts:
		xall.append(xid)
	GameState.run_artifacts = xall
	_check("weighted picker returns nothing when you own it all", GameState.random_unowned_artifact(), &"")
	GameState.clout_earned = sv_clout
	GameState.run_artifacts = sv_arts
	GameState.critic_fatigue = sv_fat
	GameState.critic_last_rating = sv_rating
	GameState.pending_critic = sv_pending
	GameState.trend = sv_trend
	GameState.publicist_used = sv_pub

	print("=== result: %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
