# Performative Wizard

A roguelike deckbuilder (à la *Slay the Spire*) where a wizard's power comes from
**swag** — the outfit you wear and the style ("Aura") you bank up mid-fight. Gen-Z
wizardry: you fight ordinary modern things turned hostile (an Angry Toaster, a
Possessed Router, The Algorithm) and win by serving looks.

## ⬇️ Download

**[Download for macOS (v1.0.0)](https://github.com/dominikdorfstetter/performative-wizard/releases/latest/download/PerformativeWizard.zip)** ·
[all releases](https://github.com/dominikdorfstetter/performative-wizard/releases)

Universal macOS app (arm64 + Intel). It's unsigned, so on first launch **right-click →
Open** (or System Settings → Privacy & Security → *Open Anyway*).

📄 **Design:** [`DESIGN.md`](DESIGN.md) (vision) · **Reviews & roadmap:** [`docs/`](docs/)

## Status

**Feature-complete roguelite.** Full run: main menu → class-select → dressing room →
**3-act branching map** (combat / elite / event / shop / rest / chest / boss) → ascension.

- **Content:** 38 cards, 23 enemies + **2 bosses**, 3 wizards, 17 outfits, 14 artifacts.
- **Wizards:** Vesper Vermillion (Hot Girl / fire), Morticia Graves (Goth Bestie / necro,
  summon-and-sacrifice), Chadwick Suave (the Rizzard / crit-on-Rizz).
- **Progression:** wizards, cards, and relics unlock via lifetime Clout; **3 acts** with
  per-act scaling; an **ascension** (hard-mode) ladder banked on each clear.
- **Combat systems:** the banked-Aura economy (hoard vs. spend at thresholds 6/12/18),
  crit/luck, **Power** cards (persistent per-turn effects), and statuses — Roasted (burn),
  Cooked (vulnerable), Mid (weak), Jinxed, Exposed (frail), Toxic (poison), Rizz
  (strength), Goons (undead). Enemies multi-hit, heal, drain Aura, **enrage**, and
  **summon adds**.
- **Presentation:** pixel battle scene with idle animation, projectiles, hit sparks,
  crits, screen shake, summoned-goon minions; 5 procedural biome backdrops; 5 synthesized
  drum-backed music tracks (per-encounter) + SFX.
- **Localization:** English / Deutsch / Español (switch in Options) — keeps the
  international Gen-Z slang, translates the rest.
- **Build:** universal macOS `.app` export. Combat engine covered by **81 headless tests**.

## Running

1. Install **Godot 4.4+** (developed on 4.6.3, GDScript): https://godotengine.org/download
2. Open this folder in Godot (import `project.godot`).
3. Press **Play** (F5). The console should print
   `[Database] loaded 38 cards, 17 outfits, 23 enemies, 3 wizards, 14 artifacts`.
4. Run the tests headless: `godot --headless scenes/test_combat.tscn` (expect `81 passed`).

## Layout

```
DESIGN.md            design vision (some sections predate the current build — see docs/)
docs/                living review + roadmap (DESIGN_REVIEW, REVIEW_2, ROADMAP, ENEMY_REDESIGN)
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

All planned phases are shipped — see [`docs/ROADMAP.md`](docs/ROADMAP.md) for the checklist
and [`docs/REVIEW_2.md`](docs/REVIEW_2.md) for the latest design review. Future ideas
(codex/bestiary screen, per-card stat upgrades, outfit-passive variety) are parked there.
