-- Jerebu progression: saved player data, upgrade tracks, hose tiers, masks, rides, premium passes/products.
-- JerebuServer requires this and calls Progression.init(hooks) once its game functions exist.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local Remotes = J:WaitForChild("Remotes")

local Progression = {}

local IS_STUDIO = RunService:IsStudio()

local store, legacyStore = nil, nil
pcall(function()
	-- Studio playtests use their own store so debug coins and test purchases never touch real saves
	store = DataStoreService:GetDataStore(if IS_STUDIO then "JerebuSave_v2_Studio" else "JerebuSave_v2")
	if not IS_STUDIO then legacyStore = DataStoreService:GetDataStore("JerebuGear_v1") end
end)

type Data = {
	coins: number,
	tracks: { [string]: number },
	hoseOwned: number,
	hoseTier: number,
	mask: number,
	rides: { [string]: boolean },
	receipts: { string },
}

local data: { [Player]: Data } = {}
local loadFailed: { [Player]: boolean } = {} -- never overwrite a real save after a failed read
local dirty: { [Player]: boolean } = {}
local lastShop: { [Player]: number } = {}
local studioPasses: { [Player]: { [string]: boolean } } = {} -- simulated purchases (Studio, id = 0)
local hooks: any = nil

---------------------------------------------------------------- lookups
local trackById = {}
for _, t in Config.Tracks do trackById[t.id] = t end
local passByKey, passById = {}, {}
for _, p in Config.Passes do
	passByKey[p.key] = p
	if p.id ~= 0 then passById[p.id] = p end
end
local productByKey, productById = {}, {}
for _, p in Config.Products do
	productByKey[p.key] = p
	if p.id ~= 0 then productById[p.id] = p end
end
local rideById = {}
for _, r in Config.Rides do rideById[r.id] = r end

---------------------------------------------------------------- data
local function defaultData(): Data
	local tracks = {}
	for _, t in Config.Tracks do tracks[t.id] = 1 end
	return { coins = 0, tracks = tracks, hoseOwned = 1, hoseTier = 1, mask = 0, rides = {}, receipts = {} }
end

-- v1 saves had tank/nozzle levels 1-3 and a single mask flag
local function migrate(old): Data
	local d = defaultData()
	local map = { 1, 4, 7 }
	local function lvl(v) return map[math.clamp(math.floor(tonumber(v) or 1), 1, 3)] end
	d.coins = math.max(0, math.floor(tonumber(old.coins) or 0))
	d.tracks.Tank = lvl(old.tank)
	d.tracks.Range = lvl(old.nozzle)
	d.tracks.Pressure = lvl(old.nozzle)
	if old.mask == true then d.mask = 3 end
	return d
end

local function sanitize(raw): Data
	local d = defaultData()
	if typeof(raw) ~= "table" then return d end
	d.coins = math.max(0, math.floor(tonumber(raw.coins) or 0))
	if typeof(raw.tracks) == "table" then
		for id in d.tracks do
			d.tracks[id] = math.clamp(math.floor(tonumber(raw.tracks[id]) or 1), 1, Config.TrackMaxLevel)
		end
	end
	d.hoseOwned = math.clamp(math.floor(tonumber(raw.hoseOwned) or 1), 1, #Config.Hoses)
	d.hoseTier = math.clamp(math.floor(tonumber(raw.hoseTier) or 1), 1, d.hoseOwned)
	d.mask = math.clamp(math.floor(tonumber(raw.mask) or 0), 0, #Config.Masks)
	if typeof(raw.rides) == "table" then
		for id in rideById do d.rides[id] = raw.rides[id] == true end
	end
	if typeof(raw.receipts) == "table" then
		for _, r in raw.receipts do
			if typeof(r) == "string" then table.insert(d.receipts, r) end
		end
	end
	return d
end

-- Session lock: a record is { data = <Data>, lock = { job = JobId, t = os.time() } }, so one player
-- can't be loaded in two servers at once (multiplayer hopping). A lock older than LOCK_STALE is taken over.
local LOCK_STALE = 300

local function releaseLock(key: string)
	pcall(function()
		store:UpdateAsync(key, function(old)
			if typeof(old) == "table" and typeof(old.lock) == "table" and old.lock.job == game.JobId then
				old.lock = nil
				return old
			end
			return nil
		end)
	end)
end

local function load(plr: Player): Data
	if not store then return defaultData() end
	local key = "u" .. plr.UserId
	for attempt = 1, 5 do
		if not plr:IsDescendantOf(Players) then break end -- left while we were retrying
		local found, lockedElsewhere = nil, false
		local ok = pcall(function()
			store:UpdateAsync(key, function(old)
				if typeof(old) == "table" and typeof(old.lock) == "table" and old.lock.job ~= game.JobId
					and os.time() - (tonumber(old.lock.t) or 0) < LOCK_STALE then
					lockedElsewhere = true
					return nil
				end
				-- older records were the bare data table
				found = if typeof(old) == "table" then (old.data or (old.lock == nil and old or nil)) else nil
				return { data = found, lock = { job = game.JobId, t = os.time() } }
			end)
		end)
		if ok and not lockedElsewhere then
			if not plr:IsDescendantOf(Players) then
				releaseLock(key) -- they left mid-load; don't lock them out of their next server
				break
			end
			if found then return sanitize(found) end
			local legacy = nil
			if legacyStore and not pcall(function() legacy = legacyStore:GetAsync(key) end) then
				releaseLock(key) -- we hold the lock but won't save this session
				break
			end
			if typeof(legacy) == "table" then return migrate(legacy) end
			return defaultData()
		end
		task.wait(lockedElsewhere and 5 or attempt)
	end
	loadFailed[plr] = true
	return defaultData()
end

-- release = true when the player leaves, so their next server can load them straight away
local function write(plr: Player, release: boolean?): boolean
	local d = data[plr]
	if not d or not store or loadFailed[plr] then return false end
	dirty[plr] = nil
	-- the release on leave is retried; true only when our data was actually written
	for attempt = 1, if release then 3 else 1 do
		local wrote = false
		local ok = pcall(function()
			store:UpdateAsync("u" .. plr.UserId, function(old)
				if typeof(old) == "table" and typeof(old.lock) == "table" and old.lock.job ~= game.JobId then
					wrote = false
					return nil -- another server owns this player now; never overwrite its data
				end
				wrote = true
				return { data = d, lock = if release then nil else { job = game.JobId, t = os.time() } }
			end)
		end)
		if ok then return wrote end
		if release and attempt < 3 then task.wait(1) end
	end
	return false
end

function Progression.save(plr: Player)
	write(plr, false)
end

---------------------------------------------------------------- passes
function Progression.hasPass(plr: Player, key: string): boolean
	return plr:GetAttribute("Pass_" .. key) == true
end

local function refreshPasses(plr: Player)
	for _, p in Config.Passes do
		local owned = false
		if p.id ~= 0 then
			pcall(function() owned = MarketplaceService:UserOwnsGamePassAsync(plr.UserId, p.id) end)
		end
		if studioPasses[plr] and studioPasses[plr][p.key] then owned = true end
		plr:SetAttribute("Pass_" .. p.key, owned)
	end
end

---------------------------------------------------------------- stats
local function boostActive(): boolean
	return (workspace:GetAttribute("BoostUntil") or 0) > workspace:GetServerTimeNow()
end

function Progression.stats(plr: Player)
	local d = data[plr] or defaultData()
	local hose = Config.Hoses[d.hoseTier] or Config.Hoses[1]
	local mask = Config.Masks[d.mask]
	local boost = boostActive() and Config.Boost.mult or 1
	local lungs = Config.TrackValue(trackById.Lungs, d.tracks.Lungs)
	local resist = 1 - (1 - lungs) * (1 - (mask and mask.resist or 0))
	local walk = Config.TrackValue(trackById.Speed, d.tracks.Speed)
	local godspeed = Progression.hasPass(plr, "Godspeed")
	if godspeed then walk *= Config.GodspeedMul end
	walk *= boost
	-- the cap applies after Server Boost too, so walking never outruns the Kapcai
	if godspeed then walk = math.min(walk, Config.GodspeedCap) end
	local coinMul = (Progression.hasPass(plr, "VIP") or Progression.hasPass(plr, "DoubleCoins")) and 2 or 1
	return {
		walk = walk,
		power = Config.BasePower * Config.TrackValue(trackById.Pressure, d.tracks.Pressure) * hose.power * boost,
		tank = math.floor(Config.TrackValue(trackById.Tank, d.tracks.Tank) * hose.tankMul + 0.5),
		range = Config.TrackValue(trackById.Range, d.tracks.Range),
		refillMul = Config.TrackValue(trackById.Refill, d.tracks.Refill),
		sprayRadius = Config.BaseSprayRadius + hose.radius,
		peatSoakMul = hose.peatSoak,
		resist = resist,
		noSlow = godspeed or (mask ~= nil and mask.noSlow == true),
		noCough = resist >= 0.7,
		infiniteWater = Progression.hasPass(plr, "InfiniteTank"),
		coinMul = coinMul,
	}
end

-- haze slowdown per band, before resist (18 base walk used to be 15 / 13 / 11)
local HAZE_SLOW = { 0, 0, 3, 5, 7 }

function Progression.walkSpeed(plr: Player, band: number): number
	if plr:GetAttribute("Downed") then return 4 end
	local riding = plr:GetAttribute("Riding")
	if riding and riding ~= "" then
		local ride = rideById[riding]
		return ride and ride.speed or 16
	end
	local s = Progression.stats(plr)
	local slow = s.noSlow and 0 or (HAZE_SLOW[band] or 0) * (1 - s.resist)
	return math.max(8, s.walk - slow)
end

-- push derived values to attributes the client reads
function Progression.apply(plr: Player)
	local d = data[plr]
	if not d then return end
	local s = Progression.stats(plr)
	for id, lvl in d.tracks do plr:SetAttribute("Track_" .. id, lvl) end
	plr:SetAttribute("HoseOwned", d.hoseOwned)
	plr:SetAttribute("HoseTier", d.hoseTier)
	plr:SetAttribute("MaskTier", d.mask)
	for id in rideById do plr:SetAttribute("Ride_" .. id, d.rides[id] == true or (rideById[id].pass ~= nil and Progression.hasPass(plr, rideById[id].pass))) end
	plr:SetAttribute("MaxWater", s.tank)
	plr:SetAttribute("Range", s.range)
	plr:SetAttribute("HazeResist", s.resist)
	plr:SetAttribute("InfiniteWater", s.infiniteWater)
	plr:SetAttribute("CoinMul", s.coinMul)
	-- legacy flag the client cough logic reads
	plr:SetAttribute("Mask", s.noCough)
	-- Infinite Tank shows as always full so the HUD never says "empty"
	if s.infiniteWater or (plr:GetAttribute("Water") or 0) > s.tank then plr:SetAttribute("Water", s.tank) end
	local ls = plr:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value = d.coins end
end

function Progression.addCoins(plr: Player, amount: number, useMultiplier: boolean?)
	local d = data[plr]
	if not d then return 0 end
	local mul = useMultiplier and Progression.stats(plr).coinMul or 1
	local n = math.floor(amount * mul + 0.5)
	d.coins += n
	local ls = plr:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value = d.coins end
	return n
end

local function spend(plr: Player, cost: number): boolean
	local d = data[plr]
	if not d or d.coins < cost then return false end
	d.coins -= cost
	local ls = plr:FindFirstChild("leaderstats")
	if ls then ls.Coins.Value = d.coins end
	return true
end

---------------------------------------------------------------- character visuals: mask + hose tool
local function giveMask(plr: Player, char: Model)
	local old = char:FindFirstChild("HazeMask")
	if old then old:Destroy() end
	local tier = data[plr] and data[plr].mask or 0
	if tier <= 0 then return end
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end
	local mask = Instance.new("Part")
	mask.Name = "HazeMask"
	-- sized/placed from the head so it shows on classic and dynamic (mesh) heads
	local hs = head.Size
	mask.Size = Vector3.new(hs.X * 0.9, hs.Y * 0.42, 0.25)
	mask.Color = Config.MaskColors[tier]
	mask.Material = Enum.Material.Fabric
	mask.CanCollide = false
	mask.Massless = true
	-- dynamic (mesh) heads bulge past Head.Size, so push the mask further out
	mask.CFrame = head.CFrame * CFrame.new(0, -hs.Y * 0.2, -hs.Z * 0.6 - 0.05)
	local w = Instance.new("WeldConstraint")
	w.Part0 = head
	w.Part1 = mask
	w.Parent = mask
	mask.Parent = char
end

-- swap the player's Hose tool for the model of their equipped tier (ServerStorage.Hoses.Hose<tier>)
local function giveHose(plr: Player)
	local tier = data[plr] and data[plr].hoseTier or 1
	local folder = ServerStorage:FindFirstChild("Hoses")
	local template = folder and folder:FindFirstChild("Hose" .. tier)
	local char = plr.Character
	local wasEquipped = char and char:FindFirstChild("Hose") ~= nil
	local tool: Tool
	if template then
		tool = template:Clone()
		tool.Name = "Hose"
		if not tool:FindFirstChild("HoseClient") then
			local client = game.StarterPack:FindFirstChild("Hose") and game.StarterPack.Hose:FindFirstChild("HoseClient")
			if client then client:Clone().Parent = tool end
		end
	else
		local starter = game.StarterPack:FindFirstChild("Hose")
		if not starter then return end
		tool = starter:Clone()
	end
	tool:SetAttribute("Tier", tier)
	for _, where in { plr.Backpack, char } do
		local old = where and where:FindFirstChild("Hose")
		if old then old:Destroy() end
	end
	if wasEquipped and char then
		tool.Parent = char
	else
		tool.Parent = plr.Backpack
	end
end

---------------------------------------------------------------- rides
local function placeholderRide(id: string): Model
	-- simple stand-in until the VFX designer's model exists in ServerStorage.Rides
	local m = Instance.new("Model")
	m.Name = id
	local color = id == "Truck" and Color3.fromRGB(210, 30, 30) or (id == "Kapcai" and Color3.fromRGB(200, 40, 40) or Color3.fromRGB(230, 60, 60))
	local len = id == "Truck" and 14 or (id == "Kapcai" and 5 or 4.5)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = id == "Truck" and Vector3.new(7, 4, len) or Vector3.new(0.6, 1, len)
	body.Color = color
	body.Parent = m
	m.PrimaryPart = body
	for _, z in { -len / 2 + 0.9, len / 2 - 0.9 } do
		local wheel = Instance.new("Part")
		wheel.Name = "Wheel"
		wheel.Shape = Enum.PartType.Cylinder
		local r = id == "Truck" and 2.6 or 2
		wheel.Size = Vector3.new(id == "Truck" and 7.4 or 0.4, r, r)
		wheel.Color = Color3.fromRGB(30, 30, 30)
		wheel.CFrame = body.CFrame * CFrame.new(0, -(body.Size.Y / 2), z)
		wheel.Parent = m
	end
	return m
end

local function dismount(plr: Player)
	plr:SetAttribute("Riding", "")
	local char = plr.Character
	local old = char and char:FindFirstChild("RideModel")
	if old then old:Destroy() end
end

local function mount(plr: Player, id: string): (boolean, string)
	local ride = rideById[id]
	if not ride then return false, "Unknown ride" end
	if plr:GetAttribute("Downed") then return false, "You can't ride while collapsed" end
	local d = data[plr]
	local owned = (d and d.rides[id]) or (ride.pass and Progression.hasPass(plr, ride.pass))
	if not owned then return false, "You don't own this ride" end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return false, "Not ready" end
	dismount(plr)
	if id ~= "Truck" then
		hum:UnequipTools()
		-- no hose in hand on a bike: unequip again if they pull it out while riding
		local conn
		conn = char.ChildAdded:Connect(function(c)
			if plr:GetAttribute("Riding") ~= id then conn:Disconnect() return end
			if c:IsA("Tool") then task.defer(function() hum:UnequipTools() end) end
		end)
	end
	local folder = ServerStorage:FindFirstChild("Rides")
	local template = folder and folder:FindFirstChild(id)
	local model = template and template:Clone() or placeholderRide(id)
	model.Name = "RideModel"
	model:SetAttribute("Ride", id)
	if not model.PrimaryPart then model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true) end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.Massless = true
		end
	end
	-- the model's "Seat" attachment (if any) lines up with the player's hips
	local seat = model:FindFirstChild("Seat", true)
	local offset = (seat and seat:IsA("Attachment")) and seat.CFrame:Inverse() or CFrame.new(0, id == "Truck" and -3.2 or -1.6, 0)
	local pivot = model.PrimaryPart
	model:PivotTo(root.CFrame * offset)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= pivot then
			local w = Instance.new("WeldConstraint")
			w.Part0 = pivot
			w.Part1 = p
			w.Parent = p
		end
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = pivot
	w.Parent = pivot
	model.Parent = char
	plr:SetAttribute("Riding", id)
	if id == "Truck" then plr:SetAttribute("TruckWater", plr:GetAttribute("TruckWater") or 1) end
	return true, ride.en .. " ready!"
end

Remotes.Ride.OnServerEvent:Connect(function(plr: Player, id: any)
	if typeof(id) ~= "string" or id == "" or plr:GetAttribute("Riding") == id then
		dismount(plr)
		return
	end
	local ok, msg = mount(plr, id)
	if not ok then Remotes.Notify:FireClient(plr, msg, "info") end
end)

---------------------------------------------------------------- shop
local function buyTrack(plr: Player, id: string)
	local t = trackById[id]
	local d = data[plr]
	if not t or not d then return false, "Unknown upgrade" end
	local lvl = d.tracks[id]
	local cost = Config.TrackCost(t, lvl)
	if not cost then return false, "Already maxed" end
	if not spend(plr, cost) then return false, "Not enough coins" end
	d.tracks[id] = lvl + 1
	Progression.apply(plr)
	return true, ("%s Lv.%d!"):format(t.en, lvl + 1)
end

local function buyHose(plr: Player, tier: number)
	local d = data[plr]
	local h = Config.Hoses[tier]
	if not d or not h then return false, "Unknown hose" end
	if tier <= d.hoseOwned then return false, "Already owned" end
	if tier ~= d.hoseOwned + 1 then return false, "Unlock the previous hose first" end
	if not spend(plr, h.price) then return false, "Not enough coins" end
	d.hoseOwned = tier
	d.hoseTier = tier
	Progression.apply(plr)
	giveHose(plr)
	return true, h.en .. " unlocked!"
end

local function equipHose(plr: Player, tier: number)
	local d = data[plr]
	if not d or tier < 1 or tier > d.hoseOwned then return false, "Not owned" end
	d.hoseTier = tier
	Progression.apply(plr)
	giveHose(plr)
	return true, Config.Hoses[tier].en .. " equipped"
end

local function buyMask(plr: Player, tier: number)
	local d = data[plr]
	local m = Config.Masks[tier]
	if not d or not m then return false, "Unknown mask" end
	if tier <= d.mask then return false, "You already have this (or better)" end
	if not spend(plr, m.price) then return false, "Not enough coins" end
	d.mask = tier
	Progression.apply(plr)
	if plr.Character then giveMask(plr, plr.Character) end
	return true, m.en .. " on. Stay safe in the haze!"
end

local function buyRide(plr: Player, id: string)
	local d = data[plr]
	local r = rideById[id]
	if not d or not r then return false, "Unknown ride" end
	if r.pass then return false, "This ride is a Game Pass" end
	if d.rides[id] then return false, "Already owned" end
	if not spend(plr, r.price) then return false, "Not enough coins" end
	d.rides[id] = true
	Progression.apply(plr)
	return true, r.en .. " unlocked! Press the ride button to hop on."
end

local function buyPass(plr: Player, key: string)
	local p = passByKey[key]
	if not p then return false, "Unknown pass" end
	if Progression.hasPass(plr, key) then return false, "Already owned" end
	if p.id == 0 then
		if not IS_STUDIO then return false, "Coming soon!" end
		studioPasses[plr] = studioPasses[plr] or {}
		studioPasses[plr][key] = true
		refreshPasses(plr)
		Progression.apply(plr)
		return true, p.en .. " (Studio test purchase)"
	end
	MarketplaceService:PromptGamePassPurchase(plr, p.id)
	return true, "__prompted"
end

local function grantProduct(plr: Player, p): boolean
	if p.coins then
		Progression.addCoins(plr, p.coins, false)
		Remotes.Notify:FireClient(plr, ("+%d coins! Terima kasih!"):format(p.coins), "good")
		return true
	elseif p.key == "CallRain" then
		if hooks and hooks.callRain then hooks.callRain(plr) end
		return true
	elseif p.key == "ServerBoost" then
		local now = workspace:GetServerTimeNow()
		local untilT = math.max(now, workspace:GetAttribute("BoostUntil") or 0) + Config.Boost.seconds
		workspace:SetAttribute("BoostUntil", untilT)
		Remotes.Notify:FireAllClients(("%s boosted the whole server! +25%% speed & power for 10 min"):format(plr.DisplayName), "good")
		return true
	end
	return false
end

local function buyProduct(plr: Player, key: string)
	local p = productByKey[key]
	if not p then return false, "Unknown item" end
	if p.key == "CallRain" and hooks and hooks.canCallRain and not hooks.canCallRain() then
		return false, "Rain is already on the way!"
	end
	if p.id == 0 then
		if not IS_STUDIO then return false, "Coming soon!" end
		grantProduct(plr, p)
		return true, p.en .. " (Studio test purchase)"
	end
	MarketplaceService:PromptProductPurchase(plr, p.id)
	return true, "__prompted"
end

local actions = {
	BuyTrack = buyTrack,
	BuyHose = buyHose,
	EquipHose = equipHose,
	BuyMask = buyMask,
	BuyRide = buyRide,
	BuyPass = buyPass,
	BuyProduct = buyProduct,
}

Remotes.Shop.OnServerInvoke = function(plr: Player, action: any, arg: any)
	if not data[plr] then return false, "Not ready" end
	local now = os.clock()
	if now - (lastShop[plr] or 0) < 0.15 then return false, "Slow down" end
	lastShop[plr] = now
	-- legacy one-argument calls from the old shop UI
	if action == "Tank" then return buyTrack(plr, "Tank") end
	if action == "Nozzle" then return buyTrack(plr, "Pressure") end
	if action == "Mask" then return buyMask(plr, math.min(data[plr].mask + 1, #Config.Masks)) end
	local fn = actions[action]
	if not fn then return false, "Unknown action" end
	-- tiers must be whole numbers (NaN / 1.5 / "2" used to corrupt the save and break the server loop)
	if action == "BuyHose" or action == "EquipHose" or action == "BuyMask" then
		if typeof(arg) ~= "number" or arg ~= arg or arg % 1 ~= 0 then return false, "Bad request" end
	elseif typeof(arg) ~= "string" or #arg > 32 then
		return false, "Bad request"
	end
	local ok, msg = fn(plr, arg)
	if ok then dirty[plr] = true end
	return ok, msg
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, purchased)
	if not purchased then return end
	local p = passById[passId]
	if not p then return end
	refreshPasses(plr)
	Progression.apply(plr)
	Remotes.Notify:FireClient(plr, p.en .. " unlocked! Terima kasih!", "good")
end)

MarketplaceService.ProcessReceipt = function(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	local d = plr and data[plr]
	if not d then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if loadFailed[plr] then
		-- can't persist it this session; Roblox retries the receipt next time they join
		Remotes.Notify:FireClient(plr, "Your purchase will arrive once your save loads. Please rejoin.", "warn")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(d.receipts, info.PurchaseId) then return Enum.ProductPurchaseDecision.PurchaseGranted end
	local p = productById[info.ProductId]
	if not p or not grantProduct(plr, p) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	table.insert(d.receipts, info.PurchaseId)
	while #d.receipts > 50 do table.remove(d.receipts, 1) end
	if store and not write(plr, false) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------- truck cannon (runs alongside the main loop)
local function truckLoop()
	while true do
		local dt = task.wait(0.2)
		for _, plr in Players:GetPlayers() do
			if plr:GetAttribute("Riding") == "Truck" and not plr:GetAttribute("Downed") then pcall(function()
				local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and hooks then
					local water = plr:GetAttribute("TruckWater") or 1
					if hooks.inRefill(root.Position) then
						water = math.min(1, water + dt / Config.Truck.refillSeconds)
					end
					local spraying = false
					if water > 0 then
						local hit = hooks.damageFiresNear(plr, root.Position, Config.Truck.radius, Config.Truck.damage * dt)
						if hit > 0 then
							spraying = true
							water = math.max(0, water - dt / Config.Truck.waterSeconds)
						end
					end
					plr:SetAttribute("TruckWater", water)
					plr:SetAttribute("TruckSpraying", spraying)
				end
			end) end
		end
	end
end

---------------------------------------------------------------- lifecycle
local function onCharacter(plr: Player, char: Model)
	plr:SetAttribute("Riding", "")
	plr:SetAttribute("Downed", false)
	plr:SetAttribute("Water", plr:GetAttribute("MaxWater") or 100)
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if hum then
		hum.Died:Connect(function()
			Remotes.Notify:FireClient(plr, "You passed out from the haze! Rest inside the BOMBA station and wear a better mask.", "band")
		end)
	end
	local head = char:WaitForChild("Head", 5)
	giveMask(plr, char)
	-- gold VIP name tag
	if head and Progression.hasPass(plr, "VIP") and not head:FindFirstChild("VIPTag") then
		local bb = Instance.new("BillboardGui")
		bb.Name = "VIPTag"
		bb.Size = UDim2.fromOffset(90, 26)
		bb.StudsOffset = Vector3.new(0, 2.6, 0)
		bb.MaxDistance = 80
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "★ VIP"
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 205, 60)
		t.TextStrokeColor3 = Color3.fromRGB(120, 70, 10)
		t.TextStrokeTransparency = 0
		t.Parent = bb
		bb.Parent = head
	end
	-- StarterPack has already copied its Hose into the Backpack; replace it with the tier model
	task.defer(giveHose, plr)
end

local function onPlayer(plr: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls
	local padam = Instance.new("IntValue")
	padam.Name = "Padam"
	padam.Parent = ls
	ls.Parent = plr

	data[plr] = load(plr)
	if loadFailed[plr] and not IS_STUDIO then
		Remotes.Notify:FireClient(plr, "Couldn't load your save, so progress this session won't be saved. Please rejoin.", "warn")
	end
	refreshPasses(plr)
	Progression.apply(plr)
	plr:SetAttribute("Water", plr:GetAttribute("MaxWater"))
	plr:SetAttribute("Riding", "")
	plr:SetAttribute("TruckWater", 1)

	plr.CharacterAdded:Connect(function(c) onCharacter(plr, c) end)
	if plr.Character then onCharacter(plr, plr.Character) end
end

function Progression.init(h)
	hooks = h
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do task.spawn(onPlayer, p) end
	Players.PlayerRemoving:Connect(function(plr)
		write(plr, true)
		data[plr] = nil
		studioPasses[plr] = nil
		loadFailed[plr] = nil
		dirty[plr] = nil
		lastShop[plr] = nil
	end)
	game:BindToClose(function()
		for _, p in Players:GetPlayers() do write(p, true) end
	end)
	task.spawn(truckLoop)
	-- boost ending / starting changes speed + power; re-push derived stats every few seconds
	task.spawn(function()
		local sinceSave = 0
		while true do
			task.wait(3)
			sinceSave += 3
			for _, p in Players:GetPlayers() do pcall(Progression.apply, p) end
			-- shop purchases mark the player dirty; save them in batches instead of on every click
			if sinceSave % 30 == 0 then
				for p in dirty do task.spawn(Progression.save, p) end
			end
			-- refresh every player's session lock well before it goes stale
			if sinceSave >= 120 then
				sinceSave = 0
				for _, p in Players:GetPlayers() do task.spawn(Progression.save, p) end
			end
		end
	end)
end

Progression.dismount = dismount

function Progression.isRiding(plr: Player): boolean
	local r = plr:GetAttribute("Riding")
	return r ~= nil and r ~= ""
end

return Progression
