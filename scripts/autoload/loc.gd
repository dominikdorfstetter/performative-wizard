extends Node
## Localization. English is the source language; Loc.t("english") returns the
## active-locale string (passthrough if untranslated or locale == en).
##
## Translation philosophy: keep the international Gen-Z slang that IS the joke
## (Rizz, Aura, Slay, Delulu, Sigma, Glow Up, Cooked, Mid, "it's giving", ...) —
## these are borrowed into German and Spanish youth speech verbatim — and
## translate the instructional/narrative connective text + plain descriptive names.

const LOCALES := ["en", "de", "es"]
const LOCALE_NAME := {"en": "English", "de": "Deutsch", "es": "Español"}

var locale := "en"

func set_locale(l: String) -> void:
	if l in LOCALES:
		locale = l

func t(s: String) -> String:
	if locale == "en" or s == "":
		return s
	var tbl: Dictionary = _DE if locale == "de" else _ES
	return tbl.get(s, s)

# Translations live in loc_de.gd / loc_es.gd (preloaded so we don't depend on the
# global class-name cache, which isn't regenerated in headless/exported runs).
const _DE_SRC := preload("res://scripts/autoload/loc_de.gd")
const _ES_SRC := preload("res://scripts/autoload/loc_es.gd")
var _DE: Dictionary = {}
var _ES: Dictionary = {}

func _ready() -> void:
	_DE = _DE_SRC.TABLE
	_ES = _ES_SRC.TABLE
	# Belt-and-braces for the bundled UI font: gui/theme/custom_font covers the
	# theme, but forcing the engine-wide fallback too means no platform (web
	# included) can ever quietly drop back to the stock Godot font.
	var f: Font = load("res://assets/fonts/jersey20.ttf")
	if f != null:
		ThemeDB.fallback_font = f
