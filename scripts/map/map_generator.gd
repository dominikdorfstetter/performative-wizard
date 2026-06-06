class_name MapGenerator
extends RefCounted
## Generates a branching, layered map (StS-style DAG). Returns an Array of rows; each row
## is an Array of node dictionaries. Row 0 is the start, the last row is the Boss.
##
## node = { row, col, type, links:Array[int] (cols in next row), enemies:Array, visited:bool }

const ROWS := 10

static func generate(seed_val: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var rows: Array = []
	for r in ROWS:
		var width: int
		if r == ROWS - 1:
			width = 1
		elif r == 0:
			width = rng.randi_range(2, 3)
		else:
			width = rng.randi_range(2, 4)
		var row: Array = []
		for c in width:
			row.append(_make_node(r, c, rng))
		rows.append(row)
	for r in ROWS - 1:
		_connect(rows[r], rows[r + 1], rng)
	return rows

static func _make_node(r: int, c: int, rng: RandomNumberGenerator) -> Dictionary:
	var t := _pick_type(r, rng)
	var node := {"row": r, "col": c, "type": t, "links": [], "enemies": [], "visited": false}
	var depth := float(r) / float(ROWS - 1)
	match t:
		"Combat":
			node.enemies = Encounters.normal(depth, rng)
		"Elite":
			node.enemies = Encounters.elite(rng)
		"Boss":
			node.enemies = Encounters.boss()
	return node

static func _pick_type(r: int, rng: RandomNumberGenerator) -> String:
	if r == 0:
		return "Combat"
	if r == ROWS - 1:
		return "Boss"
	if r == ROWS - 2:
		return "Rest"
	if r == 1:
		return "Combat" if rng.randf() < 0.7 else "Event"
	var roll := rng.randf()
	if roll < 0.44:
		return "Combat"
	elif roll < 0.60:
		return "Event"
	elif roll < 0.72:
		return "Elite"
	elif roll < 0.83:
		return "Shop"
	elif roll < 0.93:
		return "Chest"
	return "Rest"

static func _connect(cur: Array, nxt: Array, rng: RandomNumberGenerator) -> void:
	for i in cur.size():
		var rel := 0.0 if cur.size() == 1 else float(i) / float(cur.size() - 1)
		var center := int(round(rel * (nxt.size() - 1)))
		var links := {center: true}
		if rng.randf() < 0.28 and nxt.size() > 1:
			var off: int = clamp(center + (1 if rng.randf() < 0.5 else -1), 0, nxt.size() - 1)
			links[off] = true
		cur[i].links = links.keys()
	# guarantee every next-row node has at least one incoming edge
	var incoming := {}
	for i in cur.size():
		for l in cur[i].links:
			incoming[l] = true
	for j in nxt.size():
		if not incoming.has(j):
			var rel := 0.0 if nxt.size() == 1 else float(j) / float(nxt.size() - 1)
			var ci := int(round(rel * (cur.size() - 1)))
			if j not in cur[ci].links:
				cur[ci].links.append(j)
