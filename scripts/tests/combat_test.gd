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

	print("=== result: %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
