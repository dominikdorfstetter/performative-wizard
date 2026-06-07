extends Node
## Procedural pixel-art generator. Builds a 16x16 sprite per enemy from a small set of
## parameters (colour, body shape, topper feature, eyes) and caches it as an ImageTexture.
## Displayed scaled up with nearest-neighbour filtering for crisp pixels.

const SIZE := 16
const OUTLINE := Color("14111c")

const DEF := {
	&"alley_cat": {"c": "e0883c", "shape": "round", "feat": "ears", "eye": "8fd96b", "angry": false},
	&"disgruntled_pigeon": {"c": "8a93a6", "shape": "round", "feat": "beak", "eye": "ffffff", "angry": true},
	&"garden_gnome": {"c": "d8b088", "shape": "tall", "feat": "hat", "eye": "ffffff", "angry": false},
	&"angry_toaster": {"c": "b9c0c9", "shape": "square", "feat": "slots", "eye": "ffffff", "angry": true},
	&"haunted_umbrella": {"c": "8a5bd0", "shape": "tall", "feat": "wings", "eye": "d6ff66", "angry": true},
	&"sock_puppet": {"c": "e6e6ee", "shape": "tall", "feat": "mouth", "eye": "ffffff", "angry": false},
	&"possessed_wardrobe": {"c": "8a5a3a", "shape": "square", "feat": "doors", "eye": "ff6b6b", "angry": true},
	&"taxidermy_owl": {"c": "9a6b3f", "shape": "round", "feat": "tufts", "eye": "ffd24a", "angry": false},
	&"the_critic": {"c": "b23b3b", "shape": "round", "feat": "horns", "eye": "ffd24a", "angry": true},
	&"feral_houseplant": {"c": "4e9a48", "shape": "blob", "feat": "spikes", "eye": "ffffff", "angry": true},
	&"cursed_mirror": {"c": "acc4d4", "shape": "square", "feat": "none", "eye": "c08ce0", "angry": false},
	&"possessed_mannequin": {"c": "d8c2a2", "shape": "tall", "feat": "none", "eye": "241a30", "angry": true, "cyclops": true},
	&"rabid_roomba": {"c": "4a4f57", "shape": "blob", "feat": "antenna", "eye": "ff5a5a", "angry": true},
	&"goblin_gremlin": {"c": "6f9a3a", "shape": "round", "feat": "fangs", "eye": "ffd24a", "angry": true},
	&"gargoyle_cherub": {"c": "9aa0a8", "shape": "round", "feat": "wings", "eye": "ffffff", "angry": true},
	&"black_cat": {"c": "2c2735", "shape": "round", "feat": "ears", "eye": "ffd24a", "angry": true},
	&"shade_thrower": {"c": "5b4a78", "shape": "diamond", "feat": "crest", "eye": "ff6b8f", "angry": true},
	&"clout_goblin": {"c": "7aa83a", "shape": "round", "feat": "fangs", "eye": "ffd24a", "angry": true},
	&"ringlight_wraith": {"c": "d8d2e8", "shape": "diamond", "feat": "halo", "eye": "ff5ab0", "angry": true},
	&"wifi_router": {"c": "2c3a4a", "shape": "square", "feat": "antenna", "eye": "5fd0e0", "angry": true},
	&"vending_machine": {"c": "c0423c", "shape": "tall", "feat": "slots", "eye": "ffd24a", "angry": true},
	&"gym_rat": {"c": "9a8a78", "shape": "round", "feat": "ears", "eye": "ff5a5a", "angry": true},
	&"the_algorithm": {"c": "26243a", "shape": "square", "feat": "antenna", "eye": "ff5ab0", "angry": true},
	# Critic's heckler — a loudmouth she drops into a flop room.
	&"heckler": {"c": "9a5fbf", "shape": "round", "feat": "mouth", "eye": "ffd24a", "angry": true},
	# Summoned minion ("goon") for the necromancer's Undead stacks.
	&"goon": {"c": "7fa86a", "shape": "round", "feat": "tufts", "eye": "ff4d4d", "angry": true},
}

# wizards: humanoid sprites (pointy hat, face, robe)
const WIZ := {
	&"fire": {"hat": "b5302b", "robe": "e0883c", "skin": "eec8a4", "trim": "ffd24a", "motif": "flame"},
	&"necro": {"hat": "2e2440", "robe": "57804a", "skin": "cdd2dd", "trim": "8fd96b", "motif": "skull"},
	&"rizz": {"hat": "c23b8a", "robe": "e0a93c", "skin": "eec8a4", "trim": "ff8fd0", "shades": true, "motif": "chain"},
}

# Small 16x16 motif icons for cards/keywords. Each is layers of horizontal spans
# [row, x0, x1] painted in order.
const ICON := {
	"sword": [
		{"c": "8a5a3a", "s": [[12, 3, 4], [11, 4, 5]]},
		{"c": "ffd24a", "s": [[11, 4, 7], [10, 5, 6]]},
		{"c": "cdd3dd", "s": [[3, 11, 12], [4, 10, 11], [5, 9, 10], [6, 8, 9], [7, 7, 8], [8, 6, 7], [9, 6, 6], [10, 5, 6]]},
		{"c": "f4f8ff", "s": [[2, 12, 13], [3, 12, 12]]},
	],
	"fire": [
		{"c": "d9531f", "s": [[4, 8, 8], [5, 7, 9], [6, 7, 9], [7, 6, 10], [8, 6, 10], [9, 5, 11], [10, 5, 11], [11, 6, 10], [12, 7, 9]]},
		{"c": "f2902f", "s": [[7, 8, 9], [8, 7, 9], [9, 7, 10], [10, 7, 10], [11, 8, 9]]},
		{"c": "ffd24a", "s": [[9, 8, 9], [10, 8, 9], [11, 8, 8]]},
	],
	"shield": [
		{"c": "3f72c8", "s": [[3, 5, 10], [4, 4, 11], [5, 4, 11], [6, 4, 11], [7, 4, 11], [8, 5, 10], [9, 5, 10], [10, 6, 9], [11, 7, 8]]},
		{"c": "cfe0ff", "s": [[5, 7, 8], [6, 7, 8], [7, 7, 8]]},
	],
	"star": [
		{"c": "ff5ab0", "s": [[3, 7, 8], [4, 7, 8], [5, 7, 8], [6, 7, 8], [7, 3, 12], [8, 3, 12], [9, 7, 8], [10, 7, 8], [11, 7, 8], [12, 7, 8]]},
		{"c": "ffd6ef", "s": [[7, 7, 8], [8, 7, 8]]},
	],
	"skull": [
		{"c": "e8e8ee", "s": [[3, 5, 10], [4, 4, 11], [5, 4, 11], [6, 4, 11], [7, 4, 11], [8, 4, 11], [9, 5, 10], [10, 5, 10], [11, 6, 9]]},
		{"c": "201826", "s": [[6, 5, 6], [7, 5, 6], [6, 9, 10], [7, 9, 10], [8, 7, 8], [10, 6, 6], [10, 8, 8], [10, 10, 10]]},
	],
	"bones": [
		{"c": "e8e8ee", "s": [[3, 3, 4], [4, 4, 5], [5, 5, 6], [6, 6, 7], [7, 7, 8], [8, 8, 9], [9, 9, 10], [10, 10, 11], [11, 11, 12], [3, 11, 12], [4, 10, 11], [5, 9, 10], [6, 8, 9], [8, 6, 7], [9, 5, 6], [10, 4, 5], [11, 3, 4]]},
	],
	"drop": [
		{"c": "4fae5a", "s": [[3, 8, 8], [4, 7, 9], [5, 7, 9], [6, 6, 10], [7, 6, 10], [8, 5, 11], [9, 5, 11], [10, 6, 10], [11, 7, 9], [12, 8, 8]]},
		{"c": "bdf0c4", "s": [[6, 7, 7], [7, 7, 7]]},
	],
	"burst": [
		{"c": "f2902f", "s": [[3, 8, 8], [4, 8, 8], [7, 8, 9], [8, 7, 9], [9, 7, 9], [12, 8, 8], [13, 8, 8], [8, 3, 5], [8, 11, 13], [4, 4, 4], [5, 5, 5], [11, 11, 11], [10, 10, 10], [4, 12, 12], [5, 11, 11], [11, 5, 5], [12, 4, 4]]},
		{"c": "ffd24a", "s": [[8, 8, 8]]},
	],
	"swirl": [
		{"c": "a878d8", "s": [[3, 6, 9], [4, 5, 5], [4, 10, 10], [5, 4, 4], [6, 4, 4], [7, 4, 5], [8, 5, 6], [9, 6, 9], [10, 9, 10]]},
		{"c": "e0caf5", "s": [[6, 8, 9], [7, 8, 9]]},
	],
	"rizz": [{"c": "ffd24a", "s": [[2, 7, 8], [3, 6, 9], [4, 5, 10], [5, 4, 11], [6, 6, 9], [7, 7, 8], [8, 7, 8], [9, 7, 8], [10, 7, 8], [11, 7, 8]]}],
	"cooked": [{"c": "e0563a", "s": [[3, 7, 8], [4, 7, 8], [5, 7, 8], [6, 7, 8], [7, 6, 9], [8, 4, 11], [9, 5, 10], [10, 6, 9], [11, 7, 8]]}],
	"mid": [{"c": "8a93a6", "s": [[5, 4, 5], [5, 10, 11], [6, 5, 6], [6, 9, 10], [7, 6, 7], [7, 8, 9], [8, 7, 8]]}],
	"bolt": [
		{"c": "ffd24a", "s": [[2, 8, 10], [3, 7, 9], [4, 6, 9], [5, 5, 9], [6, 5, 10], [7, 7, 10], [8, 6, 9], [9, 5, 8], [10, 5, 7], [11, 6, 6]]},
		{"c": "fff3b0", "s": [[4, 8, 8], [5, 7, 8], [7, 8, 9], [8, 7, 8]]},
	],
	"heart": [
		{"c": "ff5a7a", "s": [[3, 4, 5], [3, 9, 10], [4, 3, 6], [4, 8, 11], [5, 3, 11], [6, 3, 11], [7, 4, 11], [8, 5, 10], [9, 6, 9], [10, 7, 8]]},
		{"c": "ffd0da", "s": [[4, 4, 5], [5, 4, 5]]},
	],
	"eye": [
		{"c": "f2f4fa", "s": [[6, 5, 10], [7, 4, 11], [8, 4, 11], [9, 5, 10]]},
		{"c": "4aa0e0", "s": [[7, 6, 9], [8, 6, 9]]},
		{"c": "181420", "s": [[7, 7, 8], [8, 7, 8]]},
	],
	"crown": [
		{"c": "ffd24a", "s": [[4, 3, 3], [4, 7, 8], [4, 12, 12], [5, 3, 4], [5, 7, 8], [5, 11, 12], [6, 3, 12], [7, 3, 12], [8, 4, 11]]},
		{"c": "ff5ab0", "s": [[7, 5, 5], [7, 10, 10], [7, 7, 8]]},
	],
	"coin": [
		{"c": "ffd24a", "s": [[3, 6, 9], [4, 5, 10], [5, 4, 11], [6, 4, 11], [7, 4, 11], [8, 4, 11], [9, 4, 11], [10, 5, 10], [11, 6, 9]]},
		{"c": "ffe89a", "s": [[4, 6, 7], [5, 5, 6]]},
		{"c": "d99a2a", "s": [[6, 7, 8], [7, 7, 8], [8, 7, 8]]},
	],
	"lips": [
		{"c": "ff4f8a", "s": [[6, 5, 6], [6, 9, 10], [7, 4, 11], [9, 5, 10]]},
		{"c": "c23a6a", "s": [[8, 4, 11]]},
	],
	"dice": [
		{"c": "eef0f6", "s": [[4, 5, 10], [5, 4, 11], [6, 4, 11], [7, 4, 11], [8, 4, 11], [9, 4, 11], [10, 4, 11], [11, 5, 10]]},
		{"c": "242028", "s": [[5, 5, 5], [5, 10, 10], [8, 7, 8], [10, 5, 5], [10, 10, 10]]},
	],
	"arrow": [
		{"c": "cfe0ff", "s": [[8, 3, 12], [6, 10, 10], [7, 11, 11], [8, 12, 13], [9, 11, 11], [10, 10, 10]]},
		{"c": "ff6b6b", "s": [[7, 3, 4], [9, 3, 4]]},
	],
	"wing": [
		{"c": "cfe0ff", "s": [[3, 9, 10], [4, 8, 10], [5, 7, 10], [6, 6, 10], [7, 5, 10], [8, 6, 10], [9, 7, 10], [10, 8, 10], [11, 9, 10]]},
		{"c": "8fb0d8", "s": [[4, 10, 10], [6, 9, 10], [8, 9, 10], [10, 10, 10]]},
	],
	"flask": [
		{"c": "b8bcc8", "s": [[2, 7, 8], [3, 7, 8], [4, 7, 8]]},
		{"c": "6ad06a", "s": [[6, 5, 10], [7, 4, 11], [8, 4, 11], [9, 4, 11], [10, 5, 10], [11, 6, 9]]},
		{"c": "9ff0a0", "s": [[8, 5, 7], [9, 5, 6]]},
		{"c": "5aa85a", "s": [[5, 6, 9]]},
	],
	"note": [
		{"c": "c08ce0", "s": [[3, 9, 11], [4, 9, 11], [5, 9, 9], [6, 9, 9], [7, 9, 9], [8, 9, 9], [9, 6, 9], [10, 6, 9], [11, 6, 9]]},
		{"c": "e0caf5", "s": [[10, 6, 6]]},
	],
	"fist": [
		{"c": "eec8a4", "s": [[5, 5, 9], [6, 4, 10], [7, 4, 10], [8, 4, 10], [9, 4, 10], [10, 5, 9]]},
		{"c": "c89a78", "s": [[6, 6, 6], [6, 8, 8], [7, 6, 6], [7, 8, 8], [8, 7, 7]]},
	],
	"chest": [
		{"c": "7a4e26", "s": [[4, 4, 11], [5, 3, 12], [6, 3, 12], [7, 3, 12]]},
		{"c": "5e3c1c", "s": [[9, 3, 12], [10, 3, 12], [11, 3, 12], [12, 4, 11]]},
		{"c": "ffd24a", "s": [[8, 3, 12], [5, 3, 3], [6, 3, 3], [5, 12, 12], [6, 12, 12], [11, 3, 3], [11, 12, 12]]},
		{"c": "ffe89a", "s": [[9, 7, 8], [10, 7, 8]]},
		{"c": "3a2410", "s": [[10, 7, 7]]},
	],
	"zzz": [
		{"c": "8fe0b0", "s": [[4, 4, 7], [5, 6, 6], [6, 5, 5], [7, 4, 7], [8, 9, 12], [9, 11, 11], [10, 10, 10], [11, 9, 12]]},
	],
	"crack": [
		{"c": "8fa0c0", "s": [[3, 7, 8], [4, 6, 11], [5, 5, 11], [6, 5, 10], [7, 4, 10], [8, 5, 10], [9, 5, 10], [10, 6, 9], [11, 7, 8]]},
		{"c": "1a1420", "s": [[3, 8, 8], [4, 7, 8], [5, 8, 9], [6, 7, 7], [7, 8, 8], [8, 6, 7], [9, 8, 8], [10, 7, 7]]},
	],
	"quest": [
		{"c": "c08ce0", "s": [[3, 6, 9], [4, 5, 6], [4, 9, 10], [5, 9, 10], [6, 8, 10], [7, 7, 9], [8, 7, 8], [9, 7, 8], [11, 7, 8]]},
		{"c": "e0caf5", "s": [[3, 7, 8], [11, 7, 7]]},
	],
}

# Outfit item icons, one silhouette per slot, drawn in 3 shades of the element colour.
const ELEM_BASE := {"Fire": "e07a2c", "Necro": "5fa84a", "Neutral": "8a90a6"}
# Per-outfit signature tint so pieces sharing a slot silhouette still look distinct.
const ITEM_TINT := {
	&"apprentice_hat": "6a78c0", &"drip_robe": "3aa0a0", &"plain_wand": "b89a6a",
	&"worn_boots": "8a6a4a", &"lucky_charm": "5fb45f", &"pointed_hat_swag": "9a5ad0",
	&"smolder_boots": "e0531f", &"char_wand": "d97a2a", &"bone_scepter": "d8d2c0",
	&"robe_of_excess": "e0b040", &"crowd_pleaser": "ff6aa0", &"influencer_ring": "40c0d0",
	&"lucky_cap": "8fd96b", &"catwalk_heels": "d04a9a", &"showstopper_hat": "ff4f8a",
	&"phoenix_gown": "f2792a", &"diva_heels": "8a3ad0",
}
# Per-artefact tint for their charm icon.
const ARTI := {
	"glitter_brooch": "ff5ab0", "phoenix_feather": "f2792a", "ember_pin": "e0531f",
	"bone_charm": "e8e8ee", "energy_ring": "ffd24a", "swag_engine": "9a90d8",
	"iron_corset": "9aa0a8", "vigor_idol": "e07a4c", "vampire_fang": "c0405a",
	"prophets_lens": "5fb0d8", "coin_purse": "ffcf4a", "loaded_dice": "ffd24a",
	"venom_vial": "6ad06a", "spotlight": "ffe089",
}
const ITEM := {
	"Hat": [
		["d", [[8, 3, 13]]],
		["b", [[2, 8, 8], [3, 7, 9], [4, 7, 9], [5, 6, 10], [6, 6, 10], [7, 5, 11]]],
		["l", [[3, 7, 7], [4, 7, 7], [5, 6, 6], [6, 6, 6], [7, 5, 5]]],
	],
	"Robe": [
		["b", [[3, 7, 8], [4, 6, 9], [5, 6, 9], [6, 6, 9], [7, 5, 10], [8, 5, 10], [9, 4, 11], [10, 4, 11], [11, 4, 12], [12, 3, 12], [13, 3, 12]]],
		["d", [[9, 4, 11]]],
		["l", [[4, 6, 6], [5, 6, 6], [7, 5, 5], [9, 4, 4], [11, 4, 4], [12, 3, 3]]],
	],
	"Staff": [
		["d", [[4, 8, 8], [5, 8, 8], [6, 8, 8], [7, 8, 8], [8, 8, 8], [9, 8, 8], [10, 8, 8], [11, 8, 8], [12, 8, 8], [13, 8, 8]]],
		["b", [[2, 7, 9], [3, 6, 10], [4, 7, 9]]],
		["l", [[2, 7, 7], [3, 6, 6]]],
	],
	"Boots": [
		["b", [[8, 4, 6], [9, 4, 6], [10, 4, 6], [11, 4, 6], [8, 9, 11], [9, 9, 11], [10, 9, 11], [11, 9, 11]]],
		["d", [[12, 3, 7], [13, 3, 7], [12, 8, 12], [13, 8, 12]]],
		["l", [[8, 4, 4], [9, 4, 4], [8, 9, 9], [9, 9, 9]]],
	],
	"Trinket": [
		["d", [[3, 5, 5], [3, 10, 10], [4, 6, 6], [4, 9, 9]]],
		["b", [[5, 7, 8], [6, 6, 9], [7, 6, 9], [8, 7, 8], [9, 7, 8]]],
		["l", [[6, 7, 7], [7, 7, 7]]],
	],
}

var _cache := {}

func texture(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var img := get_image(id)
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_cache[id] = tex
	return tex

func get_image(id: StringName) -> Image:
	var d = DEF.get(id)
	if d == null:
		return null
	return _render(d)

func _render(d: Dictionary) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color(d.c)
	var top := body.lightened(0.12)
	var bot := body.darkened(0.18)

	# body
	for y in SIZE:
		for x in SIZE:
			if _inside(d.shape, x, y):
				img.set_pixel(x, y, top if y < 8 else (bot if y > 11 else body))

	_feature(img, d, body)
	_eyes(img, d)
	_outline(img)
	return img

func _inside(shape: String, x: int, y: int) -> bool:
	match shape:
		"square":
			return x >= 3 and x <= 12 and y >= 4 and y <= 14
		"tall":
			return x >= 5 and x <= 10 and y >= 2 and y <= 14
		"blob":
			# squat, wide ellipse sitting low
			var bx := (x - 7.5) / 6.4
			var by := (y - 10.0) / 4.6
			return bx * bx + by * by <= 1.0
		"diamond":
			return absi(x - 7) + absi(y - 9) <= 6
		"drip":
			# round head with a pointed drop bottom
			if y <= 10:
				var rx := (x - 7.5) / 5.4
				var ry := (y - 8.0) / 4.6
				return rx * rx + ry * ry <= 1.0
			var halfw: int = max(0, 5 - (y - 10))
			return x >= 7 - halfw and x <= 8 + halfw
	var dx := (x - 7.5) / 5.6
	var dy := (y - 9.0) / 5.6
	return dx * dx + dy * dy <= 1.0

func _eyes(img: Image, d: Dictionary) -> void:
	var iris := Color(d.eye)
	if d.get("cyclops", false):
		_blot(img, 6, 7, 4, 3, Color("f4f4fa"))
		_blot(img, 7, 8, 2, 1, iris)
		img.set_pixel(7, 8, Color("1a1420"))
		if d.angry:
			img.set_pixel(6, 6, OUTLINE)
			img.set_pixel(9, 6, OUTLINE)
		return
	for ex in [5, 9]:
		# white-ish socket
		_blot(img, ex, 7, 2, 2, Color("f4f4fa"))
		img.set_pixel(ex if ex == 5 else ex + 1, 8, iris)
		img.set_pixel(ex, 8, iris) if ex == 9 else img.set_pixel(ex + 1, 8, iris)
		img.set_pixel(ex if ex == 5 else ex + 1, 8, Color("1a1420"))
	if d.angry:
		# slanted brows
		img.set_pixel(5, 6, OUTLINE)
		img.set_pixel(6, 7, OUTLINE)
		img.set_pixel(10, 6, OUTLINE)
		img.set_pixel(9, 7, OUTLINE)

func _feature(img: Image, d: Dictionary, body: Color) -> void:
	match d.feat:
		"ears":
			for t in [[3, 4], [11, 12]]:
				img.set_pixel(t[0], 2, body)
				img.set_pixel(t[0], 3, body)
				img.set_pixel(t[1], 3, body)
				img.set_pixel(t[0] + 1 if t[0] == 3 else t[0], 2, body)
		"tufts":
			img.set_pixel(4, 3, body)
			img.set_pixel(11, 3, body)
		"horns":
			for hx in [3, 12]:
				img.set_pixel(hx, 2, Color("e8e2d0"))
				img.set_pixel(hx, 3, Color("c9c2ad"))
		"beak":
			img.set_pixel(7, 9, Color("f2a03c"))
			img.set_pixel(8, 9, Color("f2a03c"))
			img.set_pixel(7, 10, Color("d97f22"))
			img.set_pixel(8, 10, Color("d97f22"))
		"hat":
			for hy in range(1, 5):
				var hw := hy
				for hx in range(7 - hw + 1, 8 + hw):
					if hx >= 0 and hx < SIZE:
						img.set_pixel(hx, hy, Color("c2342f"))
		"antenna":
			for ax in [5, 10]:
				img.set_pixel(ax, 3, OUTLINE)
				img.set_pixel(ax, 2, OUTLINE)
				img.set_pixel(ax, 1, Color("ffd24a"))
		"slots":
			_blot(img, 5, 4, 2, 1, Color("3a3f47"))
			_blot(img, 9, 4, 2, 1, Color("3a3f47"))
		"doors":
			for y in range(5, 14):
				img.set_pixel(8, y, Color("5a3a22"))
			img.set_pixel(6, 9, Color("2a1a10"))
			img.set_pixel(10, 9, Color("2a1a10"))
		"mouth":
			for mx in range(5, 11):
				img.set_pixel(mx, 12, Color("c2342f"))
		"spikes":
			for sx in [4, 6, 8, 10, 12]:
				img.set_pixel(sx, 3, body.lightened(0.2))
				img.set_pixel(sx, 2, body.darkened(0.1))
		"crest":
			for cy in range(0, 4):
				img.set_pixel(8, cy, Color("ff5ab0"))
				img.set_pixel(7, cy + 1, Color("ff8fd0"))
		"fangs":
			img.set_pixel(6, 11, Color("f4f4fa"))
			img.set_pixel(6, 12, Color("f4f4fa"))
			img.set_pixel(10, 11, Color("f4f4fa"))
			img.set_pixel(10, 12, Color("f4f4fa"))
		"wings":
			for wy in range(7, 12):
				img.set_pixel(2, wy, body.darkened(0.1))
				img.set_pixel(13, wy, body.darkened(0.1))
			img.set_pixel(1, 8, body.darkened(0.2))
			img.set_pixel(14, 8, body.darkened(0.2))
			img.set_pixel(1, 10, body.darkened(0.2))
			img.set_pixel(14, 10, body.darkened(0.2))
		"halo":
			for hx in range(5, 11):
				img.set_pixel(hx, 0, Color("ffe89a"))
			img.set_pixel(4, 1, Color("ffe89a"))
			img.set_pixel(11, 1, Color("ffe89a"))
		_:
			pass

func _blot(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and xx < SIZE and yy >= 0 and yy < SIZE:
				img.set_pixel(xx, yy, c)

func item_texture(id: StringName) -> Texture2D:
	var key := "item_" + String(id)
	if _cache.has(key):
		return _cache[key]
	var piece = Database.get_outfit(id)
	var tex: Texture2D = null
	if piece != null:
		var col: Color = Color(ITEM_TINT[id]) if ITEM_TINT.has(id) else Color(ELEM_BASE.get(piece.element, "8a90a6"))
		tex = ImageTexture.create_from_image(_item(piece.slot, col))
	_cache[key] = tex
	return tex

func item_image(slot: String, element: String) -> Image:
	return _item(slot, Color(ELEM_BASE.get(element, "8a90a6")))

func artifact_texture(id: StringName) -> Texture2D:
	var key := "arti_" + String(id)
	if _cache.has(key):
		return _cache[key]
	var col: String = ARTI.get(String(id), "b08ad8")
	var tex := ImageTexture.create_from_image(_item("Trinket", Color(col)))
	_cache[key] = tex
	return tex

func _item(slot: String, base: Color) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var shades := {"b": base, "l": base.lightened(0.24), "d": base.darkened(0.3)}
	for layer in ITEM.get(slot, []):
		var c: Color = shades[layer[0]]
		for s in layer[1]:
			for x in range(s[1], s[2] + 1):
				if x >= 0 and x < SIZE and s[0] >= 0 and s[0] < SIZE:
					img.set_pixel(x, s[0], c)
	_outline(img)
	return img

func icon_texture(name: StringName) -> Texture2D:
	var key := "ic_" + String(name)
	if _cache.has(key):
		return _cache[key]
	var img := icon_image(name)
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_cache[key] = tex
	return tex

func icon_image(name: StringName) -> Image:
	var layers = ICON.get(String(name))
	if layers == null:
		return null
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for layer in layers:
		var c := Color(layer.c)
		for s in layer.s:
			for x in range(s[1], s[2] + 1):
				if x >= 0 and x < SIZE and s[0] >= 0 and s[0] < SIZE:
					img.set_pixel(x, s[0], c)
	return img

# Combat backdrops: a palette + a celestial orb + a floor style per biome, so
# different stretches of the run look distinct. Picked by depth in combat_ui.
const BG_THEMES := {
	"night":   {"sky": ["1a0f26", "47213f"], "ground": ["2c1930", "12090f"], "line": "5c3659", "floor": "pillars", "floorc": "1a121f", "orb": [28, 9, 5, "ede8d4"], "glow": "3a2b4a", "star": "eaeaff", "stars": 11},
	"dusk":    {"sky": ["3a1c30", "b5562e"], "ground": ["3a2320", "160d0c"], "line": "7a4030", "floor": "pillars", "floorc": "241512", "orb": [70, 13, 7, "ffd06a"], "glow": "8a3f2a", "star": "ffe2b0", "stars": 6},
	"void":    {"sky": ["0a0a1f", "241a48"], "ground": ["16122e", "070611"], "line": "3b3470", "floor": "none",    "floorc": "1a1540", "orb": [24, 11, 8, "6a5ad8"], "glow": "2a2060", "star": "cfd4ff", "stars": 22},
	"dungeon": {"sky": ["15110f", "2a221c"], "ground": ["241d18", "0e0b09"], "line": "4a3c2e", "floor": "bricks",  "floorc": "18120d", "orb": [80, 10, 4, "ff8a3c"], "glow": "5a2e16", "star": "6a5c4a", "stars": 4},
	"neon":    {"sky": ["0c1424", "13324a"], "ground": ["0e1c2c", "060b12"], "line": "27d0e0", "floor": "grid",    "floorc": "123a44", "orb": [72, 12, 6, "ff4fd0", ], "glow": "1a4a6a", "star": "8ff0ff", "stars": 14},
}

# 24 deterministic star slots; themes slice the first N for denser/sparser skies.
const _STAR_SLOTS := [[10, 16], [44, 6], [56, 4], [63, 15], [72, 9], [85, 8], [89, 20], [6, 22],
	[50, 18], [78, 22], [18, 7], [33, 12], [40, 21], [60, 23], [4, 11], [92, 14],
	[26, 19], [68, 5], [80, 17], [14, 13], [48, 9], [88, 4], [36, 5], [54, 12]]

func battle_bg(theme := "night") -> Texture2D:
	var key := "bg_" + theme
	if _cache.has(key):
		return _cache[key]
	var d = BG_THEMES.get(theme, BG_THEMES["night"])
	var w := 96
	var h := 54
	var floor_y := 27
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var sky_top := Color(d.sky[0])
	var sky_bot := Color(d.sky[1])
	var gnd_top := Color(d.ground[0])
	var gnd_bot := Color(d.ground[1])
	for y in h:
		for x in w:
			var col: Color
			if y < floor_y:
				col = sky_top.lerp(sky_bot, y / float(floor_y))
			else:
				col = gnd_top.lerp(gnd_bot, (y - floor_y) / float(h - floor_y))
			img.set_pixel(x, y, col)
	# celestial orb (soft glow halo behind it)
	var orb = d.orb
	if orb != null:
		_disc(img, orb[0], orb[1], orb[2] + 3, Color(d.glow).lerp(sky_top, 0.45))
		_disc(img, orb[0], orb[1], orb[2], Color(orb[3]))
	# stars
	var sc := Color(d.star)
	var n: int = min(int(d.stars), _STAR_SLOTS.size())
	for i in n:
		var s = _STAR_SLOTS[i]
		if s[1] < floor_y - 1:
			img.set_pixel(s[0], s[1], sc)
	# horizon line
	for x in w:
		img.set_pixel(x, floor_y, Color(d.line))
	_bg_floor(img, w, h, floor_y, String(d.floor), Color(d.floorc), Color(d.line))
	_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]

func _bg_floor(img: Image, w: int, h: int, floor_y: int, style: String, fc: Color, line: Color) -> void:
	match style:
		"pillars":
			for x in range(0, w, 8):
				for y in range(floor_y + 1, h):
					img.set_pixel(x, y, fc)
		"grid":
			for x in range(0, w, 8):
				for y in range(floor_y + 1, h):
					img.set_pixel(x, y, fc)
			for y in range(floor_y + 4, h, 5):
				for x in w:
					img.set_pixel(x, y, line.darkened(0.25))
		"bricks":
			for y in range(floor_y + 1, h, 4):
				for x in w:
					img.set_pixel(x, y, fc)
			var row := 0
			for y in range(floor_y + 1, h):
				if (y - floor_y) % 4 == 2:
					var offs := 0 if row % 2 == 0 else 6
					for x in range(offs, w, 12):
						img.set_pixel(x, y, fc)
					row += 1
		"none":
			# faint receding glow streaks instead of solid pillars
			for x in range(4, w, 16):
				for y in range(floor_y + 2, h, 2):
					img.set_pixel(x, y, fc)

func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height() and (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, c)

func wizard_texture(id: StringName, look := 0) -> Texture2D:
	var key := "wiz_%s_%d" % [String(id), look]
	if _cache.has(key):
		return _cache[key]
	var img := wizard_image(id, look)
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_cache[key] = tex
	return tex

func wizard_image(id: StringName, look := 0) -> Image:
	var d = WIZ.get(id)
	if d == null:
		return null
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var hat := Color(d.hat)
	var robe := Color(d.robe)
	var skin := Color(d.skin)
	var trim := Color(d.trim)

	# pointy hat
	for r in range(1, 6):
		var half := r - 1
		for x in range(8 - half, 9 + half):
			img.set_pixel(x, r, hat if x != 8 - half else hat.darkened(0.12))
	# brim
	for x in range(3, 13):
		img.set_pixel(x, 6, hat.darkened(0.1))
	img.set_pixel(8, 3, trim)            # hat star

	# face
	for y in range(7, 10):
		for x in range(5, 11):
			img.set_pixel(x, y, skin)
	if d.get("shades", false):
		for x in range(5, 11):
			img.set_pixel(x, 8, Color("181222"))
		img.set_pixel(5, 7, Color("181222"))
		img.set_pixel(10, 7, Color("181222"))
		img.set_pixel(6, 8, Color("6a6a90"))
	else:
		img.set_pixel(6 + look, 8, Color("241a2e"))
		img.set_pixel(9 + look, 8, Color("241a2e"))

	# robe
	for y in range(10, 16):
		var half: int = min(2 + (y - 10), 6)
		var shade := robe if y < 13 else robe.darkened(0.16)
		for x in range(8 - half, 9 + half):
			if x >= 0 and x < SIZE:
				img.set_pixel(x, y, shade)
	# per-class emblem on the chest so the three wizards read differently
	match d.get("motif", ""):
		"flame":
			img.set_pixel(8, 13, Color("ffd24a"))
			img.set_pixel(8, 12, Color("ff7a2a"))
			img.set_pixel(7, 13, Color("e0531f"))
			img.set_pixel(9, 13, Color("e0531f"))
			img.set_pixel(8, 0, Color("ff7a2a"))   # ember atop the hat
			img.set_pixel(8, 1, Color("ffd24a"))
		"skull":
			img.set_pixel(8, 12, Color("e8e8ee"))
			img.set_pixel(7, 12, Color("e8e8ee"))
			img.set_pixel(9, 12, Color("e8e8ee"))
			img.set_pixel(7, 13, Color("2a2238"))
			img.set_pixel(9, 13, Color("2a2238"))
		"chain":
			for cx in [6, 8, 10]:
				img.set_pixel(cx, 11, trim)
			img.set_pixel(7, 12, trim)
			img.set_pixel(9, 12, trim)
			img.set_pixel(8, 13, Color("ffd24a"))   # pendant
		_:
			img.set_pixel(8, 12, trim)
	_outline(img)
	return img

func _outline(img: Image) -> void:
	var to_set: Array = []
	for y in SIZE:
		for x in SIZE:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for o in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = x + o[0]
				var ny: int = y + o[1]
				if nx >= 0 and nx < SIZE and ny >= 0 and ny < SIZE and img.get_pixel(nx, ny).a > 0.0:
					to_set.append(Vector2i(x, y))
					break
	for p in to_set:
		img.set_pixel(p.x, p.y, OUTLINE)
