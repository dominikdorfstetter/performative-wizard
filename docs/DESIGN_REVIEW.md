# Performative Wizard — Design Review (2026-06-06)

A critical pass over the current build from a game-designer's seat. Grounded in
the actual data: **34 cards, 19 enemies (+goon), 3 wizards, 17 outfits, 12 artifacts,
1 boss, a single 10-row act.** Companion to `ROADMAP.md` and `ENEMY_REDESIGN.md`.

## TL;DR
The **core is genuinely good** — the banked-Aura economy (hoard vs. spend at
thresholds 6/12/18) and outfit-as-power are a real identity. What's thin:
**enemy design is shallow and partly off-theme, progression has no unlock arc,
the run is one short act, and a third of the card pool is interchangeable filler.**

---

## 1. Enemies — shallow patterns, inconsistent theme

### Theme fit (the user's complaint, and it's correct)
Premise: *you fight ordinary modern things turned magical/hostile, with an
internet/Gen-Z twist.* Most roster fits beautifully — Unhinged Housecat, Angry
Toaster, Rabid Roomba, Ring-Light Wraith, Hater in the Replies, Cursed Mirror,
Possessed Mannequin. **The lazy ones break the spell:**

| Enemy | Problem |
|---|---|
| `goblin_gremlin` "Goblin Gremlin" | generic high-fantasy goblin, off-theme |
| `clout_goblin` "Clout Goblin" | another goblin; shares 👺 with above |
| `gargoyle_cherub` "Gargoyle Cherub" | generic fantasy gargoyle; shares 🗿 with the gnome |

Plus **emoji collisions** (🗿 gnome+gargoyle, 👺 ×2) read as placeholder art.

### Attack patterns are samey
Most enemies are a 3-beat loop of `attack / weak / attack` or `block / attack /
attack`. Concretely:
- **Near-duplicates:** alley_cat ≈ goblin_gremlin ≈ sock_puppet (atk/weak/atk).
- **rabid_roomba is `5/5/5`** — zero telegraph variety, the dullest possible pattern.
- **Elites are just stat blocks** — possessed_wardrobe / taxidermy_owl /
  gargoyle_cherub have no special elite *mechanic*, only bigger numbers.
- **The one boss (the_critic)** is a flat 6-intent loop — no phases, no signature.

### Mechanical gaps (the engine only does 5 enemy verbs)
Supported intents: `attack, block, apply_status, buff, drain_swag`. Missing the
staples that make fights *read differently*:
- multi-hit (chip through block), heal/lifedrain, **summon adds**, retaliate/thorns,
  ramping attackers, "enrage at low HP", buff/shield *other* enemies, card-disruption
  (the theme begs for "steals your drip"), and a unique **`frail`** (reduce block gained).

**Verdict:** enemies are the weakest pillar. Fixing theme + adding 4–5 verbs +
real elite/boss mechanics is the highest-leverage work in the game.

---

## 2. Progression — no unlock arc

- **All 3 wizards are available from turn one** (`class_select` hardcodes
  `[fire, necro, rizz]`). There is no "unlock the next class" carrot — the single
  biggest missing roguelite hook.
- **No card/relic unlocking.** Every card in a wizard's pool can appear immediately;
  the meta never *expands* your options, it only buys outfits.
- **One act, one boss, ~10 nodes** → a run is short and always ends the same way.
  No Act 2/3, no escalating bosses, no ascension/difficulty ladder.
- **Meta is a single sink:** Clout → outfits. No challenge modifiers, no mastery,
  no daily/seed, no run history.

What *works*: Clout→Boutique is a clean sink; outfits carrying passives + injected
cards is a strong identity; artifacts add per-run variety.

---

## 3. Cards — strong identity, ~1/3 filler

34 cards, but variety is inflated by duplicates and stat-stick commons:
- **Functional dupes:** `pickup_line` == `flex` (self +2 Str); composure/kindle/
  shroud all "Block 5"; ember(6)/finger_guns(5)/bone_dart(5)/flame_lash(4)/
  hot_streak(5) are the same "deal X" card.
- **`Power` card type is declared but barely used** — persistent powers are a
  deckbuilder staple and a natural home for the "drip buff" fantasy.
- **Thin archetypes:** almost no card draw engines, energy ramp, exhaust/one-shot
  bombs, X-cost, multi-hit, or scaling payoffs beyond Burn.
- **Rizz pool is only 9 cards** (2 of them neutral) → least build variety.

---

## 4. What to protect
The Aura economy, the threshold tension, outfit-as-power, the Gen-Z voice, and the
procedural pixel-art pipeline are all assets. Every change below should *feed* the
Aura decision, not bypass it.
