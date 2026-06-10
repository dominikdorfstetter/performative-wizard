# Release checklist — Performative Wizard demo

Every public build follows this list top to bottom. The v1.0.0 incident (the
README's download link served a build with the Block bug for days) happened
because nothing forced "re-export from clean HEAD".

## 1. Cut from clean HEAD
- [ ] `git status` clean, on the release branch/tag commit.
- [ ] `godot --headless scenes/test_combat.tscn` → `… passed, 0 failed`.
- [ ] Version bumped in **three** places and matching:
      `project.godot` → `application/config/version` (e.g. `1.1.0-demo`),
      `export_presets.cfg` → macOS `short_version` + `version`,
      the git tag you're about to create.

## 2. Export (both targets, same commit)
- [ ] Editor → Export → **macOS** → `builds/PerformativeWizard.zip`
      (preset is ad-hoc signed; never set codesign back to "None" — that
      ships a broken template signature Gatekeeper calls "damaged").
- [ ] Editor → Export → **Web** → `builds/web/` (threads stay OFF — the
      itch embed needs no COOP/COEP headers that way).
- [ ] Repack the macOS zip to include `dist/macos-README.txt` (rename to
      `README.txt`) and `THIRDPARTY.txt` next to the .app.

## 3. Smoke test (15 minutes, non-negotiable)
- [ ] macOS: `codesign --verify --deep --strict "Performative Wizard.app"`
      and `spctl -a -t exec` → expect "adhoc"-signed rejection, NOT "damaged".
- [ ] Fresh profile (move save.json away): boot → first-fight tutorial fires,
      menu shows the right version in the footer.
- [ ] Play one fight per wizard (unlock via a quick run or a copied save).
- [ ] Quit mid-run → relaunch → "Resume Run (Act N)" restores the map.
- [ ] Options: language DE/ES switch, volumes, shake toggle, fullscreen
      persists across relaunch.
- [ ] Web: upload `builds/web/` to the **draft** itch page → boots in
      Chrome + Safari, audio starts after the itch "Run game" click, no Exit
      button shown, fonts crisp (no tofu anywhere).
- [ ] Esc pause works on map + combat; Abandon Run banks Clout.

## 4. Publish
- [ ] GitHub: tag + release, upload the macOS zip, update the README link.
- [ ] itch: replace the web build + macOS zip, page shows the Gatekeeper
      note, "runs checkpoint on the map; unlocks persist", and
      "best played with a mouse".
- [ ] Set `GameState.LINK_DISCORD` before launch or leave it empty (the
      button hides itself).

## Next cut (not this release)
- Windows/Linux export presets.
- Run-state serialization inside combat (today: map-entry checkpoints).
