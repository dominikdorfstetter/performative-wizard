class_name Combatant
extends RefCounted
## Runtime state for the player or an enemy during a fight.

var display_name: String = ""
var hp: int = 0
var max_hp: int = 0
var block: int = 0
var statuses: Dictionary = {}    # StringName -> int (stacks)

# Enemy-only: its data + its own place in the intent pattern.
var data: EnemyData = null
var intent_index: int = 0

# Gold-thief mechanics (The IRS): what it has garnished from you so far, and
# whether it already fled the fight. Kill it BEFORE it flees → full refund.
var stolen_gold: int = 0
var fled: bool = false

func take_damage(amount: int, pierce: bool = false) -> void:
	var remaining := amount
	if block > 0 and not pierce:
		var absorbed: int = min(block, remaining)
		block -= absorbed
		remaining -= absorbed
	hp = max(0, hp - remaining)

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func add_status(id: StringName, stacks: int) -> void:
	var v := int(statuses.get(id, 0)) + stacks
	if v <= 0:
		statuses.erase(id)
	else:
		statuses[id] = v

func status(id: StringName) -> int:
	return int(statuses.get(id, 0))

func is_dead() -> bool:
	# A fled enemy is out of the fight for every purpose (targeting, win checks) —
	# it just doesn't refund what it stole.
	return hp <= 0 or fled
