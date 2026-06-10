# Contributing to Performative Wizards

Thanks for wanting to help! This page is short on ceremony and long on the
project-specific rules that will save you a rejected review.

## Ground rules

- **License:** the game is [AGPL-3.0](LICENSE). By submitting a pull request
  you agree that your contribution is licensed under AGPL-3.0 too. Don't
  submit code or assets you don't have the right to license that way (no
  copy-pasted proprietary code, no third-party art/fonts/sounds without an
  AGPL-compatible license and a `THIRDPARTY.txt` entry).
- **Be kind.** Reviews critique code, not people. The Critic is the only one
  allowed to be mean here, and she's fictional.
- **Talk first for big things.** Open a
  [GitHub issue](https://github.com/dominikdorfstetter/performative-wizard/issues)
  before building a feature, new mechanic, or balance overhaul — design
  direction is curated and PRs that fight it won't merge, however good the code.

## Getting set up

1. Install **Godot 4.6.x** (the project is developed on 4.6.3, GDScript only):
   https://godotengine.org/download
2. Clone, then open the folder in Godot (it imports `project.godot`).
3. Press **Play** (F5). The console should print a `[Database] loaded …` line
   listing cards/outfits/enemies/wizards/artifacts.

There are no external dependencies: all art is generated procedurally by
`SpriteBank`, all audio is synthesized by `Audio`, and the UI is built in
code (almost no `.tscn` layout).

## Running the tests (required before every PR)

```sh
PW_NO_SAVE=1 godot --headless scenes/test_combat.tscn
```

Expect the final line to read `=== result: N passed, 0 failed ===`. CI runs
exactly this on every push and pull request, and `main` requires it green.

**Always set `PW_NO_SAVE=1`** when running tests or dev tools — it stops them
from overwriting your real save file. Tests must never read or write
`user://save.json`; if you need to test persistence, round-trip the payload
dicts in memory (see the run-snapshot and meta-save tests in
`scripts/tests/combat_test.gd`).

If you touch combat math, also sanity-check the balance sim:

```sh
PW_NO_SAVE=1 godot --headless scenes/balance_sim.tscn
```

To eyeball every screen without clicking through a run:

```sh
PW_NO_SAVE=1 godot scenes/tools/audit_preview.tscn   # writes /tmp/a_*.png
```

(Run it with the window visible and nothing covering it — occluded windows
capture stale frames.)

## The localization rule (the #1 review rejection)

`Loc.t()` is an **exact-match dictionary lookup on the English source string**
with passthrough. That means:

- **Every player-facing English string you add or change must be added/renamed
  in BOTH** `scripts/autoload/loc_de.gd` **and** `scripts/autoload/loc_es.gd`.
  One English edit = three file edits, always.
- Duplicate dictionary keys are **parse errors** in GDScript and a broken loc
  table takes the whole `Loc` autoload down — grep for your key before adding it.
- Format strings translate the template, then apply args:
  `Loc.t("Deal %d damage.") % dmg` — never bake numbers into the source string.
- The test suite asserts loc coverage for the teaching layer and UI chrome;
  add your new keys to those lists when you extend covered surfaces.

## Fonts & glyphs

The bundled fonts have **no emoji or dingbat coverage**:

- **Jersey 20** — default UI font. **Pixelify Sans** — display titles only
  (`NodeUI.DISPLAY_FONT`); its digit "5" reads as "S", so never use it for numbers.
- Never put `→ ✦ ● ○ ▼ ✕ ⚙ ▶ ↻ ✓ ≥ −` (or any emoji) in player-facing
  strings — they render as tofu. Allowed: `— · ×`. Icons come from
  `SpriteBank.icon_texture()`, not Unicode.

## Code style

- Match the file you're in: tabs, `snake_case`, typed GDScript
  (`var x := 0`, typed params/returns) and `##` doc comments on classes/functions.
- Combat logic lives in `scripts/combat/` and must stay **UI-free and
  synchronous by default** (`CombatManager.step_delay = 0.0` means no awaits
  execute) — the headless tests and the balance sim depend on that contract.
- Screens are built in code via `NodeUI` helpers; reuse `NodeUI.item_reveal`,
  `TipIcon`, etc. rather than inventing new panel styles.
- Data content (cards/enemies/outfits/wizards/artifacts) is authored as
  `.tres` resources under `data/`.

## Branch & PR flow

1. Fork (or branch, if you have access) off **`main`** — `main` is protected:
   no direct pushes, PRs only, tests must pass.
2. One topic per PR, with tests for any logic you add. Balance changes need a
   before/after note from the balance sim in the PR description.
3. Write commit messages in the imperative ("fix X", "add Y"); explain *why*
   in the body if it isn't obvious.
4. Player-facing changes should include a screenshot (or `/tmp/a_*.png` from
   the audit tool) in the PR.

## Reporting bugs

Use [GitHub issues](https://github.com/dominikdorfstetter/performative-wizard/issues)
with: platform (web/macOS), build version (bottom-left of the main menu),
what you did, what happened, and what you expected. If the run is alive, a
copy of your save (`user://save.json` — on macOS that's
`~/Library/Application Support/Godot/app_userdata/Performative Wizards/`)
makes things much easier to reproduce.
