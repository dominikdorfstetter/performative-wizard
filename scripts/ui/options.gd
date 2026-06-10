extends Control
## Options: fullscreen toggle and reset-progress, reachable from the main menu.

var _confirm_reset := false
var _reset_done := false

func _ready() -> void:
	NodeUI.gradient_bg(self)
	_build()

func _build() -> void:
	_clear()
	NodeUI.title(self, "Options", Color(0.5, 0.62, 0.85), SpriteBank.icon_texture(&"gear"))
	var vb := VBoxContainer.new()
	vb.position = Vector2(406, 220)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	vb.add_child(NodeUI.menu_button(Loc.t("Language:   %s") % Loc.LOCALE_NAME[GameState.locale], _cycle_lang, Color(0.62, 0.55, 0.9)))
	vb.add_child(NodeUI.menu_button(Loc.t("Fullscreen:   %s") % Loc.t("On" if fs else "Off"), _toggle_fs))
	vb.add_child(NodeUI.menu_button(Loc.t("Sound FX:   %s") % Loc.t("On" if GameState.sfx_on else "Off"), _toggle_sfx))
	vb.add_child(_volume_row(Loc.t("SFX volume"), GameState.sfx_vol, func(v: float):
		GameState.sfx_vol = v
		Audio.set_sfx_volume(v)
		GameState.save_meta()))
	vb.add_child(NodeUI.menu_button(Loc.t("Music:   %s") % Loc.t("On" if GameState.music_on else "Off"), _toggle_music))
	vb.add_child(_volume_row(Loc.t("Music volume"), GameState.music_vol, func(v: float):
		GameState.music_vol = v
		Audio.set_music_volume(v)
		GameState.save_meta()))
	vb.add_child(NodeUI.menu_button(Loc.t("Screen shake & flashes:   %s") % Loc.t("On" if GameState.effects_on else "Off"), _toggle_effects))
	vb.add_child(NodeUI.menu_button("Confirm Reset?" if _confirm_reset else "Reset All Progress", _reset, Color(0.9, 0.4, 0.42)))
	vb.add_child(NodeUI.menu_button("Back to Menu", _back, Color(0.45, 0.82, 0.55)))
	if _confirm_reset:
		NodeUI.sub(self, "This wipes all unlocked clothes and Clout. Click again to confirm.", 430)
	elif _reset_done:
		NodeUI.sub(self, "Progress reset to a fresh start.", 430)

func _cycle_lang() -> void:
	var i: int = Loc.LOCALES.find(GameState.locale)
	GameState.set_language(Loc.LOCALES[(i + 1) % Loc.LOCALES.size()])
	_build()

func _toggle_fs() -> void:
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_MAXIMIZED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	_build()

func _toggle_sfx() -> void:
	GameState.set_audio(not GameState.sfx_on, GameState.music_on)
	_build()

func _toggle_music() -> void:
	GameState.set_audio(GameState.sfx_on, not GameState.music_on)
	_build()

func _toggle_effects() -> void:
	GameState.effects_on = not GameState.effects_on
	GameState.save_meta()
	_build()

## label + slider row matching the menu-button chrome
func _volume_row(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(340, 30)
	row.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(130, 0)
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82))
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(190, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row

func _reset() -> void:
	if _confirm_reset:
		GameState.new_game()
		_confirm_reset = false
		_reset_done = true
	else:
		_confirm_reset = true
	_build()

func _back() -> void:
	Fader.change_scene("res://scenes/hub/main_menu.tscn")

func _clear() -> void:
	for c in get_children():
		if not (c is TextureRect):
			c.queue_free()
