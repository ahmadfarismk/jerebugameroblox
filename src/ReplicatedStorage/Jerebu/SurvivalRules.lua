-- Pure rules shared by the server and deterministic tests. No player/save state here.
local Rules = {}

function Rules.day(d: number)
	assert(d >= 1 and d % 1 == 0, "day must be a positive integer")
	local burst = math.min(12, 2 + math.floor(d / 2))
	if d % 10 == 0 then burst *= 1.3 end
	return {
		spawnEvery = math.max(6, 26 * 0.93 ^ (d - 1)),
		burst = burst,
		peat = math.min(0.6, 0.15 + 0.03 * d),
		wind = math.min(2, 0.8 + 0.06 * d),
		haze = math.min(60, 8 + 3 * d),
		growth = math.min(1.6, 1 + 0.03 * d),
		radius = d <= 2 and 360 or (d <= 5 and 520 or 9999),
	}
end

function Rules.winner(story: number, survival: number): string
	return survival > story and "Survival" or "Story"
end

function Rules.respawnDelay(day: number): number
	return math.min(60, 10 + 2 * day)
end

function Rules.hazardExposure(previous: number, api: number, dt: number): number
	return api >= 300 and (previous + dt) or 0
end

return Rules
