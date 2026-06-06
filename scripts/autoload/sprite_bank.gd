extends Node
## Procedural pixel-art generator. Builds a 16x16 sprite per enemy from a small set of
## parameters (colour, body shape, topper feature, eyes) and caches it as an ImageTexture.
## Displayed scaled up with nearest-neighbour filtering for crisp pixels.

const SIZE := 16
const OUTLINE := Color("14111c")

const DEF := {
	&"alley_cat": {"c": "e0883c", "shape": "round", "feat": "ears", "eye": "8fd96b", "angry": false},
	&"disgruntled_pigeon": {"c": "8a93a6", "shape": "round", "feat": "beak", "eye": "ffffff", "angry": true},
	&"garden_gnome": {"c": "d8b088", "shape": "round", "feat": "hat", "eye": "ffffff", "angry": false},
	&"angry_toaster": {"c": "b9c0c9", "shape": "square", "feat": "slots", "eye": "ffffff", "angry": true},
	&"haunted_umbrella": {"c": "8a5bd0", "shape": "round", "feat": "none", "eye": "d6ff66", "angry": true},
	&"sock_puppet": {"c": "e6e6ee", "shape": "round", "feat": "mouth", "eye": "ffffff", "angry": false},
	&"possessed_wardrobe": {"c": "8a5a3a", "shape": "square", "feat": "doors", "eye": "ff6b6b", "angry": true},
	&"taxidermy_owl": {"c": "9a6b3f", "shape": "round", "feat": "tufts", "eye": "ffd24a", "angry": false},
	&"the_critic": {"c": "b23b3b", "shape": "round", "feat": "horns", "eye": "ffd24a", "angry": true},
	&"feral_houseplant": {"c": "4e9a48", "shape": "round", "feat": "tufts", "eye": "ffffff", "angry": true},
	&"cursed_mirror": {"c": "acc4d4", "shape": "square", "feat": "none", "eye": "c08ce0", "angry": false},
	&"possessed_mannequin": {"c": "d8c2a2", "shape": "round", "feat": "none", "eye": "241a30", "angry": true},
	&"rabid_roomba": {"c": "4a4f57", "shape": "round", "feat": "antenna", "eye": "ff5a5a", "angry": true},
	&"goblin_gremlin": {"c": "6f9a3a", "shape": "round", "feat": "ears", "eye": "ffd24a", "angry": true},
	&"gargoyle_cherub": {"c": "9aa0a8", "shape": "round", "feat": "horns", "eye": "ffffff", "angry": true},
	&"black_cat": {"c": "2c2735", "shape": "round", "feat": "ears", "eye": "ffd24a", "angry": true},
	&"shade_thrower": {"c": "5b4a78", "shape": "round", "feat": "none", "eye": "ff6b8f", "angry": true},
	&"clout_goblin": {"c": "7aa83a", "shape": "round", "feat": "ears", "eye": "ffd24a", "angry": true},
	&"ringlight_wraith": {"c": "d8d2e8", "shape": "round", "feat": "antenna", "eye": "ff5ab0", "angry": true},
}

# wizards: humanoid sprites (pointy hat, face, robe)
const WIZ := {
	&"fire": {"hat": "b5302b", "robe": "e0883c", "skin": "eec8a4", "trim": "ffd24a"},
	&"necro": {"hat": "2e2440", "robe": "57804a", "skin": "cdd2dd", "trim": "8fd96b"},
	&"rizz": {"hat": "c23b8a", "robe": "e0a93c", "skin": "eec8a4", "trim": "ff8fd0", "shades": true},
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
}

# Outfit item icons, one silhouette per slot, drawn in 3 shades of the element colour.
const ELEM_BASE := {"Fire": "e07a2c", "Necro": "5fa84a", "Neutral": "8a90a6"}
# Per-artefact tint for their charm icon.
const ARTI := {
	"glitter_brooch": "ff5ab0", "phoenix_feather": "f2792a", "ember_pin": "e0531f",
	"bone_charm": "e8e8ee", "energy_ring": "ffd24a", "swag_engine": "9a90d8",
	"iron_corset": "9aa0a8", "vigor_idol": "e07a4c", "vampire_fang": "c0405a",
	"prophets_lens": "5fb0d8", "coin_purse": "ffcf4a", "loaded_dice": "ffd24a",
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
	if shape == "square":
		return x >= 3 and x <= 12 and y >= 4 and y <= 14
	var dx := (x - 7.5) / 5.6
	var dy := (y - 9.0) / 5.6
	return dx * dx + dy * dy <= 1.0

func _eyes(img: Image, d: Dictionary) -> void:
	var iris := Color(d.eye)
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
		tex = ImageTexture.create_from_image(item_image(piece.slot, piece.element))
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

## A simple pixelated night-stage backdrop for combat (sky gradient, moon, stars, floor).
func battle_bg() -> Texture2D:
	if _cache.has("battlebg"):
		return _cache["battlebg"]
	var w := 96
	var h := 54
	var floor_y := 27
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var col: Color
			if y < floor_y:
				col = Color(0.10, 0.06, 0.15).lerp(Color(0.28, 0.13, 0.26), y / float(floor_y))
			else:
				col = Color(0.17, 0.10, 0.19).lerp(Color(0.07, 0.05, 0.10), (y - floor_y) / float(h - floor_y))
			img.set_pixel(x, y, col)
	for x in w:
		img.set_pixel(x, floor_y, Color(0.36, 0.21, 0.36))
	for x in range(0, w, 8):
		for y in range(floor_y + 1, h):
			img.set_pixel(x, y, Color(0.10, 0.07, 0.12))
	_disc(img, 28, 9, 5, Color(0.93, 0.91, 0.83))
	for s in [[10, 16], [44, 6], [56, 4], [63, 15], [72, 9], [85, 8], [89, 20], [6, 22], [50, 18], [78, 22]]:
		img.set_pixel(s[0], s[1], Color(0.92, 0.92, 1.0))
	_cache["battlebg"] = ImageTexture.create_from_image(img)
	return _cache["battlebg"]

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
	img.set_pixel(8, 12, trim)           # robe gem
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
