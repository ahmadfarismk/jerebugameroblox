# Bahaya Jerebu! — Hose & Havoc

Local, playable seven-day browser campaign for Dblox: seven daytime missions, six Malam defenses, camp upgrades, two mini bosses and Raja Jerebu. The original quick tutorial + Raja mode remains available. The existing Roblox project and source are untouched.

## Run

Tested on Windows with Node **24.14.1**, npm **11.11.0**.

```powershell
cd "C:\Users\faris\Documents\Projects\D_Blox\Game Testing\browser-handoff\hose-and-havoc"
npm ci
npm run dev
```

Open the Local URL Vite prints. For the production version:

```powershell
npm test
npm run build
npm run preview -- --port 5175
```

Phaser **3.90.0**, Vite **6.1.0**, TypeScript **5.7.3** are pinned; `package-lock.json` is included. Serve `dist/` over HTTP, rather than opening its HTML as a `file:` URL. No backend, Roblox login, paid APIs, or external runtime requests are used.

## Play

1. Pick Spray. Tap the hydrant at **row 5, column 2**, then adjacent tiles ending at a fire. Mouse dragging also builds a route.
2. Read the exact preview, then **Padam · Confirm**. Dry entered tiles cost 1 water; wet tiles cost 0. Routes have at most eight edges.
3. Refill spends one action for five water (seven with Water Tower). Emergency Spray is always available for one damage.
4. End Turn resolves only the displayed attack, expires effects, then deals the next hand. There is no thinking timer.
5. After each of days 1–6, play one Malam defense resolution. Protect the camp hydrant with Foam or rotate the attack with Wind Turn. Surviving grants +2 fund without integrity loss, otherwise +1, and camp ventilation removes up to 30 API. At camp, choose one affordable upgrade or Skip. Kitchen healing occurs once per later camp visit; reloading cannot repeat rewards.
6. Against Raja, douse both vents. Route **Burst Jet** to the core at **(0,2)** while open. It stays open through the next player turn. Three core hits win.

Keyboard: Tab to cards and tiles; Enter/Space selects. Arrow keys move tile focus; Enter adds it to the route. Escape, right-click, or Cancel clears the selection. Tap the preceding tile to backtrack. Mobile controls stay available at the bottom while the board/hand scroll vertically.

Sound starts muted. Enabling it only creates short original synthesized tones after a gesture. Reduced motion honors the OS preference and can be changed independently. Settings survive New Run.

## Implementation

- `src/engine.ts`: serializable state, seeded shuffle, central command validation, pure reducer, forecasting and save validation.
- `src/campaign.ts`: seven authored mission layouts, Malam rules and original CSS mini-boss portraits.
- `src/campaign-ui.ts`: campaign progress, objectives, boss hints, camp and final run journal.
- `src/data.ts`: starter deck, card rules/descriptions, upgrade definitions, API bands.
- `src/board.ts`: Phaser board, supplied image textures, code-drawn terrain, wet/foam/intent markers, water effects. Rendering never advances rules.
- `src/main.ts`: accessible DOM controls, tap/drag/keyboard input, settings and local save boundaries.
- `src/audio.ts`: gesture-triggered synthesized audio; silent fallback.
- `tests/`: rules regressions and the recorded browser victory replay.

Every valid command increments a revision and is logged with `crewId: solo-crew`. A stale revision is rejected. Previews run the same reducer on a clone. No networking is implemented or implied.

`localStorage` key `bahaya-jerebu-v1` now stores schema version 2. Existing version-1 saves migrate to the quick slice without losing progress. The save holds campaign day, completed encounter history, random state, board, resources, hand/draw/discard, intent, boss window, upgrades, camp identity and command log. Resume loads that state without rerolling or repeating purchases. Corrupt/incompatible saves show a recovery message on the title screen; New Run replaces them. Saves are device/browser/origin-local, **not cloud saves**. Development and production ports have separate saves. The app is not an installable/offline-cached PWA.

Tutorial assistance is explicit: the first hand contains the three starter Sprays. In quick mode only, the introductory boss starts with an assisted useful hand and swaps an existing Burst Jet into the hand when an opening starts and on its following turn if necessary. These swaps preserve all eleven cards; they do not create new cards. The campaign uses normal seeded draws, including Raja; the same eleven-card deck carries across every encounter. An optional seed on the title screen makes runs reproducible.

## Assets and provenance

Originals remain in the parent `assets/` folder. `scripts/prepare_assets.py` reads the supplied runtime map and writes alpha-preserving, aspect-correct WebP derivatives into `public/assets/`: icons up to 160px, Raja up to 512px. Python 3.13.15 and Pillow 12.3.0 were used. To regenerate: `python -m pip install Pillow==12.3.0`, then `npm run assets`.

The supplied images were generated for Bahaya Jerebu, according to `../ASSET-NOTES.txt`; original prompts and SHA-256 metadata remain in `../assets/reference/` and `../assets/asset-manifest.json`. Raja is a **static** supplied illustration with code-applied transforms, not an animation sheet. No original PNG was overwritten. No premium art, marketing background, reference UI, or GLB is in the runtime bundle. System fonts are used. Phaser/Vite/TypeScript retain their package licenses in `node_modules`; Phaser is MIT licensed. Project-art provenance is not a claim of exclusive IP rights.

## Validation and limits

See `TEST-RESULTS.md` for actual tests, seed and move transcript. The full production transfer was measured by downloading every build file, including runtime art, with `node scripts/measure-transfer.mjs http://127.0.0.1:5175`.

The campaign is: training → route chaining → Bara Bebola → peat rescue → Gambut Gempal → wind/rescue outpost → Raja Jerebu. Each of the first six missions is followed by a one-round Malam defense and camp. Bara takes 4 recoil when at least two ember impacts are blocked and briefly exposes its nozzle. Gambut's armor breaks permanently after both peat patches receive consecutive-turn Soaks; two Burst Jets then finish it. Days 4 and 6 require rescue. Day 7 ends the campaign directly.

The campaign adds explicit nightly fund rewards and up to 30 API recovery to support the longer run. Core card costs/damage remain unchanged. These are authored compact encounters; Malam uses the same camp-defense layout across six visits. Peat fights can take longer while waiting for consecutive Soak draws. Five sampled seeds produced three wins and two API defeats with the simple test player; this is not proof of universal seed balance or human pacing.

No co-op, accounts, monetization, endless mode, music or voice acting is included. No physical phone or Safari test has been performed. Run duration is not yet validated by human playtesting.
