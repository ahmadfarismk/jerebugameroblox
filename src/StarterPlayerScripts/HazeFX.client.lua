-- Jerebu client visuals + audio
-- Haze look is driven by the shared API meter (workspace attribute "API"), blended smoothly between bands.
-- VFX designer revision: warmer bands 3-5 with orange sun glare, fire glow through haze,
-- extinguish steam burst, streak rain + ground ripples + darker clouds.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local Assets = require(J:WaitForChild("ImageAssets"))
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

-- smaller volume close to the camera: same particle budget, far denser where the player looks
local rainPart = volumePart("Rain", Vector3.new(64, 2, 64))
local rain = Instance.new("ParticleEmitter")
rain.Texture = STREAK_TEX
rain.Shape = Enum.ParticleEmitterShape.Box
rain.EmissionDirection = Enum.NormalId.Bottom
rain.Orientation = Enum.ParticleOrientation.VelocityParallel
rain.Color = ColorSequence.new(C(215, 228, 245))
-- with VelocityParallel the particle's long axis follows the fall only for NEGATIVE Squash
-- (positive gave flat horizontal bars in testing). Size 0.75 / Squash -2.8 = thin, long streaks.
rain.Size = NumberSequence.new(0.75)
rain.Squash = NumberSequence.new(-2.8)
rain.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(0.85, 0.45), NumberSequenceKeypoint.new(1, 0.85) })
rain.Lifetime = NumberRange.new(0.85, 0.95)
rain.Speed = NumberRange.new(58, 66)
rain.LightInfluence = 0
rain.Brightness = 1.3
rain.Rate = 0
rain.Parent = rainPart

-- splash ripples on the ground around the player
local ripplePart = volumePart("Ripples", Vector3.new(36, 0.2, 36))
local ripples = Instance.new("ParticleEmitter")
ripples.Texture = RING_TEX
ripples.Shape = Enum.ParticleEmitterShape.Box
ripples.EmissionDirection = Enum.NormalId.Top
ripples.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
ripples.Color = ColorSequence.new(C(220, 232, 245))
ripples.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 2.2) })
ripples.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
ripples.Lifetime = NumberRange.new(0.4, 0.6)
ripples.Speed = NumberRange.new(0.01)
ripples.LightInfluence = 0
ripples.Brightness = 1.4
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
-- HazeFX-side floor on Config's band ranges: band 5 at 70 studs left players walking blind,
-- 95 still shrinks clearly from band 4 (120) but lets you find the next fire
local MARKER_FLOOR = 95
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
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(40, 40)
	icon.Position = UDim2.fromOffset(3, 0)
	icon.BackgroundColor3 = fire:GetAttribute("Peat") and C(120, 70, 40) or C(230, 70, 30)
	icon.Image = Assets.Fire
	icon.ScaleType = Enum.ScaleType.Fit
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
	bb.ResetOnSpawn = false -- survive respawns; the per-frame loop holds references to these
	bb.Parent = player.PlayerGui
	markers[fire] = bb
	fire.Destroying:Once(function()
		bb:Destroy()
		markers[fire] = nil
	end)
end

-- distant fire glow: billboards ignore Atmosphere fog, so a soft orange bloom reads through
-- thick haze. Sits at canopy height and AlwaysOnTop so trunks/hills don't hide it; hidden up close.
-- Soft radial look = 8 stacked low-alpha discs (UIGradient is linear-only), colour warming to the core.
local GLOW_STEPS = 8
local glows: { [BasePart]: BillboardGui } = {}
local function addGlow(fire: Instance)
	if not fire:IsA("BasePart") then return end
	local crown = fire:FindFirstChild("Crown") :: Attachment?
	local top = crown and (crown.Position.Y + 4) or 9
	local bb = Instance.new("BillboardGui")
	bb.Name = "FireGlow"
	bb.Size = UDim2.fromScale(16, 16)
	bb.StudsOffsetWorldSpace = Vector3.new(0, math.clamp(top, 9, 40), 0)
	bb.LightInfluence = 0
	bb.Brightness = 1.6
	bb.AlwaysOnTop = true
	bb.MaxDistance = 700
	bb.Adornee = fire
	for i = 1, GLOW_STEPS do
		local r = 1 - (i - 1) / GLOW_STEPS -- 1 .. 0.125
		local f = Instance.new("Frame")
		f.Name = "Ring" .. i
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(r, r)
		f.BorderSizePixel = 0
		f.BackgroundColor3 = C(255, 95, 25):Lerp(C(255, 215, 130), (i - 1) / (GLOW_STEPS - 1))
		f.BackgroundTransparency = 1
		-- per-disc alpha; stacked they build a smooth falloff (~0.75 opaque at the core at full strength)
		f:SetAttribute("Base", 0.84)
		f.ZIndex = i
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = f
		f.Parent = bb
	end
	bb.ResetOnSpawn = false
	bb.Parent = player.PlayerGui
	glows[fire] = bb
	fire.Destroying:Once(function()
		bb:Destroy()
		glows[fire] = nil
	end)
end

local function updateGlows(cpos: Vector3, hazeK: number, range: number)
	-- glow reaches well past the marker range (a hint of "something burning over there"),
	-- but still shrinks with the haze band
	local far = range * 2 + 120
	for fire, bb in glows do
		local k = (fire:GetAttribute("Intensity") or 0) / 100
		local smoulder = fire:GetAttribute("Smoulder") == true
		local d = (fire.Position - cpos).Magnitude
		local near = math.clamp((d - 30) / 40, 0, 1)
		local fade = math.clamp((far - d) / 80, 0, 1)
		local vis = near * fade * (0.45 + 0.55 * hazeK) * (smoulder and 0.45 or (0.55 + 0.45 * k))
		-- billboard size is in studs, so grow it a little with distance to stay readable on screen
		local grow = 1 + math.clamp((d - 80) / 300, 0, 0.8)
		local sz = (smoulder and 10 or (14 + 14 * k)) * grow
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
-- Look is picked from the Hose tool's "Tier" attribute (1-6). Contract with the tier models:
-- Handle -> Nozzle attachment (-> Jet + Drops emitters, optional). Everything extra (beams, foam, glow,
-- storm) lives in one anchored part per tool under LocalHazeFX, so any model works.
local splashes: { [Tool]: any } = {}
local spraySounds: { [Tool]: Sound } = {}
local toolBase: { [Tool]: { tier: number, jetSize: NumberSequence?, dropsRate: number? } } = {}

local function cs(a: Color3, b: Color3?): ColorSequence
	return ColorSequence.new(a, b or a)
end

local function scaleSeq(s: NumberSequence, k: number): NumberSequence
	local kp = {}
	for _, p in s.Keypoints do
		table.insert(kp, NumberSequenceKeypoint.new(p.Time, p.Value * k, p.Envelope * k))
	end
	return NumberSequence.new(kp)
end

-- per-tier look. Missing keys fall back to the tier 1 stream.
-- beam/jet/drops colours, beamAlpha = base transparency, *Emission = LightEmission, jetSize = particle size multiplier
local HOSE_STYLE: { [number]: any } = {
	[1] = {},
	[2] = { -- brass jet: brighter, brassy white
		beam = cs(C(255, 253, 240), C(255, 232, 170)), beamAlpha = 0.05, beamEmission = 0.7, w0 = 0.4, w1 = 2.0,
		jet = cs(C(255, 252, 235), C(255, 226, 160)), jetEmission = 0.55, jetSize = 1.1,
		drops = cs(C(255, 240, 190), C(255, 215, 130)), splash = C(255, 248, 230),
	},
	[3] = { -- twin jet: two beams side by side, chrome-blue
		twin = true,
		beam = cs(C(240, 250, 255), C(160, 210, 255)), beamAlpha = 0.1, beamEmission = 0.5, w0 = 0.3, w1 = 1.5,
		jet = cs(C(235, 248, 255), C(160, 210, 255)), jetEmission = 0.4, jetSize = 0.6,
		drops = cs(C(210, 235, 255)), splash = C(235, 247, 255),
	},
	[4] = { -- foam cannon: thick white foam + lingering foam on the ground
		foam = true,
		beam = cs(C(255, 255, 255), C(232, 242, 252)), beamAlpha = 0, beamEmission = 0.2, w0 = 0.8, w1 = 3.4,
		jet = cs(C(255, 255, 255), C(236, 244, 252)), jetEmission = 0.15, jetSize = 1.9,
		drops = cs(C(255, 255, 255)), splash = C(255, 255, 255), splashMul = 1.35,
	},
	[5] = { -- hydro pack: strong glowing blue
		glow = true,
		beam = cs(C(60, 150, 255), C(150, 225, 255)), beamAlpha = 0.05, beamEmission = 1, w0 = 0.55, w1 = 2.4,
		jet = cs(C(70, 160, 255), C(150, 225, 255)), jetEmission = 1, jetSize = 1.3,
		drops = cs(C(130, 210, 255)), splash = C(150, 215, 255), light = { C(70, 150, 255), 1.8, 14 },
	},
	[6] = { -- storm cannon (legendary): cyan glow, sparkles, small storm swirl at the splash
		glow = true, sparkles = true, storm = true,
		beam = cs(C(110, 255, 248), C(235, 255, 255)), beamAlpha = 0, beamEmission = 1, w0 = 0.6, w1 = 2.6,
		jet = cs(C(100, 255, 245), C(225, 255, 255)), jetEmission = 1, jetSize = 1.4,
		drops = cs(C(255, 255, 255), C(120, 255, 245)), dropsRate = 100, splash = C(170, 250, 250),
		light = { C(90, 255, 245), 2.4, 18 },
	},
}

local function emitterOn(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	for k, v in props do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function buildSplash(tool: Tool, tier: number)
	local st = HOSE_STYLE[tier] or HOSE_STYLE[1]
	local hose = Config.Hoses[tier]
	-- the server's spray radius is BaseSprayRadius + hose.radius: scale the visuals by the same ratio
	local scale = (Config.BaseSprayRadius + (hose and hose.radius or 0)) / Config.BaseSprayRadius
	local mul = scale * (st.splashMul or 1)
	local p = volumePart("Splash", Vector3.new(2 * scale, 1, 2 * scale))
	local extras = {}
	local sp: any = { tier = tier, part = p, scale = scale, style = st, beams = {}, src = {}, dst = {}, extras = extras, nextFlash = 0 }

	sp.emitter = emitterOn(p, {
		Texture = SMOKE_TEX,
		Color = cs(st.splash or C(235, 245, 255)),
		LightInfluence = st.glow and 0 or 0.5,
		LightEmission = st.glow and 0.6 or 0,
		Brightness = 1.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5 * mul), NumberSequenceKeypoint.new(1, 6 * mul) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(70, 70),
		EmissionDirection = Enum.NormalId.Top,
	})
	sp.rate = 30

	-- solid stream(s): curved beam(s) from the nozzle to the splash point. Beam curves bow along the
	-- attachment's +X axis, so the attachments are oriented with X pointing up (see updateSprays).
	local base = st.beamAlpha or 0.15
	for i = 1, st.twin and 2 or 1 do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent = p
		a1.Parent = p
		local b = Instance.new("Beam")
		b.Color = st.beam or cs(C(225, 242, 255), C(150, 205, 255))
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, base), NumberSequenceKeypoint.new(0.8, base + 0.2), NumberSequenceKeypoint.new(1, 0.7) })
		b.LightEmission = st.beamEmission or 0.35
		b.LightInfluence = st.glow and 0 or 0.5
		b.Width0 = st.w0 or 0.35
		b.Width1 = st.w1 or 1.8
		b.Segments = 16
		b.FaceCamera = true
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Enabled = false
		b.Parent = p
		table.insert(sp.beams, b)
		table.insert(sp.src, a0)
		table.insert(sp.dst, a1)
	end

	if tier >= 3 then -- flat mist ring marks the wider area the spray covers
		local R = (Config.BaseSprayRadius + (hose and hose.radius or 0)) * 0.7
		table.insert(extras, { rate = 4, e = emitterOn(p, {
			Texture = RING_TEX,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			EmissionDirection = Enum.NormalId.Top,
			Color = cs(st.splash or C(235, 245, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, R * 0.3), NumberSequenceKeypoint.new(1, R) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.55, 0.7),
			Speed = NumberRange.new(0.01),
			LightInfluence = 0,
			LightEmission = st.glow and 0.8 or 0.2,
		}) })
	end

	if st.foam then -- foam splash: fat white blobs that linger and settle
		table.insert(extras, { rate = 16, e = emitterOn(p, {
			Texture = SMOKE_TEX,
			Color = cs(C(255, 255, 255), C(228, 238, 248)),
			LightInfluence = 0.6,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2 * scale), NumberSequenceKeypoint.new(0.4, 4 * scale), NumberSequenceKeypoint.new(1, 5 * scale) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.35), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.8, 2.6),
			Speed = NumberRange.new(1, 4),
			SpreadAngle = Vector2.new(180, 180),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -1.5, 0),
			Drag = 2,
			RotSpeed = NumberRange.new(-40, 40),
			Rotation = NumberRange.new(0, 360),
		}) })
	end

	if st.sparkles then
		local spark = emitterOn(p, {
			Texture = SPARK_TEX,
			Color = cs(C(255, 255, 255), C(110, 255, 245)),
			LightEmission = 1,
			LightInfluence = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(8, 16),
			SpreadAngle = Vector2.new(60, 60),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -22, 0),
		})
		table.insert(extras, { rate = 22, e = spark })
		sp.flash = spark
	end

	if st.storm then -- small storm swirl: a spinning emitter lays a circular trail of tiny dark clouds
		local sPart = Instance.new("Part")
		sPart.Name = "Storm"
		sPart.Anchored = true
		sPart.CanCollide = false
		sPart.CanQuery = false
		sPart.CanTouch = false
		sPart.Transparency = 1
		sPart.Size = Vector3.new(0.5, 0.5, 0.5)
		sPart.Parent = p
		local orbit = Instance.new("Attachment")
		orbit.Position = Vector3.new(2.4, 0, 0)
		orbit.Parent = sPart
		table.insert(extras, { rate = 26, e = emitterOn(orbit, {
			Texture = SMOKE_TEX,
			Color = cs(C(175, 200, 225), C(60, 75, 100)),
			LightInfluence = 0.3,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 2.4) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(0.6, 0.85),
			Speed = NumberRange.new(0.3, 0.8),
			RotSpeed = NumberRange.new(-60, 60),
			Rotation = NumberRange.new(0, 360),
			EmissionDirection = Enum.NormalId.Top,
		}) })
		sp.storm = sPart
	end

	if st.light then
		local l = Instance.new("PointLight")
		l.Color = st.light[1]
		l.Brightness = st.light[2]
		l.Range = st.light[3]
		l.Shadows = false
		l.Enabled = false
		l.Parent = p
		sp.light = l
	end
	return sp
end

local function splashFor(tool: Tool, tier: number)
	local s = splashes[tool]
	if s and s.tier == tier then return s end
	local first = s == nil
	if s then s.part:Destroy() end
	s = buildSplash(tool, tier)
	splashes[tool] = s
	if first then -- first sighting: hook cleanup once
		tool.Destroying:Once(function()
			local cur = splashes[tool]
			if cur then cur.part:Destroy() end
			splashes[tool] = nil
			toolBase[tool] = nil
		end)
	end
	return s
end

-- restyle the tool's own Jet/Drops emitters for the tier (originals remembered so it never compounds)
local function styleTool(tool: Tool, tier: number, jet: ParticleEmitter?, drops: ParticleEmitter?)
	local b = toolBase[tool]
	if not b then
		b = { tier = 0, jetSize = jet and jet.Size, dropsRate = drops and drops.Rate }
		toolBase[tool] = b
	end
	if b.tier == tier then return end
	b.tier = tier
	local st = HOSE_STYLE[tier] or HOSE_STYLE[1]
	if jet and b.jetSize then
		if st.jet then jet.Color = st.jet end
		if st.jetEmission then jet.LightEmission = st.jetEmission end
		jet.LightInfluence = st.glow and 0 or jet.LightInfluence
		jet.Size = scaleSeq(b.jetSize, st.jetSize or 1)
	end
	if drops and b.dropsRate then
		if st.drops then drops.Color = st.drops end
		drops.LightEmission = st.glow and 1 or drops.LightEmission
		drops.Rate = st.dropsRate or b.dropsRate
	end
end

local function updateSprays()
	local cpos = workspace.CurrentCamera.CFrame.Position
	local clock = os.clock()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local tool = char and char:FindFirstChild("Hose")
		if tool and tool:IsA("Tool") then
			local handle = tool:FindFirstChild("Handle")
			local att = handle and handle:FindFirstChild("Nozzle") :: Attachment?
			if att then
				local tier = math.clamp(math.floor(tonumber(tool:GetAttribute("Tier")) or 1), 1, 6)
				local on = tool:GetAttribute("Spraying") == true
				local aim = tool:GetAttribute("Aim") :: Vector3?
				local jet = att:FindFirstChild("Jet") :: ParticleEmitter?
				local drops = att:FindFirstChild("Drops") :: ParticleEmitter?
				styleTool(tool, tier, jet, drops)
				local sp = splashFor(tool, tier)
				local from = att.WorldPosition
				if on and aim and (aim - from).Magnitude > 0.5 then
					local delta = aim - from
					local dist = delta.Magnitude
					local f = delta / dist
					-- lob the stream a little so gravity lands it on target
					local lift = Vector3.new(0, math.clamp(dist * 0.22, 0, 14), 0)
					att.WorldCFrame = CFrame.lookAt(from, aim + lift)
					local speed = math.clamp(dist * 1.45, 28, 95)
					if jet then
						jet.Speed = NumberRange.new(speed * 0.95, speed * 1.05)
						jet.Enabled = true
					end
					if drops then
						drops.Speed = NumberRange.new(speed * 0.9, speed)
						drops.Enabled = true
					end
					sp.part.Position = aim
					sp.emitter.Rate = sp.rate
					-- beam attachments: X axis up (beam curves bow that way), Y along the stream
					local upX = Vector3.yAxis - f * f.Y
					upX = upX.Magnitude > 0.05 and upX.Unit or Vector3.xAxis
					local side = f:Cross(Vector3.yAxis)
					side = side.Magnitude > 0.05 and side.Unit or Vector3.zAxis
					local arc = math.clamp(dist * 0.12, 0, 5)
					local twinGap = 0.5 * sp.scale
					for i, beam in sp.beams do
						local o = sp.style.twin and (i == 1 and -1 or 1) or 0
						sp.src[i].WorldCFrame = CFrame.fromMatrix(from + side * o * 0.45, upX, f)
						sp.dst[i].WorldCFrame = CFrame.fromMatrix(aim + side * o * twinGap, upX, f)
						beam.CurveSize0 = arc
						beam.CurveSize1 = -arc * 0.5
						beam.Width0 = (sp.style.w0 or 0.35) + 0.05 * math.sin(clock * 30 + i)
						beam.Enabled = true
					end
					-- extras (foam, ring, sparkles, storm) are skipped for far-away sprayers to save particles
					local near = (aim - cpos).Magnitude < 140
					for _, x in sp.extras do x.e.Rate = near and x.rate or 0 end
					if sp.storm then
						sp.storm.CFrame = CFrame.new(aim + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, clock * 10, 0)
					end
					if sp.light then
						sp.light.Enabled = near
					end
					if sp.flash and near and clock > sp.nextFlash then
						-- little lightning flicker inside the swirl
						sp.nextFlash = clock + 0.5 + math.random() * 0.8
						sp.flash:Emit(6)
					end
				else
					if jet then jet.Enabled = false end
					if drops then drops.Enabled = false end
					sp.emitter.Rate = 0
					for _, beam in sp.beams do beam.Enabled = false end
					for _, x in sp.extras do x.e.Rate = 0 end
					if sp.light then sp.light.Enabled = false end
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
	-- partial protection (cloth/surgical mask, Strong Lungs) skips some coughs
	if os.clock() >= nextCough and math.random() < (player:GetAttribute("HazeResist") or 0) then
		nextCough = os.clock() + math.random(6, 10)
		return
	end
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
local rippleParams = RaycastParams.new()
rippleParams.FilterType = Enum.RaycastFilterType.Exclude
rippleParams.IgnoreWater = false
local rainMix = 0
local nightMix = 0

RunService.RenderStepped:Connect(function(dt)
	local target = workspace:GetAttribute("API") or Config.StartAPI
	-- ease toward the real value so changes roll in like weather
	shownAPI += (target - shownAPI) * math.min(1, dt * 0.8)
	local raining = workspace:GetAttribute("Raining") == true
	rainMix += ((raining and 1 or 0) - rainMix) * math.min(1, dt * 0.6)
	local isNight = workspace:GetAttribute("Mode") == "Survival" and workspace:GetAttribute("Phase") == "Night"
	nightMix += ((isNight and 1 or 0) - nightMix) * math.min(1, dt * 0.8)

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
	-- Preserve each API band's hue while gently darkening survival nights.
	atm.Color = atm.Color:Lerp(atm.Color:Lerp(Color3.new(0, 0, 0), 0.35), nightMix)
	Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(C(45, 50, 70), nightMix * 0.5)
	Lighting.Brightness *= 1 - nightMix * 0.35
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
	local look = cam.CFrame.LookVector
	rainPart.CFrame = CFrame.new(cpos + Vector3.new(0, 42, 0) + Vector3.new(look.X, 0, look.Z) * 16)
	dust.Rate = v("dust") * (1 - rainMix)
	dust.Color = ColorSequence.new(atm.Color)
	ash.Rate = v("ash") * (1 - rainMix)
	rain.Rate = 600 * rainMix

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local groundHit = nil
	if root and rainMix > 0.05 then
		rippleParams.FilterDescendantsInstances = { player.Character, fxFolder, firesFolder }
		groundHit = workspace:Raycast(root.Position, Vector3.new(0, -40, 0), rippleParams)
	end
	if groundHit then
		-- sit the ripple sheet on whatever is under the player (terrain, road, roof)
		-- terrain grass blades hide a sheet lying on the ground, so lift it a bit there
		local grassy = groundHit.Material == Enum.Material.Grass or groundHit.Material == Enum.Material.LeafyGrass
		ripplePart.CFrame = CFrame.new(groundHit.Position + Vector3.new(0, grassy and 0.6 or 0.12, 0))
		ripples.Rate = 90 * rainMix
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
	markerRange += (math.max(bandCfg.markerRange, MARKER_FLOOR) - markerRange) * math.min(1, dt)
	for fire, bb in markers do
		bb.MaxDistance = markerRange
		if root then
			bb.Dist.Text = ("%dm"):format((fire.Position - root.Position).Magnitude // 1)
		end
		local smoulder = fire:GetAttribute("Smoulder") == true
		bb.Icon.Image = (smoulder or fire:GetAttribute("Peat")) and Assets.Peat or Assets.Fire
		bb.Icon.BackgroundColor3 = smoulder and C(110, 90, 80) or (fire:GetAttribute("Peat") and C(150, 80, 40) or C(230, 70, 30))
	end
	updateGlows(cpos, math.clamp((shownAPI - 50) / 300, 0, 1), markerRange)

	updateSprays()

	local refilling = player:GetAttribute("Refilling") == true
	refillSound.Volume += ((refilling and 0.4 or 0) - refillSound.Volume) * math.min(1, dt * 6)

	if workspace:GetAttribute("Phase") == "Day" then
		maybeCough(band)
	end
end)
