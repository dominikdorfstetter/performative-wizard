# Enemy Redesign Plan

> **Superseded (2026-06-11):** the "ordinary modern thing turned hostile" theme below
> was the playtest placeholder. The roster is now organized into per-act FLOORS with
> their own casts, backdrops, and headliner bosses — Act 1 "the Block" (hexed domestic
> things), Act 2 "the Scene" (the venue — ends on The Bouncer), Act 3 "the Feed"
> (terminally online — ends on The Algorithm or The Talent Agent, who books weaker
> versions of the other bosses). See `scripts/run/encounters.gd` for the pools and
> the table of truth.

Fixes the two problems from `DESIGN_REVIEW.md §1`: **off-theme/lazy designs** and
**samey attack patterns**. Theme rule: *every enemy is an ordinary modern thing
(object, animal, or online archetype) turned hostile.* No high-fantasy goblins.

## New engine verbs (so patterns can differ)
- `attack` gains an optional `"hits"` field → multi-hit that chips through Block.
- `heal` intent → enemy restores its own HP.
- `frail` status → player gains 25% less Block while frail (decays like weak).
  Themed as "they exposed your fit". New `crack` icon.

## Re-themes (keep ids, fix name/emoji/pattern)
| id | was | now | why |
|---|---|---|---|
| `goblin_gremlin` | Goblin Gremlin 👺 | **Wi-Fi Gremlin** 📶 | gremlins break machines — on-theme tech pest; now applies `frail` + a twin-hit |
| `clout_goblin` | Clout Goblin 👺 | **Clout Chaser** 🤳 | drop the goblin; it's an online archetype; unique emoji |
| `gargoyle_cherub` | Gargoyle Cherub 🗿 | **Garden Gargoyle** 🏛️ | a garden ornament come alive (like the gnome); self-heals as a tank elite |
| `rabid_roomba` | `5/5/5` flat | **flurry** (multi-hit 3×, then a 7) | kills the dullest pattern in the game |

## New enemies
| id | name | emoji | role | showcases |
|---|---|---|---|---|
| `wifi_router` | Possessed Router | 📡 | early/mid | `frail` + block, signal-jammer fantasy |
| `vending_machine` | Vengeful Vending Machine | 🥤 | mid/late | self-`heal` ("restocks") + block, attrition tank |
| `gym_rat` | Gym Rat | 🏋️ | elite | ramps Strength then **multi-hit** flurry — real elite mechanic |

## Second boss
| id | name | emoji | signature |
|---|---|---|---|
| `the_algorithm` | The Algorithm | 📱 | alternates **Feed** (heal + self-buff) and **Shadowban** (frail + drain Aura + big multi-hit). `boss()` now randomly picks between The Hater and The Algorithm so the act ending varies. |

## Pattern-distinctness pass
After this slice, no two enemies share an identical intent loop, every elite has a
signature verb, and both bosses have a phase-flavoured rhythm. Verified by the
combat test suite plus a montage render.
