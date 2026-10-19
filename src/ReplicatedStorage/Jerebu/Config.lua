--!strict
-- Jerebu: shared tuning + API band data (Malaysia official API bands, see concept doc)
local Config = {}

Config.TotalDays = 7
Config.DayLength = 240        -- seconds of firefighting per day
Config.Intermission = 20      -- before Day 1
Config.ReportLength = 14      -- night report between days
Config.EndingLength = 30

Config.StartAPI = 42
Config.MaxFires = 22          -- perf cap (phones)

-- per-day difficulty
Config.Days = {
	-- spawnEvery: seconds between new fires, burst: fires at dawn, peat: chance a new fire is peat,
	-- wind: spread multiplier, haze: transboundary API added over the day regardless of players
	{ spawnEvery = 26, burst = 2, peat = 0.15, wind = 0.8, haze = 8 },
	{ spawnEvery = 22, burst = 3, peat = 0.20, wind = 0.9, haze = 12 },
	{ spawnEvery = 17, burst = 3, peat = 0.25, wind = 1.0, haze = 16 },
	{ spawnEvery = 15, burst = 4, peat = 0.30, wind = 1.1, haze = 20 },
	{ spawnEvery = 13, burst = 4, peat = 0.35, wind = 1.25, haze = 24 },
	{ spawnEvery = 11, burst = 5, peat = 0.40, wind = 1.35, haze = 28 },
	{ spawnEvery = 10, burst = 6, peat = 0.45, wind = 1.5, haze = 32 },
}

-- fire behaviour
Config.FireGrowth = 1.8        -- intensity per second
Config.SpreadAt = 70           -- intensity needed to spread
Config.SpreadChance = 0.012    -- per second, per neighbour, before wind
Config.PeatSpreadMul = 0.4     -- peat patches sit close together; damp peat-to-peat spread
Config.SpreadRadius = 34
Config.BurnOutTime = 55        -- seconds at full intensity before the tree is burnt out
Config.PeatSoakTime = 2.5      -- extra seconds of water needed after a peat fire hits 0
Config.PeatReignite = { 22, 38 }
Config.SprayRadius = 10

-- API model
Config.APIPerFire = 0.055      -- API per second for a fire at 100 intensity
Config.APISmoulder = 0.012
Config.APIRecover = 0.22       -- API per second while no fires burn
Config.APIRain = 1.6
Config.NightPerFire = 7        -- each fire left at nightfall
Config.CleanDayBonus = 18      -- API drop for a day that ends with zero fires

-- cloud seeding (real rule: API > 150 for over 24 hours -> cloud seeding)
Config.SeedThreshold = 150
Config.SeedHold = 25           -- seconds above threshold (our "24 hours")
Config.RainTime = 45
Config.RainDamage = 3.2        -- intensity per second on every fire

-- gear
Config.Tanks = { { cap = 100, price = 0 }, { cap = 180, price = 80 }, { cap = 300, price = 220 } }
Config.Nozzles = { { power = 24, range = 40, price = 0 }, { power = 36, range = 50, price = 110 }, { power = 52, range = 62, price = 260 } }
Config.MaskPrice = 60
Config.WaterPerSec = 9

Config.FireReward = 12
Config.PeatReward = 20
Config.RunBonus = { clear = 100, survived = 60, emergency = 25 }
Config.CoopSpawnPerPlayer = 0.5 -- each extra player adds 50% more fires, so co-op income per player stays close to solo

export type Band = { min: number, max: number, en: string, bm: string, color: Color3, markerRange: number }
Config.Bands = {
	{ min = 0,   max = 50,   en = "Good",           bm = "Baik",               color = Color3.fromRGB(46, 160, 220),  markerRange = 420 },
	{ min = 51,  max = 100,  en = "Moderate",       bm = "Sederhana",          color = Color3.fromRGB(80, 190, 90),   markerRange = 320 },
	{ min = 101, max = 200,  en = "Unhealthy",      bm = "Tidak Sihat",        color = Color3.fromRGB(240, 190, 40),  markerRange = 190 },
	{ min = 201, max = 300,  en = "Very Unhealthy", bm = "Sangat Tidak Sihat", color = Color3.fromRGB(235, 110, 40),  markerRange = 120 },
	{ min = 301, max = 9999, en = "Hazardous",      bm = "Berbahaya",          color = Color3.fromRGB(200, 40, 50),   markerRange = 95 },
}

function Config.BandIndex(api: number): number
	local a = math.floor(api + 0.5)
	for i, b in Config.Bands do
		if a <= b.max then return i end
	end
	return #Config.Bands
end

Config.Tips = {
	"When the API is above 100, wear an N95 mask outdoors.",
	"Check official API readings on the MyJAS app or the APIMS website.",
	"Drink plenty of water and stay indoors when the haze is bad.",
	"Open burning is illegal in Malaysia. Report it - call 999.",
	"Peat fires can burn underground for days. Soak them completely!",
	"Schools stop outdoor activities when the API goes above 100.",
	"Kids, the elderly and people with asthma are most at risk from haze.",
}

---------------------------------------------------------------- progression (upgrades, hoses, gear, rides, premium)
-- Base numbers the upgrade tracks scale from
Config.BasePower = 24          -- fire damage per second before upgrades
Config.BaseSprayRadius = 10

-- Upgrade tracks: 10 levels each, value interpolates min -> max, next level costs base * 1.45^(level-1)
Config.TrackMaxLevel = 10
Config.TrackCostGrowth = 1.45
Config.Tracks = {
	{ id = "Speed",    en = "Bomba Boots",    bm = "Kasut Bomba",     icon = "Boots",    min = 18,  max = 27,  base = 40, fmt = "%d speed" },
	{ id = "Pressure", en = "Water Pressure", bm = "Tekanan Air",     icon = "Pressure", min = 1,   max = 2.2, base = 50, fmt = "x%.1f power" },
	{ id = "Tank",     en = "Water Tank",     bm = "Tangki Air",      icon = "Tank",     min = 100, max = 550, base = 40, fmt = "%d water" },
	{ id = "Range",    en = "Long Nozzle",    bm = "Muncung Jauh",    icon = "Range",    min = 40,  max = 70,  base = 45, fmt = "%d range" },
	{ id = "Refill",   en = "Fast Pump",      bm = "Pam Laju",        icon = "Pump",     min = 1,   max = 3,   base = 30, fmt = "x%.1f refill" },
	{ id = "Lungs",    en = "Strong Lungs",   bm = "Paru-paru Kuat",  icon = "Lungs",    min = 0,   max = 0.6, base = 35, fmt = "%d%% haze resist", pct = true },
}

function Config.TrackValue(track, level: number): number
	local t = math.clamp((level - 1) / (Config.TrackMaxLevel - 1), 0, 1)
	return track.min + (track.max - track.min) * t
end

function Config.TrackCost(track, level: number): number? -- cost to go from level -> level + 1
	if level >= Config.TrackMaxLevel then return nil end
	return math.floor(track.base * Config.TrackCostGrowth ^ (level - 1) / 5 + 0.5) * 5
end

-- Hose tiers: each is a new model (ServerStorage.Hoses.Hose<tier>) and multiplies the track stats
Config.Hoses = {
	{ en = "Starter Hose", bm = "Hos Asas",          icon = "Hose1", power = 1.00, tankMul = 1.0, radius = 0, peatSoak = 1, price = 0 },
	{ en = "Brass Jet",    bm = "Muncung Tembaga",   icon = "Hose2", power = 1.15, tankMul = 1.0, radius = 0, peatSoak = 1, price = 300 },
	{ en = "Twin Jet",     bm = "Jet Berkembar",     icon = "Hose3", power = 1.30, tankMul = 1.0, radius = 3, peatSoak = 1, price = 900 },
	{ en = "Foam Cannon",  bm = "Meriam Busa",       icon = "Hose4", power = 1.45, tankMul = 1.0, radius = 3, peatSoak = 2, price = 2200 },
	{ en = "Hydro Pack",   bm = "Ransel Hidro",      icon = "Hose5", power = 1.60, tankMul = 1.5, radius = 3, peatSoak = 2, price = 5000 },
	{ en = "Storm Cannon", bm = "Meriam Ribut",      icon = "Hose6", power = 1.80, tankMul = 1.5, radius = 6, peatSoak = 2, price = 10000, legendary = true },
}

-- Masks: haze resist combines with Strong Lungs as 1 - (1-a)(1-b)
Config.Masks = {
	{ en = "Cloth Mask",    bm = "Pelitup Kain",       icon = "Mask1", resist = 0.25, price = 30 },
	{ en = "Surgical Mask", bm = "Pelitup Perubatan",  icon = "Mask2", resist = 0.45, price = 80 },
	{ en = "N95",           bm = "N95",                icon = "Mask3", resist = 0.70, price = 140, noCough = true },
	{ en = "Respirator",    bm = "Alat Pernafasan",    icon = "Mask4", resist = 0.90, price = 400, noCough = true, noSlow = true },
}
Config.MaskColors = { Color3.fromRGB(240, 200, 210), Color3.fromRGB(150, 200, 235), Color3.fromRGB(245, 247, 250), Color3.fromRGB(90, 95, 105) }

-- Rides (model lives in ServerStorage.Rides.<id>; a placeholder is built if missing)
Config.Rides = {
	{ id = "Bicycle", en = "Bicycle",        bm = "Basikal",         icon = "Bicycle", speed = 32, price = 200 },
	{ id = "Kapcai",  en = "Kapcai",         bm = "Motosikal Kapcai", icon = "Kapcai", speed = 48, price = 1200 },
	{ id = "Truck",   en = "Bomba Fire Truck", bm = "Trak Bomba",    icon = "Truck",   speed = 40, pass = "Truck" },
}
Config.Truck = { radius = 30, damage = 80, waterSeconds = 45, refillSeconds = 20 }

-- Premium. Set id to the real Game Pass / Developer Product id from the Creator Hub.
-- id = 0 means "not created yet": in Studio the purchase is simulated for testing, live it shows "Coming soon".
Config.Passes = {
	{ key = "Godspeed",     en = "Godspeed",        bm = "Laju Kilat",          icon = "Godspeed",     id = 0, robux = 199, desc = "x1.5 run speed, no haze slowdown, golden trail" },
	{ key = "InfiniteTank", en = "Infinite Tank",   bm = "Tangki Tanpa Had",    icon = "InfiniteTank", id = 0, robux = 249, desc = "Your water never runs out" },
	{ key = "Truck",        en = "Bomba Fire Truck", bm = "Trak Bomba",         icon = "Truck",        id = 0, robux = 499, desc = "Drive the truck; its roof cannon blasts nearby fires" },
	{ key = "VIP",          en = "VIP Bomba",       bm = "VIP Bomba",           icon = "VIP",          id = 0, robux = 299, desc = "2x coins (same boost as the 2x Coins pass; they don't stack) and a gold VIP name tag" },
	{ key = "DoubleCoins",  en = "2x Coins",        bm = "Syiling 2x",          icon = "DoubleCoins",  id = 0, robux = 149, desc = "Double coins from every fire" },
}
Config.Products = {
	{ key = "Coins500",    en = "500 Coins",      bm = "500 Syiling",      icon = "Coins1",      id = 0, robux = 49,  coins = 500 },
	{ key = "Coins1500",   en = "1,500 Coins",    bm = "1,500 Syiling",    icon = "Coins2",      id = 0, robux = 129, coins = 1500 },
	{ key = "Coins5000",   en = "5,000 Coins",    bm = "5,000 Syiling",    icon = "Coins3",      id = 0, robux = 349, coins = 5000 },
	{ key = "CallRain",    en = "Call the Rain",  bm = "Panggil Hujan",    icon = "CallRain",    id = 0, robux = 79,  desc = "Cloud seeding for the whole server, now" },
	{ key = "ServerBoost", en = "Server Boost",   bm = "Galakan Pelayan",  icon = "ServerBoost", id = 0, robux = 99,  desc = "Everyone +25% speed and power for 10 min" },
}
Config.Boost = { seconds = 600, mult = 1.25 }
-- Health: HP lost per second outside during the Day, by API band, before haze resist (masks + Strong Lungs)
Config.Health = { drain = { 0, 0, 0.4, 1.0, 2.0 }, stationHeal = 8, cleanAirHeal = 1 }

-- Multiplayer: downed + revive, scout pings, fire cap per crew size
Config.Revive = { downSeconds = 25, soloDownSeconds = 8, reviveHealth = 40, reward = 6, holdSeconds = 2.5 }
Config.ScoutReward = 3
Config.ScoutRange = 200     -- you must be this close to the fire you mark
Config.ScoutDailyCap = 10   -- scout bonuses per player per day
Config.PingCooldown = 1.5
Config.MaxFiresPerPlayer = 3
Config.MaxFiresCap = 34
Config.GodspeedMul = 1.5
Config.GodspeedCap = 40

-- Shop icons: paste "rbxassetid://<id>" here once uploaded. Empty = the UI uses its emoji fallback.
Config.Icons = {
	Boots = "", Pressure = "", Tank = "", Range = "", Pump = "", Lungs = "",
	Hose1 = "", Hose2 = "", Hose3 = "", Hose4 = "", Hose5 = "", Hose6 = "",
	Mask1 = "", Mask2 = "", Mask3 = "", Mask4 = "",
	Bicycle = "", Kapcai = "", Truck = "",
	Godspeed = "", InfiniteTank = "", VIP = "", DoubleCoins = "",
	Coins1 = "", Coins2 = "", Coins3 = "", CallRain = "", ServerBoost = "",
	Coin = "", Water = "",
}

local Assets = require(script.Parent:WaitForChild("ImageAssets"))
for key in Config.Icons do Config.Icons[key] = Assets[key] or "" end
-- The premium card uses its own artwork; ride picker keeps the standard truck.
for _, pass in Config.Passes do
	if pass.key == "Truck" then pass.icon = "PremiumTruck" end
end
Config.Icons.PremiumTruck = Assets.PremiumTruck

return Config