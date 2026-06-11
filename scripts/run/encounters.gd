class_name Encounters
extends RefCounted
## Encounter pools — every act is a FLOOR with its own cast, so the climb tells a
## story: Act 1 "the Block" (your own hexed neighborhood — open-mic era), Act 2
## "the Scene" (the venue: fashion, mirrors, the door), Act 3 "the Feed"
## (terminally online — and the industry that runs it). Deeper rows within an act
## still pull bigger groups; stats scale further in GameState.node_scales.

# Per-act normal pools, early/mid/late by row depth within the act.
const NORMAL := {
	1: {   # THE BLOCK — domestic objects & critters the hex got to first
		"early": [
			[&"sock_puppet"], [&"alley_cat"], [&"disgruntled_pigeon"], [&"angry_toaster"],
			[&"sock_puppet", &"sock_puppet"], [&"feral_houseplant"], [&"rabid_roomba"],
		],
		"mid": [
			[&"garden_gnome"], [&"black_cat"], [&"alley_cat", &"sock_puppet"],
			[&"feral_houseplant", &"sock_puppet"], [&"rabid_roomba", &"rabid_roomba"],
			[&"angry_toaster", &"disgruntled_pigeon"], [&"garden_gnome", &"sock_puppet"],
		],
		"late": [
			[&"garden_gnome", &"angry_toaster"], [&"black_cat", &"alley_cat"],
			[&"garden_gnome", &"garden_gnome"], [&"feral_houseplant", &"rabid_roomba"],
			[&"disgruntled_pigeon", &"disgruntled_pigeon"], [&"black_cat", &"feral_houseplant"],
		],
	},
	2: {   # THE SCENE — the venue's mirrors, mannequins and red carpets turn on you
		"early": [
			[&"haunted_umbrella"], [&"possessed_mannequin"], [&"disco_ball"],
			[&"vending_machine"], [&"haunted_umbrella", &"sock_puppet"],
		],
		"mid": [
			[&"cursed_mirror"], [&"possessed_mannequin", &"haunted_umbrella"],
			[&"disco_ball", &"haunted_umbrella"], [&"the_irs"],
			[&"vending_machine", &"disco_ball"], [&"cursed_mirror", &"possessed_mannequin"],
		],
		"late": [
			[&"cursed_mirror", &"disco_ball"], [&"possessed_mannequin", &"possessed_mannequin"],
			[&"the_irs", &"haunted_umbrella"], [&"cursed_mirror", &"vending_machine"],
			[&"disco_ball", &"disco_ball"], [&"vending_machine", &"possessed_mannequin"],
		],
	},
	3: {   # THE FEED — extremely online entities (and the IRS knows you're rich now)
		"early": [
			[&"goblin_gremlin", &"goblin_gremlin"], [&"wifi_router"], [&"reply_guy"],
			[&"npc_streamer"], [&"goblin_gremlin", &"reply_guy"],
		],
		"mid": [
			[&"clout_goblin"], [&"shade_thrower", &"reply_guy"], [&"the_irs"],
			[&"wifi_router", &"clout_goblin"], [&"npc_streamer", &"npc_streamer"],
			[&"shade_thrower", &"goblin_gremlin"],
		],
		"late": [
			[&"clout_goblin", &"shade_thrower"], [&"the_irs", &"reply_guy"],
			[&"wifi_router", &"npc_streamer"], [&"shade_thrower", &"shade_thrower", &"reply_guy"],
			[&"clout_goblin", &"npc_streamer"], [&"wifi_router", &"wifi_router"],
		],
	},
}

# Per-act elite pools — each act's mini-celebrities.
const ELITE := {
	1: [[&"taxidermy_owl"], [&"gargoyle_cherub"], [&"taxidermy_owl", &"sock_puppet"],
		[&"gargoyle_cherub", &"feral_houseplant"]],
	2: [[&"possessed_wardrobe"], [&"ringlight_wraith"], [&"possessed_wardrobe", &"possessed_mannequin"],
		[&"ringlight_wraith", &"disco_ball"]],
	3: [[&"gym_rat"], [&"engagement_farmer"], [&"gym_rat", &"reply_guy"]],
}

static func normal(act: int, depth: float, rng: RandomNumberGenerator) -> Array:
	var pools: Dictionary = NORMAL.get(clampi(act, 1, 3), NORMAL[1])
	var pool: Array = pools["early"] if depth < 0.34 else (pools["mid"] if depth < 0.67 else pools["late"])
	return _pick(pool, rng)

static func elite(act: int, rng: RandomNumberGenerator) -> Array:
	return _pick(ELITE.get(clampi(act, 1, 3), ELITE[1]), rng)

## Each floor ends on ITS OWN headliner: the Critic reviews your debut, the
## Bouncer guards the Scene's door, and the Feed serves either the machine
## (The Algorithm) or the industry (The Talent Agent).
static func boss(act: int, rng: RandomNumberGenerator = null) -> Array:
	match clampi(act, 1, 3):
		1:
			return [&"the_critic"]
		2:
			return [&"the_bouncer"]
		_:
			var finale := [&"the_algorithm", &"the_talent_agent"]
			if rng == null:
				return [finale[0]]
			return [finale[rng.randi_range(0, finale.size() - 1)]]

static func _pick(pool: Array, rng: RandomNumberGenerator) -> Array:
	return (pool[rng.randi_range(0, pool.size() - 1)] as Array).duplicate()
