# Performative Wizards — demo review (internal, 2026-06-10)

> Written at the owner's request, in the voice of a genre critic, against the bar:
> *"fun to play, addictive and easy to understand, with depth to master."*
> Verdict: **79 / 100** — below the requested 85, so per instructions the
> critique is itemized below, each item with the cheapest path to the points.
> Basis: systems analysis, the balance-sim win-rate data (docs/USP.md), data-file
> audit of all 49 cards / 24 enemies / 14 relics / 19 fits, and full-screen
> renders of every screen in the current build. Not a substitute for human
> playtests — treat the numbers as a designer's estimate.

## What carries the score

**The hook is real (the best thing here).** Being *graded* on how boldly you
played — live, by a named rival whose verdict visibly rewrites the map — is a
genuine pillar swap, not a skin. No competitor grades anything. The drifting
taste (your winning style goes stale) is a clever anti-solve, and the new
ceremony (stamp slam, crown/heckler badges, heckler drop-in with a barb) finally
makes it legible. This system alone is worth the demo.

**The core decision is tight and teachable.** Hoard Aura for tier buffs vs dump
it on a finisher is a real every-turn tension; 6/12/18/24 reads at a glance on
the lit meter; the first-fight tutorial covers it in three beats. Easy to
understand: yes, now.

**Session shape is right.** 30–45 min to a likely act-2/3 death, Clout banked,
a visible "Necro at 70 — you have 52" bar, and a Collection screen that gives
the meta loop a home. Losing pays out. That's the addictive half of the brief.

**The voice.** "again? serve me something NEW." is a personality, not a stat
readout. The banter, verdicts, and event copy land, and they survived the
family-friendly pass intact.

## The critique (why it's 79 and not 85+)

1. **Combat depth ceiling — the master half of "easy to learn, deep to master"
   is the weak half (−6).** No draw-pile/discard inspection (deferred), no
   scry/tutor/retain effects, no card-sequencing puzzles beyond first-spell
   bonuses. A Spire veteran will solve a turn in seconds. *Cheapest points:*
   draw/discard counters + 2–3 manipulation cards ("scry 2", "retain 1") —
   the engine's draw functions already exist.
2. **Enemy presentation: variety is mechanical, not visual (−4).** 24 enemies
   with genuinely distinct intent patterns, but the 16×16 silhouettes cluster
   around "blob with eyes" and share one body grammar; the owner spotted it
   immediately. *Cheapest points:* a size/palette/posture pass in SpriteBank —
   elites 1.5× larger, bosses 2×, 2–3 distinct body templates (tall/wide/
   floating) — no hand art needed.
3. **The Rizzard's draft pool is thin (−3).** 14 reward cards vs Fire 21 /
   Necro 22 — by mid-act-2 a Rizz run sees repeat offers, exactly where draft
   variety should peak. *Cheapest points:* 5–6 new Rizz commons/rares (the
   rare tier is also globally inverted: 5 Rares vs 11 Epics).
4. **Top-end balance is documented-rough (−3).** Per the sim: asc8 boss ~59%
   for Rizz vs ~0–2% for Fire/Necro. Fine for a demo's first cut, visible to
   ladder-chasers. Balance pass #3 on main narrowed it; the gap remains.
5. **Six events (−2).** Act 2 already repeats them; by act 3 they're furniture.
   *Cheapest points:* 4–6 more events, including 1–2 that interact with the
   Critic (she IS the run — let an event bribe or provoke her).
6. **Audio wears (−2).** Five ~7-second synth loops over a 45-minute run; the
   crossfade helps, the repetition doesn't. *Cheapest points:* per-act variation
   of existing patterns (the synth is procedural — vary tempo/key per act).
7. **Upgrade depth is one note (−1).** Glow Up = cost−1 for every card; no
   choice texture. *Cheapest points:* upgrades pick cost−1 OR value+2 per card.

Progression answers (owner's questions, from the data): the **card pool (49)
is sufficient for a demo** — 27 free + 22 gated smoothly across 20→150 lifetime
Clout, so with ~40–60 Clout per loss the pool opens over ~3–4 runs (good drip);
**relics**: 8 free + 6 gated 40→130, fully open by run ~3; both curves now have
a visible home in Collection. The thin spots are the Rizz pool and the Rare
tier, not the totals.

## Scorecard

| Axis | / | Notes |
|---|---|---|
| Hook / identity | 18/20 | The Critic is a real USP; ceremony now sells it |
| Moment-to-moment combat | 14/20 | Tight core tension; low mastery ceiling |
| Progression & retention | 16/20 | Clout drip + Collection + unlock teasers work |
| Presentation | 16/20 | Coherent pixel identity, fonts, fades, juice; enemy art is the drag |
| Content breadth | 8/12 | 49/24/14/19 is demo-right; Rizz pool + events thin |
| Polish & UX | 7/8 | Tutorial, tooltips, pause, saves, a11y; minor blinks remain |
| **Total** | **79/100** | **Demo-ready; the +6 to 85 lives in items 1–3** |

The 85+ path, in order: enemy visual pass (2), draw manipulation + pile
visibility (1), Rizz pool + rare tier fill (3). All three are post-demo-v1
sized — none should gate this release.

---

# Re-review (2026-06-10, after the fix pass)

All seven items above were addressed in the same PR. What changed, scored
against the same axes:

1. **Depth ceiling:** draw/discard counters with contents tooltips, plus three
   real manipulation verbs — peek (Vision Board), recycle (Thrift Flip),
   retain (Saved to Drafts, with a 10-card hand cap). Banking a 5-card
   mega-turn behind a retain is a genuinely new line of play that feeds the
   Aura-hoarding identity. *Remaining gap:* no click-to-inspect pile overlay,
   no choose-from-discard tutor — the peek is information, not selection.
2. **Enemy presentation:** three new body grammars (wide / imp / floaty) break
   the round cluster from 11 to 7, and display bulk finally makes bosses
   tower (2x) and goons scuttle (0.8x). The cast reads as a cast now.
   *Remaining gap:* features (ears/fangs/etc.) still share one placement grid.
3. **Rizz pool:** 14 -> 23 (fire 24 / necro 25 with the neutrals), with AoE
   access (Love Bomb, Crowd Work) so wide-S grades are reachable. Rare tier
   5 -> 9 vs 11 Epics — no longer inverted enough to notice.
4. **Top-end balance:** asc8 boss went from fire ~0 / necro ~2 / rizz 59 to
   roughly **20 / 35 / 82** (K=200, +-5): the asc HP+dmg curves kink at 4,
   Goons hit critical mass at 4+, fire got a class-wide lift (drip 3, hotter
   roasts) and rizz_crit was shaved to 0.04. Honest caveat: parity is not
   claimed — crit multiplication is structural — and the sim bot under-plays
   burn lines a human would pilot.
5. **Events:** 6 -> 11, and two of them finally touch the USP — bribing the
   Critic with a matcha (guaranteed VIP) or roasting her latte order (50/50
   VIP/heckler) is exactly the kind of decision this game should be made of.
   Bonus: all 11 events now actually ship in DE/ES (the old six were silently
   English-only).
6. **Audio:** acts 2/3 transpose +2/+4 semitones at +6/+12 BPM. The loops are
   still seven seconds long, but they no longer wear identically.
7. **Upgrades:** Glow Up picks Sharper (cost-1) or Juicier (+2 amounts), and
   zero-cost cards became upgradeable. Two-note, but the choice is real.

## Re-scorecard

| Axis | Was | Now | Why |
|---|---|---|---|
| Hook / identity | 18/20 | 18/20 | unchanged — still the best thing here |
| Moment-to-moment combat | 14/20 | 17/20 | manipulation verbs + pile info; no selection UIs yet |
| Progression & retention | 16/20 | 16/20 | unchanged |
| Presentation | 16/20 | 18/20 | silhouette families + bulk scale |
| Content breadth | 8/12 | 10/12 | 58 cards, 11 events, Rizz pool fixed |
| Polish & UX | 7/8 | 7/8 | counters/tooltips fit the chrome; loc now truly complete |
| **Total** | **79** | **86/100** | **above the 85 bar** |

The path to 90: a click-to-open pile inspection overlay, 2-3 selection-based
cards (true scry, discard tutor), per-enemy feature variety on top of the new
shapes, longer music phrases, and — above all — human playtests to replace
the sim's guesses about asc4+.
