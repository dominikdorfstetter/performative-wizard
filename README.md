# Performative Wizard

A roguelike deckbuilder (à la *Slay the Spire*) where a wizard's power comes from
**swag** — the outfit you wear and the style ("Aura") you bank up mid-fight. Gen-Z
wizardry: you fight ordinary modern things turned hostile (an Angry Toaster, a
Possessed Router, The Algorithm) and win by serving looks.

**The hook:** a rival **Critic** shadows your whole run and grades every fight on
*how boldly you played your Aura* — then rewrites the road ahead (fight clean → VIP
rooms; flop → hecklers). Don't just win. **Win the room.** (See [`docs/USP.md`](docs/USP.md).)

## ⬇️ Download

**[Download for macOS (v1.0.0)](https://github.com/dominikdorfstetter/performative-wizard/releases/latest/download/PerformativeWizard.zip)** ·
[all releases](https://github.com/dominikdorfstetter/performative-wizard/releases)

Universal macOS app (arm64 + Intel). It's unsigned, so on first launch **right-click →
Open** (or System Settings → Privacy & Security → *Open Anyway*).

📄 **Design:** [`DESIGN.md`](DESIGN.md) (vision) · **Reviews & roadmap:** [`docs/`](docs/)

## Status

**Feature-complete roguelite.** Full run: main menu → class-select → dressing room →
**3-act branching map** (combat / elite / event / shop / rest / chest / boss) → ascension.

- **Content:** 41 cards, 24 enemy types (incl. **The Critic** & **The Algorithm** bosses),
  3 wizards, 19 outfits, 14 artifacts.
- **Wizards:** Vesper Vermillion (Hot Girl / fire), Morticia Graves (Goth Bestie / necro,
  summon-and-sacrifice), Chadwick Suave (the Rizzard / crit-on-Rizz).
- **The Critic (USP):** a named rival grades every fight S/A/B/C — computed primarily from
  your Aura play (peak reached, thresholds lit, a clean finisher cash-out) — shown **live**
  in combat and rewriting the next room (S → bonus gold; C → a heckler). Her **taste
  drifts**: spamming one winning style goes stale, so variety is the meta.
- **Progression:** wizards, cards, and relics unlock via lifetime Clout; **3 acts** with
  per-act scaling; an **ascension** (hard-mode) ladder banked on each clear.
- **Combat systems:** the banked-Aura economy (hoard vs. spend at thresholds 6/12/18) with
  a tiered lit/unlit meter; **finishers** that cash Aura out four different ways
  (Aura×3, spread, lifedrain, and the **Encore** that scales with time held in the
  spotlight); **Commit to the Bit** (bank past 24 to build an Encore, get *booed* if
  knocked out of the spotlight); a **tax** enemy verb that punishes hoarding; the **Feed**
  (a per-act Trend that re-prices Aura income); crit/luck, **Power** cards, and statuses —
  Roasted (burn), Cooked (vulnerable), Mid (weak), Jinxed, Exposed (frail), Toxic (poison),
  Rizz (strength), Goons (undead). Enemies multi-hit, heal, drain/tax Aura, **enrage**, and
  **summon adds**.
- **Presentation:** pixel battle scene with idle animation, projectiles, hit sparks,
  crits, screen shake, summoned-goon minions; 5 procedural biome backdrops; 5 synthesized
  drum-backed music tracks (per-encounter) + SFX.
- **Localization:** English / Deutsch / Español (switch in Options) — keeps the
  international Gen-Z slang, translates the rest.
- **Build:** universal macOS `.app` export. Combat engine covered by **152 headless tests**.

## Running

1. Install **Godot 4.4+** (developed on 4.6.3, GDScript): https://godotengine.org/download
2. Open this folder in Godot (import `project.godot`).
3. Press **Play** (F5). The console should print
   `[Database] loaded 41 cards, 19 outfits, 24 enemies, 3 wizards, 14 artifacts`.
4. Run the tests headless: `godot --headless scenes/test_combat.tscn` (expect `152 passed`).

## Layout

```
DESIGN.md            design vision (some sections predate the current build — see docs/)
docs/                living review + roadmap (USP, DESIGN_REVIEW, REVIEW_2, ROADMAP, ENEMY_REDESIGN)
project.godot        Godot config + autoloads (Loc, Database, SpriteBank, Audio, GameState)
scenes/              hub/ combat/ map/ nodes/ + tools/ (dev preview scenes) + test_combat
scripts/
  autoload/          Loc (i18n) · Database · SpriteBank (procedural art) · Audio (synth) · GameState
  combat/            Combatant · EffectResolver · CombatManager (pure logic) · combat_ui
  data/              CardData / OutfitData / EnemyData / WizardData / ArtifactData resources
  map/ run/ ui/      map generation, encounters, and all screen scripts
  tests/             combat_test.gd (81 checks)
data/
  cards/ enemies/ outfits/ wizards/ artifacts/   authored .tres content
builds/              exported macOS .app (gitignored)
```

## Roadmap

The original build's phases are shipped — see [`docs/ROADMAP.md`](docs/ROADMAP.md). The
game's unique selling proposition (**The Critic**) and its full P0–P4 build-out are
shipped too; the decision, rationale, and phase log live in [`docs/USP.md`](docs/USP.md).
Parked future ideas (codex/bestiary screen, per-card stat upgrades) are in
[`docs/REVIEW_2.md`](docs/REVIEW_2.md).
