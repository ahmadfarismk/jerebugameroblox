-- Downed screen: while the local player is Downed, a calm centred banner counts down to the end of
-- the collapse. With teammates: revive hint. Solo: heading back to the BOMBA station.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local J = RS:WaitForChild("Jerebu")
local Config = require(J:WaitForChild("Config"))
local UI = require(J:WaitForChild("UIStyle"))

local K, new, C = UI.Colors, UI.New, Color3.fromRGB
local camera = workspace.CurrentCamera

local SOFT_AMBER = C(232, 150, 60)
local SOFT_DARK = C(150, 86, 30)

local gui = new("ScreenGui", { Name = "JerebuDowned", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
-- a soft, cool veil so the world feels hushed rather than punished
local veil = new("Frame", { Name = "Veil", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(24, 30, 52), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = gui })
local root = new("Frame", { Name = "Banner", Size = UDim2.fromOffset(440, 118), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), BackgroundTransparency = 1, Parent = gui })
local fit = new("UIScale", { Parent = root })
local card = UI.Card({ Name = "Card", Size = UDim2.fromScale(1, 1), Parent = root }, 22, 4)
local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
stroke.Color = SOFT_DARK
local title = UI.Text({ Name = "Title", Text = "You collapsed!", Size = UDim2.new(1, -24, 0, 38), Position = UDim2.fromOffset(12, 8), TextSize = 32, TextColor3 = K.White, Parent = card })
UI.TextStroke(SOFT_DARK, 3).Parent = title
local sub = UI.Text({ Name = "Sub", Text = "", Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 50), TextSize = 19, TextColor3 = K.Ink, Parent = card })
local track = new("Frame", { Name = "Track", Size = UDim2.new(1, -40, 0, 10), Position = UDim2.fromOffset(20, 90), BackgroundColor3 = C(53, 32, 78), BorderSizePixel = 0, Parent = card }, { UI.Corner(5) })
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = SOFT_AMBER, BorderSizePixel = 0, Parent = track }, { UI.Corner(5) })
-- warm gradient so the card reads as a gentle notice, not an alarm
local cardGradient = card:FindFirstChildOfClass("UIGradient") :: UIGradient
cardGradient.Color = ColorSequence.new(C(255, 240, 214), C(255, 214, 160))

local function fitBanner()
	local vp = camera.ViewportSize
	fit.Scale = math.clamp((vp.X - 24) / 440, 0.55, 1)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitBanner)
fitBanner()

local shown = false
local function setShown(on: boolean)
	if on == shown then return end
	shown = on
	if on then
		gui.Enabled = true
		TweenService:Create(veil, TweenInfo.new(0.5), { BackgroundTransparency = 0.72 }):Play()
		root.Position = UDim2.fromScale(0.5, 0.38)
		TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.42) }):Play()
	else
		TweenService:Create(veil, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.delay(0.3, function()
			if not shown then gui.Enabled = false end
		end)
	end
end

RunService.RenderStepped:Connect(function()
	local downed = player:GetAttribute("Downed") == true
	setShown(downed)
	if not downed then return end
	local solo = #Players:GetPlayers() <= 1
	local total = player:GetAttribute("DownedDuration") or (solo and Config.Revive.soloDownSeconds or Config.Revive.downSeconds)
	local left = math.max(0, (player:GetAttribute("DownedUntil") or 0) - workspace:GetServerTimeNow())
	local secs = math.ceil(left)
	if solo then
		sub.Text = ("Heading back to the BOMBA station · %ds"):format(secs)
	else
		sub.Text = ("A teammate can revive you · %ds"):format(secs)
	end
	fill.Size = UDim2.fromScale(math.clamp(left / total, 0, 1), 1)
	stroke.Thickness = 4 + 1.5 * (0.5 + 0.5 * math.sin(os.clock() * 2.5))
end)
