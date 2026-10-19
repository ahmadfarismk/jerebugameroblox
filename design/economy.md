# Jerebu economy model

Simulator: `python design/economy_sim.py` (add `--quiet` to hide the per-day tables). Results and proposed
numbers are in `reports/economy-balancer-report.md`.

## What the model assumes
- One run = 7 days x 240 s, about 30.5 min of wall time.
- Fires spawned per day = burst + 240 / spawnEvery, x1.15 from Day 2 for spread. Measured by the tester: Day 1 = 11, Day 2 = 16.
- A player's capacity (fires put out per day) = 240 s / seconds per fire.
  Seconds per fire = travel + spray + peat soak + refill trips.
  Calibrated to the tester: a base player puts out about 10 fires on Day 1, and walking is about 70% of the day.
- Upgrades act through the same formulas as `Progression.stats`: Speed (walk), Pressure x hose power (spray time),
  Tank x hose tankMul (refill trips), Range (shorter approach), Refill (pump speed), Lungs + mask (less haze slowdown),
  Bicycle / Kapcai (travel speed, +2 s hop on/off), Truck (40 speed, 80 dmg/s, radius 30, peat still soaked on foot).
- Fires put out = min(sum of player capacities, 92% of spawned). Players split the fires by capacity share,
  matching the server's split by damage contribution.
- Coins per fire = FireReward / PeatReward weighted by the day's peat chance, x2 with VIP or 2x Coins.
  End-of-run bonus (clear / survived / emergency) depends on how many fires the team kept up with.

## Shopping policies
- **greedy**: always buys the cheapest next item (a casual player). Buys Lungs and Refill early, N95 late.
- **guided**: N95, Bicycle, Kapcai first (the milestones the game wants), then the best capacity gain per coin.

## What the model says about the design
1. Income is fire-limited, not upgrade-limited. A run only spawns about 140 fires, so a player with ~12 fires/day
   capacity already catches most of Days 1-3 and income per run flattens (about 1,900 coins/run when proposed).
   Late upgrades make you stronger but do not raise income, so the length of the grind is set by prices.
2. Co-op divides income. Spawns do not scale with player count, so 4 players each earn about 1/3 of a solo player.
   Fixing it needs one server change (see the report); Config alone cannot do it.
3. The Truck is fast but not a coin machine: it is fire-limited too, so a solo truck owner finishes the shop at about
   the same time as a free player. A free player next to a Truck owner keeps 26-28% of fires in run 1 and about 50% by run 5.
4. Cloth and Surgical masks are a price trap: Progression allows tier jumps, so N95 straight away is always cheaper.
