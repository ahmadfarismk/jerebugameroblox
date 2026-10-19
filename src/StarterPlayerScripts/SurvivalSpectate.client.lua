-- Follow a living teammate during survival respawn; return control on respawn.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local me = Players.LocalPlayer
local spectating = false
RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local own = me.Character and me.Character:FindFirstChildOfClass("Humanoid")
	local waiting = workspace:GetAttribute("Mode") == "Survival"
		and not workspace:GetAttribute("RunOver") and own and own.Health <= 0
	if waiting then
		for _, p in Players:GetPlayers() do
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if p ~= me and h and h.Health > 0 and not p:GetAttribute("Downed") then
				camera.CameraSubject = h
				spectating = true
				return
			end
		end
	elseif spectating and own then
		camera.CameraSubject = own
		spectating = false
	end
end)
