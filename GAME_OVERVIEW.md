# Bahaya Jerebu! — game overview

A co-op Roblox game about Malaysia's haze crisis. Players are BOMBA firefighters who put out
forest and peat fires. Every fire left burning raises the shared **API (Air Pollutant Index)**,
and the world gets visibly hazier as it climbs. The haze is a real health crisis, so the tone is
**caring, not jokey**: fun to play, never mocking the people living through it.

- Roblox place: **Bahaya Jerebu!** (placeId `71624879418597`). Saved to Roblox, **not published yet**.
- Audience: kids and families in Malaysia; English + Bahasa Melayu text.
- New here? Read this file, then [`JEREBU_CONTEXT.md`](JEREBU_CONTEXT.md) (shared rules for everyone
  working on the place), then [`README.md`](README.md) (how files map to Studio).

## Core loop
1. **Day (240 s):** fires start in the forest and spread with the wind. Peat fires smoulder and
   reignite unless fully soaked.
2. Spray fires with the hose to earn coins. Refill water at hydrants and refill zones.
3. The API rises with every burning fire, plus haze blowing in from abroad. Higher bands thicken
   the haze, drain health outdoors, and close the school field (API > 100).
4. When the API stays above 150 for long enough, players can load the plane at the airstrip for
   **cloud seeding** (rain).
5. Between days: a report screen (story) or Night and Camp phases (survival).

The API bands are the official Malaysian ones. **Never change their names, numbers or colours:**

| API | Band | Health drain outdoors |
|---|---|---|
| 0–50 | Good / Baik | +1 HP/s (clean air heals) |
| 51–100 | Moderate / Sederhana | +1 HP/s |
| 101–200 | Unhealthy / Tidak Sihat | −0.4 HP/s |
| 201–300 | Very Unhealthy / Sangat Tidak Sihat | −1.0 HP/s |
| 300+ | Hazardous / Berbahaya | −2.0 HP/s |

Masks reduce the drain (an N95 cuts it by 70%). The BOMBA station heals +8 HP/s.

## Game modes
Players vote on the main menu. A tie goes to Story.

**Krisis 7 Hari (story, default).** Seven days of rising difficulty, then one of three endings
(clear / survived / emergency) based on the final API, with a coin bonus.

**Hari demi Hari (survival, endless).** Day (240 s) → Night (60 s) → Camp (20 s), repeated, with each
day harder than the last (formulas in `SurvivalRules.lua`).
- **How a run ends:** the whole crew is down at once, or the API stays Hazardous for a full day
  ("the town is evacuated").
- **Night:** embers start small fires near camp, and haze drain is halved. If the whole crew is
  resting at camp halfway through, the night is skipped and everyone gets +5 coins.
- **Camp Fund:** a bonus pot worth 25% of fire coins. It never taxes personal rewards. Spend it at
  the camp kiosk on:
  - Water Tower: faster refills.
  - Field Kitchen: the camp becomes a healing safe zone.
  - Rescue Shelter: faster revives and a longer downed timer.
- Full spec and remaining stages: [`design/survival-mode-handoff.md`](design/survival-mode-handoff.md).

## Multiplayer (up to 6 players planned)
- **Pings:** hold or tap **Q** (touch button / L1 on gamepad) to mark Fire, Water, Help or Follow.
  Spotting a fire that someone else puts out pays the spotter +3 coins.
- **Downed and revive:** at 1 HP a player collapses instead of dying. A teammate holds **E** for
  2.5 s to revive them (40 HP, +6 coins to the helper). If nobody comes, the player respawns at the
  station.
- **Shared rewards:** coins from a fire are split by how much each player sprayed it.
- **Co-op scaling:** more players means more fires (+50% spawns per extra player), with the fire cap
  at 22 + 3 per extra player, up to 34.
- **Crew panel:** shows each teammate's health, water and ride, and flags anyone who needs a revive.

## Progression and shop
Saved per player (DataStore `JerebuSave_v2`, session-locked; Studio uses `JerebuSave_v2_Studio`).
- **Upgrade tracks** bought with coins: tank size, range, nozzle, lungs, speed and more, each up to
  level 10.
- **Six hose tiers**, each with a fancier model.
- **Masks**, up to an N95.
- **Rides:** bicycle, kapcai and the BOMBA truck with a water cannon.
- **Premium (Robux):**
  - Game passes: Godspeed, Infinite Tank, Bomba Truck, VIP, 2x Coins.
  - Products: coin packs, Call the Rain, Server Boost.
  - Ids are `0` until they are created in the Creator Hub; Studio simulates them.
- **Rule:** we sell fun, speed and style, never safety. Masks, healing, the safe zones and revives
  by teammates are never paywalled. No paid random rewards.

## Tech layout
| Folder | What's inside |
|---|---|
| `src/` | All game scripts, mirroring Studio (Rojo-style names). Studio and `src/` must stay identical. |
| `src/ServerScriptService/` | `JerebuServer` (day loop, fires, API, spraying, health, pings, revive, survival), `Progression` (saves, shop, upgrades, rides, passes), `CampServices`, `CampUpgrades` |
| `src/ReplicatedStorage/Jerebu/` | `Config` (all tuning numbers), `UIStyle` (UI kit), `ImageAssets`, `SurvivalRules` |
| `src/StarterPlayerScripts/` | Client UI (HUD, ShopUI, HealthUI, CrewUI, PingUI, DownedUI, CampUI) and FX (HazeFX, RideFX, CrewFX) |
| `build/` | Scripts that rebuild the map, lighting, sounds, remotes and props from scratch |
| `design/` | Roadmap, economy, map contract, survival spec, shop item and image prompts |
| `reports/` | Progress reports and handoffs from each round, newest is `round7-night-camp-progress.md` |
| `assets/`, `ui-reference/` | Generated images, 3D world kit, and the UI style reference |
| `tests/` | Pure-rules tests for survival (run in Studio) |
| `browser-handoff/` | A separate browser spin-off prototype ("Hose and Havoc"); run `npm install` inside it |
| `.claude/agents/`, `.codex/agents/` | Role instructions for the AI agents (UI, VFX, tester, props, economy) |

**Debug switches (Studio only, workspace attributes):**
- `DebugAPI = n` forces the API.
- `DebugSkip = true` ends the current phase.
- `DebugCoins = n` gives everyone coins.

Clear them when you're done. **Never `require` a server module from the command bar:** it creates a
second copy that hijacks the remotes.

## Status and what's next
**Done:**
- The full story mode.
- Upgrades, shop and premium.
- Haze health.
- Multiplayer pings, revive and scaling, tested with 2 clients.
- Survival stages 1–3 (vote, endless days, Night/Camp, Camp Fund, three buildings).

**Still to do:**
- Set the player limit to 6. It is currently 60.
- Six-player stress test, real phone test, and a live save test on a published server.
- Fix the two images that fail to load (Water, BadgePeat).
- The remaining three camp buildings (Lookout Radio, Firebreak, Second Truck Bay).
- Daily events, leaderboards, milestone badges and Second Wind.
- Mini bosses and the "Sang Jerebu" boss (see [`design/roadmap.md`](design/roadmap.md)).
- Create the real Game Pass and Product ids, then publish.
