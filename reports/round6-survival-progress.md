# Codex round 6 — multiplayer checks and survival stage 1

**Codex round 7 (18 October 2026):** Night/Camp, Camp Fund and the Water Tower, Field Kitchen and Rescue Shelter upgrades are implemented. Read `reports/round7-night-camp-progress.md` for exact scope, two-client multiplayer evidence, save status and remaining checks. This supersedes earlier statements that those stages are unbuilt.

18 October 2026. Survival stage 1 is implemented and tested as described below. This report supersedes earlier unsaved-state and unbuilt-survival notes; later survival stages are still unbuilt.

## Save and defaults

- Saved Claude's rounds 4–5 changes to Roblox; Studio confirmed at 15:10:04.960. No publish action.
- **Final save confirmed at 15:33:31.587:** Studio displayed `Saved new changes in 'Bahaya Jerebu!' to Roblox.` after the round-6 changes and test cleanup. Only the main Studio remained connected. All four changed/new sources matched local files after line-ending normalization; saved DayLength is 240. Not published.
- User approved survival available immediately, 240-second days, and immediate crew-down ending (no last stand).
- ServerStorage.Backup_PreSurvival_20261018 preserves the pre-change server, HUD and DownedUI sources.

## First two-client checklist session

- Two actual clients joined; crew panels existed on both.
- Forced hazardous API and low HP outside the station. Player1 collapsed, downed banner enabled, own revive prompt disabled locally.
- Player2 held the actual ProximityPrompt using InputHoldBegin/End for 2.7 seconds. Server cleared Downed and removed the prompt; helper coins rose from 0 to 6. Health was read later while hazardous damage continued, so exact 40 HP was not captured at the revive instant.
- Four Help pings sent immediately produced exactly one received broadcast, validating the cooldown. Subsequent Fire ping arrived on both-client flow.
- Player1 marked a nearby fire; Player2 equipped the hose and sprayed via the normal Spray remote. Player1 received 3 scout coins; Player2 received 12 fire coins (18 total including revive).
- Crew row showed visible REVIVE! on the second collapse.
- Advanced DownedUntil to exercise expiry without waiting out the whole countdown. Player respawned at station (-30, ~5, -34), 100 HP, Downed=false and no RevivePrompt. This verifies expiry cleanup, not the full natural 25-second timing.
- Server log had zero MessageError entries in that session. Session stopped and test lock cleared.
- Further checks are recorded below; unverified checklist items are explicitly listed.

## Implemented and runtime-checked

- Shared pure SurvivalRules module: documented daily curves, milestone burst multiplier, vote tie resolution and capped respawn delay.
- Server-owned intermission voting (validated mode strings, per-player cooldown, leave cleanup), default Story/tie to Story.
- runDay accepts its settings explicitly. Story passes its unchanged Config.Days entry; survival passes generated settings. Fire growth, spread, API haze and spawn radius consume these settings.
- Survival endless day/report loop, crew-down and continuous hazardous-day ending, days survived, per-participating-day coin rewards, session-best result and increasing respawn delay.
- Survival refreshes forest fuel at each day's start so the finite tree pool cannot silently exhaust. Story tree lifecycle is unchanged. Dedicated Night/Camp phases are not built yet.
- Main-menu vote buttons, survival day label/results, and teammate camera during survival respawn.
- Shop backdrop fix: a close toggle above the modal mirrors the original SHOP button's position while open. Other HUD elements keep their existing layer.
- Collapse overlap fix: suppress only the redundant local collapse toast while Downed; the banner retains the collapse message/countdown. Other notifications remain.
- Files: JerebuServer.server.lua, HUD.client.lua, new SurvivalRules.lua and SurvivalSpectate.client.lua. Source matches Studio after CRLF/trailing-whitespace normalization.
- Pure rules checked for days 1–100 and tie/default behavior. No server ModuleScript was required by the test tools.

## Deliberately later stages

Night/camp phases, Camp Fund/buildings, daily events, persistent survival best/leaderboards, badges and Second Wind remain unbuilt. Session best is labeled as such. No new paid products were created.

Player cap still last verified at 60; Firefox automation remains unsupported. Live save testing, real-phone testing and publishing remain outstanding.

## Follow-up test results

| Check | Actual result |
|---|---|
| Two-client survival vote | Both votes counted; selected Survival. Voting is server-owned and restricted to Intermission. |
| Shared fire payout | Player1 gained 1 coin; Player2 gained 11. Total 12 for one ordinary fire, reflecting unequal spray times. Peat split was not separately exercised. |
| Distant scout rejection | Player1 pinged from 400.02 studs away. Scout coins stayed 224; firefighter coins rose 249 → 261. |
| Two-player scaling | Phase-transition monitor captured exactly 3 initial fires and FireCap=25. Six-player cap 34 is confirmed by Config/formula, not a new six-player stress test. |
| Collapse overlap | Downed=true and banner enabled; toast contents had hazardous-air/school notices but no duplicate local collapse toast. |
| Shop toggle | Actual native mouse click on CLOSE SHOP closed the modal; both shop and toggle Visible=false afterward. Corrected positioning relative to HUD origin after detecting an off-screen position in an inactive viewport. |
| Days beyond seven | DebugSkip advanced the two-client Survival run to Day 12; 11 completed days, FireCap=25, increasing respawn delay. |
| Crew-down ending | Both marked down; Phase=Ended, RunOver=true, results showed 11 days and 220 run coins. |
| Story regressions | Three seven-day runs produced clear, survived and emergency endings with controlled API values. Initial test driver failed to reapply unchanged DebugAPI values; corrected driver clears the attribute before setting it. Only the corrected results establish ending-category coverage. |
| Evacuation ending | New Studio-only DebugDayLength=4; both clients received evacuated after HazardousSeconds=4, DayDuration=4. The shared-rules test separately checks continuous 240-second exposure and reset below 300. This is accelerated integration testing, not four real minutes at Hazardous. |
| Error logs | Final two-client and inspected solo regression server/client histories had zero MessageError entries. |
| Cleanup | Test server stopped, session closed, TemporarySurvivalVoteTest and TemporaryBurstMonitor removed; playtest lock cleared. Final Edit scan found no Debug*/Test* attributes. |

Rules regression source: `tests/survival_rules.spec.lua` (executed successfully in Studio against the shared pure module). It covers voting ties/default, days 1–100 bounds, day-10 burst, radii, respawn cap, hazardous threshold/reset and invalid day inputs.

## Checklist limits and next actions for Claude

- Natural 25-second downed expiry was accelerated; exact revive-instant 40 HP was not sampled. Actual hold-to-revive and +6 reward passed.
- Crew presence and REVIVE row passed; all ride icons/health/water presentation variants were not exhaustively inspected.
- Remote ping round-trip and cooldown passed. Native Q attempt coincided with a phase/modal transition and did not establish wheel/marker/pillar visual acceptance. Complete keyboard hold, touch and gamepad wheel checks on both clients.
- Truck remains driver-only by existing design; no passenger implementation or two-person ride claim. Driving/cannon and passenger rejection were not exercised this round.
- Survival respawn-delay value checked; new teammate spectate script still needs a full death/wait/respawn camera check.
- Water/BadgePeat recheck returned Loading after PreloadAsync; neither is confirmed fixed. Keep original fallback and fetch-failure notes.
- All new behavior remains unpublished. Keep Studio tests isolated from live saves; Progression was not edited in this round.
- Stage 2 should add Night/Camp phases and Camp Fund, replacing survival's temporary use of the existing Report phase. Stage 3 builds the camp upgrades. Defaults are approved; do not ask the same three design questions again.

## Installation and hooks

- New ModuleScript: `ReplicatedStorage.Jerebu.SurvivalRules` from `src/ReplicatedStorage/Jerebu/SurvivalRules.lua`.
- New LocalScript: `StarterPlayer.StarterPlayerScripts.SurvivalSpectate`.
- Updated `JerebuServer` and `HUD`; no Progression, Config tuning, world geometry or VFX source changes.
- `ModeVote` RemoteEvent is created by JerebuServer at startup. Attributes: Mode, StoryVotes, SurvivalVotes, SurvivalDay, DaysSurvived, RunOver, HazardousSeconds, FireCap, DayDuration; player ModeVote and SurvivalSessionBest.
- `DebugDayLength` is accepted only in Studio, between 1 and Config.DayLength, and read at the next day's start. Clear it after tests. Saved Config.DayLength remains 240.
