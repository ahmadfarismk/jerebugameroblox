-- Jerebu: 7-Day Haze - server game loop
-- Owns fires, the shared API meter, the 7-day cycle, spraying, refills, gear and cloud seeding.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local SurvivalRules = require(J:WaitForChild("SurvivalRules"))
local Remotes = J:WaitForChild("Remotes")
local Sounds = J:WaitForChild("Sounds")
local Progression = require(script.Parent:WaitForChild("Progression"))
local Camp = require(script.Parent:WaitForChild("CampUpgrades"))

local Map = workspace:WaitForChild("Map")
local FiresFolder = workspace:FindFirstChild("Fires") or Instance.new("Folder")
FiresFolder.Name = "Fires"
FiresFolder.Parent = workspace

local rng = Random.new()

---------------------------------------------------------------- state
local State = {
	api = Config.StartAPI,
	day = 0,
	phase = "Intermission",
	wind = Vector3.new(1, 0, 0),
	windStrength = 1,
	above150 = 0,
	seedUnlocked = false,
	seedUsedToday = false,
	seedLoaders = {} :: { [Player]: boolean },
	raining = false,
	dailyAPI = {} :: { number },
	dayStats = { out = 0, spawned = 0 },
	runStats = { out = 0, spawned = 0, burnt = 0 },
}

local function setAttr(name: string, v: any)
	workspace:SetAttribute(name, v)
end

-- Votes are accepted only in intermission; clients cannot choose the active mode.
local voteRemote = Remotes:FindFirstChild("ModeVote") or Instance.new("RemoteEvent")
voteRemote.Name = "ModeVote"
voteRemote.Parent = Remotes
local votes, lastVote = {}, {}
local function voteCounts()
	local story, survival = 0, 0
	for p, mode in votes do
		if p.Parent == Players then
			if mode == "Survival" then survival += 1 else story += 1 end
		end
	end
	setAttr("StoryVotes", story)
	setAttr("SurvivalVotes", survival)
	return story, survival
end
voteRemote.OnServerEvent:Connect(function(p, mode)
	if State.phase ~= "Intermission" or (mode ~= "Story" and mode ~= "Survival") then return end
	if os.clock() - (lastVote[p] or -math.huge) < 0.3 then return end
	lastVote[p] = os.clock()
	votes[p] = mode
	p:SetAttribute("ModeVote", mode)
	voteCounts()
end)
Players.PlayerRemoving:Connect(function(p) votes[p] = nil lastVote[p] = nil voteCounts() end)
local activeDayCfg = nil
local defaultRespawnTime = Players.RespawnTime
local survivalReason = nil
local survivalHadCrew = false
local survivalDaysByPlayer = {}

local function notify(text: string, kind: string?, target: Player?)
	if target then
		Remotes.Notify:FireClient(target, text, kind or "info")
	else
		Remotes.Notify:FireAllClients(text, kind or "info")
	end
end

---------------------------------------------------------------- trees / neighbours
local Trees = {}
type TreeInfo = { model: Model, pos: Vector3, height: number, peat: boolean, burnt: boolean, neighbours: { any }, fire: any?, leafColors: { [BasePart]: Color3 } }
local treeInfo: { [Model]: TreeInfo } = {}

for _, m in CS:GetTagged("Tree") do
	if m:IsA("Model") and m.PrimaryPart then
		local ground = m:GetAttribute("Ground") or m.PrimaryPart.Position.Y
		local p = m.PrimaryPart.Position
		local bbCf, bbSize = m:GetBoundingBox()
		local info: TreeInfo = {
			model = m,
			pos = Vector3.new(p.X, ground, p.Z),
			height = math.max(2, bbCf.Position.Y + bbSize.Y / 2 - ground),
			peat = m:GetAttribute("Peat") == true,
			burnt = false,
			neighbours = {},
			fire = nil,
			leafColors = {},
		}
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then info.leafColors[d] = d.Color end
		end
		treeInfo[m] = info
		table.insert(Trees, info)
	end
end
for _, a in Trees do
	for _, b in Trees do
		if a ~= b and (a.pos - b.pos).Magnitude <= Config.SpreadRadius then
			table.insert(a.neighbours, b)
		end
	end
end

---------------------------------------------------------------- fire visuals (VFX designer)
-- Budget per fire: 3 emitters (Flames, Smoke, Embers|CrownFlames) + 1 PointLight.
-- Flames use LightInfluence 0 + Brightness so they stay saturated orange in daylight and haze.
local FIRE_TEX = "rbxasset://textures/particles/fire_main.dds"
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/fire_sparks_main.dds"
local GLOW_TEX = "rbxasset://textures/particles/forcefield_glow_main.dds"
local CR = Color3.fromRGB
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new

local FLAME_COLOR = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CR(255, 236, 150)),
	ColorSequenceKeypoint.new(0.25, CR(255, 160, 40)),
	ColorSequenceKeypoint.new(0.65, CR(235, 75, 15)),
	ColorSequenceKeypoint.new(1, CR(120, 25, 10)),
})
local PEAT_FLAME_COLOR = ColorSequence.new({
	ColorSequenceKeypoint.new(0, CR(255, 200, 110)),
	ColorSequenceKeypoint.new(0.35, CR(240, 110, 30)),
	ColorSequenceKeypoint.new(1, CR(110, 30, 12)),
})
local FLAME_ALPHA = NS({ NK(0, 0.15), NK(0.15, 0), NK(0.7, 0.25), NK(1, 1) })

local scorches: { [any]: BasePart } = {}

local function charTree(info: TreeInfo, amount: number)
	-- darken leaves/trunk toward charcoal; amount 0..1
	for part, base in info.leafColors do
		if part.Parent then
			part.Color = base:Lerp(CR(38, 32, 28), math.clamp(amount, 0, 1))
		end
	end
	-- burnt-out tree leaves a scorched ring on the ground
	if amount >= 1 and not scorches[info] then
		local s = Instance.new("Part")
		s.Name = "Scorch"
		s.Shape = Enum.PartType.Cylinder
		s.Anchored = true
		s.CanCollide = false
		s.CanQuery = false
		s.CanTouch = false
		s.CastShadow = false
		s.Material = Enum.Material.Slate
		s.Color = CR(34, 29, 26)
		s.Size = Vector3.new(0.4, 13, 13)
		s.CFrame = CFrame.new(info.pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
		s.Parent = Map
		scorches[info] = s
	elseif amount <= 0 and scorches[info] then
		scorches[info]:Destroy()
		scorches[info] = nil
	end
end

local function resetTrees()
	for _, info in Trees do
		info.burnt = false
		charTree(info, 0)
	end
end

local function makeFirePart(info: TreeInfo)
	local part = Instance.new("Part")
	part.Name = info.peat and "PeatFire" or "Fire"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = info.peat and Vector3.new(9, 1, 9) or Vector3.new(6, 1, 6)
	part.CFrame = CFrame.new(info.pos + Vector3.new(0, 2.5, 0))

	local flames = Instance.new("ParticleEmitter")
	flames.Name = "Flames"
	flames.Texture = FIRE_TEX
	flames.Color = info.peat and PEAT_FLAME_COLOR or FLAME_COLOR
	flames.LightEmission = 0.3
	flames.LightInfluence = 0
	flames.Brightness = 4
	flames.Transparency = FLAME_ALPHA
	flames.Lifetime = NumberRange.new(0.6, 1.1)
	flames.SpreadAngle = Vector2.new(14, 14)
	flames.Acceleration = Vector3.new(0, 8, 0)
	flames.RotSpeed = NumberRange.new(-70, 70)
	flames.Rotation = NumberRange.new(0, 360)
	flames.EmissionDirection = Enum.NormalId.Top
	-- ground fire spreads in a ring around the trunk so it reads above the grass
	flames.Shape = Enum.ParticleEmitterShape.Disc
	flames.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	flames.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	flames.Rate = 0
	flames.Parent = part

	-- crown fire: flames climb into the canopy once the fire is strong
	if info.height > 6 then
		local crownAtt = Instance.new("Attachment")
		crownAtt.Name = "Crown"
		crownAtt.Position = Vector3.new(0, info.height - 6, 0)
		crownAtt.Parent = part
		local crown = flames:Clone()
		crown.Name = "CrownFlames"
		crown.Shape = Enum.ParticleEmitterShape.Sphere
		crown.Lifetime = NumberRange.new(0.7, 1.3)
		crown.Rate = 0
		crown.Parent = crownAtt
	end

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = SMOKE_TEX
	smoke.LightInfluence = 0.7
	smoke.RotSpeed = NumberRange.new(-20, 20)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Rate = 0
	smoke.Parent = part

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Texture = SPARK_TEX
	embers.Color = ColorSequence.new(CR(255, 200, 90), CR(255, 90, 20))
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.Brightness = 3
	embers.Size = NS({ NK(0, 0.45), NK(1, 0) })
	embers.Lifetime = NumberRange.new(1.2, 2.2)
	embers.Speed = NumberRange.new(8, 16)
	embers.SpreadAngle = Vector2.new(35, 35)
	embers.Acceleration = Vector3.new(0, 3, 0)
	embers.Drag = 0.6
	embers.EmissionDirection = Enum.NormalId.Top
	embers.Rate = 0
	embers.Parent = part

	local light = Instance.new("PointLight")
	light.Color = CR(255, 140, 50)
	light.Range = 16
	light.Brightness = 2
	light.Shadows = false
	light.Parent = part

	local crackle = Sounds.FireLoop:Clone()
	crackle.RollOffMode = Enum.RollOffMode.InverseTapered
	crackle.RollOffMinDistance = 12
	crackle.RollOffMaxDistance = 90
	crackle.Volume = 0.55
	crackle.Parent = part
	crackle:Play()

	part.Parent = FiresFolder
	return part
end

-- glowing ember patches for smouldering peat: Neon mounds poking out of the grass read in
-- full daylight where particles wash out. Plain parts, so they cost no particle budget.
local EMBER_PATCHES = { { 0, 0, 4.2, 3.2 }, { 3, 1.6, 3, 2.3 }, { -2.8, 2.2, 2.8, 2.5 }, { 1.8, -3, 3.2, 2.2 }, { -2.4, -2.4, 2.4, 2 }, { 3.9, -1, 2, 1.7 } }
local function emberPatches(part: BasePart): { BasePart }
	local folder = part:FindFirstChild("EmberPatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "EmberPatches"
		local base = part.Position - Vector3.new(0, 2.5, 0) -- ground under the fire
		for i, d in EMBER_PATCHES do
			local p = Instance.new("Part")
			p.Name = "Patch" .. i
			p.Shape = Enum.PartType.Ball
			p.Material = Enum.Material.Neon
			p.Color = CR(255, 105, 25)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Transparency = 1
			p.Size = Vector3.new(d[3], 1.2, d[4])
			p.CFrame = CFrame.new(base + Vector3.new(d[1], 0.55, d[2])) * CFrame.Angles(0, rng:NextNumber() * math.pi, 0)
			p.Parent = folder
		end
		folder.Parent = part
	end
	return folder:GetChildren() :: any
end

-- one-off look changes when a fire switches between burning and smouldering
local function setFireMode(part: BasePart, peat: boolean, smoulder: boolean)
	local mode = smoulder and "smoulder" or "burn"
	if part:GetAttribute("VisMode") == mode then return false end
	local wasSmoulder = part:GetAttribute("VisMode") == "smoulder"
	part:SetAttribute("VisMode", mode)
	local flames = part.Flames :: ParticleEmitter
	local smoke = part.Smoke :: ParticleEmitter
	if smoulder then
		-- Neon ember mounds + tiny licking flames + thin smoke that creeps along the ground
		for _, p in emberPatches(part) do p.Transparency = 0 end
		flames.Texture = FIRE_TEX
		flames.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, CR(255, 210, 120)), ColorSequenceKeypoint.new(0.4, CR(255, 110, 25)), ColorSequenceKeypoint.new(1, CR(170, 35, 10)) })
		flames.LightEmission = 0.4
		flames.LightInfluence = 0
		flames.Brightness = 5
		flames.Transparency = NS({ NK(0, 1), NK(0.3, 0.05), NK(0.75, 0.3), NK(1, 1) })
		flames.Size = NS({ NK(0, 0.9), NK(0.45, 1.6), NK(1, 0.3) })
		flames.Lifetime = NumberRange.new(0.7, 1.1)
		-- shot down from the part (2.5 up) and braked by drag (~16/7 = 2.3 studs), so they
		-- appear (fade in) right at the ground and lick upward slightly
		flames.EmissionDirection = Enum.NormalId.Bottom
		flames.Speed = NumberRange.new(15, 17)
		flames.Drag = 7
		flames.Acceleration = Vector3.new(0, 1.5, 0)
		flames.RotSpeed = NumberRange.new(-40, 40)
		flames.SpreadAngle = Vector2.new(10, 10)
		flames.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		smoke.Color = ColorSequence.new(CR(150, 140, 128), CR(175, 168, 158))
		smoke.Size = NS({ NK(0, 3), NK(1, 13) })
		smoke.Transparency = NS({ NK(0, 1), NK(0.12, 0.4), NK(1, 1) })
		smoke.Lifetime = NumberRange.new(5, 7)
		smoke.Speed = NumberRange.new(2, 3.5)
		smoke.SpreadAngle = Vector2.new(85, 85)
		smoke.Acceleration = Vector3.new(0, 0.2, 0)
		smoke.Drag = 0.5
		part.PointLight.Color = CR(255, 90, 30)
		part.Embers.Size = NS({ NK(0, 0.35), NK(1, 0) })
		part.Embers.Speed = NumberRange.new(2, 5)
	else
		local patches = part:FindFirstChild("EmberPatches")
		if patches then
			for _, p in patches:GetChildren() do (p :: BasePart).Transparency = 1 end
		end
		flames.Texture = FIRE_TEX
		flames.Color = peat and PEAT_FLAME_COLOR or FLAME_COLOR
		flames.LightEmission = 0.3
		flames.Brightness = 4
		flames.Transparency = FLAME_ALPHA
		flames.Lifetime = NumberRange.new(0.6, 1.1)
		flames.Acceleration = Vector3.new(0, 8, 0)
		flames.RotSpeed = NumberRange.new(-70, 70)
		flames.LightInfluence = 0
		flames.EmissionDirection = Enum.NormalId.Top
		flames.Drag = 0
		smoke.Size = NS({ NK(0, 3), NK(1, 14) })
		smoke.Speed = NumberRange.new(6, 9)
		smoke.Color = peat and ColorSequence.new(CR(150, 145, 135), CR(185, 178, 166)) or ColorSequence.new(CR(60, 55, 50), CR(135, 125, 112))
		smoke.Transparency = NS({ NK(0, 0.45), NK(1, 1) })
		smoke.Lifetime = NumberRange.new(4, 6)
		smoke.SpreadAngle = Vector2.new(peat and 30 or 12, peat and 30 or 12)
		smoke.Acceleration = Vector3.new(0, 2, 0)
		smoke.Drag = 0
		part.PointLight.Color = CR(255, 140, 50)
		part.Embers.Size = NS({ NK(0, 0.45), NK(1, 0) })
		part.Embers.Speed = NumberRange.new(8, 16)
		if wasSmoulder then
			-- peat flaring back up: ember burst so players notice
			part.Embers.Enabled = true
			part.Embers:Emit(30)
		end
	end
	return true
end

local function updateFireVisual(fire)
	local part = fire.part
	local k = fire.intensity / 100
	local flames = part.Flames :: ParticleEmitter
	local smoke = part.Smoke :: ParticleEmitter
	local embers = part.Embers :: ParticleEmitter
	local crown = part:FindFirstChild("CrownFlames", true) :: ParticleEmitter?
	setFireMode(part, fire.peat, fire.smoulder)
	if fire.smoulder then
		-- glow fades as the peat gets soaked, so spraying shows progress
		local wet = math.clamp(fire.soak / Config.PeatSoakTime, 0, 1)
		flames.Rate = 14 * (1 - wet * 0.85)
		if crown then crown.Rate = 0 end
		embers.Enabled = true
		embers.Rate = 4 * (1 - wet)
		smoke.Rate = 3 + 3 * wet -- more steam-like smoke as it is soaked
		-- ember mounds breathe (flicker) and dim to charcoal as the peat is soaked
		local patches = part:FindFirstChild("EmberPatches")
		if patches then
			local t = os.clock()
			for i, p in patches:GetChildren() do
				local pulse = 0.5 + 0.5 * math.sin(t * 3 + i * 1.7)
				local hot = CR(255, 140, 40):Lerp(CR(230, 70, 15), pulse)
				;(p :: BasePart).Color = hot:Lerp(CR(45, 35, 30), wet * 0.9)
				;(p :: BasePart).Transparency = 0.1 * pulse + 0.5 * wet
			end
		end
		part.PointLight.Brightness = (0.9 + rng:NextNumber() * 0.5) * (1 - wet * 0.7)
		part.PointLight.Range = 12
		part.FireLoop.Volume = 0.08
	else
		-- peat burns lower and wider; tree fires grow tall
		local s = 2.5 + (fire.peat and 5 or 7.5) * k
		local size = NS({ NK(0, s * 0.6), NK(0.35, s), NK(1, s * 0.25) })
		flames.Size = size
		flames.Rate = 8 + 28 * k
		flames.Speed = NumberRange.new(4 + 9 * k, 7 + 14 * k)
		flames.SpreadAngle = fire.peat and Vector2.new(30, 30) or Vector2.new(14, 14)
		local ck = math.clamp((fire.intensity - 45) / 55, 0, 1)
		if crown then
			crown.Rate = 22 * ck
			crown.Size = NS({ NK(0, s * 0.7), NK(0.35, s * 1.15), NK(1, s * 0.3) })
			crown.Speed = NumberRange.new(3 + 5 * k, 6 + 9 * k)
		end
		-- third emitter slot: embers while small, crown flames once it climbs
		local crowning = crown ~= nil and ck > 0
		embers.Enabled = not crowning
		embers.Rate = 2 + 8 * k
		smoke.Rate = 2 + 6 * k
		smoke.Size = NS({ NK(0, 3 + 3 * k), NK(1, 14 + 12 * k) })
		smoke.Speed = NumberRange.new(6 + 6 * k, 9 + 8 * k)
		-- occasional flare-ups on strong fires
		if k > 0.35 and rng:NextNumber() < 0.025 * k then
			flames:Emit(math.floor(4 + 8 * k))
			if crown and crowning then crown:Emit(6) elseif embers.Enabled then embers:Emit(14) end
		end
		part.PointLight.Brightness = (1.2 + 4 * k) * (0.85 + rng:NextNumber() * 0.3)
		part.PointLight.Range = 10 + 18 * k
		part.FireLoop.Volume = 0.25 + 0.5 * k
	end
	part:SetAttribute("Intensity", math.floor(fire.intensity))
	part:SetAttribute("Smoulder", fire.smoulder)
end

---------------------------------------------------------------- fires
local Fires = {} -- set of fire records

local function activeFireCount(): number
	local n = 0
	for f in Fires do
		if not f.smoulder then n += 1 end
	end
	return n
end

local function totalFires(): number
	local n = 0
	for _ in Fires do n += 1 end
	return n
end

-- more crew, more simultaneous fires (still capped for phones)
local function maxFires(): number
	return math.min(Config.MaxFiresCap, Config.MaxFires + Config.MaxFiresPerPlayer * math.max(0, #Players:GetPlayers() - 1))
end

local function ignite(info: TreeInfo, startIntensity: number?)
	if info.fire or info.burnt then return nil end
	if totalFires() >= maxFires() then return nil end
	local fire = {
		info = info,
		intensity = startIntensity or 18,
		peat = info.peat,
		smoulder = false,
		soak = 0,
		reigniteAt = 0,
		fullTime = 0,
		contrib = {} :: { [Player]: number },
		part = nil :: any,
	}
	fire.part = makeFirePart(info)
	if info.peat then fire.part:SetAttribute("Peat", true) end
	info.fire = fire
	Fires[fire] = true
	State.dayStats.spawned += 1
	State.runStats.spawned += 1
	updateFireVisual(fire)
	Remotes.Sfx:FireAllClients("Ignite", info.pos)
	return fire
end

local function removeFire(fire)
	Fires[fire] = nil
	fire.info.fire = nil
	if fire.part then fire.part:Destroy() end
end

local function rewardFire(fire)
	local total = 0
	for _, amt in fire.contrib do total += amt end
	if total <= 0 then return end
	local reward = fire.peat and Config.PeatReward or Config.FireReward
	for plr, amt in fire.contrib do
		if plr.Parent then
			local share = math.max(1, math.floor(reward * amt / total + 0.5))
			share = Progression.addCoins(plr, share, true)
			Camp.creditFire(share)
			local ls = plr:FindFirstChild("leaderstats")
			if ls then ls.Padam.Value += 1 end
			Remotes.Sfx:FireClient(plr, "Coin", nil, share)
		end
	end
end

local function extinguish(fire)
	State.dayStats.out += 1
	State.runStats.out += 1
	Remotes.Sfx:FireAllClients("Sizzle", fire.info.pos)
	-- the scout who marked this fire gets a bonus if someone else put it out
	local scout = fire.scout
	if scout and scout.Parent and not fire.contrib[scout] then
		local n = Progression.addCoins(scout, Config.ScoutReward, true)
		Remotes.Sfx:FireClient(scout, "Coin", nil, n)
		Remotes.Notify:FireClient(scout, ("Your fire marker helped the crew! +%d"):format(n), "good")
	end
	rewardFire(fire)
	removeFire(fire)
end

-- early days keep new fires closer to town so a new player isn't running for a minute
local function spawnRadius(): number
	if State.mode == "Survival" then return SurvivalRules.day(math.max(1, State.day)).radius end
	local radii = { 320, 360, 420, 520 }
	return radii[State.day] or 9999
end

local function randomTree(peatChance: number): TreeInfo?
	local wantPeat = rng:NextNumber() < peatChance
	local maxR = spawnRadius()
	local function usable(t: TreeInfo, checkPeat: boolean, checkR: boolean): boolean
		if t.fire or t.burnt then return false end
		if checkPeat and t.peat ~= wantPeat then return false end
		-- peat obeys the radius too, so the swamp (~375 studs out) first burns on Day 3
		if checkR and Vector3.new(t.pos.X, 0, t.pos.Z).Magnitude > maxR then return false end
		return true
	end
	for _, pass in { { true, true }, { false, true }, { false, false } } do
		for _ = 1, 60 do
			local t = Trees[rng:NextInteger(1, #Trees)]
			if usable(t, pass[1], pass[2]) then return t end
		end
	end
	return nil
end

local function stepFires(dt: number)
	local now = os.clock()
	local dayCfg = activeDayCfg or Config.Days[math.clamp(State.day, 1, Config.TotalDays)]
	local toIgnite = {}
	for fire in Fires do
		local info = fire.info
		if State.raining then
			fire.intensity -= Config.RainDamage * dt
			if fire.intensity <= 0 and not fire.smoulder then
				if fire.peat then
					fire.smoulder = true
					fire.reigniteAt = now + rng:NextNumber(Config.PeatReignite[1], Config.PeatReignite[2])
				else
					State.dayStats.out += 1
					State.runStats.out += 1
					removeFire(fire)
				end
			end
			if Fires[fire] then updateFireVisual(fire) end
			continue
		end
		if fire.smoulder then
			if now >= fire.reigniteAt then
				fire.smoulder = false
				fire.intensity = 35
				fire.soak = 0
				notify("A peat fire flared up again! Soak peat fires completely.", "warn")
				Remotes.Sfx:FireAllClients("Ignite", info.pos)
			end
		else
			fire.intensity = math.min(100, fire.intensity + Config.FireGrowth * (dayCfg.growth or 1) * dt)
			if fire.intensity >= 100 then
				fire.fullTime += dt
				charTree(info, 0.3 + 0.7 * fire.fullTime / Config.BurnOutTime)
				if fire.fullTime >= Config.BurnOutTime then
					info.burnt = true
					State.runStats.burnt += 1
					charTree(info, 1)
					removeFire(fire)
					continue
				end
			end
			if fire.intensity >= Config.SpreadAt then
				for _, n in info.neighbours do
					if not n.fire and not n.burnt then
						local dir = (n.pos - info.pos).Unit
						local align = dir:Dot(State.wind) -- -1..1
						local windMul = math.clamp(1 + align * 0.9 * State.windStrength, 0.25, 2.2)
						local peatMul = (info.peat and n.peat) and Config.PeatSpreadMul or 1
						local chance = Config.SpreadChance * windMul * dayCfg.wind * peatMul * dt
						if rng:NextNumber() < chance then
							table.insert(toIgnite, n)
						end
					end
				end
			end
		end
		if Fires[fire] then updateFireVisual(fire) end
	end
	for _, n in toIgnite do
		ignite(n, 15)
	end
end

---------------------------------------------------------------- players / gear (saved data, shop, rides and passes live in Progression)
Players.PlayerRemoving:Connect(function(plr)
	State.seedLoaders[plr] = nil
end)

local shopPrompt = Map.Town.FireStation.ShopCounter:FindFirstChild("ShopPrompt")
if shopPrompt then
	shopPrompt.Triggered:Connect(function(plr)
		Remotes.Notify:FireClient(plr, "__openshop", "shop")
	end)
end

---------------------------------------------------------------- pings (crew callouts)
local lastPing: { [Player]: number } = {}
local scoutClaims: { [Player]: number } = {} -- reset each day
local PING_KINDS = { Fire = true, Water = true, Help = true, Follow = true }
Remotes.Ping.OnServerEvent:Connect(function(plr: Player, kind: any, pos: any)
	if typeof(kind) ~= "string" or not PING_KINDS[kind] or typeof(pos) ~= "Vector3" or pos ~= pos then return end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (pos - root.Position).Magnitude > 500 or math.abs(pos.Y - root.Position.Y) > 150 then return end
	local now = os.clock()
	if now - (lastPing[plr] or 0) < Config.PingCooldown then return end
	lastPing[plr] = now
	if kind == "Fire" then
		-- first player to mark a fire earns a scout bonus when the crew puts it out
		-- only pays if you were reasonably close, up to a daily cap (no farming from across the map)
		local claimed = scoutClaims[plr] or 0
		if claimed < Config.ScoutDailyCap then
			for fire in Fires do
				if not fire.scout and (Vector3.new(fire.info.pos.X, pos.Y, fire.info.pos.Z) - pos).Magnitude < 20
					and (fire.info.pos - root.Position).Magnitude <= Config.ScoutRange then
					fire.scout = plr
					scoutClaims[plr] = claimed + 1
					break
				end
			end
		end
	end
	Remotes.Ping:FireAllClients(plr, kind, pos)
end)
Players.PlayerRemoving:Connect(function(plr)
	lastPing[plr] = nil
	scoutClaims[plr] = nil
end)

---------------------------------------------------------------- spraying
local lastSpray: { [Player]: number } = {}

Remotes.Spray.OnServerEvent:Connect(function(plr: Player, aim: any, active: any)
	local char = plr.Character
	local tool = char and char:FindFirstChild("Hose")
	if active ~= true then
		-- unequipping sends this after the tool is already back in the Backpack
		local t = tool or plr.Backpack:FindFirstChild("Hose")
		if t then t:SetAttribute("Spraying", false) end
		return
	end
	if not tool then return end
	if Progression.isRiding(plr) or plr:GetAttribute("Downed") then
		tool:SetAttribute("Spraying", false)
		return
	end
	if typeof(aim) ~= "Vector3" then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local now = os.clock()
	local dt = math.min(now - (lastSpray[plr] or now - 0.1), 0.25)
	lastSpray[plr] = now

	local water = plr:GetAttribute("Water") or 0
	local infinite = plr:GetAttribute("InfiniteWater") == true
	if water <= 0 and not infinite then
		tool:SetAttribute("Spraying", false)
		return
	end
	local range = plr:GetAttribute("Range") or 40
	local offset = aim - root.Position
	if offset.Magnitude > range then
		aim = root.Position + offset.Unit * range
	end
	tool:SetAttribute("Spraying", true)
	tool:SetAttribute("Aim", aim)
	if not infinite then
		plr:SetAttribute("Water", math.max(0, water - Config.WaterPerSec * dt))
	end

	local st = Progression.stats(plr)
	local power = st.power
	for fire in Fires do
		local d = Vector3.new(fire.info.pos.X - aim.X, 0, fire.info.pos.Z - aim.Z).Magnitude
		if d <= st.sprayRadius then
			fire.contrib[plr] = (fire.contrib[plr] or 0) + dt
			if fire.smoulder then
				fire.soak += dt * st.peatSoakMul
				if fire.soak >= Config.PeatSoakTime then
					extinguish(fire)
				end
			else
				fire.intensity -= power * dt
				if fire.intensity <= 0 then
					if fire.peat then
						-- peat goes underground: keep soaking or it comes back
						fire.smoulder = true
						fire.intensity = 0
						fire.soak = 0
						fire.reigniteAt = now + rng:NextNumber(Config.PeatReignite[1], Config.PeatReignite[2])
						notify("Peat is still smouldering underground - keep spraying to soak it!", "peat", plr)
						updateFireVisual(fire)
					else
						extinguish(fire)
					end
				else
					updateFireVisual(fire)
				end
			end
		end
	end
end)

-- truck cannon / area water: knocks fires down fast; peat only goes to smouldering (soak it on foot)
local function damageFiresNear(plr: Player, pos: Vector3, radius: number, amount: number): number
	local hit = 0
	local now = os.clock()
	for fire in Fires do
		local d = Vector3.new(fire.info.pos.X - pos.X, 0, fire.info.pos.Z - pos.Z).Magnitude
		if d <= radius and not fire.smoulder then
			hit += 1
			fire.contrib[plr] = (fire.contrib[plr] or 0) + amount / 100
			fire.intensity -= amount
			if fire.intensity <= 0 then
				if fire.peat then
					fire.smoulder = true
					fire.intensity = 0
					fire.soak = 0
					fire.reigniteAt = now + rng:NextNumber(Config.PeatReignite[1], Config.PeatReignite[2])
					updateFireVisual(fire)
				else
					extinguish(fire)
				end
			else
				updateFireVisual(fire)
			end
		end
	end
	return hit
end

---------------------------------------------------------------- downed + revive (multiplayer)
-- Haze can't kill outright: you collapse, and a teammate can revive you before the timer runs out.
local function goDown(plr: Player, hum: Humanoid, root: BasePart)
	if plr:GetAttribute("Downed") then return end
	Progression.dismount(plr)
	hum:UnequipTools()
	hum.Health = 1
	local solo = #Players:GetPlayers() <= 1
	local secs = (if solo then Config.Revive.soloDownSeconds else Config.Revive.downSeconds) + (Camp.has("RescueShelter") and 10 or 0)
	plr:SetAttribute("DownedDuration", secs)
	plr:SetAttribute("Downed", true)
	plr:SetAttribute("DownedUntil", workspace:GetServerTimeNow() + secs)
	if solo then
		notify("You collapsed from the haze! Heading back to the BOMBA station...", "band", plr)
		return
	end
	notify("You collapsed from the haze! Hang on, a teammate can revive you.", "band", plr)
	for _, other in Players:GetPlayers() do
		if other ~= plr then notify(("%s collapsed! Go revive them."):format(plr.DisplayName), "warn", other) end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RevivePrompt"
	prompt.ActionText = "Revive"
	prompt.ObjectText = plr.DisplayName
	prompt.HoldDuration = Camp.has("RescueShelter") and 1.2 or Config.Revive.holdSeconds
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(helper)
		if helper == plr or helper:GetAttribute("Downed") or not plr:GetAttribute("Downed") then return end
		plr:SetAttribute("Downed", false)
		hum.Health = math.max(hum.Health, Config.Revive.reviveHealth)
		prompt:Destroy()
		local n = Progression.addCoins(helper, Config.Revive.reward, true)
		Remotes.Sfx:FireClient(helper, "Coin", nil, n)
		notify(("%s revived %s! +%d"):format(helper.DisplayName, plr.DisplayName, n), "good")
	end)
end

-- downed timer ran out: pass out and respawn at the station
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, plr in Players:GetPlayers() do
			if plr:GetAttribute("Downed") then
				local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
				local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health >= Config.Revive.reviveHealth then
					-- recovered on their own (e.g. healing inside the station)
					plr:SetAttribute("Downed", false)
					local p = root and root:FindFirstChild("RevivePrompt")
					if p then p:Destroy() end
				elseif workspace:GetServerTimeNow() >= (plr:GetAttribute("DownedUntil") or 0) then
					plr:SetAttribute("Downed", false)
					if hum then hum.Health = 0 end
				end
			end
		end
	end
end)

---------------------------------------------------------------- refill + haze effects on players
local refillZones = CS:GetTagged("Refill")

local function inZone(pos: Vector3, zone: BasePart): boolean
	local rel = zone.CFrame:PointToObjectSpace(pos)
	local h = zone.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 4 and math.abs(rel.Z) <= h.Z
end

local function inAnyRefill(pos: Vector3): boolean
	for _, z in refillZones do
		if (z:GetAttribute("Rate") or 30) > 0 and inZone(pos, z) then return true end
	end
	return false
end

-- inside the BOMBA station = clean air: heals, no haze damage (follows the model if the map moves it)
local safeZone = Instance.new("Part")
do
	local cf, size = Map.Town.FireStation:GetBoundingBox()
	safeZone.CFrame = cf
	safeZone.Size = size
end

task.spawn(function()
	while true do
		local dt = task.wait(0.25)
		local band = Config.BandIndex(State.api)
		for _, plr in Players:GetPlayers() do
			-- one bad player record must never stop refills/haze for everyone
			local okPlr, err = pcall(function()
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local rate = 0
				for _, z in refillZones do
					if inZone(root.Position, z) then
						rate = math.max(rate, z:GetAttribute("Rate") or 30)
					end
				end
				local cap = plr:GetAttribute("MaxWater") or 100
				local w = plr:GetAttribute("Water") or 0
				if rate > 0 and w < cap then
					rate *= Progression.stats(plr).refillMul
					plr:SetAttribute("Water", math.min(cap, w + rate * dt))
					plr:SetAttribute("Refilling", true)
				else
					plr:SetAttribute("Refilling", false)
				end
				-- upgrades, rides and passes set the base; haze slows you unless masks/lungs resist it
				hum.WalkSpeed = Progression.walkSpeed(plr, band)
				-- haze hurts during the Day; masks + Strong Lungs resist; the station heals
				if inZone(root.Position, safeZone) then
					hum.Health = math.min(hum.MaxHealth, hum.Health + Config.Health.stationHeal * dt)
				elseif State.mode == "Survival" and Camp.contains(root.Position) and (State.phase == "Night" or State.phase == "Camp" or Camp.has("FieldKitchen")) then
					if Camp.has("FieldKitchen") then hum.Health = math.min(hum.MaxHealth, hum.Health + 4 * dt) end
				elseif State.phase == "Day" or State.phase == "Night" then
					local drain = (Config.Health.drain[band] or 0) * (1 - Progression.stats(plr).resist) * (State.phase == "Night" and 0.5 or 1)
					if plr:GetAttribute("Downed") then
						-- waiting for a teammate (see the revive section)
					elseif drain > 0 then
						if hum.Health - drain * dt <= 1 then
							goDown(plr, hum, root)
						else
							hum:TakeDamage(drain * dt)
						end
					else
						hum.Health = math.min(hum.MaxHealth, hum.Health + Config.Health.cleanAirHeal * dt)
					end
				end
			end
			end)
			if not okPlr then warn("[Jerebu] player tick failed for " .. plr.Name .. ": " .. tostring(err)) end
		end
	end
end)

---------------------------------------------------------------- school field closure (real rule: API > 100)
local fieldClosed = false
local function setFieldClosed(closed: boolean)
	if closed == fieldClosed then return end
	fieldClosed = closed
	local f = Map.Town.School.FieldClosed
	for _, p in f:GetChildren() do
		if p:IsA("BasePart") then p.Transparency = closed and 0 or 1 end
	end
	f.ClosedSign.SurfaceGui.Enabled = closed
	if closed then
		notify("API above 100 - school field closed. Outdoor activities stopped.", "warn")
	end
end

---------------------------------------------------------------- cloud seeding (real rule: API > 150 for over 24 hours)
local airstrip = Map:WaitForChild("Airstrip")
local seedPrompt: ProximityPrompt = airstrip.SeedPad.SeedPrompt
local plane: Model = airstrip.SeedingPlane
local planeHome = plane:GetPivot()

local function loadersNeeded(): number
	return math.max(1, math.ceil(#Players:GetPlayers() / 2))
end

local function runCloudSeeding()
	-- rain only counts for the day it was called in; the flight may outlast nightfall
	local seedDay = State.day
	local function stillToday(): boolean
		return State.phase == "Day" and State.day == seedDay
	end
	State.seedUsedToday = true
	State.seedUnlocked = false
	seedPrompt.Enabled = false
	table.clear(State.seedLoaders)
	setAttr("SeedLoaded", 0)
	setAttr("SeedReady", false)
	notify("Cloud seeding plane taking off!", "good")
	Remotes.Sfx:FireAllClients("Plane", planeHome.Position)
	-- fly: roll down runway, climb, circle out over the forest
	local value = Instance.new("CFrameValue")
	value.Value = planeHome
	value.Changed:Connect(function(cf)
		plane:PivotTo(cf)
	end)
	local function fly(cf: CFrame, t: number, style)
		local tw = TweenService:Create(value, TweenInfo.new(t, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Value = cf })
		tw:Play()
		tw.Completed:Wait()
	end
	-- white seeding trail off the wings while it rains (wingspan runs along the plane's X)
	local body = plane.PrimaryPart or plane:FindFirstChildWhichIsA("BasePart", true)
	local trail: Trail? = nil
	if body then
		local _, size = plane:GetBoundingBox()
		local a0 = Instance.new("Attachment")
		a0.Name = "SeedTrailA"
		a0.Position = Vector3.new(-size.X * 0.35, 0, 0)
		a0.Parent = body
		local a1 = Instance.new("Attachment")
		a1.Name = "SeedTrailB"
		a1.Position = Vector3.new(size.X * 0.35, 0, 0)
		a1.Parent = body
		trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(Color3.fromRGB(245, 248, 255))
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
		trail.Lifetime = 3
		trail.LightInfluence = 0.3
		trail.FaceCamera = true
		trail.Enabled = false
		trail.Parent = body
	end
	fly(planeHome * CFrame.new(0, 0, 60), 3, Enum.EasingStyle.Quad)
	fly(planeHome * CFrame.new(0, 60, 220) * CFrame.Angles(math.rad(12), 0, 0), 4)
	fly(CFrame.new(0, 160, -200) * CFrame.Angles(0, math.rad(200), 0), 6)
	if trail then trail.Enabled = true end
	if stillToday() then
		State.raining = true
		setAttr("Raining", true)
		notify("Hujan! Rain is falling. Fires are dying down and the air is clearing.", "good")
	end
	fly(CFrame.new(300, 170, 200) * CFrame.Angles(0, math.rad(90), 0), 8)
	fly(CFrame.new(-300, 170, 200) * CFrame.Angles(0, math.rad(-90), 0), 8)
	fly(planeHome * CFrame.new(0, 40, -200), 6)
	fly(planeHome, 4, Enum.EasingStyle.Quad)
	if trail and body then
		trail.Enabled = false
		task.delay(3.5, function()
			trail:Destroy()
			for _, n in { "SeedTrailA", "SeedTrailB" } do
				local a = body:FindFirstChild(n)
				if a then a:Destroy() end
			end
		end)
	end
	value:Destroy()
	plane:PivotTo(planeHome)
	task.delay(math.max(0, Config.RainTime - 30), function()
		if stillToday() then
			State.raining = false
			setAttr("Raining", false)
		end
	end)
end

seedPrompt.Triggered:Connect(function(plr)
	if not State.seedUnlocked or State.phase ~= "Day" then return end
	if State.seedLoaders[plr] then
		notify("You already loaded flares - get a teammate to help!", "info", plr)
		return
	end
	State.seedLoaders[plr] = true
	local n = 0
	for _ in State.seedLoaders do n += 1 end
	local need = loadersNeeded()
	setAttr("SeedLoaded", n)
	setAttr("SeedNeed", need)
	Remotes.Sfx:FireAllClients("Click")
	if n >= need then
		task.spawn(runCloudSeeding)
	else
		notify(("%s loaded seeding flares (%d/%d). More hands needed at the airstrip!"):format(plr.DisplayName, n, need), "info")
	end
end)

-- "Call the Rain" product: start seeding now if we can, otherwise when the next day starts
local pendingRain = false
local function callRain(plr: Player)
	notify(("%s called the rain for everyone!"):format(plr.DisplayName), "good")
	if State.phase == "Day" and not State.raining and not State.seedUsedToday then
		task.spawn(runCloudSeeding)
	else
		pendingRain = true
		notify("The seeding plane will fly as soon as the next day starts.", "info", plr)
	end
end

---------------------------------------------------------------- API
local lastBand = Config.BandIndex(State.api)

local function stepAPI(dt: number)
	local dayCfg = activeDayCfg or Config.Days[math.clamp(State.day, 1, Config.TotalDays)]
	local delta = 0
	local burning = 0
	for fire in Fires do
		if fire.smoulder then
			delta += Config.APISmoulder * dt
		else
			burning += 1
			delta += Config.APIPerFire * (fire.intensity / 100) * dt
		end
	end
	-- transboundary haze arrives no matter what
	delta += dayCfg.haze / Config.DayLength * dt
	if burning == 0 then delta -= Config.APIRecover * dt end
	if State.raining then delta -= Config.APIRain * dt end
	State.api = math.clamp(State.api + delta, 0, 500)

	-- band change alerts
	local b = Config.BandIndex(State.api)
	if b ~= lastBand then
		local band = Config.Bands[b]
		if b > lastBand then
			notify(("Air quality worsened: %s · %s"):format(band.en:upper(), band.bm:upper()), "band")
			if b >= 4 then Remotes.Sfx:FireAllClients("Alarm") end
		else
			notify(("Air quality improved: %s · %s"):format(band.en, band.bm), "good")
		end
		lastBand = b
	end
	setFieldClosed(State.api > 100)

	-- cloud seeding unlock
	if State.api > Config.SeedThreshold and not State.seedUsedToday then
		State.above150 += dt
		if not State.seedUnlocked and State.above150 >= Config.SeedHold then
			State.seedUnlocked = true
			seedPrompt.Enabled = true
			setAttr("SeedReady", true)
			setAttr("SeedNeed", loadersNeeded())
			setAttr("SeedLoaded", 0)
			notify("API above 150 for too long - CLOUD SEEDING unlocked! Go to the airstrip.", "seed")
			Remotes.Sfx:FireAllClients("Alarm")
		end
	elseif State.api <= Config.SeedThreshold then
		State.above150 = math.max(0, State.above150 - dt)
	end

	setAttr("API", math.floor(State.api + 0.5))
	setAttr("Fires", activeFireCount())
	setAttr("Smoulder", totalFires() - activeFireCount())
end

---------------------------------------------------------------- day cycle
local function setWind()
	local a = rng:NextNumber(0, math.pi * 2)
	State.wind = Vector3.new(math.cos(a), 0, math.sin(a))
	State.windStrength = rng:NextNumber(0.6, 1.0)
	setAttr("Wind", State.wind * State.windStrength)
end

local function clearAllFires()
	for fire in Fires do removeFire(fire) end
end

local skipPhase = false

local function countdown(phase: string, seconds: number, tick: ((number) -> ())?)
	State.phase = phase
	setAttr("Phase", phase)
	skipPhase = false
	local t = seconds
	while t > 0 and not skipPhase and not (State.mode == "Survival" and survivalReason and phase ~= "Ended") do
		setAttr("TimeLeft", math.ceil(t))
		local dt = task.wait(0.2)
		t -= dt
		if tick then tick(dt) end
	end
	setAttr("TimeLeft", 0)
end

local function avg(list: { number }): number
	if #list == 0 then return State.api end
	local s = 0
	for _, v in list do s += v end
	return s / #list
end

local function phaseLength(name, normal)
	if RunService:IsStudio() then
		local value = workspace:GetAttribute("Debug" .. name .. "Length")
		if typeof(value) == "number" and value >= 1 and value <= normal then return value end
	end
	return normal
end

local function runNight(day)
	notify("MALAM · Return to camp together to rest.", "day")
	local candidates = {}
	for _, info in Trees do
		if not info.fire and not info.burnt and (info.pos - Camp.center).Magnitude <= 150 then table.insert(candidates, info) end
	end
	for _ = 1, math.min(#candidates, 2 + math.floor(day / 3), maxFires()) do
		local index = rng:NextInteger(1, #candidates)
		ignite(table.remove(candidates, index), 10)
	end
	local duration, elapsed, checked = phaseLength("Night", 60), 0, false
	countdown("Night", duration, function(dt)
		elapsed += dt
		game.Lighting.ClockTime = (20 + 8 * math.min(1, elapsed / duration)) % 24
		stepFires(dt)
		stepAPI(dt)
		if not checked and elapsed >= duration / 2 then
			checked = true
			local crew = Players:GetPlayers()
			local safe = #crew > 0
			for _, p in crew do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if not root or not hum or hum.Health <= 0 or p:GetAttribute("Downed") or not (Camp.contains(root.Position) or inZone(root.Position, safeZone)) then safe = false end
			end
			if safe then
				for _, p in crew do Progression.addCoins(p, 5, false) end
				notify("The crew rests! +5 coins each.", "good")
				skipPhase = true
			end
		end
	end)
	clearAllFires()
	setAttr("Fires", 0)
	setAttr("Smoulder", 0)
end

local function runDay(day: number, cfg)
	local dayLength = Config.DayLength
	-- Shorten only Studio test days; published rounds always use Config.DayLength.
	if RunService:IsStudio() then
		local debugLength = workspace:GetAttribute("DebugDayLength")
		if typeof(debugLength) == "number" and debugLength >= 1 and debugLength <= Config.DayLength then
			dayLength = debugLength
		end
	end
	setAttr("DayDuration", dayLength)
	local dayCrew = Players:GetPlayers()
	if State.mode == "Survival" then resetTrees() end
	State.day = day
	State.seedUsedToday = false
	State.above150 = 0
	State.dayStats = { out = 0, spawned = 0 }
	table.clear(scoutClaims)
	setAttr("Day", day)
	setWind()
	activeDayCfg = cfg
	if State.mode == "Survival" then
		setAttr("SurvivalDay", day)
		Players.RespawnTime = SurvivalRules.respawnDelay(day)
	end
	setAttr("FireCap", maxFires())
	local coopMul = 1 + Config.CoopSpawnPerPlayer * math.max(0, #Players:GetPlayers() - 1)
	notify(("HARI %d · DAY %d - fires reported in the forest!"):format(day, day), "day")
	for _ = 1, math.floor(cfg.burst * coopMul + 0.5) do
		local t = randomTree(cfg.peat)
		if t then ignite(t, rng:NextNumber(15, 35)) end
	end
	if pendingRain then
		pendingRain = false
		task.delay(5, runCloudSeeding)
	end
	local nextSpawn = cfg.spawnEvery / coopMul
	local elapsed = 0
	local apiSamples = {}
	local sampleT = 0
	local hazardousSeconds = 0
	countdown("Day", dayLength, function(dt)
		elapsed += dt
		-- sun moves 8:00 -> 18:30
		game.Lighting.ClockTime = 8 + 10.5 * (elapsed / dayLength)
		nextSpawn -= dt
		if nextSpawn <= 0 and not State.raining then
			nextSpawn = cfg.spawnEvery / coopMul * rng:NextNumber(0.75, 1.25)
			local t = randomTree(cfg.peat)
			if t then ignite(t) end
		end
		stepFires(dt)
		stepAPI(dt)
		if State.mode == "Survival" then
			-- Continuous hazardous exposure resets when the air improves.
			hazardousSeconds = SurvivalRules.hazardExposure(hazardousSeconds, State.api, dt)
			setAttr("HazardousSeconds", math.floor(hazardousSeconds))
			if hazardousSeconds >= dayLength then survivalReason = "evacuated" end
		end
		sampleT += dt
		if sampleT >= 5 then
			sampleT = 0
			table.insert(apiSamples, State.api)
		end
	end)

	if State.mode == "Survival" and survivalReason then return end
	-- nightfall: what's still burning goes into the air overnight
	local left = activeFireCount()
	local smoulder = totalFires() - left
	local before = State.api
	State.api += left * Config.NightPerFire + smoulder * (Config.NightPerFire * 0.5)
	if totalFires() == 0 then State.api -= Config.CleanDayBonus end
	State.api = math.clamp(State.api, 0, 500)
	for fire in Fires do
		fire.info.burnt = true
		charTree(fire.info, 1)
		State.runStats.burnt += 1
	end
	clearAllFires()
	State.raining = false
	setAttr("Raining", false)
	seedPrompt.Enabled = false
	State.seedUnlocked = false
	setAttr("SeedReady", false)
	setAttr("API", math.floor(State.api + 0.5))
	setAttr("Fires", 0)
	setAttr("Smoulder", 0)

	local dayAvg = avg(apiSamples)
	table.insert(State.dailyAPI, dayAvg)
	if State.mode ~= "Survival" then Remotes.Report:FireAllClients({
		day = day,
		out = State.dayStats.out,
		spawned = State.dayStats.spawned,
		left = left + smoulder,
		apiBefore = math.floor(before + 0.5),
		apiAfter = math.floor(State.api + 0.5),
		avg = math.floor(dayAvg + 0.5),
		clean = (left + smoulder) == 0,
		last = State.mode ~= "Survival" and day >= Config.TotalDays,
		mode = State.mode,
	}) end
	game.Lighting.ClockTime = 20
	if State.mode == "Survival" then
		runNight(day)
		if survivalReason then return end
		State.completedDays += 1
		setAttr("DaysSurvived", State.completedDays)
		for _, p in dayCrew do
			if p.Parent == Players then survivalDaysByPlayer[p] = (survivalDaysByPlayer[p] or 0) + 1 end
		end
		notify("KEM · Spend the shared Camp Fund at the kiosk.", "good")
		game.Lighting.ClockTime = 6
		countdown("Camp", phaseLength("Camp", 20))
	else
		countdown("Report", Config.ReportLength)
	end
end

-- Studio-only debug switches: DebugSkip = true ends the current phase, DebugAPI = n forces the API
if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("DebugSkip"):Connect(function()
		if workspace:GetAttribute("DebugSkip") then
			skipPhase = true
			workspace:SetAttribute("DebugSkip", false)
		end
	end)
	-- DebugCoins = n gives every player n coins (tests can't require Progression: that makes a second copy)
	workspace:GetAttributeChangedSignal("DebugCoins"):Connect(function()
		local n = workspace:GetAttribute("DebugCoins")
		if typeof(n) == "number" and n > 0 then
			for _, p in Players:GetPlayers() do Progression.addCoins(p, n, false) end
			workspace:SetAttribute("DebugCoins", nil)
		end
	end)
	workspace:GetAttributeChangedSignal("DebugAPI"):Connect(function()
		local v = workspace:GetAttribute("DebugAPI")
		if typeof(v) == "number" then
			State.api = v
			setAttr("API", v)
		end
	end)
end

-- Only players who have spawned count toward a crew wipe. A joining avatar cannot
-- hold a defeated run open, and an empty server resets without awarding rewards.
task.spawn(function()
	while true do
		task.wait(0.25)
		if State.mode == "Survival" and (State.phase == "Day" or State.phase == "Night" or State.phase == "Camp") and not survivalReason then
			local alive, crew = 0, 0
			for _, p in Players:GetPlayers() do
				if p.Character then
					crew += 1
					local h = p.Character:FindFirstChildOfClass("Humanoid")
					if h and h.Health > 0 and not p:GetAttribute("Downed") then alive += 1 end
				end
			end
			if crew > 0 then survivalHadCrew = true end
			if survivalHadCrew and alive == 0 then
				survivalReason = #Players:GetPlayers() == 0 and "empty" or "crewDown"
				setAttr("RunOver", true)
			end
		end
	end
end)

local function runSurvival()
	local day = 1
	while not survivalReason do
		runDay(day, SurvivalRules.day(day))
		day += 1
	end
	setAttr("RunOver", true)
	State.phase = "Ended"
	setAttr("Phase", "Ended")
	clearAllFires()
	State.raining = false
	setAttr("Raining", false)
	seedPrompt.Enabled = false
	setAttr("SeedReady", false)
	setAttr("Fires", 0)
	setAttr("Smoulder", 0)
	Players.RespawnTime = defaultRespawnTime
	for _, p in Players:GetPlayers() do
		local reward = Progression.addCoins(p, 20 * (survivalDaysByPlayer[p] or 0), true)
		p:SetAttribute("SurvivalSessionBest", math.max(p:GetAttribute("SurvivalSessionBest") or 0, State.completedDays))
		Remotes.Ending:FireClient(p, {
			mode = "Survival", reason = survivalReason, days = State.completedDays,
			reward = reward, best = p:GetAttribute("SurvivalSessionBest"),
			out = State.runStats.out, daily = {},
		})
		task.spawn(Progression.save, p)
		p:SetAttribute("Downed", false)
		local char = p.Character
		local prompt = char and char:FindFirstChild("RevivePrompt", true)
		if prompt then prompt:Destroy() end
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
	end
	countdown("Ended", Config.EndingLength)
end

local function runGame()
	while true do
		-- fresh run
		State.mode = "Story"
		Camp.reset()
		State.phase = "Intermission"
		State.day = 0
		State.completedDays = 0
		activeDayCfg = nil
		survivalReason = nil
		survivalHadCrew = false
		table.clear(survivalDaysByPlayer)
		Players.RespawnTime = defaultRespawnTime
		table.clear(votes)
		table.clear(lastVote)
		for _, p in Players:GetPlayers() do p:SetAttribute("ModeVote", nil) end
		voteCounts()
		setAttr("Mode", "Story")
		setAttr("RunOver", false)
		setAttr("SurvivalDay", 0)
		setAttr("DaysSurvived", 0)
		setAttr("HazardousSeconds", 0)
		State.api = Config.StartAPI
		State.dailyAPI = {}
		State.runStats = { out = 0, spawned = 0, burnt = 0 }
		lastBand = Config.BandIndex(State.api)
		resetTrees()
		clearAllFires()
		setFieldClosed(false)
		setAttr("API", State.api)
		setAttr("Day", 0)
		setAttr("Raining", false)
		setAttr("SeedReady", false)
		game.Lighting.ClockTime = 8
		setWind()
		while #Players:GetPlayers() == 0 do task.wait(1) end
		countdown("Intermission", Config.Intermission)

		local storyVotes, survivalVotes = voteCounts()
		State.mode = SurvivalRules.winner(storyVotes, survivalVotes)
		setAttr("Mode", State.mode)
		if State.mode == "Survival" then
			runSurvival()
			continue
		end
		for day = 1, Config.TotalDays do
			runDay(day, Config.Days[day])
		end

		local average = avg(State.dailyAPI)
		local ending = "emergency"
		if average <= 100 then
			ending = "clear"
		elseif average <= 200 then
			ending = "survived"
		end
		State.phase = "Ended"
		setAttr("Phase", "Ended")
		Remotes.Ending:FireAllClients({
			ending = ending,
			average = math.floor(average + 0.5),
			daily = State.dailyAPI,
			out = State.runStats.out,
			spawned = State.runStats.spawned,
			burnt = State.runStats.burnt,
		})
		-- reward everyone for finishing a run
		for _, plr in Players:GetPlayers() do
			Progression.addCoins(plr, Config.RunBonus[ending], true)
			task.spawn(Progression.save, plr)
		end
		countdown("Ended", Config.EndingLength)
	end
end

Progression.init({
	damageFiresNear = damageFiresNear,
	inRefill = inAnyRefill,
	callRain = callRain,
	canCallRain = function(): boolean
		return not pendingRain and not State.raining
	end,
})

task.spawn(runGame)
