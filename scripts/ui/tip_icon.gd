extends TextureRect
## A pixel icon with a CUSTOM-styled hover tooltip (dark panel + gold title + wrapped body),
## so help text matches the pixel-UI instead of the clashing OS default tooltip. Used for
## artefact charms, status/intent chips, and HUD readouts. Set help via set_tip().
##
## Loaded via preload (not class_name) so it resolves in headless/exported runs, where the
## global class-name cache isn't regenerated (same reason loc.gd preloads its tables).

var tip_title := ""
var tip_body := ""

func set_tip(title: String, body: String) -> void:
	tip_title = title
	tip_body = body
	tooltip_text = title if title != "" else " "   # non-empty so the hover tooltip fires

func _make_custom_tooltip(_for_text: String) -> Object:
	return panel(tip_title, tip_body)

# The one canonical tooltip panel used across the game (dark pixel-UI chrome). Static so
# other screens can build the same styled tooltip without an instance.
static func panel(title: String, body: String) -> Control:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("15111e")
	sb.set_border_width_all(2)
	sb.border_color = Color("47394d")
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	if title != "":
		var t := Label.new()
		t.text = title
		t.add_theme_color_override("font_color", Color("ffd24a"))
		t.add_theme_font_size_override("font_size", 15)
		v.add_child(t)
	if body != "":
		var b := Label.new()
		b.text = body
		b.add_theme_color_override("font_color", Color("d8d2e0"))
		b.add_theme_font_size_override("font_size", 13)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.custom_minimum_size = Vector2(250, 0)
		v.add_child(b)
	return pc
