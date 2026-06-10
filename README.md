# Performative Wizards

A roguelike deckbuilder (à la *Slay the Spire*) where a wizard's power comes from
**swag** — the outfit you wear and the style ("Aura") you bank up mid-fight. Gen-Z
wizardry: you fight ordinary modern things turned hostile (an Angry Toaster, a
Possessed Router, The Algorithm) and win by serving looks.

**The hook:** a rival **Critic** shadows your whole run and grades every fight on
*how boldly you played your Aura* — then rewrites the road ahead (fight clean → VIP
rooms; flop → hecklers). Don't just win. **Win the room.** (See [`docs/USP.md`](docs/USP.md).)

## ⬇️ Play the demo

**Web (itch.io):** plays in the browser — link goes live with the demo release.
**macOS:** **[latest release](https://github.com/dominikdorfstetter/performative-wizard/releases)**
(universal arm64 + Intel zip).

The macOS app is **ad-hoc signed**: on first launch macOS says it "could not
verify" the app — open **System Settings → Privacy & Security** and click
**Open Anyway** (macOS 15+; on 14 and older, right-click → Open also works).
A README.txt with these steps ships inside the zip.

📄 **Design:** [`DESIGN.md`](DESIGN.md) (vision) · **Reviews & roadmap:** [`docs/`](docs/)

## Status

**Feature-complete roguelite.** Full run: main menu → class-select → dressing room →
**3-act branching map** (combat / elite / event / shop / rest / chest / boss) → ascension.

- **Content:** 58 cards, 24 enemy types (incl. **The Critic** & **The Algorithm** bosses),
  3 wizards, 19 outfits, 14 artifacts, 11 events.
- **Wizards:** Vesper Vermillion (It Girl / fire), Morticia Graves (Goth Bestie / necro,
  summon-and-sacrifice), Chadwick Suave (the Rizzard / crit-on-Rizz).
- **Builds:** vanilla StS-style starters + **two distinct archetypes per wizard** (Fire:
  Slow Roast / Go Viral · Necro: Sacrifice / Swarm · Rizz: Crit Storm / Rizz Ramp), with a
  **Common / Rare / Epic / Legendary** ladder and **per-wizard progressive unlocks**; reward
  offers bias toward your emerging build. See [`docs/ARCHETYPES.md`](docs/ARCHETYPES.md).
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
  (a per-act Trend that re-prices Aura income); crit/luck, **Power** cards, draw-pile/discard counters with peek/recycle/retain
  manipulation cards, two-flavour card upgrades (cheaper OR harder-hitting), and statuses —
  Roasted (burn), Cooked (vulnerable), Mid (weak), Jinxed, Exposed (frail), Toxic (poison),
  Rizz (strength), Goons (undead). Enemies multi-hit, heal, drain/tax Aura, **enrage**, and
  **summon adds**.
- **Presentation:** pixel battle scene with idle animation, projectiles, hit sparks,
  crits, screen shake, summoned-goon minions; 5 procedural biome backdrops; 5 synthesized
  drum-backed music tracks (per-encounter, with per-act tempo/key variants) + SFX.
- **Player-friendly demo build:** quit-safe **run saves** (checkpoint at every map
  entry, "Resume Run" on the menu), a one-time **first-fight tutorial**, Esc pause
  overlay with abandon-run, sequenced enemy turns with per-attacker telegraphs,
  run-end screens that pay out Clout/unlock progress, scene fades + music crossfades,
  volume sliders and a screen-shake/flash accessibility toggle.
- **Localization:** English / Deutsch / Español (auto-detected on first boot,
  switchable in Options) — keeps the international Gen-Z slang, translates the rest.
- **Build:** macOS `.app` (ad-hoc signed) + itch-ready web export, both branded
  (custom icon/boot splash) and versioned. Combat engine covered by **250 headless
  tests** (run on every push via GitHub Actions).

## Running

1. Install **Godot 4.4+** (developed on 4.6.3, GDScript): https://godotengine.org/download
2. Open this folder in Godot (import `project.godot`).
3. Press **Play** (F5). The console should print
   `[Database] loaded 58 cards, 19 outfits, 24 enemies, 3 wizards, 14 artifacts`.
4. Run the tests headless: `godot --headless scenes/test_combat.tscn` (expect `250 passed, 0 failed`).
   Set `PW_NO_SAVE=1` when running tools/tests so they never touch your real save.

## Layout

```
DESIGN.md            design vision (some sections predate the current build — see docs/)
docs/                living review + roadmap (USP, ARCHETYPES, DESIGN_REVIEW, REVIEW_2, ROADMAP, ENEMY_REDESIGN)
project.godot        Godot config + autoloads (Loc, Database, SpriteBank, Audio, GameState, Fader)
scenes/              hub/ combat/ map/ nodes/ + tools/ (dev preview scenes) + test_combat
scripts/
  autoload/          Loc (i18n) · Database · SpriteBank (procedural art) · Audio (synth) · GameState
  combat/            Combatant · EffectResolver · CombatManager (pure logic) · combat_ui
  data/              CardData / OutfitData / EnemyData / WizardData / ArtifactData resources
  map/ run/ ui/      map generation, encounters, and all screen scripts
  tests/             combat_test.gd (250 checks) · balance_sim.gd (headless balance bot)
data/
  cards/ enemies/ outfits/ wizards/ artifacts/   authored .tres content
builds/              exported macOS .app (gitignored)
```

## Releasing

See [`RELEASE.md`](RELEASE.md) for the cut-a-build checklist (version bumps, ad-hoc
signing verification, smoke test, itch upload) and [`docs/DEMO_RELEASE.md`](docs/DEMO_RELEASE.md)
for the demo plan this build implements. `LICENSE` (AGPL-3.0) and
`THIRDPARTY.txt` (Godot + font notices) must ship with every build.

## License & contributing

Performative Wizards is **free software** under the
[GNU AGPL-3.0](LICENSE) — you may play, study, modify, and redistribute it,
provided derivatives (including network-hosted ones) stay AGPL and publish
their source. Third-party components (Godot Engine, the bundled fonts) keep
their own licenses — see [`THIRDPARTY.txt`](THIRDPARTY.txt).

Want to help? Read [`CONTRIBUTING.md`](CONTRIBUTING.md) — it covers setup,
the test suite, and the project's localization/font rules. Bugs and ideas go
to [GitHub issues](https://github.com/dominikdorfstetter/performative-wizard/issues).

## Roadmap

The original build's phases are shipped — see [`docs/ROADMAP.md`](docs/ROADMAP.md). The
game's unique selling proposition (**The Critic**) and its full P0–P4 build-out are
shipped too; the decision, rationale, and phase log live in [`docs/USP.md`](docs/USP.md).
Parked future ideas (codex/bestiary screen, per-card stat upgrades) are in
[`docs/REVIEW_2.md`](docs/REVIEW_2.md).
