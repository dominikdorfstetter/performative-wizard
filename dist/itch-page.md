# itch.io page kit — Performative Wizard (demo)

## Headline
**She's watching. Serve looks or get reviewed.**

## Short description (sub-headline)
A roguelike deckbuilder where a rival Critic grades every fight live — S, A, B
or C — and rewrites the road ahead. Don't just win. Win the room.

## Body copy

You're a wizard whose power is the fit. Bank **Aura** mid-fight, light the
tiers (6+: damage, 12+: draw, 18+: pierce, 24+: the spotlight), then cash it
ALL out on a finisher — while **The Critic** scores how boldly you played.

- **A rival who reviews you.** Every fight gets a live letter grade, scored on
  your Aura play. Serve an S and a VIP room opens ahead; flop a C and she
  sends a heckler into your next fight. Her taste drifts — repeat your
  winning trick and it stops paying.
- **All your power is the outfit.** Three wizards, two archetypes each, 19
  fits that reshape your Aura curve, 49 cards, 14 relics, very ordinary
  enemies turned hostile (an Angry Toaster, The Algorithm).
- **3 acts + ascension, 30–45 min runs.** Quit-safe: runs checkpoint at the
  map, meta unlocks (Clout, wardrobe, cards) always persist.
- **EN / Deutsch / Español** — auto-detected.

## Setup checklist (page settings)
- Kind: HTML — upload `builds/web/` zipped, "This file will be played in the
  browser". Viewport **1152×648**, fullscreen button ON, SharedArrayBuffer
  support **OFF** (build is threads-off on purpose).
- Also attach the macOS zip (repacked with README.txt + THIRDPARTY.txt).
- Cover image: 630×500 — use `dist/screenshots/menu.png` cropped, or render
  the three wizards from `assets/boot_splash.png`.
- Screenshots (1152×648, in `dist/screenshots/`): combat, map, collection,
  shop, dress, chest.
- GIF 1 (lead): the FINALE cash-out (shake → meter drain → banner).
- GIF 2: Critic stamp slam on the reward screen → crown/heckler badge pulsing
  on the map.
- Description footer: the Gatekeeper note from `dist/macos-README.txt`, the
  third-party notices link, "best played with a mouse", and
  "runs checkpoint at the map; unlocks persist".

## Launch-day toggles
- Set `GameState.LINK_ITCH` to the real page URL and (optionally)
  `LINK_DISCORD` before the release export.
- Run the RELEASE.md smoke list on the itch DRAFT page before going public.
