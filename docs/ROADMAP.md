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

- [x] **Unlock wizards through play** — Fire free; Necro at 120 lifetime Clout, Rizz
  at 320. `class_select` greys locked wizards with an unlock hint.
- [x] **Card/relic unlock pool** — CardData/ArtifactData `unlock_clout`; reward/shop/
  chest/elite pools filter by lifetime Clout so the meta expands options.
- [x] **Act 2 + Act 3** — runs are 3 acts; a boss win regenerates the map and carries
  deck/HP/artifacts; `node_scales` scales by act. Map header shows "Act n/3".
- [x] **Ascension / Hard-Mode ladder** — clearing banks the next tier; class_select
  picker dials 0..ascension (+8% HP, +6% dmg, +10 Clout per tier).

## Later — Content depth & systems ✅
- [x] **De-dupe & expand cards** — repurposed the strict-dominant Pickup Line; added
  Power cards + Spread Rumors (poison). 38 cards.
- [x] **Make `Power` cards real** — ritual/aura_engine/hive_mind/barrier tick each turn
  (`_tick_powers`); Slow Burn, Hive Mind, Sigma Grindset, Pickup Line.
- [x] **More artifacts tied to new statuses** — Venom Vial (poison +1), Spotlight
  (enemies start Cooked). 14 artifacts.
- [x] **Second-tier statuses** — `poison` (ramping, ticks for both sides) and reactive
  `enrage` (EnemyData.enrage); `frail` shipped earlier.
- [x] **Events with real choices** — The Therapist (remove a card) and Cursed Bargain
  (MAX HP ↔ artefact); merchant rolls respect unlocks.

## Polish backlog ✅
- [x] Combat status-gain tells (debuff name floats over the wizard + sting).
- [x] Richer title screen (ambient sparkles, twinkles, title glow pulse).
- [x] Card upgrade system — Rest "Glow Up" makes a card cost 1 less (per-id, run-scoped).

## Done — deferred item
- [x] **Enemy summoners** — `summon_ally` intent spawns adds mid-fight (Possessed
  Wardrobe → Sock Puppet, The Algorithm → Roomba bot); UI rebuilds the row.

---
**Roadmap complete (2026-06-06).** Roster: 38 cards, 23 enemies + 2 bosses, 3 wizards,
17 outfits, 14 artifacts. **81/81 tests.** Future ideas live in `DESIGN_REVIEW.md` /
`REVIEW_2.md`.

**Post-roadmap (user requests, also shipped):** German + Spanish localization
(`Loc` autoload + `loc_de.gd`/`loc_es.gd`, language picker in Options) covering UI,
content, combat HUD, banter, and log lines; plus a Review #2 pass (`REVIEW_2.md`) that
re-decoupled `CombatManager` and fixed a latent Options-screen parse bug.

## Definition of done per slice
Each slice: data/code change → `godot --headless scenes/test_combat.tscn` green →
render a preview PNG → commit with a focused message → keep the macOS build current.
