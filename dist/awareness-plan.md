# Performative Wizards — Awareness Plan (v1.2.0, June 2026)

**The one-line diagnosis:** itch's feeds amplify external traffic, they don't create it (Report 2). But your page currently leaks the traffic it gets — a cropped-to-garbage thumbnail, 3 tags, "(Playtest)" in the title, and a stale build. Fix the funnel in 48 hours, then spend the next 4 weeks engineering one 1,000-views-in-a-day spike via Reddit + YouTuber outreach, while the Demo Jam and devlogs bank freshness on itch.

---

## The 5 Highest-Leverage Actions (in order)

### 1. Fix the itch page TODAY (gates everything — traffic to this page is wasted)
The ~1% CTR has a mechanical cause: your cover is the 960×300 banner, and itch center-crops it to 315×250 in browse/search — players see a "TIVE WIZA" slice with no hook (Report 1). Do all of these in one sitting:
- **New 630×500 cover**: title + The Critic + a big grade stamp, legible at 315px. Keep the banner as the page header only. (This also fixes your broken og:image on social cards.)
- **Tags 3 → 10**: `roguelike-deckbuilder, deck-building, roguelike, roguelite, turn-based, singleplayer, godot, comedy, pixel-art, 2d`. Drop the manual "AI Generated" tag — the mandatory disclosure panel already covers honesty, and the tag opts you into the most-filtered tag on itch. You are currently absent from every tag page your audience browses, and a genre tag is required to appear in itch's "Recommended for you" widget at all (Report 2).
- **Rename to "Performative Wizards"** — "(Playtest)" is in the H1, SEO title, and every social card, contradicting "FREE DEMO" and "Released."
- **Upload v1.2.0 builds, add Windows + Linux.** The macOS zip says 1.1.1 a day after a content drop shipped. Windows is itch's biggest download audience; Godot exports make this nearly free.
- **Cut the empty "Loot Drop" screenshot** (it reads as unfinished), switch community from discussion board to **comments**, fix the singular "PERFORMATIVE WIZARD" in-game title before recapturing.

### 2. Publish the v1.2.0 devlog + trailer within 48 hours, while the freshness window is open
The page is days old — the best organic visibility it will ever have (Report 1). A v1.2.0-scale drop is exactly the kind of "major update" that can refresh your date for New & Popular (leafo, Report 2). Use the existing kit draft. Cut a 30–60s trailer from the raw .mp4 for the empty video slot, and put a grade-stamp GIF first in the gallery — the USP sells in 2 seconds of motion, zero seconds of reading.

### 3. Submit to The Demo Jam — open NOW, deadline July 7 (Report 3)
It explicitly accepts existing demos of in-development games; you only need a jam-exclusive thanks screen or easter egg. Near-zero effort, free jam-page visibility, and jams are itch's only built-in guaranteed-audience mechanism. Also: **mark Feedback Quest 9 (Aug 30 – Oct 5) in your calendar now** — indie streamers pick entries from that jam and stream them, which is a built-in pipeline for your exact bottleneck.

### 4. Run the Reddit ladder (the cheapest path to a spike, with hard numbers behind it)
Flufftopia: one niche-sub post tripled downloads/day; another solo dev got 1,000 itch views in a week purely from story-style posts (Report 2). Your perfect rule-fit subs: **r/WebGames** (free + browser + no signup = made for you), **r/playmygame**, **r/roguelites**, **r/Games Indie Sunday**, **r/godot**. Post r/DestroyMyGame *first* to pressure-test the fixed page. Exact titles in the calendar below. Prerequisite: r/WebGames requires a 7+ day account with 10+ comment karma — start commenting in these subs today.

### 5. Email 10–20 deckbuilder YouTubers (the only lever with breakout precedent)
Every breakout comp — Die in the Dungeon, Killer Chat!, Flufftopia — was streamer-driven; a single 30–60K-view video ≈ hundreds–thousands of plays (Report 2). Named targets with precedent (Report 3): **Retromation** (retromation750@gmail.com — his Bramble Royale demo video caused its biggest wishlist spike ever), **Olexa**, **Nookrium** (specializes in free/itch games), **Clemmy/Best Indie Games** (clement@thebestindiegames.com), **Wanderbots**, stretch: **Splattercat**. Pitch line:

> "Free 30–45 min browser roguelike deckbuilder where a rival Critic grades every fight S/A/B/C on screen and rewrites the run to spite your playstyle. The IRS is an enemy who garnishes 25% of your gold and flees. Nothing to install — link plays in browser. 3 GIFs + raw mp4 attached."

Personalize the first line per channel, link the browser embed, never attach a build.

**One honesty note that shapes channel picks:** your AI-assisted disclosure conflicts with some sub rules. **Skip r/IndieGaming** (explicit no-AI-content rule), post **text-only on r/slaythespire** (no AI art rule), and **read r/godot Rule 10 before posting** there. Plenty of channels remain.

---

## 4-Week Calendar

Pair every devlog with a same-day external post — the spike and the freshness reset compound (Report 2). Reply to every comment within hours on post days; "post and ghost" kills you on r/playmygame by rule and everywhere else by culture.

### Week 1 (Thu Jun 11 – Sun Jun 14) — Fix the funnel, bank freshness
| Day | Channel | Action / exact title |
|---|---|---|
| Thu 11 | itch page | All Action-1 fixes. Start Reddit karma-building (comment in target subs). Request membership at r/roguelikedeckbuilders (it's private; approval takes time). |
| Fri 12 | itch devlog + boards | Publish: **"v1.2.0 is live — The Critic now holds grudges"** (kit draft). Cross-post to itch **Release Announcements**: *"Performative Wizards — a roguelike deckbuilder where a rival Critic grades every fight S/A/B/C (free, browser, EN/DE/ES)"*. Post itch **Get Feedback** board: *"My demo page converts at ~1% — tear apart my cover/tags."* |
| Fri 12 | r/DestroyMyGame | **"Destroy my itch page: free browser roguelike deckbuilder, ~1% CTR — what's killing it?"** — let them validate/iterate the new cover before you spend traffic anywhere. |
| Sat 13 | Mastodon + Bluesky | #ScreenshotSaturday debut: stamp-slam GIF + *"she doesn't attack you. she reviews you. S/A/B/C, live, every fight."* #gamedev #indiedev #godot |
| Sun 14 | The Demo Jam | Add jam-exclusive easter egg screen, **submit the live demo**. |

### Week 2 (Mon Jun 15 – Sun Jun 21) — The spike attempt
| Day | Channel | Action / exact title |
|---|---|---|
| Mon 15 | Trailer | Cut 45s trailer from raw mp4 → itch video slot + YouTube upload. |
| Tue 16 | **r/WebGames** | **"Performative Wizards — free browser roguelike deckbuilder where a rival Critic grades every fight (S–C) and rewrites the run to spite your playstyle. 30–45 min runs, no signup."** (Title must start with game name; link directly to the itch HTML5 page.) |
| Wed 17 | YouTuber emails | Batch 1: Retromation, Olexa, Nookrium, Clemmy, Wanderbots, Splattercat. GIFs inline, browser link, trailer link. |
| Thu 18 | **r/playmygame** | **"[PC] (Web) Performative Wizards — my Critic NPC reviews your combat style live. Does the grading feel fair or rigged? Playable Link inside. Free browser demo, EN/DE/ES."** Then trade feedback on 3–5 other games (sub reciprocates; it's the rule). |
| Sat 20 | Mastodon + Bluesky | #ScreenshotSaturday: IRS-fleeing GIF + *"the IRS just garnished 25% of my gold and fled. I'm pressing charges (next run)."* |
| Sun 21 | **r/Games Indie Sunday** | **"[Indie Sunday] Performative Wizards — a roguelike deckbuilder where the final boss is a Critic who's been grading you the whole run (free browser demo)"** — verify current wiki rules first (Report 3 flags UNVERIFIED). Highest raw reach of the month. |

### Week 3 (Mon Jun 22 – Sun Jun 28) — Widen
| Day | Channel | Action / exact title |
|---|---|---|
| Mon 22 | Curators (one afternoon) | Submit to Alpha Beta Gamer, Free Game Planet (browser-games section), Jupiter Hadley, IndieGameBundles free section. |
| Tue 23 | itch devlog #2 + **r/roguelites** | Devlog: **"How the Critic decides your grade (and how to farm S-ranks)"**. Same day on r/roguelites with stamp GIF: **"I made a roguelike deckbuilder where a rival Critic grades every fight S/A/B/C live and rewrites your run based on how you play. The IRS is an enemy. Free browser demo."** |
| Thu 25 | **r/godot** | Promotion flair (check Rule 10 / AI policy first): **"Godot 4, solo dev: how I built a Critic that grades your fights live and rewrites the run (free browser demo)"** — systems breakdown in comments; Godot devs upvote tech, not ads. |
| Sat 27 | Mastodon + Bluesky + Shorts | #ScreenshotSaturday: Aura-finisher GIF. Publish **YouTube Short #1**: "This boss doesn't fight you. She reviews you." (30–60s, one mechanic — Report 2 favors Shorts over TikTok in 2026.) |
| Sun 28 | TIGSource | Open DevLog-board thread: **"Designing a Critic who reviews the player"** — design-essay style with images. Low traffic, high credibility + backlink. |

### Week 4 (Mon Jun 29 – Sun Jul 5) — Mechanics talk + meta-story
| Day | Channel | Action / exact title |
|---|---|---|
| Mon 29 | YouTubers | One polite follow-up to batch 1; batch 2 of 8–12 micro channels (1K–10K CCV — 2026 guidance favors them for burst lifts). |
| Tue 30 | **r/slaythespire** | TEXT post, no images, link in a comment: **"StS players: would a boss that reviews your runs work? My game's Critic grades every fight, and the Talent Agent boss books weaker versions of the other bosses against you. Looking for design opinions."** Engage genuinely — this sub loves mechanics talk. |
| Thu Jul 2 | r/IndieDev | Story post: **"My free demo got almost no plays, so I rebuilt the entire itch funnel — here's what a 1% CTR taught me"** (with before/after covers + numbers; story posts are the proven format here). |
| Fri Jul 3 | itch devlog #3 | **"Designing The IRS: why the dumbest enemy does 25% of my marketing"** |
| Sat Jul 4 | Mastodon + Bluesky + Shorts | #ScreenshotSaturday + **Short #2**: "The IRS is an enemy in my game. It takes 25% of your gold and leaves." |
| Sun Jul 5 | Review | 4-week decision checkpoint (rules below). Confirm Demo Jam submission is in before the **Jul 7 deadline**. |

Ongoing habits: ~15 min/day replying to comments everywhere; #ScreenshotSaturday weekly forever (it's free); itch Discord #share-your-work once, then participate.

---

## Asset List (produce in this order)

| # | Asset | Spec | Used where |
|---|---|---|---|
| 1 | **New cover** | 630×500, title + Critic + grade stamp, readable at 315px | itch cover + og:image — the single biggest CTR lever |
| 2 | **GIF: Critic stamp slam** | 3–5s, the grade slamming down | itch gallery slot 1, Bluesky/Mastodon, r/roguelites, every YouTuber email |
| 3 | **GIF: The IRS garnishing 25% and fleeing** | 5–8s, with the flavor text visible | ScreenshotSaturday wk2, Short #2, emails — the comedy proof |
| 4 | **GIF: Critic rewriting the map after a grade** | 10–20s, the USP in motion | r/WebGames, Indie Sunday comment, devlog #2 |
| 5 | **GIF: Aura-tier finisher cash-out** | 3–5s | ScreenshotSaturday wk3, itch description inline |
| 6 | **45s trailer** | cut from existing raw .mp4; grade stamp in first 3 seconds | itch video slot (currently empty), YouTube, all pitch emails |
| 7 | **6–8 reshot screenshots** | Critic verdict close-up, boutique/fits, map across acts, Angry Toaster or IRS, character select with all 3 wizards unlocked + fixed title | itch gallery (order = argument; delete the empty Loot Drop shot) |
| 8 | **2 YouTube Shorts** (vertical) | re-edit trailer footage, one mechanic each | Weeks 3–4 |
| 9 | **Pitch email template** | the one-liner above + 3 GIFs + browser link + key art | YouTuber + curator outreach |
| 10 | **In-game "enjoyed it? rate on itch" link** on the end-of-run grade screen | small build task | the ratings flywheel — ratings feed itch's Popular signal and you currently have zero |
| 11 | **Jam easter-egg screen** | per Demo Jam rules | Demo Jam entry |

---

## Devlog Cadence + Next 3 Topics

**Cadence: one devlog every 2 weeks, always published the same day as an external traffic push** (devlogs amplify traffic you bring; with few followers they generate little alone — Report 2). Write player-facing, not dev-facing. Every devlog ends with: "Free, plays in browser in seconds — and if the Critic gave you an S, rate us on itch."

After the v1.2.0 launch post ("v1.2.0 is live — The Critic now holds grudges"):
1. **"How the Critic decides your grade (and how to farm S-ranks)"** — strategy bait; pairs with r/roguelites.
2. **"Designing The IRS: why the dumbest enemy does 25% of my marketing"** — comedy/design essay; pairs with r/IndieDev.
3. **"Every sprite and sound in this game is generated — the Godot 4 pipeline"** — pairs with r/godot and TIGSource; owns your AI/procgen story on your terms instead of letting a disclosure panel tell it.

Save the **next major content-drop devlog for the Oct–early-Nov window** (Halloween/Autumn Sale + Creator Day — itch's biggest sitewide traffic period, Report 2), publish early-week so the freshness window overlaps the weekend.

## Jam Strategy
- **The Demo Jam (now – Jul 7):** submit the existing demo this week. Trivial effort, mandatory.
- **Feedback Quest 9 (Aug 30 – Oct 5):** enter the demo. Indie streamers pick entries from the jam to stream — a free streamer pipeline aimed at exactly your bottleneck. This is your second-biggest beat of the year; build the next content drop's timing around it.
- **GMTK 2026 (Jul 22, ~17k participants):** *only if you have 4 spare days* — a micro-spinoff ("The Critic Judges X") whose page funnels to the main demo. Die in the Dungeon and Peglin were born as jam entries; jams are also how you accrue the followers that make devlogs work. Godot Wild Jam (monthly) and GitHub Game Off (Nov) are lower-priority alternatives. If time is tight, skip new-game jams entirely — the demo-friendly jams above are better effort-for-impact.

## Measurement Loop (every Monday, 15 minutes)

Watch in itch analytics: **views/week, browser plays/views ratio, downloads, referrers, followers, ratings count**, plus thumbnail CTR from browse impressions.

Decision rules:
- **CTR still ≤ ~1.5% two weeks after the new cover** → the cover failed; iterate using r/DestroyMyGame feedback, test a variant with a bigger stamp/face.
- **Plays/views < 30%** (benchmark: browser games convert 37–45% of viewers to players) → page/embed problem (load time, first gallery item, description wall) — fix before sending more traffic.
- **Any referrer drives 200+ views** → that community works; schedule the milestone repost (r/WebGames allows reposts for "substantial updates"; r/playmygame resets monthly).
- **A 1,000+ view single day** = real signal (Zukowski's threshold) → immediately email YouTubers citing the spike, ship a devlog same day to ride New & Popular's recency component.
- **A YouTuber covers it** → same-day devlog + pinned thanks, reply in their comments, clip their reaction for socials.
- **< 10 ratings after 4 weeks** → strengthen the in-game end-of-run rating ask.
- **No spike after 4 weeks** → don't churn harder on the same posts. Shift to slow-burn: Feedback Quest 9 (Aug 30), the Oct seasonal devlog, an optional GMTK spinoff — and start a Steam page so future spikes bank wishlists, since itch traffic is bursty and decays.

## Honest Expectations
- Median itch game **lifetime**: 1,582 views / 590 browser plays / 113 downloads (HTMAG 2025 benchmark). You being free + browser-playable gives ~3x engagement vs download-only — that's your structural edge.
- A realistic *good* outcome for these 4 weeks: **2,000–5,000 views, one spike day, 50–150 followers, 10–25 ratings** — i.e., climbing from below-median toward the 70th percentile (12K views / 5K plays) over a few months, mostly off 2–3 Reddit posts that land.
- The 10x outcomes (Die in the Dungeon: 1.4M views; Killer Chat: 645K) were all **streamer/jam lottery tickets on top of exactly this kind of groundwork** — "99% organic, YouTubers just found the game." You can't schedule that; you can only keep buying tickets: every YouTuber email, every jam entry, every clip-able GIF. The plan above maximizes tickets per hour of solo-dev time.
