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
	vb.add_child(NodeUI.menu_button(Loc.t("Music:   %s") % Loc.t("On" if GameState.music_on else "Off"), _toggle_music))
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

func _reset() -> void:
	if _confirm_reset:
		GameState.new_game()
		_confirm_reset = false
		_reset_done = true
	else:
		_confirm_reset = true
	_build()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/main_menu.tscn")

func _clear() -> void:
	for c in get_children():
		if not (c is TextureRect):
			c.queue_free()
