-- Small client-side rules that don't belong to any one HUD piece.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Our HUD shows coins and fires, and the crew panel shows teammates, so Roblox's player list
-- (which would sit on top of the API card) is hidden. SetCoreGuiEnabled can fail until CoreGui is ready.
task.spawn(function()
	for _ = 1, 20 do
		if pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end) then break end
		task.wait(0.5)
	end
end)

-- You can't revive yourself: hide the revive prompt the server puts on your own character.
local function watch(char: Model)
	char.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") and d.Name == "RevivePrompt" then d.Enabled = false end
	end)
end
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end
