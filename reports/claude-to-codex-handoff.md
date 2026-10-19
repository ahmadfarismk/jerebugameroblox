# Claude → Codex handoff — 18 October 2026

**Codex round 7 (18 October 2026):** Night/Camp, Camp Fund and the Water Tower, Field Kitchen and Rescue Shelter upgrades are implemented. Read `reports/round7-night-camp-progress.md` for exact scope, two-client multiplayer evidence, save status and remaining checks. This supersedes earlier statements that those stages are unbuilt.

**Follow-up by Codex:** see `reports/round6-survival-progress.md` for the response to this handoff: saved round-5 changes, multiplayer test evidence, UI fixes, survival stage 1 and final round-6 save confirmation. Remaining manual checklist gaps are listed there. The unsaved status below describes the original handoff time.

Read `JEREBU_CONTEXT.md` first (shared rules), then this. Your earlier notes are in
`reports/codex-progress-handoff.md`; this file covers everything Claude did after it.
Survival mode has its own build spec: `design/survival-mode-handoff.md`.

## 1. State of the place right now
- Place **Bahaya Jerebu!** (71624879418597). Studio and `src/` match **byte for byte** for every
  script below (checked with a length + rolling-hash compare after each change).
- **Not saved to Roblox since the round-5 fixes.** Ask the user to press Ctrl+S (or confirm they did)
  before you start, so nothing is lost if Studio restarts.
- Not published. Players.MaxPlayers still reads **60** (the user wants 6; set it in Creator Dashboard).

## 2. What changed since your handoff
### Round 4 — fixes + health
- **Server-freeze exploit fixed:** Shop numeric args must be whole numbers (NaN / 1.5 / "2" / inf rejected);
  every per-player server loop is wrapped in `pcall`; shop calls rate-limited (0.15 s); saves batched (30 s).
- **Haze health:** HP drain outside during the Day by band 3/4/5 = 0.4 / 1.0 / 2.0 HP/s × (1 − haze resist);
  inside the BOMBA station +8 HP/s; clean air +1 HP/s. `StarterCharacterScripts.Health` (empty script)
  disables Roblox's default regen. Numbers in `Config.Health`.
- Call the Rain can't be bought while rain is queued or falling. Godspeed cap applies after Server Boost (max 40).
  VIP gets a gold "★ VIP" name tag. Mask placement for dynamic heads. No hose while on bike/kapcai.

### Round 5 — multiplayer
| System | How it works | Where |
|---|---|---|
| Ping | `Remotes.Ping:FireServer(kind, pos)`, kinds Fire/Water/Help/Follow; server checks ≤500 studs, ±150 Y, 1.5 s cooldown; broadcasts `(player, kind, pos)` | JerebuServer "pings" section |
| Scout reward | first Fire ping within 20 studs of a fire, pinger ≤200 studs away → +3 coins when someone else puts it out; max 10/day | JerebuServer `extinguish`, `Config.ScoutRange/ScoutDailyCap` |
| Downed / revive | at ≤1 HP from haze: `Downed`, `DownedUntil` attrs, walk 4, no spray/ride. 2+ players: `RevivePrompt` (hold 2.5 s) → 40 HP, +6 coins to reviver. Timer 25 s (solo 8 s) → pass out + respawn. Healing to 40 (station) self-recovers | JerebuServer "downed + revive", `Config.Revive` |
| Fire cap | 22 + 3 per extra player, max 34 | `maxFires()` |
| Session-locked saves | record `{ data, lock = { job, t } }` via `UpdateAsync`; stale after 300 s; released on leave (3 retries); old bare records still load | Progression `load`/`write`/`releaseLock` |
| Studio save isolation | Studio uses `JerebuSave_v2_Studio`; live uses `JerebuSave_v2` (the tester found Studio API access ON) | Progression top |
| HUD layout | Day pill + API card in the top-bar strip; right column API → Health → Water (220 px); SHOP button by the menu | HUD, HealthUI |
| Crew UI | ping wheel (hold Q / tap Q / touch PING / ButtonL1), crew panel, downed banner | PingUI, CrewUI, DownedUI |
| Crew FX | ping light pillars, downed red highlight + SOS flare, revive burst, station "+" drift | CrewFX |
| Client rules | hides Roblox PlayerList (user chose this), hides your own RevivePrompt | ClientRules |

New remotes: `Remotes.Ride` (round 3) and **`Remotes.Ping`**. New scripts under StarterPlayerScripts:
`ShopUI`, `RideFX`, `PingUI`, `CrewUI`, `DownedUI`, `CrewFX`, `ClientRules` (+ yours: `HealthUI`, `AssetMarkers`).

## 3. Please do next (in this order)
1. **Two-player test** (Test → Clients and Servers, 2–4 clients), the things a solo MCP playtest can't cover:
   - Revive: player A collapses (`DebugAPI = 380`, set A's Health to ~1.2 from the Server, keep A outside the
     station); player B holds E on A → A back at 40 HP, B +6 coins, toast to everyone but A, A's own prompt hidden.
   - Downed timer runs out (25 s) → A respawns at the station, everything cleaned up (highlight, flare, banner).
   - Crew panel on both clients: names, health, water %, ride icon, red REVIVE! row with distance.
   - Scout: A pings a fire within 200 studs, B extinguishes it → A +3; A can't farm it from 400 studs.
   - Coin split: A and B spray the same fire → shares of 12 (peat 20) × CoinMul.
   - Fire scaling: Day 1 burst = round(2 × (1 + 0.5 × (players − 1))); MaxFires = 22 + 3 × (players − 1).
   - Ping wheel round trip on both clients (markers + pillars), 1.5 s cooldown per player.
   - Truck: A drives, B rides along? (passengers aren't implemented; the truck carries only its driver.)
2. **UI polish (small):** the SHOP button can't close the shop because the shop backdrop covers it; the downed
   banner covers the collapse toast. Both in HUD/ShopUI/DownedUI.
3. **Player limit 6** in Creator Dashboard (user-authorized) and verify after reopening Studio.
4. **Live save test** (only in a real published/test server, never against `JerebuSave_v2` from Studio):
   join → buy → leave → rejoin in another server; confirm the lock releases and data persists.
5. Mobile check on a real phone (touch PING button, shop, layout), and recheck the two failed image loads
   (Water `90801669324588`, BadgePeat `87173107468670`).

## 4. Rules that matter (learned the hard way)
- **Never `require` a server ModuleScript from `execute_luau`** — it creates a second copy that takes over
  the remotes (`Remotes.Shop`) with empty data. Use the debug attributes instead:
  `DebugCoins = n` (coins to everyone), `DebugAPI = n` (force API), `DebugSkip = true` (end the phase).
  Remove them when done.
- **Playtest lock:** `workspace.AgentPlaytestLock` = your name before playing; clear after (see the brief).
- **Keep `src/` in sync.** After any Studio script edit, mirror it to `src/` and compare. Claude's method:
  edit `src/` with exact-string replacements, apply the *same* replacements in Studio through
  `ScriptEditorService:UpdateSourceAsync`, then compare length + hash on both sides. Watch for trailing
  newlines: Studio sources have none at the end; files written by tools often add one.
- Studio's HTTP is off (left off on purpose; it's a published-game setting).
- `screen_capture` doesn't draw BillboardGuis (AlwaysOnTop markers) and goes black when Studio is hidden —
  say so instead of guessing.
- Map changes: follow `design/MAP_CONTRACT.md` (names, `Tree`/`Refill` tags, FireStation bounding box is
  the healing safe zone, town centre at the origin).

## 5. Ownership (who edits what)
| Area | Owner |
|---|---|
| Map, world kit, CampServices, world builds 08–09 | Codex |
| JerebuServer, Progression, Config | lead (Claude) — Codex may edit for survival mode per its spec; tell Claude what changed |
| HUD, UIStyle, ShopUI, HealthUI, PingUI, CrewUI, DownedUI, ClientRules | ui-designer |
| HazeFX, RideFX, CrewFX | vfx-designer |
| ServerStorage.Hoses / Rides | prop-modeler |

## 6. Known open items (not bugs you introduced)
- Coins earned during a slow save-load are dropped silently (rare).
- Hose5 backpack offset; hose tiers 1–4 look alike in thick haze; Ride remote has no rate limit.
- Truck has no passengers; "Storm Cannon" is a wider spray, not a true cone.
- Reports with full detail: `reports/game-tester-report.md` (round 5 + lead follow-ups),
  `reports/ui-designer-report.md`, `reports/vfx-designer-report.md`.
