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
}

# wizards: humanoid sprites (pointy hat, face, robe)
const WIZ := {
	&"fire": {"hat": "b5302b", "robe": "e0883c", "skin": "eec8a4", "trim": "ffd24a"},
	&"necro": {"hat": "2e2440", "robe": "57804a", "skin": "cdd2dd", "trim": "8fd96b"},
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

func wizard_texture(id: StringName) -> Texture2D:
	var key := "wiz_" + String(id)
	if _cache.has(key):
		return _cache[key]
	var img := wizard_image(id)
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_cache[key] = tex
	return tex

func wizard_image(id: StringName) -> Image:
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
	img.set_pixel(6, 8, Color("241a2e"))
	img.set_pixel(9, 8, Color("241a2e"))

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
