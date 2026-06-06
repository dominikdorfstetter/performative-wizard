class_name EffectResolver
extends RefCounted
## Applies a list of effect dicts (from a card or an enemy intent) to combatants.
## Centralising this keeps every card/enemy purely data — no per-card scripts.
##
## ctx keys:
##   "source": Combatant       — who plays the card
##   "target": Combatant       — who it hits
##   "bonus_damage": int       — flat add to each damage op (e.g. Swag threshold)
##   "pierce": bool            — damage ignores Block (e.g. Swag >=15 first spell)
##   "combat": CombatManager   — for effects that touch combat-level state (Swag)

static func apply(effects: Array, ctx: Dictionary) -> void:
	for e in effects:
		_apply_one(e, ctx)

static func _has(ctx: Dictionary, passive: StringName) -> bool:
	return passive in ctx.get("passives", [])

static func _apply_one(e: Dictionary, ctx: Dictionary) -> void:
	var op: String = e.get("op", "")
	var amount: int = int(e.get("amount", 0))
	var source: Combatant = ctx.get("source")
	var target: Combatant = ctx.get("target")
	var bonus: int = int(ctx.get("bonus_damage", 0))
	var pierce: bool = bool(ctx.get("pierce", false))
	var crit: int = 2 if bool(ctx.get("crit", false)) else 1
	match op:
		"damage":
			if target != null:
				target.take_damage(compute_damage(amount + bonus, source, target) * crit, pierce)
		"damage_all":
			for en in ctx.get("enemies", []):
				if not en.is_dead():
					en.take_damage(compute_damage(amount + bonus, source, en) * crit, pierce)
		"damage_x_burn":
			if target != null:
				var dmg := target.status(&"burn") * int(e.get("mult", 2))
				target.take_damage(compute_damage(dmg + bonus, source, target) * crit, pierce)
		"damage_if_status":
			if target != null:
				var dmg := amount
				if target.status(StringName(e.get("status", &""))) > 0:
					dmg += int(e.get("bonus", 0))
				target.take_damage(compute_damage(dmg + bonus, source, target) * crit, pierce)
		"block":
			if source != null:
				source.block += amount
		"heal":
			if source != null:
				source.heal(amount)
		"apply_status":
			if target != null:
				var sid := StringName(e.get("status", &""))
				var stacks := amount
				if sid == &"burn" and _has(ctx, &"burn_plus_1"):
					stacks += 1
				target.add_status(sid, stacks)
		"self_status":
			if source != null:
				source.add_status(StringName(e.get("status", &"")), amount)
		"summon":
			if source != null:
				var n := amount
				if _has(ctx, &"undead_plus_1_on_summon"):
					n += 1
				source.add_status(&"undead", n)
		"gain_swag":
			var cm = ctx.get("combat")
			if cm != null:
				cm.gain_swag(amount)
		"draw":
			var cmd = ctx.get("combat")
			if cmd != null:
				cmd.draw_cards(amount)
		"sacrifice_strike":
			_sacrifice_strike(e, ctx, source, target, bonus, pierce)
		_:
			push_warning("[EffectResolver] unknown op: " + op)

## Consume Undead from the source; only if enough are available do the payoffs land.
static func _sacrifice_strike(e: Dictionary, ctx: Dictionary, source: Combatant, target: Combatant, bonus: int, pierce: bool) -> void:
	if source == null:
		return
	var sac := int(e.get("sac", 1))
	if source.status(&"undead") < sac:
		return
	source.add_status(&"undead", -sac)
	if e.has("damage") and target != null:
		target.take_damage(compute_damage(int(e["damage"]) + bonus, source, target), pierce)
	if e.has("swag"):
		var cm = ctx.get("combat")
		if cm != null:
			cm.gain_swag(int(e["swag"]))

## Strength (source) and Vulnerable (target) modifiers. Block handled in take_damage.
static func compute_damage(amount: int, source: Combatant, target: Combatant) -> int:
	var dmg := amount
	if source != null:
		dmg += source.status(&"strength")
		if source.status(&"weak") > 0:
			dmg = int(dmg * 0.75)
	if target != null and target.status(&"vulnerable") > 0:
		dmg = int(round(dmg * 1.5))
	return max(0, dmg)
