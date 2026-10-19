# Economy Balancer report: Jerebu (2026-10-17)

Files: `design/economy_sim.py` (run with python), `design/economy.md` (model notes), this report.
No Config, Studio or script was edited.

## 1. Verdict
The current economy is close for a player who follows the goals, but it **misses your targets for a casual player** and **falls apart in co-op**.
- A casual (cheapest-first) player reaches **N95 in run 4, Bicycle in run 5, Kapcai in run 17**. Targets were Day 2-3, end of run 1, run 2-3.
- Four free players on one server never finish the shop in 60 runs (about 25+ hours). Spawns don't scale with player count, so each player earns about 1/3 of what a solo player does.
- Income per run flattens at about 1,500 coins/run solo after about 5 runs, because the server only spawns about 140 fires per run. More power after that does not raise income.
- The truck is **not** pay-to-win for coins (section 5).

Proposed fix: small Config changes (rewards x1.2, N95/Bicycle/Kapcai cheaper, top two hoses dearer) plus a run-bonus change and **one optional server change** for co-op (spawn scaling).

## 2. Assumptions
Full model in `design/economy.md`. Key calibration: a base player puts out about 10 fires on Day 1 (tester: 10 of 11) and 8-10 on Day 2 (tester: 10 of 16). One run is about 30.5 min.
Two shopping styles are simulated: **casual** (always buy the cheapest item) and **guided** (N95, Bicycle, Kapcai first, then best gain per coin). Real players sit between the two.
Not modelled: Server Boost, Godspeed, Infinite Tank (time-savers on top), unlucky fire spread, and players leaving mid-run.
Days 3-7 are extrapolated from the spawn schedule and haze slowdown; the tester only measured Days 1-2.

## 3. Day-by-day, runs 1-3 (solo free player, guided)
Reading it: current Day 1 pays about 110 coins, enough for a first upgrade (Tank Lv2 costs 40) but N95 (160) needs Day 2 and the bicycle (250) needs Day 4-5.
Proposed Day 1 pays about 133: still a first upgrade, N95 on Day 2, Bicycle on Day 3, Kapcai in run 2.

#### CURRENT, guided solo free player

| Run | Day | Spawned | Capacity | Put out | Coins earned | Banked after buying |
|---|---|---|---|---|---|---|
| 1 | 1 | 11.2 | 10.1 | 10.1 | 110 | 110 |
| 1 | 2 | 16.0 | 8.2 | 8.2 | 92 | 42 |
| 1 | 3 | 19.7 | 8.6 | 8.6 | 99 | 140 |
| 1 | 4 | 23.0 | 7.6 | 7.6 | 90 | 230 |
| 1 | 5 | 25.8 | 7.6 | 7.6 | 92 | 72 |
| 1 | 6 | 30.8 | 10.9 | 10.9 | 135 | 207 |
| 1 | 7 | 34.5 | 10.8 | 10.8 | 137 | 345 |
| 1 | end | | | | +15 bonus | track Lv [1, 1, 1, 1, 1, 1], hose 1, mask 3, rides ['Bicycle'], banked 360 |
| 2 | 1 | 11.2 | 13.3 | 10.3 | 113 | 472 |
| 2 | 2 | 16.0 | 12.7 | 12.7 | 142 | 614 |
| 2 | 3 | 19.7 | 12.0 | 12.0 | 138 | 752 |
| 2 | 4 | 23.0 | 11.1 | 11.1 | 132 | 884 |
| 2 | 5 | 25.8 | 11.0 | 11.0 | 134 | 1017 |
| 2 | 6 | 30.8 | 10.9 | 10.9 | 135 | 1153 |
| 2 | 7 | 34.5 | 10.8 | 10.8 | 137 | 1290 |
| 2 | end | | | | +15 bonus | track Lv [1, 1, 1, 1, 1, 1], hose 1, mask 3, rides ['Bicycle'], banked 1305 |
| 3 | 1 | 11.2 | 13.3 | 10.3 | 113 | 1418 |
| 3 | 2 | 16.0 | 12.7 | 12.7 | 142 | 19 |
| 3 | 3 | 19.7 | 15.6 | 15.6 | 180 | 14 |
| 3 | 4 | 23.0 | 15.9 | 15.9 | 188 | 67 |
| 3 | 5 | 25.8 | 16.2 | 16.2 | 196 | 28 |
| 3 | 6 | 30.8 | 16.5 | 16.5 | 205 | 233 |
| 3 | 7 | 34.5 | 16.4 | 16.4 | 208 | 96 |
| 3 | end | | | | +35 bonus | track Lv [1, 5, 4, 2, 2, 1], hose 2, mask 3, rides ['Bicycle', 'Kapcai'], banked 131 |

#### PROPOSED, guided solo free player

| Run | Day | Spawned | Capacity | Put out | Coins earned | Banked after buying |
|---|---|---|---|---|---|---|
| 1 | 1 | 11.2 | 10.1 | 10.1 | 133 | 133 |
| 1 | 2 | 16.0 | 8.2 | 8.2 | 112 | 105 |
| 1 | 3 | 19.7 | 8.6 | 8.6 | 120 | 25 |
| 1 | 4 | 23.0 | 11.1 | 11.1 | 160 | 185 |
| 1 | 5 | 25.8 | 11.0 | 11.0 | 163 | 349 |
| 1 | 6 | 30.8 | 10.9 | 10.9 | 166 | 515 |
| 1 | 7 | 34.5 | 10.8 | 10.8 | 169 | 683 |
| 1 | end | | | | +25 bonus | track Lv [1, 1, 1, 1, 1, 1], hose 1, mask 3, rides ['Bicycle'], banked 708 |
| 2 | 1 | 11.2 | 13.3 | 10.3 | 136 | 845 |
| 2 | 2 | 16.0 | 12.7 | 12.7 | 172 | 1017 |
| 2 | 3 | 19.7 | 12.0 | 12.0 | 168 | 1185 |
| 2 | 4 | 23.0 | 11.1 | 11.1 | 160 | 55 |
| 2 | 5 | 25.8 | 15.0 | 15.0 | 221 | 7 |
| 2 | 6 | 30.8 | 16.0 | 16.0 | 244 | 15 |
| 2 | 7 | 34.5 | 16.4 | 16.4 | 255 | 271 |
| 2 | end | | | | +60 bonus | track Lv [1, 5, 4, 1, 2, 1], hose 2, mask 3, rides ['Bicycle', 'Kapcai'], banked 31 |
| 3 | 1 | 11.2 | 20.8 | 10.3 | 136 | 122 |
| 3 | 2 | 16.0 | 19.9 | 14.7 | 200 | 102 |
| 3 | 3 | 19.7 | 19.1 | 18.1 | 254 | 126 |
| 3 | 4 | 23.0 | 17.9 | 17.9 | 257 | 63 |
| 3 | 5 | 25.8 | 17.9 | 17.9 | 265 | 18 |
| 3 | 6 | 30.8 | 17.8 | 17.8 | 271 | 154 |
| 3 | 7 | 34.5 | 17.7 | 17.7 | 276 | 430 |
| 3 | end | | | | +60 bonus | track Lv [2, 8, 6, 5, 3, 1], hose 2, mask 3, rides ['Bicycle', 'Kapcai'], banked 25 |


## 4. Milestones, solo free player
| Milestone | Current, casual | Proposed, casual | Current, guided | Proposed, guided | Target |
|---|---|---|---|---|---|
| First upgrade | Day 1 | Day 1 | Day 1 | Day 1 | after Day 1 |
| N95 | run 4 day 1 | run 3 day 2 | run 1 day 2 | run 1 day 2 | Day 2-3 |
| Bicycle | run 5 day 4 | run 4 day 2 | run 1 day 5 | run 1 day 3 | end of run 1 |
| Kapcai | run 17 day 5 | run 14 day 2 | run 3 day 2 | run 2 day 4 | run 2-3 |
| Hose 2 | run 6 day 6 | run 5 day 4 | run 3 day 7 | run 2 day 7 | run 1-2 |
| Hose 3 | run 15 day 5 | run 12 day 5 | run 5 day 6 | run 4 day 5 | |
| Hose 4 | run 19 day 2 | run 15 day 3 | run 7 day 3 | run 5 day 6 | |
| Hose 5 | run 22 day 1 | run 17 day 7 | run 13 day 6 | run 11 day 3 | |
| Hose 6 | run 27 day 7 | run 23 day 3 | run 19 day 7 | run 16 day 7 | |
| All six tracks Lv10 | run 16 | run 13 | run 24 | run 20 | |
| **All max** | run 27 (13.7 h) | run 23 (11.7 h) | run 24 (12.2 h) | run 20 (10.2 h) | 10-15 h |

Casual players still miss the Kapcai target (cheapest-first leaves the dearest item for last). A shop "next goal" highlight on N95, Bicycle and Kapcai would close that gap (UI request, not a number).

Coins earned per run, solo free (runs 1-12):
- Current guided: 770, 945, 1266, 1393, 1416, 1427, 1481, 1496, 1506, 1513, 1515, 1515
- Proposed guided: 1048, 1417, 1719, 1751, 1778, 1839, 1855, 1867, 1867, 1867, 1884, 1885

## 5. Other player types (proposed Config, guided)
| Player | N95 | Bicycle | Kapcai | Hose 6 | All max |
|---|---|---|---|---|---|
| Solo free | run 1 day 2 | run 1 day 3 | run 2 day 4 | run 16 | run 20 (10.2 h) |
| Solo 2x coins (VIP / 2x Coins) | run 1 day 1 | run 1 day 2 | run 1 day 6 | run 8 | run 10 (5.1 h) |
| Solo Truck owner | run 1 day 2 | run 1 day 3 | run 1 day 7 | run 20 | run 20 (10.2 h) |
| 2 free players | run 1 day 2 | run 1 day 4 | run 2 day 5 | run 24 | run 30 (15.2 h) |
| 4 free players | run 1 day 3 | run 1 day 6 | run 3 day 5 | run 44 | run 55 (27.9 h) |
| 4 free players + co-op spawn scale 0.5 | run 1 day 2 | run 1 day 4 | run 2 day 5 | run 21 | run 25 (12.7 h) |

- **2x coins** halves the shop time (10 h to 5 h). A real speed-up, and it takes nothing away from a free player.
- **Truck**: capacity is about 25 fires/day vs 10 for a base player, but the server only spawns 11-35 fires a day, so a solo truck owner finishes the shop in the same time as a free player. The truck gives early power, not extra coins.
  A free player alongside a truck owner keeps **26-28% of fires in run 1**, rising to **about 50% by run 5** once they have upgrades. They are not pointless, but run 1 is thin, so watch the first-hour experience of a free player in a truck server.
- VIP and 2x Coins do not stack (`coinMul` is 2 if either is owned). A player who buys both wastes 149 R$. Say so in the DoubleCoins description, or make VIP the one that includes it.

## 6. Problems found
1. **Casual players miss the N95 target** (run 4 vs Day 2-3). Cheapest-first buys Speed, Refill and Lungs first. Cloth (30) and Surgical (80) masks are a trap because the tier jump to N95 is allowed (buying them first wastes 110 coins).
2. **Co-op divides income.** Each of 4 players earns about 40-60% less than solo. Needs the server change in section 7.
3. **Income plateau.** After about run 5 a solo player's income is capped by the fire count (about 140 per run), so Lv10 stats don't pay more. All-max length is therefore set purely by prices.
4. **Kapcai at 1,500** is out of reach for casual players (run 17).
5. **Late hoses were cheap** against a 10-15 h target: the legendary Storm Cannon arrived in run 19 for a guided player.
6. **Run bonus is almost nothing for losers** (15 coins on a bad run).

## 7. Server change request (not Config, for the lead)
In `JerebuServer.server.lua`, scale spawns with player count so co-op doesn't dilute income:
```lua
local function coopMul(): number
	return 1 + 0.5 * (math.max(1, #Players:GetPlayers()) - 1)
end
-- runDay: for _ = 1, math.floor(cfg.burst * coopMul() + 0.5) do ... end
-- runDay: nextSpawn = cfg.spawnEvery / coopMul() * rng:NextNumber(0.75, 1.25)  (also the first nextSpawn)
```
Effect (simulated): 4 free players complete the shop in about 12.7 h instead of 27.9 h. Side effect: more fires means more API pressure with more players. That is the right direction for co-op, but the tester should check Days 3-4 with 3-4 players (`Config.MaxFires = 22` already caps the total).
Without this change, the fallback is a bigger reward bump, but then solo players finish too fast.

## 8. Ready-to-paste Config changes
```lua
Config.FireReward = 12            -- was 10
Config.PeatReward = 20            -- was 16

Config.Masks[3].price = 140       -- N95, was 160

Config.Hoses[5].price = 5000      -- Hydro Pack, was 4500
Config.Hoses[6].price = 10000     -- Storm Cannon, was 9000

Config.Rides[1].price = 200       -- Bicycle, was 250
Config.Rides[2].price = 1200      -- Kapcai, was 1500
```
Run bonus is hard-coded in `JerebuServer.server.lua` (about line 1108). Change
`ending == "clear" and 60 or (ending == "survived" and 35 or 15)` to
`ending == "clear" and 100 or (ending == "survived" and 60 or 25)`.
(Optional: move them into `Config.RunBonus = { clear = 100, survived = 60, emergency = 25 }`.)

Unchanged on purpose: `TrackCostGrowth` 1.45 and all six track bases, Hoses 2-4 (300 / 900 / 2200), Cloth 30, Surgical 80, Respirator 400, and every Robux price.
Total shop cost: 33,780 coins now, 34,910 proposed.

## 9. Premium sanity check
- Coin packs: 5,000 coins is about 14% of the shop for 349 R$. Buying the whole shop with packs would cost roughly 2,400 R$, so nobody skips the game cheaply.
- Godspeed, Infinite Tank and Truck save time without raising the income cap. Nothing paywalls protection: N95 is a coin item at 140.
- 2x Coins at 149 R$ is the best value and halves the grind. VIP at 299 gives the same 2x plus cosmetics, which is fine as the supporter tier.

## 10. Caveats
The model is an average-case estimate from two measured days. If the tester plays Days 3-5 and put-out counts differ by more than about 30%, adjust `RADIUS`, `DAY_BAND` and `CATCH` at the top of `economy_sim.py` and rerun.
