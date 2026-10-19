# Codex progress handoff — 18 October 2026

**Newer work:** `reports/round6-survival-progress.md` records subsequent multiplayer tests, the two UI fixes, survival stage 1 and final save confirmation. Use it with Claude's rounds 4–5 handoff; this file remains the image/world import history.

Read this alongside `reports/image-ui-integration.md` and `reports/world-design-report.md`. This records completed work and tested limits; proposed work in the world-design report is not all implemented.

## Current save and multiplayer status

- Place: **Bahaya Jerebu!**, place ID **71624879418597**.
- Reconnected after Studio restarted and confirmed `Workspace.Map.KemBombaRimba`, `ServerStorage.KemBombaKit`, and `ServerScriptService.CampServices` still exist.
- **Save confirmed:** Studio displayed `Saved new changes in "Bahaya Jerebu!" to Roblox.` after Ctrl+S (13:13:01 Studio output on 18 October). No Publish action was performed.
- **Player limit is still 60 at the last verified read.** User has authorized changing it to 6. Do not report this as completed.
- **Six-client local smoke test completed:** all six joined and refilled from 10 to 100 concurrently; see `reports/six-player-playtest.md`. Shop interaction, route traversal and persistence are not yet verified with six clients.
- Creator Dashboard is now open to the game's settings according to the user. Prior Windows browser automation was stopped because URL-policy enforcement was unsupported in Firefox. No player-limit setting was changed during that attempt.

## Images and working UI completed

- Generated and saved 61 PNGs: original 59 requested assets, plus health heart and health-bar preview, in `assets/bahaya-jerebu/`.
- All 61 uploaded to Roblox; mappings in `assets/bahaya-jerebu/roblox-uploads.json` and `src/ReplicatedStorage/Jerebu/ImageAssets.lua`.
- Wired 29 shop card mappings, HUD icons, API faces, tutorial art, menu background, fire/peat markers, nearby hydrant markers, and health heart.
- HealthUI follows live Humanoid health, displays LOW HP, and reconnects after respawn without duplicate bars. Native UI supplies the changing fill; preview PNG is a reference.
- Render check: 59/61 images loaded. Water `90801669324588` and BadgePeat `87173107468670` failed fetching at the last check; BadgePeat logged HTTP 502. Water has a native fallback; peat badge is catalog-only. Do not claim these two are fixed.
- Marketing and badge art are cataloged; experience thumbnail/icon configuration, badge awards, and new monetization products were not created.

## Kem Bomba Rimba kit and world changes completed

- Original modular Blender kit: `assets/world/kem-bomba-rimba/Kem_Bomba_Rimba.blend`, with 12 FBX and 12 GLB module exports, preview and validation files.
- `prepare_roblox.py` produced `Kem_Bomba_Rimba_Roblox.fbx`: 40 material-separated mesh pieces with corrected import scale. Imported/uploaded using Studio's native importer.
- Twelve reusable templates live in `ServerStorage.KemBombaKit`. Uploaded mesh IDs, transforms, sizes, and colors are recorded in `roblox-mesh-manifest.json`; export metadata in `roblox-export.json`.
- New world subtree: `Workspace.Map.KemBombaRimba` (Buildings, Routes, Landmarks). Added pavilion, rescue shelter, supply kiosk, water tower, court, lookout, trail signs and tropical decorations.
- Forward camp is around X=-78, Z=-205. Existing vehicle bridge widened from 14 to 24 studs; separate 12-stud pedestrian bridge at X=-32. Added access ramps, camp approach, lookout loop, peat loop and raised peat boardwalk.
- Relocated 21 obstructing trees; all 302 existing tagged fire targets preserved. Moved the approach hydrant east to clear the vehicle lane.
- Changed grass material beneath routes/camp to Ground to prevent grass poking through; terrain shape was not changed.
- Imported decorative meshes are non-collidable; native colliders provide floors, supports, rails and access. Templates use Atomic model streaming.
- Added camp refill zone tagged `Refill`, rate 30, using existing server refill logic.
- `CampServices` validates the kiosk prompt's player health, distance and per-player cooldown, then opens the existing shop for that player. No separate economy was introduced.
- Replaced inaccessible lookout access with a wider crew ramp and landing after the original staircase failed no-jump pathfinding.

## Source and backup locations

- `build/08_kem_bomba_layout.lua`: camp layout, routes, bridge changes, tree relocation and surface material changes. Requires the imported templates already in ServerStorage; it is not a standalone mesh importer.
- `build/09_kem_lookout_access.lua`: lookout ramp/access correction; run after 08 when rebuilding.
- `src/ServerScriptService/CampServices.server.lua`: installed camp shop service.
- `ServerStorage.Backup_WorldBeforeKem_20261018`: original map component backups, with gameplay tags removed from backups to avoid duplicate server processing.
- Its `TerrainBeforeKemSurface` TerrainRegion stores the pre-surface terrain snapshot with CornerX/Y/Z attributes for restoration.
- `ServerStorage.Backup_ImageIntegration_20261018`: image/UI integration backup.
- Original source exports and the Blender file remain intact. Live game was saved; do not rerun build scripts merely to resume testing.

## Verification actually performed

- No-jump pathfinding succeeded for pedestrian crossing, town-to-camp route, camp-to-lookout route and peat boardwalk. Lookout ramp succeeded after correction.
- Two actual local test clients connected to one local server. Both were placed in the camp refill zone with Water=10 and both reached Water=100 concurrently.
- Both clients saw the camp and HUD and shared API state; no client MessageError entries were observed during those checks.
- Local multiplayer session ended and its test windows were closed; playtest lock was cleared at that time.
- Health heart loaded, 20/100 health displayed LOW HP, and respawn restored exactly one bar at 100/100 in prior UI tests.

## Next work, already authorized by the user

1. Set the place server limit to **6** in Creator Dashboard, save, and verify the persisted value. Reopen/refresh Studio if necessary; an already-open Edit session may retain old settings.
2. Run a bounded six-client local server test. Follow the `AgentPlaytestLock` workspace-attribute protocol in `JEREBU_CONTEXT.md`; stop play and clear only your own lock afterward.
3. Verify six players can spawn, refill together, open the camp shop independently, and traverse the bridges/boardwalk/lookout. Check truck passing/turning and client/server errors. Two-client evidence is not six-player or mobile performance evidence.
4. Record actual results, remaining bugs and the final player limit here or in a linked playtest report. Save any fixes to Roblox and mirror script changes in `src/`.
5. Still outstanding beyond that bounded test: mobile performance, full seven-day multiplayer round, streamed travel checks and rechecking the two failed image loads.

Do not require server modules from `execute_luau` (can duplicate state and hijack remotes). Discover fresh Studio IDs on reconnect. No live publishing has been performed by Codex.

## Claude follow-up (18 October 2026, after this handoff)
- Verified the live place contains BOTH Codex's world work (KemBombaRimba, KemBombaKit, CampServices) and Claude's round-4 script fixes (save safety, safe zone, health drain, StarterCharacterScripts.Health). Config, JerebuServer, Progression, HazeFX, HUD and CampServices match `src/` byte for byte (CampServices trailing newline aligned).
- Round-4 changes not listed above: see the "Lead follow-up (round 4)" section in `reports/game-tester-report.md` (B1 server-freeze exploit fixed, save-wipe protection, Call the Rain double-buy, haze health drain + BOMBA-station safe zone).
- Plans written: `design/roadmap.md` (monetization, survival mode, multiplayer, bosses) and `design/MAP_CONTRACT.md` (what the scripts need from the map — read before further map changes).
- Players.MaxPlayers still reads 60 in Studio. Six-client test not yet run.

### Please include in the six-client test (Claude's round-4 changes, never multiplayer-tested)
- Haze health: with `DebugAPI = 380` during a Day, unmasked players lose ~2 HP/s outside; inside the BOMBA station they heal 8 HP/s; passing out respawns at the station with one toast. Check all 6 drain independently and the server log has no "player tick failed" warnings.
- Co-op fire scaling: Day 1 burst = round(2 × (1 + 0.5 × (players − 1))) → 7 fires with 6 players; spawn interval divides by the same factor. Watch API pressure on Days 1–2 with 6 players.
- Coin split: several players spraying one fire each get a share of 12 (peat 20), × CoinMul.
- Shop from 6 clients at once (station counter and the camp kiosk): purchases succeed independently; rapid repeat clicks may return "Slow down" (0.15 s limit) — that's expected.
- `DebugCoins = n` gives every player coins for shop tests. Do not `require` Progression from execute_luau.

