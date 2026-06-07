# Performative Wizard — Design Document

> A roguelike deckbuilder in the spirit of *Slay the Spire*, but the wizard's power
> comes from **swag**: the outfit you wear and the style you build mid-fight. You don't
> just cast spells — you put on a *performance*, and the better dressed and more
> committed the bit, the harder you hit.

Status: **Feature-complete roguelite** — data-driven Godot 4 project; combat engine
passing **81 headless tests**. Full loop: main menu → class-select → dressing room →
**3-act branching map** (Combat / Elite / Event / Shop / Rest / Chest / Boss) → ascension.
Last updated: 2026-06-06.

> **Note on this document.** The sections below were written as the original *vision/plan*
> (POC framing, "two wizards", a first-pass roster, an M0–M4 milestone plan). The shipped
> game has grown well past that — see the snapshot just below and the living docs in
> [`docs/`](docs/) (`REVIEW_2.md`, `ROADMAP.md`, `ENEMY_REDESIGN.md`) for the current state.
> The design *rationale* here (pillars, the Aura economy, the wardrobe system) is still the
> source of truth for *why* things are the way they are.

### Current snapshot (2026-06-06)
- **Content:** 49 cards, 24 enemy types + **2 bosses** (The Critic, The Algorithm), **3
  wizards** (Fire / Necro / Rizzard), 19 outfits, 14 artifacts.
- **USP — The Critic:** a rival grades every fight on how boldly you played your Aura and
  rewrites the run in response (live grade in combat; S → VIP room, C → heckler; her taste
  drifts so variety is the meta). Full rationale + build log in [`docs/USP.md`](docs/USP.md).
- **Progression:** wizards, cards, and relics unlock via lifetime **Clout**; **3 acts** with
  per-act scaling; an **ascension** hard-mode ladder banked on each clear.
- **Combat depth:** the banked-Aura economy (thresholds 6/12/18) with a tiered lit/unlit
  meter; **four finishers** (Aura×3 / spread / lifedrain / Encore); **Commit to the Bit**
  (a spotlight at 24 builds an Encore, falling out gets you *booed*); a **tax** verb that
  punishes hoarding; the **Feed** (per-act Aura-income Trend); crit/luck, **Power** cards
  (ritual / aura-engine / hive-mind / barrier), and a full status set — Roasted (burn),
  Cooked (vulnerable), Mid (weak), Jinxed, **Exposed** (frail), **Toxic** (poison ramp),
  Rizz (strength), Goons (undead). Enemies multi-hit, heal, drain/tax Aura, **enrage**, and
  **summon adds** mid-fight.
- **Presentation:** procedural pixel-art (`SpriteBank`) — varied enemy silhouettes, per-class
  wizards, summoned-goon minions, 5 biome backdrops; a pixel battle scene with idle bob,
  projectiles, hit sparks, crits, screen shake.
- **Audio:** 5 synthesized drum-backed music tracks selected per encounter, + SFX.
- **Localization:** English / Deutsch / Español (Options), keeping the international Gen-Z
  slang and translating the rest (`Loc` autoload + `loc_de.gd` / `loc_es.gd`).

### Implemented beyond the original plan
- **Multi-enemy encounters** with click-to-target and AoE cards; **enemy summoners**.
- **Run-scoped artefacts** (relics) + **meta unlocks** (wizards/cards/relics by Clout).
- **Procedural pixel-art + procedural audio** generated at runtime.
- **3-act runs + ascension** difficulty ladder (the original plan was "one act, POC").
- **Power cards** and second-tier statuses (frail, poison, enrage) past the first-pass spec.
- **Three wizards** (the doc's §7 still says "two"); the Rizzard adds a crit/Rizz playstyle.
- **Localization** (EN/DE/ES).

---

## 1. Elevator pitch

You are a **performative wizard** — and here's the secret: you have **no innate magic at
all. All power comes from the clothes.** You throw on a basic class robe (Fire or Necro),
raid your **wardrobe** for swaggier pieces, and the better dressed you are, the stronger
your spells. In a fight you keep building **Swag** — a resource that rises turn over turn
— toward a grand finale. Your foes? Ordinary things the world has hexed into monsters: a
furious housecat, a possessed wardrobe, a vengeful art critic. Win fights, look fabulous,
unlock more drip, go deeper.

### Setting & tone
Comedic-glam fantasy played straight-faced (which makes it funnier). The wizard is a
poseur whose power is 100% fashion; enemies are **mundane creatures and objects turned
magical** — a cat, a pigeon, a toaster. The wardrobe is **sorted by class**: pick Fire and
you browse the Fire rack.

## 2. Design pillars

1. **The clothes ARE the power.** The wizard has zero innate magic — every point of
   damage, Block, and Swag traces back to an equipped piece or a card it granted. Outfit
   (meta) and Swag (in-combat) are the same fantasy at two timescales. Everything ladders
   up to "dress better, perform better."
2. **The fight is an arc, not a flat exchange.** Banked Swag means fights *build* — a
   cold open, a rising act, a finale. Pacing is a mechanic.
3. **One real decision per turn, minimum.** The hoard-vs-spend Swag tension guarantees
   a meaningful choice every turn even with a simple hand.
4. **Readable like StS.** Intents, energy, block, keywords — we borrow the proven
   legibility and spend our novelty budget on Swag and wardrobe.

---

## 3. Gameplay loops

### Macro loop (a run)
```
HUB / DRESSING ROOM
  pick a wizard (Fire / Necro)
  equip an outfit from your owned wardrobe  ──► sets passives, Swag income, starter deck
        │
        ▼
RUN (branching map, one act for the POC)
  Combat ──► card reward (+ gold)
  Elite  ──► better reward, sometimes an OUTFIT PIECE (unlocks forever)
  Event  ──► risk/reward choices
  Shop   ──► buy cards / remove cards / buy outfit pieces
  Rest   ──► heal OR upgrade a card
        │
        ▼
  BOSS ──► win = run cleared, big unlocks; lose = run ends
        │
        ▼
back to HUB with any newly-unlocked outfit pieces kept permanently
```

- **In-run progression** = your **deck** (card rewards, upgrades, removals) + gold.
  Resets every run. This is the roguelike tension.
- **Meta progression** = your **wardrobe** (outfit pieces unlock permanently). This is
  the long game and the reason to come back.
- The outfit is chosen at the hub and **locked for the duration of a run** (keeps each
  run's identity stable). Pieces *found* mid-run unlock for *future* runs.
  - *Open question (§13):* allow swapping outfit at Rest sites?

### Micro loop (a combat turn)
```
Start of turn:  +3 Energy · draw to 5 · gain Swag from outfit drip · tick statuses
Your turn:      play cards (spend Energy; some generate/spend Swag) until done
                Swag thresholds apply passively while your pool stays high
End of turn:    discard hand · Block resets to 0 · Swag PERSISTS
Enemy turn:     enemy resolves its telegraphed intent · DoTs tick
```

---

## 4. Combat system

- **Player HP:** Fire 72 / Necro 68 (squishier than a warrior; they win with tempo).
- **Energy:** **3 per turn, flat.** Does not carry over. Outfit pieces can raise the
  baseline (e.g. *Robe of Excess* → 4/turn).
- **Draw:** 5 cards at start of turn. **Hand discards at end of turn.**
- **Block:** absorbs damage; **resets to 0 each turn** (StS standard).
- **Intents:** enemies telegraph their next action (attack value, block, buff, debuff).

### Core keywords (shared)
| Keyword | Meaning |
|---|---|
| **Block** | Temporary HP for this turn; resets EOT. |
| **Strength** | +X damage to all your attacks (persists in combat). |
| **Vulnerable** | Target takes +50% damage while it lasts (counts down). |
| **Weak** | Target deals −25% damage while it lasts (counts down). |
| **Pose** | Card keyword: "gain N Swag." The basic Swag generator. |

---

## 5. The Swag economy (the signature system)

Swag is a **second resource alongside Energy**, with one defining property: **it is
banked — it persists and accumulates across the entire fight and does NOT reset each
turn.** You start each combat at 0 Swag (outfit can seed a few).

### Where Swag comes from
- **Outfit drip rating:** your equipped outfit emits a passive `+drip` Swag at the start
  of each of your turns (a baseline performance income).
- **Pose cards:** cards with the *Pose* keyword grant Swag on play.
- **Wizard kits:** Fire's flashy multi-hits and Necro's grim spectacle both grant Swag.

### What Swag does — the dual payoff (hoard vs. spend)
This is the heart of the game. Swag pays off **two competing ways**:

**A) Thresholds (passive, while your pool stays at/above the line):**
| Pool | Bonus (first-pass, tunable) |
|---|---|
| ≥ 5 Swag | All spells deal **+2 damage** |
| ≥ 10 Swag | **Draw +1** card each turn |
| ≥ 15 Swag | Your **first spell each turn pierces Block** |

**B) Finishers (cards that consume Swag for a burst):**
- `Grand Finale` — Spend ALL Swag. Deal **Swag × 3** damage to one enemy.
- `Encore` — Spend 6 Swag: replay the last spell you cast this turn.

> **The tension:** spending Swag on a finisher drops you below your thresholds, turning
> off your passive bonuses. Do you cash out now, or keep building the bit? Every turn
> after ~turn 2 asks this question. That's the whole game in one decision.

No hard cap on the pool (soft display cap 99). Swag is lost only by spending it or by
combat ending.

---

## 6. Wardrobe system

The wardrobe is the **meta** layer and the *only* source of power. You own a growing
collection of outfit pieces and equip one piece per slot before a run. It is **sorted by
class** (a Fire rack, a Necro rack); your chosen class also fixes a **basic robe set** —
the cheapest possible outfit and the only kit you own at the very start.

### Slots (5)
`Hat` · `Robe` · `Staff` · `Boots` · `Trinket`

### Anatomy of an outfit piece
```
name:          "Char Wand"
slot:          Staff
element:       Fire        (Fire / Necro / Neutral)
rarity:        Common      (Common / Rare / Legendary)
drip:          2           (passive Swag/turn it contributes)
passive:       "Your Burn applies +1 stack."
injected_cards: [ "Flame Lash" x2 ]   (added to your combat deck this run)
```

Each piece does **both**: a **passive** modifier *and* **injects cards** into your deck.
Your full run deck = (wizard's fixed starter core) + (cards injected by all 5 equipped
pieces) + (cards gained during the run). Total outfit drip across 5 slots = your
baseline Swag income.

### How pieces are earned (meta-persistence)
- Drop from **Elites** and the **Boss**.
- Bought in **Shops** with run gold.
- Granted by certain **Events**.
- Once obtained, a piece is **permanently unlocked** in the dressing room — kept across
  all future runs, even after death.

### Sample pieces
| Piece | Slot | Elem | Drip | Passive | Injects |
|---|---|---|---|---|---|
| Apprentice Hat | Hat | Neutral | 1 | — (starter) | — |
| Spite Hat | Hat | Necro | 2 | Whenever a Minion dies, gain 1 Swag. | Hex ×1 |
| Drip Robe | Robe | Neutral | 2 | Start combat with 5 Block. | Strike-a-Pose ×1 |
| Robe of Excess | Robe | Fire | 1 | +1 Energy per turn. | — |
| Char Wand | Staff | Fire | 2 | Burn applies +1 stack. | Flame Lash ×2 |
| Bone Scepter | Staff | Necro | 2 | Summons summon +1 Undead. | Raise Dead ×1 |
| Smolder Boots | Boots | Fire | 1 | First spell each turn deals +3. | — |
| Catwalk Heels | Boots | Neutral | 3 | At ≥10 Swag, also gain 1 Strength/turn. | Sashay ×1 |
| Crowd-Pleaser Trinket | Trinket | Neutral | 2 | Pose cards grant +1 Swag. | — |

---

## 7. The two wizards

A "wizard" is really a **base robe set** — the only kit you own at the very start. It
defines your class rack in the wardrobe and your fixed starter-core cards. Everything
beyond it is drip you earn. The wizard is powerless out of costume; the costume is the
character.

### 🔥 Fire — the Pyromancer · *"Ignite & Escalate"*
- **HP 72.** Aggressive tempo; damage-over-time that snowballs; flashy spells that pay
  Swag for showmanship.
- **Signature keyword — Burn(X):** at the **start of the enemy's turn** it takes X
  damage, then X is reduced by 1. Stacks add up; the *Char Wand* and similar make stacks
  hit harder or decay slower.
- **Swag tie-in:** the more theatrical the spell (multi-hits, big ignitions), the more
  Swag it poses. Fire wants to stay above thresholds AND has strong finishers.

**Fire starter core (10 cards):**
| Card | Cost | Type | Effect |
|---|---|---|---|
| Ember ×4 | 1 | Attack | Deal 6. |
| Kindle ×3 | 1 | Skill | Gain 5 Block. |
| Ignite ×2 | 1 | Attack | Apply 3 Burn. **Pose: gain 1 Swag.** |
| Flashfire ×1 | 2 | Attack | Deal 8 to all enemies. **Pose: gain 2 Swag.** |

*(Injected by outfit: Flame Lash — 1 energy, deal 4, if target has Burn deal 4 more.)*
*Finisher available via cards/shops: Grand Finale.*

### 💀 Necro — the Necromancer · *"Summon & Sacrifice"*
- **HP 68.** Builds a board of Undead that block and chip, then sacrifices them for
  bursts and lifedrain. Grim spectacle = Swag.
- **Signature keyword — Undead(X):** an abstract minion counter. At the **end of your
  turn**, each Undead deals 2 to a random enemy. Undead also soak the first hits against
  you (each absorbs one instance, capped). Many cards **Sacrifice** Undead for effects.
- **Swag tie-in:** summoning and sacrificing are crowd-pleasers — both pose Swag. Necro
  leans toward threshold-hoarding (a slow, building dread).

**Necro starter core (10 cards):**
| Card | Cost | Type | Effect |
|---|---|---|---|
| Bone Dart ×3 | 1 | Attack | Deal 5. |
| Shroud ×3 | 1 | Skill | Gain 5 Block. |
| Raise Dead ×2 | 1 | Skill | Summon 1 Undead. **Pose: gain 1 Swag.** |
| Drain ×1 | 1 | Attack | Deal 4, heal 3. |
| Macabre Bow ×1 | 2 | Skill | **Sacrifice** an Undead: deal 7 + gain 3 Swag. |

*(Injected by outfit: Hex — 0 energy, apply 1 Vulnerable, Pose: gain 1 Swag.)*

> **Minions in the POC** are modeled as a simple **stack counter** (Undead = N), not
> separate battlefield entities, to keep combat tractable. Full minion entities with
> their own HP/intents are a post-POC stretch goal (§13).

---

## 8. Enemies (first-pass roster for the POC)

All foes are **mundane things hexed into monsters** — the joke is that a glam wizard is
fighting a housecat to the death.

| Enemy | HP | Intent pattern | Note |
|---|---|---|---|
| Hexed Housecat | 28 | Scratch 6 → Hiss (Weak 1) → Pounce 9 | Tutorial-tier. **The POC enemy.** |
| Disgruntled Pigeon | 34 | Peck 7 → Flap (Block 6) → Dive-bomb 11 | Punishes greedy hoarding. |
| Possessed Wardrobe (Elite) | 60 | Slam 8 / Maul 14 / Swallow (you discard 1) | A literal angry closet — drops an outfit piece. |
| The Critic (Boss) | 120 | Multi-phase: scores your outfit, punishes low-Swag turns | A mundane art critic turned couture demon. |

Enemy data is fully data-driven (HP + an intent script). Intents are deterministic
patterns for the POC (no RNG AI yet).

---

## 9. Run structure (map)

POC = **one act**, StS-style branching node map, ~12–15 nodes.

- Node types: `Combat` · `Elite` · `Event (?)` · `Shop` · `Rest` · `Boss`.
- Branching paths; you pick your route. Boss is the act's terminal node.
- **Rest:** heal 30% max HP **or** upgrade a card.
- **Shop:** buy cards, remove a card (escalating cost), buy an outfit piece if offered.
- **Event:** 2–3 hand-written narrative choices with risk/reward (a few for the POC).

---

## 10. First-pass numbers (all tunable)

| Param | Value |
|---|---|
| Starting Energy | 3/turn |
| Cards drawn | 5/turn |
| Starting hand discard | yes, EOT |
| Block | resets EOT |
| Starting Swag | 0 (+ outfit seed if any) |
| Swag thresholds | 5 / 10 / 15 |
| Player HP | Fire 72 · Necro 68 |
| Starter deck size | 10 core + outfit injections |
| Act length | ~12–15 nodes |

---

## 11. Technical design (Godot)

- **Engine:** Godot **4.4** (4.3+ fine), **GDScript**. *(Godot is not currently installed
  on this machine — install before scaffolding; see §14.)*
- **Philosophy:** **data-driven**. Cards, outfit pieces, enemies, and statuses are
  `Resource` subclasses authored as `.tres` files. Card behavior is a list of **effect
  data**, resolved by one `EffectResolver` — no per-card scripts. This keeps content
  cheap to add and trivial to balance.

### Autoloads (singletons)
- `GameState` — current run (deck, HP, gold, map position) + meta (wardrobe unlocks).
  Persists meta to `user://save.json`.
- `Database` — loads all card/outfit/enemy `.tres` at boot, lookup by id.

### Combat architecture
- `CombatManager` — finite state machine: `START → PLAYER_TURN → RESOLVING → ENEMY_TURN → … → WIN/LOSE`.
- `Combatant` — shared base for player & enemies (HP, Block, statuses).
- `EffectResolver` — applies a card's/enemy-intent's effect list to combatants;
  centralizes damage, block, status application, Swag changes, threshold checks.
- `StatusEffect` resources: Burn, Strength, Vulnerable, Weak, Undead, etc.

### Data schemas (sketch)
```gdscript
class_name CardData extends Resource
@export var id: StringName
@export var title: String
@export var cost: int
@export_enum("Attack","Skill","Power") var type: String
@export var effects: Array[Dictionary]   # e.g. {op="damage", amount=6, target="enemy"}
@export var swag_gain: int                # Pose value
@export var rarity: String

class_name OutfitData extends Resource
@export var id: StringName
@export_enum("Hat","Robe","Staff","Boots","Trinket") var slot: String
@export_enum("Fire","Necro","Neutral") var element: String
@export var drip: int
@export var passive_id: StringName        # resolved to a hook
@export var injected_cards: Array[StringName]

class_name EnemyData extends Resource
@export var id: StringName
@export var max_hp: int
@export var intents: Array[Dictionary]    # ordered pattern of {op, amount, ...}
```

### Project structure
```
project.godot
/scenes/
  main.tscn
  hub/wardrobe.tscn
  map/map.tscn  map/map_node.tscn
  combat/combat.tscn  combat/card.tscn  combat/enemy.tscn
/scripts/
  autoload/game_state.gd  autoload/database.gd
  combat/combat_manager.gd  combat/effect_resolver.gd  combat/combatant.gd
  data/card_data.gd  data/outfit_data.gd  data/enemy_data.gd  data/status_effect.gd
/data/
  cards/*.tres  outfits/*.tres  enemies/*.tres
/assets/   (placeholder art: colored panels + text first)
```

---

## 12. POC milestone plan (de-risking the ambitious scope)

You chose the full run + map. To avoid the classic deckbuilder trap of building 12
systems and having nothing playable, we build **outward from a single combat** so there
is always a thing you can play:

- **M0 — Skeleton.** Godot project, autoloads, data schemas, one card renders on screen,
  empty combat scene. *Deliverable: it boots.*
- **M1 — THE HEARTBEAT (core POC).** One full combat: Fire wizard, 10-card starter deck,
  draw/play/discard, 3 Energy, the **full Swag system** (drip, Pose, 3 thresholds, 1
  finisher), one enemy with intents, Block, Burn, win/lose screens.
  *Deliverable: a fight that's actually fun. If the Swag tension doesn't feel good here,
  we fix the design before building anything else.*
- **M2 — Second wizard + reward.** Necro with Undead/Sacrifice; a second enemy; a card
  reward screen after victory. *Deliverable: deckbuilding begins.*
- **M3 — Wardrobe + meta.** Dressing-room hub, save/load of unlocks, 2–3 pieces per slot
  that inject cards and apply passives, equip-before-run flow.
  *Deliverable: the swag meta exists.*
- **M4 — The run.** Branching map, Rest, Shop, one Event, the Boss. Wire it into a
  full hub→run→boss→hub loop. *Deliverable: a complete roguelike slice.*

Each milestone is independently playable. We can stop, playtest, and re-tune at any one.

---

## 13. Open questions / decisions still to make

1. **Swag seeding:** should any outfit *start* you with Swag, or is income-only cleaner?
2. **Rest-site outfit swapping:** keep outfit locked per run, or let Rest sites re-dress?
3. **Threshold numbers & effects:** are 5/10/15 the right lines? Are the bonuses too
   strong (snowbally) or too weak (ignorable)? → tune in M1.
4. **Finisher density:** how many finisher cards should a deck realistically hold? Too
   many = always cashing out; too few = thresholds never threatened.
5. **Undead model:** stack-counter (POC) vs. full minion entities (later) — confirm
   stack-counter is acceptable for the POC feel.
6. **Act count:** one act for POC; 3 acts for v1?
7. **Potions / consumables:** in or out of the POC? (Leaning out.)
8. **Art direction:** placeholder-first, but what's the target vibe — campy drag-glam,
   gothic haute couture, vaporwave? Affects card frame & UI design later.

## 14. Risks

- **Scope (highest).** Full run = many systems. *Mitigation:* the M0–M4 ladder; we don't
  start M4 until M1's combat is fun.
- **Swag balance.** Two interacting payoffs (thresholds + finishers) can degenerate
  (always hoard, or always dump). *Mitigation:* M1 exists specifically to tune this.
- **Meta power creep.** Permanent wardrobe unlocks can trivialize runs. *Mitigation:*
  scale enemy difficulty to total drip / introduce ascension-style modifiers later.
- **Godot not installed.** Blocks scaffolding. *Mitigation:* install Godot 4.4 first.

---

## 15. The pitch in one line
*Slay the Spire, but you're a wizard putting on the performance of your afterlife — and
the better the drip and the bigger the build-up, the more devastating the finale.*
