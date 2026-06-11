class_name ArtifactData
extends Resource
## A run-scoped relic ("artefact"). Found in chests, events, elites, shops. Most grant a
## combat passive (reusing the passive-hook system); some give economy effects. Lost when
## the run ends — power you assemble within a single run.

@export var id: StringName
@export var title: String = ""
@export var emoji: String = "🔮"
@export_multiline var description: String = ""
## Drop-table tier (and shop price band). Default keeps pre-rarity .tres files valid.
@export_enum("Common", "Rare", "Epic", "Legendary") var rarity: String = "Common"
@export var passive_id: StringName = &""     # combat passive granted (may be empty)
## Which wizards can be OFFERED this relic (drops/shops). Empty = everyone.
## Class-kit relics (Goon/sac/burn/toxic boosters) are dead picks off-class.
@export var wizards: Array[StringName] = []
@export var gold_per_combat: int = 0         # economy: gold gained after each won combat
@export var unlock_clout: int = 0            # lifetime Clout to appear in pools (0 = always)
