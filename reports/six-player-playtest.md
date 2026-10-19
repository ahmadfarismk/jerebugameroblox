# Six-player local smoke test — 18 October 2026

## Result

Partial pass: six real Studio clients connected to one local server, spawned alive, and simultaneously refilled at the new camp. This is not a full multiplayer acceptance or performance test.

## Evidence

- Started Studio's Server and Clients session, then selected six clients in Add Clients.
- Server returned Player1 through Player6, each with a character and health 100.
- Moved each character to a separate position in the camp refill zone and set Water=10 on the test server.
- Subsequent server read returned Water=100 for all six. Each of the six client reads independently returned Water=100, six connected players, and the streamed KemBombaRimba subtree present.
- All six clients had zero MessageError entries in their inspected LogService histories.
- API values advanced from 68 to 95 across sequential client reads. This confirms replicated active state, not an exact simultaneous synchronization measurement.
- Server log contained 18 GetAsync errors: StudioAccessToApisNotAllowed for JerebuSave_v2. Studio API access was not changed. Data persistence is unverified in this test.
- A UI probe looked for PlayerGui.HUD and returned false on all clients. Source inspection shows the actual ScreenGui is named JerebuHUD (with JerebuMenus separately). This probe was invalid and cannot establish UI failure or UI success. No six-client visual UI verification is claimed.

## Cleanup and settings

- Stopped the local server, invoked End Session in the parent Studio window, and cleared the owned AgentPlaytestLock attribute in Edit mode.
- Test character positions and Water mutations were runtime-only; no gameplay source changes were made.
- World save confirmation from the prior turn remains valid. No publishing was performed.
- Players.MaxPlayers remained **60** in the final Edit read. The requested value **6 has not been applied**.
- Firefox's open Dashboard tab is not exposed through supported browser tools. Earlier Windows automation explicitly stopped because URL-policy enforcement is unsupported for Firefox; this attempt did not bypass that restriction.

## Remaining work

1. Set the place's Maximum Players to 6 through an accessible Creator Dashboard browser, save, and verify persistence.
2. Verify six-client kiosk prompt interactions and correct JerebuHUD/health UI rendering.
3. Test actual six-player walking, truck passing/turning, and streaming along the bridges, peat boardwalk and lookout. Previous no-jump pathfinding checks remain separate evidence, not a six-player traversal test.
4. Test persistence in an appropriate permitted environment, plus mobile performance and the complete seven-day round.
