class_name StatusEffect
extends Resource
## Definition of a status / keyword (Burn, Strength, Vulnerable, Weak, Undead, ...).
## Runtime stacks live on Combatant.statuses; this is the authored description of one.

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""

## If true, loses 1 stack at end of the owner's turn (e.g. Vulnerable, Burn).
@export var decays: bool = true

## If true, it's a debuff (shown in red, etc.).
@export var is_debuff: bool = false
