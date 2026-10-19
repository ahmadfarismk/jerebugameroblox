-- Jerebu client visuals + audio
-- Haze look is driven by the shared API meter (workspace attribute "API"), blended smoothly between bands.
-- VFX designer revision (UNVERIFIED in Studio): warmer bands 3-5 with orange sun glare, fire glow
-- through haze, extinguish steam burst, streak rain + ground ripples + darker clouds.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local Remotes = J:WaitForChild("Remotes")
local Sounds = J:WaitForChild("Sounds")

local atm = Lighting:WaitForChild("HazeAtmosphere") :: Atmosphere
local cc = Lighting:WaitForChild("HazeColor") :: ColorCorrectionEffect
local blur = Lighting:WaitForChild("HazeBlur") :: BlurEffect
local rays = Lighting:WaitForChild("SunRays") :: SunRaysEffect

local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"
local STREAK_TEX = "rbxasset://textures/particles/SquareParticle.png" -- solid quad, stretched into rain streaks
local RING_TEX = "rbxasset://textures/particles/explosion01_shockwave_main.dds"

---------------------------------------------------------------- band presets
-- anchor API values, one per band; visuals interpolate between neighbours
-- glare + orange decay gives the sun an orange/red halo in bands 3-5 (Sky sun can't be tinted)
local C = Color3.fromRGB
local presets = {
	{ api = 20,  density = 0.28, offset = 0.20, haze = 0.6, glare = 0.25, color = C(199, 214, 230), decay = C(110, 130, 160), tint = C(255, 255, 255), sat = 0.10, contrast = 0.05, bright = 0.00, ambient = C(140, 140, 150), light = 2.6, blur = 0,   rays = 0.07, dust = 0,  ash = 0,  vignette = 1.00, birds = 0.35, wind = 0.00 },
	{ api = 75,  density = 0.40, offset = 0.25, haze = 2.2, glare = 0.15, color = C(208, 204, 194), decay = C(160, 148, 130), tint = C(254, 248, 236), sat = -0.03, contrast = 0.03, bright = 0.00, ambient = C(150, 147, 140), light = 2.3, blur = 0,   rays = 0.04, dust = 5,  ash = 0,  vignette = 0.90, birds = 0.20, wind = 0.04 },
	{ api = 150, density = 0.55, offset = 0.30, haze = 4.8, glare = 0.45, color = C(226, 192, 150), decay = C(205, 135, 75),  tint = C(255, 228, 196), sat = -0.16, contrast = 0.00, bright = -0.02, ambient = C(170, 150, 122), light = 1.9, blur = 1,   rays = 0.02, dust = 16, ash = 0,  vignette = 0.70, birds = 0.05, wind = 0.12 },
	{ api = 250, density = 0.70, offset = 0.36, haze = 7.8, glare = 0.70, color = C(196, 140, 96),  decay = C(190, 95, 45),   tint = C(255, 210, 170), sat = -0.24, contrast = -0.03, bright = -0.04, ambient = C(160, 122, 94),  light = 1.6, blur = 2,   rays = 0.00, dust = 32, ash = 10, vignette = 0.50, birds = 0.00, wind = 0.24 },
	{ api = 360, density = 0.85, offset = 0.45, haze = 10,  glare = 0.90, color = C(172, 122, 88),  decay = C(175, 70, 35),   tint = C(248, 192, 150), sat = -0.32, contrast = -0.06, bright = -0.03, ambient = C(160, 124, 98),  light = 1.55, blur = 3, rays = 0.00, dust = 50, ash = 26, vignette = 0.32, birds = 0.00, wind = 0.38 },
}
local rainPreset = { density = 0.5, haze = 1.5, glare = 0, color = C(150, 160, 175), decay = C(90, 100, 115), tint = C(225, 232, 245), sat = -0.15, ambient = C(110, 115, 125), light = 1.4 }

local function blend(api: number)
	if api <= presets[1].api then return presets[1], presets[1], 0 end
	for i = 1, #presets - 1 do
		local a, b = presets[i], presets[i + 1]
		if api <= b.api then
			return a, b, (api - a.api) / (b.api - a.api)
		end
	end
	return presets[#presets], presets[#presets], 0
end

local function lerp(a: any, b: any, t: number): any
	if typeof(a) == "Color3" then return a:Lerp(b, t) end
	return a + (b - a) * t
end

---------------------------------------------------------------- camera-attached particles: drifting haze, ash, rain
local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalHazeFX"
fxFolder.Parent = workspace

local function volumePart(name: string, size: Vector3)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size
	p.Parent = fxFolder
	return p
end

local dustPart = volumePart("Dust", Vector3.new(120, 30, 120))
local dust = Instance.new("ParticleEmitter")
dust.Texture = SMOKE_TEX
dust.Shape = Enum.ParticleEmitterShape.Box
dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18) })
dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.82), NumberSequenceKeypoint.new(1, 1) })
dust.Lifetime = NumberRange.new(6, 9)
dust.Speed = NumberRange.new(0.5, 2)
dust.RotSpeed = NumberRange.new(-8, 8)
dust.Rotation = NumberRange.new(0, 360)
dust.LightInfluence = 1
dust.Rate = 0
dust.Parent = dustPart

local ashPart = volumePart("Ash", Vector3.new(90, 2, 90))
local ash = Instance.new("ParticleEmitter")
ash.Texture = SPARK_TEX
ash.Shape = Enum.ParticleEmitterShape.Box
ash.EmissionDirection = Enum.NormalId.Bottom
ash.Color = ColorSequence.new(C(70, 66, 62), C(120, 112, 104))
ash.Size = NumberSequence.new(0.26, 0.14)
ash.Transparency = NumberSequence.new(0.1, 0.6)
ash.Lifetime = NumberRange.new(5, 7)
ash.Speed = NumberRange.new(3, 6)
ash.SpreadAngle = Vector2.new(25, 25)
ash.RotSpeed = NumberRange.new(-120, 120)
ash.Acceleration = Vector3.new(1.5, -1, 0.5)
ash.Rate = 0
ash.Parent = ashPart

local rainPart = volumePart("Rain", Vector3.new(110, 2, 110))
local rain = Instance.new("ParticleEmitter")
rain.Texture = STREAK_TEX
rain.Shape = Enum.ParticleEmitterShape.Box
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.Color = ColorSequence.new(C(205, 220, 240))
rain.Size = NumberSequence.new(0.9)
-- positive Squash = thinner + taller; with VelocityParallel that stretches along the fall.
-- (the old -2.5 flattened the drops, which is why streaks were hard to see)
rain.Squash = NumberSequence.new(2.6)
rain.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.7) })
rain.Lifetime = NumberRange.new(0.75, 0.85)
rain.Speed = NumberRange.new(85, 95)
rain.LightInfluence = 0.4
rain.Brightness = 1.6
rain.Rate = 0
rain.Parent = rainPart

-- splash ripples on the ground around the player
local ripplePart = volumePart("Ripples", Vector3.new(50, 0.2, 50))
local ripples = Instance.new("ParticleEmitter")
ripples.Texture = RING_TEX
ripples.Shape = Enum.ParticleEmitterShape.Box
ripples.EmissionDirection = Enum.NormalId.Top
ripples.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
ripples.Color = ColorSequence.new(C(220, 232, 245))
ripples.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1.6) })
ripples.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
ripples.Lifetime = NumberRange.new(0.35, 0.5)
ripples.Speed = NumberRange.new(0.01)
ripples.LightInfluence = 0.5
ripples.Rate = 0
ripples.Parent = ripplePart

-- darker, heavier clouds while it rains (only if the place has Terrain.Clouds)
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local cloudBase = clouds and { cover = clouds.Cover, density = clouds.Density, color = clouds.Color }

---------------------------------------------------------------- extinguish steam burst (reward beat)
local steamPart = volumePart("Steam", Vector3.new(4, 1, 4))
local steam = Instance.new("ParticleEmitter")
steam.Texture = SMOKE_TEX
steam.Color = ColorSequence.new(C(250, 252, 255))
steam.LightInfluence = 0.3
steam.Brightness = 1.6
steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 14) })
steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1) })
steam.Lifetime = NumberRange.new(0.9, 1.6)
steam.Speed = NumberRange.new(14, 26)
steam.SpreadAngle = Vector2.new(28, 28)
steam.Acceleration = Vector3.new(0, 10, 0)
steam.Drag = 2.2
steam.RotSpeed = NumberRange.new(-90, 90)
steam.Rotation = NumberRange.new(0, 360)
steam.EmissionDirection = Enum.NormalId.Top
steam.Rate = 0
steam.Parent = steamPart
local puff = steam:Clone() -- low wide puff that bulges out around the base
puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8) })
puff.Speed = NumberRange.new(12, 18)
puff.SpreadAngle = Vector2.new(80, 80)
puff.Acceleration = Vector3.new(0, 3, 0)
puff.Drag = 4
puff.Lifetime = NumberRange.new(0.6, 1)
puff.Parent = steamPart

local function steamBurst(pos: Vector3)
	steamPart.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
	steam:Emit(26)
	puff:Emit(16)
end

---------------------------------------------------------------- screen vignette (edges darken / tint as haze worsens)
local gui = Instance.new("ScreenGui")
gui.Name = "HazeVignette"
gui.IgnoreGuiInset = true
gui.DisplayOrder = -5
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local vignetteFrames = {}
local function edge(rot: number, size: UDim2, pos: UDim2, anchor: Vector2)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.BackgroundColor3 = C(60, 40, 25)
	local g = Instance.new("UIGradient")
	g.Rotation = rot
	g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	g.Parent = f
	f.Parent = gui
	table.insert(vignetteFrames, f)
end
edge(90, UDim2.new(1, 0, 0.28, 0), UDim2.fromScale(0, 0), Vector2.zero)
edge(-90, UDim2.new(1, 0, 0.28, 0), UDim2.fromScale(0, 1), Vector2.new(0, 1))
edge(0, UDim2.new(0.22, 0, 1, 0), UDim2.fromScale(0, 0), Vector2.zero)
edge(180, UDim2.new(0.22, 0, 1, 0), UDim2.fromScale(1, 0), Vector2.new(1, 0))

local coughFlash = Instance.new("Frame")
coughFlash.Size = UDim2.fromScale(1, 1)
coughFlash.BackgroundColor3 = C(40, 25, 15)
coughFlash.BackgroundTransparency = 1
coughFlash.BorderSizePixel = 0
coughFlash.Parent = gui

---------------------------------------------------------------- ambient audio
local ambient = Instance.new("SoundGroup")
ambient.Name = "Ambient"
ambient.Parent = SoundService

local function loop(name: string): Sound
	local s = Sounds[name]:Clone()
	s.SoundGroup = ambient
	s.Volume = 0
	s.Parent = SoundService
	s:Play()
	return s
end
local birds = loop("Birds")
local wind = loop("HazeWind")
local rainSound = loop("Rain")

local function play2D(name: string, volume: number?, pitch: number?)
	local tmpl = Sounds:FindFirstChild(name)
	if not tmpl then return end
	local s = tmpl:Clone()
	if volume then s.Volume = volume end
	if pitch then s.PlaybackSpeed = pitch end
	s.Looped = false
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	task.delay(12, function() if s.Parent then s:Destroy() end end)
end

-- some library clips are long takes; play just the opening and fade out
local clipLength = { Sizzle = 1.6, Ignite = 2.4 }

local function play3D(name: string, pos: Vector3, volume: number?, maxDist: number?)
	local tmpl = Sounds:FindFirstChild(name)
	if not tmpl then return end
	local a = Instance.new("Attachment")
	a.WorldPosition = pos
	a.Parent = workspace.Terrain
	local s = tmpl:Clone()
	s.Looped = false
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = maxDist or 140
	if volume then s.Volume = volume end
	s.Parent = a
	s:Play()
	local len = clipLength[name] or 8
	task.delay(len, function()
		TweenService:Create(s, TweenInfo.new(0.5), { Volume = 0 }):Play()
		task.wait(0.55)
		a:Destroy()
	end)
end

Remotes.Sfx.OnClientEvent:Connect(function(name: string, pos: Vector3?, _amount: number?)
	if name == "Coin" then
		play2D("Coin", 0.45, 1 + math.random() * 0.1)
	elseif name == "Plane" then
		play2D("Plane", 0.7)
	elseif name == "Alarm" then
		local s = Sounds.Alarm:Clone()
		s.Parent = SoundService
		s:Play()
		task.delay(2.2, function()
			TweenService:Create(s, TweenInfo.new(0.6), { Volume = 0 }):Play()
			task.wait(0.7)
			s:Destroy()
		end)
	elseif pos then
		-- server fires "Sizzle" at the fire position on every extinguish
		if name == "Sizzle" then steamBurst(pos) end
		play3D(name, pos, name == "Sizzle" and 0.7 or 0.55, name == "Ignite" and 160 or 120)
	else
		play2D(name)
	end
end)

---------------------------------------------------------------- fire markers (visibility shrinks as haze thickens)
local markerRange = 420
local markers: { [BasePart]: BillboardGui } = {}

local function addMarker(fire: Instance)
	if not fire:IsA("BasePart") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Marker"
	bb.Size = UDim2.fromOffset(46, 58)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = markerRange
	bb.Adornee = fire
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(40, 40)
	icon.Position = UDim2.fromOffset(3, 0)
	icon.BackgroundColor3 = fire:GetAttribute("Peat") and C(120, 70, 40) or C(230, 70, 30)
	icon.Text = "🔥"
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = icon
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = icon
	icon.Parent = bb
	local dist = Instance.new("TextLabel")
	dist.Name = "Dist"
	dist.Size = UDim2.fromOffset(46, 16)
	dist.Position = UDim2.fromOffset(0, 42)
	dist.BackgroundTransparency = 1
	dist.TextColor3 = Color3.new(1, 1, 1)
	dist.TextStrokeTransparency = 0.4
	dist.Font = Enum.Font.GothamBold
	dist.TextSize = 13
	dist.Text = ""
	dist.Parent = bb
	bb.Parent = player.PlayerGui
	markers[fire] = bb
	fire.Destroying:Once(function()
		bb:Destroy()
		markers[fire] = nil
	end)
end

-- distant fire glow: billboards ignore Atmosphere fog, so a soft orange bloom reads through
-- thick haze. Occluded by terrain/buildings (not AlwaysOnTop), hidden up close.
local glows: { [BasePart]: BillboardGui } = {}
local function addGlow(fire: Instance)
	if not fire:IsA("BasePart") then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "FireGlow"
	bb.Size = UDim2.fromScale(16, 16)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	bb.LightInfluence = 0
	bb.Brightness = 1.4
	bb.AlwaysOnTop = false
	bb.MaxDistance = 700
	bb.Adornee = fire
	for i, step in { { 1, 0.86 }, { 0.62, 0.78 }, { 0.32, 0.68 } } do
		local f = Instance.new("Frame")
		f.Name = "Ring" .. i
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(step[1], step[1])
		f.BorderSizePixel = 0
		f.BackgroundColor3 = i == 3 and C(255, 200, 110) or C(255, 120, 40)
		f.BackgroundTransparency = 1
		f:SetAttribute("Base", step[2])
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = f
		f.Parent = bb
	end
	bb.Parent = player.PlayerGui
	glows[fire] = bb
	fire.Destroying:Once(function()
		bb:Destroy()
		glows[fire] = nil
	end)
end

local function updateGlows(cpos: Vector3, hazeK: number)
	for fire, bb in glows do
		local k = (fire:GetAttribute("Intensity") or 0) / 100
		local smoulder = fire:GetAttribute("Smoulder") == true
		local d = (fire.Position - cpos).Magnitude
		local near = math.clamp((d - 35) / 60, 0, 1)
		local vis = near * (0.35 + 0.65 * hazeK) * (smoulder and 0.35 or (0.4 + 0.6 * k))
		local sz = smoulder and 8 or (10 + 14 * k)
		bb.Size = UDim2.fromScale(sz, sz)
		bb.Enabled = vis > 0.02
		if bb.Enabled then
			for _, f in bb:GetChildren() do
				local base = f:GetAttribute("Base")
				if base then f.BackgroundTransparency = 1 - (1 - base) * vis end
			end
		end
	end
end

local firesFolder = workspace:WaitForChild("Fires")
local function onFire(f: Instance)
	addMarker(f)
	addGlow(f)
end
for _, f in firesFolder:GetChildren() do onFire(f) end
firesFolder.ChildAdded:Connect(onFire)

---------------------------------------------------------------- spray visuals for every player's hose
local splashes: { [Tool]: { part: BasePart, emitter: ParticleEmitter, beam: Beam, target: Attachment } } = {}
local spraySounds: { [Tool]: Sound } = {}

local function splashFor(tool: Tool)
	local s = splashes[tool]
	if s then return s end
	local p = volumePart("Splash", Vector3.new(2, 1, 2))
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE_TEX
	e.Color = ColorSequence.new(C(235, 245, 255))
	e.LightInfluence = 0.5
	e.Brightness = 1.3
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 6) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.8, 1.3)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(70, 70)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = p
	-- solid stream: a curved beam from the nozzle to the splash point
	local target = Instance.new("Attachment")
	target.Parent = p
	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(C(225, 242, 255), C(150, 205, 255))
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 0.7) })
	beam.LightEmission = 0.35
	beam.LightInfluence = 0.5
	beam.Width0 = 0.35
	beam.Width1 = 1.8
	beam.Segments = 16
	beam.FaceCamera = true
	beam.Attachment1 = target
	beam.Enabled = false
	beam.Parent = p
	s = { part = p, emitter = e, beam = beam, target = target }
	splashes[tool] = s
	tool.Destroying:Once(function()
		p:Destroy()
		splashes[tool] = nil
	end)
	return s
end

local function updateSprays()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local tool = char and char:FindFirstChild("Hose")
		if tool and tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle")
			local att = handle and handle:FindFirstChild("Nozzle") :: Attachment?
			if att then
				local on = tool:GetAttribute("Spraying") == true
				local aim = tool:GetAttribute("Aim") :: Vector3?
				local jet = att:FindFirstChild("Jet") :: ParticleEmitter
				local drops = att:FindFirstChild("Drops") :: ParticleEmitter
				local sp = splashFor(tool)
				if on and aim then
					local from = att.WorldPosition
					local dist = (aim - from).Magnitude
					-- lob the stream a little so gravity lands it on target
					local lift = Vector3.new(0, math.clamp(dist * 0.22, 0, 14), 0)
					att.WorldCFrame = CFrame.lookAt(from, aim + lift)
					local speed = math.clamp(dist * 1.45, 28, 95)
					jet.Speed = NumberRange.new(speed * 0.95, speed * 1.05)
					drops.Speed = NumberRange.new(speed * 0.9, speed)
					jet.Enabled = true
					drops.Enabled = true
					sp.part.Position = aim
					sp.emitter.Rate = 30
					sp.beam.Attachment0 = att
					sp.beam.CurveSize0 = math.clamp(dist * 0.25, 0, 10)
					sp.beam.CurveSize1 = 0
					sp.beam.Width0 = 0.3 + 0.05 * math.sin(os.clock() * 30)
					sp.beam.Enabled = true
				else
					jet.Enabled = false
					drops.Enabled = false
					sp.emitter.Rate = 0
					sp.beam.Enabled = false
				end
				-- hose sound
				local snd = spraySounds[tool]
				if not snd then
					snd = Sounds.Spray:Clone()
					snd.RollOffMaxDistance = 80
					snd.Volume = 0
					snd.Parent = handle
					snd:Play()
					spraySounds[tool] = snd
					tool.Destroying:Once(function() spraySounds[tool] = nil end)
				end
				local target = on and 0.45 or 0
				snd.Volume += (target - snd.Volume) * 0.35
			end
		end
	end
end

---------------------------------------------------------------- refill sound
local refillSound = Sounds.Refill:Clone()
refillSound.Volume = 0
refillSound.Parent = SoundService
refillSound:Play()

---------------------------------------------------------------- coughing (unmasked, API > 100)
local nextCough = os.clock() + 8
local function maybeCough(band: number)
	if band < 3 or player:GetAttribute("Mask") then return end
	if os.clock() < nextCough then return end
	local gap = band >= 5 and math.random(4, 7) or (band == 4 and math.random(6, 10) or math.random(10, 16))
	nextCough = os.clock() + gap
	play2D(math.random() < 0.5 and "Cough1" or "Cough2", 0.55)
	coughFlash.BackgroundTransparency = band >= 5 and 0.55 or 0.75
	TweenService:Create(coughFlash, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
	-- small camera shake
	task.spawn(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		for i = 1, 8 do
			hum.CameraOffset = Vector3.new(math.random(-10, 10) / 60, math.random(-10, 10) / 60, 0)
			task.wait(0.03)
		end
		hum.CameraOffset = Vector3.zero
	end)
end

---------------------------------------------------------------- main blend loop
local shownAPI = workspace:GetAttribute("API") or Config.StartAPI
local rainMix = 0

RunService.RenderStepped:Connect(function(dt)
	local target = workspace:GetAttribute("API") or Config.StartAPI
	-- ease toward the real value so changes roll in like weather
	shownAPI += (target - shownAPI) * math.min(1, dt * 0.8)
	local raining = workspace:GetAttribute("Raining") == true
	rainMix += ((raining and 1 or 0) - rainMix) * math.min(1, dt * 0.6)

	local a, b, t = blend(shownAPI)
	local function v(key: string) return lerp(a[key], b[key], t) end

	atm.Density = lerp(v("density"), rainPreset.density, rainMix)
	atm.Offset = v("offset")
	atm.Haze = lerp(v("haze"), rainPreset.haze, rainMix)
	atm.Glare = lerp(v("glare"), rainPreset.glare, rainMix)
	atm.Color = lerp(v("color"), rainPreset.color, rainMix)
	atm.Decay = lerp(v("decay"), rainPreset.decay, rainMix)
	cc.TintColor = lerp(v("tint"), rainPreset.tint, rainMix)
	cc.Saturation = lerp(v("sat"), rainPreset.sat, rainMix)
	cc.Contrast = v("contrast")
	cc.Brightness = v("bright")
	Lighting.OutdoorAmbient = lerp(v("ambient"), rainPreset.ambient, rainMix)
	Lighting.Brightness = lerp(v("light"), rainPreset.light, rainMix)
	blur.Size = v("blur") * (1 - rainMix * 0.5)
	rays.Intensity = v("rays") * (1 - rainMix)

	if clouds and cloudBase then
		clouds.Cover = lerp(cloudBase.cover, math.max(cloudBase.cover, 0.85), rainMix)
		clouds.Density = lerp(cloudBase.density, math.max(cloudBase.density, 0.75), rainMix)
		clouds.Color = cloudBase.color:Lerp(C(110, 115, 125), rainMix)
	end

	local cam = workspace.CurrentCamera
	local cpos = cam.CFrame.Position
	dustPart.CFrame = CFrame.new(cpos + cam.CFrame.LookVector * 30)
	ashPart.CFrame = CFrame.new(cpos + Vector3.new(0, 30, 0))
	rainPart.CFrame = CFrame.new(cpos + Vector3.new(0, 60, 0) + cam.CFrame.LookVector * 20)
	dust.Rate = v("dust") * (1 - rainMix)
	dust.Color = ColorSequence.new(atm.Color)
	ash.Rate = v("ash") * (1 - rainMix)
	rain.Rate = 700 * rainMix

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and rainMix > 0.05 then
		ripplePart.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.8, 0))
		ripples.Rate = 70 * rainMix
	else
		ripples.Rate = 0
	end

	local vig = v("vignette")
	local vigColor = atm.Decay:Lerp(Color3.new(0, 0, 0), 0.35)
	for _, f in vignetteFrames do
		f.BackgroundTransparency = vig
		f.BackgroundColor3 = vigColor
	end

	birds.Volume = v("birds") * (1 - rainMix)
	wind.Volume = v("wind") * (1 - rainMix * 0.7)
	rainSound.Volume = 0.8 * rainMix

	-- marker visibility follows the band
	local band = Config.BandIndex(shownAPI)
	local bandCfg = Config.Bands[band]
	markerRange += (bandCfg.markerRange - markerRange) * math.min(1, dt)
	for fire, bb in markers do
		bb.MaxDistance = markerRange
		if root then
			bb.Dist.Text = ("%dm"):format((fire.Position - root.Position).Magnitude // 1)
		end
		local smoulder = fire:GetAttribute("Smoulder") == true
		bb.Icon.Text = smoulder and "♨️" or "🔥"
		bb.Icon.BackgroundColor3 = smoulder and C(110, 90, 80) or (fire:GetAttribute("Peat") and C(150, 80, 40) or C(230, 70, 30))
	end
	updateGlows(cpos, math.clamp((shownAPI - 50) / 300, 0, 1))

	updateSprays()

	local refilling = player:GetAttribute("Refilling") == true
	refillSound.Volume += ((refilling and 0.4 or 0) - refillSound.Volume) * math.min(1, dt * 6)

	if workspace:GetAttribute("Phase") == "Day" then
		maybeCough(band)
	end
end)
