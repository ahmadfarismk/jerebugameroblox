-- 07_props.lua: rebuilds ServerStorage.Hoses.Hose1..6 and ServerStorage.Rides.Bicycle/Kapcai/Truck.
-- Run in Edit mode via execute_luau (needs StarterPack.Hose for the Nozzle/Jet/Drops template).
-- Studio freezes on big scripts: run it in 4 chunks, split at the "-- ==== CHUNK" markers
-- (each chunk after the first must start with the LIB header, i.e. keep `local L = shared.PropLib`).
-- Ride space: ground = y 0, forward = -Z, wheel axes = X. Seat attachment = player's HumanoidRootPart
-- (3 studs above the floor), so the truck is a low "well" bed: the root cannot be raised by the model.

-- ==== CHUNK 1: LIB ====
local SS = game:GetService("ServerStorage")
local L = {}
shared.PropLib = L
local V, CN, AN, C = Vector3.new, CFrame.new, CFrame.Angles, Color3.fromRGB
L.V, L.CN, L.AN, L.C = V, CN, AN, C
local MAT = {P = Enum.Material.SmoothPlastic, M = Enum.Material.Metal, N = Enum.Material.Neon, W = Enum.Material.Wood,
	R = Enum.Material.Rubber, G = Enum.Material.Glass, L = Enum.Material.Leather}
function L.folder(n) local f = SS:FindFirstChild(n) if not f then f = Instance.new("Folder") f.Name = n f.Parent = SS end return f end
local function mk(parent, name, shape, size, cf, col, mat, tr)
	local p = Instance.new("Part") p.Name = name p.Shape = shape p.Size = size p.CFrame = cf p.Color = col
	p.Material = MAT[mat or "P"] p.Transparency = tr or 0 p.Anchored = false p.CanCollide = false p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth p.Parent = parent return p
end
function L.blk(pa, n, sx, sy, sz, x, y, z, col, mat, rot, tr) return mk(pa, n, Enum.PartType.Block, V(sx, sy, sz), CN(x, y, z) * (rot or CFrame.new()), col, mat, tr) end
function L.cylX(pa, n, len, d, cf, col, mat, tr) return mk(pa, n, Enum.PartType.Cylinder, V(len, d, d), cf, col, mat, tr) end
function L.cylZ(pa, n, len, d, cf, col, mat, tr) return mk(pa, n, Enum.PartType.Cylinder, V(len, d, d), cf * AN(0, math.pi / 2, 0), col, mat, tr) end
function L.cylY(pa, n, len, d, cf, col, mat, tr) return mk(pa, n, Enum.PartType.Cylinder, V(len, d, d), cf * AN(0, 0, math.pi / 2), col, mat, tr) end
function L.ball(pa, n, d, cf, col, mat, tr) return mk(pa, n, Enum.PartType.Ball, V(d, d, d), cf, col, mat, tr) end
function L.bar(pa, n, a, b, t, col, mat) return mk(pa, n, Enum.PartType.Block, V(t, t, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), col, mat) end
function L.newHose(tier, hcol, hmat, fn)
	local src = game.StarterPack.Hose
	local tool = Instance.new("Tool") tool.Name = "Hose" .. tier tool.RequiresHandle = true tool.CanBeDropped = false
	tool.GripPos = src.GripPos tool.GripForward = src.GripForward tool.GripUp = src.GripUp tool.GripRight = src.GripRight
	local h = mk(tool, "Handle", Enum.PartType.Block, V(.6, .8, 2.6), CFrame.new(), hcol, hmat)
	fn(tool)
	local nz = src.Handle.Nozzle:Clone() nz.CFrame = CN(0, .15, -2.95) nz.Parent = h
	for _, e in nz:GetChildren() do if e:IsA("ParticleEmitter") then e.Enabled = false end end
	for _, p in tool:GetChildren() do if p:IsA("BasePart") and p ~= h then
		local w = Instance.new("WeldConstraint") w.Part0 = h w.Part1 = p w.Parent = p end end
	local f = L.folder("Hoses") local old = f:FindFirstChild(tool.Name) if old then old:Destroy() end
	tool.Parent = f return tool
end
function L.newRide(name, build)
	local m = Instance.new("Model") m.Name = name
	local primary, seat, cannon = build(m)
	m.PrimaryPart = primary
	local a = Instance.new("Attachment") a.Name = "Seat" a.CFrame = primary.CFrame:Inverse() * CN(seat) a.Parent = primary
	if cannon then local c = Instance.new("Attachment") c.Name = "Cannon" c.CFrame = primary.CFrame:Inverse() * CN(cannon) c.Parent = primary end
	local f = L.folder("Rides") local old = f:FindFirstChild(name) if old then old:Destroy() end
	m.Parent = f return m
end

-- ==== CHUNK 2: HOSES ====
local blk, cylX, cylZ, cylY, ball, bar = L.blk, L.cylX, L.cylZ, L.cylY, L.ball, L.bar
local g = AN(-math.rad(15), 0, 0)
-- Tier 1: red starter hose, brass nozzle
L.newHose(1, C(200, 40, 40), "P", function(t)
	cylZ(t, "Barrel", 1.6, .5, CN(0, .15, -1.9), C(214, 160, 50), "M")
	cylZ(t, "Tip", .3, .7, CN(0, .15, -2.8), C(235, 185, 65), "M")
	blk(t, "Grip", .45, 1.1, .5, 0, -.7, .4, C(60, 60, 65), "P", g)
	cylX(t, "Coil", .5, 1.3, CN(0, -.1, 1.6), C(170, 30, 30), "P")
	blk(t, "Band", .7, .9, .25, 0, 0, -.6, C(214, 160, 50), "M")
end)
-- Tier 2: brass jet, leather grip, gauge
local brass, leather = C(222, 170, 60), C(120, 70, 40)
L.newHose(2, brass, "M", function(t)
	cylZ(t, "Barrel", 1.6, .55, CN(0, .15, -1.9), C(200, 140, 40), "M")
	cylZ(t, "Collar", .2, .85, CN(0, .15, -1.2), leather, "L")
	cylZ(t, "Tip", .35, .95, CN(0, .15, -2.78), C(245, 200, 85), "M")
	blk(t, "Grip", .5, 1.2, .55, 0, -.75, .4, leather, "L", g)
	blk(t, "Wrap1", .72, .95, .3, 0, 0, .9, leather, "L")
	blk(t, "Wrap2", .72, .95, .3, 0, 0, -.1, leather, "L")
	cylX(t, "GaugeRim", .25, .8, CN(.45, .5, .2), brass, "M")
	cylX(t, "GaugeFace", .06, .62, CN(.6, .5, .2), C(250, 250, 250), "P")
	blk(t, "Needle", .04, .3, .06, .64, .55, .2, C(220, 40, 40), "P")
	blk(t, "Pipe", .15, .15, .9, .35, .3, -.4, brass, "M")
end)
-- Tier 3: chrome twin barrel, blue strap
local chrome, dchrome = C(225, 230, 240), C(120, 130, 150)
L.newHose(3, C(205, 210, 220), "M", function(t)
	for _, s in {-1, 1} do
		cylZ(t, "Barrel", 1.9, .42, CN(s * .3, .15, -1.95), chrome, "M")
		cylZ(t, "BarrelTip", .2, .56, CN(s * .3, .15, -2.85), dchrome, "M")
	end
	blk(t, "Bridge1", .7, .3, .3, 0, .15, -1.4, dchrome, "M")
	blk(t, "Bridge2", .7, .3, .3, 0, .15, -2.4, dchrome, "M")
	blk(t, "Strap", .72, 1.0, .35, 0, 0, .6, C(40, 110, 220), "P")
	blk(t, "Buckle", .25, .25, .4, 0, .45, .6, chrome, "M")
	blk(t, "Grip", .45, 1.1, .5, 0, -.7, .4, C(30, 60, 130), "P", g)
	cylZ(t, "MiniTank", 1.2, .55, CN(0, .75, -.3), C(40, 110, 220), "P")
	cylZ(t, "TankCap", .15, .4, CN(0, .75, -.95), chrome, "M")
end)
-- Tier 4: yellow foam cannon, white tank
local yel = C(250, 200, 30)
L.newHose(4, yel, "P", function(t)
	cylZ(t, "Barrel", 1.9, 1.1, CN(0, .15, -1.95), yel, "P")
	cylZ(t, "MuzzleRing", .3, 1.3, CN(0, .15, -2.8), C(60, 60, 70), "M")
	cylY(t, "FoamTank", 1.7, 1.1, CN(0, 1.4, -1.2), C(245, 245, 245), "P")
	ball(t, "TankCap", 1.1, CN(0, 2.25, -1.2), yel, "P")
	cylY(t, "StripeLow", .2, 1.16, CN(0, .9, -1.2), yel, "P")
	cylY(t, "StripeHigh", .2, 1.16, CN(0, 1.9, -1.2), yel, "P")
	blk(t, "Grip", .5, 1.1, .55, 0, -.7, .4, C(40, 40, 45), "P", g)
	cylX(t, "Valve", .3, .4, CN(.7, .3, -.4), C(220, 40, 40), "P")
	ball(t, "Foam", .7, CN(0, .2, -3.1), C(255, 255, 255), "N", 0.3)
end)
-- Tier 5: backpack tanks + glowing blue gun (pack sits behind the hand, +Z)
local blue = C(70, 170, 255)
L.newHose(5, C(60, 70, 90), "P", function(t)
	cylZ(t, "GunBarrel", 1.7, .45, CN(0, .15, -1.85), C(170, 180, 195), "M")
	blk(t, "GlowTop", .12, .1, 1.5, 0, .45, -1.9, blue, "N")
	cylZ(t, "GlowTip", .25, .65, CN(0, .15, -2.82), blue, "N")
	blk(t, "GlowL", .1, .12, 1.2, -.25, .15, -1.8, blue, "N")
	blk(t, "GlowR", .1, .12, 1.2, .25, .15, -1.8, blue, "N")
	blk(t, "Grip", .45, 1.1, .5, 0, -.7, .4, C(35, 40, 55), "P", g)
	blk(t, "PackFrame", 1.7, 2.3, .6, 0, 1.1, 3.6, C(50, 60, 80), "P")
	for _, s in {-1, 1} do
		cylY(t, "Tank", 2.2, .7, CN(s * .45, 1.15, 4.0), C(90, 150, 210), "M")
		cylY(t, "TankBand", .15, .76, CN(s * .45, 1.15, 4.0), blue, "N")
	end
	bar(t, "Tube1", V(0, .3, 3.3), V(0, .1, 2.0), .18, blue, "N")
	bar(t, "Tube2", V(0, .1, 2.0), V(0, .15, 1.2), .18, blue, "N")
end)
-- Tier 6: white/gold Storm Cannon, cyan core
local gold, white, cyan = C(235, 185, 60), C(245, 245, 250), C(60, 230, 255)
L.newHose(6, white, "P", function(t)
	cylZ(t, "Barrel", 1.9, .65, CN(0, .15, -1.95), white, "P")
	cylZ(t, "Ring1", .2, .85, CN(0, .15, -1.3), gold, "M")
	cylZ(t, "Ring2", .2, .85, CN(0, .15, -2.1), gold, "M")
	cylZ(t, "Tip", .35, .95, CN(0, .15, -2.78), gold, "M")
	ball(t, "CoreGlass", 1.1, CN(0, .9, -.9), C(200, 250, 255), "G", 0.55)
	ball(t, "Core", .6, CN(0, .9, -.9), cyan, "N")
	ball(t, "Cloud", .3, CN(0, .95, -.9), white, "N")
	blk(t, "StripeL", .1, .1, 1.5, -.34, .15, -1.9, cyan, "N")
	blk(t, "StripeR", .1, .1, 1.5, .34, .15, -1.9, cyan, "N")
	blk(t, "Fin", .1, .6, .9, 0, .75, .35, gold, "M")
	blk(t, "Grip", .45, 1.1, .5, 0, -.7, .4, gold, "M", g)
	ball(t, "Pommel", .6, CN(0, 0, 1.4), gold, "M")
end)

-- ==== CHUNK 3: BICYCLE + KAPCAI ====
local red, black, silver = C(205, 45, 45), C(30, 30, 35), C(190, 195, 205)
local function wheel(m, tag, z, r, tw)
	cylX(m, tag .. "Tire", tw, 2 * r, CN(0, r, z), black, "R")
	cylX(m, tag .. "Rim", tw + .04, 2 * r - .5, CN(0, r, z), silver, "M")
	cylX(m, tag .. "Hub", tw + .1, .4, CN(0, r, z), red, "P")
end
L.newRide("Bicycle", function(m)
	wheel(m, "F", -2.1, 1.1, .3) wheel(m, "R", 1.9, 1.1, .3)
	local BB, S, H, R, F = V(0, .9, .5), V(0, 2.0, .9), V(0, 2.2, -1.6), V(0, 1.1, 1.9), V(0, 1.1, -2.1)
	local body = bar(m, "Body", BB, S, .24, red, "P")
	bar(m, "TopTube", S, H, .2, red, "P") bar(m, "DownTube", BB, H, .22, red, "P")
	bar(m, "ChainStay", BB, R, .14, red, "P") bar(m, "SeatStay", S, R, .14, red, "P")
	bar(m, "Fork", H, F, .16, silver, "M")
	bar(m, "Stem", H, V(0, 2.75, -1.75), .14, silver, "M")
	blk(m, "Handlebar", 1.8, .14, .14, 0, 2.75, -1.75, silver, "M")
	for _, s in {-1, 1} do
		cylX(m, "HandGrip", .4, .24, CN(s * .95, 2.75, -1.75), black, "R")
		blk(m, "Pedal", .5, .1, .3, s * .45, .9, .5, black, "P")
	end
	cylX(m, "Crank", .9, .2, CN(0, .9, .5), silver, "M")
	blk(m, "Saddle", .7, .22, 1.2, 0, 2.15, .95, black, "P")
	bar(m, "SeatPost", V(0, 1.95, .9), V(0, 2.1, .93), .12, silver, "M")
	local wood = C(170, 120, 70)
	blk(m, "BasketBase", 1.1, .08, .9, 0, 2.3, -2.5, wood, "W")
	blk(m, "BasketFront", 1.1, .5, .08, 0, 2.58, -2.95, wood, "W")
	blk(m, "BasketBack", 1.1, .5, .08, 0, 2.58, -2.05, wood, "W")
	blk(m, "BasketL", .08, .5, .9, -.55, 2.58, -2.5, wood, "W")
	blk(m, "BasketR", .08, .5, .9, .55, 2.58, -2.5, wood, "W")
	bar(m, "BasketArm", V(0, 2.2, -1.6), V(0, 2.3, -2.2), .1, silver, "M")
	ball(m, "Headlight", .35, CN(0, 2.6, -1.95), C(255, 240, 150), "N")
	blk(m, "Reflector", .25, .25, .1, 0, 1.85, 2.0, C(255, 60, 60), "N")
	return body, V(0, 3.0, .95)
end)
local gray, white2 = C(120, 125, 135), C(245, 245, 245)
L.newRide("Kapcai", function(m)
	wheel(m, "F", -2.4, 1.1, .5) wheel(m, "R", 2.0, 1.1, .5)
	local body = blk(m, "Body", 1.1, 1.0, 2.0, 0, 1.6, .7, red, "P")
	blk(m, "Engine", .9, .9, 1.3, 0, .9, -.1, gray, "M")
	blk(m, "Seat", .95, .3, 2.1, 0, 2.15, 1.0, black, "P")
	blk(m, "Floor", 1.2, .15, 1.5, 0, .95, -.9, white2, "P")
	blk(m, "LegShield", 1.2, 1.9, .3, 0, 1.8, -1.6, red, "P", AN(math.rad(-12), 0, 0))
	bar(m, "Fork", V(0, 1.1, -2.4), V(0, 2.5, -1.75), .22, silver, "M")
	blk(m, "Handlebar", 2.0, .2, .2, 0, 2.75, -1.7, black, "P")
	for _, s in {-1, 1} do
		cylX(m, "HandGrip", .4, .3, CN(s * 1.05, 2.75, -1.7), black, "R")
		bar(m, "Mirror", V(s * .9, 2.8, -1.7), V(s * 1.0, 3.4, -1.65), .1, silver, "M")
		blk(m, "MirrorHead", .4, .3, .08, s * 1.0, 3.5, -1.65, black, "P")
		blk(m, "Peg", .5, .12, .4, s * .75, .8, .3, black, "P")
	end
	ball(m, "Headlight", .7, CN(0, 2.6, -2.15), C(255, 245, 170), "N")
	blk(m, "FrontFender", .8, .12, 1.4, 0, 2.0, -2.45, red, "P", AN(math.rad(-6), 0, 0))
	blk(m, "RearFender", .9, .12, 1.4, 0, 2.3, 2.4, white2, "P")
	blk(m, "TailLight", .5, .25, .12, 0, 1.9, 3.0, C(255, 50, 50), "N")
	cylZ(m, "Exhaust", 2.0, .3, CN(.65, .65, 1.4), silver, "M")
	cylZ(m, "ExhaustTip", .3, .34, CN(.65, .65, 2.4), black, "M")
	blk(m, "Rack", 1.0, .12, 1.3, 0, 2.4, 3.0, black, "P")
	blk(m, "RearBox", 1.3, 1.0, 1.3, 0, 2.95, 3.0, white2, "P")
	blk(m, "BoxLid", 1.36, .12, 1.36, 0, 3.5, 3.0, red, "P")
	blk(m, "Stripe", 1.12, .2, 2.0, 0, 1.9, .7, white2, "P")
	return body, V(0, 3.0, 1.0)
end)

-- ==== CHUNK 4: TRUCK ====
local tred, tyel, dgray = C(205, 35, 40), C(255, 210, 50), C(70, 72, 80)
local function label(part, face, txt)
	local sg = Instance.new("SurfaceGui") sg.Face = face sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 50 sg.Parent = part
	local tl = Instance.new("TextLabel") tl.Size = UDim2.fromScale(1, 1) tl.BackgroundTransparency = 1 tl.Text = txt
	tl.TextScaled = true tl.Font = Enum.Font.GothamBlack tl.TextColor3 = white2 tl.Parent = sg
end
-- Player root sits 3 studs above the ground, so the bed is a low well: floor top ~0.15, walls to waist height
L.newRide("Truck", function(m)
	for _, z in {-4.6, 3.8} do for _, s in {-1, 1} do
		cylX(m, "Tire", .8, 2.8, CN(s * 3.2, 1.4, z), black, "R")
		cylX(m, "Hub", .85, 1.4, CN(s * 3.2, 1.4, z), silver, "M")
		cylX(m, "HubCap", .9, .5, CN(s * 3.2, 1.4, z), tred, "P")
		blk(m, "Mudguard", 1.0, .25, 3.4, s * 3.2, 2.95, z, tred, "P")
	end end
	local body = blk(m, "Body", 4.6, .2, 9.6, 0, .05, 2.2, dgray, "M")
	for _, s in {-1, 1} do
		blk(m, "Wall", .5, 2.2, 9.6, s * 2.55, 1.15, 2.2, tred, "P")
		blk(m, "Stripe", .06, .3, 9.6, s * 2.83, 2.0, 2.2, tyel, "P")
		local pl = blk(m, "NamePlate", .05, 1.0, 3.4, s * 2.83, 1.1, -.2, black, "P")
		label(pl, s == 1 and Enum.NormalId.Right or Enum.NormalId.Left, "BOMBA")
	end
	blk(m, "RearGate", 4.6, 1.2, .3, 0, .75, 7.0, tred, "P")
	blk(m, "FrontBumper", 6, .6, .6, 0, .8, -7.3, silver, "M")
	blk(m, "RearBumper", 5, .5, .5, 0, .5, 7.3, silver, "M")
	blk(m, "Cab", 5.6, 3.8, 4.4, 0, 2.1, -5.0, tred, "P")
	blk(m, "Windshield", 4.6, 1.4, .1, 0, 3.1, -7.23, C(150, 210, 255), "G", nil, .35)
	blk(m, "Grill", 2.6, 1.0, .12, 0, 1.3, -7.23, black, "P")
	for _, s in {-1, 1} do
		blk(m, "SideWindow", .1, 1.4, 2.4, s * 2.82, 3.1, -5.0, C(150, 210, 255), "G", nil, .35)
		ball(m, "Headlight", .9, CN(s * 2.0, 1.5, -7.3), C(255, 245, 170), "N")
		blk(m, "TailLight", .6, .4, .12, s * 1.9, .9, 7.2, C(255, 50, 50), "N")
		bar(m, "Mirror", V(s * 2.8, 3.0, -6.4), V(s * 3.5, 3.4, -6.6), .15, black, "P")
		blk(m, "MirrorHead", .2, .9, .5, s * 3.55, 3.3, -6.6, black, "P")
	end
	blk(m, "LightBarR", 2, .35, .7, -1.0, 4.2, -3.6, C(255, 50, 50), "N")
	blk(m, "LightBarB", 2, .35, .7, 1.0, 4.2, -3.6, C(60, 120, 255), "N")
	cylY(m, "CannonBase", .6, 1.4, CN(0, 4.3, -5.6), dgray, "M")
	cylZ(m, "CannonBarrel", 2.4, .7, CN(0, 5.0, -6.3), silver, "M")
	cylZ(m, "CannonTip", .35, .95, CN(0, 5.0, -7.4), tyel, "M")
	cylZ(m, "WaterTank", 2.0, 1.8, CN(0, 1.05, -1.5), white2, "P")
	cylZ(m, "TankStripe", .35, 1.86, CN(0, 1.05, -1.5), tred, "P")
	for _, x in {-2.65, -2.15} do bar(m, "LadderRail", V(x, 2.5, -2.0), V(x, 2.5, 6.4), .12, silver, "M") end
	for i = 0, 8 do blk(m, "Rung", .7, .1, .1, -2.4, 2.5, -1.7 + i * .9, silver, "M") end
	for _, s in {-1, 1} do blk(m, "Step", .8, .15, .7, s * 2.2, .3, -7.6, silver, "M") end
	return body, V(0, 3.15, 3.2), V(0, 5.0, -7.6)
end)
shared.PropLib = nil
