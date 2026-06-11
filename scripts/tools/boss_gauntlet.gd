extends Node
## One-off probe: every boss vs every wizard with act-appropriate decks, 12 tries.
const SimBot = preload("res://scripts/tests/balance_sim.gd")

func _ready() -> void:
	var bot = SimBot.new()
	var cases := [[1, &"the_critic"], [2, &"the_bouncer"], [3, &"the_algorithm"], [3, &"the_talent_agent"]]
	for c in cases:
		var act: int = c[0]
		var bid: StringName = c[1]
		for wid: StringName in [&"fire", &"necro", &"rizz"]:
			var wins := 0
			var turns := 0.0
			for i in 24:
				var deck: Array = bot._build_deck(wid, act)
				var sc: Array = bot._scales(act, 0, "Boss", 9)
				var r: Dictionary = bot._sim_combat(wid, [bid], deck, [0, 3, 4, 5][act], [], sc[0], sc[1], "balanced", i, 0)
				if r.win:
					wins += 1
				turns += r.turns
			print("  act%d %-18s vs %-6s win %3d%%  avg turns %.1f" % [act, bid, wid, wins * 100 / 24, turns / 24])
	bot.free()
	get_tree().quit()
