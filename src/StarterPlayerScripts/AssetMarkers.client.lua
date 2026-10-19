-- Nearby refill markers use the same artwork as the HUD.
local Players = game:GetService("Players")
local Assets = require(game:GetService("ReplicatedStorage"):WaitForChild("Jerebu"):WaitForChild("ImageAssets"))
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local refill = workspace:WaitForChild("Map"):WaitForChild("Refill")
local marked = {}
local function attach(model)
	if not model:IsA("Model") or model.Name ~= "Hydrant" or marked[model] then return end
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then return end
	marked[model] = true
	local gui = Instance.new("BillboardGui")
	gui.Name = "HydrantArt"
	gui.Adornee = part
	gui.Size = UDim2.fromOffset(36, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = Assets.Hydrant
	image.Parent = gui
	gui.Parent = playerGui
	model.Destroying:Once(function() gui:Destroy() marked[model] = nil end)
end
for _, model in refill:GetChildren() do attach(model) end
refill.DescendantAdded:Connect(function(descendant)
	local model = descendant:FindFirstAncestorWhichIsA("Model")
	if model then attach(model) end
end)
