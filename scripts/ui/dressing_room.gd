extends Control
## The wardrobe / dressing room (M3). Equip one owned piece per slot — filtered to your
## class rack — then enter the gauntlet. Equipped pieces inject cards, add Swag income,
## and grant passives (baked in by GameState.finalize_loadout).

const ELEM_COLOR := {
	"Fire": Color(0.86, 0.30, 0.27),
	"Necro": Color(0.55, 0.78, 0.45),
	"Neutral": Color(0.6, 0.6, 0.66),
}

@onready var _slots: VBoxContainer = $Slots
@onready var _summary: Label = $SummaryPanel/SummaryText

var _wizard: WizardData

func _ready() -> void:
	$Background.color = Color(0.08, 0.06, 0.11)
	$Title.add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	$SummaryPanel.add_theme_stylebox_override("panel", _panel(Color(0.13, 0.11, 0.17), Color(0.28, 0.24, 0.36)))
	_wizard = Database.get_wizard(GameState.wizard_id)
	$WizardLabel.text = "%s  %s    —    pick your drip" % [_wizard.emoji, _wizard.title]
	$WizardLabel.add_theme_color_override("font_color", _wizard.accent.lightened(0.3))
	$EnterButton.pressed.connect(_enter)
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/hub/class_select.tscn"))
	$EnterButton.add_theme_stylebox_override("normal", _panel(Color(0.16, 0.36, 0.22), Color(0.36, 0.70, 0.45)))
	$EnterButton.add_theme_stylebox_override("hover", _panel(Color(0.20, 0.46, 0.28), Color(0.45, 0.85, 0.55)))
	_rebuild()

func _rebuild() -> void:
	for c in _slots.get_children():
		c.queue_free()
	for slot in GameState.SLOTS:
		_slots.add_child(_make_slot_row(slot))
	_update_summary()

func _make_slot_row(slot: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = slot
	label.custom_minimum_size = Vector2(80, 78)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.76))
	row.add_child(label)

	var options := GameState.owned_for(slot, _wizard.element)
	if options.is_empty():
		var none := Label.new()
		none.text = "(nothing owned)"
		none.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		row.add_child(none)
	for id in options:
		row.add_child(_make_piece_button(slot, Database.get_outfit(id)))
	return row

func _make_piece_button(slot: String, piece: OutfitData) -> Button:
	var equipped := GameState.equipped_id(slot) == piece.id
	var ec: Color = ELEM_COLOR.get(piece.element, Color.GRAY)
	var border := Color(1.0, 0.82, 0.29) if equipped else ec.darkened(0.1)
	var b := Button.new()
	b.custom_minimum_size = Vector2(176, 78)
	b.add_theme_stylebox_override("normal", _panel(Color(0.18, 0.16, 0.22) if equipped else Color(0.12, 0.11, 0.15), border, 3 if equipped else 1))
	b.add_theme_stylebox_override("hover", _panel(Color(0.22, 0.19, 0.27), border.lightened(0.2), 3 if equipped else 1))
	b.add_theme_stylebox_override("pressed", _panel(Color(0.2, 0.18, 0.25), border, 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func():
		GameState.equip(slot, piece.id)
		GameState.save_meta()
		_rebuild())

	var title := ("✓ " if equipped else "") + piece.title
	_lbl(b, title, Vector2(8, 6), Vector2(160, 20), 14, ec.lightened(0.35))
	var sub := "✦ +%d" % piece.drip
	if not piece.injected_cards.is_empty():
		sub += "   +%d card" % piece.injected_cards.size()
	_lbl(b, sub, Vector2(8, 28), Vector2(160, 16), 12, Color(0.8, 0.8, 0.85))
	var pt := piece.passive_text if piece.passive_text != "" else "—"
	_lbl(b, pt, Vector2(8, 46), Vector2(162, 28), 11, Color(0.66, 0.66, 0.72))
	return b

func _update_summary() -> void:
	var lines: Array[String] = []
	lines.append("LOADOUT")
	lines.append("")
	lines.append("✦ Swag income: +%d / turn" % GameState.preview_drip())
	var injected := 0
	var passives: Array[String] = []
	for p in GameState.equipped_pieces():
		injected += p.injected_cards.size()
		if p.passive_text != "":
			passives.append("• " + p.passive_text)
	lines.append("🃏 Cards added to deck: %d" % injected)
	lines.append("")
	lines.append("Passives:")
	if passives.is_empty():
		lines.append("  (none)")
	else:
		lines.append_array(passives)
	_summary.text = "\n".join(lines)

func _enter() -> void:
	GameState.finalize_loadout()
	get_tree().change_scene_to_file("res://scenes/combat/combat.tscn")

# --- helpers ---
func _lbl(parent: Control, text: String, pos: Vector2, sz: Vector2, fs: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)

func _panel(bg: Color, border: Color, bw: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s
