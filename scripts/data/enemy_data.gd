class_name EnemyData
extends Resource
## An enemy and its telegraphed intent pattern. Intents loop in order for the POC
## (deterministic, no AI yet).

@export var id: StringName
@export var title: String = ""
@export var emoji: String = "👾"
@export var max_hp: int = 20

## Ordered, looping list of intents. Each is a dict like
## {"op": "attack", "amount": 7} or {"op": "apply_status", "status": "weak", "amount": 2}.
@export var intents: Array[Dictionary] = []
