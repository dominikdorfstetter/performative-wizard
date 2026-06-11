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

## Relic boosts on applied debuffs (ember_pin / venom_vial), shared by the single-
## target and room-wide apply ops.
static func _adjusted_stacks(sid: StringName, amount: int, ctx: Dictionary) -> int:
	var stacks := amount
	if sid == &"burn" and _has(ctx, &"burn_plus_1"):
		stacks += 1
	if sid == &"poison" and _has(ctx, &"poison_plus_1"):
		stacks += 1
	return stacks

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
				var blk := amount
				if source.status(&"frail") > 0:   # exposed fit → softer guard
					blk = int(blk * 0.75)
				source.block += blk
		"heal":
			if source != null:
				source.heal(amount)
		"apply_status":
			if target != null:
				var sid := StringName(e.get("status", &""))
				target.add_status(sid, _adjusted_stacks(sid, amount, ctx))
		"apply_status_all":
			# Room-wide status. Relic boosts (ember_pin/venom_vial) apply PER ENEMY.
			var sid_all := StringName(e.get("status", &""))
			for en in ctx.get("enemies", []):
				if not en.is_dead():
					en.add_status(sid_all, _adjusted_stacks(sid_all, amount, ctx))
		"self_status":
			if source != null:
				source.add_status(StringName(e.get("status", &"")), amount)
		"cleanse":
			if source != null:
				# poison included: Toxic never decays now, so cleansing IS the answer
				for s in [&"weak", &"vulnerable", &"jinx", &"poison"]:
					source.statuses.erase(s)
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
		"peek":
			var cmp = ctx.get("combat")
			if cmp != null:
				cmp.peek_draw(amount)
		"peek_pick":
			var cmpp = ctx.get("combat")
			if cmpp != null:
				cmpp.request_pick(amount)
		"shuffle_discard":
			var cmsd = ctx.get("combat")
			if cmsd != null:
				cmsd.recycle_discard()
		"retain":
			var cmr = ctx.get("combat")
			if cmr != null:
				cmr.retain_hand = true
		"goon_strike":
			var cmg = ctx.get("combat")
			if cmg != null:
				cmg.goon_strike()
		"damage_x_status":
			# Optional keys: of: "self"|"target" (whose stacks scale it; default target),
			# all: bool (hit every living enemy — each reads its OWN stacks unless
			# of=="self"), amount (flat base, default 0). One crit roll covers all hits,
			# matching damage_all. NOTE: when status == "strength", compute_damage adds
			# the source's strength AGAIN — effective scaling is (mult+1)×Rizz.
			var xsid := StringName(e.get("status", &""))
			var xmult := int(e.get("mult", 2))
			var read_self: bool = String(e.get("of", "target")) == "self"
			if bool(e.get("all", false)):
				for en in ctx.get("enemies", []):
					if not en.is_dead():
						var st: int = source.status(xsid) if read_self else en.status(xsid)
						en.take_damage(compute_damage(amount + st * xmult + bonus, source, en) * crit, pierce)
			elif target != null:
				var st2: int = source.status(xsid) if read_self else target.status(xsid)
				target.take_damage(compute_damage(amount + st2 * xmult + bonus, source, target) * crit, pierce)
		"block_x_status":
			# Block scaled by someone's stacks (of: "self" e.g. your Goons; "target" e.g.
			# their Roasted). Exposed (frail) softens the SCALED part, same as the block op.
			if source != null:
				var bsid := StringName(e.get("status", &""))
				var reader: Combatant = source if String(e.get("of", "target")) == "self" else target
				var bstacks: int = reader.status(bsid) if reader != null else 0
				var blk2 := amount + bstacks * int(e.get("mult", 2))
				if source.status(&"frail") > 0:
					blk2 = int(blk2 * 0.75)
				source.block += blk2
		"self_status_x_self":
			# Gain N of status X where N = your stacks of status Y × mult (floored),
			# optionally capped. Reads at resolve time — earlier ops in the same effects
			# array (e.g. a Rizz gain) are already applied.
			if source != null:
				var grant := int(floor(source.status(StringName(e.get("from", &""))) * float(e.get("mult", 1.0))))
				var gcap := int(e.get("cap", 0))
				if gcap > 0:
					grant = mini(grant, gcap)
				if grant > 0:
					source.add_status(StringName(e.get("status", &"")), grant)
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
	# celebration_of_life relic: every sacrificed Goon tips +1 Aura on the way out.
	# Counts as pose_swag — the sendoff is a performance, and the Critic credits it.
	if _has(ctx, &"sac_swag_1"):
		var cms = ctx.get("combat")
		if cms != null:
			cms.gain_swag(sac)
			cms.pose_swag += sac

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
