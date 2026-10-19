-- Run-local camp economy. Required only by JerebuServer; no save data.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Camp = {}
local costs = {WaterTower = 300, FieldKitchen = 250, RescueShelter = 500}
local buildings = workspace.Map.KemBombaRimba.Buildings
local counter = buildings.SupplyKiosk.CounterCollider
local refill = buildings.WaterTower.CampRefill
local remotes = RS.Jerebu.Remotes
local fund, built, lastBuy = 0, {}, {}
local extra = Instance.new("Part")
extra.Name = "SurvivalExtraRefill"
extra.Size = Vector3.new(14, 8, 14)
extra.CFrame = refill.CFrame * CFrame.new(20, 0, 0)
extra.Anchored, extra.CanCollide, extra.CanTouch, extra.CanQuery = true, false, false, false
extra.Transparency = 1
extra:SetAttribute("Rate", 0)
extra.Parent = buildings.WaterTower
CS:AddTag(extra, "Refill")
Camp.center = Vector3.new(-77, refill.Position.Y, -198)
function Camp.contains(pos)
	return math.abs(pos.X - Camp.center.X) <= 60 and math.abs(pos.Z - Camp.center.Z) <= 48 and math.abs(pos.Y - Camp.center.Y) <= 24
end
function Camp.has(id)
	return workspace:GetAttribute("Mode") == "Survival" and built[id] == true
end
local indicators = {}
for id in costs do
	local model = buildings:FindFirstChild(id == "FieldKitchen" and "CommandPavilion" or id)
	local base = model and model:GetPivot().Position or counter.Position
	local part = Instance.new("Part")
	part.Name = "Upgrade_" .. id
	part.Size = Vector3.new(3, 1, 3)
	part.Position = base + Vector3.new(0, 8, 0)
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
	part.Color = Color3.fromRGB(69, 198, 83)
	part.Material = Enum.Material.Neon
	part.Transparency = 1
	part.Parent = buildings
	indicators[id] = part
end
local function sync()
	workspace:SetAttribute("CampFund", fund)
	for id in costs do
		workspace:SetAttribute("CampBuilt_" .. id, built[id] == true)
		indicators[id].Transparency = built[id] and 0 or 1
	end
	refill:SetAttribute("Rate", built.WaterTower and 60 or 30)
	extra:SetAttribute("Rate", built.WaterTower and 60 or 0)
end
function Camp.reset()
	fund = 0
	table.clear(built)
	table.clear(lastBuy)
	sync()
end
function Camp.creditFire(paid)
	if workspace:GetAttribute("Mode") ~= "Survival" then return end
	fund += paid * 0.25 -- exact quarters retain small contributor rewards
	workspace:SetAttribute("CampFund", fund)
end
local buy = Instance.new("RemoteEvent")
buy.Name = "CampBuy"
buy.Parent = remotes
buy.OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "string" or not costs[id] then return end
	if os.clock() - (lastBuy[player] or -math.huge) < 0.4 then return end
	lastBuy[player] = os.clock()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if workspace:GetAttribute("Mode") ~= "Survival" or workspace:GetAttribute("Phase") ~= "Camp" then return end
	if not root or not hum or hum.Health <= 0 or player:GetAttribute("Downed") then return end
	if (root.Position - counter.Position).Magnitude > 16 then
		remotes.Notify:FireClient(player, "Visit the camp kiosk to build.", "info") return
	end
	if built[id] then return end
	if fund < costs[id] then remotes.Notify:FireClient(player, "The Camp Fund needs more coins.", "info") return end
	-- No yields between checking, debiting and marking built: concurrent requests cannot double-spend.
	fund -= costs[id]
	built[id] = true
	sync()
	remotes.Notify:FireAllClients(player.DisplayName .. " upgraded the camp!", "good")
end)
Players.PlayerRemoving:Connect(function(p) lastBuy[p] = nil end)
if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("DebugCampFund"):Connect(function()
		local n = workspace:GetAttribute("DebugCampFund")
		if typeof(n) == "number" and n >= 0 and n <= 10000 then fund = n sync() end
	end)
end
Camp.reset()
return Camp
