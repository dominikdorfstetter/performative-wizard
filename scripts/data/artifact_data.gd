class_name ArtifactData
extends Resource
## A run-scoped relic ("artefact"). Found in chests, events, elites, shops. Most grant a
## combat passive (reusing the passive-hook system); some give economy effects. Lost when
## the run ends — power you assemble within a single run.

@export var id: StringName
@export var title: String = ""
@export var emoji: String = "🔮"
@export_multiline var description: String = ""
@export var passive_id: StringName = &""     # combat passive granted (may be empty)
@export var gold_per_combat: int = 0         # economy: gold gained after each won combat
@export var unlock_clout: int = 0            # lifetime Clout to appear in pools (0 = always)
