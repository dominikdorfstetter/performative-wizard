# Performative Wizard

A roguelike deckbuilder (à la *Slay the Spire*) where a wizard's power comes from
**swag** — the outfit you wear and the style you build up mid-fight.

📄 **Design:** see [`DESIGN.md`](DESIGN.md) for the full design document.

## Status

**M3 — the wardrobe.** Full loop: class-select → **dressing room** (equip outfit pieces
filtered to your class) → 3-fight gauntlet → pick-a-card rewards. 12 outfit pieces inject
cards, add Swag income, and grant passives; the wardrobe is meta-persistent (saved to
disk, new pieces unlock by clearing runs). Combat engine covered by 28 headless tests.
Next: M4 (branching map, shops, rest, boss).

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
- **M4** branching map + shops + rest sites + boss
