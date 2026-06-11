extends Control
## Collection: lifetime stats + per-wizard unlock progress (cards, fits, relics).
## Answers "how much have I unlocked?" — the meta loop used to be invisible
## outside the moment an unlock happened.

func _ready() -> void:
	NodeUI.background(self)
	NodeUI.title(self, "Collection", NodeUI.PINK, SpriteBank.icon_texture(&"star"))
	NodeUI.sub(self, Loc.t("lifetime Clout %d   ·   to spend %d   ·   Critic score %d   ·   Ascension %d") % [
		GameState.clout_earned, GameState.clout, GameState.critic_score, GameState.ascension])

	var row := HBoxContainer.new()
	row.position = Vector2(96, 156)
	row.size = Vector2(960, 330)
	row.add_theme_constant_override("separation", 30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	for wid in [&"fire", &"necro", &"rizz"]:
		var w := Database.get_wizard(wid)
		if w != null:
			row.add_child(_wizard_column(w))

	# relics are account-wide, so they get one shared progress line
	var total_art := Database.artifacts.size()
	var unlocked_art := 0
	for aid in Database.artifacts:
		if GameState.artifact_unlocked(aid):
			unlocked_art += 1
	var relics := Label.new()
	relics.text = Loc.t("Relic pool unlocked: %d / %d") % [unlocked_art, total_art]
	relics.position = Vector2(0, 506)
	relics.size = Vector2(1152, 24)
	relics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relics.add_theme_font_size_override("font_size", 17)
	relics.add_theme_color_override("font_color", NodeUI.GOLD)
	add_child(relics)

	var teaser := _next_unlock_teaser()
	if teaser != "":
		var nxt := Label.new()
		nxt.text = teaser
		nxt.position = Vector2(0, 534)
		nxt.size = Vector2(1152, 24)
		nxt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nxt.add_theme_font_size_override("font_size", 15)
		nxt.add_theme_color_override("font_color", Color(0.7, 0.7, 0.78))
		add_child(nxt)

	var back := NodeUI.small_button("Back", func(): Fader.change_scene("res://scenes/hub/class_select.tscn"), Color(0.4, 0.85, 0.55))
	back.position = Vector2(486, 588)
	add_child(back)

func _wizard_column(w: WizardData) -> Control:
	var locked := not GameState.wizard_unlocked(w.id)
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(300, 330)
	panel.add_theme_stylebox_override("panel", NodeUI.box(Color(0.13, 0.11, 0.17), Color(0.4, 0.4, 0.46) if locked else w.accent.darkened(0.1)))

	var tex := SpriteBank.wizard_texture(w.id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = Vector2(110, 12)
		tr.size = Vector2(80, 80)
		tr.modulate = Color(0.3, 0.3, 0.35) if locked else Color.WHITE
		panel.add_child(tr)
	_lbl(panel, w.pname, 96, 20, Color(0.6, 0.6, 0.66) if locked else w.accent.lightened(0.35))
	if locked:
		_lbl(panel, GameState.locked_wizard_hint(w.id), 130, 14, Color(0.85, 0.7, 0.4))

	# cards: how much of this wizard's reward pool the meta has opened up
	var pool: Array = w.reward_pool
	var open_cards: int = GameState.unlocked_cards(pool, w.id).size()
	_lbl(panel, Loc.t("Cards unlocked: %d / %d") % [open_cards, pool.size()], 168, 16, Color(0.85, 0.85, 0.9))
	panel.add_child(_bar(open_cards, pool.size(), 196, w.accent))

	# fits: owned wardrobe pieces this wizard can wear (element + neutral)
	var total_fits := 0
	var owned_fits := 0
	for oid in Database.outfits:
		var p: OutfitData = Database.outfits[oid]
		if p.element == "Neutral" or p.element == w.element:
			total_fits += 1
			if oid in GameState.unlocked_outfits:
				owned_fits += 1
	_lbl(panel, Loc.t("Fits owned: %d / %d") % [owned_fits, total_fits], 226, 16, Color(0.85, 0.85, 0.9))
	panel.add_child(_bar(owned_fits, total_fits, 254, NodeUI.GOLD))

	if not locked:
		_lbl(panel, Loc.t("ready to serve"), 288, 14, Color(0.55, 0.8, 0.6))
	return panel

## The single next thing lifetime Clout will open — keeps "one more run" concrete.
## The single next thing on the unlock ladder — measured in "Clout to go" so the
## per-wizard card gates and the account-wide wizard/relic gates compare fairly.
func _next_unlock_teaser() -> String:
	var best_gap := -1
	var best_name := ""
	for wid in Database.wizards:
		var w: WizardData = Database.wizards[wid]
		var wgap := w.unlock_clout - GameState.clout_earned
		if wgap > 0 and (best_gap < 0 or wgap < best_gap):
			best_gap = wgap
			best_name = w.pname
		var wc := GameState.wizard_clout(wid)
		for cid in w.reward_pool:
			var c := Database.get_card(cid)
			if c == null:
				continue
			var gap := c.unlock_clout - wc
			if gap > 0 and (best_gap < 0 or gap < best_gap):
				best_gap = gap
				best_name = Loc.t("%s (%s)") % [Loc.t(c.title), w.pname]
	for aid in Database.artifacts:
		var a: ArtifactData = Database.artifacts[aid]
		var agap := a.unlock_clout - GameState.clout_earned
		if agap > 0 and (best_gap < 0 or agap < best_gap):
			best_gap = agap
			best_name = Loc.t(a.title)
	if best_gap < 0:
		return Loc.t("everything is unlocked — full drip achieved.")
	return Loc.t("next unlock: %s — %d more Clout") % [best_name, best_gap]

func _bar(value: int, total: int, y: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = max(1, total)
	bar.value = value
	bar.position = Vector2(30, y)
	bar.size = Vector2(240, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.09, 0.13)
	bg.set_corner_radius_all(5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

func _lbl(panel: Panel, text: String, y: float, fs: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(12, y)
	l.size = Vector2(276, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(l)
