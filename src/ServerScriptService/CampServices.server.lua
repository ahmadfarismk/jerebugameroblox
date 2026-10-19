-- Uses the existing shop remote and refill rules; no separate economy.
local Players = game:GetService("Players")
local camp = workspace:WaitForChild("Map"):WaitForChild("KemBombaRimba")
local kiosk = camp.Buildings:WaitForChild("SupplyKiosk")
local prompt = kiosk.CounterCollider:WaitForChild("CampShopPrompt")
local notify = game:GetService("ReplicatedStorage"):WaitForChild("Jerebu"):WaitForChild("Remotes"):WaitForChild("Notify")
local lastOpen = {}
prompt.Triggered:Connect(function(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or player:GetAttribute("Downed") then return end
	if (root.Position - prompt.Parent.Position).Magnitude > 16 then return end
	local now = os.clock()
	if now - (lastOpen[player] or -math.huge) < 0.75 then return end
	lastOpen[player] = now
	local isCamp = workspace:GetAttribute("Mode") == "Survival" and workspace:GetAttribute("Phase") == "Camp"
	notify:FireClient(player, isCamp and "__opencamp" or "__openshop", "shop")
end)
Players.PlayerRemoving:Connect(function(player) lastOpen[player] = nil end)