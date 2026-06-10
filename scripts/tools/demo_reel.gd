extends Node
## Dev tool: auto-plays a fight for raw gameplay footage. Record with movie
## maker (captures every frame + audio):
##   PW_NO_SAVE=1 godot --write-movie /tmp/gameplay.avi --fixed-fps 30 scenes/tools/demo_reel.tscn
## The bot plays Morticia: raises the squad, banks Aura, commands strikes —
## the run continues into the reward screen (stamp) before quitting.

var _elapsed := 0.0

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 648))
	# tree-level quit: survives the victory scene-swap (which frees this node),
	# so the movie file always finalizes cleanly
	get_tree().create_timer(75.0).timeout.connect(func():
		(Engine.get_main_loop() as SceneTree).quit())
	GameState.start_run(&"necro")
	GameState.finalize_loadout()
	GameState.seen_tutorial = true
	GameState.gold = 86
	GameState.player_max_hp = 140   # the bot can't block; stack the take for a win
	GameState.player_hp = 140
	GameState.enter(0, 0)
	GameState.map[0][0]["enemies"] = [&"gym_rat", &"clout_goblin"]
	var c: Node = load("res://scenes/combat/combat.tscn").instantiate()
	add_child(c)
	_drive(c)

func _drive(c: Node) -> void:
	await get_tree().create_timer(2.0).timeout
	while is_instance_valid(c) and c.cm != null and _elapsed < 70.0:
		var cm: CombatManager = c.cm
		if cm.state == CombatManager.State.PLAYER_TURN:
			var played := false
			for card in cm.hand.duplicate():
				if cm.can_play(card):
					var alive := cm.living_enemies()
					if not alive.is_empty():
						cm.set_target(cm.enemies.find(alive[0]))
					await get_tree().create_timer(0.5).timeout
					cm.play_card(card)
					played = true
					break
			if not played:
				await get_tree().create_timer(0.8).timeout
				cm.end_turn()
		await get_tree().create_timer(1.1).timeout
		_elapsed += 1.6
	# linger on whatever screen the run reached (reward stamp etc.), then cut
	await get_tree().create_timer(6.0).timeout
	get_tree().quit()
