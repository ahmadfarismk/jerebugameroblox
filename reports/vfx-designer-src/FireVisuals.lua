--[[ VFX Designer — owned JerebuServer functions (UNVERIFIED: written after Studio crashed)

WHERE THIS GOES in ServerScriptService.JerebuServer:
 1. DELETE the old `local function charTree(...) ... end` (it sits right after the tree
    neighbour loop, before `resetTrees`). resetTrees still calls charTree(info, 0), so the
    new charTree must be declared BEFORE resetTrees.
 2. DELETE the old "fire visuals" block: the FIRE_TEX/SMOKE_TEX/SPARK_TEX locals,
    `makeFirePart` and `updateFireVisual` (between `resetTrees` and the "fires" section header).
 3. PASTE everything from the "fire visuals" header below to the end of `updateFireVisual`
    in place of the old charTree (i.e. after the neighbour loop, before resetTrees).
    It relies on existing upvalues: Map, FiresFolder, Sounds, Config, rng, TreeInfo type.
 4. The plane-trail snippet at the bottom of this file goes inside `runCloudSeeding`
    (see the comments there). Nothing else in the server changes; no rules/tuning touched.
]]

---------------------------------------------------------------- fire visuals
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

-- one-off look changes when a fire switches between burning and smouldering
local function setFireMode(part: BasePart, peat: boolean, smoulder: boolean)
	local mode = smoulder and "smoulder" or "burn"
	if part:GetAttribute("VisMode") == mode then return false end
	local wasSmoulder = part:GetAttribute("VisMode") == "smoulder"
	part:SetAttribute("VisMode", mode)
	local flames = part.Flames :: ParticleEmitter
	local smoke = part.Smoke :: ParticleEmitter
	if smoulder then
		-- glowing ember patches in the peat + thin smoke that creeps along the ground
		flames.Texture = GLOW_TEX
		flames.Color = ColorSequence.new(CR(255, 120, 30), CR(200, 45, 15))
		flames.LightEmission = 0.8
		flames.Brightness = 3
		flames.Transparency = NS({ NK(0, 1), NK(0.25, 0.15), NK(0.6, 0.35), NK(1, 1) })
		flames.Size = NS({ NK(0, 1.4), NK(0.5, 2.6), NK(1, 1.8) })
		flames.Lifetime = NumberRange.new(1.6, 2.8)
		flames.Speed = NumberRange.new(0.1, 0.4)
		flames.Acceleration = Vector3.zero
		flames.RotSpeed = NumberRange.new(0, 0)
		flames.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		smoke.Color = ColorSequence.new(CR(190, 185, 175), CR(160, 155, 148))
		smoke.Size = NS({ NK(0, 2.5), NK(1, 11) })
		smoke.Transparency = NS({ NK(0, 1), NK(0.15, 0.55), NK(1, 1) })
		smoke.Lifetime = NumberRange.new(5, 7)
		smoke.Speed = NumberRange.new(1.5, 3)
		smoke.SpreadAngle = Vector2.new(80, 80)
		smoke.Acceleration = Vector3.new(0, 0.25, 0)
		smoke.Drag = 0.4
		part.PointLight.Color = CR(255, 90, 30)
		part.Embers.Size = NS({ NK(0, 0.3), NK(1, 0) })
		part.Embers.Speed = NumberRange.new(2, 5)
	else
		flames.Texture = FIRE_TEX
		flames.Color = peat and PEAT_FLAME_COLOR or FLAME_COLOR
		flames.LightEmission = 0.3
		flames.Brightness = 4
		flames.Transparency = FLAME_ALPHA
		flames.Lifetime = NumberRange.new(0.6, 1.1)
		flames.Acceleration = Vector3.new(0, 8, 0)
		flames.RotSpeed = NumberRange.new(-70, 70)
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
		flames.Rate = 9 * (1 - wet * 0.8)
		if crown then crown.Rate = 0 end
		embers.Enabled = true
		embers.Rate = 1.5 * (1 - wet)
		smoke.Rate = 3 + 3 * wet -- more steam-like smoke as it is soaked
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

---------------------------------------------------------------- plane seeding trail (inside runCloudSeeding)
-- (a) Paste right after `local function fly(...) ... end` inside runCloudSeeding:
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
-- (b) Right before `State.raining = true`:   if trail then trail.Enabled = true end
-- (c) Right before `value:Destroy()`:
--     if trail then trail.Enabled = false; task.delay(3.5, function() trail:Destroy() end) end
--     (also destroy the two attachments in that delay: body.SeedTrailA / body.SeedTrailB)
-- Note: plane wingspan axis assumed X; if the trail looks vertical, swap X for Y/Z.
