class_name CombatManager
extends RefCounted
## The combat engine: turn loop, energy, the banked-Swag economy, draw/discard,
## enemy intents, and win/lose. Pure logic (no UI) so it can be unit-tested headless.
## A view layer connects to `changed` and re-renders.

signal changed
signal combat_ended(victory: bool)

enum State { PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

const HAND_SIZE := 5
const MAX_ENERGY := 3
const LOG_KEEP := 6

# Swag thresholds (banked pool -> passive bonus). Tuned by playtest.
const THRESHOLD_DAMAGE := 5      # >= : spells +2 damage
const THRESHOLD_DRAW := 10       # >= : draw +1 each turn
const THRESHOLD_PIERCE := 15     # >= : first spell each turn pierces Block
const SWAG_DAMAGE_BONUS := 2

var state: State = State.PLAYER_TURN
var player: Combatant
var enemy: Combatant
var enemy_data: EnemyData
var intent_index := 0
var turn := 0

var energy := 0
var max_energy := MAX_ENERGY
var swag := 0
var drip := 0                    # outfit Swag income per turn
var spells_this_turn := 0

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var passives: Array[StringName] = []         # outfit passive ids active this combat
var log_lines: Array[String] = []

# --- setup ---------------------------------------------------------------

func start_combat(p: Combatant, edata: EnemyData, deck: Array[CardData], drip_value: int, deterministic := false, outfit_passives: Array[StringName] = []) -> void:
	player = p
	enemy_data = edata
	enemy = Combatant.new()
	enemy.display_name = edata.title
	enemy.max_hp = edata.max_hp
	enemy.hp = edata.max_hp
	drip = drip_value
	passives = outfit_passives
	draw_pile = deck.duplicate()
	if not deterministic:
		randomize()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	intent_index = 0
	turn = 0
	log_lines.clear()
	state = State.PLAYER_TURN
	_apply_combat_start_passives()
	_say("A wild %s appears!" % enemy.display_name)
	_start_player_turn()

func has_passive(id: StringName) -> bool:
	return id in passives

func _apply_combat_start_passives() -> void:
	if has_passive(&"energy_plus_1"):
		max_energy += 1
	if has_passive(&"start_block_5"):
		player.block += 5
	if has_passive(&"swag_start_3"):
		swag += 3

# --- Swag economy --------------------------------------------------------

func gain_swag(amount: int) -> void:
	swag = max(0, swag + amount)

func swag_damage_bonus() -> int:
	return SWAG_DAMAGE_BONUS if swag >= THRESHOLD_DAMAGE else 0

func swag_extra_draw() -> int:
	return 1 if swag >= THRESHOLD_DRAW else 0

func swag_pierces() -> bool:
	return swag >= THRESHOLD_PIERCE

# --- turn loop -----------------------------------------------------------

func _start_player_turn() -> void:
	state = State.PLAYER_TURN
	spells_this_turn = 0
	turn += 1
	energy = max_energy
	var before := swag
	gain_swag(drip)                         # the performance income
	if has_passive(&"strength_at_10_swag") and swag >= 10:
		player.add_status(&"strength", 1)
		_say("Catwalk Heels: +1 Strength")
	_draw(HAND_SIZE + swag_extra_draw())
	if drip > 0:
		_say("— Your turn %d  (+%d swag → %d) —" % [turn, swag - before, swag])
	else:
		_say("— Your turn %d —" % turn)
	_emit()

func can_play(card: CardData) -> bool:
	return state == State.PLAYER_TURN and energy >= card.cost

func play_card(card: CardData) -> bool:
	if not can_play(card) or card not in hand:
		return false
	energy -= card.cost
	hand.erase(card)
	discard_pile.append(card)

	var swag0 := swag
	if card.swag_gain > 0:
		gain_swag(card.swag_gain)
		if has_passive(&"pose_plus_1"):
			gain_swag(1)

	var is_attack := card.type == "Attack"
	var first_spell := spells_this_turn == 0
	var pierced := is_attack and first_spell and swag_pierces()
	var atk_bonus := swag_damage_bonus() if is_attack else 0
	if is_attack and first_spell and has_passive(&"first_spell_plus_3"):
		atk_bonus += 3
	var ctx := {
		"source": player,
		"target": enemy,
		"combat": self,
		"passives": passives,
		"bonus_damage": atk_bonus,
		"pierce": pierced,
	}

	# Snapshot for the combat log.
	var ehp0 := enemy.hp
	var pblk0 := player.block
	var eburn0 := enemy.status(&"burn")

	# Finishers spend the whole pool; resolve them separately from generic effects.
	var normal: Array = []
	for e in card.effects:
		if String(e.get("op", "")).begins_with("finisher"):
			_resolve_finisher(e, ctx)
		else:
			normal.append(e)
	EffectResolver.apply(normal, ctx)

	if is_attack:
		spells_this_turn += 1

	_log_card(card, ehp0 - enemy.hp, player.block - pblk0, enemy.status(&"burn") - eburn0, swag - swag0, pierced)
	_check_end()
	_emit()
	return true

func _log_card(card: CardData, dmg: int, blk: int, burn_added: int, swag_delta: int, pierced: bool) -> void:
	var parts: Array[String] = []
	if dmg > 0:
		parts.append("%d dmg" % dmg)
	if blk > 0:
		parts.append("%d block" % blk)
	if burn_added > 0:
		parts.append("%d burn" % burn_added)
	if swag_delta > 0:
		parts.append("+%d swag" % swag_delta)
	elif swag_delta < 0:
		parts.append("spent %d swag" % -swag_delta)
	if pierced and dmg > 0:
		parts.append("pierced!")
	var msg := "You play %s" % card.title
	if not parts.is_empty():
		msg += "  →  " + ", ".join(parts)
	_say(msg)

func _resolve_finisher(e: Dictionary, ctx: Dictionary) -> void:
	match String(e.get("op", "")):
		"finisher_swag_x3":
			var raw := swag * 3 + int(ctx.get("bonus_damage", 0))
			enemy.take_damage(EffectResolver.compute_damage(raw, player, enemy), ctx.get("pierce", false))
			swag = 0
		_:
			push_warning("[CombatManager] unknown finisher: " + String(e.get("op", "")))

func end_turn() -> void:
	if state != State.PLAYER_TURN:
		return
	discard_pile.append_array(hand)
	hand.clear()
	# Undead strike at the end of your turn.
	var undead := player.status(&"undead")
	if undead > 0:
		var dealt := undead * 2
		enemy.take_damage(dealt)
		_say("Your %d Undead strike for %d" % [undead, dealt])
		if enemy.is_dead():
			_finish(true)
			return
	player.block = 0
	_decay(player)
	_enemy_turn()

func _enemy_turn() -> void:
	state = State.ENEMY_TURN
	_emit()
	var burned := _tick_burn(enemy)
	if burned > 0:
		_say("%s takes %d burn" % [enemy.display_name, burned])
	if enemy.is_dead():
		_finish(true)
		return
	var intent: Dictionary = enemy_data.intents[intent_index % enemy_data.intents.size()]
	_resolve_intent(intent)
	intent_index += 1
	_decay(enemy)
	enemy.block = 0
	if player.is_dead():
		_finish(false)
		return
	_start_player_turn()

func _resolve_intent(intent: Dictionary) -> void:
	var amount := int(intent.get("amount", 0))
	var name := enemy.display_name
	match String(intent.get("op", "")):
		"attack":
			var hp0 := player.hp
			player.take_damage(EffectResolver.compute_damage(amount, enemy, player))
			_say("%s hits you for %d" % [name, hp0 - player.hp])
		"block":
			enemy.block += amount
			_say("%s braces (Block %d)" % [name, amount])
		"apply_status":
			var s := StringName(intent.get("status", &""))
			player.add_status(s, amount)
			_say("%s inflicts %s %d" % [name, String(s).capitalize(), amount])
		"buff":
			var s2 := StringName(intent.get("status", &""))
			enemy.add_status(s2, amount)
			_say("%s gains %s %d" % [name, String(s2).capitalize(), amount])
		_:
			push_warning("[CombatManager] unknown intent: " + String(intent.get("op", "")))

func peek_intent() -> Dictionary:
	if enemy_data == null or enemy_data.intents.is_empty():
		return {}
	return enemy_data.intents[intent_index % enemy_data.intents.size()]

# --- helpers -------------------------------------------------------------

func _tick_burn(c: Combatant) -> int:
	var b := c.status(&"burn")
	if b <= 0:
		return 0
	c.take_damage(b, true)                   # Burn pierces Block
	if b - 1 <= 0:
		c.statuses.erase(&"burn")
	else:
		c.statuses[&"burn"] = b - 1
	return b

func _decay(c: Combatant) -> void:
	for s in [&"weak", &"vulnerable"]:
		var v := c.status(s)
		if v > 0:
			if v - 1 <= 0:
				c.statuses.erase(s)
			else:
				c.statuses[s] = v - 1

func _draw(n: int) -> void:
	for i in n:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func _check_end() -> void:
	if enemy.is_dead():
		_finish(true)

func _finish(victory: bool) -> void:
	state = State.WIN if victory else State.LOSE
	_say("✦ VICTORY ✦" if victory else "You have been defeated...")
	combat_ended.emit(victory)
	_emit()

func _say(msg: String) -> void:
	log_lines.append(msg)
	while log_lines.size() > LOG_KEEP:
		log_lines.pop_front()

func _emit() -> void:
	changed.emit()
