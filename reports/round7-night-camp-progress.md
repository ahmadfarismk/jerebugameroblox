# Codex round 7 — Night, Camp and upgrades

18 October 2026. Supersedes round 6's statement that Night/Camp are unbuilt.

## Implemented

- Survival now runs Day (240 seconds), Night (60), Camp (20). Story retains its Report flow. A completed survival day is counted after surviving Night. Crew-down checks cover all three survival phases.
- Night moves the clock from 20:00 through midnight to 04:00, darkens the existing client atmosphere gently, and starts up to `2 + floor(day/3)` small fires on eligible trees within 150 studs of camp, respecting the multiplayer fire cap. Fires remain sprayable. Remaining night fires clear before Camp.
- Night haze damage is half strength. Station and camp protect players at night; the station retains its healing. At the halfway checkpoint, if every connected player is alive, not downed and in camp/station, the crew rests, skips the rest of Night and receives 5 personal coins each.
- Camp Fund receives an additional 25% of actual paid fire shares. Personal rewards remain whole. Exact quarter-coins are retained. Scout/revive/rest rewards do not contribute. Fund and upgrades are run-local, never persisted.
- Kiosk opens the camp menu during Survival Camp; otherwise it opens the existing shop. Fund/menu UI uses the shared purple/green kit, displays prices and built state, disables unavailable purchases, and scales down for small Studio viewports.
- Water Tower: 300 fund; existing camp refill 30 to 60, additional refill zone at 60.
- Field Kitchen: 250 fund; camp becomes safe by day too, healing 4 HP/sec.
- Rescue Shelter: 500 fund; revive prompt 1.2 seconds, downed duration +10 seconds. Downed bar reads effective duration.
- Purchases are server-owned: known string ID, Survival/Camp, alive/non-downed, within 16 studs of kiosk, sufficient funds, not already built, 0.4-second request cooldown. Check/debit/build has no yield, preventing duplicate concurrent spending.
- Existing camp models remain intact. Three bounded green upgrade indicators and one refill part are created once per server, reused/reset each run. No accumulating per-run instances.

## Files / ownership

New: `src/ServerScriptService/CampUpgrades.lua`, `src/StarterPlayerScripts/CampUI.client.lua`.

Updated: `JerebuServer.server.lua`, `CampServices.server.lua`, `HUD.client.lua`, `DownedUI.client.lua`, `HazeFX.client.lua`. HazeFX change is only a smoothed survival-night atmosphere/ambient/brightness adjustment; API band colors and thresholds are unchanged. Progression and save code are unchanged.

`build/round7_patch.py` records the one-time source transformation; **do not rerun** it against the already transformed source.

Studio backup: `ServerStorage.Backup_PreCamp_20261018`, including the previous HazeFX. All seven final script sources were compared against local files with line-ending/trailing-whitespace normalization: all matched.

## Tests actually run

Two real Studio clients (Player1 and Player2), with Studio-only accelerated days/nights:

- Both voted Survival. Recorded Intermission → Day → Night → Camp → Day → Night → Camp.
- Eight-second test nights completed at about four seconds with both players safely at camp, exercising the halfway rest path. Camp lasted approximately 20 seconds.
- Both clients sent competing purchases, including duplicate Water Tower requests. Starting fund 1,050 ended at exactly 0, with all three upgrades built once. Both clients replicated built state. Both refill rates were 60.
- Kitchen: player health 50 → 58.329 in about two seconds during Day.
- Shelter: forced haze collapse produced effective downed duration 35 seconds and revive prompt HoldDuration 1.20000005. Completing an upgraded revive hold was not separately exercised.
- Additional tower zone: water 0 → 30.939 in about half a second.
- Server and both clients returned no MessageError entries at the multiplayer checks.

Follow-up solo integration / visual checks:

- Actual hose extinguish: personal coins 2,295 → 2,307 (+12), Camp Fund 0 → 3, confirming the bonus does not tax the reward.
- Malformed/unknown and valid purchase requests during Day did not build or spend. This is an out-of-phase rejection check, **not** independent proof of the distance or insufficient-funds checks.
- Crew-down ending then new Intermission reset fund to 0 and Water Tower flag to false.
- Native screenshot caught overlapping kit button Text/Label; fixed to use the kit's Label and SetEnabled API. Follow-up native screenshot confirmed single price labels, grey disabled buttons, and the complete panel fitting a small Studio viewport (UIScale approximately 0.552).
- Final solo client and server MessageError lists were empty.

Tests used normal client remotes, plus server-side test positioning, temporary health/water changes and Studio-only debug attributes. No server modules were required from execute_luau. Debug hooks added: DebugNightLength, DebugCampLength and DebugCampFund, all gated by IsStudio. Production durations remain 60/20. Lock cleared, tests stopped; no Debug*/Test* attributes remained in Edit.

## Remaining checks / next work

- This round tested **two concurrent clients**, not six. Six-player stress, phone touch input, live persistence, independent distance/insufficient-funds rejection, exact night half-drain measurement, and completing the shortened revive hold remain acceptance checks.
- Night darkness is implemented and runtime-smoke-tested; full visual balance at all API bands remains for VFX review.
- First upgrades use simple green status fixtures on the existing buildings. More elaborate upgrade art is not added.
- Other three camp upgrades, daily events, persistent survival bests/leaderboards and milestone rewards remain future stages.
- Earlier unresolved items remain: place player limit last verified at 60, two image loading checks, live save acceptance. No publishing was performed.

## Save status

Saved successfully with Ctrl+S. Studio Output at **17:33:05.946** confirmed: `Saved new changes in 'Bahaya Jerebu!' to Roblox.` Final seven script sources match `src/`. Only the main place remains connected; the playtest lock is clear. Saved, not published.
