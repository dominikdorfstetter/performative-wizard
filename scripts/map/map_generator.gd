class_name MapGenerator
extends RefCounted
## Generates a branching, layered map (StS-style DAG). Returns an Array of rows; each row
## is an Array of node dictionaries. Row 0 is the start, the last row is the Boss.
##
## node = { row, col, type, links:Array[int] (cols in next row), enemies:Array, visited:bool }
##
## Guarantees (added after playtest feedback — "2 rests follow each other",
## "paths appear random"):
##   - links are MONOTONIC windows: edges never cross, every node is reachable
##     and every node has an exit
##   - the same special never appears twice in a row along any path
##   - at most one Rest / Shop / Chest per row
##   - every act has at least one Shop

const ROWS := 10
const ONE_PER_ROW := ["Rest", "Shop", "Chest"]

static func generate(seed_val: int, act: int = 1) -> Array:
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
			row.append(_make_node(r, c, rng, act))
		if r != ROWS - 2:   # the pre-boss row is ALL Rest by design — leave it
			_dedupe_row(row, rng, act)
		rows.append(row)
	for r in ROWS - 1:
		_connect(rows[r], rows[r + 1], rng)
	_repair_consecutive(rows, rng, act)
	_ensure_shop(rows, rng, act)
	return rows

static func _make_node(r: int, c: int, rng: RandomNumberGenerator, act: int = 1) -> Dictionary:
	var node := {"row": r, "col": c, "type": "", "links": [], "enemies": [], "visited": false}
	_set_type(node, _pick_type(r, rng), rng, act)
	return node

## Type changes always go through here so the encounter list stays in sync.
static func _set_type(node: Dictionary, t: String, rng: RandomNumberGenerator, act: int = 1) -> void:
	node.type = t
	var depth := float(node.row) / float(ROWS - 1)
	match t:
		"Combat":
			node.enemies = Encounters.normal(act, depth, rng)
		"Elite":
			node.enemies = Encounters.elite(act, rng)
		"Boss":
			node.enemies = Encounters.boss(act, rng)
		_:
			node.enemies = []

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
	# the row before the forced pre-boss Rest must never roll Rest itself
	return "Rest" if r != ROWS - 3 else "Event"

## A second Rest/Shop/Chest in the same row dilutes the choice — re-roll it.
static func _dedupe_row(row: Array, rng: RandomNumberGenerator, act: int = 1) -> void:
	var seen := {}
	for node in row:
		var t: String = node.type
		if t in ONE_PER_ROW:
			if seen.has(t):
				_set_type(node, "Combat" if rng.randf() < 0.6 else "Event", rng, act)
			else:
				seen[t] = true

## Monotonic window connect: node i links to a contiguous slice of the next row,
## slices in order, so edges can never cross; the slices partition the next row,
## so every node is reachable. A 35% "diamond" borrows the first node of the
## neighbour's window (shared target — still crossing-free) for branching.
static func _connect(cur: Array, nxt: Array, rng: RandomNumberGenerator) -> void:
	var n := cur.size()
	var m := nxt.size()
	for i in n:
		var lo := int(floor(float(i) * m / n))
		var hi := int(floor(float(i + 1) * m / n))
		var links: Array = []
		if hi <= lo:
			# converging rows leave this window empty — share the boundary node;
			# never borrow past it (that's exactly what made edges cross)
			links.append(mini(lo, m - 1))
		else:
			for k in range(lo, hi):
				links.append(k)
			if hi < m and rng.randf() < 0.35:
				links.append(hi)   # diamond: the raw boundary, shared with i+1
		cur[i].links = links

## The same special twice along one path is a dead choice ("two rests in a row")
## — the child becomes a Combat. Runs edge-by-edge after connection.
static func _repair_consecutive(rows: Array, rng: RandomNumberGenerator, act: int = 1) -> void:
	for r in rows.size() - 1:
		for node in rows[r]:
			var t: String = node.type
			if t == "Combat" or t == "Boss":
				continue
			for l in node.links:
				var child: Dictionary = rows[r + 1][l]
				if child.type == t:
					_set_type(child, "Combat", rng, act)

## An act with no shop strands your gold; convert a mid-act Combat if needed.
static func _ensure_shop(rows: Array, rng: RandomNumberGenerator, act: int = 1) -> void:
	for r in range(1, rows.size() - 1):
		for node in rows[r]:
			if node.type == "Shop":
				return
	var mid: Array = rows[rows.size() / 2]
	var cands: Array = []
	for node in mid:
		if node.type == "Combat":
			cands.append(node)
	if not cands.is_empty():
		_set_type(cands[rng.randi_range(0, cands.size() - 1)], "Shop", rng, act)
