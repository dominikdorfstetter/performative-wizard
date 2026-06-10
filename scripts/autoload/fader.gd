extends CanvasLayer
## Black-dip scene transitions. Fader.change_scene(path) replaces the bare
## get_tree().change_scene_to_file() hard cuts that used to sit on every one of
## the game's ~20 screen swaps.

const DIP := 0.15
const RISE := 0.18

var _rect: ColorRect
var _busy := false

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # swallow clicks mid-fade
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, DIP)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
	tw.tween_property(_rect, "color:a", 0.0, RISE)
	tw.tween_callback(func():
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false)
