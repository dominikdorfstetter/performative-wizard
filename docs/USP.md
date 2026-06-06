# Performative Wizard — The USP Decision (2026-06-06)

> Produced by a three-lens design panel — **Product Owner**, **Game Design Director**,
> **Godot Architect** — plus a competitive-market scan and six creative-lens ideation
> passes. Companion to `DESIGN.md` (vision), `DESIGN_REVIEW.md` / `REVIEW_2.md`
> (critiques), and `ROADMAP.md` (the now-shipped build plan).

## The problem

We have a **feature-complete, technically clean Slay-the-Spire-like** — pure-logic
tested combat engine, data-driven content, 38 cards / 23 enemies / 3 wizards / 17 outfits
/ 14 artifacts, 3 acts + ascension, procedural art/audio, EN/DE/ES. **But it has no
unique selling proposition.** "StS but Gen-Z fashion" is a *skin*, and the banked-Aura
economy — genuinely good — is a *well-executed variation*, not a pillar swap. In a market
with 1,400+ deckbuilders on Steam where players reflexively skip anything that reads as a
clone, that is not enough to break out.

Two hard market facts the panel surfaced:
1. **Every breakout swapped a PILLAR** (StS = telegraphed intent; Balatro = multiplicative
   score engine; Wildfrost = countdown timers; Monster Train = spatial lanes; Luck be a
   Landlord = slot adjacency). More cards/relics/acts is **not** differentiation.
2. **The fashion theme is now contested.** *Dress the Duel* (UgokuWare, Q1 2026) is a
   fashion deckbuilder with outfit slots + a stacking "Posture" resource. We **cannot**
   win the head-to-head on "you fight in outfits." We must compete on the **Aura
   hoard-vs-spend decision** and the **Gen-Z voice**, where we are genuinely distinct.

## The decision

> ### USP: *The roguelike deckbuilder that **REVIEWS you**.*
> A rival critic shadows your whole run, grading every fight on **how boldly you played
> your Aura** — peak swag reached, which 6/12/18 thresholds you lit, and whether you closed
> on a clean finisher cash-out. Her running review **rewrites the map ahead**: fight clean
> and she opens VIP rooms; fight ugly and she sends hecklers. **Don't just win. Win the room.**

**Store hook:** *She's watching. Serve looks or get reviewed.*

Winning candidate of 8 shortlisted, top blended score across all three lenses
(differentiation 8 / feasibility 9 / Aura-synergy 9; fun 7). It is the **only** candidate
that scores high on differentiation, feasibility, AND deepens the protected Aura pillar at
the same time.

### Why this one (the three lenses agree)

- **Market / differentiation.** It attacks the genre's single biggest *unclaimed* white
  space: **StS-likes grade nothing** — a 1-HP win equals a flawless one. Grading *how* you
  won is a real pillar swap, and it reframes us from "the fashion deckbuilder" (a losing
  lane) to **"the deckbuilder that judges you"** (no competitor). Best trailer moment of
  any candidate: a Letterboxd-style **"S — serve. obsessed. devastating."** stamp slamming
  onto a finisher cash-out, then the map visibly rewriting into a gold VIP room. The
  inverse — **"C — flop"** + a heckler physically dropping into your next node — is *more*
  shareable (schadenfreude clips travel). Legible in one frame; that's the Balatro bar.

- **Game design.** The Show Rating is computed **primarily from Aura behavior**, so it
  *amplifies* the hoard-vs-spend decision at the exact moment it matters (the final dump)
  and never routes around it. It also fixes the genre's worst structural flaw: because
  nothing is normally graded, the optimal line collapses to "survive efficiently." A style
  score **forces you to keep playing the Aura tension at full volume even when you could
  coast.** Outfits become **stage personas** — flash fits chase high-peak S-spikes,
  slow-burn fits farm consistent A's — which is real build variety welded to the core
  resource.

- **Architecture.** Verified against the actual code, effort **M**, feasibility **9/10**.
  The map is a mutable `Array` of node dicts read at `enter()` (`game_state.gd:283`);
  combat ends via `combat_ended` **before** the scene swaps (`combat_ui.gd`), giving a
  clean hook; the Critic **already ships** as a boss (`&"the_critic"`), so art/fight/
  identity exist. New bookkeeping is small, localized, and **headless-testable** in the
  existing harness: peak-swag tracking in `gain_swag()`, a clean-finisher flag on
  `finisher_swag_x3`, a `compute_show_rating()` method, and `GameState.critic_score` +
  `apply_critic_mutation(next_node)`.

### Runner-up (fold in, don't compete): *Commit to the Bit* (Encore High-Wire)

The Critic's one real weakness: when she's off-screen, the turn-by-turn loop is still "StS
+ a second banked resource." **Commit to the Bit** fixes exactly that by making the **top
threshold a live every-turn decision** — bank past a SPOTLIGHT line (~24) to arm a growing
**Encore**; **Take a Bow** on your terms for `swag × (2 + encore)`, or get **booed off
stage** if you drop below the line. Sequence it **after** the Critic MVP proves the loop
(roadmap P3). The two reinforce each other: a clean Take-a-Bow becomes the single
highest-scoring style fingerprint the Critic rewards.

### What lost, and why (the honest cut list)

| Candidate | Verdict |
|---|---|
| **The Audience (Read the Room)** | Strong (31), great trailer, but adds a **4th meter** and cognitive load that threatens first-fight legibility while we're still establishing Aura + Critic. **Waits.** |
| **The Set List (Carry Aura Between Rooms)** | On-strategy (28.6), cheapest (S), but the USP is the *absence* of a reset animation — a legibility/spectacle gap; needs a sibling to feel tense in minute one. Fold the "Cash Out the Set" idea into rewards later. |
| **Call Your Shot / The Feed / Wardrobe Malfunction / Living Wardrobe** | Each has a real idea, but: borrowed-from-finisher trailer (Feed), feels-bad permanence (Malfunction), wrong-altitude / menu-bound moment (Living Wardrobe), or weaker Aura-synergy (Call Your Shot). |

## The roadmap (leverage-ordered, gated)

Each phase has a **gate**: a "is it fun, do we continue?" check. Do not pass a gate on
faith. Maintain the green test suite and the macOS build per slice (existing DoD).

### P0 — Make the Aura meter the loudest thing on screen · **M**
Before *any* USP: fix the named failure "burying the signature mechanic." The threshold
meter and the finisher cash-out must be the juiciest element in fight one, Critic or not.
- Redesign the swag bar into a **tiered meter with visibly LIT/UNLIT tiers at 6/12/18** —
  a glance reads "I am +2dmg / +1draw / piercing right now."
- Engineer the **Grand Finale cash-out as the trailer shot**: screen-shake, meter drains
  full→empty in one beat, big number, crowd-pop synth (`Audio._build_sfx`).
- Localize all new readouts EN/DE/ES.
- **GATE:** A new tester, first fight, describes the game as *"I bank style and one
  finisher turns all my buffs off"* **unprompted**. If they say "StS with a second
  energy," stop and re-juice before building the Critic.

### P1 — The Critic MVP (the run frame + the live grade) · **L**
Prove the scored-rival loop: a **live** rating during combat, a **visible** map reaction
after, computed primarily from Aura behavior.
- `peak_swag` tracking in `gain_swag()`; clean-finisher-kill flag on `finisher_swag_x3`.
- `CombatManager.compute_show_rating()` → `{rating, peak_swag, thresholds_lit,
  finisher_clean, turns, hp_lost}`.
- **A LIVE on-screen running rating** that ticks up as you light thresholds / peak higher —
  this is the must-have that makes her read as *watching*, not a results screen.
- `GameState.critic_score` + `apply_critic_mutation(next_node)`: S enriches the reward
  (bonus gold / ovation Aura seed via the existing `swag_start` path); C injects a low-HP
  heckler into `node.enemies`. **Penalties touch rooms/upside ONLY, never starting-combat
  math** — no death spiral. Persist in `save.json`.
- Resolve the naming collision: the meta-antagonist **IS** the existing `&"the_critic"`
  boss; she headlines the act when `critic_score` demands it.
- Headless tests for rating + node mutation.
- **GATE:** Do testers feel *watched* and change how they play the next fight to chase a
  better review? If the rating reads as a passive results screen they ignore, fix
  presentation before adding depth.

### P2 — Anti-solve: the drifting taste (the make-or-break) · **L**
This is **the whole ball game**, not a nice-to-have. Defend against "collapses to one
dominant line" — specifically the degenerate *hoard-then-single-Grand-Finale-every-fight*
that a naive scorer actively *teaches*.
- **Widen the style fingerprint** beyond the 5 facts the engine emits: which finisher,
  which threshold you parked at, single-target vs spread, overkill, took-a-hit-at-full-Aura.
- Make the Critic's taste a **drifting target** in that space (not a binary S-cooldown):
  repeating the same S-style **decays its bonus**, punishing repeated "parked-high → one
  finisher."
- **Outfit-as-persona tuning** so no single persona stays optimal across 3 acts.
- **GATE:** By Act 2, is there a fresh stylistic ask each fight — or have optimizers found
  a 2-state alternating script? If solvable in ~1 hour by alternating two memorized lines,
  the fingerprint isn't rich enough.

### P3 — In-combat tension layer (fold in *Commit to the Bit*) · **M**
Make the turn-by-turn loop novel even when the Critic is off-screen.
- `THRESHOLD_ENCORE` (~24) + encore counter in `_tick_powers()`.
- Voluntary **Take a Bow** `finisher_encore` op (`swag × (2 + encore)`) — visibly distinct
  from Grand Finale to avoid the trap-card problem.
- Involuntary **Booed** state with a one-turn "shaky" telegraph + a soft floor so one drop
  doesn't cascade off all tiers.
- New **`tax`** enemy verb (extends `_resolve_intent` like `drain_swag`) — gives drain
  enemies a counter-play identity that punishes hoarding.
- Wire a clean Take-a-Bow as a top fingerprint for the Critic; gate to Act 2+.
- **GATE:** Does holding the encore zone vs bowing feel like a real gamble the Critic
  rewards — without bricking runs via Booed?

### P4 — Longevity & depth siblings · **XL**
- Add 3–4 finishers so "which cash-out style" is real fingerprint variety (also powers P2/P3).
- Make more outfits genuinely **reshape the Aura curve** (high-drip slow-burn vs low-drip
  flash) so outfit choice = "which hoard-vs-spend identity am I touring."
- Optionally layer **The Feed**: a rotating Trend that re-prices Aura *income* (off-trend =
  reduced, never zero), telegraphed a day ahead, giving The Algorithm boss its identity.
- Expand Critic mood states / reactive text so the rival never feels repetitive.
- **GATE:** Do 10+ runs still feel different because outfits play differently AND the
  Critic + Trend keep moving the optimum?

## Risks (eyes open)

- **Drift is the whole ball game and is currently a slogan.** The depth ceiling is entirely
  gated on P2. With only today's 5 facts, "vary your style" degenerates into a 2-state
  chore. **P2 is make-or-break.**
- **Reward-chasing can distort the Aura tension** instead of deepening it — the naive scorer
  teaches the exact degenerate line it claims to kill. Drift must punish the repeated
  parked-high→one-finisher pattern.
- **Cold-streak death spiral / grade-anxiety chore.** Penalties must be upside/room-only; an
  A/B run must remain fully winnable and progress meta, or we ship a stress simulator, not a
  glam fantasy.
- **It's a meta-wrapper, not a combat-pillar swap.** If P0 and P3 slip, combat reads generic
  between the Critic's appearances.
- **Presentation/writing is load-bearing.** A reactive rival lives in her portrait, running
  review voice, and barbs (× EN/DE/ES). Budget the text/VO or she's a silent difficulty
  modifier.
- **Tuning surface grows combinatorially** (fingerprint × archetype × act × ascension);
  the inline tests don't cover it.

## Kill criteria (when to abandon)

- After **P0**: testers still say "StS with a second energy" and can't articulate
  hoard-vs-spend unprompted → the signature is buried; don't build on an invisible core.
- After **P1**: testers treat the rating as a passive results screen and don't alter play →
  the "watched" fantasy failed; if a presentation pass can't fix it, the Critic is just a
  difficulty modifier — cut it.
- After **P2**: optimizers solve the drift in <1 hour by alternating two lines, OR the path
  of least resistance stays hoard-then-one-finisher → the anti-solve didn't hold; the USP
  isn't defensible.
- Cold-streak can't be tuned to "pressure without bricking" → strip mutations to cosmetic +
  reward-only, or kill the candidate.
- Sentiment over 5+ runs reads as a stressful nag, not a brag-worthy chase → the audience
  wedge inverts; the Gen-Z voice becomes a liability.
- By **P4**, runs converge on one optimal fit and the Critic stops surprising → build
  variety failed; we have a 3-hour game in a 30-hour shell.

## What to protect (unchanged)

The banked-Aura hoard-vs-spend decision, outfit-as-power, the Gen-Z voice, and the
procedural art/audio pipeline. **Every change above must feed the Aura decision, not bypass
it.**
