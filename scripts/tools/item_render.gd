extends Node
## Dev tool: dumps every outfit-piece sprite as an upscaled PNG plus a contact
## sheet grouped by slot, so item distinguishability can be eyeballed at a glance.
##   PW_NO_SAVE=1 godot --headless scenes/tools/item_render.tscn
## Writes /tmp/item_<id>.png and /tmp/item_sheet.png.

func _ready() -> void:
	var by_slot := {}
	for oid in Database.outfits:
		var p: OutfitData = Database.outfits[oid]
		if not by_slot.has(p.slot):
			by_slot[p.slot] = []
		by_slot[p.slot].append(oid)
	var cols := 0
	for slot in by_slot:
		(by_slot[slot] as Array).sort()
		cols = max(cols, (by_slot[slot] as Array).size())
	var cell := 144
	var slots: Array = ["Hat", "Robe", "Staff", "Boots", "Trinket"]
	var sheet := Image.create(cols * cell, slots.size() * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("181024"))
	for row in slots.size():
		var ids: Array = by_slot.get(slots[row], [])
		for i in ids.size():
			var tex := SpriteBank.item_texture(ids[i])
			if tex == null:
				continue
			var img := tex.get_image()
			img.resize(128, 128, Image.INTERPOLATE_NEAREST)
			img.save_png("/tmp/item_%s.png" % ids[i])
			sheet.blend_rect(img, Rect2i(0, 0, 128, 128), Vector2i(i * cell + 8, row * cell + 8))
	sheet.save_png("/tmp/item_sheet.png")
	print("[item_render] wrote item sprites + /tmp/item_sheet.png")
	get_tree().quit()
