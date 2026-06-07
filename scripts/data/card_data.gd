class_name CardData
extends Resource
## A single playable card. Behaviour is data: `effects` is a list of effect
## dictionaries resolved by EffectResolver, so cards never need their own scripts.

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var cost: int = 1
@export_enum("Attack", "Skill", "Power") var type: String = "Attack"
@export var rarity: String = "Common"
@export var unlock_clout: int = 0            # lifetime Clout to appear in pools (0 = always)

## Build-archetype tag for reward biasing (fire: roast|viral, necro: sac|swarm,
## rizz: storm|ramp). Empty = neutral/shared (basics, finishers).
@export var archetype: StringName = &""

## "Pose" value — Swag gained when this card is played.
@export var swag_gain: int = 0

## Optional Swag cost for finishers (0 = none).
@export var swag_cost: int = 0

## Each entry is a dict like {"op": "damage", "amount": 6, "target": "enemy"}.
@export var effects: Array[Dictionary] = []
