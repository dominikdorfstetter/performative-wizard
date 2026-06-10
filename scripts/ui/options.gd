extends Control
## Options: fullscreen toggle and reset-progress, reachable from the main menu.

var _confirm_reset := false
var _reset_done := false

func _ready() -> void:
	NodeUI.gradient_bg(self)
	_build()

## Most-used settings first; audio toggles share a row with their slider so the
## column FITS the 648px viewport (two stacked slider rows once pushed 'Back to
## Menu' off-screen — you literally couldn't leave); destructive Reset sits
## last, visually separated from Back.
func _build() -> void:
	_clear()
	NodeUI.title(self, "Options", Color(0.5, 0.62, 0.85), SpriteBank.icon_texture(&"gear"))
	var vb := VBoxContainer.new()
	vb.position = Vector2(346, 142)
	vb.add_theme_constant_override("separation", 10)
	add_child(vb)
	vb.add_child(NodeUI.menu_button(Loc.t("Language:   %s") % Loc.LOCALE_NAME[GameState.locale], _cycle_lang, Color(0.62, 0.55, 0.9), 460.0))
	vb.add_child(_audio_row(
		Loc.t("Sound FX:   %s") % Loc.t("On" if GameState.sfx_on else "Off"), _toggle_sfx,
		GameState.sfx_vol, func(v: float):
			GameState.sfx_vol = v
			Audio.set_sfx_volume(v)
			GameState.save_meta()))
	vb.add_child(_audio_row(
		Loc.t("Music:   %s") % Loc.t("On" if GameState.music_on else "Off"), _toggle_music,
		GameState.music_vol, func(v: float):
			GameState.music_vol = v
			Audio.set_music_volume(v)
			GameState.save_meta()))
	vb.add_child(NodeUI.menu_button(Loc.t("Screen shake & flashes:   %s") % Loc.t("On" if GameState.effects_on else "Off"), _toggle_effects, Color(0.5, 0.62, 0.85), 460.0))
	if not OS.has_feature("web"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		vb.add_child(NodeUI.menu_button(Loc.t("Fullscreen:   %s") % Loc.t("On" if fs else "Off"), _toggle_fs, Color(0.5, 0.62, 0.85), 460.0))
	vb.add_child(NodeUI.menu_button("Back to Menu", _back, Color(0.45, 0.82, 0.55), 460.0))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	vb.add_child(NodeUI.menu_button("Confirm Reset?" if _confirm_reset else "Reset All Progress", _reset, Color(0.9, 0.4, 0.42), 460.0))
	if _confirm_reset:
		NodeUI.sub(self, "This wipes all unlocked clothes and Clout. Click again to confirm.", 608)
	elif _reset_done:
		NodeUI.sub(self, "Progress reset to a fresh start.", 608)

## On/Off toggle and its volume slider on ONE row.
func _audio_row(toggle_text: String, on_toggle: Callable, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var btn := NodeUI.menu_button(toggle_text, on_toggle, Color(0.5, 0.62, 0.85), 250.0)
	btn.add_theme_font_size_override("font_size", 18)
	row.add_child(btn)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(196, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_back()
		get_viewport().set_input_as_handled()

func _clear() -> void:
	for c in get_children():
		if not (c is TextureRect):
			c.queue_free()
