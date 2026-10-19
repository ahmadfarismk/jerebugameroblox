-- Jerebu round 3 client visuals for the progression system:
--   ride sit pose, truck roof cannon, Godspeed trail, Server Boost aura, Infinite Tank gauge shimmer.
-- Everything is client-side and read from replicated attributes (Riding, TruckSpraying, Pass_Godspeed,
-- InfiniteWater, workspace BoostUntil). Hose tier looks live in HazeFX.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local Sounds = J:WaitForChild("Sounds")

local C = Color3.fromRGB
local SMOKE_TEX = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEX = "rbxasset://textures/particles/sparkles_main.dds"

local fxFolder = Instance.new("Folder")
fxFolder.Name = "LocalRideFX"
fxFolder.Parent = workspace

local function emitterOn(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	for k, v in props do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function fxPart(name: string): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Parent = fxFolder
	return p
end

---------------------------------------------------------------- ride pose (local player; owner-played animations replicate)
-- R15 / R6 default sit ids, used only if the Animate script has no sit animation
local FALLBACK_SIT = { [Enum.HumanoidRigType.R15] = "rbxassetid://2506281703", [Enum.HumanoidRigType.R6] = "rbxassetid://178130996" }
local sitTrack: AnimationTrack? = nil
local sitChar: Model? = nil

local function stopSit()
	local t = sitTrack
	if t then
		pcall(function()
			t:Stop(0.2)
			t:Destroy()
		end)
	end
	sitTrack = nil
	sitChar = nil
end

local function sitAnimationId(char: Model, hum: Humanoid): string
	local animate = char:FindFirstChild("Animate")
	local sit = animate and animate:FindFirstChild("sit")
	local a = sit and sit:FindFirstChild("SitAnim")
	if a and a:IsA("Animation") and a.AnimationId ~= "" then return a.AnimationId end
	return FALLBACK_SIT[hum.RigType] or FALLBACK_SIT[Enum.HumanoidRigType.R15]
end

local function updatePose()
	local riding = (player:GetAttribute("Riding") or "") ~= ""
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (riding and char and hum and hum.Health > 0) then
		if sitTrack then stopSit() end
		return
	end
	if sitChar ~= char then stopSit() end
	local track = sitTrack
	if not track then
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then return end -- try again next frame
		local anim = Instance.new("Animation")
		anim.AnimationId = sitAnimationId(char, hum)
		local ok, loaded = pcall(function() return animator:LoadAnimation(anim) end)
		if not ok then return end
		loaded.Priority = Enum.AnimationPriority.Action -- above the Animate script's walk/idle so legs stay seated
		loaded.Looped = true
		loaded:Play(0.2)
		sitTrack = loaded
		sitChar = char
	elseif not track.IsPlaying then
		track:Play(0.2)
	end
end

---------------------------------------------------------------- truck roof cannon
local CANNON_RANGE = Config.Truck.radius -- same radius the server damages in
local GRAVITY = 70 -- stream particle gravity (studs/s^2), lighter than world gravity for a floaty arc
local cannons: { [Player]: any } = {}

local function buildCannon()
	local c: any = { muzzle = fxPart("TruckMuzzle"), target = fxPart("TruckTarget"), idle = 0 }
	c.stream = emitterOn(c.muzzle, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(C(245, 252, 255), C(170, 215, 255)),
		LightInfluence = 0.3,
		LightEmission = 0.35,
		Brightness = 1.4,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(0.6, 2.4), NumberSequenceKeypoint.new(1, 3.2) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.75, 0.4), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.5, 0.5),
		Speed = NumberRange.new(40, 40),
		SpreadAngle = Vector2.new(1.5, 1.5),
		EmissionDirection = Enum.NormalId.Front,
		Acceleration = Vector3.new(0, -GRAVITY, 0),
		RotSpeed = NumberRange.new(-60, 60),
		Rotation = NumberRange.new(0, 360),
	})
	c.drops = emitterOn(c.muzzle, {
		Texture = SPARK_TEX,
		Color = ColorSequence.new(C(220, 240, 255)),
		LightEmission = 0.4,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.15) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.5, 0.5),
		Speed = NumberRange.new(40, 40),
		SpreadAngle = Vector2.new(5, 5),
		EmissionDirection = Enum.NormalId.Front,
		Acceleration = Vector3.new(0, -GRAVITY, 0),
	})
	c.splash = emitterOn(c.target, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(C(235, 245, 255)),
		LightInfluence = 0.5,
		Brightness = 1.3,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 9) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.8, 1.3),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(75, 75),
		EmissionDirection = Enum.NormalId.Top,
	})
	c.steam = emitterOn(c.target, {
		Texture = SMOKE_TEX,
		Color = ColorSequence.new(C(250, 252, 255)),
		LightInfluence = 0.3,
		Brightness = 1.5,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 12) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(1.1, 1.8),
		Speed = NumberRange.new(5, 10),
		SpreadAngle = Vector2.new(30, 30),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 8, 0),
		Drag = 1.5,
		RotSpeed = NumberRange.new(-60, 60),
		Rotation = NumberRange.new(0, 360),
	})
	local snd = (Sounds:FindFirstChild("Spray") :: Sound):Clone()
	snd.Looped = true
	snd.Volume = 0
	snd.PlaybackSpeed = 0.85 -- slower = heavier pump
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = 15
	snd.RollOffMaxDistance = 160
	snd.Parent = c.muzzle
	snd:Play()
	c.sound = snd
	return c
end

local function destroyCannon(plr: Player)
	local c = cannons[plr]
	if not c then return end
	c.muzzle:Destroy()
	c.target:Destroy()
	cannons[plr] = nil
end

-- the model's "Cannon" attachment, else the roof of the model, else just above the player
local function muzzlePosition(char: Model, root: BasePart): Vector3
	local model = char:FindFirstChild("RideModel")
	if model and model:IsA("Model") then
		local cannon = model:FindFirstChild("Cannon", true)
		if cannon and cannon:IsA("Attachment") then return cannon.WorldPosition end
		local cf, size = model:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2 + 0.5, 0)
	end
	return root.Position + Vector3.new(0, 2.5, 0)
end

local function nearestFire(pos: Vector3): BasePart?
	local folder = workspace:FindFirstChild("Fires")
	if not folder then return nil end
	local best, bestD = nil, CANNON_RANGE
	for _, f in folder:GetChildren() do
		if f:IsA("BasePart") then
			local d = (f.Position - pos).Magnitude
			if d <= bestD then best, bestD = f, d end
		end
	end
	return best
end

local function updateCannon(plr: Player)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local active = root ~= nil
		and plr:GetAttribute("Riding") == "Truck"
		and plr:GetAttribute("TruckSpraying") == true
	local c = cannons[plr]
	if active and not c then
		c = buildCannon()
		cannons[plr] = c
	end
	if not c then return end

	local fire = active and nearestFire(root.Position) or nil
	if active and fire then
		local from = muzzlePosition(char, root)
		local to = fire.Position + Vector3.new(0, 1.5, 0)
		local dist = (to - from).Magnitude
		-- ballistic launch so the stream lands on the fire: v = d/T + g*T/2 (upward part)
		local T = math.clamp(dist / 45, 0.35, 0.75)
		local v = (to - from) / T + Vector3.new(0, 0.5 * GRAVITY * T, 0)
		c.muzzle.CFrame = CFrame.lookAt(from, from + v)
		c.target.CFrame = CFrame.new(to)
		c.stream.Speed = NumberRange.new(v.Magnitude * 0.98, v.Magnitude * 1.02)
		c.stream.Lifetime = NumberRange.new(T, T)
		c.drops.Speed = NumberRange.new(v.Magnitude * 0.96, v.Magnitude * 1.04)
		c.drops.Lifetime = NumberRange.new(T, T)
		local cam = workspace.CurrentCamera.CFrame.Position
		local near = (from - cam).Magnitude < 200
		c.stream.Rate = near and 110 or 40
		c.drops.Rate = near and 45 or 0
		c.splash.Rate = near and 32 or 10
		c.steam.Rate = near and 14 or 4
		c.sound.Volume += (0.9 - c.sound.Volume) * 0.25
		c.idle = 0
	else
		c.stream.Rate = 0
		c.drops.Rate = 0
		c.splash.Rate = 0
		c.steam.Rate = 0
		c.sound.Volume += (0 - c.sound.Volume) * 0.35
		c.idle += 1
		if c.idle > 180 and not active then destroyCannon(plr) end -- ~3 s: let particles finish, then clean up
	end
end

---------------------------------------------------------------- Godspeed golden trail
local trails: { [Player]: Trail } = {}

local function ensureTrail(plr: Player, root: BasePart): Trail
	local t = trails[plr]
	if t and t.Parent == root then return t end
	if t then t:Destroy() end
	local a0 = Instance.new("Attachment")
	a0.Name = "GodTop"
	a0.Position = Vector3.new(0, 0.6, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "GodBottom"
	a1.Position = Vector3.new(0, -2.2, 0.4)
	a1.Parent = root
	t = Instance.new("Trail")
	t.Name = "GodspeedTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, C(255, 236, 140)), ColorSequenceKeypoint.new(0.5, C(255, 190, 50)), ColorSequenceKeypoint.new(1, C(255, 140, 20)) })
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
	t.LightEmission = 0.9
	t.LightInfluence = 0
	t.Lifetime = 0.45
	t.MinLength = 0.1
	t.FaceCamera = true
	t.Enabled = false
	t.Parent = root
	trails[plr] = t
	return t
end

local function updateTrail(plr: Player, char: Model?, root: BasePart?, hum: Humanoid?)
	local wanted = root ~= nil and hum ~= nil and plr:GetAttribute("Pass_Godspeed") == true
	if not wanted then
		local t = trails[plr]
		if t then t.Enabled = false end
		return
	end
	local t = ensureTrail(plr, root :: BasePart)
	local v = (root :: BasePart).AssemblyLinearVelocity
	local moving = Vector3.new(v.X, 0, v.Z).Magnitude > 8
	t.Enabled = moving and (plr:GetAttribute("Riding") or "") == "" -- the pass is for running, not riding
end

---------------------------------------------------------------- Server Boost aura (green + purple motes)
local auras: { [Player]: { green: ParticleEmitter, purple: ParticleEmitter } } = {}

local function ensureAura(plr: Player, root: BasePart)
	local a = auras[plr]
	if a and a.green.Parent == root then return a end
	local function mote(color: Color3, tint: Color3)
		return emitterOn(root, {
			Name = "BoostAura",
			Texture = SPARK_TEX,
			Color = ColorSequence.new(color, tint),
			LightEmission = 0.8,
			LightInfluence = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.1) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 1) }),
			Lifetime = NumberRange.new(1.2, 1.8),
			Speed = NumberRange.new(0.5, 1.5),
			SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, 2.5, 0),
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			RotSpeed = NumberRange.new(-90, 90),
		})
	end
	a = { green = mote(C(90, 240, 140), C(190, 255, 200)), purple = mote(C(170, 110, 255), C(225, 200, 255)) }
	auras[plr] = a
	return a
end

local function updateAura(plr: Player, root: BasePart?, boosted: boolean, camPos: Vector3)
	local a = auras[plr]
	if not (boosted and root) then
		if a then
			a.green.Rate = 0
			a.purple.Rate = 0
		end
		return
	end
	a = ensureAura(plr, root)
	local near = (root.Position - camPos).Magnitude < 120
	local r = near and 5 or 0
	a.green.Rate = r
	a.purple.Rate = r
end

---------------------------------------------------------------- Infinite Tank gauge shimmer (cheap: one billboard on the tool)
local function updateInfinity(plr: Player, char: Model?, clock: number)
	if plr:GetAttribute("InfiniteWater") ~= true then return end
	local tool = char and char:FindFirstChild("Hose")
	local gauge = tool and (tool:FindFirstChild("Gauge", true) or tool:FindFirstChild("Handle"))
	if not (gauge and gauge:IsA("BasePart")) then return end
	local old = gauge:FindFirstChild("InfShimmer")
	if not old then
		local bb = Instance.new("BillboardGui")
		bb.Name = "InfShimmer"
		bb.Size = UDim2.fromScale(1.3, 1.3)
		bb.StudsOffset = Vector3.new(0, 0.9, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 60
		bb.Adornee = gauge
		local t = Instance.new("TextLabel")
		t.Name = "Sym"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "∞"
		t.TextScaled = true
		t.Font = Enum.Font.SourceSansBold
		t.TextColor3 = C(120, 235, 255)
		t.TextStrokeColor3 = C(255, 230, 140)
		t.TextStrokeTransparency = 0.5
		t.Parent = bb
		bb.Parent = gauge
		old = bb
	end
	local sym = (old :: Instance):FindFirstChild("Sym") :: TextLabel?
	if sym then
		local k = 0.5 + 0.5 * math.sin(clock * 3 + plr.UserId % 7)
		sym.TextTransparency = 0.1 + 0.5 * k
		sym.TextColor3 = C(120, 235, 255):Lerp(C(255, 230, 140), k)
	end
end

---------------------------------------------------------------- loop
RunService.RenderStepped:Connect(function()
	local clock = os.clock()
	local boosted = (workspace:GetAttribute("BoostUntil") or 0) > workspace:GetServerTimeNow()
	local camPos = workspace.CurrentCamera.CFrame.Position
	updatePose()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		updateCannon(plr)
		updateTrail(plr, char, root, hum)
		updateAura(plr, root, boosted, camPos)
		updateInfinity(plr, char, clock)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	destroyCannon(plr)
	trails[plr] = nil
	auras[plr] = nil
end)

player.CharacterRemoving:Connect(stopSit)
