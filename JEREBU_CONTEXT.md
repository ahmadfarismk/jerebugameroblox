# Jerebu: 7-Day Haze — shared brief for all agents

**Codex round 7 (18 October 2026):** Night/Camp, Camp Fund and the Water Tower, Field Kitchen and Rescue Shelter upgrades are implemented. Read `reports/round7-night-camp-progress.md` for exact scope, two-client multiplayer evidence, save status and remaining checks. This supersedes earlier statements that those stages are unbuilt.

Read this first. Then read your own role file in `.claude/agents/`.

**Codex round 6 (newest):** read `reports/round6-survival-progress.md`. Claude's latest changes were saved, core two-player revive/ping/reward checks ran, the two UI issues were fixed, and Survival stage 1 (vote, endless days, endings/results) is implemented. Night/Camp/buildings are later stages. User approved immediate survival access, 240-second days and immediate crew-down ending. See the report for test limits and final save status.

**Earlier Claude handoff (18 October 2026):** read `reports/claude-to-codex-handoff.md` (rounds 4–5: health, multiplayer, save locking) and `design/survival-mode-handoff.md` (the survival mode build spec). The round-6 report above supersedes its unsaved-state and pending-check notes where tests have now been completed.

**Latest handoff (18 October 2026):** Read `reports/codex-progress-handoff.md` before continuing. Generated images and working health UI are installed; Kem Bomba Rimba camp/routes are imported and saved to Roblox. Six-client join/refill smoke tests passed (reports/six-player-playtest.md); shop, traversal and persistence checks remain incomplete. The server limit was last verified at 60; setting it to 6 remains pending and is user-authorized.

## The game
A co-op Roblox sim set in Malaysia. Players put out forest fires for 7 in-game days.
Every fire left burning raises the shared **API (Air Pollutant Index)** meter, and the
whole world gets visibly hazier as the API climbs. The haze crisis is real and serious
(JAS reported dozens of areas with unhealthy API in Oct 2026), so the tone is **caring,
not jokey**: fun to play, but never mocking the people living through it.

Official Malaysian API bands (do not change these numbers or names):

| API | English | Bahasa Melayu | Colour |
|---|---|---|---|
| 0–50 | Good | Baik | blue `46,160,220` |
| 51–100 | Moderate | Sederhana | green `80,190,90` |
| 101–200 | Unhealthy | Tidak Sihat | yellow `240,190,40` |
| 201–300 | Very Unhealthy | Sangat Tidak Sihat | orange `235,110,40` |
| 300+ | Hazardous | Berbahaya | red `200,40,50` |

Real rules used as mechanics: school field closes at API > 100; cloud seeding unlocks
when API stays > 150 (in-game: 25 s).

## Roblox Studio access
- Use the Roblox Studio MCP tools. They are deferred: load them first with
  `ToolSearch` query `Roblox_Studio` (max_results 30).
- Call `list_roblox_studios` to get the `studio_id`. The place is the published
  **"Bahaya Jerebu!"** (placeId 71624879418597). Only one Studio place is open; everyone shares it.
- A pre-agent backup of the scripts lives in `ServerStorage.Backup_PreAgents` (disabled). Don't delete it.
- Source of truth for scripts is mirrored in `src/` (see README.md). If you change a script in
  Studio, say so in your report so it can be mirrored.
- `multi_edit` only works in **Edit** mode. `execute_luau` can target Edit, Server or Client.
- `screen_capture` only renders the 3D view while the Studio window is visible on screen.
  If the 3D view comes back black/blank, that is a capture problem, not a game bug — fall
  back to reading values with `execute_luau` and say so in your report.
- Edit-mode `execute_luau` cannot read or write `Lighting.Technology`.

## Shared-Studio rules (several agents work at the same time)
1. **Playtest lock.** Before `start_stop_play(true)`, run in Edit:
   `return workspace:GetAttribute("AgentPlaytestLock")`. If it is set and not yours, wait
   ~30 s and check again (max 10 min, then report it). If free, set it to your role name,
   then start play. Always stop play and clear the lock (`SetAttribute(..., nil)`) when
   done, even after errors. Keep playtests under 4 minutes.
2. If an edit fails because Studio is in play mode, the other agent is testing: wait and retry.
3. **Only edit the scripts/instances your role owns** (listed in your role file). If you
   need a change elsewhere, write it in your report as a request instead.
4. Never delete the map, `ServerScriptService.JerebuServer`'s game loop, or other agents' work.
5. Studio-only debug switches exist on the server: set workspace attribute `DebugAPI`
   (number) to force the API, `DebugSkip = true` to end the current phase. Remove any
   attributes you set when finished.

## Where things live
| Path | What |
|---|---|
| `ReplicatedStorage.Jerebu.Config` | tuning, API bands, tips (ModuleScript) |
| `ReplicatedStorage.Jerebu.Remotes` | Spray, Notify, Report, Sfx, Ending (RemoteEvents), Shop (RemoteFunction) |
| `ReplicatedStorage.Jerebu.Sounds` | Sound templates (FireLoop, Spray, Sizzle, Birds, HazeWind, Click, Coin, Cough1/2, Plane, Alarm, Rain, Refill, Success, Ignite) |
| `ServerScriptService.JerebuServer` | day loop, fires (`makeFirePart`, `updateFireVisual`), API, spraying, refills, shop, cloud seeding |
| `StarterPlayer.StarterPlayerScripts.HUD` | all 2D UI: API card, day pill, coins, water bar, toasts, title card, night report, ending, shop |
| `StarterPlayer.StarterPlayerScripts.HazeFX` | haze presets per band, camera dust/ash/rain, vignette, ambient audio, fire markers, hose stream visuals, coughing |
| `StarterPack.Hose` (+ `HoseClient`) | the hose tool and its input |
| `Workspace.Map` | Town (FireStation w/ ShopCounter + Spawn, School, houses), Forest (trees tagged `Tree`, `Peat` attr), Refill zones, Airstrip (SeedPad, SeedingPlane) |
| `Workspace.Fires` | live fire parts (attrs `Intensity`, `Smoulder`, `Peat`) |

Workspace attributes clients read: `API`, `Day`, `Phase` (Intermission/Day/Report/Ended),
`TimeLeft`, `Fires`, `Smoulder`, `Wind`, `Raining`, `SeedReady`, `SeedLoaded`, `SeedNeed`.
Player attributes: `Water`, `MaxWater`, `Range`, `Tank`, `Nozzle`, `Mask`, `Refilling`.

## Progression system (round 3)
Server: `ServerScriptService.Progression` (ModuleScript) owns saved data (DataStore `JerebuSave_v2`,
migrates v1), the shop, stats, masks, hose tools, rides, truck cannon and purchases. **Never
`require` it (or any server module) from execute_luau** — that creates a second copy that hijacks
the remotes. Use the debug attributes instead; `DebugCoins = n` gives every player n coins.

Data lives in `Config` (`Tracks`, `Hoses`, `Masks`, `Rides`, `Truck`, `Passes`, `Products`, `Boost`,
`Icons`). Uploaded image mappings now live in `ImageAssets` and Config; preserve readable fallbacks for empty or failed image loads. See `reports/image-ui-integration.md` for the two assets that failed fetching at the last check.

**Shop remote:** `Remotes.Shop:InvokeServer(action, arg) -> ok, msg`. Actions: `BuyTrack(id)`,
`BuyHose(tier)` (must be next tier), `EquipHose(tier)`, `BuyMask(tier)`, `BuyRide(id)`,
`BuyPass(key)`, `BuyProduct(key)`. `msg == "__prompted"` means Roblox's purchase prompt opened (show
nothing). Passes/products with `id = 0` are simulated in Studio ("Studio test purchase") and say
"Coming soon!" live.
**Ride remote:** `Remotes.Ride:FireServer(id)` mounts; `FireServer("")` or the same id dismounts.

**Player attributes:** `Track_<id>` (level 1–10), `HoseOwned`, `HoseTier`, `MaskTier`, `Ride_<id>`
(owned), `Pass_<key>`, `Riding` (`""` or ride id), `TruckWater` (0–1), `TruckSpraying`, `MaxWater`,
`Range`, `HazeResist`, `InfiniteWater`, `CoinMul`, `Mask` (true when resist ≥ 0.7, used for coughing).
Tool attribute `Tier` on the Hose. Workspace `BoostUntil` (server time; active while > `GetServerTimeNow()`).

**Models (prop-modeler):** `ServerStorage.Hoses.Hose1..6` (Tool; `Handle` → `Nozzle` attachment →
`Jet` + `Drops` emitters; no scripts) and `ServerStorage.Rides.Bicycle/Kapcai/Truck` (Model,
PrimaryPart, `Seat` attachment in PrimaryPart; Truck also `Cannon`). Missing models fall back to
the starter hose / a placeholder ride, so nothing breaks while they're being built.

| Role | Owns this round |
|---|---|
| ui-designer | `HUD`, `UIStyle`, `ShopUI`, `HealthUI`, new UI LocalScripts |
| vfx-designer | `HazeFX`, new FX LocalScripts (e.g. `RideFX`) |
| prop-modeler | `ServerStorage.Hoses`, `ServerStorage.Rides`, `build/07_props.lua` |
| economy-balancer | `design/economy*`, its report (files only, no Studio) |
| lead | `JerebuServer`, `Progression`, `Config` |

## Multiplayer (round 5)
- **Ping remote:** `Remotes.Ping:FireServer(kind, pos)` with kind `"Fire" | "Water" | "Help" | "Follow"`;
  server validates (≤ 500 studs from the player, one per `Config.PingCooldown` = 1.5 s) and broadcasts
  `Remotes.Ping.OnClientEvent(player, kind, pos)` to everyone. The first `Fire` ping within 20 studs
  of a fire makes that player its scout: +`Config.ScoutReward` coins when someone else puts it out.
- **Downed:** haze can't kill outright. At ≤ 1 HP a player gets attribute `Downed = true` and
  `DownedUntil` (server time, `workspace:GetServerTimeNow()`), walks at 4, can't spray or ride.
  With 2+ players a `ProximityPrompt` named `RevivePrompt` (hold 2.5 s) appears in their
  HumanoidRootPart; a teammate reviving them restores 40 HP and earns +6 coins. When the timer ends
  (25 s, or 8 s when solo) they pass out and respawn at the station.
- **Fire cap** scales: 22 + 3 per extra player, max 34. Saves are session-locked per server.
- Studio playtests save to a separate DataStore (`JerebuSave_v2_Studio`); live servers use `JerebuSave_v2`. Studio API access is ON, so never write to the live store from tests.
- The shop can be opened from anywhere (purchases have no distance check), so a HUD Shop button is fine.

## Code style
Luau, tabs, short comments only where the *why* isn't obvious, typed where it helps.
Match the existing scripts. Mobile matters: test at ~375 px wide via the device
emulator or by reasoning about `UIScale`; keep touch targets ≥ 44 px.

## Reporting
Write your report to `reports/<role>-report.md` in this folder (create `reports/` if
missing): what you changed (script + function names), what you verified and how, what you
could not verify, and open requests for other roles. Keep it under ~80 lines.

