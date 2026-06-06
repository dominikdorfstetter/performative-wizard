extends Node
## Dev tool: render every generated enemy sprite into one montage PNG for inspection.

func _ready() -> void:
	var ids: Array = SpriteBank.DEF.keys()
	for wid in SpriteBank.WIZ.keys():
		ids.append(wid)
	for icn in SpriteBank.ICON.keys():
		ids.append("icon:" + icn)
	for slot in ["Hat", "Robe", "Staff", "Boots", "Trinket"]:
		for el in ["Fire", "Necro", "Neutral"]:
			ids.append("item:%s:%s" % [slot, el])
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
		var id = ids[i]
		var img: Image
		if typeof(id) == TYPE_STRING and id.begins_with("icon:"):
			img = SpriteBank.icon_image(id.substr(5))
		elif typeof(id) == TYPE_STRING and id.begins_with("item:"):
			var parts = id.split(":")
			img = SpriteBank.item_image(parts[1], parts[2])
		elif SpriteBank.WIZ.has(id):
			img = SpriteBank.wizard_image(id)
		else:
			img = SpriteBank.get_image(id)
		img.resize(cell, cell, Image.INTERPOLATE_NEAREST)
		var cx := i % cols
		var cy := i / cols
		m.blend_rect(img, Rect2i(0, 0, cell, cell), Vector2i(pad + cx * (cell + pad), pad + cy * (cell + pad)))
	m.save_png("/tmp/pw_sprites.png")
	print("saved /tmp/pw_sprites.png  (%d sprites)" % ids.size())
	get_tree().quit()
