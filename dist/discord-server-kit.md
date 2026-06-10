# Discord server kit — Performative Wizards

Everything to set the server up in ~15 minutes. Assets live in
`dist/discord/`: `server-icon.png` (512×512), `server-banner.png` (960×540,
needs boost level 2 to display), `invite-splash.png` (1920×1080, boost level 1).

## Identity

- **Server name:** Performative Wizards
- **Icon:** `dist/discord/server-icon.png` (Vesper + star on the dark frame)
- **Banner / invite splash:** the three wizards from the boot splash
- **Server description** (Settings → Overview, also used for discovery):

  > She's watching. A roguelike deckbuilder where a rival Critic grades every
  > fight live — S, A, B or C — and rewrites the road ahead. Bank Aura, serve
  > looks, win the room. Demo out now on itch.io — free, in the browser.

- **Vanity/invite note:** pin the itch link everywhere; the demo IS the funnel.

## Channel structure

**📌 INFO** (read-only for everyone except mods)
- `#welcome` — what the game is, the itch link, rule summary, role menu.
  Post the two launch GIFs (FINALE cash-out, Critic stamp) here.
- `#rules` — see template below.
- `#announcements` — releases, patch notes, devlogs. (Enable the
  "Announcement channel" type so other servers can follow it.)

**🎮 THE GAME**
- `#general` — main hang. Default landing channel.
- `#strategy` — builds, archetypes, ascension talk. ("how do I S-rank?")
- `#fits` — screenshot channel: outfits, FINALE banners, S-stamps. (Images on.)
- `#bug-reports` — pin the format: platform / version (bottom-left of menu) /
  what happened / expected. Link the GitHub issues page; mods triage weekly.
- `#suggestions` — feature wishes. React-vote with ⭐.

**🧪 DEV** (visible to all, posting for @Dev)
- `#devlog` — work-in-progress shots, balance-sim numbers, design notes.
- `#beta-keys` — (later) build access for the @Playtester role.

**🔊 VOICE**
- `Green Room` — general voice.
- `Spotlight` — streaming/playtest sessions (enable Activities).

## Roles

| Role | Colour | How it's given |
|---|---|---|
| @Dev | pink `#ff4fb3` | you |
| @Mod | gold `#ffd24a` | hand-picked |
| @Playtester | purple `#8a5bd0` | hand-out in #beta-keys later |
| @Wizard | default | auto on join (everyone) |
| @S-Tier | gold | fun vanity role for first S-rank screenshot in #fits |

## Rules template (`#rules`)

1. **Be kind.** The Critic is the only one allowed to be mean here, and she's
   fictional. No harassment, slurs, or gatekeeping.
2. **Keep it PG-13.** The game is family-friendly; the server is too.
3. **Spoiler-tag** late-act content (`||like this||`) for the first month
   after any release.
4. **Bugs go to #bug-reports** (or GitHub) — they get lost in #general.
5. **No self-promo** without asking a @Mod first.
6. Mods may remove anything that breaks the vibe. Appeals via DM to @Dev.

## Onboarding (Settings → Onboarding)

- Default channels: `#welcome`, `#general`, `#fits`.
- Question 1: "What are you here for?" → Strategy (#strategy), Showing off
  fits (#fits), Bug hunting (#bug-reports), Just vibing (#general).

## Settings checklist

- [ ] Verification level: **Medium** (registered >5 min) — keeps drive-by spam out.
- [ ] Explicit content filter: **all members**.
- [ ] Community features: ON (unlocks welcome screen, discovery, announcements).
- [ ] Create the `#welcome` post, pin the itch + GitHub links.
- [ ] Upload icon + splash assets.
- [ ] Create an **invite that never expires** → this URL goes into
      `GameState.LINK_DISCORD` before the release export (empty string hides
      the in-game button until then).

## Launch-day post (paste into #announcements)

> **The demo is LIVE.** 🎭 *(server emoji, not in-game — the game's font has no emoji)*
> Performative Wizards — the roguelike deckbuilder where the Critic reviews
> your every fight — is free in your browser, right now: **[itch link]**
> EN / Deutsch / Español · macOS build on the same page.
> Post your first grade in #fits. She's watching.
