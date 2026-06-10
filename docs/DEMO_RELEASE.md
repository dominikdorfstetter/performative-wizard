# Performative Wizard — First Public Demo Release Plan

> Produced 2026-06-10 from a 10-agent audit (6 dimensions: art consistency, first-session
> UX, game feel, release ops, product scope, runtime QA with rendered screenshots) plus a
> 3-lens prioritization panel (new player / streamer-marketability / shipping engineer)
> and a completeness critic. 194/194 headless tests green at audit time. Owner decisions
> recorded below; this file is the working plan. Companion to `ROADMAP.md` (completed
> pre-USP plan) and `USP.md`.

**Goal:** a stranger can find the demo, boot it in under a minute, understand the Aura +
Critic loop in fight one, lose a run at minute ~35 feeling like they made progress, and
know where to follow the game — on a build that looks intentional on every screen.

## Decision record (owner-confirmed 2026-06-10)

| Decision | Call |
|---|---|
| Timeline | **2–3 weeks** to launch |
| Platforms | **itch.io web (primary) + macOS zip** (Windows noted for next cut) |
| Emoji strategy | **Finish the emoji→pixel sweep** on all ~70 remaining strings **+ bundle a CC0 pixel font** as default theme |
| Mid-run save | **Map-snapshot save** (save at map entry only; no combat-state serialization) |
| Enemy-turn feel | **Rewrite as sequenced coroutine in week 1**, gated on tests + balance sim |
| Onboarding | **Full first-fight layer**: 3-beat callout + Critic intro + grade tooltip + verdict "because" clause |
| Unlock pacing | **Retune for demo**: Necro 120→**70**, Rizz 320→**180** lifetime Clout (data-only, revertable) |
| Feedback CTAs | **itch page link + Discord invite + GitHub issues** (via `OS.shell_open`, works on web) |
| License (default) | Explicit **all-rights-reserved** notice + Godot MIT third-party notices in both artifacts |
| DE/ES (default) | **Complete coverage** restored during the sweep (tooltip layer + flow strings); keep the EN/DE/ES claim |
| Difficulty | **Unchanged.** Act-1-clear-then-die-in-act-2/3 is correctly StS-shaped; react to real itch comments only |

---

## Week 1 — Destabilizing work first + the build pipeline

Riskiest changes land NOW so they soak under 2+ weeks of playtesting. Everything here is
gated on `godot --headless scenes/test_combat.tscn` staying green (194) and a balance-sim
re-run for the combat change.

### 1.1 Commit art pass 5 + its loc regression fix · S
- Commit `scripts/ui/{chest,node_ui,shop}.gd` atomically (the icon_tex mechanism is the
  foundation for the whole sweep; runtime-verified working).
- Fix the regression it introduced: `shop.gd:40` hardcodes `"%d gold"` with no DE/ES key —
  use the `Loc.t(template) % args` pattern.

### 1.2 Enemy-turn sequencing (the feel rewrite) · M — **gated**
The single biggest "unfinished vs StS" tell: `_enemy_turn()` (combat_manager.gd:484-516)
resolves every enemy synchronously in one call stack — "THEIR TURN" never renders, enemies
never telegraph, multi-enemy damage collapses into one instant number.
- Make `_enemy_turn()` a coroutine: emit after each enemy's intent resolves, `await` ~0.45s
  between enemies; guard `end_turn()` against re-entry.
- UI: lunge the acting enemy toward the player (mirror of `_lunge`); per-enemy damage
  numbers, blocked-hit feedback (`BLOCKED N` float + clink when block fully absorbs), and
  multi-hit readability fall out of the per-action emits for free.
- **Gate:** 194 tests green (add an await-aware test path if needed) + balance sim within
  noise of pre-change numbers. If not green in 3 days, revert and ship synchronous (the
  demo does not die on this; it dies on the pipeline items below).

### 1.3 Map-snapshot run save + schema version · M — **gated**
- Serialize run state at map entry only: wizard_id, deck, card_upgrades, map array, pos,
  act, hp, gold, artifacts, critic fields (all plain data on GameState). Hooks:
  `GameState.enter()` (game_state.gd:355) to write, `finish_run()` (game_state.gd:473) to clear.
- Add `save_version: 1` to `save_meta()` (game_state.gd:561) **before any public saves exist**.
- Main menu "↻ Continue" becomes a real **Resume run** when a snapshot exists (today it
  silently routes to class_select and discards the run — main_menu.gd:225-228, 261).
- Headless tests: save→load→identical state; corrupt snapshot degrades to meta-only (the
  existing graceful corrupt-save path at game_state.gd:533-535 is the model).

### 1.4 Build pipeline & branding (the minute-0 blockers) · M
- **Fix macOS signing:** `codesign/codesign=0` keeps the Godot template's Developer ID
  signature with unsealed resources → verified locally: Gatekeeper says *"damaged, move to
  Trash"* with no Open-Anyway path. Switch the preset to **ad-hoc signing**, re-export,
  verify `codesign --verify --deep --strict` + `spctl -a` pass to the recoverable
  "Open Anyway" flow. Rewrite README/itch instructions for the macOS 15 Sequoia flow.
- **Identity:** render a 1024px wizard from SpriteBank once → `application/config/icon`,
  `boot_splash/image` + bg matching the UI's dark violet, macOS preset icon, regenerated
  .icns, web favicon + loading image (kills the Godot robot / white "GODOT" splash).
- **Web preset:** commit it to `export_presets.cfg` with **threads OFF** (matches the
  current build — index.html:115 — so itch needs no SharedArrayBuffer headers).
- **Version identity:** `application/config/version = "1.1.0-demo"`; render it in the menu
  footer via `ProjectSettings.get_setting()`; bump the macOS preset's hardcoded "1.0".
- **Web correctness:** hide "✕ Exit Game" behind `if not OS.has_feature("web")`
  (main_menu.gd:268 is a dead end in an iframe). Keep itch's default click-to-run launch
  button — the click is the user gesture that unblocks browser audio autoplay.
- **Browser-boot the web build once now** (private itch draft): verify boot, time the
  audio-synthesis freeze (audio.gd builds 5 tracks sample-by-sample in `_ready`; ~1.1s
  native). Only if web shows a multi-second frozen canvas: defer non-menu track synthesis
  via `call_deferred` chain / WorkerThreadPool.

### 1.5 Pixel font + sweep foundations · M
- Bundle one CC0 pixel font (m5x7 / Pixel Operator) as the project default theme font —
  kills both the web-tofu correctness bug and the "default Open Sans over pixel art"
  engine-template tell in every screenshot.
- Define a 4-step type scale in node_ui.gd (TITLE 36 / HEADING 22 / BODY 16 / CAPTION 13);
  sweep the ~20 ad-hoc `font_size` overrides onto it.
- Add the missing 16×16 SpriteBank icons the sweep needs (door, boot, moon, scissors,
  question, coin, crown, heckler…).

---

## Week 2 — The player-facing layer

### 2.1 Finish the emoji→pixel sweep · M
~70 UI occurrences, worst-first (full inventory in the audit): event.gd (7 "❓" titles +
13 choice icons), rest.gd, shop.gd/chest.gd titles + 💰, class_select (❤/🔥/🔒), reward.gd
critic/loot lines, main_menu glyph buttons (▶ ⚙ ✕ ↻), combat floats (🛡 💸 🎤 📉),
"Bye ✌" → pixel icon + literal **"End Turn"** anchor, "BIG L 💀", map trend labels
(game_state.gd:455-457), 3 card descriptions (wink/finger_guns/ember .tres).
- **Triple-edit every string**: EN source + loc_de + loc_es (46 emoji-keyed entries each)
  in one pass, or DE/ES silently fall back to English.
- Restore full DE/ES while in there: the entire tooltip teaching layer (13 status descs,
  energy/aura/gold tips, intent lines — combat_ui.gd:27-42, 249-264, 1012/1039) has **zero**
  DE/ES entries; plus map header, shop pre-formatted strings, death/victory strings.
- Add a headless test: every `Loc.t("...")` literal in scripts/ has a key in both tables.
- Banter/quips keep flavor emoji **only if** the bundled font renders them (verify on web);
  otherwise rewrite to slang-only.
- Disambiguate ✦ (today it means Clout, Aura income, upgrade, AND decoration): pixel star
  = Aura, distinct gem = Clout, ✦ reserved for decoration.

### 2.2 Onboarding: the first-fight layer · M
- One-time dismissible 3-beat callout in `combat_ui._start_fight()` (line 155), gated by a
  persisted `seen_tutorial` bool: (1) energy + hand, (2) Aura bar + 6/12/18 thresholds,
  (3) the Critic introduces herself — *"I'm reviewing this. Light the tiers, cash out a
  finisher, impress me."*
- Grade-criteria tooltip on the `THE CRITIC B` label (the only HUD element without one).
- "Because" clause on her reward verdict from the rating dict (`peak_swag`,
  `thresholds_lit`, `finisher_clean` are already returned — combat_manager.gd:436-446).
- Targeting discoverability: hover-highlight enemy widgets + tooltip on the ▼.
- Map micro-legibility: "badge = number of enemies" in the legend; label or tooltip the
  header's bare "Critic N".

### 2.3 USP ceremony — make the Critic visible · M
- **Reward screen stamp:** big letter-grade slam (scale 3.0→1.0, TRANS_BACK, S gold / A
  green / C red, crowd sting for S/A, jeer for C) replacing the unnoticed text line
  (reward.gd:21-27).
- **Map rewrite made visible:** `critic_note` is written (game_state.gd:432-439) but has
  ZERO UI readers. Badge candidate nodes with crown/heckler pixel icons while
  `pending_critic` is set; heckler gets a drop-in beat + Critic barb at combat start;
  "VIP +20g" becomes its own reward line.
- This is the trailer shot the store page sells — it must exist before assets are captured.

### 2.4 Run-end screens (death AND victory) + the funnel · M
- Replace both `_on_combat_ended` exits (combat_ui.gd:1163-1176): death panel shows
  **+N Clout (lifetime M)**, an unlock-progress bar ("✦ 52/70 — Morticia unlocks soon"),
  newly unlocked cards/relics (computed today, never announced), the Critic's final word,
  and **"Run it back"** (correctly labeled). Victory gets a real recap: acts cleared, grade
  history, her closing review.
- CTAs on both + menu footer: itch page, Discord invite, GitHub issues (`OS.shell_open`).
- Act-1-clear interstitial (combat_ui.gd:1159-1162): act number + the Critic's act review;
  the one-time "enjoying it? follow on itch" line lives here (most players see act-1 clear;
  most never see act-3 victory).
- Unlock retune (data-only): necro.tres 120→70, rizz.tres 320→180.

### 2.5 Confirmed-bug sweep · S (bundle, ~1 day)
All render-verified:
- Reward cards permanently shrink after one hover — CardView._hover tweens to absolute
  scale vs reward.gd's 1.45 pre-scale (reward.gd:47-48, card_view.gd:125-131). Store base
  scale in meta or scale a holder Control.
- Map bottom node row overlaps the legend (BOT=600 circles vs legend y=610 — map_ui.gd:33,162).
- Shop artifact price renders on the panel border (shop.gd:40 desc packing vs fixed 300×178
  button) — price as its own label like the card stalls.
- Untextured square particles drift over "THE CRITIC" / turn banner reading as dead pixels
  (combat_ui.gd:582-615) — texture them, cap travel below the HUD band, drop alpha.
- Hand cards clip at the bottom screen edge; boutique row 3 slices mid-card under the Back
  button (add bottom padding/fade + "↓ more" hint).
- Stock-gray `pressed`/`disabled` styleboxes on End Turn, defeat-panel, map deck button,
  ascension arrows; unify on the NodeUI stylebox family.
- class_select shows two different Clout numbers under one ✦ glyph — "to spend" vs
  "lifetime ✦ 124/320" progress bar on the locked card.
- Guard the 5 unguarded `Database.get_*().title` chains in event.gd (31/54/89/104/125).

### 2.6 Quit/resume safety & input · S
- Esc pause overlay on map + combat (resume / options / abandon-run-with-confirm; reuse the
  `_show_deck()` overlay pattern). The map currently has NO exit besides force-quit.
- Global fullscreen handling in one autoload (today F11 works on 2 of ~10 screens, collides
  with macOS Show Desktop and browser F11); persist the fullscreen setting (options.gd:35-39
  never saves it); platform-aware hint text (Cmd+Ctrl+F on macOS, hidden on web).
- Space/Enter = End Turn.
- Locale auto-detect on first boot: `OS.get_locale_language()` when no save exists (~4
  lines in load_meta; DE/ES players currently boot into English forever).

---

## Week 3 — Feel pass, accessibility, release cut

### 3.1 Transitions & music handoff · S
- ~30-line `Fader` autoload (black fade 0.15s) across all 20 hard-cut
  `change_scene_to_file` sites.
- Music: `play_music("menu")` on reward + class_select (combat/boss music currently blasts
  over the reward screen, the death panel, and the post-run hub); crossfade in audio.gd
  (tween volume_db, swap, tween back); stop music + somber beat on defeat.
- Hoist the existing 0.9s finisher victory delay to ALL wins + "BIG W" banner (normal kills
  currently hard-cut to reward on the killing-blow frame).
- Defeat moment: kill the idle bob, tint/collapse the wizard, fade the panel in after the sting.

### 3.2 Selective juice (timeboxed to what fits) · S each
Priority order: HP-bar tweening + gold count-up → SFX on silent interactions (map node
entry, wizard pick, reward take, chest reveal sting, boutique unlock fanfare, event
outcomes) → reward-card stagger-in + chest two-beat open + elite loot using chest's panel →
available-map-node pulse + "you are here" marker → hand rebuild diffing (kills the
hover-blink + bob restart) → unaffordable-card shake + energy pulse. Anything that doesn't
fit moves to demo v1.1 without guilt.

### 3.3 Accessibility & options · S
- "Screen shake & flash: On/Off" toggle (full-canvas 16px shake + full-screen red hurt
  flash currently have no off switch), persisted via save_meta like sfx_on.
- Music/SFX volume sliders on dedicated buses (synth audio is piercing on stream).
- "Best played with a mouse" note on the itch page (tooltips never fire on touch).

### 3.4 Release engineering · S
- `RELEASE.md` smoke checklist: commit-clean → tests 194 green → re-export macOS+web from
  HEAD → `codesign --verify` + `spctl -a` pass → fresh-profile boot → each wizard → options
  toggles persist → web boot on private itch draft → Gatekeeper open on a clean Mac.
- GitHub Action: headless test suite on push.
- LICENSE: explicit all-rights-reserved + Godot MIT notices (THIRDPARTY.txt) in the zip and
  on the page; README.txt with Sequoia Gatekeeper steps inside the macOS zip.
- README refresh: 194 tests, web demo link above the design links, correct Gatekeeper flow.

### 3.5 Launch · M
- Re-export both targets from clean HEAD; tag `v1.1.0-demo`; replace the stale v1.0.0 link
  (today's public download ships pre-Block-fix!).
- itch page kit, captured LAST so assets show the fixed game: 630×500 cover from SpriteBank
  art; 3–5 screenshots; lead GIF = FINALE cash-out; second GIF = Critic stamp → map badge
  rewrite; headline **"She's watching. Serve looks or get reviewed."** (adopt in-game as the
  menu subtitle too); embed at 1152×648; "runs save at the map; unlocks persist" note;
  Gatekeeper instructions in the description.
- Launch order: private itch draft → full smoke checklist → public.

---

## Explicitly cut (decided, not forgotten)
- **Full combat-state serialization** — map-snapshot covers the demo; revisit post-demo.
- **122-color palette consolidation** — invisible at streaming bitrate; collisions are fixed in 2.5.
- **Per-artifact unique sprites** — tinted silhouettes pass at 1080p.
- **"Chill mode" / difficulty softening** — react to real itch comments only.
- **Windows/Linux presets** — noted in RELEASE.md for the next cut.
- **Draw/discard counters + inspect overlay** — first post-demo patch (the one genre nicety
  a streamer may name-check; below the line at this budget).
- **Dressing-room layout redesign** — functional; on camera <1 min/run.
- **Headless preview-tool hang + ObjectDB exit warning** — dev tooling.

## Definition of done per slice
Code/data change → 194 headless tests green (+ balance-sim re-run for combat-touching
work) → windowed preview PNG of affected screens → focused commit → builds re-exported
only at release cut, from clean HEAD, via RELEASE.md.
