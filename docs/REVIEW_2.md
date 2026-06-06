# Performative Wizard — Review #2 (2026-06-06)

Second pass after the roadmap build-out. State: **38 cards, 23 enemies + 2 bosses,
3 wizards, 17 outfits, 14 artifacts, 3 acts, ascension, 81 tests, EN/DE/ES.**

## What's much better since Review #1
- **Progression is real now** — wizard/card/relic unlocks, 3 acts, ascension. The
  "why keep playing" question is answered.
- **Enemies have identity** — distinct silhouettes, multi-hit/heal/frail/enrage/
  summon verbs, two bosses. The "lazy" complaint is resolved.
- **Powers + statuses give builds depth** — poison/ritual/aura-engine/barrier open
  real archetypes beyond "deal X".
- **Events shape builds** (Therapist/Bargain) instead of pure coin-flips.

## Findings this pass
1. **[fixed] Engine↔GameState coupling.** `CombatManager` had started reading
   `GameState.card_cost` directly, breaking the pure-logic isolation that makes it
   unit-testable. Fixed: upgrades are now passed into `start_combat`; the manager
   owns `card_cost()`.
2. **Localization: strings are well-placed for it.** Content text funnels through a
   few choke points (`CardView` reads `card.title/description`; enemy/wizard/artifact/
   outfit displays read their data fields), so wrapping those plus the UI literals
   covers the game. This pass added DE/ES — `Loc` autoload + `loc_de.gd`/`loc_es.gd`,
   a language picker in Options, covering UI, content, combat HUD, banter, and log lines.
3. **Balance watch (not blocking):**
   - Ascension scaling is gentle (+8% HP/tier). Fine for now; revisit if high tiers
     feel trivial once players have full unlock pools.
   - `enrage` + multi-hit enemies (Gym Rat) can spike if the player relies on chip
     damage — intended, but worth watching with weak starter decks.
   - Three "Block 5" commons (kindle/shroud/composure) remain class-flavored dupes;
     acceptable (each class needs a basic guard) but a candidate for differentiation.
4. **Code health: good.** No TODO/FIXME debt; combat logic covered by 81 tests; UI is
   data-driven; the procedural art/audio pipeline scales. Main risk area is the
   breadth of hardcoded UI strings — addressed by routing them through `Loc.t()`.

## Suggested next (post-localization)
- Outfit-passive variety tied to the new statuses (only artifacts got them).
- A codex/bestiary screen (lots of content now, no in-game reference).
- Per-card stat upgrades (current Glow Up is cost-only).
