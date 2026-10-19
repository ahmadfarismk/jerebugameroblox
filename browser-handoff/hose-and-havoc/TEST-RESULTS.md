# Seven-day campaign verification — 19 October 2026

## Current build

`npm test`: **21/21 passed**. `npm run build`: TypeScript and Vite passed. The Phaser large-chunk advisory remains. Full production HTTP response bodies: **1,748,578 bytes across 25 files**, including **210,844 bytes** of runtime art, measured with `scripts/measure-transfer.mjs`. No original authoring PNGs or GLBs ship.

Ten new campaign tests cover day/night/camp progression and deck conservation; mandatory night resolution and defeat precedence; Foam/Wind protection and exact forecasts; one-time Kitchen/ventilation/rewards/purchases; Bara recoil and opening duration; Gambut peat armor and second hydrant; required rescue and final-day completion; legacy-save migration and invalid progress; reachable objectives; and a complete seed-42 campaign with save/resume after every command. Eleven previous slice regressions also pass.

## Full browser run

Completed all seven days and six nights through in-app Chromium DOM controls, using legal routes chosen by the deterministic test player in `tests/campaign-player.ts`. No application state injection or automatic victory shortcut was used. The command sequence is `qa/campaign-42.json`; `qa/browser-campaign-log.json` records browser observations from command 21 onward (the earlier in-memory transcript was lost when the browser tool timed out). The first 21 actions were also executed and observed through controls.

**Seed 42: victory, 111 committed commands, 144 coins, 4/5 integrity, 194 API, 25 enemy resolutions.** The visible final journal lists all 13 encounters. Bara was defeated using two reflected ember counters. Gambut required both consecutive-turn peat clears and two Burst Jets. Days 4 and 6 required rescuing the house. Raja fell on its sixth player turn using normal campaign draws. Final browser error log was empty.

Reload/resume was exercised after a camp purchase and mid-Gambut: fund, purchased upgrade, hand, resources and boss state were preserved. Kitchen recovery was observed after later nights. Campaign mobile testing at 360×800 used browser clicks, including routes from both hydrants; no horizontal overflow was observed. Mini-boss portrait stretching and night-panel text contrast were found and fixed. Desktop finale was inspected at 1280×900.

`qa/campaign-raja.jpg` and `qa/campaign-victory.jpg` show the final campaign. Existing quick-slice captures remain historical evidence.

## Balance and limits

Five sample seeds were run with a simple legal-action test player: 42, 7 and 2373565907 won; 19 and 2026 lost to API during Raja. These results demonstrate completed runs and functioning defeat, not universal solvability. Gambut took eight turns in the browser seed; another sample took eighteen because of consecutive Soak draw timing. Human pacing and broader balance still need playtesting.

Each Malam is a one-resolution defense using the same camp board. Successful nights grant +2 fund without integrity loss, otherwise +1. Camp ventilation removes up to 30 API once. These are explicit campaign additions; original card costs and damage remain unchanged. The optional quick slice retains its prior assistance and rules. No seventh Malam follows the final boss.

Physical Android/iOS touch dragging, Safari, audible playback, storage-quota failure, and human session duration remain untested. No networking, accounts, monetization or offline installation is implemented.

---

# Earlier quick-slice verification — 19 October 2026

## Automated

`npm run build`: TypeScript check and Vite production bundle passed. Vite reports a large-chunk advisory because Phaser is bundled with the app; this is an advisory, not a build error.

`npm test`: 11 passing tests covering pure previews; exact route costs; invalid adjacency/repetition/obstacles; overspend and stale revisions; deterministic deck exhaustion; wet/foam expiry and impact consumption; boss shield rejection and opening duration; hazardous warning/loss; shelter charge; rescue anti-farming; Wind Turn once-per-turn rotation; consecutive peat Soaks; corrupt saves; one-time camp purchases; a deterministic replay of the browser victory, and a six-turn victory with no camp upgrades.

## Browser exercise

Used the Codex in-app Chromium browser through visible DOM controls. No developer state injection, solver actions, automatic wins, or console gameplay commands were used for the completed run.

- Tutorial completed by tapping each route and Confirm.
- Water Tower bought: fund changed 6 → 3. Reload → Continue retained the upgrade, disabled further purchases, and did not repeat the stipend.
- Raja beaten in six boss turns: **seed 2373565907**, **40 coins**, **4/5 integrity**, **114 API**, **22 commands**.
- The same command transcript remains an automated regression after subsequent fixes.
- At 360×800, keyboard Enter/ArrowUp routed to a fire, Escape canceled without spending, then successive tile clicks and Confirm extinguished it. Reduced motion was enabled.
- Mobile board measured approximately **51.5×51.5 CSS pixels per tile**. No horizontal page overflow after fixing the grid's minimum width. Hand scrolls horizontally; page scrolls vertically; critical action controls remain visible at bottom.
- Deliberately ending five turns without defense produced an evacuation warning and integrity defeat; replay started another game.
- Restart scene reuse was found broken during testing and fixed by constructing a fresh Phaser scene on every mount. Mobile overflow was also found and fixed.
- Temporarily removing the **derived** fire image produced readable `FIRE`/HP markers and kept the board playable. The file was restored. A post-load missing-texture check supplies a Retry banner.

Desktop was exercised at the browser's default approximately 1265×712 viewport and the production build at 1280×900; mobile at the explicit 360×800 override. Desktop canvas, icons, route lines and DOM cards were visually inspected. No physical touch hardware test or multi-point drag test was performed: the mobile exercise used single-target browser clicks and keyboard, not genuine touchscreen events. Pointer/touch drag is implemented but remains a device-testing item. Audio gesture gating was checked in code; audible playback was not independently verified.

## Winning move transcript

Tiles below use index `row * 6 + column`; rows/columns start at zero. Every route begins at hydrant 32.

| Stage | Committed actions |
|---|---|
| Tutorial T1 | Spray `32,26,20`; Spray `32,31,25`; Spray `32,33,34,28` |
| Camp | Buy Water Tower; reload/resume to verify; Continue |
| Boss T1 | Spray `32,26,20,14,8,7`; Burst Jet `32,26,20,14,15,16,10`; End Turn |
| Boss T2 | Burst Jet `32,26,20,14,8,2`; Refill; End Turn |
| Boss T3 | Spray left vent using T1 route; Spray right vent using T1 route; Refill; End Turn |
| Boss T4 | Burst Jet core using T2 route; Spray `32,26,20,14,13`; End Turn |
| Boss T5 | Spray left vent; Spray right vent; End Turn with one action unused |
| Boss T6 | Burst Jet core → victory |

No numeric balance values were changed from the brief. Boss rows are authored as 2, 4, 3 in successive Ember cycles; Dry Gust columns are 0, 5, 3. Peat Pop uses seeded eligible ground cells. Opening assistance is part of the disclosed introductory rules.

## Transfer measurement

Measured through HTTP against Vite's production preview, requesting identity encoding. All 25 production files, **including all runtime images**, totaled **1,732,527 response-body bytes** in the final measurement. This is a conservative full-build transfer, not a claim about a browser's cached resource timing or HTTP header overhead. The runtime art alone is **210,844 bytes**. The 70 MB handoff archive and original source PNGs are outside `dist/`.

## Remaining verification

- This historical section describes the earlier quick-slice verification; campaign results are above.
- Physical Android/iOS, Safari, actual touch dragging, audible sound, and real 10–15-minute pacing remain untested.
- Kitchen healing and corrupt-save recovery are engine-tested, not separately exercised through a browser-modified save.
- Missing-art text fallback was visually verified; service-worker offline installation is not implemented.
- Save errors are caught and reported, but browser storage-quota exhaustion was not forced.

