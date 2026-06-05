extends Node
## Headless test harness for the combat engine. Scripts a deterministic fight and
## asserts the Swag economy, Burn, thresholds, and the finisher all behave.
## Run by temporarily pointing the main scene here (see run_tests.sh).

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
	player.display_name = "Pyromancer"
	player.max_hp = 72
	player.hp = 72

	var cat := Database.get_enemy(&"alley_cat")
	_check("enemy loaded", cat != null, true)

	# Deck of known cards; we inject hands directly for determinism.
	var deck: Array[CardData] = [Database.get_card(&"ember"), Database.get_card(&"ignite")]
	cm.start_combat(player, cat, deck, 2, true)   # drip = 2

	# Turn 1 start: energy 3, swag = drip 2
	_check("t1 energy", cm.energy, 3)
	_check("t1 swag (drip)", cm.swag, 2)

	# Play Ignite: apply 3 Burn, Pose +1 Swag
	cm.hand = [Database.get_card(&"ignite")]
	cm.play_card(cm.hand[0])
	_check("enemy burn after ignite", cm.enemy.status(&"burn"), 3)
	_check("swag after ignite pose", cm.swag, 3)

	# Play Ember: 6 dmg, swag 3 (<5) so NO threshold bonus -> 28 - 6 = 22
	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after ember (no bonus)", cm.enemy.hp, 22)

	# End turn -> enemy turn: Burn ticks 3 (22->19, burn 3->2), intent[0] attack 6 (72->66)
	cm.end_turn()
	_check("enemy hp after burn tick", cm.enemy.hp, 19)
	_check("enemy burn decayed", cm.enemy.status(&"burn"), 2)
	_check("player hp after cat attack", cm.player.hp, 66)

	# Turn 2 start: swag 3 + drip 2 = 5  -> threshold reached, attacks +2
	_check("t2 swag (>=5 threshold)", cm.swag, 5)
	_check("swag damage bonus active", cm.swag_damage_bonus(), 2)

	# Burn ticks again at NEXT enemy turn, not now. Play Ember: 6 + 2 = 8 -> 19 - 8 = 11
	cm.hand = [Database.get_card(&"ember")]
	cm.play_card(cm.hand[0])
	_check("enemy hp after boosted ember", cm.enemy.hp, 11)

	# Finisher: set a big pool, Grand Finale = swag*3 (+2 bonus since >=5) -> spends all
	cm.swag = 6
	cm.hand = [Database.get_card(&"grand_finale")]
	var hp_before := cm.enemy.hp
	cm.play_card(cm.hand[0])
	# 6*3 + 2 bonus = 20 damage; enemy had 11 -> dead, swag emptied
	_check("swag spent by finisher", cm.swag, 0)
	_check("enemy defeated by finisher", cm.enemy.is_dead(), true)
	_check("state is WIN", cm.state, CombatManager.State.WIN)

	# --- Necro: Undead + Sacrifice -------------------------------------------
	print("--- necro: undead & sacrifice ---")
	var cm2 := CombatManager.new()
	var necro := Combatant.new()
	necro.display_name = "Necromancer"
	necro.max_hp = 68
	necro.hp = 68
	var cat2 := Database.get_enemy(&"alley_cat")
	var deck2: Array[CardData] = [Database.get_card(&"bone_dart")]
	cm2.start_combat(necro, cat2, deck2, 0, true)   # drip 0 for clean swag math

	cm2.hand = [Database.get_card(&"raise_dead")]
	cm2.play_card(cm2.hand[0])
	cm2.hand = [Database.get_card(&"raise_dead")]
	cm2.play_card(cm2.hand[0])
	_check("undead summoned", cm2.player.status(&"undead"), 2)
	_check("swag from two poses", cm2.swag, 2)

	cm2.end_turn()                                  # 2 Undead strike for 4 (28 -> 24)
	_check("cat hp after undead strike", cm2.enemy.hp, 24)
	_check("undead persist across turn", cm2.player.status(&"undead"), 2)

	var ehp := cm2.enemy.hp
	cm2.hand = [Database.get_card(&"macabre_bow")]   # sacrifice 1 Undead: 7 dmg + 3 swag
	cm2.play_card(cm2.hand[0])
	_check("undead after sacrifice", cm2.player.status(&"undead"), 1)
	_check("cat hp after macabre bow", cm2.enemy.hp, ehp - 7)
	_check("swag after macabre bow", cm2.swag, 5)

	# --- M3: outfit passives -------------------------------------------------
	print("--- m3: outfit passives ---")
	var cm3 := CombatManager.new()
	var pp := Combatant.new()
	pp.max_hp = 72
	pp.hp = 72
	var deck3: Array[CardData] = [Database.get_card(&"ember")]
	var pass3: Array[StringName] = [&"energy_plus_1", &"burn_plus_1", &"start_block_5", &"pose_plus_1"]
	cm3.start_combat(pp, Database.get_enemy(&"alley_cat"), deck3, 0, true, pass3)
	_check("energy_plus_1 → max energy 4", cm3.max_energy, 4)
	_check("energy this turn 4", cm3.energy, 4)
	_check("start_block_5 → 5 block", cm3.player.block, 5)
	cm3.hand = [Database.get_card(&"ignite")]
	cm3.play_card(cm3.hand[0])
	_check("burn_plus_1 → 4 burn", cm3.enemy.status(&"burn"), 4)
	_check("pose_plus_1 → swag 2", cm3.swag, 2)

	var cm4 := CombatManager.new()
	var p4 := Combatant.new()
	p4.max_hp = 68
	p4.hp = 68
	var deck4: Array[CardData] = [Database.get_card(&"bone_dart")]
	var pass4: Array[StringName] = [&"undead_plus_1_on_summon"]
	cm4.start_combat(p4, Database.get_enemy(&"alley_cat"), deck4, 0, true, pass4)
	cm4.hand = [Database.get_card(&"raise_dead")]
	cm4.play_card(cm4.hand[0])
	_check("undead_plus_1_on_summon → 2 undead", cm4.player.status(&"undead"), 2)

	print("=== result: %d passed, %d failed ===" % [_pass, _fail])
	get_tree().quit(1 if _fail > 0 else 0)
