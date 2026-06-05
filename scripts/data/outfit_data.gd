class_name OutfitData
extends Resource
## A wardrobe piece. Equipped at the hub; contributes passive Swag income (`drip`),
## a passive effect, and injects cards into the run deck.

@export var id: StringName
@export var title: String = ""
@export_enum("Hat", "Robe", "Staff", "Boots", "Trinket") var slot: String = "Hat"
@export_enum("Fire", "Necro", "Neutral") var element: String = "Neutral"

## Passive Swag gained at the start of each of your turns from this piece.
@export var drip: int = 0

@export_multiline var passive_text: String = ""
## Resolved to a code hook by the passive system (M3).
@export var passive_id: StringName = &""

## Card ids this piece adds to the run deck (duplicates allowed for x2/x3).
@export var injected_cards: Array[StringName] = []
