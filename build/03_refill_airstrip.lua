-- Jerebu build step 3/6: refill zones (river + hydrants), bridge, airstrip with cloud-seeding plane
local CS = game:GetService("CollectionService")
local Map = workspace.Map
local function P(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true
	if props then for k, v in props do p[k] = v end end
	p.Parent = parent
	return p
end
local hidden = { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }

local Refill = Instance.new("Folder", Map) Refill.Name = "Refill"
local river = P(Refill, "RiverZone", Vector3.new(900, 10, 44), CFrame.new(0, 0, -130), Color3.new(0, 0.5, 1), nil, hidden)
river:SetAttribute("Rate", 30) CS:AddTag(river, "Refill")
for _, h in { { 12, -10 }, { -12, 50 }, { 30, 32 }, { -30, 8 }, { 12, 90 }, { 0, -100 }, { 150, 20 }, { -150, 20 }, { 0, 150 } } do
	local m = Instance.new("Model") m.Name = "Hydrant"
	local b = P(m, "Body", Vector3.new(3, 1.6, 1.6), CFrame.new(h[1], 1.5, h[2]) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(220, 40, 40), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	P(m, "Cap", Vector3.new(1.9, 0.5, 1.9), CFrame.new(h[1], 3.2, h[2]), Color3.fromRGB(240, 200, 60), Enum.Material.Metal)
	local zone = P(m, "Zone", Vector3.new(14, 8, 14), CFrame.new(h[1], 3, h[2]), Color3.new(0, 0.5, 1), nil, hidden)
	zone:SetAttribute("Rate", 40) CS:AddTag(zone, "Refill")
	local bb = Instance.new("BillboardGui") bb.Name = "Icon" bb.Size = UDim2.fromOffset(34, 34) bb.StudsOffset = Vector3.new(0, 3.5, 0) bb.MaxDistance = 120 bb.AlwaysOnTop = true
	local t = Instance.new("TextLabel", bb) t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = Color3.fromRGB(30, 140, 255) t.Text = "💧" t.TextScaled = true t.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", t).CornerRadius = UDim.new(1, 0)
	bb.Parent = b
	m.Parent = Refill
end

-- bridge over the river on the south path
P(Map, "Bridge", Vector3.new(14, 1, 50), CFrame.new(0, 0.6, -130), Color3.fromRGB(120, 86, 58), Enum.Material.WoodPlanks)
P(Map, "RailL", Vector3.new(0.6, 3, 50), CFrame.new(-7, 2.6, -130), Color3.fromRGB(96, 68, 48), Enum.Material.Wood)
P(Map, "RailR", Vector3.new(0.6, 3, 50), CFrame.new(7, 2.6, -130), Color3.fromRGB(96, 68, 48), Enum.Material.Wood)

-- AIRSTRIP + cloud seeding plane
local air = Instance.new("Model") air.Name = "Airstrip"
local ab = CFrame.new(-120, 0, 60)
P(air, "Runway", Vector3.new(30, 0.3, 110), ab * CFrame.new(0, 0.2, 0), Color3.fromRGB(55, 55, 60), Enum.Material.Asphalt)
for i = -4, 4 do P(air, "Stripe", Vector3.new(1.2, 0.32, 6), ab * CFrame.new(0, 0.22, i * 12), Color3.new(1, 1, 1)) end
local plane = Instance.new("Model", air) plane.Name = "SeedingPlane"
local body = P(plane, "Body", Vector3.new(4, 4, 22), ab * CFrame.new(0, 3, 10), Color3.fromRGB(235, 235, 235))
P(plane, "Wing", Vector3.new(30, 0.6, 5), ab * CFrame.new(0, 3.6, 12), Color3.fromRGB(235, 235, 235))
P(plane, "Tail", Vector3.new(10, 0.5, 3), ab * CFrame.new(0, 4, 0.5), Color3.fromRGB(235, 235, 235))
P(plane, "Fin", Vector3.new(0.5, 4, 3), ab * CFrame.new(0, 6, 0.5), Color3.fromRGB(30, 90, 170))
P(plane, "Stripe", Vector3.new(4.1, 0.8, 22.1), ab * CFrame.new(0, 3, 10), Color3.fromRGB(30, 90, 170))
P(plane, "Nose", Vector3.new(3, 3, 2), ab * CFrame.new(0, 3, 22), Color3.fromRGB(30, 30, 35))
P(plane, "Prop", Vector3.new(7, 0.4, 0.3), ab * CFrame.new(0, 3, 23.2), Color3.fromRGB(40, 40, 40))
plane.PrimaryPart = body
local pad = P(air, "SeedPad", Vector3.new(10, 1, 10), ab * CFrame.new(20, 0.5, 10), Color3.fromRGB(30, 140, 255), Enum.Material.Neon, { Transparency = 0.5 })
local pr = Instance.new("ProximityPrompt") pr.Name = "SeedPrompt" pr.ActionText = "Load seeding flares" pr.ObjectText = "Cloud Seeding · Pembenihan Awan"
pr.HoldDuration = 2.5 pr.MaxActivationDistance = 12 pr.RequiresLineOfSight = false pr.Enabled = false pr.Parent = pad
P(air, "Hangar", Vector3.new(26, 14, 22), ab * CFrame.new(-28, 7, -30), Color3.fromRGB(180, 185, 190), Enum.Material.CorrodedMetal)
air.Parent = Map
return "refill + airstrip ok"
