local Players = game:GetService("Players")
local J = game:GetService("ReplicatedStorage"):WaitForChild("Jerebu")
local UI = require(J:WaitForChild("UIStyle"))
local remotes = J:WaitForChild("Remotes")
local buy = remotes:WaitForChild("CampBuy")
local player = Players.LocalPlayer
local gui = UI.New("ScreenGui", {Name = "JerebuCamp", ResetOnSpawn = false, DisplayOrder = 15, Parent = player:WaitForChild("PlayerGui")})
local fund = UI.GreenButton("CAMP FUND 0", {Name = "Fund", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -76), Size = UDim2.fromOffset(220, 44), Parent = gui}, 17)
local panel = UI.Panel({Name = "BuildMenu", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 370), Parent = gui}, 24)
local scale = UI.New("UIScale", {Parent = panel})
local function fit()
	scale.Scale = math.min(1, (gui.AbsoluteSize.X - 24) / 340, (gui.AbsoluteSize.Y - 24) / 370)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()
local function label(text, y, height, size)
	return UI.New("TextLabel", {BackgroundTransparency = 1, Text = text, Font = UI.Font, TextColor3 = UI.Colors.Ink, TextSize = size, TextWrapped = true, Position = UDim2.fromOffset(14, y), Size = UDim2.new(1, -28, 0, height), Parent = panel})
end
local title = label("KEM · CAMP UPGRADES", 12, 32, 20)
label("Shared bonus from fire rewards.\nBuild at the kiosk during Camp.", 46, 40, 14)
local definitions = {
	{"WaterTower", "WATER TOWER", 300, "Double refill speed + another refill spot"},
	{"FieldKitchen", "FIELD KITCHEN", 250, "Safe camp by day · heal 4 HP/sec"},
	{"RescueShelter", "RESCUE SHELTER", 500, "Faster revives · 10 more seconds to rescue"},
}
local buttons = {}
for i, item in definitions do
	local y = 92 + (i - 1) * 72
	local button = UI.PurpleButton(item[2], {Name = item[1], Position = UDim2.fromOffset(16, y), Size = UDim2.new(1, -32, 0, 44), Parent = panel}, 17)
	label(item[4], y + 46, 20, 12)
	button.Activated:Connect(function() if not button:GetAttribute("Disabled") then buy:FireServer(item[1]) end end)
	buttons[item[1]] = button
end
UI.GreenButton("CLOSE", {Position = UDim2.fromOffset(90, 316), Size = UDim2.fromOffset(160, 44), Parent = panel}, 17).Activated:Connect(function() panel.Visible = false end)
local function refresh()
	local survival = workspace:GetAttribute("Mode") == "Survival"
	local phase = workspace:GetAttribute("Phase")
	local balance = workspace:GetAttribute("CampFund") or 0
	fund.Visible = survival and phase ~= "Ended" and phase ~= "Intermission"
	fund.Label.Text = ("CAMP FUND %g · VIEW"):format(balance)
	if phase ~= "Camp" then panel.Visible = false end
	for _, item in definitions do
		local built = workspace:GetAttribute("CampBuilt_" .. item[1])
		buttons[item[1]].Label.Text = item[2] .. (built and " · BUILT" or (" · %d"):format(item[3]))
		UI.SetEnabled(buttons[item[1]], not built and balance >= item[3] and phase == "Camp")
	end
end
fund.Activated:Connect(function() panel.Visible = not panel.Visible end)
remotes.Notify.OnClientEvent:Connect(function(msg) if msg == "__opencamp" then panel.Visible = true end end)
for _, name in {"Mode", "Phase", "CampFund", "CampBuilt_WaterTower", "CampBuilt_FieldKitchen", "CampBuilt_RescueShelter"} do
	workspace:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
