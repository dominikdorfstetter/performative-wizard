class_name WizardData
extends Resource
## A wizard class — really a "base robe set" (see DESIGN.md §7). Defines the starting
## kit: HP, base Swag income, the fixed starter deck, and the pool of cards that can be
## offered as rewards.

@export var id: StringName
@export var title: String = ""
@export var pname: String = ""               # the performer's stage name
@export_enum("Fire", "Necro", "Neutral") var element: String = "Neutral"
@export var emoji: String = "🧙"
@export var blurb: String = ""
@export var max_hp: int = 70
@export var base_drip: int = 2
@export var accent: Color = Color(1, 1, 1)
@export var starter_deck: Array[StringName] = []
@export var reward_pool: Array[StringName] = []
