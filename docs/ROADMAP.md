# Performative Wizard — Roadmap

Prioritized from `DESIGN_REVIEW.md`. Ordered by **leverage** (impact ÷ effort).
Checkboxes track delivery; this file is the working plan.

## Now — Enemy overhaul (highest leverage) ✅ shipped 2026-06-06
The weakest pillar and the user's explicit ask. Detailed plan in `ENEMY_REDESIGN.md`.

- [x] **Retheme the off-theme enemies** — Goblin Gremlin→Wi-Fi Gremlin 📶, Clout
  Goblin→Clout Chaser 🤳, Gargoyle Cherub→Garden Gargoyle 🏛️; emoji collisions gone.
- [x] **Add enemy intent verbs** to the engine: `multi-hit` (`hits` field), `heal`,
  `frail` (player gains 25% less Block; new `crack` icon).
- [x] **Give each enemy a distinct pattern** — the `5/5/5` roomba is now a 4×3 flurry
  + guard; no two enemies share an identical loop.
- [x] **Real elite mechanics** — Gym Rat 🏋️ (ramp→multi-hit), Garden Gargoyle
  self-heals, Vending Machine 🥤 restocks; elites have signature verbs.
- [x] **A second boss** — The Algorithm 📱 (Feed/Shadowban rhythm); `boss()` now
  randomly picks between The Hater and The Algorithm.
- [x] New on-theme enemies: Possessed Router 📡 (frail), Vengeful Vending Machine 🥤
  (heal), Gym Rat 🏋️ (multi-hit elite). Roster now 23 enemies + 2 bosses.
- [ ] **Enemy summoners** (spawn adds mid-fight) — needs CombatManager + combat_ui
  support for a growing enemy list; deferred to its own slice.

## Next — Progression & unlock arc
The missing roguelite hook.

- [ ] **Unlock wizards through play** — start with Fire; unlock Necro/Rizz via Clout
  milestones or beating the boss. Gate `class_select` on `GameState.unlocked_wizards`.
- [ ] **Card/relic unlock pool** — seed each wizard with a small pool, unlock the
  rest via wins/Clout so the meta *expands options*, not just buys outfits.
- [ ] **Act 2 (+ Act 3)** — chain acts with escalating scaling and a boss each.
  Generalize the map to `act` count; reset per act, carry deck/HP/artifacts.
- [ ] **Ascension/"Hard Mode" ladder** — post-win difficulty modifiers for replay.

## Later — Content depth & systems
- [ ] **De-dupe & expand cards** — merge functional duplicates; add real archetypes
  (draw engine, energy ramp, exhaust bombs, X-cost, multi-hit, scaling Powers).
- [ ] **Make `Power` cards real** — persistent in-combat buffs (e.g. "+1 Aura/turn",
  "every 3rd card crits"), the natural home for the drip fantasy.
- [ ] **More artifacts & outfit passives** tied to the new statuses (frail, jinx).
- [ ] **Second-tier statuses** — `poison` (ramps), `frail`, `entangle` (skip a card),
  enemy-side `enrage`.
- [ ] **Events with real choices** — current events are 50/50 coin flips; add
  build-shaping decisions (remove/transform/upgrade cards, swap outfits).

## Polish backlog (carried from the graphics grind)
- [ ] Combat status-effect popup animations (gain/expire tells).
- [ ] Richer title screen.
- [ ] Card upgrade system (a "+" version per card).

## Definition of done per slice
Each slice: data/code change → `godot --headless scenes/test_combat.tscn` green →
render a preview PNG → commit with a focused message → keep the macOS build current.
