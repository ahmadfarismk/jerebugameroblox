-- Run in Studio against the shared, stateless module (never require Progression).
local R = require(game.ReplicatedStorage.Jerebu.SurvivalRules)
assert(R.winner(0, 0) == "Story")
assert(R.winner(3, 3) == "Story")
assert(R.winner(2, 3) == "Survival")
assert(R.day(1).radius == 360 and R.day(3).radius == 520 and R.day(6).radius == 9999)
assert(math.abs(R.day(10).burst - 9.1) < 0.00001)
assert(R.respawnDelay(1) == 12 and R.respawnDelay(25) == 60)
for day = 1, 100 do
	local c = R.day(day)
	assert(c.spawnEvery >= 6 and c.spawnEvery <= 26)
	assert(c.peat <= 0.6 and c.wind <= 2 and c.growth <= 1.6 and c.haze <= 60)
end
local t = 0
for _ = 1, 959 do t = R.hazardExposure(t, 300, 0.25) end
assert(t < 240)
t = R.hazardExposure(t, 300, 0.25)
assert(t == 240)
assert(R.hazardExposure(t, 299, 0.25) == 0)
assert(R.hazardExposure(0, 500, 1) == 1)
assert(not pcall(R.day, 0) and not pcall(R.day, 1.5))
return "Survival rules: vote, curves, bounds, respawn and continuous hazard checks passed"
