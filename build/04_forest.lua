-- Jerebu build step 4/6: forest (280 trees + 22 peat patches), all tagged "Tree" with Peat/Ground attributes
local CS = game:GetService("CollectionService")
local Map = workspace.Map
local old = Map:FindFirstChild("Forest") if old then old:Destroy() end
local Forest = Instance.new("Folder") Forest.Name = "Forest" Forest.Parent = Map
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }

local function P(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color p.Material = mat p.Anchored = true
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function ok(x, z)
	if x > -165 and x < 165 and z > -108 and z < 155 then return false end -- town
	if z > -160 and z < -100 then return false end -- river
	if math.abs(x) < 9 or math.abs(z - 20) < 9 then return false end -- paths
	if x > -150 and x < -90 and z > -10 and z < 130 then return false end -- airstrip
	if math.abs(x) > 425 or math.abs(z) > 425 then return false end
	return true
end

local rng = Random.new(7)
local leafCols = { Color3.fromRGB(52, 110, 48), Color3.fromRGB(70, 128, 52), Color3.fromRGB(40, 94, 44), Color3.fromRGB(86, 140, 60) }
local pts = {}
local function far(x, z)
	for _, p in pts do if (p.X - x) ^ 2 + (p.Y - z) ^ 2 < 15 ^ 2 then return false end end
	return true
end
local tries, count = 0, 0
local chunk = Instance.new("Folder")
while count < 280 and tries < 6000 do
	tries += 1
	local x, z = rng:NextNumber(-420, 420), rng:NextNumber(-420, 420)
	local peat = (x > 150 and x < 370 and z > -360 and z < -180)
	if ok(x, z) and far(x, z) then
		local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -200, 0), params)
		if hit and hit.Material ~= Enum.Material.Water then
			table.insert(pts, Vector2.new(x, z))
			count += 1
			local y = hit.Position.Y
			local m = Instance.new("Model") m.Name = peat and "PeatTree" or "Tree"
			local palm = (not peat) and rng:NextNumber() < 0.25
			local h = peat and rng:NextNumber(10, 16) or (palm and rng:NextNumber(14, 20) or rng:NextNumber(18, 30))
			local trunk = P(m, "Trunk", Vector3.new(h, peat and 1.4 or 2.2, peat and 1.4 or 2.2), CFrame.new(x, y + h / 2 - 0.5, z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(92, 66, 46), Enum.Material.Wood, Enum.PartType.Cylinder)
			if palm then
				for i = 1, 6 do
					local a = i / 6 * math.pi * 2
					P(m, "Frond", Vector3.new(0.4, 1.6, 9), CFrame.new(x, y + h, z) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-20), 0, 0) * CFrame.new(0, 0, -4), Color3.fromRGB(64, 120, 44), Enum.Material.Grass)
				end
			elseif peat then
				P(m, "Leaves", Vector3.new(7, 7, 7), CFrame.new(x, y + h, z), Color3.fromRGB(110, 120, 60), Enum.Material.Grass, Enum.PartType.Ball)
			else
				local c = leafCols[rng:NextInteger(1, #leafCols)]
				local s = rng:NextNumber(11, 16)
				P(m, "Leaves", Vector3.new(s, s * 0.8, s), CFrame.new(x, y + h, z), c, Enum.Material.Grass, Enum.PartType.Ball)
				P(m, "Leaves2", Vector3.new(s * 0.75, s * 0.6, s * 0.75), CFrame.new(x + s * 0.35, y + h - 2, z + s * 0.2), c, Enum.Material.Grass, Enum.PartType.Ball)
			end
			for _, d in m:GetChildren() do if d.Name ~= "Trunk" then d.CanCollide = false end end
			m.PrimaryPart = trunk
			m:SetAttribute("Peat", peat)
			m:SetAttribute("Ground", y)
			CS:AddTag(m, "Tree")
			m.Parent = chunk
			if count % 40 == 0 then chunk.Parent = Forest chunk = Instance.new("Folder") task.wait() end
		end
	end
end
chunk.Parent = Forest
for _, f in Forest:GetChildren() do
	if f:IsA("Folder") then for _, t in f:GetChildren() do t.Parent = Forest end f:Destroy() end
end

-- peat patches (dry shrubs on peat ground) so the peatland has enough fire spots
local prng = Random.new(99)
local n = 0
for _ = 1, 200 do
	if n >= 22 then break end
	local x, z = prng:NextNumber(165, 360), prng:NextNumber(-350, -190)
	local clear = true
	for _, t in Forest:GetChildren() do
		local p = t:GetPivot().Position
		if (Vector2.new(p.X, p.Z) - Vector2.new(x, z)).Magnitude < 12 then clear = false break end
	end
	if clear then
		local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -200, 0), params)
		if hit then
			n += 1
			local y = hit.Position.Y
			local m = Instance.new("Model") m.Name = "PeatPatch"
			local base = P(m, "Trunk", Vector3.new(6, 0.6, 6), CFrame.new(x, y + 0.1, z), Color3.fromRGB(60, 42, 30), Enum.Material.Ground)
			base.CanCollide = false
			for _ = 1, 4 do
				local d = prng:NextNumber(1.6, 3)
				local s = P(m, "Shrub", Vector3.new(d, d * 0.7, d), CFrame.new(x + prng:NextNumber(-2.5, 2.5), y + d * 0.3, z + prng:NextNumber(-2.5, 2.5)), Color3.fromRGB(130, 120, 70), Enum.Material.Grass, Enum.PartType.Ball)
				s.CanCollide = false
			end
			m.PrimaryPart = base
			m:SetAttribute("Peat", true)
			m:SetAttribute("Ground", y)
			CS:AddTag(m, "Tree")
			m.Parent = Forest
		end
	end
end
return count .. " trees, " .. n .. " peat patches"
