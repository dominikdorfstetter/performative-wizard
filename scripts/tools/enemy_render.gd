extends Node
## Dev tool: dumps every enemy sprite as an upscaled PNG so an art pass can be
## eyeballed without booting fights. Run headless:
##   PW_NO_SAVE=1 godot --headless scenes/tools/enemy_render.tscn
## Writes /tmp/enemy_<id>.png (128x128, nearest) plus a 5-column contact sheet.

func _ready() -> void:
	var ids: Array = SpriteBank.DEF.keys()
	ids.sort()
	var cols := 5
	var cell := 144
	var rows := int(ceil(ids.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("181024"))
	for i in ids.size():
		var tex := SpriteBank.texture(ids[i])
		if tex == null:
			continue
		var img := tex.get_image()
		img.resize(128, 128, Image.INTERPOLATE_NEAREST)
		img.save_png("/tmp/enemy_%s.png" % ids[i])
		sheet.blend_rect(img, Rect2i(0, 0, 128, 128),
			Vector2i((i % cols) * cell + 8, (i / cols) * cell + 8))
	sheet.save_png("/tmp/enemy_sheet.png")
	print("[enemy_render] wrote %d sprites + /tmp/enemy_sheet.png" % ids.size())
	get_tree().quit()
