-- Jerebu build step 2/6: Map folder, kampung houses, BOMBA fire station, school
local old = workspace:FindFirstChild("Map") if old then old:Destroy() end
local Map = Instance.new("Folder") Map.Name = "Map"
local Town = Instance.new("Folder", Map) Town.Name = "Town"

local function P(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = name p.Size = size p.CFrame = cf p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in props do p[k] = v end end
	p.Parent = parent
	return p
end
local function W(parent, name, size, cf, color, mat)
	local w = Instance.new("WedgePart")
	w.Name = name w.Size = size w.CFrame = cf w.Color = color
	w.Material = mat or Enum.Material.SmoothPlastic w.Anchored = true
	w.Parent = parent
	return w
end
local function sign(part, face, text, bg, fg)
	local sg = Instance.new("SurfaceGui") sg.Face = face sg.PixelsPerStud = 40 sg.LightInfluence = 0.2
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundColor3 = bg t.TextColor3 = fg
	t.Text = text t.TextScaled = true t.Font = Enum.Font.GothamBlack t.Parent = sg
	local pad = Instance.new("UIPadding", t) pad.PaddingLeft = UDim.new(0.04, 0) pad.PaddingRight = UDim.new(0.04, 0)
	sg.Parent = part
end

-- kampung houses on stilts
local function house(cf, wall, roof)
	local m = Instance.new("Model") m.Name = "Rumah"
	for _, o in { Vector3.new(-9, 0, -7), Vector3.new(9, 0, -7), Vector3.new(-9, 0, 7), Vector3.new(9, 0, 7) } do
		P(m, "Stilt", Vector3.new(1.2, 4, 1.2), cf * CFrame.new(o + Vector3.new(0, 2, 0)), Color3.fromRGB(96, 68, 48), Enum.Material.Wood)
	end
	P(m, "Floor", Vector3.new(20, 1, 16), cf * CFrame.new(0, 4.5, 0), Color3.fromRGB(120, 86, 58), Enum.Material.WoodPlanks)
	P(m, "WallBack", Vector3.new(20, 8, 0.8), cf * CFrame.new(0, 9, -7.6), wall, Enum.Material.WoodPlanks)
	P(m, "WallL", Vector3.new(0.8, 8, 16), cf * CFrame.new(-9.6, 9, 0), wall, Enum.Material.WoodPlanks)
	P(m, "WallR", Vector3.new(0.8, 8, 16), cf * CFrame.new(9.6, 9, 0), wall, Enum.Material.WoodPlanks)
	P(m, "WallFrontL", Vector3.new(7, 8, 0.8), cf * CFrame.new(-6.5, 9, 7.6), wall, Enum.Material.WoodPlanks)
	P(m, "WallFrontR", Vector3.new(7, 8, 0.8), cf * CFrame.new(6.5, 9, 7.6), wall, Enum.Material.WoodPlanks)
	P(m, "WallFrontTop", Vector3.new(6, 2.5, 0.8), cf * CFrame.new(0, 11.75, 7.6), wall, Enum.Material.WoodPlanks)
	P(m, "Window", Vector3.new(4, 3, 0.9), cf * CFrame.new(-6, 10, 7.6), Color3.fromRGB(160, 200, 220), Enum.Material.Glass, { Transparency = 0.4 })
	P(m, "Window2", Vector3.new(4, 3, 0.9), cf * CFrame.new(6, 10, 7.6), Color3.fromRGB(160, 200, 220), Enum.Material.Glass, { Transparency = 0.4 })
	W(m, "RoofA", Vector3.new(22, 6, 10), cf * CFrame.new(0, 16, 4.5), roof, Enum.Material.CorrodedMetal)
	W(m, "RoofB", Vector3.new(22, 6, 10), cf * CFrame.new(0, 16, -4.5) * CFrame.Angles(0, math.pi, 0), roof, Enum.Material.CorrodedMetal)
	for i = 0, 3 do
		P(m, "Step", Vector3.new(5, 0.6, 1.4), cf * CFrame.new(0, 0.6 + i * 1, 11.5 - i * 1.3), Color3.fromRGB(110, 78, 52), Enum.Material.Wood)
	end
	m.Parent = Town
end
local walls = { Color3.fromRGB(214, 190, 140), Color3.fromRGB(170, 205, 190), Color3.fromRGB(230, 215, 170), Color3.fromRGB(200, 170, 150), Color3.fromRGB(180, 200, 220) }
local roofs = { Color3.fromRGB(150, 60, 45), Color3.fromRGB(70, 90, 110), Color3.fromRGB(120, 50, 40) }
local spots = {
	{ -40, 55, 0 }, { -75, 55, 0 }, { -40, 95, math.pi }, { -75, 95, math.pi },
	{ 40, -15, math.pi }, { 75, -15, math.pi }, { -75, -15, math.pi },
	{ 40, 100, math.pi / 2 }, { -80, 20, math.pi / 2 }, { 80, 20, -math.pi / 2 },
}
for i, s in spots do
	house(CFrame.new(s[1], 0, s[2]) * CFrame.Angles(0, s[3], 0), walls[(i - 1) % #walls + 1], roofs[(i - 1) % #roofs + 1])
end

-- FIRE STATION (BOMBA): spawn, shop counter
local fs = Instance.new("Model") fs.Name = "FireStation"
local base = CFrame.new(-40, 0, -40)
P(fs, "Slab", Vector3.new(44, 1, 32), base * CFrame.new(0, 0.5, 0), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
P(fs, "Back", Vector3.new(44, 18, 1), base * CFrame.new(0, 9.5, -15.5), Color3.fromRGB(200, 40, 40), Enum.Material.Brick)
P(fs, "Left", Vector3.new(1, 18, 32), base * CFrame.new(-21.5, 9.5, 0), Color3.fromRGB(200, 40, 40), Enum.Material.Brick)
P(fs, "Right", Vector3.new(1, 18, 32), base * CFrame.new(21.5, 9.5, 0), Color3.fromRGB(200, 40, 40), Enum.Material.Brick)
P(fs, "Pillar", Vector3.new(2, 18, 1), base * CFrame.new(0, 9.5, 15.5), Color3.fromRGB(230, 230, 230), Enum.Material.Concrete)
local front = P(fs, "FrontTop", Vector3.new(44, 5, 1), base * CFrame.new(0, 16, 15.5), Color3.fromRGB(230, 230, 230), Enum.Material.Concrete)
sign(front, Enum.NormalId.Front, "BALAI BOMBA", Color3.fromRGB(200, 30, 30), Color3.new(1, 1, 1))
P(fs, "Roof", Vector3.new(46, 1, 34), base * CFrame.new(0, 19, 0), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
local truck = Instance.new("Model", fs) truck.Name = "FireTruck"
P(truck, "Body", Vector3.new(8, 6, 16), base * CFrame.new(-10, 4.5, 2), Color3.fromRGB(210, 30, 30))
P(truck, "Cab", Vector3.new(8, 4, 5), base * CFrame.new(-10, 9.5, 7), Color3.fromRGB(210, 30, 30))
P(truck, "Glass", Vector3.new(7.6, 2.4, 0.3), base * CFrame.new(-10, 10, 9.6), Color3.fromRGB(120, 170, 200), Enum.Material.Glass, { Transparency = 0.3 })
P(truck, "Ladder", Vector3.new(2, 1, 12), base * CFrame.new(-10, 8, -2), Color3.fromRGB(200, 200, 200), Enum.Material.Metal)
for _, o in { { -4, -4 }, { 4, -4 }, { -4, 7 }, { 4, 7 } } do
	P(truck, "Wheel", Vector3.new(1.4, 3, 3), base * CFrame.new(-10 + o[1], 1.6, 2 + o[2]) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3, 3) })
end
local counter = P(fs, "ShopCounter", Vector3.new(10, 4, 3), base * CFrame.new(10, 3, -8), Color3.fromRGB(240, 200, 60))
local shopSign = P(fs, "ShopSign", Vector3.new(10, 3, 0.4), base * CFrame.new(10, 8, -9.4), Color3.fromRGB(30, 30, 30))
sign(shopSign, Enum.NormalId.Front, "KEDAI PERALATAN · GEAR", Color3.fromRGB(240, 200, 60), Color3.fromRGB(30, 30, 30))
local shopPrompt = Instance.new("ProximityPrompt") shopPrompt.Name = "ShopPrompt" shopPrompt.ActionText = "Open shop" shopPrompt.ObjectText = "Gear · Peralatan" shopPrompt.HoldDuration = 0 shopPrompt.MaxActivationDistance = 12 shopPrompt.RequiresLineOfSight = false shopPrompt.Parent = counter
local sp = Instance.new("SpawnLocation") sp.Name = "Spawn" sp.Size = Vector3.new(10, 1, 10)
sp.CFrame = base * CFrame.new(10, 1.1, 6) * CFrame.Angles(0, math.pi, 0) -- face out of the open front
sp.Anchored = true sp.Color = Color3.fromRGB(240, 200, 60) sp.Material = Enum.Material.SmoothPlastic sp.Duration = 0 sp.Transparency = 0.2
local decal = sp:FindFirstChildOfClass("Decal") if decal then decal:Destroy() end
sp.Parent = fs
fs.Parent = Town

-- SCHOOL (+ "field closed" tape and sign, toggled by the server at API > 100)
local sc = Instance.new("Model") sc.Name = "School"
local sb = CFrame.new(110, 0, 65)
P(sc, "Building", Vector3.new(16, 16, 50), sb * CFrame.new(0, 8, 0), Color3.fromRGB(235, 225, 190), Enum.Material.Concrete)
P(sc, "Roof", Vector3.new(18, 1, 52), sb * CFrame.new(0, 16.5, 0), Color3.fromRGB(40, 90, 140), Enum.Material.Metal)
local ss = P(sc, "Sign", Vector3.new(0.4, 4, 26), sb * CFrame.new(-8.3, 12, 0), Color3.fromRGB(40, 90, 140))
sign(ss, Enum.NormalId.Left, "SEKOLAH KEBANGSAAN", Color3.fromRGB(40, 90, 140), Color3.new(1, 1, 1))
for i = -2, 2 do P(sc, "Window", Vector3.new(0.3, 4, 6), sb * CFrame.new(-8.1, 6, i * 9), Color3.fromRGB(150, 190, 210), Enum.Material.Glass, { Transparency = 0.3 }) end
P(sc, "GoalA", Vector3.new(1, 6, 10), CFrame.new(32, 3, 65), Color3.new(1, 1, 1))
P(sc, "GoalB", Vector3.new(1, 6, 10), CFrame.new(88, 3, 65), Color3.new(1, 1, 1))
local closed = Instance.new("Model", sc) closed.Name = "FieldClosed"
for _, c in { { 60, 43 }, { 60, 87 } } do
	P(closed, "Tape", Vector3.new(60, 0.6, 0.3), CFrame.new(c[1], 3, c[2]), Color3.fromRGB(255, 200, 0), Enum.Material.Neon, { CanCollide = false, Transparency = 1 })
end
local closeSign = P(closed, "ClosedSign", Vector3.new(14, 5, 0.4), CFrame.new(60, 6, 43), Color3.fromRGB(255, 200, 0), Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false })
sign(closeSign, Enum.NormalId.Front, "PADANG DITUTUP · API > 100", Color3.fromRGB(255, 200, 0), Color3.fromRGB(20, 20, 20))
closeSign.SurfaceGui.Enabled = false
sc.Parent = Town

Map.Parent = workspace
return "town ok"
