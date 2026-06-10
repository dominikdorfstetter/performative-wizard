extends Control
## Post-victory reward. Awards gold (scaled by encounter difficulty), grants an artefact
## on Elite kills, and offers a card to add. Returns to the map.

@onready var _options: HBoxContainer = %Options

func _ready() -> void:
	NodeUI.gradient_bg(self)
	Audio.play_music("menu")
	(%Title as Label).text = Loc.t("BIG W!   cop a card")
	(%Title as Label).add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	(%Title as Label).add_theme_color_override("font_color", Color(1.0, 0.31, 0.70))
	(%Banner as Label).text = ""

	var node := GameState.current_node()
	var gain := GameState.combat_reward(node) + GameState.gold_income()
	GameState.gold += gain
	var tail := ""
	var vip := int(node.get("critic_bonus_gold", 0))
	if vip > 0:
		tail += "\n" + Loc.t("VIP ovation: +%d gold — she approved.") % vip

	# The Critic's review of the fight you just had — and a heads-up on what her
	# verdict did to the road ahead.
	if GameState.critic_last_rating != "":
		var quip := GameState.critic_quip(GameState.critic_last_rating)
		if GameState.pending_critic == "S":
			quip += "   " + Loc.t("— a VIP room opens ahead.")
		elif GameState.pending_critic == "C":
			quip += "   " + Loc.t("— a heckler's waiting in your next fight.")
		tail += "\n" + Loc.t("THE CRITIC:  ") + quip
		var d := GameState.critic_last_details
		if not d.is_empty():
			tail += "\n" + Loc.t("because: peak Aura %d · %d tiers lit · %s") % [
				int(d.get("peak_swag", 0)), int(d.get("thresholds_lit", 0)),
				Loc.t("clean cash-out finish") if bool(d.get("finisher_clean", false)) else Loc.t("no finisher cash-out")]
		_stamp_grade(GameState.critic_last_rating)

	# gold counts up with coin ticks instead of appearing as a static total
	var goal := GameState.gold
	var sub_lbl := %Subtitle as Label
	var count := func(v: int) -> void:
		sub_lbl.text = ("+%d gold  (now %d)    ·    HP %d/%d    ·    Deck %d" % [
			v, goal - gain + v, GameState.player_hp, GameState.player_max_hp, GameState.deck.size()]) + tail
	count.call(0)
	var count_tw := create_tween()
	count_tw.tween_method(count, 0, gain, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Audio.play("coin", -4.0)
	get_tree().create_timer(0.3).timeout.connect(func(): Audio.play("coin", -7.0))

	if node.get("type") == "Elite":
		var aid := _random_unowned_artifact()
		if aid != &"":
			GameState.add_artifact(aid)
			var a := Database.get_artifact(aid)
			(%Banner as Label).text = Loc.t("elite loot:")
			(%Banner as Label).add_theme_color_override("font_color", Color(1.0, 0.82, 0.29))
			# the canonical item panel (left, mirroring the grade stamp on the right)
			NodeUI.item_reveal(self, SpriteBank.artifact_texture(aid), a.title, [a.description], Vector2(28, 120))

	var deal_i := 0
	for id in GameState.reward_offer(3):
		var card := Database.get_card(id)
		if card != null:
			var holder := _big_card(card, id)
			holder.modulate.a = 0.0
			_options.add_child(holder)
			var deal := create_tween()
			deal.tween_interval(0.12 + deal_i * 0.13)
			deal.tween_callback(func(): Audio.play("card", -10.0))
			deal.tween_property(holder, "modulate:a", 1.0, 0.16)
			deal_i += 1

	var skip := %Skip as Button
	skip.pressed.connect(_to_map)
	skip.pressed.connect(Audio.play.bind("click", -7.0))
	skip.add_theme_stylebox_override("normal", NodeUI.box(Color(0.15, 0.13, 0.2), Color(0.45, 0.5, 0.62), 2))
	skip.add_theme_stylebox_override("hover", NodeUI.box(Color(0.22, 0.19, 0.3), Color(0.6, 0.66, 0.78), 2))
	skip.add_theme_stylebox_override("pressed", NodeUI.box(Color(0.2, 0.17, 0.27), Color(0.45, 0.5, 0.62), 2))
	skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	skip.text = Loc.t("Skip")

## The letter-grade stamp: her verdict slams onto the screen with a sting — the
## review is the USP and used to be an unnoticed text line.
func _stamp_grade(letter: String) -> void:
	var colors := {"S": Color(1.0, 0.82, 0.29), "A": Color(0.6, 0.95, 0.7), "B": Color(0.85, 0.85, 0.95), "C": Color(0.92, 0.46, 0.5)}
	var stamp := Label.new()
	stamp.text = letter
	stamp.add_theme_font_override("font", NodeUI.DISPLAY_FONT)
	stamp.add_theme_font_size_override("font_size", 110)
	stamp.add_theme_color_override("font_color", colors.get(letter, Color.WHITE))
	stamp.position = Vector2(940, 52)
	stamp.size = Vector2(140, 130)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.pivot_offset = Vector2(70, 65)
	stamp.rotation = deg_to_rad(-8)
	stamp.scale = Vector2(2.6, 2.6)
	stamp.modulate.a = 0.0
	add_child(stamp)
	var ring := Panel.new()
	ring.position = Vector2(-10, 4)
	ring.size = Vector2(160, 130)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(4)
	sb.border_color = colors.get(letter, Color.WHITE)
	sb.set_corner_radius_all(16)
	ring.add_theme_stylebox_override("panel", sb)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_child(ring)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(stamp, "modulate:a", 1.0, 0.16)
	if letter == "S" or letter == "A":
		Audio.play("crowd", -3.0)
	else:
		Audio.play("debuff", -4.0)

# scale cards up and box them so they spread across the screen instead of clustering
func _big_card(card: CardData, id: StringName) -> Control:
	var view := CardView.build(card, true, _take.bind(id))
	view.pivot_offset = Vector2(75, 100)
	view.scale = Vector2(1.45, 1.45)
	view.position = Vector2(34, 45)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(218, 290)
	holder.add_child(view)
	return holder

func _random_unowned_artifact() -> StringName:
	var all := Database.all_artifact_ids().duplicate()
	all.shuffle()
	for aid in all:
		if not GameState.has_artifact(aid) and GameState.artifact_unlocked(aid):
			return aid
	return &""

func _take(id: StringName) -> void:
	Audio.play("card", -4.0)
	GameState.deck.append(id)
	_to_map()

func _to_map() -> void:
	Fader.change_scene("res://scenes/map/map.tscn")
