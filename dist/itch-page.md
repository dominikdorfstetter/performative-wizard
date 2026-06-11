# itch.io page kit — Performative Wizards (demo v1.2.2)

The page converts at ~1% CTR — the kit below is built to fix that: a cover
with TEXT on it, a hook-first description, and fresh screenshots.

## Page setup (do these in the dashboard)
- **Title:** `Performative Wizards` — drop the "(Playtest)" suffix; it reads
  as unfinished and costs clicks.
- **Cover image:** `dist/itch-cover.png` (630×500, wordmark + hook + FREE chip
  — readable at thumbnail size; the cover IS the ad).
- **Banner (theme → banner):** `dist/itch-banner.png` (960×300).
- **Pricing:** "No payments" for the demo (a $0.99 suggested-donation dialog
  adds a click between browse and play — pure funnel loss at this stage).
- **Screenshots** (fresh, 1152×648, in `dist/screenshots/`), in this order:
  `agent.png` (Talent Agent + his roster), `irs.png` (The IRS mid-audit),
  `bouncer.png` (the neon door), `scene-fight.png` (disco ball strobe),
  `dress.png` (the full-unlock rack), `reward.png` (S-stamp), `map.png`,
  `boutique.png`.
- Remove `performative-wizards-web.zip` from the *downloads* list — it's the
  embedded game; offering it as a download splits the stats.
- Kind: HTML, viewport **1152×648**, fullscreen ON, SharedArrayBuffer **OFF**.

## Short description (sub-headline)
She's watching. A roguelike deckbuilder where a rival Critic grades every
fight live — S, A, B or C — and rewrites the road ahead. Don't just win.
Win the room.

## Body copy

**The hardest enemy in this deckbuilder doesn't attack you. She reviews you.**

You're a wizard whose power is the fit. Bank **Aura** mid-fight, light the
tiers (6+: damage · 12+: draw · 18+: pierce · 24+: the spotlight), then cash
it ALL out on one filthy finisher — while **The Critic** grades how boldly
you played.

- **A rival who reviews you.** Every fight gets a live letter grade. Serve an
  S and a VIP room opens ahead; flop a C and she sends a heckler into your
  next fight. Her taste drifts — repeat your winning trick and it stops
  paying. You can even bribe her with a matcha. Or roast her latte order.
  Your funeral.
- **All your power is the outfit.** Three wizards with real identities:
  Vesper burns the room down, Morticia raises a **crowd of ghouls and sics
  them on command**, Chadwick crits so hard the Energy comes back — and can
  now **Ghost** entire turns (dodge hits = your Rizz). 25 fits that reshape
  your build, **30 cards per wizard, 30 relics from Common to Legendary**,
  11 events, two archetypes per wizard.
- **Three floors, each with its own cast.** Act 1: your hexed neighborhood
  (an Angry Toaster, a Possessed Wardrobe). Act 2: the venue turns on you —
  cursed mirrors, a strobing disco ball, and **The Bouncer** checking your
  fit at the door. Act 3: the Feed — NPC Streamers, Reply Guys, **The IRS**
  (it garnishes 25% of your gold and FLEES — kill it first for the refund),
  and a finale against The Algorithm or **The Talent Agent**, who books
  weaker versions of every other boss.
- **3 acts + ascension, 30–45 min runs.** Quit-safe: runs checkpoint at the
  map, meta unlocks (Clout, wardrobe, cards) always persist — and every
  wizard earns their OWN card pool by being played, so each one is a fresh
  progression ladder.
- **EN / Deutsch / Español** — auto-detected. Every pixel and bleep generated
  by code.

## Media checklist
- GIF 1 (lead): the FINALE cash-out (shake → meter drain → banner).
- GIF 2: Critic stamp slam on the reward screen → crown/heckler badge on map.
- Gameplay video: raw footage in `builds/gameplay-raw.mov` — cut to 30–45s,
  lead with the goon crowd lunge + the stamp.
- Description footer: Gatekeeper note from `dist/macos-README.txt`,
  third-party notices link, "best played with a mouse",
  "runs checkpoint at the map; unlocks persist".

## Launch-day toggles
- `GameState.LINK_ITCH` ✓ and `LINK_DISCORD` ✓ are already wired.
- Run the RELEASE.md smoke list on the itch DRAFT page before going public.

## Theme settings (itch dashboard → Edit theme)
Pulled straight from the game's palette so the page reads as one product:

| Setting | Value | Why |
|---|---|---|
| Background (page) | `#0E0A14` | the game's splash/void colour |
| Background 2 (content box) | `#181024` | the game's panel base — subtle lift |
| Text | `#D8D2E0` | the in-game body text lavender-grey |
| Link | `#FF4FB3` | brand pink (the wordmark/Critic colour) |
| Button | `#FF4FB3`, white label | one loud CTA colour, used nowhere else |
| Banner | `dist/itch-banner.png` | 960×300, has the wordmark + FREE chip |
| Font | leave default (sans) | itch has no pixel font; faking it with monospace hurts readability — the cover/banner/screenshots carry the pixel identity |
| Screenshots | sidebar ON | keeps the embed + buy box above the fold |
| Embed bg | `#0E0A14`, no border | the canvas melts into the page |

Custom CSS (if the account tier allows): none needed — resist the urge;
the assets do the theming.
