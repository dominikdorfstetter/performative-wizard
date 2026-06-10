extends Node
## Dev tool: generates the project's branding assets (app icon + boot splash) from
## SpriteBank's procedural pixel art, so exports stop shipping the Godot robot and
## the white "GODOT Game engine" web loading splash.
## Run:  godot --headless scenes/tools/make_branding.tscn
## Writes res://assets/icon.png (1024x1024) and res://assets/boot_splash.png (1152x648).

const BG := Color("181024")
const SPLASH_BG := Color("0e0a14")
const PINK := Color("ff4fb3")
const GOLD := Color("ffd24a")

func _ready() -> void:
	_make_icon()
	_make_splash()
	print("[make_branding] wrote assets/icon.png and assets/boot_splash.png")
	get_tree().quit()

func _make_icon() -> void:
	var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(BG)
	_frame(img, 1024, 20, PINK)
	var wiz := SpriteBank.wizard_image(&"fire", 0)
	if wiz != null:
		wiz.resize(832, 832, Image.INTERPOLATE_NEAREST)
		img.blend_rect(wiz, Rect2i(0, 0, 832, 832), Vector2i(96, 120))
	var star := SpriteBank.icon_image(&"star")
	if star != null:
		star.resize(176, 176, Image.INTERPOLATE_NEAREST)
		img.blend_rect(star, Rect2i(0, 0, 176, 176), Vector2i(756, 84))
	img.save_png("res://assets/icon.png")

func _make_splash() -> void:
	var img := Image.create(1152, 648, false, Image.FORMAT_RGBA8)
	img.fill(SPLASH_BG)
	# the three wizards on one baseline: Vesper front and center, the others flanking
	var ids: Array = [&"necro", &"fire", &"rizz"]
	var sizes: Array = [208, 288, 208]
	var centers: Array = [276, 576, 876]
	var baseline := 470
	for i in 3:
		var wiz := SpriteBank.wizard_image(ids[i], 0)
		if wiz == null:
			continue
		var s: int = sizes[i]
		wiz.resize(s, s, Image.INTERPOLATE_NEAREST)
		img.blend_rect(wiz, Rect2i(0, 0, s, s), Vector2i(int(centers[i]) - s / 2, baseline - s))
	# sparse twinkles so the dark frame reads intentional, not empty
	for p in [[180, 120], [340, 80], [580, 56], [820, 95], [980, 140], [120, 320], [1024, 300], [576, 530]]:
		_blot(img, p[0], p[1], 4, GOLD if p[1] == 530 else Color(1, 1, 1, 0.85))
	img.save_png("res://assets/boot_splash.png")

func _frame(img: Image, sz: int, t: int, c: Color) -> void:
	for y in sz:
		for x in sz:
			if x < t or y < t or x >= sz - t or y >= sz - t:
				img.set_pixel(x, y, c)

func _blot(img: Image, x: int, y: int, s: int, c: Color) -> void:
	for dy in s:
		for dx in s:
			var px := x + dx
			var py := y + dy
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, c)
