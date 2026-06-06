class_name Encounters
extends RefCounted
## Encounter pools — groups of enemies chosen by map depth. Deeper = bigger, nastier
## groups. (Stats are further scaled by depth in GameState.node_scales.)

static func normal(depth: float, rng: RandomNumberGenerator) -> Array:
	var early := [
		[&"alley_cat"], [&"disgruntled_pigeon"], [&"angry_toaster"],
		[&"sock_puppet", &"sock_puppet"], [&"garden_gnome"], [&"black_cat"],
		[&"goblin_gremlin", &"goblin_gremlin"], [&"rabid_roomba"], [&"feral_houseplant"],
		[&"wifi_router"], [&"goblin_gremlin", &"rabid_roomba"],
	]
	var mid := [
		[&"garden_gnome", &"angry_toaster"], [&"haunted_umbrella", &"sock_puppet"],
		[&"disgruntled_pigeon", &"disgruntled_pigeon"], [&"alley_cat", &"haunted_umbrella"],
		[&"sock_puppet", &"sock_puppet", &"angry_toaster"], [&"possessed_mannequin"],
		[&"feral_houseplant", &"goblin_gremlin"], [&"rabid_roomba", &"rabid_roomba"],
		[&"shade_thrower", &"sock_puppet"], [&"black_cat", &"clout_goblin"],
		[&"vending_machine"], [&"wifi_router", &"clout_goblin"],
	]
	var late := [
		[&"garden_gnome", &"haunted_umbrella"], [&"garden_gnome", &"garden_gnome"],
		[&"haunted_umbrella", &"angry_toaster", &"sock_puppet"],
		[&"disgruntled_pigeon", &"haunted_umbrella"], [&"cursed_mirror", &"feral_houseplant"],
		[&"possessed_mannequin", &"rabid_roomba"], [&"cursed_mirror", &"goblin_gremlin"],
		[&"shade_thrower", &"clout_goblin"], [&"black_cat", &"cursed_mirror"],
		[&"vending_machine", &"wifi_router"], [&"vending_machine", &"shade_thrower"],
	]
	var pool: Array = early if depth < 0.34 else (mid if depth < 0.67 else late)
	return _pick(pool, rng)

static func elite(rng: RandomNumberGenerator) -> Array:
	return _pick([
		[&"possessed_wardrobe"], [&"taxidermy_owl"], [&"possessed_wardrobe", &"sock_puppet"],
		[&"gargoyle_cherub"], [&"cursed_mirror", &"gargoyle_cherub"], [&"taxidermy_owl", &"goblin_gremlin"],
		[&"ringlight_wraith"], [&"ringlight_wraith", &"shade_thrower"],
		[&"gym_rat"], [&"gym_rat", &"clout_goblin"],
	], rng)

# Two act-bosses now; pick one so the run's finale varies.
static func boss(rng: RandomNumberGenerator = null) -> Array:
	var bosses := [&"the_critic", &"the_algorithm"]
	if rng == null:
		return [bosses[0]]
	return [bosses[rng.randi_range(0, bosses.size() - 1)]]

static func _pick(pool: Array, rng: RandomNumberGenerator) -> Array:
	return (pool[rng.randi_range(0, pool.size() - 1)] as Array).duplicate()
