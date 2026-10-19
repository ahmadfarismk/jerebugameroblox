-- Jerebu round 5 crew visuals (client only):
--   1. ping pillars + ground ring pulse (Remotes.Ping.OnClientEvent)
--   2. downed players: red pulsing Highlight, "SOS" smoke flare, slumped pose (local), revive sparkle burst
--   3. clean-air relief: green "+" drift on the local player while healing inside the BOMBA station
-- The icon billboards for pings belong to the HUD; this script only draws the world-space light.
-- Everything except the ping pillars switches off beyond FX_RANGE studs from the camera.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Remotes = J:WaitForChild("Remotes")
local Sounds = J:WaitForChild("Sounds")

local C = Color3.fromRGB
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local RING_TEX = "rbxasset://textures/particles/explosion01_shockwave_main.dds"

local FX_RANGE = 250 -- downed FX / relief are skipped beyond this distance from the camera
local PING_LIFE = 8
local PING_FADE_IN = 0.35
local PING_FADE_OUT = 2.2
local PING_HEIGHT = 80
local MAX_PINGS = 8

local PING_COLORS: { [string]: Color3 } = {
	Fire = C(255, 128, 36),
	Water = C(64, 168, 255),
	Help = C(255, 56, 56),
	Follow = C(80, 232, 120),
}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalCrewFX"
fxFolder.Parent = workspace

local function fxPart(name: string, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = parent or fxFolder
	return p
end

local function emitterOn(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	for k, v in props do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function cameraDistance(pos: Vector3): number
	local cam = workspace.CurrentCamera
	return if cam then (cam.CFrame.Position - pos).Magnitude else 0
end

local function rootOf(plr: Player): BasePart?
	local char = plr.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

---------------------------------------------------------------- 1. ping pillars
-- Each pillar = a camera-facing Beam (in-world, depth correct) + a BillboardGui light column. Billboards
-- ignore Atmosphere fog, so the column stays readable through thick haze (band 5).
type Ping = {
	owner: Player?,
	t0: number,
	color: Color3,
	part: Part,
	beam: Beam,
	layers: { { frame: Frame, base: number } },
	ring: ParticleEmitter,
	nextRing: number,
	rings: number,
}
local pings: { Ping } = {}

local function verticalFade(): UIGradient
	local g = Instance.new("UIGradient")
	g.Rotation = 90 -- offset 0 = top, 1 = bottom
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 0.65),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	return g
end

local function removePing(p: Ping)
	local i = table.find(pings, p)
	if i then table.remove(pings, i) end
	p.part:Destroy()
end

local function spawnPing(owner: Player?, kind: string, pos: Vector3)
	local color = PING_COLORS[kind]
	if not color then return end
	-- one pillar per player: a new ping replaces their previous one; cap the total for phones
	for i = #pings, 1, -1 do
		if owner and pings[i].owner == owner then removePing(pings[i]) end
	end
	while #pings >= MAX_PINGS do removePing(pings[1]) end

	local part = fxPart("PingPillar_" .. kind)
	part.Position = pos
	local top = Instance.new("Attachment")
	top.Name = "Top"
	top.Position = Vector3.new(0, PING_HEIGHT, 0)
	top.Parent = part
	local bottom = Instance.new("Attachment")
	bottom.Name = "Bottom"
	bottom.Position = Vector3.new(0, 0.2, 0)
	bottom.Parent = part

	local beam = Instance.new("Beam")
	beam.Attachment0 = bottom
	beam.Attachment1 = top
	beam.FaceCamera = true
	beam.Width0 = 3.2
	beam.Width1 = 2
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(color:Lerp(C(255, 255, 255), 0.25))
	beam.Transparency = NumberSequence.new(1)
	beam.Segments = 1
	beam.Parent = part

	-- billboard: studs-sized (Scale = studs), so it keeps perspective like a real pillar
	local gui = Instance.new("BillboardGui")
	gui.Name = "Column"
	gui.Adornee = part
	gui.Size = UDim2.fromScale(9, PING_HEIGHT)
	gui.StudsOffsetWorldSpace = Vector3.new(0, PING_HEIGHT / 2, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.MaxDistance = 2500
	gui.Parent = part

	local layers = {}
	local function layer(widthScale: number, c: Color3, base: number)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(widthScale, 1)
		f.BackgroundColor3 = c
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = f
		verticalFade().Parent = f
		table.insert(layers, { frame = f, base = base })
	end
	layer(1, color, 0.22) -- wide soft halo
	layer(0.5, color, 0.42)
	layer(0.16, color:Lerp(C(255, 255, 255), 0.55), 0.7) -- bright core

	-- ground ring pulse (re-emitted a few times while the pillar is up)
	local ring = emitterOn(part, {
		Texture = RING_TEX,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		EmissionDirection = Enum.NormalId.Top,
		Color = ColorSequence.new(color),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 20) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(1.4, 1.4),
		Speed = NumberRange.new(0, 0),
		Rotation = NumberRange.new(0, 0),
	})
	ring.Brightness = 2
	ring:Emit(1)

	table.insert(pings, {
		owner = owner,
		t0 = os.clock(),
		color = color,
		part = part,
		beam = beam,
		layers = layers,
		ring = ring,
		nextRing = 1.5,
		rings = 1,
	})
end

Remotes:WaitForChild("Ping").OnClientEvent:Connect(function(owner: any, kind: any, pos: any)
	if typeof(kind) ~= "string" or typeof(pos) ~= "Vector3" then return end
	spawnPing(if typeof(owner) == "Instance" and owner:IsA("Player") then owner else nil, kind, pos)
end)

local function updatePings(now: number)
	for i = #pings, 1, -1 do
		local p = pings[i]
		local age = now - p.t0
		if age >= PING_LIFE then
			removePing(p)
		else
			local a = math.min(age / PING_FADE_IN, 1) * math.clamp((PING_LIFE - age) / PING_FADE_OUT, 0, 1)
			-- gentle breathing so it reads as a beacon, not a static bar
			local breathe = 0.9 + 0.1 * math.sin(age * 3)
			a *= breathe
			for _, l in p.layers do
				l.frame.BackgroundTransparency = 1 - l.base * a
			end
			local bt = 1 - 0.5 * a
			p.beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, bt),
				NumberSequenceKeypoint.new(0.55, math.min(1, bt + 0.25)),
				NumberSequenceKeypoint.new(1, 1),
			})
			if p.rings < 3 and age >= p.nextRing then
				p.rings += 1
				p.nextRing += 1.5
				p.ring:Emit(1)
			end
		end
	end
end

---------------------------------------------------------------- 2. downed players
-- Downed/DownedUntil are replicated player attributes (JerebuServer.goDown).
local SOS_CYCLE = 9
local SOS_EVENTS: { number } = {} -- emit times within one cycle: S (3 dots), O (3 dashes), S (3 dots)
for _, t in { 0, 0.45, 0.9 } do table.insert(SOS_EVENTS, t) end
for _, start in { 1.8, 3.0, 4.2 } do
	for k = 0, 4 do table.insert(SOS_EVENTS, start + k * 0.15) end
end
for _, t in { 5.7, 6.15, 6.6 } do table.insert(SOS_EVENTS, t) end
table.sort(SOS_EVENTS)

type DownedFX = {
	plr: Player,
	char: Model?,
	highlight: Highlight?,
	flarePart: Part,
	flare: ParticleEmitter,
	t0: number,
	lastPhase: number,
	near: boolean,
}
local downedFx: { [Player]: DownedFX } = {}
local wasDowned: { [Player]: boolean } = {}

local function buildFlare(): (Part, ParticleEmitter)
	local part = fxPart("SOSFlare")
	local e = emitterOn(part, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C(255, 70, 50)),
			ColorSequenceKeypoint.new(0.5, C(255, 120, 90)),
			ColorSequenceKeypoint.new(1, C(230, 190, 185)),
		}),
		LightEmission = 0.45,
		LightInfluence = 0.15,
		Brightness = 2.5,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8.5) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.6, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(4.2, 4.8),
		Speed = NumberRange.new(10, 12),
		SpreadAngle = Vector2.new(5, 5),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 1.2, 0),
		RotSpeed = NumberRange.new(-25, 25),
		Rotation = NumberRange.new(0, 360),
	})
	return part, e
end

local function clearDowned(plr: Player)
	local fx = downedFx[plr]
	if not fx then return end
	downedFx[plr] = nil
	if fx.highlight then fx.highlight:Destroy() end
	fx.flarePart:Destroy()
end

local function setupDowned(plr: Player)
	local char = plr.Character
	if not char then return end
	local fx = downedFx[plr]
	if fx and fx.char == char then return end
	clearDowned(plr)

	local hl = Instance.new("Highlight")
	hl.Name = "DownedGlow"
	hl.FillColor = C(255, 40, 40)
	hl.OutlineColor = C(255, 90, 80)
	hl.FillTransparency = 0.75
	hl.OutlineTransparency = 0.35
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- teammates can find them through haze and walls
	hl.Adornee = char
	hl.Enabled = false
	hl.Parent = char

	local part, flare = buildFlare()
	downedFx[plr] = {
		plr = plr,
		char = char,
		highlight = hl,
		flarePart = part,
		flare = flare,
		t0 = os.clock(),
		lastPhase = 0,
		near = plr == player,
	}
end

-- local slumped pose: only the downed player plays it, the animation replicates to everyone
local FALLBACK_SIT = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" }
local slumpTrack: AnimationTrack? = nil
local slumpChar: Model? = nil

local function stopSlump()
	local t = slumpTrack
	if t then
		pcall(function()
			t:Stop(0.3)
			t:Destroy()
		end)
	end
	slumpTrack = nil
	slumpChar = nil
end

local function updateSlump()
	local down = player:GetAttribute("Downed") == true
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (down and char and hum and hum.Health > 0) then
		if slumpTrack then stopSlump() end
		return
	end
	if slumpChar ~= char then stopSlump() end
	local track = slumpTrack
	if not track then
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then return end
		local animate = char:FindFirstChild("Animate")
		local sit = animate and animate:FindFirstChild("sit")
		local sa = sit and sit:FindFirstChild("SitAnim")
		local id = if sa and sa:IsA("Animation") and sa.AnimationId ~= "" then sa.AnimationId else (FALLBACK_SIT[hum.RigType] or FALLBACK_SIT[Enum.HumanoidRigType.R15])
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, loaded = pcall(function() return animator:LoadAnimation(anim) end)
		if not ok then return end
		loaded.Priority = Enum.AnimationPriority.Action
		loaded.Looped = true
		loaded:Play(0.4)
		slumpTrack = loaded
		slumpChar = char
	elseif not track.IsPlaying then
		track:Play(0.3)
	end
end

-- revive: short green/white sparkle burst + soft chime
local function reviveBurst(plr: Player, char: Model)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	if plr ~= player and cameraDistance(root.Position) > 120 then return end
	local att = Instance.new("Attachment")
	att.Name = "ReviveFX"
	att.Parent = root
	local sparks = emitterOn(att, {
		Texture = SPARK_TEX,
		Color = ColorSequence.new(C(130, 255, 160), C(255, 255, 255)),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(6, 15),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 7, 0),
		Drag = 2,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120),
	})
	local glow = emitterOn(att, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(C(190, 255, 205)),
		LightEmission = 1,
		LightInfluence = 0,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.6, 0.6),
		Speed = NumberRange.new(0, 0),
	})
	sparks:Emit(34)
	glow:Emit(2)
	local snd = Sounds:FindFirstChild("Success")
	if snd and snd:IsA("Sound") then
		local s = snd:Clone()
		s.Volume = 0.25
		s.RollOffMaxDistance = 90
		s.Parent = root
		s:Play()
		Debris:AddItem(s, 4)
	end
	Debris:AddItem(att, 2.5)
end

local function onDownedChanged(plr: Player)
	local down = plr:GetAttribute("Downed") == true
	local before = wasDowned[plr] == true
	wasDowned[plr] = down
	if down then
		setupDowned(plr)
	else
		clearDowned(plr)
		if before then
			-- true -> false is either a revive (health jumps up) or a pass-out (health 0 right after)
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hum then
				task.delay(0.35, function()
					if char.Parent and hum.Health > 5 then reviveBurst(plr, char) end
				end)
			end
		end
	end
	if plr == player then updateSlump() end
end

local function trackPlayer(plr: Player)
	plr:GetAttributeChangedSignal("Downed"):Connect(function() onDownedChanged(plr) end)
	plr.CharacterAdded:Connect(function()
		clearDowned(plr)
		if plr:GetAttribute("Downed") == true then
			task.defer(setupDowned, plr)
		end
	end)
	if plr:GetAttribute("Downed") == true then onDownedChanged(plr) end
end

for _, plr in Players:GetPlayers() do trackPlayer(plr) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(plr)
	clearDowned(plr)
	wasDowned[plr] = nil
end)

local function updateDowned(now: number)
	for plr, fx in downedFx do
		local char = fx.char
		local root = rootOf(plr)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and char.Parent and root and hum and hum.Health > 0) then
			clearDowned(plr)
		else
			fx.flarePart.Position = root.Position + Vector3.new(0, 2, 0)
			local hl = fx.highlight
			if fx.near then
				if hl then
					hl.Enabled = true
					local s = 0.5 + 0.5 * math.sin(now * 3.6)
					hl.FillTransparency = 0.82 - 0.2 * s
					hl.OutlineTransparency = 0.55 - 0.3 * s
				end
				-- SOS: three dots, three dashes, three dots (puffs rise as a readable column)
				local phase = (now - fx.t0) % SOS_CYCLE
				local last = fx.lastPhase
				for _, t in SOS_EVENTS do
					local hit = if phase >= last then (t > last and t <= phase) else (t > last or t <= phase)
					if hit then fx.flare:Emit(1) end
				end
				fx.lastPhase = phase
			elseif hl then
				hl.Enabled = false
			end
		end
	end
end

-- distance gating (every 0.4 s): off beyond FX_RANGE except for the local player
task.spawn(function()
	while true do
		task.wait(0.4)
		for plr, fx in downedFx do
			local root = rootOf(plr)
			fx.near = plr == player or (root ~= nil and cameraDistance(root.Position) <= FX_RANGE)
		end
	end
end)

---------------------------------------------------------------- 3. clean-air relief in the BOMBA station
local stationCF: CFrame? = nil
local stationHalf = Vector3.zero
local nextStationRefresh = 0

local function refreshStation(now: number)
	if now < nextStationRefresh then return end
	nextStationRefresh = now + 5
	local map = workspace:FindFirstChild("Map")
	local town = map and map:FindFirstChild("Town")
	local fs = town and town:FindFirstChild("FireStation")
	if fs and fs:IsA("Model") then
		local cf, size = fs:GetBoundingBox() -- same box the server uses for its safe zone
		stationCF = cf
		stationHalf = size / 2
	end
end

local function inStation(pos: Vector3): boolean
	local cf = stationCF
	if not cf then return false end
	local rel = cf:PointToObjectSpace(pos)
	return math.abs(rel.X) <= stationHalf.X and math.abs(rel.Y) <= stationHalf.Y and math.abs(rel.Z) <= stationHalf.Z
end

local PLUS_COLORS = { C(120, 235, 140), C(170, 250, 180), C(90, 215, 120) }
local plusRng = Random.new()
local nextPlus = 0

local function spawnPlus(root: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(30, 30)
	gui.Adornee = root
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = FX_RANGE
	local a = plusRng:NextNumber(0, math.pi * 2)
	local r = plusRng:NextNumber(1.2, 2.6)
	local start = Vector3.new(math.cos(a) * r, plusRng:NextNumber(-2, 0.5), math.sin(a) * r)
	gui.StudsOffsetWorldSpace = start
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.Text = "+"
	t.TextScaled = true
	t.TextColor3 = PLUS_COLORS[plusRng:NextInteger(1, #PLUS_COLORS)]
	t.TextTransparency = 1
	t.TextStrokeColor3 = C(20, 90, 40)
	t.TextStrokeTransparency = 1
	t.Parent = gui
	gui.Parent = root
	local life = plusRng:NextNumber(1.4, 1.9)
	TweenService:Create(gui, TweenInfo.new(life, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = start + Vector3.new(0, 4.5, 0) }):Play()
	local fadeIn = TweenService:Create(t, TweenInfo.new(0.25), { TextTransparency = 0.1, TextStrokeTransparency = 0.6 })
	fadeIn:Play()
	task.delay(0.25, function()
		if not gui.Parent then return end
		TweenService:Create(t, TweenInfo.new(life - 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	Debris:AddItem(gui, life + 0.1)
end

local function updateRelief(now: number)
	refreshStation(now)
	if now < nextPlus then return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum and hum.Health > 0) then return end
	-- the server heals everyone inside the station box; only show it while there is something to heal
	if inStation(root.Position) and hum.Health < hum.MaxHealth - 0.05 then
		nextPlus = now + 0.3
		spawnPlus(root)
	end
end

---------------------------------------------------------------- main loop
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	updatePings(now)
	updateDowned(now)
	updateRelief(now)
end)

-- slump pose retries every frame until the Animator exists, then holds
RunService.Heartbeat:Connect(function()
	if (player:GetAttribute("Downed") == true) or slumpTrack then updateSlump() end
end)
