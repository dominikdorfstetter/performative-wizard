# Performative Wizard

A roguelike deckbuilder (à la *Slay the Spire*) where a wizard's power comes from
**swag** — the outfit you wear and the style you build up mid-fight.

📄 **Design:** see [`DESIGN.md`](DESIGN.md) for the full design document.

## Status

**M4 + roguelite pass.** Full run: class-select → dressing room → **branching map**
(combat / elite / event / shop / rest / chest / boss) → boss. Multi-enemy encounters with
click-to-target and AoE, difficulty scaling with depth, a gold economy, shops, events,
chests, and run-scoped **artefacts** (relics). Meta progression: persistent wardrobe +
**Clout** currency. Procedural **pixel-art** enemy sprites; floating damage numbers. The
combat engine is covered by 34 headless tests. Content: 22 cards, 15 enemy types, 16
outfits, 11 artefacts, two named wizards (Vesper Vermillion & Morticia Graves) with
pixel-art portraits.

## Running

1. Install **Godot 4.4** (GDScript): https://godotengine.org/download
2. Open this folder in Godot (import `project.godot`).
3. Press **Play** (F5). You should see one card rendered, and the console should print:
   `[Database] loaded N cards, 1 outfits, 1 enemies`.

## Layout

```
DESIGN.md            full design doc + milestone plan (M0–M4)
project.godot        Godot config + autoloads (Database, GameState)
scenes/main.tscn     M0 entry scene (renders one card)
scripts/
  autoload/          Database (loads all data) + GameState (run + meta save)
  combat/            Combatant, EffectResolver, CombatManager (M0 shell)
  data/              CardData / OutfitData / EnemyData / StatusEffect resources
  main.gd            M0 entry script
data/
  cards/ outfits/ enemies/   authored .tres content
```

## Roadmap

- **M0** skeleton ✅ · **M1** playable Fire combat + Swag system ✅
- **M2** Necro + class-select + card-reward gauntlet ✅
- **M3** dressing room + meta-persistent wardrobe (cards/passives/drip) ✅
- **M4** branching map + shops + rest + events + chests + boss ✅
- **Roguelite pass** multi-enemy combat, artefacts, gold, Clout, pixel-art ✅
- **Next** Clout meta-shop, more cards/enemies/events, audio, balance tuning
