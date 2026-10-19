# VFX Designer report — Jerebu: 7-Day Haze

**Status: NOTHING VERIFIED. Nothing was applied in Studio.** I read HazeFX and JerebuServer in
Studio (place "Game", studio id `25d88d6a-…`). Before my first edit, Studio crashed: the MCP lost the
connection, `RobloxStudioBeta.exe` stopped running, and it was still down 15+ minutes later. I made
**no edits in Studio** and never took or released the AgentPlaytestLock, so the crash cannot have lost
any VFX work. As the coordinator asked, all the work is below as source files.

## Files
- `reports/vfx-designer-src/HazeFX.lua` — full replacement for `StarterPlayer.StarterPlayerScripts.HazeFX`.
- `reports/vfx-designer-src/FireVisuals.lua` — new `charTree`, `makeFirePart`, `setFireMode` (new
  helper) and `updateFireVisual` for `ServerScriptService.JerebuServer`, plus a plane-trail snippet for
  `runCloudSeeding`. The header comment says exactly where each piece goes. No rules, tuning or remotes are touched.

## Fires (JerebuServer)
- Removed the classic `Fire` instances (Core, CrownCore). They looked cheap and broke the emitter budget.
  To stay readable in daylight, the flames now use `LightInfluence 0`, `Brightness 4` and `LightEmission 0.3`. Low additive
  blending keeps them saturated orange against a bright hazy sky instead of washing out to white.
- 4-stop colour ramp (pale yellow → orange → red → dark red). Alpha fades in quickly.
- Intensity reads clearly: flame size runs from 2.5 to 10 studs, rate from 8 to 36/s, speed scales, and smoke size and rate scale.
  The light pulses each update. Random flare-ups (`Emit`) happen on fires above 35 intensity.
- Crown fire still starts at intensity > 45. The third emitter slot switches: Embers while the fire is small, CrownFlames
  once it crowns. That keeps every fire at 3 emitters + 1 light.
- Burning peat looks different: lower, wider flames, a deeper orange ramp, and a wider pale-grey smoke column.
- **Smouldering peat** (new `setFireMode`, which runs only when the mode changes): the Flames emitter switches to
  `forcefield_glow_main.dds` orange ember-glow patches in a 9-stud disc. Smoke becomes thin, pale and low, spreading 80°
  so it hugs the ground and creeps. Embers drop to a few small sparks, and the orange light flickers.
  The glow **fades as `fire.soak` rises**, so players can see their spraying working. When it flares back up, there is a 30-ember burst.
- `charTree(info, 1)` now leaves a dark scorched ring (a flat Slate cylinder parented to `Map`).
  `charTree(info, 0)` (resetTrees) removes it.

## Extinguish (HazeFX)
- On `Sfx "Sizzle"` with a position (sent on every extinguish), `steamBurst` emits 26 white rising
  steam puffs (fast and dragged, ~1.2 s fade) and 16 low puffs that bulge out around the base. One pooled part is reused,
  and it costs nothing between bursts. The existing sizzle sound plays as before.

## API bands (HazeFX presets)
| Band | Before | After (intent) |
|---|---|---|
| 1 Good | clear blue | unchanged |
| 2 Moderate | neutral grey | slightly warmer grey, small glare |
| 3 Unhealthy | tan, read as green | colour/tint/decay moved toward amber (more red, less green); glare 0.45 + orange decay = orange sun halo |
| 4 Very Unh. | brown-orange | deeper orange decay, glare 0.7 (red-orange sun), dust 34→32 |
| 5 Hazardous | brown-orange (fixed earlier) | density 0.88→0.85, light 1.55, glare 0.9 with red decay, dust 60→50 (playability + perf) |
- New fire glow: one BillboardGui per fire with 3 soft concentric discs. Billboards ignore fog, so fires
  show as an orange bloom through thick haze. The glow is hidden within ~35 studs, stronger at distance and at higher API,
  and blocked by terrain (not AlwaysOnTop). The fire-marker range-shrink mechanic is unchanged.

## Rain (cloud seeding)
- Texture changed to `SquareParticle.png`. The old `Squash -2.5` flattened the drops; it is now `+2.6` with
  VelocityParallel, which should give thin, long streaks. Brightness is 1.6 and the rate is 700/s (was 800).
  **The sign of the squash needs checking by eye**.
- New ground ripples (`explosion01_shockwave_main.dds`, flat, 70/s) in a 50-stud box at the player's feet.
- Terrain `Clouds` (if present) get darker and heavier while it rains. SunRays are off in rain.
- Plane: white `Trail` between wingtip attachments while seeding (the snippet assumes the wingspan runs along X).

## Performance (by calculation)
- Per fire: 3 emitters + 1 PointLight. At intensity 100: flames 36 + crown 22 + smoke 8 = 66/s.
  22 fires × 66 = ~1450/s, plus haze dust 50 and ash 26 ≈ 1530/s worst case (the budget is about 1500).
  If profiling shows that is too much, lower flame `Rate` to `8 + 24*k`.
- Rain is 700 + 70/s, but dust and ash are 0 then and the rain is shrinking the fires.
- All textures are built-in `rbxasset://textures/particles/*`. I confirmed the files exist in the local
  Roblox install, but did not run `PreloadAsync`.

## Not verified (everything)
- No playtest, no DebugAPI sweep, no captures, no `LogService` check. The code is not even compiled/linted in Studio.
- Specific risks: the rain Squash sign, how soft the glow discs look (they may look like flat target rings; if so,
  use one disc or an ImageLabel), whether the scorch ring is hidden by tall grass, the plane wingspan axis, and how
  the band 3–5 glare looks on the real sun.

## Requests / next steps
- Whoever restores Studio: paste both files, then run the verify list in `vfx-designer.md` (DebugAPI
  30/80/160/250/380, fire at intensity ~30 and ~100, peat smoulder, hose, rain).
- Hose `Jet`/`Drops` emitters (StarterPack.Hose) were not reviewed. Only the splash got a small brightness bump.
- No requests for the UI designer. The HUD was not touched.

## Fix round 1 (2026-10-17, after QA)
Edited live in Studio (Edit mode, small `multi_edit`s) and mirrored to `src/`.

**B2 Rain (HazeFX).** The cause: with `VelocityParallel`, **positive** Squash makes flat *horizontal*
bars (capture FR1_rain_1). Negative Squash stretches the drops along the fall instead.
- Rain is now `Size 0.75`, `Squash -2.8`, transparency 0.4 to 0.45, `LightInfluence 0`, `Brightness 1.3`,
  speed 58 to 66, lifetime 0.85 to 0.95.
- The volume shrank from 110² to 64², sits 42 studs above the camera, and is offset horizontally
  along the look direction. Rate went from 700 to 600, so it is denser near the player at a lower rate.
- Ripples: each frame a raycast goes down from the HumanoidRootPart, excluding the character,
  LocalHazeFX and Fires. The sheet sits at hit +0.12, or +0.6 on Grass/LeafyGrass so the blades
  don't bury it. Ripples are now 36² at rate 90, size 0.3 to 2.2, alpha 0.1, LightInfluence 0.
- Verified: clear thin falling streaks in FR1_rain_3 (FR1_rain_2 was the too-thick step).
  The grass offset was added after the playtest. Ripples in tall grass were not seen in a capture.

**B4 Fire glow (HazeFX `addGlow`/`updateGlows`).**
- The glow now sits at canopy height (`Crown` attachment Y +4, clamped 9 to 40; 9 for short trees)
  and is `AlwaysOnTop`, so trunks and hills no longer hide it.
- The 3 hard discs are now 8 concentric discs, each about 16% opaque, warming from deep orange
  to a yellow core. Together they give a soft radial falloff. UIGradient is linear only, so a
  real radial gradient isn't possible.
- Visibility = near (30 to 70 studs) × distance fade × haze × intensity. The core is about 75%
  opaque at full haze. The size grows up to 1.8× with distance so it keeps its screen size.
- The glow's range follows the marker range (`2 × markerRange + 120`, 80-stud fade), so haze
  still shrinks how far you can see.
- **Marker range floor:** HazeFX now uses `max(Config markerRange, 95)`. Band 5 goes from 70 to 95;
  bands 1 to 4 are unchanged. Config was not touched.
- Verified by property reads. `screen_capture` does not draw BillboardGuis at all: a 6-stud red
  test billboard 12 studs from the camera did not show (FR1_bbtest/bbtest2). Results:
  - API ~285, fire 117 studs away: glow enabled, on screen, ~102 px wide, core opacity 0.70.
  - API 383, same fire: core opacity 0.75. A second fire at 222 studs: 0.58.
    Fires at 340 studs or more: hidden. Marker MaxDistance: 95.

**B7 Smouldering peat (JerebuServer: new `emberPatches` helper + `setFireMode`/`updateFireVisual`).**
- The fire part gets 6 Neon mounds (ball parts, 1.2 tall, up to 4.2×3.2, anchored, no
  collide/query/touch/shadow). They are created the first time a fire smoulders and hidden when it burns.
- In `updateFireVisual` the mounds pulse orange (sine flicker) and dim to charcoal as the peat is
  soaked. They are parts, so they cost nothing from the particle budget.
- Smoulder flames use `fire_main` with LightInfluence 0 and Brightness 5. They are small (0.9 to 1.6),
  emitted downward and braked by drag (16/7 ≈ 2.3 studs) so they flicker at ground level. Rate 14.
- The smoke is wider and greyer (spread 85°, speed 2 to 3.5, rise 0.2) so it hugs the ground.
  Embers went from 1.5 to 4/s.
- The burn branch now resets EmissionDirection, Drag and LightInfluence.
- Budget unchanged: 3 emitters + 1 light per fire.
- Verified: sprayed a PeatFire to 0 with the Spray remote at API 31 in daylight. In FR1_smoulder_day3
  the bright orange mounds read clearly from ~18 studs, with smoke rising. Patch size went up ~25%
  after that capture.

**Checks.**
- One playtest: lock set, then stopped, and the lock plus DebugAPI/DebugSkip/Raining cleared.
- No script errors on server or client; only the expected DataStore Studio error.
- The final scripts were also running error-free in the ui-designer's later playtest
  (rain Squash -2.8 confirmed on their client).
- That playtest ran ~7 minutes, over the 4-minute guideline, because a day ended mid-test and
  I had to wait for a peat fire.
- Bonus: in FR1_smoulder_day2, night-time fires and the crown fire look strong.

**Open / for others.**
- The fire glow can't be checked in a screenshot (capture tool limit). Please eyeball it in a
  real client at band 4 and 5.
- Lead: `Config.Bands[5].markerRange` (70) is now effectively 95 on the client. Raise it in Config
  if you want the two to agree.
- The `GLOW_TEX` constant in JerebuServer is now unused (harmless).


## Round 3 (progression FX)

**Files.** `HazeFX` (spray section rewritten: `HOSE_STYLE`, `buildSplash`, `splashFor`, `styleTool`,
`updateSprays`) and new `StarterPlayerScripts.RideFX` (LocalScript). Both mirrored in `src/StarterPlayerScripts/`
(byte-identical to Studio). I did not touch HUD, UIStyle, JerebuServer, Progression, Config or ServerStorage.

**Hose tiers (HazeFX).** Read from the equipped Hose tool's `Tier` attribute, for every player's tool. Only
needs `Handle -> Nozzle`; `Jet`/`Drops` are optional. Extra FX live in one anchored `Splash` part per tool.
- T1: unchanged stream. T2: brassy-white beam, warm Jet/Drops, brighter. T3: two beams side by side (twin),
  thinner centre jet, mist ring. T4: thick white foam beam (w 0.8 to 3.4), big white splash plus lingering
  foam blobs. T5: strong glowing blue (LightEmission 1) and a blue PointLight at the splash. T6: cyan glow,
  sparkles (Drops rate 100 plus a sparkle emitter with small flicker bursts), a cyan light, and a small storm
  swirl (spinning emitter leaves a ring of dark cloudlets) at the splash.
- Width follows the server radius: scale = (BaseSprayRadius + Hoses[tier].radius) / BaseSprayRadius
  (1.0 / 1.3 / 1.6); splash size, twin gap, foam size and the ground mist ring scale with it.
- Bug fixed: the old stream Beam bowed sideways, because beam curves bend along the attachment's +X axis and
  the nozzle was only look-at oriented. Beam attachments are now built with X = up (CFrame.fromMatrix).
- Tool Jet/Drops are restyled once per (tool, tier) from remembered originals (never compounds).
- Budget per active sprayer (rates/s, approx.): T1 180, T3 214, T4 230, T5 214, T6 272 (Jet 90 + Drops 60/100 +
  splash 30 + extras). Extras, lights and the swirl switch off when the splash is > 140 studs from the camera.

**Truck cannon (RideFX).** When a player has Riding == "Truck" and TruckSpraying: ballistic particle arc
(110/s) from the model's `Cannon` attachment (fallback: top of the RideModel bounding box, else root + 2.5) to the
nearest fire within `Config.Truck.radius` (30), plus splash (32/s) and steam (14/s) at the fire, and a looped
`Sounds.Spray` clone at volume 0.9, pitch 0.85, rolloff 15 to 160. It fades out and cleans up ~3 s after
spraying stops. Works for any player's truck, not only the local one.

**Ride pose (RideFX).** Local player, Riding ~= "": loops `Animate.sit.SitAnim` (fallback R15 2506281703 / R6
178130996) at Action priority; stops on dismount, death or respawn.

**Godspeed (RideFX).** Gold Trail (two attachments on HumanoidRootPart) on any player with Pass_Godspeed true
while horizontal speed > 8 and not riding. **Server Boost.** Two sparkle emitters (green, purple), 5/s each,
on every player while `BoostUntil > GetServerTimeNow()`, off beyond 120 studs. **Infinite Tank.** Pulsing cyan/gold
"∞" BillboardGui on the tool's `Gauge` (else `Handle`) when `InfiniteWater` is true (one billboard, no particles).

**Verified (one playtest, lock released, DebugCoins/BoostUntil/DebugSkip cleared).**
- Via client Shop remote with DebugCoins 20000: BuyHose 2-6, EquipHose each tier, BuyPass InfiniteTank /
  Godspeed / Truck, BuyProduct ServerBoost; sprayed with `Remotes.Spray:FireServer(firePos, true)`.
- Read back per tier: tool Tier 1-6; beams enabled (1 or 2 for T3); Jet/Drops colour, emission and rate as
  designed; T5/T6 light on; T6 storm part rotating; beam attachment X axis = up (0.998 Y); twin beams offset.
- Truck: Riding "Truck", RideModel had a `Cannon` attachment, sit track playing at Action priority and stopped on
  dismount; TruckSpraying true near fires gave muzzle rates 110/45, sound volume 0.85, target 1.5 studs above the fire.
- Godspeed trail Enabled while moving (33.8 studs/s) and off when stopped; boost aura rate 5 while boosted.
- No script errors in the server or client log (only the expected Studio DataStore messages).

**Not verified.** All visuals by eye: `screen_capture` returned a black 3D view (window hidden), so the look of
each tier, the arc shape, the swirl and the colours are checked by property values only. Needs a real-client look,
especially T4 foam density, T6 swirl, and the truck arc against the real Truck model. Sit pose was verified as a
playing Action track, not visually. Ride pose for non-local players relies on replication of the owner's track.

**Requests for others.**
- UI designer: with InfiniteWater true the HUD water bar showed "Tank empty!" (Water attribute reaches 0 but the
  server ignores it). The HUD should treat `InfiniteWater` as full.
- Lead: `Hose` tier-1 tool in StarterPack has no `Tier` attribute until `giveHose` runs (fine in play).


## Round 5 (crew FX)

**File.** New `StarterPlayer.StarterPlayerScripts.CrewFX` (LocalScript), mirrored byte-identical to
`src/StarterPlayerScripts/CrewFX.client.lua` (19207 bytes, hash-checked against Studio). HazeFX and all
other scripts untouched. Everything is client-side, built under `workspace.LocalCrewFX`.

**1. Ping pillars** (`Remotes.Ping.OnClientEvent(player, kind, pos)`). Per ping: an anchored invisible part at `pos`
with (a) a camera-facing Neon-style Beam, 80 studs tall, transparency gradient base to top, and (b) a BillboardGui
(studs-sized, so it keeps perspective) with 3 vertical-gradient layers (wide halo, mid, white-ish core). Billboards
ignore Atmosphere fog, so the column stays visible in thick haze. Colours: Fire orange, Water blue, Help red,
Follow green. Fade in 0.35 s, gentle breathing, fade out over the last 2.2 s, gone at 8 s. A flat ground ring
(`explosion01_shockwave`, re-emitted 3 times at 0 / 1.5 / 3 s). One pillar per player (a new ping replaces theirs),
max 8 at once. Not distance-gated, as requested. No icons: the HUD billboards are the UI designer's.

**2. Downed** (`Downed` player attribute, every player). Soft red Highlight on the character (AlwaysOnTop, pulsing
fill 0.62 to 0.82, outline pulse). "SOS" smoke flare: red/orange smoke_main column rising ~50 studs, emitted as
Morse puffs (3 dots, 3 dashes, 3 dots, 9 s cycle; about 20 puffs per cycle, so negligible budget). Local player only:
the sit animation (Animate's `SitAnim`, fallback R15/R6 id) loops at Action priority while Downed, so it
replicates; it stops on revive, pass-out or respawn. Highlight and flare are off beyond 250 studs from the
camera (checked every 0.4 s; the local player is always on). Cleared on Downed false, death, respawn or leaving.
**Revive** (Downed true to false and Health still > 5 after 0.35 s, which separates it from the pass-out, where the
server zeroes Health): 34 green/white sparkles + a soft green glow puff on the root, `Sounds.Success` clone at
Volume 0.25, rolloff 90. Skipped for others beyond 120 studs.

**3. Clean-air relief.** Local player inside the FireStation bounding box (recomputed every 5 s, same box as the
server safe zone) and Health < MaxHealth: a green "+" (pooled-free billboard, 30 px, GothamBlack) every 0.3 s that
drifts up 4.5 studs and fades (about 5 alive at once). No built-in plus texture exists, hence text billboards.

**Verified (one short playtest, lock set then cleared, DebugAPI cleared, play stopped).**
- Ping:FireServer("Fire", pos): `PingPillar_Fire` created at pos, 3 frame layers fading, beam transparency
  animating, part removed by 8 s; Water/Help/Follow fired in sequence: replaced the owner's previous pillar (1 part).
- DebugAPI 380 + Health 3 on the server: Downed true, Health 1; DownedGlow present and enabled, fill pulsing,
  SOSFlare part present, track 2506281703 playing at Action priority; at 8 s (solo) Downed false, Health 0, all FX
  removed, respawned at 100 with no leftover Highlight/flare/track.
- Revive path simulated from the server (Downed true, then false + Health 40): `ReviveFX` attachment with 2 emitters
  and a Success sound (Volume 0.25) appeared for ~2.5 s, then cleaned up. The solo pass-out did not trigger it.
- Station: teleported to (-40,4,-40) at 20 HP: 1 to 7 "+" billboards alive while it healed to 78.
- Client and server logs: no script errors (only Studio's own UIBlox/Plugin warnings).

**Not verified.** (a) Real multi-client revive (RevivePrompt, another client seeing the Highlight, flare and slump
animation replicate): only the code paths above were run, no second client via MCP. (b) Anything by eye:
`screen_capture` does not draw BillboardGuis and the 3D view is unreliable in play, so pillar look, flare readability
in band 5 haze and the "+" look are checked by property reads only. (c) Whether the sit animation looks right while
walking at speed 4. (d) The ring texture's flatness on slopes.
**Requests.** None for other roles. If the HUD ping icon sits at the same world point, anchor it at pos + ~6 studs
so it does not overlap the pillar core.
