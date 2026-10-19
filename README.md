# Jerebu: 7-Day Haze (Roblox)

**Codex round 7 (18 October 2026):** Night/Camp, Camp Fund and the Water Tower, Field Kitchen and Rescue Shelter upgrades are implemented. Read `reports/round7-night-camp-progress.md` for exact scope, two-client multiplayer evidence, save status and remaining checks. This supersedes earlier statements that those stages are unbuilt.

## Latest progress — 18 October 2026

**Newest:** [Round 6 multiplayer checks and survival stage 1](reports/round6-survival-progress.md). Includes the two UI fixes, playable Story/Survival voting, endless-day rules and run results, with exact test evidence and remaining manual checks. Night/Camp phases and upgrades are not built yet.

See [Codex progress and Claude handoff](reports/codex-progress-handoff.md) for completed image/UI integration, the imported Kem Bomba Rimba world, save confirmation, test evidence and outstanding work. World changes are saved to Roblox. Six-client join/refill smoke testing passed; see reports/six-player-playtest.md for limits. Changing the server limit from 60 to 6 remains blocked by Firefox automation support.

This folder holds the whole game, so the place can be rebuilt from files at any time.
New developers: start with [GAME_OVERVIEW.md](GAME_OVERVIEW.md) for what the game is and where things stand.

## Layout
| File | Becomes in Studio |
|---|---|
| `build/01_terrain.lua` … `build/06_hose_tool.lua` | the map, lighting, remotes, sounds, hose tool (run in order, Edit mode, via the command bar or the MCP `execute_luau`) |
| `src/ReplicatedStorage/Jerebu/Config.lua` | `ReplicatedStorage.Jerebu.Config` (ModuleScript) |
| `src/ReplicatedStorage/Jerebu/UIStyle.lua` | `ReplicatedStorage.Jerebu.UIStyle` (ModuleScript) |
| `src/ReplicatedStorage/Jerebu/ImageAssets.lua` | `ReplicatedStorage.Jerebu.ImageAssets` (ModuleScript, uploaded image IDs) |
| `src/ReplicatedStorage/Jerebu/SurvivalRules.lua` | `ReplicatedStorage.Jerebu.SurvivalRules` (ModuleScript, pure difficulty/voting rules) |
| `src/StarterPlayerScripts/SurvivalSpectate.client.lua` | `StarterPlayer.StarterPlayerScripts.SurvivalSpectate` (LocalScript) |
| `src/StarterPlayerScripts/AssetMarkers.client.lua` | `StarterPlayer.StarterPlayerScripts.AssetMarkers` (LocalScript, nearby hydrant icons) |
| `src/ServerScriptService/JerebuServer.server.lua` | `ServerScriptService.JerebuServer` (Script) |
| `src/ServerScriptService/Progression.lua` | `ServerScriptService.Progression` (ModuleScript): saves, shop, upgrades, rides, passes |
| `build/07_props.lua` | hose tier tools + ride models in ServerStorage (written by the prop modeler) |
| `build/08_kem_bomba_layout.lua` | Kem Bomba Rimba camp/routes; requires imported `ServerStorage.KemBombaKit` templates |
| `build/09_kem_lookout_access.lua` | wider lookout ramp and landing, applied after 08 |
| `src/ServerScriptService/CampServices.server.lua` | `ServerScriptService.CampServices` (Script, validated camp shop prompt) |
| `src/StarterPlayerScripts/HUD.client.lua` | `StarterPlayer.StarterPlayerScripts.HUD` (LocalScript) |
| `src/StarterPlayerScripts/HealthUI.lua` | `StarterPlayer.StarterPlayerScripts.HealthUI` (ModuleScript, required by HUD; live Humanoid health meter) |
| `src/StarterPlayerScripts/CrewUI.lua` | `StarterPlayer.StarterPlayerScripts.CrewUI` (ModuleScript, crew list under the coins pill, required by HUD) |
| `src/StarterPlayerScripts/PingUI.client.lua` | `StarterPlayer.StarterPlayerScripts.PingUI` (LocalScript, Q / touch / L1 ping wheel + ping markers) |
| `src/StarterPlayerScripts/DownedUI.client.lua` | `StarterPlayer.StarterPlayerScripts.DownedUI` (LocalScript, "You collapsed!" banner) |
| `src/StarterPlayerScripts/HazeFX.client.lua` | `StarterPlayer.StarterPlayerScripts.HazeFX` (LocalScript) |
| `src/StarterPlayerScripts/JoinCamera.client.lua` | `StarterPlayer.StarterPlayerScripts.JoinCamera` (LocalScript) |
| `src/StarterPlayerScripts/ShopUI.lua` | `StarterPlayer.StarterPlayerScripts.ShopUI` (ModuleScript, tabbed shop, required by HUD) |
| `src/StarterPlayerScripts/RideFX.client.lua` | `StarterPlayer.StarterPlayerScripts.RideFX` (LocalScript, truck cannon, ride pose, Godspeed trail, boost aura) |
| `src/StarterPlayerScripts/CrewFX.client.lua` | `StarterPlayer.StarterPlayerScripts.CrewFX` (LocalScript, ping pillars, downed highlight/SOS flare, revive burst, station healing drift) |
| `src/StarterPlayerScripts/ClientRules.client.lua` | `StarterPlayer.StarterPlayerScripts.ClientRules` (LocalScript: hides Roblox's player list, hides your own revive prompt) |
| `src/StarterPack/Hose/HoseClient.client.lua` | `StarterPack.Hose.HoseClient` (LocalScript) |
| `src/StarterCharacterScripts/Health.server.lua` | `StarterPlayer.StarterCharacterScripts.Health` (Script, empty: turns off Roblox's default regen so haze damage matters) |

The `.server.lua` / `.client.lua` suffixes follow Rojo conventions, so you can move to
Rojo later if you want live file sync.

## Rebuild a fresh place
1. Open Studio → new Baseplate place → set `Lighting.Technology` to **Future** by hand.
2. Run `build/01` … `build/06` in order.
3. Create the scripts from `src/` (types in the table above).
4. **Save (Ctrl+S) right away**, and publish if you want cloud backups.

## Agents
Role instructions live in `.claude/agents/` (`ui-designer`, `vfx-designer`, `game-tester`);
the shared brief is `JEREBU_CONTEXT.md`. Reports go to `reports/`.

## Debug (Studio only)
Workspace attribute `DebugAPI = <number>` forces the API; `DebugSkip = true` ends the current phase;
`DebugCoins = <number>` gives every player coins. Game Passes / Developer Products with `id = 0`
in Config are simulated in Studio.

## Going live with premium
Create each Game Pass and Developer Product in the Creator Hub, then put its id into
`Config.Passes[*].id` / `Config.Products[*].id`. Until then they show "Coming soon!" in the live game.

