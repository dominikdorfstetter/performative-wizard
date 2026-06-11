# Post templates — paste-ready, per channel

Companion to `dist/awareness-plan.md` (the why + calendar). Everything below is
ready to paste; swap GIF/screenshot attachments from `dist/screenshots/`.
Link everywhere: https://dorfid.itch.io/performative-wizards

Rules recap before posting anywhere:
- r/WebGames needs a 7+ day-old account with 10+ comment karma. Start commenting today.
- r/playmygame requires you to give feedback on other games — budget 30 min for it.
- r/IndieGaming bans AI-assisted content → **skip entirely**.
- r/slaythespire: **text only**, no images, link in a comment if asked.
- Reply to every comment within a few hours on post day. Post-and-ghost kills reach.

---

## r/DestroyMyGame (post FIRST — pressure-test the page)

**Title:** Destroy my itch page: free browser roguelike deckbuilder, ~1% CTR — what's killing it?

**Body:**
Page: https://dorfid.itch.io/performative-wizards

Solo dev. The demo is free, plays in the browser, 30–45 min runs — and almost
nobody clicks through. I just rebuilt the cover (was a banner that itch cropped
to garbage), retagged, and reshot the screenshots. Before I spend traffic on
this page: what would stop YOU from clicking, and what would stop you from
pressing "Run game" once you landed?

Destroy the page, not my feelings. (Fine. Both.)

---

## r/WebGames

**Title:** Performative Wizards — free browser roguelike deckbuilder where a rival Critic grades every fight (S–C) and rewrites the run to spite your playstyle. 30–45 min runs, no signup.

**Body:**
Link: https://dorfid.itch.io/performative-wizards

The hook: the hardest enemy doesn't attack you — she reviews you. Every fight
gets a live letter grade based on how boldly you play your Aura economy. Serve
an S and a VIP room opens ahead; flop a C and she sends a heckler into your
next fight. Her taste drifts, so repeating your winning trick stops paying.

Also features: The IRS as an enemy (it garnishes 25% of your gold and FLEES —
kill it before it dips and your refund comes through), a Bouncer boss who
fit-checks you at the door, and a Talent Agent who books weaker versions of
the other bosses against you.

Free, no signup, saves in browser, EN/DE/ES. Feedback very welcome — solo dev.

---

## r/playmygame

**Title:** [PC] (Web) Performative Wizards — my Critic NPC reviews your combat style live. Does the grading feel fair or rigged? Playable Link inside. Free browser demo, EN/DE/ES.

**Body:**
Playable Link: https://dorfid.itch.io/performative-wizards (browser, no signup)

It's a roguelike deckbuilder where a rival Critic grades every fight S/A/B/C
on how boldly you played — peak Aura reached, thresholds lit, whether you
closed on a finisher. Her verdict rewrites the map ahead (VIP rooms / hecklers)
and her taste drifts so one-trick builds decay.

**What I most want feedback on:** does the grading feel readable and fair, or
arbitrary? Did you understand WHY you got your grade? And did anyone manage an
S on the Bouncer?

I'll be in the comments all day, and I'm playing + reviewing other games from
this sub today as well (it's the rule, and honestly the fun part).

---

## r/roguelites (pair with devlog #2)

**Title:** I made a roguelike deckbuilder where a rival Critic grades every fight S/A/B/C live and rewrites your run based on how you play. The IRS is an enemy. Free browser demo.

**Body:**
[attach: stamp-slam GIF]

The design problem I was chasing: deckbuilders reward solved loops — find the
combo, repeat it forever. So I built a Critic who gets BORED. Every fight is
graded live on how boldly you play the banked-Aura economy, the grade rewrites
the road ahead (S = VIP room, C = heckler in your next fight), and her taste
drifts: the style she just rewarded pays less next time. Variety IS the meta.

Three acts with their own casts (your hexed neighborhood → the venue → the
terminally-online Feed), four bosses incl. a Talent Agent who books weaker
versions of the other bosses, and yes — The IRS spawns, garnishes 25% of your
gold, and tries to flee with it.

Free in the browser: https://dorfid.itch.io/performative-wizards
Happy to talk design in the comments — especially the anti-net-decking drift.

---

## r/Games — Indie Sunday (verify current wiki rules first)

**Title:** [Indie Sunday] Performative Wizards — dorfid — a roguelike deckbuilder where the final boss is a Critic who's been grading you the whole run (free browser demo)

**Body:**
Play (free, browser): https://dorfid.itch.io/performative-wizards

Slay-the-Spire-like with one twist: a rival Critic grades every fight S/A/B/C
live, based on how boldly you play the banked-Aura economy — and her verdict
rewrites the run (VIP rooms, hecklers, drifting taste that punishes one-trick
builds). 30–45 min runs, 3 themed acts, 3 wizards with their own card pools,
EN/DE/ES, made solo in Godot 4 with fully procedural art + audio.

Recent update: every act is now its own floor with its own cast — including
The IRS, which garnishes 25% of your gold and files to leave with it.

---

## r/godot (check Rule 10 / flair before posting)

**Title:** Godot 4, solo dev: how I built a Critic that grades your fights live and rewrites the run (free browser demo)

**Body:**
[attach: stamp GIF or combat screenshot]

Architecture notes for fellow Godot people:
- Combat is a pure RefCounted state machine (no nodes) — 372 headless tests
  run in CI on every push, plus a balance-sim bot and a full-run playtest bot.
- Every sprite and sound is generated at runtime (a parameterized 16×16
  pixel-art generator + synthesized audio) — the binary ships zero art assets.
- The Critic reads a "style fingerprint" off the fight (peak Aura, AoE vs
  single-target plays, finisher kind, risky flexes) and grades S–C; grades
  mutate the map ahead and her taste drifts to punish repeat strategies.
- Localization is a dumb-but-bulletproof dict-passthrough autoload (EN/DE/ES)
  with a CI test that fails if any player-visible string misses a table.

Demo (free, browser): https://dorfid.itch.io/performative-wizards
AMA about the headless-testing setup — it's the only reason a solo project
this size hasn't collapsed.

---

## r/slaythespire (TEXT ONLY, no images, no link in post)

**Title:** StS players: would a boss that reviews your runs work? My game's Critic grades every fight, and the Talent Agent boss books weaker versions of the other bosses against you. Looking for design opinions.

**Body:**
Designing a StS-like and wrestling with the "solved loop" problem — once you
find your infinite, every fight plays itself. My experiment: a rival Critic
who grades every fight S/A/B/C on how boldly you played (peak resource,
thresholds lit, finisher close), rewrites the path based on the grade, and
gets BORED of styles she's seen — the bonus for your winning trick decays
until you switch it up.

Questions for people who've sunk real hours into Spire:
1. Would grade-based path rewriting feel like agency or like the game
   punishing consistency?
2. A boss who summons weaker versions of the other bosses — fun callback or
   cheap difficulty?
3. Where's the line between "taste drift" and "the game won't let me play my
   deck"?

(It's playable free in a browser — link in comments if anyone asks; mods,
happy to remove if that crosses the line.)

---

## Bluesky / Mastodon — #ScreenshotSaturday rotation

**Week 1 (stamp GIF):**
she doesn't attack you. she reviews you. S/A/B/C, live, every fight — and her
taste drifts, so your winning trick stops paying.
Performative Wizards: free roguelike deckbuilder in your browser.
https://dorfid.itch.io/performative-wizards
#ScreenshotSaturday #gamedev #indiedev #godot #roguelike

**Week 2 (IRS GIF):**
the IRS just garnished 25% of my gold and FLED THE FIGHT. I'm pressing
charges (next run).
free browser deckbuilder, 30–45 min runs:
https://dorfid.itch.io/performative-wizards
#ScreenshotSaturday #gamedev #indiedev #pixelart

**Week 3 (finisher GIF):**
bank the Aura. light the tiers. hold the spotlight. then spend EVERYTHING on
one filthy finisher while the Critic watches.
https://dorfid.itch.io/performative-wizards
#ScreenshotSaturday #gamedev #indiedev #godot

---

## YouTuber / streamer pitch email

**Subject:** Free browser deckbuilder where a Critic grades your fights live — 30 min, nothing to install

**Body:**
Hi [NAME],

[One personalized line — name a specific video of theirs, e.g. "Your Bramble
Royale demo video is the reason I believe in demo coverage."]

Performative Wizards is a free 30–45 min browser roguelike deckbuilder where a
rival Critic grades every fight S/A/B/C on screen and rewrites the run to
spite your playstyle — her taste drifts, so one-trick builds literally stop
paying. The IRS is an enemy: it garnishes 25% of your gold and flees; kill it
first and your refund comes through. The act-3 boss is a Talent Agent who
books weaker versions of the other bosses against you.

Plays instantly in the browser, no install, no signup:
https://dorfid.itch.io/performative-wizards

GIFs attached (stamp slam / IRS fleeing / finisher), trailer: [LINK]. If you'd
rather have a build or a press kit, say the word. No deadline, no exclusivity —
it's free and I'd just love your take on whether the grading feels fair.

Thanks either way for the videos,
Dominik (solo dev)

**Send to (personalize line 1 each):** Retromation, Olexa, Nookrium,
Clemmy / Best Indie Games, Wanderbots; stretch: Splattercat.

---

## itch community boards

**Release Announcements:**
Title: Performative Wizards — a roguelike deckbuilder where a rival Critic
grades every fight S/A/B/C (free, browser, EN/DE/ES)
Body: 2 paragraphs from the page copy + 2 screenshots + link.

**Get Feedback:**
Title: My demo page converts at ~1% — tear apart my cover/tags
Body: link + "what would stop you from clicking?" — mirror the
r/DestroyMyGame post.
