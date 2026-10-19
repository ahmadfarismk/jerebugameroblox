-- Hose input: hold to spray toward the cursor (or screen centre on touch)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local tool = script.Parent
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local Remotes = RS:WaitForChild("Jerebu"):WaitForChild("Remotes")

local holding = false
local equipped = false

local function aimPoint(): Vector3
	local cam = workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, workspace:FindFirstChild("Fires") }
	local ray
	if UIS.TouchEnabled and not UIS.MouseEnabled then
		local vp = cam.ViewportSize
		ray = cam:ViewportPointToRay(vp.X / 2, vp.Y * 0.45)
	else
		ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
	end
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	return hit and hit.Position or (ray.Origin + ray.Direction * 60)
end

tool.Equipped:Connect(function()
	equipped = true
end)
tool.Unequipped:Connect(function()
	equipped = false
	if holding then
		holding = false
		Remotes.Spray:FireServer(nil, false)
	end
end)
tool.Activated:Connect(function()
	if holding then return end
	holding = true
	task.spawn(function()
		while holding and equipped do
			Remotes.Spray:FireServer(aimPoint(), true)
			task.wait(0.1)
		end
	end)
end)
tool.Deactivated:Connect(function()
	holding = false
	Remotes.Spray:FireServer(nil, false)
end)
