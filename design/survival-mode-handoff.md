# Survival mode — "Hari demi Hari" — build spec for Codex

**Codex round 7 (18 October 2026):** Night/Camp, Camp Fund and the Water Tower, Field Kitchen and Rescue Shelter upgrades are implemented. Read `reports/round7-night-camp-progress.md` for exact scope, two-client multiplayer evidence, save status and remaining checks. This supersedes earlier statements that those stages are unbuilt.

**Implementation update, 18 October 2026:** Stage 1 is implemented; see `reports/round6-survival-progress.md` for scope/tests. The user approved immediate survival access, 240-second days, and immediate crew-down ending. Sections describing later stages remain specifications, not completed features. Survival currently uses the existing Report phase between days until Stage 2 adds Night/Camp.

Read first: `JEREBU_CONTEXT.md`, `reports/claude-to-codex-handoff.md`, `design/roadmap.md` §3.2,
`design/MAP_CONTRACT.md`. This is the plan for the second game mode; **only Stage 1 is built so far**.

## 1. The pitch
Survive the haze season day by day with your crew, until everyone has collapsed.
Inspired by the day-by-day rhythm of "99 Nights in the Forest" (our own design: tropical forest,
haze and firefighting, **no monsters copied**). Story mode ("Krisis 7 Hari", 7 days, 3 endings) stays
as is and stays the default; survival is a second mode.

## 2. How a run works
1. **Lobby/Intermission:** players vote STORY or SURVIVAL on the main menu (majority wins, ties → story).
2. **Day N** (same 240 s firefight as story, harder each day) → **Night N** (60 s, see §5) →
   **Camp phase** (20 s: spend the Camp Fund, see §4) → Day N+1.
3. The run **ends** when either:
   - every player is collapsed at the same time (downed or respawning) — "the crew is down", or
   - the API stays ≥ 300 (Hazardous) for a full day — "the town is evacuated".
4. **Results screen:** days survived, fires out, revives, best day, rewards; then back to the vote.

Individual collapse is NOT the end: the existing downed/revive system (`Downed`, `RevivePrompt`)
applies. In survival the respawn timer after passing out grows: `10 + 2 × day` seconds (cap 60),
during which the player spectates the crew.

## 3. Difficulty curve (endless)
Story uses `Config.Days[1..7]`. Survival generates day settings from day number `d`:

| Setting | Formula | Notes |
|---|---|---|
| `spawnEvery` | `max(6, 26 × 0.93^(d−1))` s | → 15 s by day 9, floor 6 s |
| `burst` | `min(12, 2 + floor(d / 2))` | before co-op scaling |
| `peat` | `min(0.6, 0.15 + 0.03 × d)` | |
| `wind` | `min(2.0, 0.8 + 0.06 × d)` | spread multiplier |
| `haze` (transboundary API per day) | `min(60, 8 + 3 × d)` | rises regardless of players |
| fire growth | `Config.FireGrowth × min(1.6, 1 + 0.03 × d)` | |
| spawn radius | day 1–2: 360 · 3–5: 520 · 6+: whole map | reuse `spawnRadius()` idea |

Co-op scaling (`Config.CoopSpawnPerPlayer`) and `maxFires()` apply on top, as in story mode.
Every **10th day** is a "milestone day": +30% fires, and (later phase) a boss.

## 4. Camp Fund + camp buildings (uses the Kem Bomba Rimba camp)
- **Camp Fund** = 25% of every coin the crew earns from fires goes into a shared pot
  (players still get 100% of their personal reward — the fund is a bonus, not a tax).
- During the Camp phase any player can spend the fund at the **camp kiosk** (CampServices already
  validates that prompt). Buildings reset every run, so each run has its own build path:

| Building | Cost (fund) | Effect | Fits |
|---|---|---|---|
| Water Tower | 300 | camp refill rate 30 → 60, +1 refill zone at camp | existing camp water tower model |
| Lookout Radio | 400 | fire markers +60 studs range in haze for everyone | camp lookout |
| Rescue Shelter | 500 | revives take 1.2 s instead of 2.5; downed timer +10 s | rescue shelter |
| Firebreak (per sector) | 350 | trees in one chosen sector can't catch spread for the next day | trail posts / new sector |
| Second Truck Bay | 800 | a crew truck anyone can drive (no pass needed) for that run | BOMBA / camp court |
| Field Kitchen | 250 | everyone at camp heals +4 HP/s (camp becomes a second safe zone) | pavilion |

All effects are server-side and read by existing systems (refill zones, marker range attribute,
`Config.Revive`, safe zone). Models: reuse `ServerStorage.KemBombaKit`; show "built" vs "not built"
by toggling visibility/transparency, never by creating untracked parts every run.

## 5. Night phase (60 s)
- Darkness (ClockTime 20 → 4, Atmosphere darker) + embers carried by the wind start **small fires
  within 150 studs of camp** (2 + floor(d/3) of them).
- Haze drain continues at half strength at night; camp/station are safe.
- If all players are inside the camp/station area when the night timer hits 30 s, the night is
  skipped ("the crew rests") — rewards everyone +5 coins.
- Mosquito/creature attacks: **no** (keep it about fire and haze).

## 6. Daily events (one random per day from day 3)
Wind shift mid-day · dry lightning (3 fires at once in one sector) · villager rescue (escort an NPC
from a stilt house to camp; +40 fund) · broken hydrant (one refill zone off for the day) · free
cloud seeding offer · haze surge (+40 API at noon). Event name shows on the day pill.

## 7. Rewards, leaderboards, monetization (fair)
- Coins as in story, plus **+20 coins per day survived** at run end (×CoinMul), milestone badges at
  days 10 / 25 / 50 / 99.
- Leaderboards (OrderedDataStore): **most days survived** solo, and best crew run (store the best per
  player). Show top 10 on a board in the lobby/station.
- Upgrades, hoses, rides, cosmetics carry over from story mode; camp and run progress do not.
- **Second Wind** (product, 49 R$): revive yourself once per run. Also earnable: one free Second Wind
  per 10 days survived. Never sell anything that prevents the run from ending.

## 8. Where it hooks into the code
`ServerScriptService.JerebuServer`:
- `runGame()` (~line 1202) currently does: intermission → `for day = 1, Config.TotalDays do runDay(day) end`
  → ending. Add a mode branch: `if mode == "Survival" then runSurvival() else <current story loop> end`.
- `runDay(day)` (~line 1096) reads `Config.Days[day]`. Refactor it to take a `cfg` table
  (`runDay(day, cfg)`), so story passes `Config.Days[day]` and survival passes `survivalDayCfg(d)`.
  Keep story behaviour byte-identical apart from that refactor.
- `stepAPI()` uses `dayCfg.haze`; `stepFires()` uses `dayCfg.wind` — both come from the same cfg.
- Run-end checks live in the per-player loop / a new 1 s survival watcher: count players with
  `Downed` or dead; track seconds at API ≥ 300 per day.
- Night phase: new `runNight(day)` with `countdown("Night", 60, tick)` — add `"Night"` and `"Camp"` to
  the phases clients understand (HUD shows "Night falls" / "Camp").
- New workspace attributes for clients: `Mode` ("Story"/"Survival"), `SurvivalDay`, `CampFund`,
  `DayEvent`, `CampBuilt_<Building>` (bool), `RunOver` (bool).
- Progression: add `Progression.addCoins` usage for the fund split (server-side only) and a
  `SecondWind` product in `Config.Products` handled in `grantProduct` (stores a per-run flag, not saved).
- Leaderboard: new module `ServerScriptService.Leaderboards` (OrderedDataStore, Studio-only store name
  ending `_Studio`, like `JerebuSave_v2_Studio`).

UI work (ui-designer or Codex): mode vote on the main menu; day pill shows "HARI 12 · Survival" + event;
Camp Fund + build menu at the kiosk (reuse ShopUI kit styles); night/camp phase banners; results screen
with days survived; spectate camera while respawning; leaderboard board model in the station.

## 9. Build order (each step playable and tested)
1. Mode flag + vote + `runDay(day, cfg)` refactor + endless day loop + run-end conditions + results screen.
2. Night phase + camp phase + Camp Fund (no buildings yet: just the fund counter).
3. Camp buildings (start with Water Tower, Field Kitchen, Rescue Shelter).
4. Daily events, then leaderboards + milestone badges, then Second Wind.
5. Later (roadmap phase 4): mini bosses on milestone days, Sang Jerebu on day 10/20/30…

## 10. Test plan / acceptance
- Story mode unchanged: run the 7-day loop with `DebugSkip` to all three endings (bonuses 100/60/25).
- Survival: `DebugSkip` through days 1–12 and check the formulas in §3 (log the cfg each day);
  force run end both ways (`DebugAPI = 350` for a whole day; collapse every player).
- 2–4 clients: revive during a survival day, fund split, building purchase by one player visible to
  all, night skip when everyone is at camp.
- No errors in server/client logs; Studio and `src/` byte-identical; no writes to live DataStores
  from Studio; playtest lock respected.
- Performance: at day 20 with 4 players, fires stay ≤ `maxFires()` and frame rate on a mid phone is OK.

## 11. Guardrails
- Real API band names/numbers never change; the haze stays a health message, not a joke.
- Nothing paywalls safety (masks, station/camp healing, revive by teammates).
- No paid random rewards. Kid-friendly copy.
- Follow `design/MAP_CONTRACT.md` for any new camp parts; keep `Tree`/`Refill` contracts.

## 12. Questions for the user before step 3+
- Should survival unlock only after finishing story mode once?
- Day length in survival: keep 240 s, or shorter (180 s) for faster runs?
- Should the run end when the crew is down, or allow a last-player "solo stand" for 30 s?
