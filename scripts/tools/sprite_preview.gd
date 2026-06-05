extends Node
## Dev tool: render every generated enemy sprite into one montage PNG for inspection.

func _ready() -> void:
	var ids: Array = SpriteBank.DEF.keys()
	for wid in SpriteBank.WIZ.keys():
		ids.append(wid)
	var scale := 8
	var cell := SpriteBank.SIZE * scale
	var pad := 10
	var cols := 3
	var rows := int(ceil(ids.size() / float(cols)))
	var w := cols * cell + (cols + 1) * pad
	var h := rows * cell + (rows + 1) * pad
	var m := Image.create(w, h, false, Image.FORMAT_RGBA8)
	m.fill(Color("241d30"))
	for i in ids.size():
		var img: Image = SpriteBank.wizard_image(ids[i]) if SpriteBank.WIZ.has(ids[i]) else SpriteBank.get_image(ids[i])
		img.resize(cell, cell, Image.INTERPOLATE_NEAREST)
		var cx := i % cols
		var cy := i / cols
		m.blend_rect(img, Rect2i(0, 0, cell, cell), Vector2i(pad + cx * (cell + pad), pad + cy * (cell + pad)))
	m.save_png("/tmp/pw_sprites.png")
	print("saved /tmp/pw_sprites.png  (%d sprites)" % ids.size())
	get_tree().quit()
