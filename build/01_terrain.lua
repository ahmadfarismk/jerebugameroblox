-- Jerebu build step 1/6: terrain (run in Edit mode; clears existing terrain + baseplate)
local T = workspace.Terrain
if workspace:FindFirstChild("Baseplate") then workspace.Baseplate:Destroy() end
if workspace:FindFirstChild("SpawnLocation") then workspace.SpawnLocation:Destroy() end
T:Clear()
-- base ground
T:FillBlock(CFrame.new(0, -6, 0), Vector3.new(900, 12, 900), Enum.Material.Grass)
task.wait()
T:FillBlock(CFrame.new(0, -16, 0), Vector3.new(900, 8, 900), Enum.Material.Rock)
-- gentle hills in the forest ring
local rng = Random.new(42)
for i = 1, 40 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(200, 400)
	T:FillBall(Vector3.new(math.cos(a) * r, -10, math.sin(a) * r), rng:NextNumber(18, 34), Enum.Material.Grass)
	if i % 10 == 0 then task.wait() end
end
-- leafy ground patches
for _ = 1, 30 do
	local p = Vector3.new(rng:NextNumber(-420, 420), -1, rng:NextNumber(-420, 420))
	if p.Magnitude > 140 then
		T:FillBlock(CFrame.new(p), Vector3.new(rng:NextNumber(30, 70), 2.2, rng:NextNumber(30, 70)), Enum.Material.LeafyGrass)
	end
end
task.wait()
-- peatland (north-east)
T:FillBlock(CFrame.new(260, -1.2, -270), Vector3.new(220, 2.6, 180), Enum.Material.Mud)
T:FillBlock(CFrame.new(260, -1.0, -270), Vector3.new(180, 2.2, 140), Enum.Material.Ground)
T:FillBlock(CFrame.new(260, -1.2, -270), Vector3.new(150, 2.6, 110), Enum.Material.Mud)
task.wait()
-- river along z = -130
T:FillBlock(CFrame.new(0, -3, -130), Vector3.new(900, 8, 34), Enum.Material.Air)
T:FillBlock(CFrame.new(0, -7, -130), Vector3.new(900, 2, 34), Enum.Material.Sand)
T:FillBlock(CFrame.new(0, -4.5, -130), Vector3.new(900, 3, 34), Enum.Material.Water)
T:FillBlock(CFrame.new(0, -1, -112), Vector3.new(900, 2.2, 4), Enum.Material.Sand)
T:FillBlock(CFrame.new(0, -1, -148), Vector3.new(900, 2.2, 4), Enum.Material.Sand)
task.wait()
-- town ground + roads + paths
T:FillBlock(CFrame.new(0, -1, 20), Vector3.new(200, 2.2, 170), Enum.Material.Grass)
T:FillBlock(CFrame.new(0, -0.6, 20), Vector3.new(14, 1.4, 170), Enum.Material.Asphalt)
T:FillBlock(CFrame.new(0, -0.6, 20), Vector3.new(200, 1.4, 14), Enum.Material.Asphalt)
T:FillBlock(CFrame.new(0, -0.7, -160), Vector3.new(10, 1.4, 180), Enum.Material.Ground)
T:FillBlock(CFrame.new(220, -0.7, 20), Vector3.new(240, 1.4, 10), Enum.Material.Ground)
T:FillBlock(CFrame.new(-220, -0.7, 20), Vector3.new(240, 1.4, 10), Enum.Material.Ground)
T:FillBlock(CFrame.new(0, -0.7, 210), Vector3.new(10, 1.4, 220), Enum.Material.Ground)
-- school field
T:FillBlock(CFrame.new(60, -0.8, 65), Vector3.new(60, 1.4, 40), Enum.Material.LeafyGrass)
task.wait()
-- pave under buildings so terrain grass doesn't poke through floors
local function pave(pos, size, mat)
	local r = Region3.new(pos - size / 2, pos + size / 2):ExpandToGrid(4)
	T:ReplaceMaterial(r, 4, Enum.Material.Grass, mat)
	T:ReplaceMaterial(r, 4, Enum.Material.LeafyGrass, mat)
end
pave(Vector3.new(-40, -1, -40), Vector3.new(56, 6, 48), Enum.Material.Concrete)
pave(Vector3.new(110, -1, 65), Vector3.new(24, 6, 60), Enum.Material.Concrete)
pave(Vector3.new(-120, -1, 60), Vector3.new(48, 6, 124), Enum.Material.Asphalt)
for _, h in { { 12, -10 }, { -12, 50 }, { 30, 32 }, { -30, 8 }, { 12, 90 }, { 0, -100 }, { 150, 20 }, { -150, 20 }, { 0, 150 } } do
	pave(Vector3.new(h[1], -1, h[2]), Vector3.new(8, 6, 8), Enum.Material.Pavement)
end
return "terrain ok"
