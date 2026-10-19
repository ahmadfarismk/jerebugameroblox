-- Start the camera behind the character, looking where it faces (out of the fire station door),
-- instead of the place's saved camera angle at the station's back wall.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local function frameCharacter(char: Model)
	local root = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not root then return end
	-- let the default camera module and the spawn pivot settle first
	task.wait(0.3)
	RunService.RenderStepped:Wait()
	local cam = workspace.CurrentCamera
	if not root.Parent or cam.CameraType ~= Enum.CameraType.Custom then return end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
	local focus = root.Position + Vector3.new(0, 1.5, 0)
	-- the default camera keeps its zoom distance and only reads the look direction from here
	cam.CFrame = CFrame.lookAt(focus - flat * 12 + Vector3.new(0, 3, 0), focus + flat * 10)
end

player.CharacterAdded:Connect(frameCharacter)
if player.Character then task.spawn(frameCharacter, player.Character) end
