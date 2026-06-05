extends Node
## Dev tool: render the class-select screen for inspection.

func _ready() -> void:
	var s: Node = load("res://scenes/hub/class_select.tscn").instantiate()
	add_child(s)
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/pw_hub.png")
	print("saved /tmp/pw_hub.png")
	get_tree().quit()
