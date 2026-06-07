# Performative Wizard — Archetypes, Rarity & Per-Wizard Unlocks (2026-06-07)

> Built from a 4-lens design panel (archetypes / progression / architecture / USP-integrity)
> + adversarial critique. Direction from the owner: **vanilla starters → 2 build archetypes
> per wizard → rarity-tiered, per-wizard progressive unlocks**, all still feeding the Aura /
> Critic USP. Companion to `docs/USP.md`.

## The shape

- **Vanilla starters.** Each wizard opens with StS-style basics (4 basic attacks, 3 basic
  blocks, a light identity hint) **+ one guaranteed Pose** (`strike_a_pose`) so the Aura
  signature still shows from fight 1. Strategy is **built from rewards**, not handed out.
- **Two archetypes per wizard** — both engage the Aura/Critic USP (no build ignores Aura).
- **4-tier rarity:** Common (one basic op) · Rare (a light engine piece) · Epic (a build
  enabler — Powers/finishers) · Legendary (one build-defining chase payoff per wizard).
- **Per-wizard unlocking, single currency.** Cards gate on **lifetime Clout** (the existing
  axis — no second currency), and *per-wizard-ness comes free* because each wizard only ever
  offers its own `reward_pool`. **Draftability** is the load-bearing add: a `CardData.archetype`
  tag biases reward offers toward your emerging build (`GameState.reward_offer`).

## The six builds

| Wizard | Build A | Build B |
|---|---|---|
| **Fire** | **Slow Roast** — park a burn DoT, bank Aura to the 18 pierce line, flex, cash `grand_finale` | **Go Viral** — flood cheap Pose/AoE to spike `pose_swag`, finish wide with `encore_for_fans` |
| **Necro** | **Sacrifice** — summon then `sacrifice_strike` Goons for active Aura, burst + sustain via `soak_it_in` | **Swarm** — keep Goons alive (`hive_mind`/`mass_grave`), win on chip, finish spread |
| **Rizz** | **Crit Storm** — many cheap attacks → `swag_on_crit` Aura pings → coast lit-3 → `grand_finale` | **Rizz Ramp** — stack Strength for one huge crit, hold the spotlight (flex), `take_a_bow` |

Every build has a **bold S-route**: hoard/ramp lines flex or hold the Encore spotlight; the
wide/tempo lines (Go Viral, Swarm, Crit Storm) earn S via an **active decisive close** —
`finisher_clean and (aoe_plays ≥ 2 or pose_swag ≥ 12)` — which *can't* be farmed by coasting
on passive drip. Each wizard's two builds use **distinct finishers**, so the Critic's per-run
drift sees them as different styles. Necro-B's held board reads as a dedicated **`swarm`**
fingerprint (`peak_undead ≥ 4`).

## New cards (7)

| id | rarity | wizard/tag | effect |
|---|---|---|---|
| `smoulder` | Common | Fire / roast | Power: +1 Aura/turn (2nd hoard engine) |
| `serve_face` | Common | Fire / viral | cost-0 Pose: +2 Aura |
| `bone_offering` | Common | Necro / sac | cost-0: sacrifice a Goon → +3 Aura |
| `gravecall` | Common | Necro / swarm | Summon 1 + draw 1 |
| `double_tap` | Common | Rizz / storm | Deal 3 twice (two crit rolls → two `swag_on_crit` pings) |
| `flashpoint` | **Legendary** | Fire / roast | Deal 3× Roast, then apply 3 Roast |
| `mass_sacrifice` | **Legendary** | Necro / sac | Sacrifice 3 Goons → deal 16 + 6 Aura |
| `main_character` | **Legendary** | Rizz / ramp | Deal 8 + 3 Rizz |

Pool: **49 cards** — 30 Common / 5 Rare / 11 Epic / 3 Legendary.

## Bugs fixed along the way
- `flame_lash` dealt a flat 4 — its "+4 if Roasted" text was never implemented (now
  `damage_if_status`).
- `chest.gd` handed out cards straight from the raw `reward_pool`, **leaking locked cards**
  (now routes through `unlocked_cards`).

## Engine touch-points
- `CardData.archetype` (new field). `GameState.deck_archetype()` + `reward_offer()` (draft bias).
- `combat_manager.gd`: `pose_swag` (active Aura) + `peak_undead` tracking; `style_signature`
  gains a `swarm` branch; `compute_show_rating` gains the wide/tempo bold S-path.
- `card_view.gd` RARITY_COLOR (4 tiers) + thick border for Epic/Legendary; `shop.gd` pricing
  `{Common:40, Rare:60, Epic:90, Legendary:140}`.
- Save schema unchanged (cards gate on existing `clout_earned`; `load_meta` is back-compat).

## Deliberately deferred / out of scope
- A second "Stage Time" currency + a 5-rank mastery track + a Green-Room collection screen —
  the single-axis design delivers per-wizard unlocking without the extra systems/grind.
- Per-archetype Legendaries for *every* build (each **wizard** gets one chase Legendary for v1;
  the other build's spine is an existing Epic).
